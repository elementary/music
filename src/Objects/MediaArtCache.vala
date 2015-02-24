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
public abstract class Noise.MediaArtCache<T> {

    public signal void changed ();

    private PixbufCache pixbuf_cache;
    private bool notify_queued = false; // whether an update notification is waiting or not

    public MediaArtCache (string folder_name) {
        var image_dir = FileUtils.get_cache_directory ().get_child (folder_name);
        pixbuf_cache = new PixbufCache (image_dir);

        // The key parameter is not useful for our purposes (there's no way to get the media
        // corresponding to the @key parameter without scanning the entire cache, which is not
        // efficient by any means), so we use a lambda function as a bridge in order to discard it.
        pixbuf_cache.filter_func = (key, orig_pix) => {
            return filter_func (orig_pix);
        };
    }

    /**
     * Key used for storing images.
     */
    protected abstract string get_key (T object);

    /**
     * This function is called before storing a pixbuf in the cache, allowing
     * to transform it.
     *
     * @see Noise.PixbufCache.filter_func
     */
    protected abstract Gdk.Pixbuf? filter_func (Gdk.Pixbuf pix);

    /**
     * Verifies whether the object has a corresponding image in the cache.
     *
     * @see Noise.PixbufCache.has_image
     */
    public bool has_image (T object) {
        return pixbuf_cache.has_image (get_key (object));
    }

    /**
     * Returns a file representing the objects's image on disk. This call does no blocking I/O.
     * If there's no associated image in the cache, //null// is returned.
     */
    public File? get_cached_image_file (T object) {
        var key = get_key (object);
        bool has_image = pixbuf_cache.has_image (key);
        return has_image ? pixbuf_cache.get_cached_image_file (key) : null;
    }

    /**
     * Assign an image to media and all other objects for which get_key()
     * would return an identical value. The image is not assigned to the
     * object itself, but stored on an internal table. Changes are written to
     * disk as well.
     *
     * The image can be later retrieved through get_image().
     *
     * This method can also be used to update image buffers when they have changed
     * (e.g. due to metadata changes, etc.), since the old pixbuf and cached image
     * are overwritten.
     */
    public async void cache_image_async (T object, Gdk.Pixbuf image) {
        yield pixbuf_cache.cache_image_async (get_key (object), image);
        queue_notify ();
    }

    /**
     * This method does the same as cache_image(), with the only difference that it
     * first fetches the image from the given file.
     */
    public async void cache_image_from_file_async (T object, File image_file, Cancellable? c = null) {
        yield pixbuf_cache.cache_image_from_file_async (get_key (object), image_file, c);
        queue_notify ();
    }

    /**
     * Removes the image corresponding to the object from the table. It also deletes
     * the associated file from the cache directory.
     */
    public Gdk.Pixbuf? decache_image (T object) {
        var pix = pixbuf_cache.decache_image (get_key (object));
        queue_notify ();
        return pix;
    }

    /**
     * @return null if the object's corresponding image was not found; otherwise
     * a valid {@link Gdk.Pixbuf}.
     */
    public virtual Gdk.Pixbuf? get_image (T object) {
        return pixbuf_cache.get_image (get_key (object));
    }

    /**
     * FIXME this is a temporary workaround. In the future, this will be removed and
     * get_image() will be the only way to access the cache. See CoverartCache for more
     * information.
     */
    [Deprecated (since = "1.1", replacement = "Noise.MediaArtCache.get_image")]
    protected Gdk.Pixbuf? get_image_from_key (string key) {
        return pixbuf_cache.get_image (key);
    }

    /**
     * @return null if the object's corresponding image was not found; otherwise
     * a valid {@link Gdk.Pixbuf}
     */
    protected async Gdk.Pixbuf? get_image_async (T object, bool lookup_file) {
        return yield pixbuf_cache.get_image_async (get_key (object), lookup_file);
    }

    /**
     * @return A {@link Gdk.Pixbuf} representing the image as it appears in the file cache.
     *         That is a version of the image not affected by {@link Noise.MediaArtCache.filter_func}.
     */

    public virtual async Gdk.Pixbuf? get_original_image_async (T object, int width, int height,
                                                               bool preserve_aspect_ratio,
                                                               Cancellable? cancellable = null) {
        var file = get_cached_image_file (object);
        
        if (file != null) {
            try {
                return yield PixbufUtils.get_pixbuf_from_file_at_scale_async (file, width, height,
                                                                              preserve_aspect_ratio,
                                                                              cancellable);
            } catch (Error err) {
                warning ("Could not get image from file [%s]: %s", file.get_uri (), err.message);
            }
        }
        return null;
    }

    /**
     * Notifies about changes in the cache.
     *
     * We use a low priority to avoid emitting the changed() signal many times.
     * Instead, we want to notify in a batch.
     */
    protected void queue_notify () {
        if (notify_queued)
            return;

        changed ();
        notify_queued = false;
    }
}
