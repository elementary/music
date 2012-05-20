/*-
 * Copyright (c) 2011-2012 Scott Ringwelski <sgringwe@mtu.edu>
 * Copyright (c) 2012 Noise Developers
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
 *
 * Authored by: Scott Ringwelski <sgringwe@mtu.edu>
 *              Victor Eduardo <victoreduardm@gmail.com>
 */

using Gee;

public class BeatBox.Settings : Object {
	public GLib.Settings lastfm {get; private set;}
	public GLib.Settings ui {get; private set;}
	public GLib.Settings library {get; private set;}
	public GLib.Settings equalizer {get; private set;}
	public GLib.Settings plugins {get; private set;}

	private const string LASTFM_SESSION_KEY = "session-key";

	private const string MUSIC_FOLDER = "music-folder";
	private const string MUSIC_MOUNT_NAME  = "music-mount-name";
	private const string UPDATE_FOLDER_HIERARCHY = "update-folder-hierarchy";
	private const string WRITE_METADATA_TO_FILE = "write-metadata-to-file";
	private const string COPY_IMPORTED_MUSIC = "copy-imported-music";
	private const string DOWNLOAD_NEW_PODCASTS = "download-new-podcasts";
	private const string LAST_MEDIA_PLAYING = "last-media-playing";
	private const string LAST_MEDIA_POSITION = "last-media-position";
	private const string SHUFFLE_MODE = "shuffle-mode";
	private const string REPEAT_MODE = "repeat-mode";
	private const string SEARCH_STRING = "search-string";
	
	private const string WINDOW_MAXIMIZED = "window-maximized";
	private const string WINDOW_WIDTH = "window-width";
	private const string WINDOW_HEIGHT = "window-height";
	private const string SIDEBAR_WIDTH = "sidebar-width";
	private const string MORE_WIDTH = "more-width";
	private const string MORE_VISIBLE = "more-visible";
	private const string VIEW_MODE = "view-mode";
	private const string MILLER_WIDTH = "miller-width";
	private const string MILLER_HEIGHT = "miller-height";
	private const string MILLER_COLUMNS_ENABLED = "miller-columns-enabled";
	private const string MUSIC_MILLER_VISIBLE_COLUMNS = "music-miller-visible-columns";
	private const string GENERIC_MILLER_VISIBLE_COLUMNS = "generic-miller-visible-columns";
	private const string MILLER_COLUMNS_POSITION = "miller-columns-position";
	
	private const string EQUALIZER_ENABLED = "equalizer-enabled";
	private const string SELECTED_PRESET = "selected-preset";
	private const string CUSTOM_PRESETS = "custom-presets";
	private const string AUTO_SWITCH_PRESET = "auto-switch-preset";

	public const string ENABLED_PLUGINS = "enabled-plugins";

	LinkedList<string> lastfm_settings;
	LinkedList<string> ui_settings;
	LinkedList<string> library_settings;
	LinkedList<string> equalizer_settings;

#if HAVE_FAST_EXPERIMENTAL_MODE
	private bool writing_settings_to_disk = false;
#endif

	HashMap<string, int> int_cache;
	HashMap<string, int> enum_cache;
	HashMap<string, string> string_cache;
	HashMap<string, Gee.Collection<string>> string_array_cache;
	HashMap<string, bool> bool_cache;

	public Settings() {
		lastfm = new GLib.Settings("org.pantheon.noise.lastfm");
		ui = new GLib.Settings("org.pantheon.noise.ui");
		library = new GLib.Settings("org.pantheon.noise.library");
		equalizer = new GLib.Settings("org.pantheon.noise.equalizer");
		plugins = new GLib.Settings("org.pantheon.noise.plugins");

		int_cache = new HashMap<string, int> ();
		enum_cache = new HashMap<string, int> ();
		string_cache = new HashMap<string, string> ();
		string_array_cache = new HashMap<string, Gee.Collection<string>> ();
		bool_cache = new HashMap<string, bool> ();

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
		equalizer_settings.add(AUTO_SWITCH_PRESET);
	}

#if HAVE_FAST_EXPERIMENTAL_MODE
	public void save () {
		writing_settings_to_disk = true;

		// INTEGERS
		foreach (var key in int_cache.keys) {
			set_int (key, int_cache.get (key));
		}

		// ENUMS
		foreach (var key in enum_cache.keys) {
			set_enum (key, enum_cache.get (key));
		}

		// STRINGS
		foreach (var key in string_cache.keys) {
			set_string (key, string_cache.get (key));
		}

		// STRING ARRAYS
		foreach (var key in string_array_cache.keys) {
			set_strings (key, string_array_cache.get (key));
		}

		// BOOLEANS
		foreach (var key in bool_cache.keys) {
			set_bool (key, bool_cache.get (key));
		}


		writing_settings_to_disk = false;
	}
#endif

	/**
	 *  GET ...
	 */

	private bool get_bool(string path) {
		if (bool_cache.has_key (path))
			return bool_cache.get (path);

		bool rv = false;

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
		}
		
		return rv;
	}

	private Gee.Collection<string> get_strings (string path) {
		if (string_array_cache.has_key (path))
			return string_array_cache.get (path);

		string[] ? values = null;
		var rv = new Gee.LinkedList<string> ();

		if(lastfm_settings.contains(path)) {
			values = lastfm.get_strv(path);
		}
		else if(ui_settings.contains(path)) {
			values = ui.get_strv(path);
		}
		else if(library_settings.contains(path)) {
			values = library.get_strv(path);
		}
		else if(equalizer_settings.contains(path)) {
			values = equalizer.get_strv(path);
		}
		else {
			warning("could not find strings for %s\n", path);
		}

		if (values != null) {
			for (int i = 0; i < values.length; i++) {
				rv.add (values[i]);
			}
		}

		return rv;
	}

	private string get_string (string path) {
		string rv = "";

		if (string_cache.has_key (path))
			return string_cache.get (path);

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
		}
		
		return rv;
	}

	private int get_enum (string path) {
		if (enum_cache.has_key (path))
			return enum_cache.get (path);

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
	
	private int get_int (string path) {
		if (int_cache.has_key (path))
			return int_cache.get (path);

		int rv = 0;
		
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
		}
		
		return rv;
	}

	/**
	 *  SET ...
	 */

	private void set_bool (string path, bool val) {
		bool_cache.unset (path);
		bool_cache.set (path, val);

#if HAVE_FAST_EXPERIMENTAL_MODE
		if (!writing_settings_to_disk)
			return;
#endif

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
	
	private void set_string(string path, string val) {
		string_cache.unset (path);
		string_cache.set (path, val);

#if HAVE_FAST_EXPERIMENTAL_MODE
		if (!writing_settings_to_disk)
			return;
#endif

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
	}

	private void set_strings(string path, Gee.Collection<string> vals) {
		string_array_cache.unset (path);
		string_array_cache.set (path, vals);

		if (vals == null)
			return;

		string[] val = new string[vals.size];

		int i = 0;
		foreach (string s in vals) {
			val[i++] = s;
		}

#if HAVE_FAST_EXPERIMENTAL_MODE
		if (!writing_settings_to_disk)
			return;
#endif

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
		enum_cache.unset (path);
		enum_cache.set (path, val);

#if HAVE_FAST_EXPERIMENTAL_MODE
		if (!writing_settings_to_disk)
			return;
#endif

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

	private void set_int(string path, int val) {
		int_cache.unset (path);
		int_cache.set (path, val);

#if HAVE_FAST_EXPERIMENTAL_MODE
		if (!writing_settings_to_disk)
			return;
#endif

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
		string rv = get_string(MUSIC_FOLDER);
		if(rv == "")
			rv = Environment.get_user_special_dir(UserDirectory.MUSIC);
		return rv;
	}

	public string getMusicMountName() {
		return get_string(MUSIC_MOUNT_NAME);
	}
	
	public bool getWindowMaximized() {
		return get_bool(WINDOW_MAXIMIZED);
	}
	
	public int getWindowWidth() {
		return get_int(WINDOW_WIDTH);
	}
	
	public int getWindowHeight() {
		return get_int(WINDOW_HEIGHT);
	}
	
	public int getSidebarWidth() {
		return get_int(SIDEBAR_WIDTH);
	}
	
	public int getMoreWidth() {
		return get_int(MORE_WIDTH);
	}
	
	public bool getMoreVisible() {
		return get_bool(MORE_VISIBLE);
	}
	
	public int getViewMode() {
		return get_int(VIEW_MODE);
	}

	public bool get_miller_columns_enabled () {
		return get_bool(MILLER_COLUMNS_ENABLED);
	}
	
	public int get_miller_columns_width () {
		return get_int(MILLER_WIDTH);
	}
	
	public int get_miller_columns_height () {
		return get_int(MILLER_HEIGHT);
	}

	public int get_miller_columns_position () {
		return get_enum (MILLER_COLUMNS_POSITION);
	}

	public Gee.Collection<string> get_music_miller_visible_columns () {
		return get_strings (MUSIC_MILLER_VISIBLE_COLUMNS);
	}

	public Gee.Collection<string> get_generic_miller_visible_columns () {
		return get_strings (GENERIC_MILLER_VISIBLE_COLUMNS);
	}

	public string getSearchString() {
		return get_string(SEARCH_STRING);
	}
	
	public bool getUpdateFolderHierarchy() {
		return get_bool(UPDATE_FOLDER_HIERARCHY);
	}
	
	public bool getWriteMetadataToFile() {
		return get_bool(WRITE_METADATA_TO_FILE);
	}
	
	public bool getCopyImportedMusic() {
		return get_bool(COPY_IMPORTED_MUSIC);
	}
	
	public bool getDownloadNewPodcasts() {
		return get_bool(DOWNLOAD_NEW_PODCASTS);
	}
	
	public int getLastMediaPlaying() {
		return get_int(LAST_MEDIA_PLAYING);
	}
	
	public int getLastMediaPosition() {
		return get_int(LAST_MEDIA_POSITION);
	}
	
	public int getShuffleMode() {
		return get_int(SHUFFLE_MODE);
	}
	
	public int getRepeatMode() {
		return get_int(REPEAT_MODE);
	}
	
	public string getLastFMSessionKey() {
		return get_string(LASTFM_SESSION_KEY);
	}
	
	public bool getEqualizerEnabled() {
		return get_bool(EQUALIZER_ENABLED);
	}
	
	public string? getSelectedPreset() {
		string rv = get_string(SELECTED_PRESET);
		
		if(rv != null && rv.length == 0)
			return null;

		return rv;
	}
	
	public Gee.Collection<EqualizerPreset> getCustomPresets() {
		return getPresets(get_strings(CUSTOM_PRESETS));
	}

	private Gee.Collection<EqualizerPreset> getPresets(Gee.Collection<string> presets) {
		var rv = new Gee.LinkedList<EqualizerPreset>();

		foreach (var preset in presets) {
			string[] vals = preset.split("/", 0);

			var p = new EqualizerPreset.basic(vals[0]);

			for(int i = 1; i < vals.length; ++i) {
				p.setGain(i - 1, int.parse(vals[i]));
			}

			rv.add(p);
		}
		
		return rv;
	}	

	public bool getAutoSwitchPreset() {
		return get_bool(AUTO_SWITCH_PRESET);
	}
	
	/** Set Values **/
	public void setMusicFolder(string path) {
		set_string(MUSIC_FOLDER, path);
	}
	
	public void setMusicMountName(string path) {
		set_string(MUSIC_MOUNT_NAME, path);
	}
	
	public void setWindowMaximized(bool val) {
		set_bool(WINDOW_MAXIMIZED, val);
	}
	
	public void setWindowWidth(int val) {
		set_int(WINDOW_WIDTH, val);
	}
	
	public void setWindowHeight(int val) {
		set_int(WINDOW_HEIGHT, val);
	}
	
	public void setSidebarWidth(int val) {
		set_int(SIDEBAR_WIDTH, val);
	}
	
	public void setMoreWidth(int val) {
		set_int(MORE_WIDTH, val);
	}
	
	public void setMoreVisible(bool val) {
		set_bool(MORE_VISIBLE, val);
	}
	
	public void setViewMode(int val) {
		set_int(VIEW_MODE, val);
	}

	public void set_miller_columns_enabled (bool val) {
		set_bool(MILLER_COLUMNS_ENABLED, val);
	}

	public void set_miller_columns_width (int val) {
		set_int(MILLER_WIDTH, val);
	}

	public void set_miller_columns_height (int val) {
		set_int(MILLER_HEIGHT, val);
	}

	public void set_miller_columns_position (int val) {
		set_enum (MILLER_COLUMNS_POSITION, val);
	}

	public void set_music_miller_visible_columns (Gee.Collection<string> columns) {
		set_strings (MUSIC_MILLER_VISIBLE_COLUMNS, columns);
	}

	public void set_generic_miller_visible_columns (Gee.Collection<string> columns) {
		set_strings (GENERIC_MILLER_VISIBLE_COLUMNS, columns);
	}

	public void setSearchString(string val) {
		set_string(SEARCH_STRING, val);
	}
	
	public void setUpdateFolderHierarchy(bool val) {
		set_bool(UPDATE_FOLDER_HIERARCHY, val);
	}
	
	public void setWriteMetadataToFile(bool val) {
		set_bool(WRITE_METADATA_TO_FILE, val);
	}
	
	public void setCopyImportedMusic(bool val) {
		set_bool(COPY_IMPORTED_MUSIC, val);
	}
	
	public void setDownloadNewPodcasts(bool val) {
		set_bool(DOWNLOAD_NEW_PODCASTS, val);
	}
	
	public void setLastMediaPlaying(int val) {
		set_int(LAST_MEDIA_PLAYING, val);
	}
	
	public void setLastMediaPosition(int val) {
		set_int(LAST_MEDIA_POSITION, val);
	}
	
	public void setShuffleMode(int val) {
		set_int(SHUFFLE_MODE, val);
	}
	
	public void setRepeatMode(int val) {
		set_int(REPEAT_MODE, val);
	}
	
	public void setLastFMSessionKey(string val) {
		set_string(LASTFM_SESSION_KEY, val);
	}
	
	public void setEqualizerEnabled(bool val) {
		set_bool(EQUALIZER_ENABLED, val);
	}
	
	public void setSelectedPreset(EqualizerPreset? preset) {
		set_string(SELECTED_PRESET, (preset != null)? preset.name : "");
	}

	public void setPresets(Gee.Collection<EqualizerPreset> presets) {
		var vals = new Gee.LinkedList<string> ();

		foreach (var p in presets) {
			string preset = p.name;
			for(int i = 0; i < 10; ++i)
				preset += "/" + p.getGain(i).to_string();
			vals.add (preset);
		}

		set_strings(CUSTOM_PRESETS, vals);
	}

	public void setAutoSwitchPreset(bool val) {
		set_bool(AUTO_SWITCH_PRESET, val);
	}
	
}

