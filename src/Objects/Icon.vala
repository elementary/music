/*-
 * Copyright (c) 2011-2012		Scott Ringwelski <sgringwe@mtu.edu>
 *
 * Originally Written by Scott Ringwelski and Victor Eduardo for
 * BeatBox Music Player: http://www.launchpad.net/beat-box
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
 */

using Gtk;

public class BeatBox.Icon : GLib.Object {

	public string name {get; private set;}

	public bool has_backup {
		get {
			return (this.backup != null);
		}
	}

	private string? backup;
	private int? size;
	private Icons.Type? type;
	private Icons.FileType? file_type;

	public Icon (string name, int? size, Icons.Type? type, Icons.FileType? file_type, bool has_backup) {

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
				case Icons.Type.MIMETYPE:
					type_folder = Icons.MIMETYPES_FOLDER;
					break;
				case Icons.Type.ACTION:
					type_folder = Icons.ACTIONS_FOLDER;
					break;
				case Icons.Type.STATUS:
					type_folder = Icons.STATUS_FOLDER;
					break;
				case Icons.Type.APP:
					type_folder = Icons.APPS_FOLDER;
					break;
				default:
					type_folder = "";
					break;
			}

			if (file_type != null) {
				switch (file_type)
				{
					case Icons.FileType.SVG:
						actual_icon_name = this.name + Icons.SVG_EXT;
						break;
					case Icons.FileType.PNG:
						actual_icon_name = this.name + Icons.PNG_EXT;
						break;
					default:
						actual_icon_name = this.name + Icons.SVG_EXT;
						break;
				}
			}
			else {
				actual_icon_name = name + Icons.SVG_EXT;
			}

			var icon_path = GLib.Path.build_path("/", Build.ICON_FOLDER, size_folder, type_folder);
			IconTheme.get_default().append_search_path (icon_path);
			this.backup = GLib.Path.build_filename("/", Build.ICON_FOLDER, size_folder, type_folder, actual_icon_name);
		}
		else {
			this.backup = null;
		}
	}

	public GLib.Icon get_gicon () {
		return new GLib.ThemedIcon.with_default_fallbacks (this.name);
	}

	public Gtk.IconInfo? get_icon_info (int size) {
		var icon_theme = IconTheme.get_default();
		var lookup_flags = Gtk.IconLookupFlags.GENERIC_FALLBACK;
		return icon_theme.lookup_by_gicon (get_gicon(), size, lookup_flags);
	}

	public Gdk.Pixbuf? render (Gtk.IconSize? size, StyleContext? context = null, int px_size = 0) {
		Gdk.Pixbuf? rv = null;
		int width = 16, height = 16;

		// Don't load image as a regular icon if it's a PNG and belongs
		// to the project's folder.
		if (file_type == Icons.FileType.PNG && backup != null && size == null) {
			try {
				rv = new Gdk.Pixbuf.from_file(backup);
			}
			catch(Error err) {
				message ("Could not load PNG image: %s\n", err.message);
			}

			return rv;
		}

		// If a null size was passed, use original size
		if (size != null) {
			icon_size_lookup (size, out width, out height);
		}
		else if (px_size > 0) {
			width = px_size;
			height = px_size;
		}
		else if (this.size != null) {
			width = this.size;
			height = width;
		}

		// Try to load icon from theme
		if (IconTheme.get_default().has_icon(this.name)) {
			try {
				var icon_info = get_icon_info (height);
				if (icon_info != null) {
					if (context != null)
						rv = icon_info.load_symbolic_for_context (context);
					else
						rv = icon_info.load_icon ();
				}
			}
			catch (Error err) {
				message ("%s, falling back to BeatBox default.", err.message);
			}
		}

		// If the above failed, use available backup
		if (rv == null && this.backup != null) {
			try {
				message ("Loading backup icon for %s", this.name);
				rv = new Gdk.Pixbuf.from_file_at_size (this.backup, width, height);
			}
			catch (Error err) {
				message ("Couldn't load backup icon: %s", err.message);
			}
		}

		return rv;
	}

	/**
	 * Use this method for loading symbolic icons. They will follow every state.
	 **/
	public Gtk.Image? render_image (Gtk.IconSize? size, Gtk.StyleContext? ctx = null, int px_size = 0) {
		Gtk.Image? rv = null;
		int width = 16, height = 16;

		// If a null size was passed, use original size
		if (size != null) {
			icon_size_lookup (size, out width, out height);
		}
		else if (px_size > 0) {
			width = px_size;
			height = px_size;
		}
		else if (this.size != null) {
			width = this.size;
			height = width;
		}

		if (IconTheme.get_default().has_icon (this.name) && size != null) {
			// Try to load icon from theme
			rv = new Image.from_icon_name (this.name, size);
		} else if (this.backup != null) {
			// If the icon theme doesn't contain the icon, load backup
			message ("Loading %s from backup", this.name);
			rv = new Image.from_file (this.backup);
		} else {
			// And if there was no backup, use the default method
			message ("Loading %s using default method", this.name);
			rv = new Image.from_pixbuf (this.render (size, ctx));
		}

		// Resize image if necessary
		if (rv.get_pixel_size () != height)
			rv.set_pixel_size (height);

		return rv;
	}
}

