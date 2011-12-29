/*-
 * Copyright (c) 2011	   Scott Ringwelski <sgringwe@mtu.edu>
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

	public string name;
	public string? backup;
	public int? size;
	public IconType? type;
	public IconFileType? file_type;

	public Icon (string name, int? size, IconType? type, IconFileType? file_type, bool create_backup) {

		this.name = name;
		this.size = size;
		this.type = type;
		this.file_type = file_type;

		/**
		 * The following code creates a backup string for the icon.
		 * This ensures consistency in the way we store icons in the
		 * 'images' folder.
		 **/

		if (create_backup && this.type != null && this.size != null) {
			string size_folder, type_folder, actual_icon_name;
			
			if (this.size != null)
				size_folder = this.size.to_string() + "x" + this.size.to_string();
			else
				size_folder = "";

			switch (this.type)
	 		{
	 			case IconType.MIMETYPE:
	 				type_folder = "mimetypes";
	 				break;
	 			case IconType.ACTION:
	 				type_folder = "actions";
	 				break;
	 			case IconType.STATUS:
	 				type_folder = "status";
	 				break;
	 			case IconType.APP:
	 				type_folder = "apps";
	 				break;
	 			default:
	 				type_folder = "";
	 				break;
	 		}

			if (this.file_type != null) {
				switch (this.file_type)
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
				actual_icon_name = this.name + ".svg";
			}

			this.backup = GLib.Path.build_filename("/", Build.ICON_FOLDER, "hicolor", size_folder, type_folder, actual_icon_name);
		}
		else {
			this.backup = null;
		}
	}

	public Gdk.Pixbuf? render (Gtk.IconSize? size, StyleContext? context) {
		bool is_symbolic = this.name.contains ("-symbolic");

		Gdk.Pixbuf? rv = null;

		int width = 16, height = 16;

		if (this.size != null) {
			width = this.size;
			height = this.size;			
		}

		if (size != null)
			icon_size_lookup (size, out width, out height);

		if (IconTheme.get_default().has_icon(this.name)) {
			try {
				rv = IconTheme.get_default().load_icon(this.name, width, IconLookupFlags.GENERIC_FALLBACK);
			}
			catch (Error err) {
				stderr.printf("Default theme does not have icon for '%s', falling back to BeatBox default.\n", this.name);
			}
		}

		if (rv == null && this.backup != null) {
			try {
				rv = new Gdk.Pixbuf.from_file_at_size (this.backup, width, height);
			}
			catch (Error err) {
				stderr.printf("Couldn't load backup icon for '%s'\n", this.name);
			}
		}

		if (rv != null && is_symbolic && context != null) {
			try {
				var themed_icon = new GLib.ThemedIcon.with_default_fallbacks (this.name);
				var icon_info = IconTheme.get_default ().lookup_by_gicon (themed_icon as GLib.Icon, width, Gtk.IconLookupFlags.GENERIC_FALLBACK);
				rv = icon_info.load_symbolic_for_context (context);
			}
			catch (Error err) {
				stderr.printf ("\nCould not load symbolic icon: %s\n", this.name);
			}
		}

		return rv;
	}
}

public class BeatBox.Icons : GLib.Object {
	LibraryManager lm;
	LibraryWindow lw;

	public Icon default_album_art;
	public Icon drop_album;

	public Icon beatbox_icon;
	public Icon now_playing_icon;
	public Icon music_icon;
	public Icon podcast_icon;
	public Icon audiobook_icon;
	public Icon history_icon;
	public Icon playlist_icon;
	public Icon smart_playlist_icon;
	public Icon lastfm_love_icon;
	public Icon lastfm_ban_icon;
	public Icon starred_icon;
	public Icon not_starred_icon;
	public Icon info_icon;
	
	public Icon process_stop_icon;

	/** Symbolic icons **/
	public Icon process_completed_icon;
	public Icon process_error_icon;
	public Icon shuffle_on_icon;
	public Icon shuffle_off_icon;
	public Icon repeat_on_icon;
	public Icon repeat_off_icon;
	public Icon view_column_icon;
	public Icon view_details_icon;
	public Icon view_icons_icon;
	public Icon view_video_icon;

	public Icons (LibraryManager lm, LibraryWindow lw) {
		this.lm = lm;
		this.lw = lw;
	}

	public void load_icons () {

		default_album_art = new Icon ("media-audio", 128, Icon.IconType.MIMETYPE, Icon.IconFileType.PNG, true);
		drop_album = new Icon ("drop-album", 128, Icon.IconType.MIMETYPE, null, true);
		beatbox_icon = new Icon ("beatbox", 16, Icon.IconType.APP, null, true);
		now_playing_icon = new Icon ("audio-volume-high", 16, Icon.IconType.MIMETYPE, null, true);
		music_icon = new Icon ("library-music", 16, Icon.IconType.MIMETYPE, null, true);
		podcast_icon = new Icon ("library-podcast", 16, Icon.IconType.MIMETYPE, null, true);
		//audiobook_icon = new Icon ("library-audiobook", 16, Icon.IconType.MIMETYPE, null, true);
		history_icon = new Icon ("document-open-recent", 22, Icon.IconType.ACTION, null, true);
		playlist_icon = new Icon ("playlist", 22, Icon.IconType.MIMETYPE, null, true);
		smart_playlist_icon = new Icon ("playlist-automatic", 22, Icon.IconType.MIMETYPE, null, true);
		lastfm_love_icon = new Icon ("lastfm-love", 16, Icon.IconType.ACTION, null, true);
		lastfm_ban_icon = new Icon ("lastfm-ban", 16, Icon.IconType.ACTION, null, true);
		starred_icon = new Icon ("starred", 16, Icon.IconType.STATUS, null, true);
		not_starred_icon = new Icon ("not-starred", 16, Icon.IconType.STATUS, null, true);
		process_completed_icon = new Icon ("process-completed-symbolic", 16, Icon.IconType.STATUS, null, true);
		process_error_icon = new Icon ("process-error-symbolic", 16, Icon.IconType.STATUS, null, true);

		info_icon = new Icon (Gtk.Stock.INFO, 16, null, null, false);

		/** SYMBOLIC ICONS **/

		process_stop_icon = new Icon ("process-stop-symbolic", 16, Icon.IconType.ACTION, null, true);

		shuffle_on_icon = new Icon ("media-playlist-shuffle-symbolic", 16, Icon.IconType.STATUS, null, true);
		shuffle_off_icon = new Icon ("media-playlist-no-shuffle-symbolic", 16, Icon.IconType.STATUS, null, true);
		repeat_on_icon = new Icon ("media-playlist-repeat-symbolic", 16, Icon.IconType.STATUS, null, true);
		repeat_off_icon = new Icon ("media-playlist-no-repeat-symbolic", 16, Icon.IconType.STATUS, null, true);

		view_column_icon = new Icon ("view-list-column-symbolic", 16, Icon.IconType.ACTION, null, true);
		view_details_icon =new Icon ("view-list-details-symbolic", 16, Icon.IconType.ACTION, null, true);
		view_icons_icon = new Icon ("view-list-icons-symbolic", 16, Icon.IconType.ACTION, null, true);
		view_video_icon = new Icon ("view-list-video-symbolic", 16, Icon.IconType.ACTION, null, true);
	}
}

