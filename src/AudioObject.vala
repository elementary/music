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

    public void update_metadata () {
        try {
            new Thread<void*>.try (null, () => {
                try {
                    var discoverer = new Gst.PbUtils.Discoverer ((Gst.ClockTime) (5 * Gst.SECOND));

                    var info = discoverer.discover_uri (uri);

                    if (info == null) {
                        warning ("Discovery failed.");
                        return null;
                    }

                    unowned Gst.TagList? tag_list = info.get_tags ();

                    duration = (int64) info.get_duration ();

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

                    var sample = PlaybackManager.get_cover_sample (tag_list);
                    if (sample != null) {
                        var buffer = sample.get_buffer ();

                        Gst.MapInfo? map_info = null;
                        if (buffer != null && buffer.map (out map_info, Gst.MapFlags.READ) && map_info != null) {
                            var bytes = new Bytes (map_info.data);
                            try {
                                texture = Gdk.Texture.from_bytes (bytes);
                            } catch (Error e) {
                                warning ("Error processing image data: %s", e.message);
                            }

                            buffer.unmap (map_info);
                        } else {
                            warning ("Could not map memory buffer");
                        }
                    }
                } catch (Error e) {
                    warning ("Failed to create texture: %s", e.message);
                }

                return null;
            });
        } catch (Error e) {
            warning ("Failed to create thread: %s", e.message);
        }
    }
}
