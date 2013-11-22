// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012 Noise Developers (http://launchpad.net/noise)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Scott Ringwelski <sgringwe@mtu.edu>,
 *              Victor Eduardo <victoreduardm@gmail.com>
 */

public class Noise.GStreamerTagger : Object {
    private const int DISCOVER_SET_SIZE = 20;
    private const int DISCOVERER_TIMEOUT_MS = 10;

    public signal void media_imported (Media m);
    public signal void import_error (string file_uri);
    public signal void queue_finished ();

    private Gst.PbUtils.Discoverer d;
    private Gee.LinkedList<string> uri_queue;

    private bool cancelled;

    public GStreamerTagger () {
        uri_queue = new Gee.LinkedList<string> ();
    }

    private void file_set_finished () {
        if (cancelled) {
            debug ("import cancelled");
            d.stop ();
            queue_finished ();
        }
        else if (uri_queue.size == 0) {
            debug ("queue finished");
            d.stop ();
            queue_finished ();
        }
        else {
            import_next_file_set.begin ();
        }
    }

    private async void import_next_file_set () {
        if (d == null) {
            try {
                d = new Gst.PbUtils.Discoverer ((Gst.ClockTime) (10 * Gst.SECOND));
            } catch (Error err) {
                critical ("Could not create Gst discoverer object: %s", err.message);
            }

            d.discovered.connect (import_media);
            d.finished.connect (file_set_finished);
        } else {
            d.stop ();
        }
        d.start ();

        for (int i = 0; i < DISCOVER_SET_SIZE; i++) {
            bool not_found = true;
            string uri = null;
            while (uri == null && !uri_queue.is_empty) {
                uri = uri_queue.poll_head ();
                if (uri != null) {
                    d.discover_uri_async (uri);
                    not_found = false;
                }
            }
        }
    }

    public void cancel_operations () {
        cancelled = true;
    }

    public void discoverer_import_media (Gee.Collection<string> uris) {
        cancelled = false;
        lock (uri_queue) {
            uri_queue.clear ();
            uri_queue.add_all (uris);
        }
        
        import_next_file_set.begin ();
    }

    private async void import_media (Gst.PbUtils.DiscovererInfo info, Error err) {
        Media? m = null;

        string uri = info.get_uri ();

        bool gstreamer_discovery_successful = false;

        switch (info.get_result ()) {
            case Gst.PbUtils.DiscovererResult.OK:
                gstreamer_discovery_successful = true;
            break;

            case Gst.PbUtils.DiscovererResult.URI_INVALID:
                warning ("GStreamer could not import '%s': invalid URI.", uri);
            break;

            case Gst.PbUtils.DiscovererResult.ERROR:
                warning ("GStreamer could not import '%s': %s", uri, err.message);
            break;

            case Gst.PbUtils.DiscovererResult.TIMEOUT:
                warning ("GStreamer could not import '%s': Discovery timed out.", uri);
            break;

            case Gst.PbUtils.DiscovererResult.BUSY:
                warning ("GStreamer could not import '%s': Already discovering a file.", uri);
            break;

            case Gst.PbUtils.DiscovererResult.MISSING_PLUGINS:
                warning ("GStreamer could not import '%s': Missing plugins.", uri);

                /**
                 * TODO: handle this gracefully.
                 * After the import finishes, show the plugin-not-found
                 * dialog and rescan the music folder.
                 */
            break;
        }

        if (gstreamer_discovery_successful) {
            debug ("Importing with GStreamer: %s", uri);

            m = new Media (uri);

            // Get length in nanoseconds. We use the tag length as fallback
            uint64 duration = info.get_duration ();

            // Try to do the best we can: if only tags are null, only skip these.
            // The other data should still be imported.
            unowned Gst.TagList? tags = info.get_tags ();

            if (tags != null) {
                string title;
                if (tags.get_string (Gst.Tags.TITLE, out title))
                    m.title = title;

                string artist;
                if (tags.get_string (Gst.Tags.ARTIST, out artist))
                    m.artist = artist;

                string composer;
                if (tags.get_string (Gst.Tags.COMPOSER, out composer))
                    m.composer = composer;

                string album_artist;
                if (tags.get_string (Gst.Tags.ALBUM_ARTIST, out album_artist))
                    m.album_artist = album_artist;

                string album;
                if (tags.get_string (Gst.Tags.ALBUM, out album))
                    m.album = album;

                string grouping;
                if (tags.get_string (Gst.Tags.GROUPING, out grouping))
                    m.grouping = grouping;

                string genre;
                if (tags.get_string (Gst.Tags.GENRE, out genre))
                    m.genre = genre;

                string comment;
                if (tags.get_string (Gst.Tags.COMMENT, out comment))
                    m.comment = comment;

                string lyrics;
                if (tags.get_string (Gst.Tags.LYRICS, out lyrics))
                    m.lyrics = lyrics;

                uint track_number;
                if (tags.get_uint (Gst.Tags.TRACK_NUMBER, out track_number))
                    m.track = track_number;

                uint track_count;
                if (tags.get_uint (Gst.Tags.TRACK_COUNT, out track_count))
                    m.track_count = track_count;

                uint album_number;
                if (tags.get_uint (Gst.Tags.ALBUM_VOLUME_NUMBER, out album_number))
                    m.album_number = album_number;

                uint album_count;
                if (tags.get_uint (Gst.Tags.ALBUM_VOLUME_COUNT, out album_count))
                    m.album_count = album_count;

                uint bitrate;
                if (tags.get_uint (Gst.Tags.BITRATE, out bitrate))
                    m.bitrate = bitrate / 1000;

                uint rating;
                if (tags.get_uint (Gst.Tags.USER_RATING, out rating))
                    m.rating = rating; // Noise.Media will clamp the value

                // Get the year
                Date? date;
                if (tags.get_date (Gst.Tags.DATE, out date)) {
                    // Don't let the assumption that @date is non-null deceive you.
                    // This is sometimes null even though get_date() returned true!
                    if (date != null)
                        m.year = date.get_year ();
                }

                double bpm;
                if (tags.get_double (Gst.Tags.BEATS_PER_MINUTE, out bpm))
                    m.bpm = (uint) bpm.clamp (0, bpm);

                if (duration == 0)
                    if (!tags.get_uint64 (Gst.Tags.DURATION, out duration))
                        duration = 0;
            }

            m.length = TimeUtils.nanoseconds_to_miliseconds (duration);

            foreach (var stream_info in info.get_audio_streams ()) {
                var audio_stream = stream_info as Gst.PbUtils.DiscovererAudioInfo;
                if (audio_stream == null)
                    continue;

                if (m.samplerate == 0) {
                    debug ("Getting sample rate from stream info");
                    m.samplerate = audio_stream.get_sample_rate ();
                    debug ("Sample rate = %s", m.samplerate.to_string ());
                }

                if (m.bitrate == 0) {
                    debug ("Getting bitrate from stream info");
                    m.bitrate = audio_stream.get_bitrate ();
                    debug ("Bitrate = %s", m.bitrate.to_string ());
                }

                break;
           }

        }

        // Use taglib as fallback if GStreamer fails
        if (m == null && uri != null)
            m = taglib_import_media (uri);

        if (m != null) {
            // Get file size
            m.file_size = yield FileUtils.get_size_async (m.file);
            m.date_added = (int) time_t ();

            // For thread-safety reasons, we report the new import from the
            // main context's thread
            Idle.add_full (Priority.HIGH_IDLE, () => {
                media_imported (m);
                return false;
            });
        } else {
            // Got import error
            Idle.add_full (Priority.HIGH_IDLE, () => {
                import_error (uri);
                return false;
            });
        }
    }

    public Media? taglib_import_media (string uri) {
        debug ("Importing with TabLib: %s", uri);

        string? filename = null;
        try {
            filename = Filename.from_uri (uri);
        } catch (Error err) {
            warning ("Could not convert URI to filename: %s", err.message);
            filename = File.new_for_uri (uri).get_path ();
        }

        //var tag_file = new TagLib.File (uri.replace ("file://",""));
        var tag_file = new TagLib.File (filename);

        if (tag_file != null && tag_file.is_valid ()) {
            var s = new Media (uri);

            unowned TagLib.Tag? tag = tag_file.tag;
            bool has_tag = tag != null;
            if (has_tag) {
                s.title = tag.title;
                s.artist = tag.artist;
                s.album = tag.album;
                s.genre = tag.genre;
                s.comment = tag.comment;
                s.year = tag.year;
                s.track = tag.track;
            } else {
                warning ("Got NULL TagLib tags.");
            }

            unowned TagLib.AudioProperties? audioproperties = tag_file.audioproperties;
            bool has_audio_properties = audioproperties != null;
            if (has_audio_properties) {
                s.bitrate = audioproperties.bitrate;
                s.length = (uint) (audioproperties.length * Numeric.MILI_INV);
                s.samplerate = audioproperties.samplerate;
            } else {
                warning ("Got NULL TagLib audio properties.");
            }

            // We want to return null if nothing was found.
            if (has_tag || has_audio_properties)
                return s;
        }

        warning ("TagLib could not import '%s'", uri);
        return null;
    }


}
