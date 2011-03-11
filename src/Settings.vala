public class BeatBox.Settings : Object {
	GConf.Client client;
	
	public static const string LASTFM_USERNAME = "/apps/beatbox/preferences/lastfm/username";
	public static const string LASTFM_PASSWORD = "/apps/beatbox/preferences/lastfm/pass";
	public static const string LASTFM_AUTO_LOGIN = "/apps/beatbox/preferences/lastfm/auto_login";
	public static const string LASTFM_SESSION_KEY = "/apps/beatbox/preferences/lastfm/lastfm_session_key";
	
	public static const string MUSIC_FOLDER = "/apps/beatbox/preferences/music/music_folder";
	public static const string UPDATE_FOLDER_HIERARCHY = "/apps/beatbox/preferences/music/update_folder_hierarchy";
	public static const string COPY_IMPORTED_MUSIC = "/apps/beatbox/preferences/music/copy_imported_music";
	public static const string LAST_SONG_PLAYING = "/apps/beatbox/preferences/music/last_song_playing";
	public static const string LAST_SONG_POSITION = "/apps/beatbox/preferences/music/last_song_position";
	public static const string SHUFFLE_ENABLED = "/apps/beatbox/preferences/music/shuffle_enabled";
	
	public static const string WINDOW_MAXIMIZED = "/apps/beatbox/preferences/ui/window_maximized";
	public static const string WINDOW_WIDTH = "/apps/beatbox/preferences/ui/window_width";
	public static const string WINDOW_HEIGHT = "/apps/beatbox/preferences/ui/window_height";
	public static const string SIDEBAR_WIDTH = "/apps/beatbox/preferences/ui/sidebar_width";
	public static const string MORE_WIDTH = "/apps/beatbox/preferences/ui/more_width";
	
	public Settings() {
		client = GConf.Client.get_default();
	}
	
	private bool getBool(string path, bool def) {
		bool rv = def;
		
		try {
			if(client.get(path) != null) {
				rv = client.get_bool(path);
			}
			else
				rv = def;
		}
		catch(GLib.Error err) {
			stdout.printf("Could not get bool value %s from gconf: %s\n", path, err.message);
		}
		
		return rv;
	}
	
	private string getString(string path, string def) {
		string rv = def;
		
		try {
			if(client.get(path) != null) {
				rv = client.get_string(path);
			}
			else
				rv = def;
		}
		catch(GLib.Error err) {
			stdout.printf("Could not get string value %s from gconf: %s\n", path, err.message);
		}
		
		return rv;
	}
	
	private int getInt(string path, int def) {
		int rv = def;
		
		try {
			if(client.get(path) != null) {
				rv = client.get_int(path);
			}
			else
				rv = def;
		}
		catch(GLib.Error err) {
			stdout.printf("Could not get int value %s from gconf: %s\n", path, err.message);
		}
		
		return rv;
	}
	
	private void setBool(string path, bool val) {
		try {
			client.set_bool(path, val);
		}
		catch(GLib.Error err) {
			stdout.printf("Could not set bool value %s from gconf: %s\n", path, err.message);
		}
	}
	
	private void setString(string path, string val) {
		try {
			client.set_string(path, val);
		}
		catch(GLib.Error err) {
			stdout.printf("Could not set string value %s from gconf: %s\n", path, err.message);
		}
	}
	
	private void setInt(string path, int val) {
		try {
			client.set_int(path, val);
		}
		catch(GLib.Error err) {
			stdout.printf("Could not set int value %s from gconf: %s\n", path, err.message);
		}
	}
	
	/** Get values **/
	public string getMusicFolder() {
		return getString(MUSIC_FOLDER, "");
	}
	
	public bool getWindowMaximized() {
		return getBool(WINDOW_MAXIMIZED, false);
	}
	
	public int getWindowWidth() {
		return getInt(WINDOW_WIDTH, 1100);
	}
	
	public int getWindowHeight() {
		return getInt(WINDOW_HEIGHT, 600);
	}
	
	public int getSidebarWidth() {
		return getInt(SIDEBAR_WIDTH, 200);
	}
	
	public int getMoreWidth() {
		return getInt(MORE_WIDTH, 725);
	}
	
	public bool getUpdateFolderHierarchy() {
		return getBool(UPDATE_FOLDER_HIERARCHY, false);
	}
	
	public bool getCopyImportedMusic() {
		return getBool(COPY_IMPORTED_MUSIC, false);
	}
	
	public Song getLastSongPlaying() {
		string[] song_parts = getString(LAST_SONG_PLAYING, "").split("<seperator>", 0);
		
		Song rv = new Song("");
		
		if(song_parts.length < 2)
			return rv;
		
		rv.title = song_parts[0];
		rv.artist = song_parts[1];
		
		return rv;
	}
	
	public int getLastSongPosition() {
		return getInt(LAST_SONG_POSITION, 0);
	}
	
	public bool getShuffleEnabled() {
		return getBool(SHUFFLE_ENABLED, false);
	}
	
	public bool getLastFMAutoLogin() {
		return getBool(LASTFM_AUTO_LOGIN, false);
	}
	
	public string getLastFMSessionKey() {
		return getString(LASTFM_SESSION_KEY, "");
	}
	
	/** Set Values **/
	public void setMusicFolder(string path) {
		setString(MUSIC_FOLDER, path);
	}
	
	public void setWindowMaximized(bool val) {
		setBool(WINDOW_MAXIMIZED, val);
	}
	
	public void setWindowWidth(int val) {
		setInt(WINDOW_WIDTH, val);
	}
	
	public void setWindowHeight(int val) {
		setInt(WINDOW_HEIGHT, val);
	}
	
	public void setSidebarWidth(int val) {
		setInt(SIDEBAR_WIDTH, val);
	}
	
	public void setMoreWidth(int val) {
		setInt(MORE_WIDTH, val);
	}
	
	public void setUpdateFolderHierarchy(bool val) {
		setBool(UPDATE_FOLDER_HIERARCHY, val);
	}
	
	public void setCopyImportedMusic(bool val) {
		setBool(COPY_IMPORTED_MUSIC, val);
	}
	
	public void setLastSongPlaying(Song s) {
		setString(LAST_SONG_PLAYING, s.title + "<seperator>" + s.artist);
	}
	
	public void setLastSongPosition(int val) {
		setInt(LAST_SONG_POSITION, val);
	}
	
	public void setShuffleEnabled(bool val) {
		setBool(SHUFFLE_ENABLED, val);
	}
	
	public void setLastFMAutoLogin(bool val) {
		setBool(LASTFM_AUTO_LOGIN, val);
	}
	
	public void setLastFMSessionKey(string val) {
		setString(LASTFM_SESSION_KEY, val);
	}
}
