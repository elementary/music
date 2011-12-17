/*-
 * Copyright (c) 2011       Scott Ringwelski <sgringwe@mtu.edu>
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
using Gtk;

/** This is where all the song stuff happens. Here, songs are retrieved
 * from the db, added to the queue, sorted, and more. LibraryWindow is
 * the visual representation of this class
 */
public class BeatBox.LibraryManager : GLib.Object {
	public BeatBox.LibraryWindow lw;
	public BeatBox.Settings settings;
	public BeatBox.DataBaseManager dbm;
	public BeatBox.DataBaseUpdater dbu;
	public BeatBox.FileOperator fo;
	public BeatBox.Streamer player;
	public BeatBox.DeviceManager dm;
	public BeatBox.PodcastManager pm;
	public BeatBox.Icons icons;
	
	private HashMap<int, SmartPlaylist> _smart_playlists; // rowid, smart playlist
	public HashMap<int, Playlist> _playlists; // rowid, playlist of all playlists
	private HashMap<int, Song> _songs; // rowid, song of all songs
	private HashMap<int, Song> _podcasts;
	private HashMap<int, Song> _audiobooks;
	private LinkedList<int> _locals; // list of all local songs
	private HashMap<string, DevicePreferences> _device_preferences;
	
	private HashMap<int, int> _current; // id, song of current songs.
	private HashMap<int, int> _current_shuffled;//list of id's yet to be played while on shuffle
	private HashMap<int, int> _current_view; // id, song of currently showing songs
	private LinkedList<int> _queue; // rowid, Song of queue
	private LinkedList<int> _already_played; // Song of already played
	private HashMap<string, Gdk.Pixbuf> _album_art; // All album art
	
	public LastFM.Core lfm;
	private HashMap<string, LastFM.ArtistInfo> _artists;//key:artist
	private HashMap<string, LastFM.AlbumInfo> _albums;//key:artist<sep>album
	private HashMap<string, LastFM.TrackInfo> _tracks;//key:artist<sep>album<sep>track
	
	public TreeViewSetup music_setup;
	public TreeViewSetup podcast_setup;
	public TreeViewSetup similar_setup;
	public TreeViewSetup queue_setup;
	public TreeViewSetup history_setup;
	
	public int _played_index;//if user press back, this goes back 1 until it hits 0. as new songs play, this goes with it
	public int _current_index;
	public int _current_shuffled_index;
	public BeatBox.SongInfo song_info;
	
	public bool playing;
	public Repeat repeat;
	public Shuffle shuffle;
	
	private string temp_add_folder;
	private LinkedList<string> temp_add_files;
	public bool doing_file_operations;
	
	public signal void music_counted(int count);
	public signal void music_added(LinkedList<string> not_imported);
	public signal void music_imported(LinkedList<Song> new_songs, LinkedList<string> not_imported);
	public signal void music_rescanned(LinkedList<Song> new_songs, LinkedList<string> not_imported);
	public signal void progress_notification(string? message, double progress);
	public signal void file_operations_started();
	public signal void file_operations_done();
	public signal void progress_cancel_clicked();
	
	public signal void current_cleared();
	public signal void song_updated(int id);
	public signal void songs_added(LinkedList<int> ids);
	public signal void songs_updated(LinkedList<int> ids);
	public signal void songs_removed(LinkedList<int> ids);
	public signal void song_queued(int id);
	public signal void song_played(int id, int old_id);
	public signal void playback_stopped(int was_playing);
	
	public enum Shuffle {
		OFF,
		ALL;
	}
	
	public enum Repeat {
		OFF,
		SONG,
		ALBUM,
		ARTIST,
		ALL;
	}
	
	public LibraryManager(BeatBox.Settings sett, BeatBox.LibraryWindow lww, string[] args) {
		this.lw = lww;
		this.player = new Streamer(this, lw, args);
		this.settings = sett;
		
		this.dbm = new DataBaseManager(this);
		this.dbu = new DataBaseUpdater(dbm);
		this.fo = new BeatBox.FileOperator(this, settings);
		this.pm = new PodcastManager(this, lw);
		
		fo.fo_progress.connect(dbProgress);
		dbm.db_progress.connect(dbProgress);
		
		_smart_playlists = new HashMap<int, SmartPlaylist>();
		_playlists = new HashMap<int, Playlist>();
		_songs = new HashMap<int, Song>();
		_podcasts = new HashMap<int, Song>(); // subset of _songs
		_audiobooks = new HashMap<int, Song>(); // subset of _songs
		_locals = new LinkedList<int>();
		_device_preferences = new HashMap<string, DevicePreferences>();
		
		_current = new HashMap<int, int>();
		_current_shuffled = new HashMap<int, int>();
		_current_view = new HashMap<int, int>();
		_queue = new LinkedList<int>();
		_already_played = new LinkedList<int>();
		_album_art = new HashMap<string, Gdk.Pixbuf>();
		
		icons = new Icons(this, lw);
		icons.load_icons();
		
		lfm = new LastFM.Core(this);
		_artists = new HashMap<string, LastFM.ArtistInfo>();
		_albums = new HashMap<string, LastFM.AlbumInfo>();
		_tracks = new HashMap<string, LastFM.TrackInfo>();
		
		_played_index = 0;
		
		song_info = new BeatBox.SongInfo();
		song_info.track = new LastFM.TrackInfo.basic();
		song_info.artist = new LastFM.ArtistInfo.basic();
		song_info.album = new LastFM.AlbumInfo.basic();
		
		int repeatValue = settings.getRepeatMode();
		if(repeatValue == 0)
			repeat = LibraryManager.Repeat.OFF;
		else if(repeatValue == 1)
			repeat = LibraryManager.Repeat.SONG;
		else if(repeatValue == 2)
			repeat = LibraryManager.Repeat.ALBUM;
		else if(repeatValue == 3)
			repeat = LibraryManager.Repeat.ARTIST;
		else if(repeatValue == 4)
			repeat = LibraryManager.Repeat.ALL;
		
		doing_file_operations = false;
		
		music_setup = new TreeViewSetup("Artist", Gtk.SortType.ASCENDING, ViewWrapper.Hint.MUSIC);
		podcast_setup = new TreeViewSetup("Artist", Gtk.SortType.ASCENDING, ViewWrapper.Hint.PODCAST);
		similar_setup = new TreeViewSetup("#", Gtk.SortType.ASCENDING, ViewWrapper.Hint.SIMILAR);
		queue_setup = new TreeViewSetup("#", Gtk.SortType.ASCENDING, ViewWrapper.Hint.QUEUE);
		history_setup = new TreeViewSetup("#", Gtk.SortType.ASCENDING, ViewWrapper.Hint.HISTORY);
		
		//load all songs from db
		foreach(Song s in dbm.load_songs()) {
			_songs.set(s.rowid, s);
			_locals.add(s.rowid);
			
			if(s.mediatype == 1)
				_podcasts.set(s.rowid, s);
			if(s.mediatype == 2)
				_audiobooks.set(s.rowid, s);
		}
		
		if(_songs.size == 0)
			settings.setMusicFolder("");
		
		foreach(SmartPlaylist p in dbm.load_smart_playlists()) {
			_smart_playlists.set(p.rowid, p);
		}
		
		//load all playlists from db
		stdout.printf("loading playlists\n");
		foreach(Playlist p in dbm.load_playlists()) {
			_playlists.set(p.rowid, p);
			
			if(p.name == "autosaved_music") {
				music_setup = p.tvs;
				_playlists.unset(p.rowid);
			}
			else if(p.name == "autosaved_podcast") {
				podcast_setup = p.tvs;
				_playlists.unset(p.rowid);
			}
			else if(p.name == "autosaved_similar") {
				similar_setup = p.tvs;
				_playlists.unset(p.rowid);				
			}
			else if(p.name == "autosaved_queue") {
				foreach(int i in songs_from_playlist(p.rowid)) {
					queue_song_by_id(i);
				}
				
				queue_setup = p.tvs;
				_playlists.unset(p.rowid);
			}
			else if(p.name == "autosaved_history") {
				history_setup = p.tvs;
				_playlists.unset(p.rowid);
			}
		}
		stdout.printf("finished loading playlists\n");
		
		foreach(LastFM.ArtistInfo a in dbm.load_artists()) {
			_artists.set(a.name, a);
		}
		
		foreach(LastFM.AlbumInfo a in dbm.load_albums()) {
			_albums.set(a.name + " by " + a.artist, a);
		}
		
		foreach(LastFM.TrackInfo t in dbm.load_tracks()) {
			_tracks.set(t.name + " by " + t.artist, t);
		}
		
		// set the equalizer
		if(settings.getEqualizerEnabled() && !settings.getAutoSwitchPreset()) {
			set_selected_equalizer_preset ();
		}
		
		// pre-load devices and their preferences
		foreach(DevicePreferences dp in dbm.load_devices()) {
			_device_preferences.set(dp.id, dp);
		}
		
		dm = new DeviceManager(this);
		
		// set the volume
		player.setVolume(settings.getVolume());
		
		// start thread to load all the songs pixbuf's and to load playlists
		try {
			Thread.create<void*>(fetch_thread_function, false);
			//Thread.create<void*>(update_playlists_thread, false);
		}
		catch(GLib.ThreadError err) {
			stdout.printf("Could not create thread to load song pixbuf's: %s \n", err.message);
		}
	}
	
	/************ Library/Collection management stuff ************/
	public virtual void dbProgress(string? message, double progress) {
		progress_notification(message, progress);
	}
	
	public bool doProgressNotificationWithTimeout() {
		if(doing_file_operations)
			progress_notification(null, (double)((double)fo.index)/((double)fo.item_count));
		
		if(fo.index < fo.item_count && doing_file_operations) {
			return true;
		}
		
		return false;
	}
	
	/* warning! this sets the music folder in the process */
	public void count_music_files(GLib.File folder) {
		if(!doing_file_operations) {
			doing_file_operations = true;
			settings.setMusicFolder(folder.get_path());
			
			try {
				Thread.create<void*>(count_files_thread_function, false);
			}
			catch(GLib.Error err) {
				stdout.printf("Could not create thread to count music files: %s\n", err.message);
			}
		}
	}
	
	public void* count_files_thread_function () {
		var file = GLib.File.new_for_path(settings.getMusicFolder());
		
		fo.index = 0;
		var items = fo.count_music_files(file);
		
		Idle.add( () => {
			doing_file_operations = false;
			music_counted(items);
			return false;
		});
		
		file_operations_done();
		return null;
	}
	
	public void set_music_folder(string folder) {
		if(!doing_file_operations) {
			doing_file_operations = true;
			progress_notification("Importing music from <b>" + folder + "</b>.", 0.0);
			
			clear_songs();
			_queue.clear();
			dbm.clear_songs();
			lw.resetSideTree();
			
			foreach(int i in _songs.keys) {
				stdout.printf("remainging: %d %s\n", i, song_from_id(i).title);
			}
			
			settings.setMusicFolder(folder);
			try {
				Thread.create<void*>(set_music_thread_function, false);
			}
			catch(GLib.Error err) {
				stdout.printf("Could not create thread to set music folder: %s\n", err.message);
			}
		}
	}
        
        // i should do the actual file browsing here
	public void* set_music_thread_function () {
		var file = GLib.File.new_for_path(settings.getMusicFolder());
		
		var items = fo.count_music_files(file);
		
		fo.resetProgress(items);
		Timeout.add(100, doProgressNotificationWithTimeout);
		
		var new_songs = new LinkedList<Song>();
		var not_imported = new LinkedList<string>();
		
		stdout.printf("setting music folder\n");
		fo.get_music_files_set(file, ref new_songs, ref not_imported);
		
		add_songs(new_songs, true);
		
		Idle.add( () => { 
			doing_file_operations = false;
			
			music_added(not_imported);
			
			try {
				Thread.create<void*>(fetch_thread_function, false);
			}
			catch(GLib.ThreadError err) {
				stdout.printf("Could not create thread to load song pixbuf's: %s \n", err.message);
			}
			
			return false;
		});
		
		file_operations_done();
		return null;
	}
	
	public void add_files_to_library(LinkedList<string> files) {
		if(!doing_file_operations) {
			doing_file_operations = true;
			progress_notification("Adding files to library. This may take a while...", 0.0);
			
			temp_add_files = files;
			try {
				Thread.create<void*>(add_files_to_library_thread, false);
			}
			catch(GLib.Error err) {
				stdout.printf("Could not create thread to add music files: %s\n", err.message);
			}
		}
	}
	
	public void* add_files_to_library_thread () {
		//music_counted(temp_add_files.size);
		fo.resetProgress(temp_add_files.size - 1);
		Timeout.add(100, doProgressNotificationWithTimeout);
		
		var new_songs = new LinkedList<Song>();
		var not_imported = new LinkedList<string>();
		fo.get_music_files_individually(temp_add_files, ref new_songs, ref not_imported);
		
		fo.resetProgress(new_songs.size);
		
		if(settings.getCopyImportedMusic())
			progress_notification("<b>Copying</b> files to <b>Music Folder</b>...", 0.0);
		
		Timeout.add(100, doProgressNotificationWithTimeout);
		
		foreach(Song s in new_songs) {
			if(settings.getCopyImportedMusic())
				fo.update_file_hierarchy(s, false);
			
			fo.index++;
		}
		
		Idle.add( () => { 
			add_songs(new_songs, true);
			
			doing_file_operations = false;
			music_imported(new_songs, not_imported);
			
			try {
				Thread.create<void*>(fetch_thread_function, false);
			}
			catch(GLib.ThreadError err) {
				stdout.printf("Could not create thread to load song pixbuf's: %s \n", err.message);
			}
			
			return false; 
		});
		
		file_operations_done();
		return null;
	}
	
	public void add_folder_to_library(string folder) {
		if(!doing_file_operations) {
			doing_file_operations = true;
			progress_notification("Adding music from <b>" + folder + "</b> to library. This may take a while...", 0.0);
			
			temp_add_folder = folder;
			try {
				Thread.create<void*>(add_folder_to_library_thread, false);
			}
			catch(GLib.Error err) {
				stdout.printf("Could not create thread to add music folder: %s\n", err.message);
			}
		}
	}
	
	public void* add_folder_to_library_thread () {
		var file = GLib.File.new_for_path(temp_add_folder);
		
		var items = fo.count_music_files(file);
		//music_counted(items);
		fo.resetProgress(items);
		Timeout.add(100, doProgressNotificationWithTimeout);
		
		var new_songs = new LinkedList<Song>();
		var not_imported = new LinkedList<string>();
		fo.get_music_files_folder(file, ref new_songs, ref not_imported);
		
		fo.resetProgress(new_songs.size);
		Timeout.add(100, doProgressNotificationWithTimeout);
		
		progress_notification("<b>Copying</b> files to <b>Music Folder</b>...", 0.0);
		
		foreach(Song s in new_songs) {
			if(settings.getCopyImportedMusic())
				fo.update_file_hierarchy(s, false);
			
			fo.index++;
		}
		
		Idle.add( () => { 
			add_songs(new_songs, true);
			
			doing_file_operations = false;
			music_imported(new_songs, not_imported);
			
			try {
				Thread.create<void*>(fetch_thread_function, false);
			}
			catch(GLib.ThreadError err) {
				stdout.printf("Could not create thread to load song pixbuf's: %s \n", err.message);
			}
			
			return false; 
		});
		
		file_operations_done();
		return null;
	}
    
	public void rescan_music_folder() {
		if(!doing_file_operations) {
			doing_file_operations = true;
			progress_notification("Rescanning music for changes. This may take a while...", 0.0);
			
			try {
					Thread.create<void*>(rescan_music_thread_function, false);
			}
			catch(GLib.Error err) {
					stdout.printf("Could not create thread to rescan music folder: %s\n", err.message);
			}
		}
	}
        
	public void* rescan_music_thread_function () {
		LinkedList<string> paths = new LinkedList<string>();
		LinkedList<Song> removed = new LinkedList<Song>();
		
		string music_folder = settings.getMusicFolder();
		foreach(Song s in _songs.values) {
			if(!s.isTemporary && !s.isPreview && s.file.has_prefix(music_folder))
				paths.add(s.file);
		}
		
		fo.resetProgress(paths.size);
		Timeout.add(100, doProgressNotificationWithTimeout);
		
		var not_imported = new LinkedList<string>();
		var new_songs = new LinkedList<Song>();
		fo.rescan_music(GLib.File.new_for_path(music_folder), ref paths, ref not_imported, ref new_songs);
		
		// all songs remaining are no longer in folder hierarchy
		lock(_songs) {
			foreach(Song s in _songs.values) {
				foreach(string path in paths) {
					if(s.file == path && !s.isTemporary && !s.isPreview && s.file.has_prefix(music_folder)) {
						removed.add(s);
					}
				}
			}
		}
		
		dbm.remove_songs(paths);
		
		Idle.add( () => {
			remove_songs(removed, false);
			add_songs(new_songs, true);
			
			foreach(Song s in new_songs) {
				if(settings.getCopyImportedMusic())
					fo.update_file_hierarchy(s, false);
			}
			
			doing_file_operations = false;
			music_rescanned(new_songs, not_imported); 
			
			try {
				Thread.create<void*>(fetch_thread_function, false);
			}
			catch(GLib.ThreadError err) {
				stdout.printf("Could not create thread to load song pixbuf's: %s \n", err.message);
			}
			
			return false; 
		});
		
		file_operations_done();
		return null;
	}
	
	/************************ Playlist stuff ******************/
	public int playlist_count() {
		return _playlists.size;
	}
	
	public Collection<Playlist> playlists() {
		return _playlists.values;
	}
	
	public HashMap<int, Playlist> playlist_hash() {
		return _playlists;
	}
	
	public void save_playlists() {
		try {
			lock(_playlists) {
				Thread.create<void*>( () => {
					var playlists_and_queue = new LinkedList<Playlist>();
					playlists_and_queue.add_all(_playlists.values);
					
					Playlist p_queue = new Playlist();
					p_queue.name = "autosaved_queue";
					foreach(int i in _queue) {
						p_queue.addSong(i);
					}
					p_queue.tvs = queue_setup;
					
					Playlist p_history = new Playlist();
					p_history.name = "autosaved_history";
					p_history.tvs = history_setup;
					
					Playlist p_similar = new Playlist();
					p_similar.name = "autosaved_similar";
					p_similar.tvs = similar_setup;
					
					Playlist p_music = new Playlist();
					p_music.name = "autosaved_music";
					p_music.tvs = music_setup;
					
					Playlist p_podcast = new Playlist();
					p_podcast.name = "autosaved_podcast";
					p_podcast.tvs = podcast_setup;
					
					playlists_and_queue.add(p_queue);
					playlists_and_queue.add(p_history);
					playlists_and_queue.add(p_similar);
					playlists_and_queue.add(p_music);
					playlists_and_queue.add(p_podcast);
					
					dbm.save_playlists(playlists_and_queue);
					return null; 
				}, false);
			}
		}
		catch(GLib.Error err) {
			stdout.printf("Could not create thread to save playlists: %s\n", err.message);
		}
	}
	
	public Playlist playlist_from_id(int id) {
		return _playlists.get(id);
	}
	
	public Playlist? playlist_from_name(string name) {
		foreach(var p in _playlists.values) {
			if(p.name == name)
				return p;
		}
		
		return null;
	}
	
	public int add_playlist(Playlist p) {
		p.rowid = _playlists.size + 1;
		_playlists.set(p.rowid, p);
		
		save_playlists();
		
		return p.rowid;
	}
	
	public void remove_playlist(int id) {
		Playlist removed;
		_playlists.unset(id, out removed);
		
		dbu.removeItem(removed);
	}
	
	/**************** Smart playlists ****************/
	public int smart_playlist_count() {
		return _smart_playlists.size;
	}
	
	public Collection<SmartPlaylist> smart_playlists() {
		return _smart_playlists.values;
	}
	
	public HashMap<int, SmartPlaylist> smart_playlist_hash() {
		return _smart_playlists;
	}
	
	public SmartPlaylist smart_playlist_from_id(int id) {
		return _smart_playlists.get(id);
	}
	
	public void save_smart_playlists() {
		try {
			Thread.create<void*>( () => { 
				lock(_smart_playlists) {
					dbm.save_smart_playlists(_smart_playlists.values);
				}
				
				return null; 
			}, false);
		}
		catch(GLib.Error err) {
			stdout.printf("Could not create thread to save smart playlists: %s\n", err.message);
		}
	}
	
	public int add_smart_playlist(SmartPlaylist p) {
		p.rowid = _smart_playlists.size + 1;// + 1 for 1-based db
		_smart_playlists.set(p.rowid, p);
		
		save_smart_playlists();
		
		return p.rowid;
	}
	
	public void remove_smart_playlist(int id) {
		SmartPlaylist removed;
		_smart_playlists.unset(id, out removed);
		
		dbu.removeItem(removed);
	}
	
	/******************** Song stuff ******************/
	public void clear_songs() {
		var unset = new HashMap<int, Song>();
		foreach(int i in _songs.keys) {
			Song s = _songs.get(i);
			if(!(s.isTemporary || s.isPreview || s.file.has_prefix("http://"))) {
				if(s.mediatype == 1 && s.podcast_url != null && s.podcast_url.has_prefix("http://")) {
					s.file = s.podcast_url;
				}
				else {
					unset.set(i, s);
					_podcasts.unset(i);
					_audiobooks.unset(i);
					_locals.remove(i);
				}
			}
		}
		
		_songs.unset_all(unset);
	}
	
	public int song_count() {
		return _songs.size;
	}
	
	public Collection<Song> songs() {
		return _songs.values;
	}
	
	public Collection<int> song_ids() {
		return _songs.keys;
	}
	
	public Collection<int> podcast_ids() {
		return _podcasts.keys;
	}
	
	public Collection<int> audiobook_ids() {
		return _audiobooks.keys;
	}
	
	public HashMap<int, Song> song_hash() {
		return _songs;
	}
	
	public void update_song(Song s, bool updateMeta, bool record_time) {
		LinkedList<Song> one = new LinkedList<Song>();
		one.add(s);
		
		update_songs(one, updateMeta, record_time);
	}
	
	public void update_songs(Collection<Song> updates, bool updateMeta, bool record_time) {
		LinkedList<int> rv = new LinkedList<int>();
		
		foreach(Song s in updates) {
			/*_songs.set(s.rowid, s);*/
			rv.add(s.rowid);
			
			if(record_time)
				s.last_modified = (int)time_t();
		}
		
		songs_updated(rv);
		if(updates.size == 1)
			song_updated(updates.to_array()[0].rowid);
		
		/* now do background work */
		if(updateMeta)
			fo.save_songs(updates);
		
		dbu.updateItem(updates);
		
		// mark all smart playlists as not up to date
		//foreach(SmartPlaylist sp in _smart_playlists.values) {
		//	sp.is_up_to_date = false;
		//}
		
		foreach(Widget w in lw.mainViews.get_children()) {
			if(w.visible && w is ViewWrapper && ((ViewWrapper)w).isCurrentView) {
				ViewWrapper vw = (ViewWrapper)w;
				
				if(vw.list.get_hint() == ViewWrapper.Hint.SMART_PLAYLIST)
					vw.doUpdate(vw.currentView, songs_from_smart_playlist(vw.list.get_relative_id()), false, true);
			}
		}
		
		// now update all non-showing views
		try {
			Thread.create<void*>(update_views_thread, false);
		} 
		catch(GLib.ThreadError err) {
			stdout.printf("ERROR: Could not create thread to update hidden views: %s \n", err.message);
		}
	}
	
	public void* update_views_thread () {
		// update them
		foreach(Widget w in lw.mainViews.get_children()) {
			if(!w.visible && w is ViewWrapper) {
				ViewWrapper vw = (ViewWrapper)w;
				vw.doUpdate(vw.currentView, vw.songs, false, false);
			}
		}
		
		return null;
	}
	
	public void save_songs() {
		try {
			Thread.create<void*>( () => { 
				lock(_songs) {
					dbm.update_songs(_songs.values);
				} 
				
				return null; 
			}, false);
		}
		catch(GLib.Error err) {
			stdout.printf("Could not create thread to save songs: %s\n", err.message);
		}
	}
	
	/** Used extensively. All other song data stores a song rowid, and then
	 * use this to retrieve the song. This is for memory saving and 
	 * consistency
	 */
	public Song song_from_id(int id) {
		return _songs.get(id);
	}
	
	public Song song_from_name(string title, string artist) {
		Song rv = new Song("");
		rv.title = title;
		rv.artist = artist;
		Song[] searchable;
		
		lock(_songs) {
			searchable = _songs.values.to_array();
		}
		
		for(int i = 0; i < searchable.length; ++i) {
			Song s = searchable[i];
			if(s.title.down() == title.down() && s.artist.down() == artist.down())
				return s;
		}
		
		return rv;
	}
	
	public Song? song_from_file(string file) {
		lock(_songs) {
			foreach(Song s in _songs.values) {
				if(s.file == file)
					return s;
			}
		}
		
		return null;
	}
	
	public void do_search(string search, ViewWrapper.Hint hint,string genre, string artist, string album,
	Collection<int> to_search, ref Collection<int> results, ref Collection<int> album_results) {
		string l_search = search.down();
		int mediatype = 0;
		bool include_temps = (hint == ViewWrapper.Hint.CDROM || hint == ViewWrapper.Hint.DEVICE_AUDIO || 
						hint == ViewWrapper.Hint.DEVICE_PODCAST || hint == ViewWrapper.Hint.DEVICE_AUDIOBOOK ||
						hint == ViewWrapper.Hint.QUEUE || hint == ViewWrapper.Hint.HISTORY);
		
		if(hint == ViewWrapper.Hint.PODCAST || hint == ViewWrapper.Hint.DEVICE_PODCAST) {
			mediatype = 1;
		}
		else if(hint == ViewWrapper.Hint.AUDIOBOOK || hint == ViewWrapper.Hint.DEVICE_AUDIOBOOK) {
			mediatype = 2;
		}
		else if(hint == ViewWrapper.Hint.QUEUE || hint == ViewWrapper.Hint.HISTORY ||
		hint == ViewWrapper.Hint.PLAYLIST || hint == ViewWrapper.Hint.SMART_PLAYLIST) {
			mediatype = 3; // some lists should be able to have ALL media types
		}
		
		foreach(int i in to_search) {
			Song s = song_from_id(i);
			if(s != null && (s.mediatype == mediatype || mediatype == 3) && (!s.isTemporary || include_temps) &&
			(l_search in s.title.down() || l_search in s.artist.down() || l_search in s.album.down() || l_search in s.genre.down())) {
				if((genre == "All Genres" || s.genre == genre) && (artist == "All Artists" || s.artist == artist))
					if(album == "All Albums" || s.album == album) {
						results.add(i);
					}
					
					album_results.add(i);
			}
		}
	}
	
	public LinkedList<int> songs_from_playlist(int id) {
		return _playlists.get(id).analyze(this);
	}
	
	public LinkedList<int> songs_from_smart_playlist(int id) {
		return _smart_playlists.get(id).analyze(this);
	}
	
	public void add_song(Song s, bool permanent) {
		var coll = new LinkedList<Song>();
		coll.add(s);
		add_songs(coll, permanent);
	}
	
	public void add_songs(Collection<Song> new_songs, bool permanent) {
		int top_index = 0;
		
		lock(_songs) {
			foreach(int i in _songs.keys) {
				if(i > top_index)
					top_index = i;
			}
		}
		
		var added = new LinkedList<int>();
		foreach(var s in new_songs) {
			if(s.rowid == 0)
				s.rowid = ++top_index;
			
			added.add(s.rowid);
			_songs.set(s.rowid, s);
			
			if(permanent && !s.isTemporary)
				_locals.add(s.rowid);
			if(s.mediatype == 1)
				_podcasts.set(s.rowid, s);
			if(s.mediatype == 2)
				_audiobooks.set(s.rowid, s);
		}
		
		if(new_songs.size > 0 && new_songs.to_array()[0].rowid != -2 && permanent) {
			dbm.add_songs(new_songs);
		}
		
		Idle.add( () => {
			songs_added(added);
			
			return false;
		});
	}
	
	public void remove_songs(LinkedList<Song> toRemove, bool trash) {
		LinkedList<int> removedIds = new LinkedList<int>();
		LinkedList<string> removePaths = new LinkedList<string>();
		
		//string file_path = song_from_id(id).file;
		foreach(Song s in toRemove) {
			removedIds.add(s.rowid);
			removePaths.add(s.file);
		}
		
		// TODO: Check why this is in the order it is
		dbu.removeItem(removePaths);
		
		if(trash) {
			fo.remove_songs(removePaths);
		}
		
		foreach(Song s in toRemove) {
			_songs.unset(s.rowid);
			_locals.remove(s.rowid);
			
			if(s.mediatype == 1)
				_podcasts.unset(s.rowid);
			else if(s.mediatype == 2)
				_audiobooks.unset(s.rowid);
				
			foreach(var p in _playlists.values) {
				p.removeSong(s.rowid);
			}
		}
		
		songs_removed(removedIds);
		
		if(_songs.size == 0)
			settings.setMusicFolder("");
		
		lw.updateSensitivities();
	}
	
	/**************** Queue Stuff **************************/
	public bool queue_empty() {
		return (_queue.size == 0);
	}
	
	public void clear_queue() {
		_queue.clear();
	}
	
	public void queue_song_by_id(int id) {
		_queue.offer_tail(id);
	}
	
	public void unqueue_song_by_id(int id) {
		_queue.remove(id);
	}
	
	public int peek_queue() {
		return _queue.peek_head();
	}
	
	public int poll_queue() {
		return _queue.poll_head();
	}
	
	public Collection<int> queue() {
		return _queue;
	}
	
	/************ Already Played Stuff **************/
	public void reset_already_played() {
		_already_played.clear();
	}
	
	public void add_already_played(int i) {
		_already_played.offer_tail(i);
	}
	
	public LinkedList<int> already_played() {
		return _already_played;
	}
	
	/************ Current songlist stuff ***************/
	public bool is_shuffled() {
		return _current_shuffled.size > 0;
	}
	
	/* value returned depends on whether shuffle is on or not */
	public int current_index {
		get {
			if(_current_shuffled.size == 0)
				return _current_index;
			else
				return _current_shuffled_index;
		}
		set {
			if(_current_shuffled.size == 0)
				_current_index = value;
			else {
				stdout.printf("just set _current_shuffled_index to %d\n", value);
				_current_shuffled_index = value;
			}
		}
	}
	
	public int songFromCurrentIndex(int index_in_current) {
		if(shuffle == Shuffle.OFF)
			return _current.get(index_in_current);
		else
			return _current_shuffled.get(index_in_current);
	}
	
	public Collection<int> current_songs() {
		if(shuffle == Shuffle.OFF)
			return _current_shuffled.values;
		else
			return _current.values;
	}
	
	public void clearCurrent() {
		current_cleared();
		_current.clear();
		
		shuffle = Shuffle.OFF; // must manually reshuffle
	}
	
	public void addToCurrent(int i) {
		_current.set(_current.size, i);
	}
	
	public void setShuffleMode(Shuffle mode, bool reshuffle) {
		/*if(mode == shuffle)
			return;
		*/
		settings.setShuffleMode(mode);
		shuffle = mode;
		
		if(!reshuffle)
			return;
		
		_current_shuffled.clear();
		_current_shuffled_index = 0;
		
		if(mode == Shuffle.OFF) {
			if(song_info.song != null) {
				//make sure we continue playing where we left off
				for(int i = 0; i < _current.size; ++i) {
					if(_current.get(i) == song_info.song.rowid) {
						_current_index = i;
						return;
					}
				}
			}
			else {
				_current_index = 0;
			}
		}
		else if(mode == Shuffle.ALL) {
			//create temp list of all of current's song id's
			LinkedList<int> temp = new LinkedList<int>();
			foreach(int i in _current.values) {
				temp.add(i);
			}
			
			//loop through all current song id's and pick a random one remaining
			//and set that int i as one of those this is confusing just a sort
			//_current_shuffled.set(0, song_info.song.rowid);
			for(int i = 1;i < _current.size; ++i) {
				int random = GLib.Random.int_range(0, temp.size);
				
				//if(temp.get(random) != song_info.song.rowid) {
				if(song_info.song != null && temp.get(random) == song_info.song.rowid) {
					_current_shuffled.set(0, song_info.song.rowid);
					--i;
				}
				else {
					_current_shuffled.set(i, temp.get(random));
				}
				temp.remove(temp.get(random));
			}
		}
	}
	
	public int getNext(bool play) {
		int rv;
		
		// next check if user has queued songs
		if(!queue_empty()) {
			rv = poll_queue();
		}
		else if(_current_shuffled.size != 0) {
			if(song_info.song == null) {
				_current_shuffled_index = 0;
				rv = _current_shuffled.get(0);
			}
			else if(repeat == Repeat.SONG) {
				rv = _current_shuffled.get(_current_shuffled_index);
			}
			else if(_current_shuffled_index == (_current_shuffled.size - 1)) {// consider repeat options
				if(repeat == Repeat.ALL)
					_current_shuffled_index = 0;
				else {
					/* reset to no song playing */
					song_info.song = null;
					_current_shuffled.clear();
					_current.clear();
					_current_shuffled_index = 0;
					_current_index = 0;
					return 0;
				}
				
				rv = _current_shuffled.get(0);
			}
			else if(_current_shuffled_index >= 0 && _current_shuffled_index < (_current_shuffled.size - 1)){
				// make sure we are repeating what we need to be
				if(repeat == Repeat.ARTIST && song_from_id(_current_shuffled.get(_current_shuffled_index + 1)).artist != song_from_id(_current_shuffled.get(_current_shuffled_index)).artist) {
					while(song_from_id(_current_shuffled.get(_current_shuffled_index - 1)).artist == song_info.song.artist)
						--_current_shuffled_index;
				}
				else if(repeat == Repeat.ALBUM && song_from_id(_current_shuffled.get(_current_shuffled_index + 1)).album != song_from_id(_current_shuffled.get(_current_shuffled_index)).album) {
					while(song_from_id(_current_shuffled.get(_current_shuffled_index - 1)).album == song_info.song.album)
						--_current_shuffled_index;
				}
				else {
					++_current_shuffled_index;
				}
				
				rv = _current_shuffled.get(_current_shuffled_index);
			}
			else {
				foreach(Song s in _songs.values)
					addToCurrent(s.rowid);
				
				_current_shuffled_index = 0;
				setShuffleMode(Shuffle.ALL, true);
				rv = _current_shuffled.get(0);
			}
		}
		else {
			if(song_info.song == null) {
				_current_index = 0;
				rv = _current.get(0);
			}
			else if(repeat == Repeat.SONG) {
				rv = _current.get(_current_index);
			}
			else if(_current_index == (_current.size - 1)) {// consider repeat options
				if(repeat == Repeat.ALL)
					_current_index = 0;
				else {
					stopPlayback();
					return 0;
				}
				
				rv = _current.get(0);
			}
			else if(_current_index >= 0 && _current_index < (_current.size - 1)){
				// make sure we are repeating what we need to be
				if(repeat == Repeat.ARTIST && song_from_id(_current.get(_current_index + 1)).artist != song_from_id(_current.get(_current_index)).artist) {
					while(song_from_id(_current.get(_current_index - 1)).artist == song_info.song.artist)
						--_current_index;
				}
				else if(repeat == Repeat.ALBUM && song_from_id(_current.get(_current_index + 1)).album != song_from_id(_current.get(_current_index)).album) {
					while(song_from_id(_current.get(_current_index - 1)).album == song_info.song.album)
						--_current_index;
				}
				else
					++_current_index;
				
				rv = _current.get(_current_index);
			}
			else {
				foreach(Song s in _songs.values)
					addToCurrent(s.rowid);
				
				_current_index = 0;
				rv = _current.get(0);
			}
		}
		
		if(play)
			playSong(rv);
		
		return rv;
	}
	
	public int getPrevious(bool play) {
		int rv;
		
		if(_current_shuffled.size != 0) {
			if(song_info.song == null) {
				_current_shuffled_index = _current_shuffled.size - 1;
				rv = _current_shuffled.get(_current_shuffled_index);
			}
			else if(repeat == Repeat.SONG) {
				rv = _current_shuffled.get(_current_shuffled_index);
			}
			else if(_current_shuffled_index == 0) {// consider repeat options
				if(repeat == Repeat.ALL)
					_current_shuffled_index = _current_shuffled.size - 1;
				else {
					stopPlayback();
					return 0;
				}
				
				rv = _current_shuffled.get(_current_shuffled_index);
			}
			else if(_current_shuffled_index > 0 && _current_shuffled_index < _current_shuffled.size){
				// make sure we are repeating what we need to be
				if(repeat == Repeat.ARTIST && song_from_id(_current_shuffled.get(_current_shuffled_index - 1)).artist != song_from_id(_current_shuffled.get(_current_shuffled_index)).artist) {
					while(song_from_id(_current_shuffled.get(_current_shuffled_index + 1)).artist == song_info.song.artist)
						++_current_shuffled_index;
				}
				else if(repeat == Repeat.ALBUM && song_from_id(_current_shuffled.get(_current_shuffled_index - 1)).album != song_from_id(_current_shuffled.get(_current_shuffled_index)).album) {
					while(song_from_id(_current_shuffled.get(_current_shuffled_index + 1)).album == song_info.song.album)
						++_current_shuffled_index;
				}
				else
					--_current_shuffled_index;
				
				rv = _current_shuffled.get(_current_shuffled_index);
			}
			else {
				foreach(Song s in _songs.values)
					addToCurrent(s.rowid);
				
				_current_shuffled_index = _current_shuffled.size - 1;
				rv = _current_shuffled.get(_current_shuffled_index);
			}
		}
		else {
			if(song_info.song == null) {
				_current_index = _current.size - 1;
				rv = _current.get(_current_index);
			}
			else if(repeat == Repeat.SONG) {
				rv = _current.get(_current_index);
			}
			else if(_current_index == (0)) {// consider repeat options
				if(repeat == Repeat.ALL)
					_current_index = _current.size - 1;
				else {
					stopPlayback();
					return 0;
				}
				
				rv = _current.get(_current_index);
			}
			else if(_current_index > 0 && _current_index < _current.size){
				// make sure we are repeating what we need to be
				if(repeat == Repeat.ARTIST && song_from_id(_current.get(_current_index - 1)).artist != song_from_id(_current.get(_current_index)).artist) {
					while(song_from_id(_current.get(_current_index + 1)).artist == song_info.song.artist)
						++_current_index;
				}
				else if(repeat == Repeat.ALBUM && song_from_id(_current.get(_current_index - 1)).album != song_from_id(_current.get(_current_index)).album) {
					while(song_from_id(_current.get(_current_index + 1)).album == song_info.song.album)
						++_current_index;
				}
				else
					--_current_index;
				
				rv = _current.get(_current_index);
			}
			else {
				foreach(Song s in _songs.values)
					addToCurrent(s.rowid);
				
				_current_index = _current.size - 1;
				rv = _current.get(_current_index);
			}
		}
		
		if(play)
			playSong(rv);
		
		return rv;
	}
	
	public void playSong(int id) {
		int old_id = -1;
		
		if(id == 0 || song_from_id(id) == null)
			return;
		
		// save previous song's id
		if(song_info.song != null)
			old_id = song_info.song.rowid;
		
		// set the current song
		song_info.song = song_from_id(id);
		
		// check that the file exists
		if(!GLib.File.new_for_path(song_from_id(id).file).query_exists() && song_from_id(id).file.contains(settings.getMusicFolder())) {
			song_from_id(id).unique_status_image = icons.process_error_icon;
			lw.song_not_found(id);
			return;
		}
		else {
			song_from_id(id).unique_status_image = null;
		}
		
		// actually play the song asap
		if(!song_from_id(id).isPreview && !song_from_id(id).file.contains("cdda://") && !song_from_id(id).file.contains("http://")) // normal file
			player.setURI("file://" + song_from_id(id).file);
		else
			player.setURI(song_from_id(id).file); // probably cdda
		
		//pause if paused
		if(!playing)
			player.pause();
		
		//update settings
		if(id != -2)
			settings.setLastSongPlaying(id);
		
		song_played(id, old_id);
		
		try {
			Thread.create<void*>(change_gains_thread, false);
		}
		catch(GLib.Error err) {
			stdout.printf("Could not create thread to change gains: %s\n", err.message);
		}
		
		/* if same song 1 second later...
		 * check for embedded art if need be (not loaded from on file) and use that
		 * check that the s.getAlbumArtPath() exists, if not set to "" and call updateCurrentSong
		 */
		Timeout.add(1000, () => {
			
			if(song_info.song.rowid == id) {
				if(!File.new_for_path(song_info.song.getAlbumArtPath()).query_exists()) {
					song_info.song.setAlbumArtPath("");
					lw.updateCurrentSong();
				}
				
				// potentially fix song length
				if((player.getDuration()/1000000000) > 1) {
					song_info.song.length = (int)(player.getDuration()/1000000000);
					update_song(song_info.song, true, false);
				}
			}
			
			return false;
			
		});
	}
	
	public void* change_gains_thread () {
		if(settings.getAutoSwitchPreset() && settings.getEqualizerEnabled()) {
			bool matched_genre = false;
			foreach(var p in settings.getPresets(null)) {
				if(p != null && song_info.song != null && p.name.down() == song_info.song.genre.down()) {
					
					matched_genre = true;
					
					for(int i = 0; i < 10; ++i)
						player.setEqualizerGain(i, p.getGain(i));
					
					break;
				}
			}
			
			if(!matched_genre) {
				set_selected_equalizer_preset ();
			}
		}
		
		return null;
	}
	
	public void playTrackPreview(Store.Track track, string uri) {
		Song s = new Song(uri);
		s.isPreview = true;
		s.rowid = -2;
		s.title = track.title;
		s.artist = track.artist.name;
		s.album = track.release.title;
		s.length = 30;
		
		LinkedList<Song> temps = new LinkedList<Song>();
		temps.add(s);
		add_songs(temps, false);
		
		playSong(-2);
		
		if(!playing) {
			lw.playClicked();
		}
	}
	
	public void stopPlayback() {
		player.pause();
		
		int was_playing = 0;
		if(song_info.song != null)
			was_playing = song_info.song.rowid;
		
		settings.setLastSongPlaying(0);
		song_info.update(null, null, null, null);
		
		playback_stopped(was_playing);
	}
	
	/************* Last FM Artist Stuff ************/
	public void save_artist(LastFM.ArtistInfo artist) {
		_artists.set(artist.name, artist);
		
		save_artists();
	}
	
	public void save_artists() {
		try {
			Thread.create<void*>( () => { 
				lock(_artists) {
					dbm.save_artists(_artists.values);
				}
				
				return null; 
			}, false);
		}
		catch(GLib.Error err) {
			stdout.printf("Could not create thread to save last fm artists: %s\n", err.message);
		}
	}
	
	public bool artist_info_exists(string artist_key) {
		return _artists.has_key(artist_key);
	}
	
	public LastFM.ArtistInfo? get_artist(string artist_key) {
		if(artist_info_exists(artist_key))	
			return _artists.get(artist_key);
			
		return null;
	}
	
	/************** LastFM Album stuff **************/
	public void save_album(LastFM.AlbumInfo album) {
		_albums.set(album.name + " by " + album.artist, album);
		
		save_albums();
	}
	
	public void save_albums() {
		try {
			Thread.create<void*>( () => { 
				lock(_albums) {
					dbm.save_albums(_albums.values);
				}
				
				return null; 
			}, false);
		}
		catch(GLib.Error err) {
			stdout.printf("Could not create thread to save last fm albums: %s\n", err.message);
		}
	}
	
	public bool album_info_exists(string album_key) {
		return _albums.has_key(album_key);
	}
	
	public LastFM.AlbumInfo? get_album(string album_key) {
		if(album_info_exists(album_key))	
			return _albums.get(album_key);
			
		return null;
	}
	
	/************** Last FM Track Stuff ***************/
	public void save_track(LastFM.TrackInfo track) {
		_tracks.set(track.name + " by " + track.artist, track);
		
		save_tracks();
	}
	
	public void save_tracks() {
		try {
			Thread.create<void*>( () => { 
				lock(_tracks) {
					dbm.save_tracks(_tracks.values);
				}
				
				return null; 
			}, false);
		}
		catch(GLib.Error err) {
			stdout.printf("Could not create thread to save last fm albums: %s\n", err.message);
		}
	}
	
	public bool track_info_exists(string track_key) {
		return _tracks.has_key(track_key);
	}
	
	public LastFM.TrackInfo? get_track(string track_key) {
		if(track_info_exists(track_key))	
			return _tracks.get(track_key);
			
		return null;
	}
	
	/************ Image stuff ********************/
	public string getAlbumArtPath(int id) {
		return _songs.get(id).getAlbumArtPath();
	}
	
	public void save_album_locally(int id, string album) {
		fo.save_album(_songs.get(id), album);
	}
	
	public string getArtistImagePath(int id) {
		return _songs.get(id).getArtistImagePath();
	}
	
	public Gdk.Pixbuf? save_artist_image_locally(int id, string image) {
		return fo.save_artist_image(_songs.get(id), image);
	}
	
	/* at the start, load all the pixbufs */
	public void* fetch_thread_function () {
		
		var toShowS = new LinkedList<Song>();
        foreach(var s in _songs.values)
			toShowS.add(s);
        
        // first sort the songs so we know they are grouped by album artist, album
		toShowS.sort((CompareFunc)songCompareFunc);
		
		string previousAlbum = "";
		foreach(Song s in toShowS) {
			if(s.album != previousAlbum) {
				
				if(!s.getAlbumArtPath().contains("/usr/share/") && _album_art.get(s.artist+s.album) == null) {
					try {
						_album_art.set(s.artist+s.album, new Gdk.Pixbuf.from_file_at_size(s.getAlbumArtPath(), 128, 128));
					}
					catch(GLib.Error err) {}
				}
				
				// also try loading from metadata
				
				previousAlbum = s.album;
			}
		}
		
		return null;

	}
	
	public static int songCompareFunc(Song a, Song b) {
		if(a.album_artist != b.album_artist)
			return (a.album > b.album) ? 1 : -1;
		else
			return (a.album_artist > b.album_artist) ? 1 : -1;
	}
	
	public void cancel_operations() {
		progress_cancel_clicked();
	}
	
	public void set_selected_equalizer_preset () {
		string selected_preset = settings.getSelectedPreset();
		if(selected_preset != null) {
			foreach (EqualizerPreset p in settings.getPresets(null)) {
				if(p.name == selected_preset) {
					for(int i = 0; i < 10; ++i)
						player.setEqualizerGain(i, p.getGain(i));
					break;
				}
			}
		}
	}

	public Gdk.Pixbuf? get_album_art(int id) {
		Song s = _songs.get(id);
		
		if(s == null)
			return null;
		
		return _album_art.get(s.artist+s.album);
	}
	
	/* Device Preferences */
	public DevicePreferences? get_device_preferences(string id) {
		return _device_preferences.get(id);
	}
	
	public void add_device_preferences(DevicePreferences dp) {
		_device_preferences.set(dp.id, dp);
		save_device_preferences();
	}
	
	public void save_device_preferences() {
		try {
			Thread.create<void*>( () => { 
				lock(_device_preferences) {
					dbm.save_devices(_device_preferences.values);
				}
				
				return null; 
			}, false);
		}
		catch(GLib.Error err) {
			stdout.printf("Could not create thread to save device preferences: %s\n", err.message);
		}
	}
}
