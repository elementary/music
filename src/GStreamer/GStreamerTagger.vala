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
    private const int DISCOVER_SET_SIZE = 50;
    private const int DISCOVERER_TIMEOUT_MS = 10;

    public signal void media_imported (Media m);
    public signal void import_error (string file_uri);
    public signal void queue_finished ();

    private Gst.Discoverer d;
    private Gee.LinkedList<string> uri_queue;

    private bool cancelled;

    public GStreamerTagger () {
        uri_queue = new Gee.LinkedList<string> ();
    }

    private Gst.Discoverer? create_discoverer () {
        Gst.Discoverer? discoverer = null;

        try {
            discoverer = new Gst.Discoverer ((Gst.ClockTime) (10 * Gst.SECOND));
        } catch (Error err) {
            critical ("Could not create Gst discoverer object: %s", err.message);
        }

        discoverer.discovered.connect (import_media);
        discoverer.finished.connect (file_set_finished);

        return discoverer;
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
            import_next_file_set ();
        }
    }

    private async void import_next_file_set () {
        d = create_discoverer ();
        d.start ();

        for (int i = 0; i < uri_queue.size; i++) {
            lock (uri_queue) {
                d.discover_uri_async (uri_queue.poll_head ());
            }
        }
    }

    public void cancel_operations () {
        cancelled = true;
    }

    public void discoverer_import_media (Gee.Collection<string> uris) {
        cancelled = false;
        uri_queue.clear ();

        uri_queue.add_all (uris);
        
        import_next_file_set ();
    }

    private async void import_media (Gst.DiscovererInfo info, Error err) {
        Media? m = null;

        string uri = info.get_uri ();

        bool gstreamer_discovery_successful = false;

        switch (info.get_result ()) {
            case Gst.DiscovererResult.OK:
                gstreamer_discovery_successful = true;
            break;

            case Gst.DiscovererResult.URI_INVALID:
                warning ("GStreamer could not import '%s': invalid URI.", uri);
            break;

            case Gst.DiscovererResult.ERROR:
                warning ("GStreamer could not import '%s': %s", uri, err.message);
            break;

            case Gst.DiscovererResult.TIMEOUT:
                warning ("GStreamer could not import '%s': Discovery timed out.", uri);
            break;

            case Gst.DiscovererResult.BUSY:
                warning ("GStreamer could not import '%s': Already discovering a file.", uri);
            break;

            case Gst.DiscovererResult.MISSING_PLUGINS:
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
                if (tags.get_string (Gst.TAG_TITLE, out title))
                    m.title = title;

                string artist;
                if (tags.get_string (Gst.TAG_ARTIST, out artist))
                    m.artist = artist;

                string composer;
                if (tags.get_string (Gst.TAG_COMPOSER, out composer))
                    m.composer = composer;

                string album_artist;
                if (tags.get_string (Gst.TAG_ALBUM_ARTIST, out album_artist))
                    m.album_artist = album_artist;

                string album;
                if (tags.get_string (Gst.TAG_ALBUM, out album))
                    m.album = album;

                string grouping;
                if (tags.get_string (Gst.TAG_GROUPING, out grouping))
                    m.grouping = grouping;

                string genre;
                if (tags.get_string (Gst.TAG_GENRE, out genre))
                    m.genre = genre;

                string comment;
                if (tags.get_string (Gst.TAG_COMMENT, out comment))
                    m.comment = comment;

                string lyrics;
                if (tags.get_string (Gst.TAG_LYRICS, out lyrics))
                    m.lyrics = lyrics;

                uint track_number;
                if (tags.get_uint (Gst.TAG_TRACK_NUMBER, out track_number))
                    m.track = track_number;

                uint track_count;
                if (tags.get_uint (Gst.TAG_TRACK_COUNT, out track_count))
                    m.track_count = track_count;

                uint album_number;
                if (tags.get_uint (Gst.TAG_ALBUM_VOLUME_NUMBER, out album_number))
                    m.album_number = album_number;

                uint album_count;
                if (tags.get_uint (Gst.TAG_ALBUM_VOLUME_COUNT, out album_count))
                    m.album_count = album_count;

                uint bitrate;
                if (tags.get_uint (Gst.TAG_BITRATE, out bitrate))
                    m.bitrate = bitrate / 1000;

                uint rating;
                if (tags.get_uint (Gst.TAG_USER_RATING, out rating))
                    m.rating = rating; // Noise.Media will clamp the value

                // Get the year
                Date? date;
                if (tags.get_date (Gst.TAG_DATE, out date)) {
                    // Don't let the assumption that @date is non-null deceive you.
                    // This is sometimes null even though get_date() returned true!
                    if (date != null)
                        m.year = date.get_year ();
                }

                double bpm;
                if (tags.get_double (Gst.TAG_BEATS_PER_MINUTE, out bpm))
                    m.bpm = (uint) bpm.clamp (0, bpm);

                if (duration == 0)
                    if (!tags.get_uint64 (Gst.TAG_DURATION, out duration))
                        duration = 0;
            }

            m.length = TimeUtils.nanoseconds_to_miliseconds (duration);

            foreach (var audio_stream in info.get_audio_streams ()) {
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

            // Get cover art
            import_art_async.begin (m, info);
        }

        // Use taglib as fallback if GStreamer fails
        if (m == null)
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

    private async void import_art_async (Media m, Gst.DiscovererInfo info) {
        var cache = CoverartCache.instance;
        if (cache.has_image (m))
            return;

        var pix = get_image (info.get_tags ());

        if (pix != null)
            yield cache.cache_image_async (m, pix);
        else
            warning ("Could not find embedded image for '%s'", info.get_uri ());
            
    }

    private static Gdk.Pixbuf? get_image (Gst.TagList tag) {
        Gst.Buffer? buffer = null;

        for (int i = 0; ; i++) {
            Gst.Buffer? loop_buffer = null;
            if (!tag.get_buffer_index (Gst.TAG_IMAGE, i, out loop_buffer))
                break;

            if (loop_buffer == null)
                continue;

            var structure = loop_buffer.caps.get_structure (0);
            if (structure == null)
                continue;

            int image_type;
            structure.get_enum ("image-type", typeof (Gst.TagImageType), out image_type);

            if (image_type == Gst.TagImageType.FRONT_COVER) {
                buffer = loop_buffer;
                break;
            } else if (image_type == Gst.TagImageType.UNDEFINED || buffer == null) {
                buffer = loop_buffer;
            }
        }

        if (buffer == null) {
            debug ("Final image buffer is null");
            return null;
        }

        return get_pixbuf_from_buffer (buffer);
    }

    private static Gdk.Pixbuf? get_pixbuf_from_buffer (Gst.Buffer buffer) {
        Gdk.Pixbuf? pix = null;
        var loader = new Gdk.PixbufLoader ();

        try {
            if (loader.write (buffer.data))
                pix = loader.get_pixbuf ();
            loader.close ();
        } catch (Error err) {
            warning ("Error processing pixbuf data: %s", err.message);
        }

        return pix;
    }

#if 0
    public bool save_media (Media s) {
        return false;

        Gst.Pipeline pipe = new Pipeline ("pipe");
        Element src = Element.make_from_uri (URIType.SRC, "file://" + s.file, null);
        Element decoder = ElementFactory.make ("decodebin", "decoder");

        Signal.connect (decoder, "new-decoded-pad", (Callback)newDecodedPad, this);

        if (! ((Gst.Bin)pipe).add_many (src, decoder)) {
            message ("Could not add src and decoder to pipeline to save metadata\n");
            return false;
        }

        if (!src.link_many (decoder)) {
            message ("Could not link src to decoder to save metadata\n");
            return false;
        }


        Gst.Element queue = ElementFactory.make ("queue", "queue");
        Gst.Element queue2 = ElementFactory.make ("queue", "queue2");

        if (queue == null || queue2 == null) {
            message ("could not add create queues to save metadata\n");
            return false;
        }

        if (! ((Gst.Bin)pipe).add_many (queue, queue2)) {
            warning ("Could not add queue's to save metadata\n");
            return false;
        }

        queue.set ("max-size-time", 120 * Gst.SECOND);




        //Element encoder = new_element_from_uri (URIType.SINK, "file://" + s.file, null);

        Gst.TagList tags;
        bool rv = true;
        //long day;

        tags = new TagList ();
        tags.add (TagMergeMode.REPLACE,  TAG_TITLE, s.title,
                                        TAG_ARTIST, s.artist,
                                        TAG_COMPOSER, s.composer,
                                        TAG_ALBUM_ARTIST, s.album_artist,
                                        TAG_ALBUM, s.album,
                                        TAG_GROUPING, s.grouping,
                                        TAG_GENRE, s.genre,
                                        TAG_COMMENT, s.comment,
                                        TAG_LYRICS, s.lyrics,
                                        TAG_TRACK_NUMBER, s.track,
                                        TAG_TRACK_COUNT, s.track_count,
                                        TAG_ALBUM_VOLUME_NUMBER, s.album_number,
                                        TAG_ALBUM_VOLUME_COUNT, s.album_count,
                                        TAG_USER_RATING, s.rating);

        /* fetch date, set new year to s.year, set date */

        // now find a tag setter interface and use it
        /*Gst.Iterator iter;
        bool done;

        iter = ((Gst.Bin)pipeline).iterate_all_by_interface (typeof (Gst.TagSetter));
        done = false;
        while (!done) {
              Gst.TagSetter tagger = null;

              switch (iter.next (out tagger) {
              case GST_ITERATOR_OK:
                    tagger.merge_tags (tags, GST_TAG_MERGE_REPLACE_ALL);
                    break;
              case GST_ITERATOR_RESYNC:
                    iter.resync ();
                    break;
              case GST_ITERATOR_ERROR:
                    warning ("Could not update metadata on media\n");
                    rv = false;
                    done = true;
                    break;
              case GST_ITERATOR_DONE:
                    done = true;
                    break;
              }
        }

        return rv;
    }

    public bool save_embeddeart_d (Gdk.Pixbuf pix) {
        return false;
    }
#endif
}
