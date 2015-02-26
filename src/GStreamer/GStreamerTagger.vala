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
    private const int DISCOVERER_TIMEOUT = 5;

    public signal void media_imported (Media m);
    public signal void import_error (string file_uri, Error error);
    public signal void queue_finished ();

    private Gst.PbUtils.Discoverer d;
    private Gee.LinkedList<string> uri_queue = new Gee.LinkedList<string> ();
    private Cancellable cancellable = new GLib.Cancellable ();

    public GStreamerTagger (GLib.Cancellable? cancellable = null) {
        this.cancellable = cancellable;
        if (this.cancellable == null)
            this.cancellable = new Cancellable ();

        try {
            d = new Gst.PbUtils.Discoverer ((Gst.ClockTime) (DISCOVERER_TIMEOUT * Gst.SECOND));
            d.discovered.connect (import_media);
            d.finished.connect (file_set_finished);
        } catch (Error err) {
            critical ("Could not create Gst discoverer object: %s", err.message);
        }
    }

    private void file_set_finished () {
        if (cancellable.is_cancelled ()) {
            debug ("import cancelled");
            d.stop ();
            queue_finished ();
        } else if (uri_queue.size == 0) {
            debug ("queue finished");
            d.stop ();
            queue_finished ();
        } else {
            import_next_file_set ();
        }
    }

    private void import_next_file_set () {
        lock (uri_queue) {
            for (string uri = uri_queue.poll_head (); uri != null; uri = uri_queue.poll_head ()) {
                d.discover_uri_async (uri);
            }
        }
    }

    public void discoverer_import_media (Gee.Collection<string> uris) {
        lock (uri_queue) {
            uri_queue.add_all (uris);
        }

        d.start ();
        new Thread<void*> (null, () => {
            import_next_file_set ();
            return null;
        });
    }

    private void import_media (Gst.PbUtils.DiscovererInfo info, Error err) {
        if (cancellable.is_cancelled ()) {
            d.stop ();
            lock (uri_queue) {
                uri_queue.clear ();
            }

            queue_finished ();
            return;
        }

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

        if (!gstreamer_discovery_successful) {
            import_error (uri, err);
            return;
        }

        var m = new Media (uri);
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

            // Get the year, try datetime first, otherwise try date
            // NOTE: date might be superfluous, it was the original method,
            //       but doesn't seem to be used.
            Gst.DateTime? datetime;
            if (tags.get_date_time (Gst.Tags.DATE_TIME, out datetime)) {
                // Don't let the assumption that @datetime is non-null deceive you.
                // This is sometimes null even though get_date() returned true!
                if (datetime != null) {
                    m.year = datetime.get_year ();
                } else {
                    Date? date;
                    if (tags.get_date (Gst.Tags.DATE, out date)) {
                        // Don't let the assumption that @date is non-null deceive you.
                        // This is sometimes null even though get_date() returned true!
                        if (date != null) {
                            m.year = date.get_year ();
                        }
                    }
                }
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

        m.file_size = FileUtils.get_size (m.file);
        m.date_added = (int) time_t ();
        media_imported (m);
    }
}
