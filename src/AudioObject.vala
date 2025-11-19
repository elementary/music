/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2021 elementary, Inc. (https://elementary.io)
 */

public class Music.AudioObject : Object {
    public string uri { get; construct; }
    public Gdk.Texture? texture { get; set; default = null; }
    public string album { get; set; }
    public string artist { get; set; }
    public string title { get; set; }
    public int64 duration { get; set; default = 0; }
    public string art_url { get; set; default = ""; }

    private static MetadataDiscoverer discoverer = new MetadataDiscoverer ();

    public AudioObject (string uri) {
        Object (
            uri: uri,
            title: uri
        );
    }

    construct {
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

        var sample = get_cover_sample (tag_list);
        if (sample != null) {
            var buffer = sample.get_buffer ();

            if (buffer != null) {
                texture = Gdk.Texture.for_pixbuf (get_pixbuf_from_buffer (buffer));
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

    public static bool equal_func (AudioObject a, AudioObject b) {
        return (a.uri == b.uri);
    }
}
