/*-
 * Copyright (c) 2011-2012       Scott Ringwelski <sgringwe@mtu.edu>
 *
 * Originally Written by Scott Ringwelski for BeatBox Music Player
 * BeatBox Music Player: http://www.launchpad.net/beat-box
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

using Gst;
using Gee;

public class Noise.GStreamerTagger : GLib.Object {

    LibraryManager lm;
    static int DISCOVER_SET_SIZE = 50;
    Gst.Discoverer d;
    HashMap<string, int> uri_to_id;
    LinkedList<string> path_queue;

    public signal void media_imported(Media m);
    public signal void import_error(string file);
    public signal void queue_finished();

    bool cancelled;

    public GStreamerTagger (LibraryManager lm) {
        this.lm = lm;

        d = create_discoverer ();

        uri_to_id = new HashMap<string, int> ();
        path_queue = new LinkedList<string> ();
    }

    private Gst.Discoverer? create_discoverer () {
        Gst.Discoverer? discoverer = null;

        try {
            discoverer = new Gst.Discoverer ((ClockTime) (30 * Gst.SECOND));
        } catch (Error err) {
            critical ("Metadata reader could not create discoverer object: %s\n", err.message);
        }

        discoverer.discovered.connect (import_media);
        discoverer.finished.connect (finished);

        return discoverer;
    }

    void finished () {
        if (!cancelled && path_queue.size > 0) {
            d = create_discoverer ();

            d.start ();
            for (int i = 0; i < DISCOVER_SET_SIZE && i < path_queue.size; ++i) {
                d.discover_uri_async ("file://" + path_queue.get (i));
            }
        } else {
            debug ("queue finished\n");
            queue_finished ();
        }
    }

    public void cancel_operations () {
        cancelled = true;
    }

    public void discoverer_import_media (LinkedList<string> files) {
        int size = 0;
        cancelled = false;
        path_queue.clear ();

        foreach (string s in files) {
            path_queue.add (s);

            d.start ();
            if (size < DISCOVER_SET_SIZE) {
                ++size;
                d.discover_uri_async ("file://" + s);
            }
        }
    }

    private async void import_media (DiscovererInfo info, Error err) {
        path_queue.remove (info.get_uri ().replace ("file://", ""));

        Media? s = null;

        if (info != null && info.get_tags () != null) {
            s = new Media (info.get_uri ());

            string title = "";
            string artist, composer, album_artist, album, grouping, genre, comment, lyrics;
            uint track, track_count, album_number, album_count, bitrate, rating;
            double bpm;
            GLib.Date? date = GLib.Date ();

            // get title, artist, album artist, album, genre, comment, lyrics strings
            if (info.get_tags ().get_string (TAG_TITLE, out title))
                s.title = title;
            if (info.get_tags ().get_string (TAG_ARTIST, out artist))
                s.artist = artist;
            if (info.get_tags ().get_string (TAG_COMPOSER, out composer))
                s.composer = composer;

            if (info.get_tags ().get_string (TAG_ALBUM_ARTIST, out album_artist))
                s.album_artist = album_artist;
            else
                s.album_artist = s.artist;

            if (info.get_tags ().get_string (TAG_ALBUM, out album))
                s.album = album;
            if (info.get_tags ().get_string (TAG_GROUPING, out grouping))
                s.grouping = grouping;
            if (info.get_tags ().get_string (TAG_GENRE, out genre))
                s.genre = genre;
            if (info.get_tags ().get_string (TAG_COMMENT, out comment))
                s.comment = comment;
            if (info.get_tags ().get_string (TAG_LYRICS, out lyrics))
                s.lyrics = lyrics;

            /* Get the year */
            if (info.get_tags ().get_date (TAG_DATE, out date)) {
                if (date != null)
                    s.year = (int) date.get_year ();
            }

            /* get track/album number/count, bitrating, rating, bpm */
            if (info.get_tags ().get_uint (TAG_TRACK_NUMBER, out track))
                s.track = (int)track;
            if (info.get_tags ().get_uint (TAG_TRACK_COUNT, out track_count))
                s.track_count = track_count;

            if (info.get_tags ().get_uint (TAG_ALBUM_VOLUME_NUMBER, out album_number))
                s.album_number = album_number;
            if (info.get_tags ().get_uint (TAG_ALBUM_VOLUME_COUNT, out album_count))
                s.album_count = album_count;

            if (info.get_tags ().get_uint (TAG_BITRATE, out bitrate))
                s.bitrate = (int) (bitrate / 1000);
            if (info.get_tags ().get_uint (TAG_USER_RATING, out rating))
                s.rating = (int) ((rating > 0 && rating <= 5) ? rating : 0);
            if (info.get_tags ().get_double (TAG_BEATS_PER_MINUTE, out bpm))
                s.bpm = (int) bpm;


            /* Get length */
            uint64 duration = info.get_duration ();

            if (duration == 0)
                info.get_tags ().get_uint64 (TAG_DURATION, out duration);

            /* Convert from nanoseconds (10E-9) to miliseconds (10E-3) */
            s.length = (uint) ((duration * Numeric.MILI_INV) / Numeric.NANO_INV);

            foreach (var audio_stream in info.get_audio_streams ()) {
                if (audio_stream == null)
                    continue;

                if (s.samplerate == 0) {
                    debug ("Getting sample rate from stream info");
                    s.samplerate = audio_stream.get_sample_rate ();
                    debug ("Sample rate = %s", s.samplerate.to_string ());
                }

                if (s.bitrate == 0) {
                    debug ("Getting bitrate from stream info");
                    s.bitrate = audio_stream.get_bitrate ();
                    debug ("Bitrate = %s", s.bitrate.to_string ());
                }

                break;
            }

            /* Get cover art */
            import_art_async.begin (s, info);
        } else {
            s = taglib_import_media (info.get_uri ());

            if (s == null) {
                import_error (info.get_uri ().replace ("file://", ""));
                return;
            }
        }

        /* Get the size */
        s.file_size = yield FileUtils.get_size_async (s.file);
        s.date_added = (int) time_t ();

        media_imported (s);
    }

    public Media? taglib_import_media (string uri) {
        Media s = new Media (uri);
        TagLib.File tag_file;

        tag_file = new TagLib.File (uri.replace ("file://",""));

        if (tag_file != null && tag_file.tag != null && tag_file.audioproperties != null) {
            try {
                s.title = tag_file.tag.title;
                s.artist = tag_file.tag.artist;
                s.album = tag_file.tag.album;
                s.genre = tag_file.tag.genre;
                s.comment = tag_file.tag.comment;
                s.year = (int) tag_file.tag.year;
                s.track = (int) tag_file.tag.track;
                s.bitrate = tag_file.audioproperties.bitrate;

                s.length = (uint) (tag_file.audioproperties.length * Numeric.MILI_INV);
                s.samplerate = tag_file.audioproperties.samplerate;
            } finally {
                if (s.title == null || s.title == "") {
                    string[] paths = uri.split ("/", 0);
                    s.title = paths[paths.length - 1];
                }

                if (s.artist == null || s.artist == "") s.artist = Media.UNKNOWN_ARTIST;

                s.album_artist = s.artist;
                s.album_number = 1;
            }
        } else {
            return null;
        }

        return s;
    }

    private async void import_art_async (Media m, DiscovererInfo info) {
        var cache = CoverartCache.instance;

        if (cache.has_image (m))
            return;

        var pix = get_image (info.get_tags ());

        if (pix != null)
            yield cache.cache_image_async (m, pix);
        else
            warning ("import_art: null pixbuf");
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
            debug ("FINAL BUFFER IS NULL. RETURNING NULL");
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

    public bool save_media (Media s) {
        return false;

        /*Gst.Pipeline pipe = new Pipeline("pipe");
          Element src = Element.make_from_uri(URIType.SRC, "file://" + s.file, null);
          Element decoder = ElementFactory.make("decodebin", "decoder");

          GLib.Signal.connect(decoder, "new-decoded-pad", (GLib.Callback)newDecodedPad, this);

          if(!((Gst.Bin)pipe).add_many(src, decoder)) {
          message ("Could not add src and decoder to pipeline to save metadata\n");
          return false;
          }

          if(!src.link_many(decoder)) {
          message ("Could not link src to decoder to save metadata\n");
          return false;
          }


          Gst.Element queue = ElementFactory.make("queue", "queue");
          Gst.Element queue2 = ElementFactory.make("queue", "queue2");

          if(queue == null || queue2 == null) {
          message ("could not add create queues to save metadata\n");
          return false;
          }

          if(!((Gst.Bin)pipe).add_many(queue, queue2)) {
          warning ("Could not add queue's to save metadata\n");
          return false;
          }

          queue.set("max-size-time", 120 * Gst.SECOND);




          //Element encoder = new_element_from_uri(URIType.SINK, "file://" + s.file, null);

          Gst.TagList tags;
          bool rv = true;
          //long day;

          tags = new TagList();
          tags.add(TagMergeMode.REPLACE,  TAG_TITLE, s.title,
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

          iter = ((Gst.Bin)pipeline).iterate_all_by_interface(typeof(Gst.TagSetter));
          done = false;
          while (!done) {
          Gst.TagSetter tagger = null;

          switch (iter.next(out tagger) {
          case GST_ITERATOR_OK:
          tagger.merge_tags (tags, GST_TAG_MERGE_REPLACE_ALL);
          break;
          case GST_ITERATOR_RESYNC:
          iter.resync();
          break;
          case GST_ITERATOR_ERROR:
          warning("Could not update metadata on media\n");
          rv = false;
          done = true;
          break;
          case GST_ITERATOR_DONE:
          done = true;
          break;
          }
          }

          return rv;      */
    }

    public bool save_embeddeart_d (Gdk.Pixbuf pix) {
        return false;
    }
}
