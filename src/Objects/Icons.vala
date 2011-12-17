using Gtk;

public class BeatBox.Icons : GLib.Object {
	LibraryManager lm;
	LibraryWindow lw;
	
	public Gdk.Pixbuf default_album_art;
	public Gdk.Pixbuf drop_album;
	
	public Gdk.Pixbuf beatbox_icon;
	public Gdk.Pixbuf now_playing_icon;
	public Gdk.Pixbuf music_icon;
	public Gdk.Pixbuf podcast_icon;
	public Gdk.Pixbuf audiobook_icon;
	public Gdk.Pixbuf playlist_icon;
	public Gdk.Pixbuf smart_playlist_icon;
	public Gdk.Pixbuf lastfm_love_icon;
	public Gdk.Pixbuf lastfm_ban_icon;
	public Gdk.Pixbuf starred_icon;
	public Gdk.Pixbuf not_starred_icon;
	public Gdk.Pixbuf info_icon;
	
	public Gdk.Pixbuf view_column_icon;
	public Gdk.Pixbuf view_details_icon;
	public Gdk.Pixbuf view_icons_icon;
	public Gdk.Pixbuf view_video_icon;
	
	public Gdk.Pixbuf process_completed_icon;
	public Gdk.Pixbuf process_error_icon;
	public Gdk.Pixbuf process_stop_icon;
	
	public Gdk.Pixbuf shuffle_on_icon;
	public Gdk.Pixbuf shuffle_off_icon;
	public Gdk.Pixbuf repeat_on_icon;
	public Gdk.Pixbuf repeat_off_icon;
	
	public Icons(LibraryManager lm, LibraryWindow lw) {
		this.lm = lm;
		this.lw = lw;
	}
	
	public void load_icons() {
		try {
			default_album_art = new Gdk.Pixbuf.from_file(GLib.Path.build_filename("/", Build.ICON_FOLDER, "hicolor", "128x128", "mimetypes", "media-audio.png", null));
		}
		catch(Error err) {
			stdout.printf("Could not load default album art: %s\n", err.message);
		}
		try {
			drop_album = new Gdk.Pixbuf.from_file(GLib.Path.build_filename("/", Build.ICON_FOLDER, "hicolor", "128x128", "mimetypes", "drop-album.svg", null));
		}
		catch(Error err) {
			stdout.printf("Could not load drop album: %s\n", err.message);
		}
		
		beatbox_icon = safe_render_icon("beatbox", IconSize.DIALOG, GLib.Path.build_filename("/", Build.ICON_FOLDER, "hicolor", "16x16", "apps", "beatbox.svg"));
		now_playing_icon = safe_render_icon("audio-volume-high", IconSize.MENU, GLib.Path.build_filename("/", Build.ICON_FOLDER, "hicolor", "22x22", "mimetypes", "library-music.svg"));
		
		music_icon = safe_render_icon("library-music", IconSize.MENU, GLib.Path.build_filename("/", Build.ICON_FOLDER, "hicolor", "22x22", "mimetypes", "library-music.svg"));
		podcast_icon = safe_render_icon("library-podcast", IconSize.MENU, GLib.Path.build_filename("/", Build.ICON_FOLDER, "hicolor", "22x22", "mimetypes", "library-podcast.svg"));
		//audiobook_icon = safe_render_icon("library-audiobook", IconSize.MENU, GLib.Path.build_filename("/", Build.ICON_FOLDER, "hicolor", "22x22", "mimetypes", "library-audiobook.svg"));
		
		playlist_icon = safe_render_icon("playlist", IconSize.MENU, GLib.Path.build_filename("/", Build.ICON_FOLDER, "hicolor", "22x22", "mimetypes", "playlist.svg"));
		smart_playlist_icon = safe_render_icon("playlist-automatic", IconSize.MENU, GLib.Path.build_filename("/", Build.ICON_FOLDER, "hicolor", "22x22", "mimetypes", "playlist-automatic.svg"));
		
		lastfm_love_icon = safe_render_icon("lastfm-love", IconSize.MENU, GLib.Path.build_filename("/", Build.ICON_FOLDER, "hicolor", "16x16", "actions", "lastfm-love.svg"));
		lastfm_ban_icon = safe_render_icon("lastfm-ban", IconSize.MENU, GLib.Path.build_filename("/", Build.ICON_FOLDER, "hicolor", "16x16", "actions", "lastfm-ban.svg"));
		
		starred_icon = safe_render_icon("starred", IconSize.MENU, GLib.Path.build_filename("/", Build.ICON_FOLDER, "hicolor", "16x16", "status", "starred.svg"));
		not_starred_icon = safe_render_icon("not-starred", IconSize.MENU, GLib.Path.build_filename("/", Build.ICON_FOLDER, "hicolor", "16x16", "status", "not-starred.svg"));
		
		info_icon = lw.render_icon(Gtk.Stock.INFO, IconSize.MENU, null);
		
		view_column_icon = safe_render_icon("view-list-column-symbolic", IconSize.MENU, GLib.Path.build_filename("/", Build.ICON_FOLDER, "hicolor", "16x16", "actions", "view-list-column-symbolic.svg"));
		view_details_icon = safe_render_icon("view-list-details-symbolic", IconSize.MENU, GLib.Path.build_filename("/", Build.ICON_FOLDER, "hicolor", "16x16", "actions", "view-list-details-symbolic.svg"));
		view_icons_icon = safe_render_icon("view-list-icons-symbolic", IconSize.MENU, GLib.Path.build_filename("/", Build.ICON_FOLDER, "hicolor", "16x16", "actions", "view-list-icons-symbolic.svg"));
		view_video_icon = safe_render_icon("view-list-video-symbolic", IconSize.MENU, GLib.Path.build_filename("/", Build.ICON_FOLDER, "hicolor", "16x16", "actions", "view-list-video-symbolic.svg"));
		
		process_stop_icon = safe_render_icon("process-stop", IconSize.MENU, GLib.Path.build_filename("/", Build.ICON_FOLDER, "hicolor", "16x16", "actions", "process-stop.svg"));
		
		process_completed_icon = safe_render_icon("process-completed-symbolic", IconSize.MENU, GLib.Path.build_filename("/", Build.ICON_FOLDER, "hicolor", "16x16", "status", "process-completed-symbolic.svg"));
		process_error_icon = safe_render_icon("process-error-symbolic", IconSize.MENU, GLib.Path.build_filename("/", Build.ICON_FOLDER, "hicolor", "16x16", "status", "process-error-symbolic.svg"));
		
		shuffle_on_icon = safe_render_icon("media-playlist-shuffle-active-symbolic", IconSize.MENU, GLib.Path.build_filename("/", Build.ICON_FOLDER, "hicolor", "16x16", "status", "media-playlist-shuffle-active-symbolic.svg"));
		shuffle_off_icon = safe_render_icon("media-playlist-shuffle-symbolic", IconSize.MENU, GLib.Path.build_filename("/", Build.ICON_FOLDER, "hicolor", "16x16", "status", "media-playlist-shuffle-symbolic.svg"));
		
		repeat_on_icon = safe_render_icon("media-playlist-repeat-active-symbolic", IconSize.MENU, GLib.Path.build_filename("/", Build.ICON_FOLDER, "hicolor", "16x16", "status", "media-playlist-repeat-active-symbolic.svg"));
		repeat_off_icon = safe_render_icon("media-playlist-repeat-symbolic", IconSize.MENU, GLib.Path.build_filename("/", Build.ICON_FOLDER, "hicolor", "16x16", "status", "media-playlist-repeat-symbolic.svg"));
	}
	
	public Gdk.Pixbuf safe_render_icon(string name, Gtk.IconSize size, string backup_path) {
		Gdk.Pixbuf? rv = null;
		int width = 16; int height = 16;
		icon_size_lookup(size, out width, out height);
		
		if(IconTheme.get_default().has_icon(name)) {
			try {
				rv = IconTheme.get_default().load_icon(name, width, IconLookupFlags.GENERIC_FALLBACK);
			}
			catch(Error err) {
				stdout.printf("Default theme does not have icon for '%s', falling back to BeatBox default.\n", name);
			}
		}
		
		if(rv == null) {
			rv = new Gdk.Pixbuf.from_file_at_size(backup_path, width, height);
		}
		
		return rv;
	}
}
