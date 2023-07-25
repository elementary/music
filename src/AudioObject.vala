/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2021 elementary, Inc. (https://elementary.io)
 */

public class Music.AudioObject : Object {
    public string uri { get; set; }
    public Gdk.Texture texture { get; set; }
    public string artist { get; set; }
    public string title { get; set; }
    public int64 duration { get; set; default = 0; }

    public AudioObject.from_file (File file) {
        uri = file.get_uri ();

        string? basename = file.get_basename ();

        if (basename != null) {
            title = basename;
        } else {
            title = uri;
        }
    }

    construct {
        new Thread<void*> (null, () => {
            try {
                var discoverer = new Gst.PbUtils.Discoverer ((Gst.ClockTime) (5 * Gst.SECOND));

                var info = discoverer.discover_uri (uri);

                if (info == null) {
                    warning ("Discovery failed.");
                    return null;
                }

                unowned Gst.TagList? tag_list = info.get_tags ();

                var sample = PlaybackManager.get_cover_sample (tag_list);
                if (sample != null) {
                    var buffer = sample.get_buffer ();

                    if (buffer != null) {
                        texture = Gdk.Texture.for_pixbuf (PlaybackManager.get_pixbuf_from_buffer (buffer));
                    }
                }
            } catch (Error e) {
                warning ("Failed to create texture: %s", e.message);
            }

            return null;
        });
    }
}
