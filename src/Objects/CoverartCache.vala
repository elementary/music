// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012 Noise Developers (http://launchpad.net/noise)
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
 *
 * The Noise authors hereby grant permission for non-GPL compatible
 * GStreamer plugins to be used and distributed together with GStreamer
 * and Noise. This permission is above and beyond the permissions granted
 * by the GPL license by which Noise is covered. If you modify this code
 * you may extend this exception to your version of the code, but you are not
 * obligated to do so. If you do not wish to do so, delete this exception
 * statement from your version.
 *
 * Authored by: Victor Eduardo <victoreduardm@gmail.com>
 */

/**
 * Stores and fetches album-art images.
 *
 * TODO base upon Album instead of Media
 */
public class Noise.CoverartCache : MediaArtCache<Media> {

    private static CoverartCache? _instance = null;
    public static CoverartCache instance {
        get {
            if (_instance == null)
                _instance = new CoverartCache ();
            return _instance;
        }
    }

    private Gdk.Pixbuf default_image;

    public CoverartCache () {
        assert (_instance == null);

        base ("album-art");

        var default_pix = Icons.DEFAULT_ALBUM_ART.render_at_size (Icons.DEFAULT_ALBUM_ART_SIZE);
        default_image = filter_func (default_pix);
    }

    protected override Gdk.Pixbuf? filter_func (Gdk.Pixbuf pix) {
        int size = Icons.DEFAULT_ALBUM_ART_SIZE;
        return pix.scale_simple (size, size, Gdk.InterpType.BILINEAR);
    }

    protected override string get_key (Media m) {
        var builder = new StringBuilder ();

        string album_artist = m.album_artist;
        if (album_artist == "")
            album_artist = m.artist;

        builder.append (album_artist);
        builder.append (m.album);

        return builder.str;
    }

    /**
     * FIXME This is a temporary workaround. In the future (once Media's 'album' field is
     * an Album object), this entire class will be based upon Album and not Media.
     */
    [Deprecated (since = "1.1", replacement = "get_key")]
    private string get_album_key (Album album) {
        // This *must* be identical to the key returned for normal Media objects
        var builder = new StringBuilder ();
        builder.append (album.artist);
        builder.append (album.name);
        return builder.str;
    }

    [Deprecated (since = "1.1", replacement = "get_image")]
    public Gdk.Pixbuf get_album_cover (Album album) {
        return get_image_from_key (get_album_key (album)) ?? default_image;
    }

    public Gdk.Pixbuf get_cover (Media m) {
        return get_image (m) ?? default_image;
    }

    public Gdk.Pixbuf? get_original_cover (Media m) {
        var file = get_cached_image_file (m);
        if (file == null)
            return null;
        try {
            return new Gdk.Pixbuf.from_file (file.get_path ());
        } catch (Error err) {
            warning ("Could not get image from file [%s]: %s", file.get_uri (), err.message);
        }
        return null;
    }

    public async void fetch_all_cover_art_async (Gee.Collection<Media> media) {
        yield fetch_folder_images_async (media);
        yield load_for_media_async (media);
    }

    /**
     * Retrieves images from the cache for the specified media.
     */
    public async void load_for_media_async (Gee.Collection<Media> media) {
        // get_key() can yield a similar key for different media files, so we keep
        // track of all the keys we've explored in order to lookup images only once
        // for every equivalent media.
        var used_keys_set = new Gee.HashSet<string> ();
        var copy = new Gee.TreeSet<Media> ();
        copy.add_all (media);

        foreach (var m in copy) {
            string key = get_key (m);
            if (!used_keys_set.contains (key) && !has_image (m)) {
                yield get_image_async (m, true);
                used_keys_set.add (key);
            }
        }

        queue_notify ();
    }

    /**
     * Looks up for image types in the media's directory.
     */
    public async void fetch_folder_images_async (Gee.Collection<Media> media) {
        // get_key() can yield a similar key for different media files, so we keep
        // track of all the keys we've explored in order to lookup images only once
        // for every equivalent media.
        var used_keys_set = new Gee.HashSet<string> ();
        var copy = new Gee.TreeSet<Media> ();
        copy.add_all (media);

        foreach (var m in copy) {
            string key = get_key (m);
            if (!used_keys_set.contains (key) && !has_image (m)) {
                var art_file = yield lookup_folder_image_file_async (m);
                if (art_file != null)
                    yield cache_image_from_file_async (m, art_file);

                used_keys_set.add (key);
            }
        }
    }

    /**
     * Looks up a valid album image in a media's directory.
     *
     * It tries to find image files that follow certain name patterns, like "album.png",
     * "folder.jpg", the album name, etc. If no image matching the pattern is found, null
     * is returned.
     */
    private async File? lookup_folder_image_file_async (Media m) {
        File? media_file = m.file;
        return_val_if_fail (media_file != null, null);

        // Check file existence
        return_val_if_fail (yield FileUtils.query_exists_async (media_file), null);

        var album_folder = media_file.get_parent ();
        return_val_if_fail (album_folder != null, null);

        string album_name = String.canonicalize_for_search (m.album ?? "");

        // Don't consider generic image names if the album folder doesn't contain the name of
        // the media's album. This is probably the simpler way to prevent considering images
        // from folders that contain multiple unrelated tracks.
        bool generic_folder = !(album_name in String.canonicalize_for_search (album_folder.get_path ()));

        if (generic_folder)
            debug ("Found generic folder: %s. Won't import image files from it.", album_folder.get_path ());

        Gee.Collection<File> image_files;
        yield FileUtils.enumerate_files_async (album_folder, PixbufCache.IMAGE_TYPES, false, out image_files);

        File? image_file = null;

        // Choose an image based on priorities.
        foreach (var file in image_files) {
            // We don't want to be fooled by strange characters or whitespace
            string file_path = String.canonicalize_for_search (file.get_path ());

            if (generic_folder) {
                if (!String.is_white_space (album_name) && album_name in file_path) {
                    image_file = file;
                    break;
                }

                continue;
            }

            if ("folder" in file_path) {
                image_file = file;
                break;
            }

            if ("cover" in file_path) {
                image_file = file;
                continue;
            }

            // Let's use whatever we found
            if (image_file == null)
                image_file = file;

            if (!("cover" in image_file.get_path ()) && "album" in file_path)
                image_file = file;
            else if (!("album" in image_file.get_path ()) && "front" in file_path)
                image_file = file;
        }

        return image_file;
    }
}
