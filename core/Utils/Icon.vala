// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012-2013 Noise Developers (http://launchpad.net/noise)
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
 * An Icon Object
 *
 * Icon objects point to icon files or generic icon names. The API provides convenience
 * methods for rendering the icon to a {@link Gdk.Pixbuf} image or {@link Gtk.Image} widgets.
 *
 * When an icon points to an absolute path (e.g. /usr/share/noise/icons/default-cover-art.png),
 * the image is loaded from that specific file and not from any icon theme. Otherwise, the icon
 * is searched in the available icon themes. Please note though that it's not necessary to pass
 * an absolute path in order to get backup icon (i.e. icons shipped along with the application)
 * support, since the application's icon path is also queried when looking up for named icons,
 * which means that shipping a backup icon file and installing it to a sub-directory named "hicolor"
 * is enough for making sure that the icon will always be available/found. For instance:
 *
 * {{{
 * // To provide a fallback, simply install a fallback icon. e.g. ${NOISE_ICON_DIR}/hicolor/starred.svg
 * var icon = new Noise.Icon ("starred");
 *
 * // Supposing the icon was not found in any icon theme, the fallback icon file will be used instead,
 * // so this operation will never fail.
 * icon.render (Gtk.IconSize.MENU);
 * }}}
 *
 * This class is actually a wrapper around {@link GLib.Icon} that allows easy backup-icon management.
 */
public class Noise.Icon : Object {

    private static Gtk.IconTheme? _theme;
    public static Gtk.IconTheme theme {
        get {
            if (_theme == null) {
                _theme = Gtk.IconTheme.get_default ();

                // This only works if Build.ICON_DIR contains a sub-directory named "hicolor"
                // containing all the fallback icons (possibly organized into sub-folders as well),
                // or if the icons are immediate children of this directory.
                _theme.append_search_path (Path.build_filename (Build.ICON_DIR));
            }

            return _theme;
        }
    }

    /**
     * The name of the icon, as passed to the constructor. If the icon points to an absolute
     * file name, this will return null.
     */
    public string? name { get; private set; }

    /**
     * The absolute file name of the icon, as passed to the constructor. If the icon points to
     * an icon name instead, this will return null.
     */
    public string? file_name { get; private set; }

    /**
     * The {@link GLib.Icon} representing the icon.
     */
    public GLib.Icon gicon { get; private set; }


    /**
     * Creates a new icon object.
     *
     * @param file_name A filename pointing to the icon file. If it is an absolute file name,
     * the icon will be loaded from the file it points to; otherwise, it is assumed that the
     * string only specifies the icon name (without filename extension), and it will be loaded from
     * the available icon themes.
     */
    public Icon (string file_name) {
        if (Path.is_absolute (file_name)) {
            this.file_name = file_name;
            gicon = new FileIcon (File.new_for_path (this.file_name));
        } else {
            this.name = file_name;
            gicon = new ThemedIcon (this.name); // no need for ugly generic fallbacks
        }
    }


    public Gtk.IconInfo? get_icon_info (int size) {
        return theme.lookup_by_gicon (gicon, size, Gtk.IconLookupFlags.USE_BUILTIN);
    }

    /**
     * Returns a file representing the icon in the filesystem. If this icon represents a
     * file, it returns a file at a location equivalent to {@link Noise.Icon.file_name}.
     * Otherwise, a file pointing to the image in the icon theme is returned.
     *
     * @param size Icon size to query.
     * @return A {@link GLib.File} representing the icon, or //null// if none is found.
     */
    public File? get_file (int size = 16) {
        if (gicon is FileIcon)
            return (gicon as FileIcon).file;

        var info = get_icon_info (size);
        return info != null ? File.new_for_path (info.get_filename ()) : null;
    }

    /**
     * Creates a new {@link Gdk.Pixbuf} from the icon at the specified icon size.
     *
     * @param size The pixbuf's icon size.
     * @param style_context The style context used to render the icon, or null to use none.
     * @return a newly-created Gdk.Pixbuf displaying the icon (or a "missing-image" icon)
     * @see Noise.Icon.render_at_size
     */
    public Gdk.Pixbuf? render (Gtk.IconSize size, Gtk.StyleContext? style_context = null) {
        int width, height;
        Gtk.icon_size_lookup (size, out width, out height);
        return render_at_size (int.max (width, height), style_context);
    }


    /**
     * Creates a new {@link Gdk.Pixbuf} from the icon at the specified pixel size.
     *
     * @param pixel_size The pixbuf's pixel size.
     * @param style_context The style context used to render the icon, or null to use none.
     * @return a newly-created Gdk.Pixbuf displaying the icon (or a "missing-image" icon)
     * @see Noise.Icon.render
     */
    public Gdk.Pixbuf? render_at_size (int pixel_size, Gtk.StyleContext? style_context = null) {
        Gdk.Pixbuf? rv = null;

        try {
            var icon_info = get_icon_info (pixel_size);

            if (icon_info != null) {
                if (style_context != null)
                    rv = icon_info.load_symbolic_for_context (style_context);
                else
                    rv = icon_info.load_icon ();
            }

            // If we failed at loading the icon, try to load the default "missing-image"
            if (rv == null) {
                warning ("Icon not found: %s", file_name ?? name);
                rv = theme.load_icon ("image-missing", pixel_size,
                                      Gtk.IconLookupFlags.GENERIC_FALLBACK);
            }
        } catch (Error err) {
            warning ("Could not load icon [%s]: %s", file_name ?? name, err.message);
        }

        return rv;
    }


    /**
     * Creates a new {@link Gtk.Image} displaying the icon at the specified size.
     *
     * @param size The image's icon size.
     * @return a newly-created Gtk.Image.
     * @see Noise.Icon.render_image_at_size
     */
    public Gtk.Image render_image (Gtk.IconSize size) {
        Gtk.Image image;
        if (name != null)
            image = new Gtk.Image.from_icon_name (name, size);
        else
            image = new Gtk.Image.from_gicon (gicon, size);
        return image;
    }


    /**
     * Creates a new {@link Gtk.Image} displaying the icon at the specified pixel size.
     *
     * @param pixel_size The image's pixel size.
     * @return a newly-created Gtk.Image.
     * @see Noise.Icon.render_image
     */
    public Gtk.Image render_image_at_size (int pixel_size) {
        var rv = render_image (Gtk.IconSize.MENU);
        rv.set_pixel_size (pixel_size);
        return rv;
    }
}
