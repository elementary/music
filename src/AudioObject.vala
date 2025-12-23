/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2021 elementary, Inc. (https://elementary.io)
 */

public class Music.AudioObject : Object {
    public string uri { get; construct; }
    public Gdk.Texture? texture { get; private set; default = null; }
    public string album { get; private set; }
    public string artist { get; private set; }
    public string title { get; private set; }
    public int64 duration { get; private set; default = 0; }
    public string art_url { get; private set; default = ""; }

    private static MetadataDiscoverer discoverer = new MetadataDiscoverer ();

    public AudioObject (string uri) {
        Object (uri: uri);
    }

    construct {
        title = uri;
        discoverer.request (this);
    }

    public void update_metadata (Gst.PbUtils.DiscovererInfo info) {
        duration = (int64) info.get_duration ();

        unowned Gst.TagList? tag_list = info.get_tags ();

        string _title;
        tag_list.get_string (Gst.Tags.TITLE, out _title);
        if (_title != null) {
            title = _title;
        }

        string _artist;
        tag_list.get_string (Gst.Tags.ARTIST, out _artist);
        if (_artist != null) {
            artist = _artist;
        } else if (_title != null) { // Don't set artist for files without tags
            artist = _("Unknown");
        }

        string art_hash = uri;
        if (_artist != null && _album != null) {
            art_hash = "%s:%s".printf (_artist, _album);
        }

        var art_file = File.new_for_path (Path.build_path (
            Path.DIR_SEPARATOR_S,
            get_art_cache_dir (),
            Checksum.compute_for_string (SHA256, art_hash)
        ));

        if (art_file.query_exists ()) {
            art_url = art_file.get_uri ();
            texture = Gdk.Texture.from_file (art_file);
        } else {
            var sample = get_cover_sample (tag_list);
            if (sample != null) {
                var buffer = sample.get_buffer ();

                if (buffer != null) {
                    texture = Gdk.Texture.for_pixbuf (get_pixbuf_from_buffer (buffer));
                    save_art_file.begin (texture, art_file);
                }
            }
        }
    }

    private Gst.Sample? get_cover_sample (Gst.TagList tag_list) {
        Gst.Sample cover_sample = null;
        Gst.Sample sample;
        for (int i = 0; tag_list.get_sample_index (Gst.Tags.IMAGE, i, out sample); i++) {
            var caps = sample.get_caps ();
            unowned Gst.Structure caps_struct = caps.get_structure (0);
            int image_type = Gst.Tag.ImageType.UNDEFINED;
            caps_struct.get_enum ("image-type", typeof (Gst.Tag.ImageType), out image_type);
            if (image_type == Gst.Tag.ImageType.UNDEFINED && cover_sample == null) {
                cover_sample = sample;
            } else if (image_type == Gst.Tag.ImageType.FRONT_COVER) {
                return sample;
            }
        }

        return cover_sample;
    }

    private Gdk.Pixbuf? get_pixbuf_from_buffer (Gst.Buffer buffer) {
        Gst.MapInfo map_info;

        if (!buffer.map (out map_info, Gst.MapFlags.READ)) {
            warning ("Could not map memory buffer");
            return null;
        }

        Gdk.Pixbuf pix = null;

        try {
            var loader = new Gdk.PixbufLoader ();

            if (loader.write (map_info.data) && loader.close ()) {
                pix = loader.get_pixbuf ();
            }
        } catch (Error err) {
            warning ("Error processing image data: %s", err.message);
        }

        buffer.unmap (map_info);

        return pix;
    }

    private async void save_art_file (Gdk.Texture? texture, File file) requires (texture != null) {
        try {
            DirUtils.create_with_parents (get_art_cache_dir (), 0755);

            var ostream = yield file.create_async (NONE);
            yield ostream.write_bytes_async (texture.save_to_png_bytes ());

            art_url = file.get_uri ();
        } catch (Error e) {
            critical ("Error saving artwork file: %s", e.message);
        }
    }

    private string get_art_cache_dir () {
        return Path.build_path (
            Path.DIR_SEPARATOR_S,
            Environment.get_user_cache_dir (),
            GLib.Application.get_default ().application_id,
            "art"
        );
    }

    public static bool equal_func (AudioObject a, AudioObject b) {
        return (a.uri == b.uri);
    }
}
