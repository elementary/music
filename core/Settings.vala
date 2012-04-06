/*-
 * Copyright (c) 2011-2012	   Scott Ringwelski <sgringwe@mtu.edu>
 *
 * Originally Written by Scott Ringwelski for BeatBox Music Player
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
	public GLib.Settings lastfm {get; private set;}
	public GLib.Settings ui {get; private set;}
	public GLib.Settings library {get; private set;}
	public GLib.Settings equalizer {get; private set;}
	public GLib.Settings plugins {get; private set;}

	public static const string LASTFM_SESSION_KEY = "session-key";
	
	public static const string MUSIC_FOLDER = "music-folder";
	public static const string MUSIC_MOUNT_NAME  = "music-mount-name";
	public static const string UPDATE_FOLDER_HIERARCHY = "update-folder-hierarchy";
	public static const string WRITE_METADATA_TO_FILE = "write-metadata-to-file";
	public static const string COPY_IMPORTED_MUSIC = "copy-imported-music";
	public static const string DOWNLOAD_NEW_PODCASTS = "download-new-podcasts";
	public static const string LAST_MEDIA_PLAYING = "last-media-playing";
	public static const string LAST_MEDIA_POSITION = "last-media-position";
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
	public static const string MILLER_WIDTH = "miller-width";
	public static const string MILLER_HEIGHT = "miller-height";
	public static const string MILLER_COLUMNS_ENABLED = "miller-columns-enabled";
	public static const string MUSIC_MILLER_VISIBLE_COLUMNS = "music-miller-visible-columns";
	public static const string GENERIC_MILLER_VISIBLE_COLUMNS = "generic-miller-visible-columns";
	public static const string MILLER_COLUMNS_POSITION = "miller-columns-position";
	
	public static const string EQUALIZER_ENABLED = "equalizer-enabled";
	public static const string SELECTED_PRESET = "selected-preset";
	public static const string CUSTOM_PRESETS = "custom-presets";
	public static const string DEFAULT_PRESETS = "default-presets";
	public static const string AUTO_SWITCH_PRESET = "auto-switch-preset";
	public static const string VOLUME = "volume";

	public static const string ENABLED_PLUGINS = "enabled-plugins";

	LinkedList<string> lastfm_settings;
	LinkedList<string> ui_settings;
	LinkedList<string> library_settings;
	LinkedList<string> equalizer_settings;
	
	string music_folder;
	
	public Settings() {
		lastfm = new GLib.Settings("org.elementary.noise.lastfm");
		ui = new GLib.Settings("org.elementary.noise.ui");
		library = new GLib.Settings("org.elementary.noise.library");
		equalizer = new GLib.Settings("org.elementary.noise.equalizer");
		plugins = new GLib.Settings("org.elementary.noise.plugins");
		
		lastfm_settings = new LinkedList<string>();
		ui_settings = new LinkedList<string>();
		library_settings = new LinkedList<string>();
		equalizer_settings = new LinkedList<string>();
		
		lastfm_settings.add(LASTFM_SESSION_KEY);
		
		library_settings.add(MUSIC_FOLDER);
		library_settings.add(MUSIC_MOUNT_NAME);
		library_settings.add(UPDATE_FOLDER_HIERARCHY);
		library_settings.add(WRITE_METADATA_TO_FILE);
		library_settings.add(COPY_IMPORTED_MUSIC);
		library_settings.add(DOWNLOAD_NEW_PODCASTS);
		library_settings.add(LAST_MEDIA_PLAYING);
		library_settings.add(LAST_MEDIA_POSITION);
		library_settings.add(SHUFFLE_MODE);
		library_settings.add(REPEAT_MODE);
		library_settings.add(SEARCH_STRING);
		
		ui_settings.add(WINDOW_MAXIMIZED);
		ui_settings.add(WINDOW_WIDTH);
		ui_settings.add(WINDOW_HEIGHT);
		ui_settings.add(SIDEBAR_WIDTH);
		ui_settings.add(MORE_VISIBLE);
		ui_settings.add(MORE_WIDTH);
		ui_settings.add(VIEW_MODE);
		ui_settings.add(MILLER_WIDTH);
		ui_settings.add(MILLER_HEIGHT);
		ui_settings.add(MUSIC_MILLER_VISIBLE_COLUMNS);
		ui_settings.add(GENERIC_MILLER_VISIBLE_COLUMNS);
		ui_settings.add(MILLER_COLUMNS_POSITION);
		ui_settings.add(MILLER_COLUMNS_ENABLED);
		
		equalizer_settings.add(EQUALIZER_ENABLED);
		equalizer_settings.add(SELECTED_PRESET);
		equalizer_settings.add(CUSTOM_PRESETS);
		equalizer_settings.add(DEFAULT_PRESETS);
		equalizer_settings.add(AUTO_SWITCH_PRESET);
		equalizer_settings.add(VOLUME);

		//music_folder = getMusicFolder();
	}
	
	private bool getBool(string path, bool def) {
		bool rv = def;
		
		if(lastfm_settings.contains(path)) {
			rv = lastfm.get_boolean(path);
		}
		else if(ui_settings.contains(path)) {
			rv = ui.get_boolean(path);
		}
		else if(library_settings.contains(path)) {
			rv = library.get_boolean(path);
		}
		else if(equalizer_settings.contains(path)) {
			rv = equalizer.get_boolean(path);
		}
		else {
			warning ("could not find bool for %s\n", path);
			rv = def;
		}
		
		return rv;
	}

	private string[] getStrings(string path) {
		if(lastfm_settings.contains(path)) {
			return lastfm.get_strv(path);
		}
		else if(ui_settings.contains(path)) {
			return ui.get_strv(path);
		}
		else if(library_settings.contains(path)) {
			return library.get_strv(path);
		}
		else if(equalizer_settings.contains(path)) {
			return equalizer.get_strv(path);
		}
		else {
			warning("could not find strings for %s\n", path);
		}

		return new string[0];
	}

	private string getString(string path, string def) {
		string rv = def;
		
		if(lastfm_settings.contains(path)) {
			rv = lastfm.get_string(path);
		}
		else if(ui_settings.contains(path)) {
			rv = ui.get_string(path);
		}
		else if(library_settings.contains(path)) {
			rv = library.get_string(path);
		}
		else if(equalizer_settings.contains(path)) {
			rv = equalizer.get_string(path);
		}
		else {
			warning ("could not find string for %s\n", path);
			rv = def;
		}
		
		return rv;
	}

	private int get_enum (string path) {
		int rv = 0;
		
		if(lastfm_settings.contains (path)) {
			rv = lastfm.get_enum (path);
		}
		else if(ui_settings.contains (path)) {
			rv = ui.get_enum (path);
		}
		else if(library_settings.contains (path)) {
			rv = library.get_enum (path);
		}
		else if(equalizer_settings.contains (path)) {
			rv = equalizer.get_enum (path);
		}
		else {
			warning ("could not find string for %s\n", path);
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
		else if(library_settings.contains(path)) {
			rv = library.get_int(path);
		}
		else if(equalizer_settings.contains(path)) {
			rv = equalizer.get_int(path);
		}
		else {
			warning ("could not find int for %s\n", path);
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
		else if(library_settings.contains(path)) {
			library.set_boolean(path, val);
		}
		else if(equalizer_settings.contains(path)) {
			equalizer.set_boolean(path, val);
		}
		else {
			warning ("could not find bool for %s\n", path);
		}
	}
	
	private void setString(string path, string val) {
		if(lastfm_settings.contains(path)) {
			lastfm.set_string(path, val);
		}
		else if(ui_settings.contains(path)) {
			ui.set_string(path, val);
		}
		else if(library_settings.contains(path)) {
			library.set_string(path, val);
		}
		else if(equalizer_settings.contains(path)) {
			equalizer.set_string(path, val);
		}
		else {
			warning ("could not find string for %s\n", path);
		}
		
		if(path == MUSIC_FOLDER)
			music_folder = val;
	}

	private void setStrings(string path, string[] val) {

		if(lastfm_settings.contains(path)) {
			lastfm.set_strv(path, val);
		}
		else if(ui_settings.contains(path)) {
			ui.set_strv(path, val);
		}
		else if(library_settings.contains(path)) {
			library.set_strv(path, val);
		}
		else if(equalizer_settings.contains(path)) {
			equalizer.set_strv(path, val);
		}
		else {
			warning("could not find strings for %s\n", path);
		}
	}

	private void set_enum (string path, int val) {
		if(lastfm_settings.contains (path)) {
			lastfm.set_enum (path, val);
		}
		else if(ui_settings.contains (path)) {
			ui.set_enum (path, val);
		}
		else if(library_settings.contains (path)) {
			library.set_enum (path, val);
		}
		else if(equalizer_settings.contains (path)) {
			equalizer.set_enum (path, val);
		}
		else {
			warning ("could not find int for %s\n", path);
		}	
	}

	private void setInt(string path, int val) {
		if(lastfm_settings.contains(path)) {
			lastfm.set_int(path, val);
		}
		else if(ui_settings.contains(path)) {
			ui.set_int(path, val);
		}
		else if(library_settings.contains(path)) {
			library.set_int(path, val);
		}
		else if(equalizer_settings.contains(path)) {
			equalizer.set_int(path, val);
		}
		else {
			warning ("could not find int for %s\n", path);
		}
	}


	/** Get values **/
	public string getMusicFolder() {
		string rv = getString(MUSIC_FOLDER, "");
		
		if(rv == "")
			rv = Environment.get_user_special_dir(UserDirectory.MUSIC);
			
		return rv;
	}
	
	public string get_album_art_cache_dir () {
		return GLib.Path.build_path ("/", get_cache_dir (), "album-art");
	}

	public string get_cache_dir () {
		return GLib.Path.build_path ("/", Environment.get_user_cache_dir(), "noise");
	}
	
	public string getMusicMountName() {
		return getString(MUSIC_MOUNT_NAME, "");
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

	public bool get_miller_columns_enabled () {
		return getBool(MILLER_COLUMNS_ENABLED, false);
	}
	
	public int get_miller_columns_width () {
		return getInt(MILLER_WIDTH, 200);
	}
	
	public int get_miller_columns_height () {
		return getInt(MILLER_HEIGHT, 200);
	}

	public int get_miller_columns_position () {
		return get_enum (MILLER_COLUMNS_POSITION);
	}

	public Gee.Collection<string> get_music_miller_visible_columns () {
		var rv = new Gee.LinkedList<string>();

		var visible_columns = getStrings (MUSIC_MILLER_VISIBLE_COLUMNS);

		for (int index = 0; index < visible_columns.length; index++) {
			rv.add (visible_columns[index]);
		}

		return rv;
	}

	public Gee.Collection<string> get_generic_miller_visible_columns () {
		var rv = new Gee.LinkedList<string>();

		var visible_columns = getStrings (GENERIC_MILLER_VISIBLE_COLUMNS);

		for (int index = 0; index < visible_columns.length; index++) {
			rv.add (visible_columns[index]);
		}

		return rv;
	}

	public string getSearchString() {
		return getString(SEARCH_STRING, "");
	}
	
	public bool getUpdateFolderHierarchy() {
		return getBool(UPDATE_FOLDER_HIERARCHY, false);
	}
	
	public bool getWriteMetadataToFile() {
		return getBool(WRITE_METADATA_TO_FILE, false);
	}
	
	public bool getCopyImportedMusic() {
		return getBool(COPY_IMPORTED_MUSIC, false);
	}
	
	public bool getDownloadNewPodcasts() {
		return getBool(DOWNLOAD_NEW_PODCASTS, false);
	}
	
	public int getLastMediaPlaying() {
		return getInt(LAST_MEDIA_PLAYING, 0);
	}
	
	public int getLastMediaPosition() {
		return getInt(LAST_MEDIA_POSITION, 0);
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
	
	public bool getEqualizerEnabled() {
		return getBool(EQUALIZER_ENABLED, false);
	}
	
	public string? getSelectedPreset() {
		string rv = getString(SELECTED_PRESET, "");
		
		if(rv != null && rv.length == 0)
			return null;

		return rv;
	}
	
	public Gee.Collection<EqualizerPreset> getDefaultPresets() {

		return getPresets(getStrings(DEFAULT_PRESETS));
	
	}
	
	public Gee.Collection<EqualizerPreset> getCustomPresets() {
	
		return getPresets(getStrings(CUSTOM_PRESETS));
	
	}

	private Gee.Collection<EqualizerPreset> getPresets(string[] presets) {
		var rv = new Gee.LinkedList<EqualizerPreset>();

		for (int index = 0; index < presets.length; index++) {
			string[] vals = presets[index].split("/", 0);
			
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
	
	public void setMusicMountName(string path) {
		setString(MUSIC_MOUNT_NAME, path);
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

	public void set_miller_columns_enabled (bool val) {
		setBool(MILLER_COLUMNS_ENABLED, val);
	}

	public void set_miller_columns_width (int val) {
		setInt(MILLER_WIDTH, val);
	}

	public void set_miller_columns_height (int val) {
		setInt(MILLER_HEIGHT, val);
	}

	public void set_miller_columns_position (int val) {
		set_enum (MILLER_COLUMNS_POSITION, val);
	}

	public void set_music_miller_visible_columns (Gee.Collection<string> columns) {
		string[] vals = new string[columns.size];
		int index = 0;

		foreach (var col in columns) {
			vals[index++] = col;
		}

		setStrings (MUSIC_MILLER_VISIBLE_COLUMNS, vals);
	}

	public void set_generic_miller_visible_columns (Gee.Collection<string> columns) {
		string[] vals = new string[columns.size];
		int index = 0;

		foreach (var col in columns) {
			vals[index++] = col;
		}

		setStrings (GENERIC_MILLER_VISIBLE_COLUMNS, vals);
	}

	public void setSearchString(string val) {
		setString(SEARCH_STRING, val);
	}
	
	public void setUpdateFolderHierarchy(bool val) {
		setBool(UPDATE_FOLDER_HIERARCHY, val);
	}
	
	public void setWriteMetadataToFile(bool val) {
		setBool(WRITE_METADATA_TO_FILE, val);
	}
	
	public void setCopyImportedMusic(bool val) {
		setBool(COPY_IMPORTED_MUSIC, val);
	}
	
	public void setDownloadNewPodcasts(bool val) {
		setBool(DOWNLOAD_NEW_PODCASTS, val);
	}
	
	public void setLastMediaPlaying(int val) {
		setInt(LAST_MEDIA_PLAYING, val);
	}
	
	public void setLastMediaPosition(int val) {
		setInt(LAST_MEDIA_POSITION, val);
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
	
	public void setEqualizerEnabled(bool val) {
		setBool(EQUALIZER_ENABLED, val);
	}
	
	public void setSelectedPreset(EqualizerPreset? preset) {
		setString(SELECTED_PRESET, (preset != null)? preset.name : "");
	}

	public void setPresets(Gee.Collection<EqualizerPreset> presets, string type) {
		string[] vals = new string[presets.size];

		int index = 0;
		foreach (var p in presets) {
			string preset = p.name;

			for(int i = 0; i < 10; ++i) {
				preset += "/" + p.getGain(i).to_string();
			}

			vals[index++] = preset;
		}
		
		if (type == CUSTOM_PRESETS)
			setStrings(CUSTOM_PRESETS, vals);
		else if (type == DEFAULT_PRESETS)
			setStrings(DEFAULT_PRESETS, vals);
	}

	public void setAutoSwitchPreset(bool val) {
		setBool(AUTO_SWITCH_PRESET, val);
	}
	
	public void setVolume(double val) {
		setInt(VOLUME, (int)(val*100));
	}
}

