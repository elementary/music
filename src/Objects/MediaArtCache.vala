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
 * Base class for storing cached media-art pixbufs
 *
 * Media art images are permanently stored at ${XDG_CACHE_HOME}/noise/...
 */
public abstract class Noise.MediaArtCache {

    public signal void changed ();

    private PixbufCache pixbuf_cache;


    public MediaArtCache (string folder_name) {
        var image_dir = FileUtils.get_cache_directory ().get_child (folder_name);
        pixbuf_cache = new PixbufCache (image_dir);

        pixbuf_cache.filter_func = (key, orig_pix, apply_to_file) => {
            return filter_func (orig_pix, out apply_to_file);
        };
    }


    /**
     * Key used for storing images.
     */
    protected abstract string get_key (Media m);


    /**
     * This function is called before storing a pixbuf in the cache, allowing
     * to transform it. The changes are applied to the cache file when apply_to_file
     * is set to true.
     */
    protected abstract Gdk.Pixbuf? filter_func (Gdk.Pixbuf pix, out bool apply_to_file);


    /**
     * Verifies whether the media object m has a corresponding image in the cache.
     */
    public bool has_image (Media m) {
        return pixbuf_cache.has_image (get_key (m));
    }


    /**
     * Returns the location of the image on disk. This call does no blocking I/O.
     * A path is returned even if there's no associated image in the cache (i.e. the path
     * doesn't exist).
     * Since there are no guarantees that the returned path is valid, don't write code that crashes
     * if it isn't. You can call has_image() to verify the existance of the image, and it will
     * reliably help to avoid errors most of the time (i.e. under normal conditions).
     */
    protected string get_cached_image_path (string key) {
        return pixbuf_cache.get_cached_image_path (key);
    }


    /**
     * Returns the location of the media's image on disk. This call does no blocking I/O.
     * A path is returned even if there's no associated image in the cache (i.e. the path
     * doesn't exist).
     * Since there are no guarantees that the returned path is valid, don't write code that crashes
     * if it isn't. You can call has_image() to verify the existance of the image, and it will
     * reliably help to avoid errors most of the time (i.e. under normal conditions).
     */
    public string get_cached_image_path_for_media (Media m) {
        return pixbuf_cache.get_cached_image_path (get_key (m));
    }


    /**
     * Assign an image to media and all other media objects for which get_key()
     * would return an identical value. The image is not assigned to the media
     * object itself, but stored on an internal table. Changes are written to
     * disk as well.
     *
     * The image can be later retrieved through get_image().
     *
     * This method can also be used to update image buffers when they have changed
     * (e.g. due to metadata changes, etc.), since the old pixbuf and cached image
     * are overwritten.
     */
    public void cache_image (Media m, Gdk.Pixbuf image) {
        pixbuf_cache.cache_image (get_key (m), image);
        queue_notify ();
    }


    /**
     * This method does the same as cache_image(), with the only difference that it
     * first fetches the image from the given file.
     */
    public void cache_image_from_file (Media m, File image_file, Cancellable? c = null) {
        pixbuf_cache.cache_image_from_file (get_key (m), image_file, c);
        queue_notify ();
    }


    /**
     * Removes the image corresponding to the media from the table. It also deletes
     * the associated file from the cache directory.
     */
    public Gdk.Pixbuf? decache_image (Media m) {
        var pix = pixbuf_cache.decache_image (get_key (m));
        queue_notify ();
        return pix;
    }


    /**
     * @return null if the media's corresponding image was not found; otherwise
     *         a valid {@link Gdk.Pixbuf}
     */
    protected Gdk.Pixbuf? get_image (Media m, bool lookup_file) {
        return pixbuf_cache.get_image (get_key (m), lookup_file);
    }


    protected void queue_notify () {
        Idle.add ( () => {
            changed ();
            return false;
        });
    }
}


/**
 * Stores and fetches album-art images
 */
public class Noise.CoverartCache : MediaArtCache {

    public Gdk.Pixbuf DEFAULT_IMAGE;

    private static CoverartCache? _instance = null;
    public static CoverartCache instance {
        get {
            if (_instance == null)
                _instance = new CoverartCache ();
            return _instance;
        }
    }

    private Mutex mutex;


    public CoverartCache () {
        base ("album-art");

        bool dummy;
        DEFAULT_IMAGE = filter_func (Icons.DEFAULT_ALBUM_ART.render (null), out dummy);
    }


    // add a shadow to every image
    protected override Gdk.Pixbuf? filter_func (Gdk.Pixbuf pix, out bool apply_to_file) {
        apply_to_file = false;
        return PixbufUtils.get_pixbuf_shadow (pix, Icons.ALBUM_VIEW_IMAGE_SIZE);
    }


    protected override string get_key (Media m) {
        string album_name = m.album;
        string artist_name = m.album_artist;

        if (artist_name == "")
            artist_name = m.artist;

        return @"$artist_name-$album_name";
    }


    public Gdk.Pixbuf get_cover (Media m) {
        var image = get_image (m, false);
        return image ?? DEFAULT_IMAGE;
    }


    public async void fetch_all_cover_art_async (Gee.Collection<Media> media) {
        yield fetch_folder_images_async (media);
        yield load_for_media_async (media);
    }


    public async void load_for_media_async (Gee.Collection<Media> media) {
        SourceFunc callback = load_for_media_async.callback;

        try {
            new Thread<void*>.try (null, () => {
                load_for_media (media);

                Idle.add ((owned)callback);
                return null;
            });
        } catch (Error err) {
            warning ("Could not create thread to fetch all cover art: %s", err.message);
        }

        yield;
    }


    public void load_for_media (Gee.Collection<Media> media) {
        mutex.lock ();
        debug ("READING CACHED COVERART");

        var used_keys_set = new Gee.HashSet<string> ();

        foreach (var m in media) {
            string key = get_key (m);

            if (!used_keys_set.contains (key) && !has_image (m)) {
                debug ("Getting [%s]", key);

                // Pass true to lookup_file in order to fetch the images for the first time
                get_image (m, true);

                used_keys_set.add (key);
            }
        }

        debug ("FINISHED LOADING CACHED COVERART");
        mutex.unlock ();

        queue_notify ();
    }


    public async void fetch_folder_images_async (Gee.Collection<Media> media) {
        SourceFunc callback = fetch_folder_images_async.callback;

        try {
            new Thread<void*>.try (null, () => {
                fetch_folder_images (media);

                Idle.add ((owned)callback);
                return null;
            });
        } catch (Error err) {
            warning ("Could not create thread to fetch all cover art: %s", err.message);
        }

        yield;
    }


    /**
     * Looks up for image types in the media's directory. We look for image files
     * that follow certain name patterns, like "album.png", "folder.jpg", etc.
     */
    public void fetch_folder_images (Gee.Collection<Media> media) {
        mutex.lock ();

        foreach (var m in media) {
            if (!has_image (m)) {
                var art_file = lookup_folder_image_file (m);
                if (art_file != null)
                    cache_image_from_file (m, art_file);
            }
        }

        mutex.unlock ();

        queue_notify ();
    }


    // Awesome method taken from BeatBox's FileOperator.vala (adapted to use Noise's internal API)
    private static File? lookup_folder_image_file (Media m) {
        File? rv = null, media_file = m.file;

        if (!media_file.query_exists ())
            return rv;

        var album_folder = media_file.get_parent ();

        if (album_folder == null)
            return rv;

        // Don't consider generic image names if the album folder doesn't contain the name of
        // the media's album. This is probably the simpler way to prevent considering images
        // from folders that contain multiple unrelated tracks.
        bool generic_folder = !album_folder.get_path ().contains (m.album);

        string[] image_types = { "jpg", "jpeg", "png" };
        Gee.Collection<File> image_files;
        FileUtils.enumerate_files (album_folder, image_types, false, out image_files);

        // Choose an image based on priorities.
        foreach (var file in image_files) {
            string file_path = file.get_path ().down ();

            if (generic_folder) {
                if (file_path.contains (m.album)) {
                    rv = file;
                    break;
                }

                continue;
            }


            if (file_path.contains ("folder")) {
                rv = file;
                break;
            }

            if (file_path.contains ("cover")) {
                rv = file;
            } else if (rv != null) {
                if (!rv.get_path ().contains ("cover") && file_path.contains ("album"))
                    rv = file;
                else if (!rv.get_path ().contains ("album") && file_path.contains ("front"))
                    rv = file;
                else if (!rv.get_path ().contains ("front") && file_path.contains (m.album))
                    rv = file;
            } else {
                rv = file;
            }
        }

        return rv;
    }
}
