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

using Gee;

public class BeatBox.Settings : Object {
	GLib.Settings lastfm;
	GLib.Settings ui;
	GLib.Settings music;
	GLib.Settings equalizer;
	
	public static const string LASTFM_SESSION_KEY = "session-key";
	
	public static const string MUSIC_FOLDER = "music-folder";
	public static const string UPDATE_FOLDER_HIERARCHY = "update-folder-hierarchy";
	public static const string COPY_IMPORTED_MUSIC = "copy-imported-music";
	public static const string LAST_SONG_PLAYING = "last-song-playing";
	public static const string LAST_SONG_POSITION = "last-song-position";
	public static const string SHUFFLE_MODE = "shuffle-mode";
	public static const string REPEAT_MODE = "repeat-mode";
	public static const string SEARCH_STRING = "search-string";
	
	public static const string WINDOW_MAXIMIZED = "window-maximized";
	public static const string WINDOW_WIDTH = "window-width";
	public static const string WINDOW_HEIGHT = "window-height";
	public static const string SIDEBAR_WIDTH = "sidebar-width";
	public static const string MORE_WIDTH = "more-width";
	public static const string MORE_VISIBLE = "more-visible";
	public static const string VIEW_MODE = "view-mode";
	public static const string MILLER_HEIGHT = "miller-height";
	public static const string MILLER_COLUMN_VISIBILITIES = "miller-column-visibilities";
	
	public static const string EQUALIZER_DISABLED = "equalizer-disabled";
	public static const string SELECTED_PRESET = "selected-preset";
	public static const string PRESETS = "presets";
	public static const string AUTO_SWITCH_PRESET = "auto-switch-preset";
	public static const string VOLUME = "volume";
	
	LinkedList<string> lastfm_settings;
	LinkedList<string> ui_settings;
	LinkedList<string> music_settings;
	LinkedList<string> equalizer_settings;
	
	public Settings() {
		lastfm = new GLib.Settings("org.gnome.beatbox.lastfm");
		ui = new GLib.Settings("org.gnome.beatbox.ui");
		music = new GLib.Settings("org.gnome.beatbox.music");
		equalizer = new GLib.Settings("org.gnome.beatbox.equalizer");
		
		lastfm_settings = new LinkedList<string>();
		ui_settings = new LinkedList<string>();
		music_settings = new LinkedList<string>();
		equalizer_settings = new LinkedList<string>();
		
		lastfm_settings.add(LASTFM_SESSION_KEY);
		
		music_settings.add(MUSIC_FOLDER);
		music_settings.add(UPDATE_FOLDER_HIERARCHY);
		music_settings.add(COPY_IMPORTED_MUSIC);
		music_settings.add(LAST_SONG_PLAYING);
		music_settings.add(LAST_SONG_POSITION);
		music_settings.add(SHUFFLE_MODE);
		music_settings.add(REPEAT_MODE);
		music_settings.add(SEARCH_STRING);
		
		ui_settings.add(WINDOW_MAXIMIZED);
		ui_settings.add(WINDOW_WIDTH);
		ui_settings.add(WINDOW_HEIGHT);
		ui_settings.add(SIDEBAR_WIDTH);
		ui_settings.add(MORE_VISIBLE);
		ui_settings.add(MORE_WIDTH);
		ui_settings.add(VIEW_MODE);
		ui_settings.add(MILLER_HEIGHT);
		ui_settings.add(MILLER_COLUMN_VISIBILITIES);
		
		equalizer_settings.add(EQUALIZER_DISABLED);
		equalizer_settings.add(SELECTED_PRESET);
		equalizer_settings.add(PRESETS);
		equalizer_settings.add(AUTO_SWITCH_PRESET);
		equalizer_settings.add(VOLUME);
	}
	
	private bool getBool(string path, bool def) {
		bool rv = def;
		
		if(lastfm_settings.contains(path)) {
			rv = lastfm.get_boolean(path);
		}
		else if(ui_settings.contains(path)) {
			rv = ui.get_boolean(path);
		}
		else if(music_settings.contains(path)) {
			rv = music.get_boolean(path);
		}
		else if(equalizer_settings.contains(path)) {
			rv = equalizer.get_boolean(path);
		}
		else {
			stdout.printf("could not find bool for %s\n", path);
			rv = def;
		}
		
		return rv;
	}
	
	private string getString(string path, string def) {
		string rv = def;
		
		if(lastfm_settings.contains(path)) {
			rv = lastfm.get_string(path);
		}
		else if(ui_settings.contains(path)) {
			rv = ui.get_string(path);
		}
		else if(music_settings.contains(path)) {
			rv = music.get_string(path);
		}
		else if(equalizer_settings.contains(path)) {
			rv = equalizer.get_string(path);
		}
		else {
			stdout.printf("could not find string for %s\n", path);
			rv = def;
		}
		
		return rv;
	}
	
	private int getInt(string path, int def) {
		int rv = def;
		
		if(lastfm_settings.contains(path)) {
			rv = lastfm.get_int(path);
		}
		else if(ui_settings.contains(path)) {
			rv = ui.get_int(path);
		}
		else if(music_settings.contains(path)) {
			rv = music.get_int(path);
		}
		else if(equalizer_settings.contains(path)) {
			rv = equalizer.get_int(path);
		}
		else {
			stdout.printf("could not find int for %s\n", path);
			rv = def;
		}
		
		return rv;
	}
	
	private void setBool(string path, bool val) {
		if(lastfm_settings.contains(path)) {
			lastfm.set_boolean(path, val);
		}
		else if(ui_settings.contains(path)) {
			ui.set_boolean(path, val);
		}
		else if(music_settings.contains(path)) {
			music.set_boolean(path, val);
		}
		else if(equalizer_settings.contains(path)) {
			equalizer.set_boolean(path, val);
		}
		else {
			stdout.printf("could not find int for %s\n", path);
		}
	}
	
	private void setString(string path, string val) {
		if(lastfm_settings.contains(path)) {
			lastfm.set_string(path, val);
		}
		else if(ui_settings.contains(path)) {
			ui.set_string(path, val);
		}
		else if(music_settings.contains(path)) {
			music.set_string(path, val);
		}
		else if(equalizer_settings.contains(path)) {
			equalizer.set_string(path, val);
		}
		else {
			stdout.printf("could not find int for %s\n", path);
		}
	}
	
	private void setInt(string path, int val) {
		if(lastfm_settings.contains(path)) {
			lastfm.set_int(path, val);
		}
		else if(ui_settings.contains(path)) {
			ui.set_int(path, val);
		}
		else if(music_settings.contains(path)) {
			music.set_int(path, val);
		}
		else if(equalizer_settings.contains(path)) {
			equalizer.set_int(path, val);
		}
		else {
			stdout.printf("could not find int for %s\n", path);
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
	
	public int getLastSongPlaying() {
		return getInt(LAST_SONG_PLAYING, 0);
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
	
	public EqualizerPreset? getSelectedPreset() {
		string[] vals = getString(SELECTED_PRESET, "").split("<val_sep>", 0);
		
		if(vals.length == 0 || vals[0] == null)
			return null;
		
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
		
		if(presets.length == 0)
			return rv;
		
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
	
	public double getVolume() {
		return (double)((double)(getInt(VOLUME, 100)) / 100.0);
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
	
	public void setLastSongPlaying(int val) {
		setInt(LAST_SONG_PLAYING, val);
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
	
	public void setVolume(double val) {
		setInt(VOLUME, (int)(val*100));
	}
}
