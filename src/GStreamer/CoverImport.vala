// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012-2018 elementary LLC. (https://elementary.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * The Noise authors hereby grant permission for non-GPL compatible
 * GStreamer plugins to be used and distributed together with GStreamer
 * and Noise. This permission is above and beyond the permissions granted
 * by the GPL license by which Noise is covered. If you modify this code
 * you may extend this exception to your version of the code, but you are not
 * obligated to do so. If you do not wish to do so, delete this exception
 * statement from your version.
 *
 * Authored by: Corentin Noël <corentin@elementary.io>
 */

public class Noise.CoverImport : GLib.Object {
    private const int DISCOVERER_TIMEOUT = 5;

    private Gst.PbUtils.Discoverer discoverer;
    private Album album;

    construct {
        try {
            discoverer = new Gst.PbUtils.Discoverer ((Gst.ClockTime) (DISCOVERER_TIMEOUT * Gst.SECOND));
        } catch (Error err) {
            critical ("Could not create Gst discoverer object: %s", err.message);
        }
    }

    public CoverImport (Album album) {
        this.album = album;
        new Thread<void*> (null, () => {
            lock (this.album) {
                foreach (var media in album.get_media ()) {
                    try {
                        var info = discoverer.discover_uri (media.uri);
                        read_info (info);
                    } catch (Error err) {
                        critical ("Error while importing cover for %s: %s", album.name, err.message);
                    }
                }
            }
            return null;
        });
    }

    private void read_info (Gst.PbUtils.DiscovererInfo info) {
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
                warning ("GStreamer could not import '%s'", uri);
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
            Gdk.Pixbuf pixbuf = null;
            var tag_list = info.get_tags ();
            var sample = get_cover_sample (tag_list);

            if (sample == null) {
                tag_list.get_sample_index (Gst.Tags.PREVIEW_IMAGE, 0, out sample);
            }

            if (sample != null) {
                var buffer = sample.get_buffer ();

                if (buffer != null) {
                    pixbuf = get_pixbuf_from_buffer (buffer);
                    if (pixbuf != null) {
                        lock (album) {
                            album.save_cover_pixbuf (pixbuf);
                        }
                    }
                }

                debug ("Final image buffer is NULL for '%s'", info.get_uri ());
            } else {
                debug ("Image sample is NULL for '%s'", info.get_uri ());
            }
        }
    }

    private static Gst.Sample? get_cover_sample (Gst.TagList tag_list) {
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

    private static Gdk.Pixbuf? get_pixbuf_from_buffer (Gst.Buffer buffer) {
        Gst.MapInfo map_info;

        if (!buffer.map (out map_info, Gst.MapFlags.READ)) {
            warning ("Could not map memory buffer");
            return null;
        }

        Gdk.Pixbuf pix = null;

        try {
            var loader = new Gdk.PixbufLoader ();

            if (loader.write (map_info.data) && loader.close ())
                pix = loader.get_pixbuf ();
        } catch (Error err) {
            warning ("Error processing image data: %s", err.message);
        }

        buffer.unmap (map_info);

        return pix;
    }
}
