/*-
 * Copyright (c) 2011		Scott Ringwelski <sgringwe@mtu.edu>
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

	public enum IconType {
		MIMETYPE,
		ACTION,
		STATUS,
		APP
	}

	public enum IconFileType {
		SVG,
		PNG
	}

	public string icon_name {
		get {
			return this.name;
		}
	}

	public bool has_backup {
		get {
			return (this.backup != null);
		}
	}

	private const string MIMETYPES_FOLDER = "mimetypes";
	private const string ACTIONS_FOLDER = "actions";
	private const string STATUS_FOLDER = "status";
	private const string APPS_FOLDER = "apps";

	private string name;
	private string? backup;
	private int? size;
	private IconType? type;
	private IconFileType? file_type;

	public Icon (string name, int? size, IconType? type, IconFileType? file_type, bool has_backup) {

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
				case IconType.MIMETYPE:
					type_folder = MIMETYPES_FOLDER;
					break;
				case IconType.ACTION:
					type_folder = ACTIONS_FOLDER;
					break;
				case IconType.STATUS:
					type_folder = STATUS_FOLDER;
					break;
				case IconType.APP:
					type_folder = APPS_FOLDER;
					break;
				default:
					type_folder = "";
					break;
			}

			if (file_type != null) {
				switch (file_type)
				{
					case IconFileType.SVG:
						actual_icon_name = this.name + ".svg";
						break;
					case IconFileType.PNG:
						actual_icon_name = this.name + ".png";
						break;
					default:
						actual_icon_name = this.name + ".svg";
						break;
				}
			}
			else {
				actual_icon_name = name + ".svg";
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

	public Gdk.Pixbuf? render (Gtk.IconSize? size, StyleContext? context) {
		Gdk.Pixbuf? rv = null;
		int width = 16, height = 16;

		// Don't load the image as a regular icon if it's a PNG and belongs
		// to the project's folder.
		if (file_type == IconFileType.PNG && backup != null && size == null) {
			try {
				warning ("Loading unscaled PNG image: %s", this.name);
				rv = new Gdk.Pixbuf.from_file(backup);
			}
			catch(Error err) {
				critical ("Could not load PNG image: %s\n", err.message);
			}

			return rv;
		}

		// If a null size was passed, use the original size
		if (size != null) {
			icon_size_lookup (size, out width, out height);
		}
		else if (this.size != null) {
			width = this.size;
			height = this.size;
		}

		// Try to load the icon from the icon theme
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
				warning ("%s, falling back to BeatBox default.", err.message);
			}
		}

		// If the above failed, use the available backup
		if (rv == null && this.backup != null) {
			try {
				warning ("Loading backup icon for %s", this.name);
				rv = new Gdk.Pixbuf.from_file_at_size (this.backup, width, height);
			}
			catch (Error err) {
				warning ("Couldn't load backup icon: %s", err.message);
			}
		}

		return rv;
	}

	/**
	 * Use this method for loading symbolic icons. They will follow every state.
	 **/
	public Gtk.Image? render_image (Gtk.IconSize? size, Gtk.StyleContext? ctx = null) {
		Gtk.Image? rv = null;
		int width = 16, height = 16;

		// If a null size was passed, use the original size
		if (size != null) {
			icon_size_lookup (size, out width, out height);
		}
		else if (this.size != null) {
			width = this.size;
			height = this.size;
		}

		if (IconTheme.get_default().has_icon (this.name) && size != null) {
			// Try to load the icon from the icon theme
			rv = new Image.from_icon_name (this.name, size);
		} else if (this.backup != null) {
			// If the icon theme doesn't contain the icon, load backup
			warning ("Loading %s from backup", this.name);
			rv = new Image.from_file (this.backup);
		} else {
			// And if there was no backup, use the default method
			warning ("Loading %s using default method", this.name);
			rv = new Image.from_pixbuf (this.render (size, ctx));
		}

		// Resize the image
		if (rv.get_pixel_size () != height)
			rv.set_pixel_size (height);

		return rv;
	}
}

public class BeatBox.Icons : GLib.Object {
	LibraryManager lm;
	LibraryWindow lw;

	/* TODO: CAPITALIZE icon names */

	public Icon default_album_art;
	public Icon DROP_ALBUM;

	public Icon music_folder;

	public Icon beatbox_icon;
	public Icon radio_icon;
	public Icon music_icon;
	public Icon podcast_icon;
	public Icon audiobook_icon;
	public Icon AUDIO_CD_ICON;
	public Icon history_icon;
	public Icon playlist_icon;
	public Icon smart_playlist_icon;
	public Icon lastfm_love_icon;
	public Icon lastfm_ban_icon;
	public Icon starred_icon;
	public Icon not_starred_icon;
	public Icon INFO_ICON;
	public Icon new_podcast_icon;

	/** Symbolic icons **/
	public Icon now_playing_icon;
	public Icon process_stop_icon;
	public Icon process_completed_icon;
	public Icon process_error_icon;
	public Icon SHUFFLE_ON_ICON;
	public Icon SHUFFLE_OFF_ICON;
	public Icon REPEAT_ON_ICON;
	public Icon REPEAT_ONCE_ICON;
	public Icon REPEAT_OFF_ICON;

	public Icon VIEW_COLUMN_ICON;
	public Icon VIEW_DETAILS_ICON;
	public Icon VIEW_ICONS_ICON;
	public Icon VIEW_VIDEO_ICON;

	public Icons (LibraryManager lm, LibraryWindow lw) {
		this.lm = lm;
		this.lw = lw;
	}

	public void load_icons () {

		// 128 x 128
		default_album_art = new Icon ("media-audio", 128, Icon.IconType.MIMETYPE, Icon.IconFileType.PNG, true);
		DROP_ALBUM = new Icon ("drop-album", 128, Icon.IconType.MIMETYPE, null, true);
		music_folder = new Icon ("folder-music", 128, Icon.IconType.MIMETYPE, null, true);

		// 22 x 22
		history_icon = new Icon ("document-open-recent", 22, Icon.IconType.ACTION, null, true);

		// 16 x 16
		beatbox_icon = new Icon ("beatbox", 16, Icon.IconType.APP, null, true);
		radio_icon = new Icon ("internet-radio", 16, Icon.IconType.MIMETYPE, null, true);
		music_icon = new Icon ("library-music", 16, Icon.IconType.MIMETYPE, null, true);
		podcast_icon = new Icon ("library-podcast", 16, Icon.IconType.MIMETYPE, null, true);
		//audiobook_icon = new Icon ("library-audiobook", 16, Icon.IconType.MIMETYPE, null, true);
		AUDIO_CD_ICON = new Icon ("media-cdrom-audio", 16, Icon.IconType.MIMETYPE, null, true);
		playlist_icon = new Icon ("playlist", 16, Icon.IconType.MIMETYPE, null, true);
		smart_playlist_icon = new Icon ("playlist-automatic", 16, Icon.IconType.MIMETYPE, null, true);
		lastfm_love_icon = new Icon ("lastfm-love", 16, Icon.IconType.ACTION, null, true);
		lastfm_ban_icon = new Icon ("lastfm-ban", 16, Icon.IconType.ACTION, null, true);
		starred_icon = new Icon ("starred", 16, Icon.IconType.STATUS, null, true);
		not_starred_icon = new Icon ("not-starred", 16, Icon.IconType.STATUS, null, true);
		INFO_ICON = new Icon ("help-info", 16, Icon.IconType.STATUS, null, true);
		new_podcast_icon = new Icon ("podcast-new", 16, Icon.IconType.STATUS, null, true);

		// SYMBOLIC ICONS
		process_completed_icon = new Icon ("process-completed-symbolic", 16, Icon.IconType.STATUS, null, true);
		process_error_icon = new Icon ("process-error-symbolic", 16, Icon.IconType.STATUS, null, true);
		now_playing_icon = new Icon ("audio-volume-high-symbolic", 16, Icon.IconType.STATUS, null, true);
		process_stop_icon = new Icon ("process-stop-symbolic", 16, Icon.IconType.ACTION, null, true);
		SHUFFLE_ON_ICON = new Icon ("media-playlist-shuffle-symbolic", 16, Icon.IconType.STATUS, null, true);
		SHUFFLE_OFF_ICON = new Icon ("media-playlist-no-shuffle-symbolic", 16, Icon.IconType.STATUS, null, true);
		REPEAT_ON_ICON = new Icon ("media-playlist-repeat-symbolic", 16, Icon.IconType.STATUS, null, true);
		REPEAT_ONCE_ICON = new Icon ("media-playlist-repeat-one-symbolic", 16, Icon.IconType.STATUS, null, true);
		REPEAT_OFF_ICON = new Icon ("media-playlist-no-repeat-symbolic", 16, Icon.IconType.STATUS, null, true);
		VIEW_COLUMN_ICON = new Icon ("view-list-column-symbolic", 16, Icon.IconType.ACTION, null, true);
		VIEW_DETAILS_ICON =new Icon ("view-list-details-symbolic", 16, Icon.IconType.ACTION, null, true);
		VIEW_ICONS_ICON = new Icon ("view-list-icons-symbolic", 16, Icon.IconType.ACTION, null, true);
		VIEW_VIDEO_ICON = new Icon ("view-list-video-symbolic", 16, Icon.IconType.ACTION, null, true);
	}

	/**
	 * These methods are useful for rendering non-loaded icons (Stock icons, etc.)
	 **/

	public Gdk.Pixbuf? render_icon (string icon_name, Gtk.IconSize size, Gtk.StyleContext? context = null) {
		var icon = new Icon (icon_name, null, null, null, false);
		return icon.render (size, context);
	}

	public Gtk.Image? render_image (string icon_name, Gtk.IconSize size) {
		var icon = new Icon (icon_name, null, null, null, false);
		return icon.render_image (size);
	}
}

