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
 * Authored by: Scott Ringwelski <sgringwe@mtu.edu>
 *              Victor Eduardo <victoreduardm@gmail.com>
 */

public class Noise.Icon : Object {

    public enum Category {
        MIMETYPE,
        ACTION,
        STATUS,
        APP,
        OTHER
    }

    public enum FileType {
        SVG,
        PNG
    }

    private const string MIMETYPES_FOLDER = "mimetypes";
    private const string ACTIONS_FOLDER = "actions";
    private const string STATUS_FOLDER = "status";
    private const string APPS_FOLDER = "apps";
    private const string OTHER_FOLDER = "other";

    private const string PNG_EXT = ".png";
    private const string SVG_EXT = ".svg";


    public string name { get; private set; }

    public bool has_backup {
        get {
            return (this.backup != null);
        }
    }

    public string backup_filename {
        get {
            if (backup == null)
                return "";

            return backup;
        }
    }

    private string? backup;
    private int? size;
    private Category? type;
    private FileType? file_type;

    /**
     * @param name icon name
     *
     * The following parameters are only necessary if has_backup is true.
     * @param size pixel-size of the backup icon
     * @param type Icon category
     * @param file_type Icon type (SVG or PNG)
     * FIXME deprecate has_backup
     * @param has_backup whether a backup exists or not. It will be deprecated in the future since it's redundant
     */
    public Icon (string name, int? size = 16, Category? type = Category.ACTION, FileType? file_type = FileType.SVG, bool has_backup = false) {

        this.name = name;
        this.size = size;
        this.type = type;
        this.file_type = file_type;

        /**
         * The following code creates a backup path for the icon.
         * This ensures consistency in the way we store icons in the
         * 'images' folder.
         **/
        if (has_backup && type != null && size != null) {
            string size_folder, type_folder, actual_icon_name;

            if (size != null)
                size_folder = size.to_string() + "x" + size.to_string();
            else
                size_folder = "";

            switch (type)
            {
                case Category.MIMETYPE:
                    type_folder = MIMETYPES_FOLDER;
                    break;
                case Category.ACTION:
                    type_folder = ACTIONS_FOLDER;
                    break;
                case Category.STATUS:
                    type_folder = STATUS_FOLDER;
                    break;
                case Category.APP:
                    type_folder = APPS_FOLDER;
                    break;
                default:
                    type_folder = OTHER_FOLDER;
                    break;
            }

            if (file_type != null) {
                switch (file_type)
                {
                    case FileType.SVG:
                        actual_icon_name = this.name + SVG_EXT;
                        break;
                    case FileType.PNG:
                        actual_icon_name = this.name + PNG_EXT;
                        break;
                    default:
                        actual_icon_name = this.name + SVG_EXT;
                        break;
                }
            }
            else {
                actual_icon_name = name + SVG_EXT;
            }

            var icon_path = Path.build_path ("/", Build.ICON_DIR, size_folder, type_folder);
            Gtk.IconTheme.get_default().append_search_path (icon_path);
            this.backup = Path.build_filename ("/", Build.ICON_DIR, size_folder, type_folder, actual_icon_name);
        }
        else {
            this.backup = null;
        }
    }

    public GLib.Icon get_gicon () {
        return new ThemedIcon.with_default_fallbacks (this.name);
    }

    public Gtk.IconInfo? get_icon_info (int size) {
        var icon_theme = Gtk.IconTheme.get_default ();
        var lookup_flags = Gtk.IconLookupFlags.GENERIC_FALLBACK;
        return icon_theme.lookup_by_gicon (get_gicon(), size, lookup_flags);
    }

    public Gdk.Pixbuf? render (Gtk.IconSize? size, Gtk.StyleContext? context = null, int px_size = 0) {
        Gdk.Pixbuf? rv = null;

        // Don't load image as a regular icon if it's a PNG and belongs
        // to the project's folder.
        if (file_type == FileType.PNG && has_backup && size == null) {
            try {
                rv = new Gdk.Pixbuf.from_file (backup);
            } catch (Error err) {
                warning ("Could not load PNG image: %s\n", err.message);
            }

            return rv;
        }

        int pixel_size = get_pixel_size (size, px_size);

        // Try to load icon from theme
        if (Gtk.IconTheme.get_default().has_icon(this.name)) {
            try {
                var icon_info = get_icon_info (pixel_size);

                if (icon_info != null) {
                    if (context != null)
                        rv = icon_info.load_symbolic_for_context (context);
                    else
                        rv = icon_info.load_icon ();
                }
            } catch (Error err) {
                message ("%s, falling back to default.", err.message);
            }
        }

        // If the above failed, use available backup
        if (rv == null && has_backup) {
            try {
                message ("Loading backup icon for %s", this.name);
                rv = new Gdk.Pixbuf.from_file_at_size (this.backup, pixel_size, pixel_size);
            } catch (Error err) {
                warning ("Couldn't load backup icon: %s", err.message);
            }
        }

        return rv;
    }

    /**
     * Use this method for loading symbolic icons. They will follow every state.
     **/
    public Gtk.Image render_image (Gtk.IconSize? size, Gtk.StyleContext? ctx = null, int px_size = 0) {
        var rv = new Gtk.Image ();
        int pixel_size = get_pixel_size (size, px_size);
        rv.set_pixel_size (pixel_size);

        // The passed icon size won't be used since we already set the pixel size above

        if (Gtk.IconTheme.get_default().has_icon (this.name) && size != null) {
            // Try to load icon from theme. 
            rv.set_from_gicon (get_gicon (), Gtk.IconSize.MENU);
        } else if (has_backup) {
            // If the icon theme doesn't contain the icon, load backup
            message ("Loading %s from backup", this.name);
            rv.set_from_file (this.backup);
        } else {
            // And if there was no backup, use the default method
            message ("Loading %s using default method", this.name);
            rv.set_from_pixbuf (this.render (null, ctx, pixel_size));
        }

        return rv;
    }


    public int get_pixel_size (Gtk.IconSize? size, int px_size = 0) {
        int rv = 0;

        // If a null size was passed, use original size
        if (size != null) {
            int dummy_width;
            Gtk.icon_size_lookup (size, out dummy_width, out rv);
        } else if (px_size > 0) {
            rv = px_size;
        } else if (this.size != null) {
            rv = this.size;
        }

        return rv;
    }
}
