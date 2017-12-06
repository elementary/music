// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012-2017 elementary LLC. (https://elementary.io)
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
 * Authored by: Victor Eduardo <victoreduardm@gmail.com>
 */

/**
 * An Icon Object
 *
 * Icon objects point to icon files or generic icon names. The API provides convenience
 * methods for rendering the icon to a {@link Gdk.Pixbuf} image or {@link Gtk.Image} widgets.
 *
 * The icon is searched in the available icon themes.
 */
public class Noise.Icon : Object {
    private static Gtk.IconTheme? _theme;
    public static Gtk.IconTheme theme {
        get {
            if (_theme == null) {
                _theme = Gtk.IconTheme.get_default ();
            }

            return _theme;
        }
    }

    public string? name { get; private set; }
    public GLib.Icon gicon { get; private set; }

    /**
     * Creates a new icon object.
     *
     * @param name The icon name (without filename extension), to be loaded from
     * the available icon themes.
     */
    public Icon (string name) {
        this.name = name;
        gicon = new ThemedIcon (this.name);
    }

    public Gtk.IconInfo? get_icon_info (int size) {
        return theme.lookup_by_gicon (gicon, size, Gtk.IconLookupFlags.USE_BUILTIN);
    }

    /**
     * Returns a file representing the icon in the filesystem.
     * @param size Icon size to query.
     * @return A {@link GLib.File} representing the icon, or //null// if none is found.
     */
    public File? get_file (int size = 16) {
        var info = get_icon_info (size);
        return info != null ? File.new_for_path (info.get_filename ()) : null;
    }

    /**
     * Creates a new {@link Gdk.Pixbuf} from the icon at the specified icon size.
     *
     * @param size The pixbuf's icon size.
     * @param style_context The style context used to render the icon, or null to use none.
     * @return a newly-created Gdk.Pixbuf displaying the icon (or a "missing-image" icon)
     */
    public Gdk.Pixbuf? render (Gtk.IconSize size, Gtk.StyleContext? style_context = null) {
        int width, height;
        Gtk.icon_size_lookup (size, out width, out height);
        int pixel_size = int.max (width, height);
        Gdk.Pixbuf? rv = null;

        try {
            var icon_info = get_icon_info (pixel_size);

            if (icon_info != null) {
                if (style_context != null) {
                    rv = icon_info.load_symbolic_for_context (style_context);
                } else {
                    rv = icon_info.load_icon ();
                }
            }

            // If we failed at loading the icon, try to load the default "missing-image"
            if (rv == null) {
                warning ("Icon not found: %s", name);
                rv = theme.load_icon ("image-missing", pixel_size, Gtk.IconLookupFlags.GENERIC_FALLBACK);
            }
        } catch (Error err) {
            warning ("Could not load icon [%s]: %s", name, err.message);
        }

        return rv;
    }
}
