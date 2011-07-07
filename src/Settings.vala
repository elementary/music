/*-
 * Copyright (c) 2011       Scott Ringwelski <sgringwe@mtu.edu>
 *
 * Originaly Written by Scott Ringwelski for BeatBox Music Player
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
	public static const string SHUFFLE_MODE = "/apps/beatbox/preferences/music/shuffle_mode";
	public static const string REPEAT_MODE = "/apps/beatbox/preferences/music/repeat_mode";
	public static const string SEARCH_STRING = "/apps/beatbox/preferences/music/search_string";
	
	public static const string WINDOW_MAXIMIZED = "/apps/beatbox/preferences/ui/window_maximized";
	public static const string WINDOW_WIDTH = "/apps/beatbox/preferences/ui/window_width";
	public static const string WINDOW_HEIGHT = "/apps/beatbox/preferences/ui/window_height";
	public static const string SIDEBAR_WIDTH = "/apps/beatbox/preferences/ui/sidebar_width";
	public static const string MORE_WIDTH = "/apps/beatbox/preferences/ui/more_width";
	public static const string MORE_VISIBLE = "/apps/beatbox/preferences/ui/more_visible";
	public static const string VIEW_MODE = "/apps/beatbox/preferences/ui/view_mode";
	public static const string MILLER_HEIGHT = "/apps/beatbox/preferences/ui/miller_height";
	public static const string MILLER_COLUMN_VISIBILITIES = "/apps/beatbox/preferences/ui/miller_column_visibilities";
	
	public static const string EQUALIZER_DISABLED = "/apps/beatbox/preferences/equalizer/equalizer_disabled";
	public static const string SELECTED_PRESET = "/apps/beatbox/preferences/equalizer/selected_preset";
	public static const string PRESETS = "/apps/beatbox/preferences/equalizer/presets";
	public static const string AUTO_SWITCH_PRESET = "/apps/beatbox/preferences/equalizer/auto_switch_preset";
	
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
		return getInt(MORE_WIDTH, 150);
	}
	
	public bool getMoreVisible() {
		return getBool(MORE_VISIBLE, false);
	}
	
	public int getViewMode() {
		return getInt(VIEW_MODE, 1);
	}
	
	public int getMillerHeight() {
		return getInt(MILLER_HEIGHT, 250);
	}
	
	public void getMillerVisibilities(out bool genre, out bool artist, out bool album) {
		string vis = getString(MILLER_COLUMN_VISIBILITIES, "GenreArtistAlbum");
		
		genre = vis.contains("Genre");
		artist = vis.contains("Artist");
		album = vis.contains("Album");
	}
	
	public string getSearchString() {
		return getString(SEARCH_STRING, "");
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
	
	public int getShuffleMode() {
		return getInt(SHUFFLE_MODE, 0);
	}
	
	public int getRepeatMode() {
		return getInt(REPEAT_MODE, 0);
	}
	
	public string getLastFMSessionKey() {
		return getString(LASTFM_SESSION_KEY, "");
	}
	
	public bool getEqualizerDisabled() {
		return getBool(EQUALIZER_DISABLED, false);
	}
	
	public EqualizerPreset getSelectedPreset() {
		string[] vals = getString(SELECTED_PRESET, "").split("<val_sep>", 0);
		var rv = new EqualizerPreset.basic(vals[0]);
		
		for(int i = 1; i < vals.length; ++i) {
			rv.setGain(i, int.parse(vals[i]));
		}
		
		return rv;
	}
	
	public Gee.Collection<EqualizerPreset> getPresets() {
		var rv = new Gee.LinkedList<EqualizerPreset>();
		
		string list = getString(PRESETS, "");
		string[] presets = list.split("<preset_seperator>", 0);
		
		int index;
		for(index = 0; index < presets.length - 1; ++index) {
			string[] vals = presets[index].split("<val_sep>", 0);
			
			var p = new EqualizerPreset.basic(vals[0]);
			
			for(int i = 1; i < vals.length; ++i) {
				p.setGain(i - 1, int.parse(vals[i]));
			}
			
			rv.add(p);
		}
		
		return rv;
	}
	
	public bool getAutoSwitchPreset() {
		return getBool(AUTO_SWITCH_PRESET, false);
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
	
	public void setMoreVisible(bool val) {
		setBool(MORE_VISIBLE, val);
	}
	
	public void setViewMode(int val) {
		setInt(VIEW_MODE, val);
	}
	
	public void setMillerHeight(int val) {
		setInt(MILLER_HEIGHT, val);
	}
	
	public void setMillerColumnVisibilities(bool genre, bool artist, bool album) {
		string vis = "";
		if(genre)	vis += "Genre";
		if(artist)	vis += "Artist";
		if(album)	vis += "Album";
			
		setString(MILLER_COLUMN_VISIBILITIES, vis);
	}
	
	public void setSearchString(string val) {
		setString(SEARCH_STRING, val);
	}
	
	public void setUpdateFolderHierarchy(bool val) {
		setBool(UPDATE_FOLDER_HIERARCHY, val);
	}
	
	public void setCopyImportedMusic(bool val) {
		setBool(COPY_IMPORTED_MUSIC, val);
	}
	
	public void setLastSongPlaying(Song? s) {
		if(s != null)
			setString(LAST_SONG_PLAYING, s.title + "<seperator>" + s.artist);
		else
			setString(LAST_SONG_PLAYING, "");
	}
	
	public void setLastSongPosition(int val) {
		setInt(LAST_SONG_POSITION, val);
	}
	
	public void setShuffleMode(int val) {
		setInt(SHUFFLE_MODE, val);
	}
	
	public void setRepeatMode(int val) {
		setInt(REPEAT_MODE, val);
	}
	
	public void setLastFMSessionKey(string val) {
		setString(LASTFM_SESSION_KEY, val);
	}
	
	public void setEqualizerDisabled(bool val) {
		setBool(EQUALIZER_DISABLED, val);
	}
	
	public void setSelectedPreset(EqualizerPreset preset) {
		string toSave = preset.name;
		
		foreach(int gain in preset.gains) {
			toSave += "<val_sep>" + gain.to_string();
		}
		
		setString(SELECTED_PRESET, toSave);
	}
	
	public void setPresets(Gee.Collection<EqualizerPreset> presets) {
		string rv = "";
		
		foreach(var p in presets) {
			rv += p.name;
			
			for(int i = 0; i < 10; ++i) {
				rv += "<val_sep>" + p.getGain(i).to_string();
			}
			
			rv += "<preset_seperator>";
		}
		
		setString(PRESETS, rv);
	}
	
	public void setAutoSwitchPreset(bool val) {
		setBool(AUTO_SWITCH_PRESET, val);
	}
}
