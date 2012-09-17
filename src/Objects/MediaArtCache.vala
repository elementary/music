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
    protected abstract string get_key (Media m);


    /**
     * This function is called before storing a pixbuf in the cache, allowing
     * to transform it.
     *
     * @see Noise.PixbufCache.filter_func
     */
    protected abstract Gdk.Pixbuf? filter_func (Gdk.Pixbuf pix);


    /**
     * Verifies whether the media object m has a corresponding image in the cache.
     *
     * @see Noise.PixbufCache.has_image
     */
    public bool has_image (Media m) {
        return pixbuf_cache.has_image (get_key (m));
    }


    /**
     * Returns the location of the media's image on disk. This call does no blocking I/O.
     * A path is returned even if there's no associated image in the cache (i.e. the file
     * pointed by the path doesn't exist).
     * Since there is no guarantee that the returned path will be valid, don't write code
     * that crashes if it isn't. You can call has_image() to verify the existance of the
     * image, and it will reliably help to avoid errors most of the time (under normal
     * conditions, where every cached image has an associated file and there is no race
     * between threads).
     */
    public string get_cached_image_path_for_media (Media m) {
        return get_cached_image_path (get_key (m));
    }


    /**
     * Returns the location of the image on disk. This call does no blocking I/O.
     *
     * @see Noise.PixbufCache.get_cached_image_path
     */
    protected string get_cached_image_path (string key) {
        return pixbuf_cache.get_cached_image_path (key);
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
