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
 * A thread-safe place to store cached pixbufs
 *
 * Pixbuf images are permanently stored at the directory passed to the constructor,
 * and use JPEG buffers by default, since they are much lighter in terms of
 * resource usage and rendering time, while offering acceptable quality. A
 * different image format can be specified at construct-time too.
 *
 * When saving changes to the cache directory, a MD5-based name is used, which
 * is in turn computed from the image's key. This often works better than escaping
 * (and later unescaping) paths, and lets us have tighter control over the image
 * format used, since it's encoded along with the image name.
 *
 * Keep in mind that both cache_image_*() and decache_image() do blocking I/O,
 * and therefore it's recommended to make extensive use of has_image() prior to
 * calling these in order to avoid unnecessary disk access.
 *
 * This class is meant to be kept as generic as possible. It currently does not
 * depend on Noise's internal API (except for PixbufUtils, which is also considered
 * to be generic). It should be easy to re-use it on another application.
 */
public class Noise.PixbufCache {

    /**
     * Supported image's content types.
     */
    public const string[] IMAGE_TYPES = {
        "image/jpeg",
        "image/png",
        "image/tiff"
    };

    public Gee.Map<string, Gdk.Pixbuf> images {
        owned get { return image_map.read_only_view; }
    }

    public Gdk.PixbufFormat image_format { get; private set; }

    private const string DEFAULT_FORMAT_NAME = "jpeg";
    private File image_dir;
    private Gee.HashMap<string, Gdk.Pixbuf> image_map;

    /**
     * Creates a new {@link Noise.PixbufCache} object.
     * It also creates the cache directory if it doesn't exist, and thus expect blocking I/O.
     *
     * @param image_dir a {@link GLib.File} representing the cache directory.
     * @param image_format a string specifying the image format, or null to use the default
     * format (JPEG). Valid image formats are those supported by {@link Gdk.Pixbuf.save}.
     */
    public PixbufCache (File image_dir, Gdk.PixbufFormat? image_format = null) {
        if (image_format == null) {
            foreach (var format in Gdk.Pixbuf.get_formats ()) {
                if (format.get_name () == DEFAULT_FORMAT_NAME) {
                    this.image_format = format;
                    break;
                }
            }
        } else {
            this.image_format = image_format;
        }

        // We need to be able to write images to disk for permanent storage
        assert (this.image_format != null && this.image_format.is_writable ());

        this.image_dir = image_dir;

        try {
            image_dir.make_directory_with_parents (null);
        } catch (Error err) {
            if (!(err is IOError.EXISTS))
                warning ("Could not create image cache directory: %s", err.message);
        }

        image_map = new Gee.HashMap<string, Gdk.Pixbuf> ();
    }

    /**
     * This method is called right before storing a pixbuf in the internal hashmap.
     * Its purpose is to allow client code to make modifications to the passed image
     * (e.g. adding a drop shadow, etc.) Changes are *not* reflected on disk.
     *
     * You can also use this method to prevent the storage of certain images in
     * the cache. To do so it just needs to set the new pixbuf to null. In such case,
     * the call to {@link Noise.PixbufCache.cache_image} will have no effect, since
     * null pixbufs are not added to the internal map, nor saved to disk.
     */
    public delegate Gdk.Pixbuf? FilterFunction (string key, Gdk.Pixbuf orig_pixbuf);
    public unowned FilterFunction? filter_func;

    /**
     * Verifies whether the key has a corresponding image in the cache.
     */
    public bool has_image (string key) {
        return image_map.has_key (key);
    }

    /**
     * Returns a file representing the key's image on disk. This call does no blocking I/O.
     * Use it to consistently read cached image files. Pixbuf cache uses it internally
     * to save the images.
     *
     * This method only creates a file based on the passed key, and thus it doesn't
     * know whether the file it points to exists or not. It is recommended to pair
     * calls to {@link Noise.PixbufCache.has_image} to check for that.
     */
    public File get_cached_image_file (string key) {
        var builder = new StringBuilder ();
        builder.append (key);
        builder.append (image_format.get_name ());
        string filename = Checksum.compute_for_string (ChecksumType.MD5, builder.str);
        return image_dir.get_child (filename);
    }

    /**
     * Removes the image corresponding to the key from the table. It also deletes
     * the associated file from the cache directory.
     */
    public Gdk.Pixbuf? decache_image (string key) {
        Gdk.Pixbuf? val;

        lock (image_map) {
            image_map.unset (key, out val);
            delete_file (get_cached_image_file (key));
        }

        return val;
    }

    /**
     * Associates an image to a key.
     *
     * The image is stored on an internal table and on disk, and can be later
     * retrieved through {@link Noise.PixbufCache.get_image}.
     *
     * This method can also be used to update image buffers when they have changed,
     * since the old image is overwritten (in both primary memory and disk.)
     */
    public async void cache_image_async (string key, Gdk.Pixbuf image) {
        yield cache_image_internal_async (key, image, true);
    }

    /**
     * This method does the same as {@link Noise.PixbufCache.cache_image}, with the only
     * difference that it first fetches the image from the given file.
     */
    public async void cache_image_from_file_async (string key, File image_file, Cancellable? c = null) {
        var image = yield load_image_from_file_async (image_file, c);
        if (image != null)
            yield cache_image_async (key, image);
    }

    /**
     * Retrieves the image for the given key from the cache.
     *
     * @return A valid {@link Gdk.Pixbuf}, or null if the image is not found.
     */
    public Gdk.Pixbuf? get_image (string key) {
        return image_map.get (key);
    }

    /**
     * Retrieves the image for the given key from the cache. If lookup_file
     * is true, it attempts to load the image from the disk cache in case
     * it wasn't found in the table. The lookup_file parameter provides an
     * efficient way to initialize the cache, since -when set to true-, files
     * are retrieved from disk as they are needed.
     *
     * @return null if the key's corresponding image was not found; Otherwise
     *         a valid {@link Gdk.Pixbuf}
     */
    public async Gdk.Pixbuf? get_image_async (string key, bool lookup_file = true) {
        if (lookup_file && !has_image (key)) {
            var image_file = get_cached_image_file (key);
            var image = yield load_image_from_file_async (image_file, null);
            if (image != null)
                yield cache_image_internal_async (key, image, false);
        }

        return image_map.get (key);
    }

    /**
     * Adds an image to the hash map and also writes the image to disk if save_to_disk is true.
     */
    private async void cache_image_internal_async (string key, Gdk.Pixbuf image, bool save_to_disk) {
        Gdk.Pixbuf? modified_image = (filter_func != null) ? filter_func (key, image) : image;

        if (modified_image != null) {
            lock (image_map) {
                image_map.set (key, modified_image);

                // We store the unmodified image. Otherwise modifications would be applied over and
                // over again every time the images are retrieved from disk.
                if (save_to_disk)
                    save_image_to_file.begin (key, image);
            }
        }
    }

    /**
     * Central place for retrieving images from permanent-storage locations. This is not
     * limited to this cache's local directory.
     */
    private async Gdk.Pixbuf? load_image_from_file_async (File image_file, Cancellable? cancellable) {
        Gdk.Pixbuf? image = null;

        try {
            image = yield PixbufUtils.get_pixbuf_from_file_async (image_file, cancellable);
        } catch (Error err) {
            debug ("Could not get image from file [%s]: %s", image_file.get_uri (), err.message);
        }

        return image;
    }

    /**
     * Stores a pixbuf in the cache directory. Not thread-safe
     */
    private async void save_image_to_file (string key, Gdk.Pixbuf to_save) {
        debug ("Saving cached image for: %s", key);

        try {
            var dest_file = get_cached_image_file (key);
            if (delete_file (dest_file))
                yield PixbufUtils.save_pixbuf_async (to_save, dest_file ,image_format.get_name ());
        } catch (Error err) {
            warning ("Could not save pixbuf: %s", err.message);
        }
    }

    /**
     * Deletes a file.
     
     * It silently fails in case the file doesn't exist. Not thread-safe.
     *
     * @return true in case the image was deleted or doesn't exist; false otherwise.
     */
    private bool delete_file (File file) {
        try {
            file.delete ();
        } catch (Error err) {
            if (err is IOError.NOT_FOUND) {
                debug (err.message);
            } else {
                warning ("Could not delete image: %s", err.message);
                return false;
            }
        }

        return true;
    }
}
