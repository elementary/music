/*-
 * Copyright (c) 2011-2012       Scott Ringwelski <sgringwe@mtu.edu>
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

#if 0
public interface BeatBox.LibraryModel {
	public signal void music_counted(int count);
	public signal void music_added(LinkedList<string> not_imported);
	public signal void music_imported(LinkedList<Media> new_medias, LinkedList<string> not_imported);
	public signal void music_rescanned(LinkedList<Media> new_medias, LinkedList<string> not_imported);
	public signal void progress_notification(string? message, double progress);
	public signal void file_operations_started();
	public signal void file_operations_done();
	public signal void progress_cancel_clicked();
	
	public signal void current_cleared();
	public signal void media_updated(int id);
	public signal void medias_added(LinkedList<int> ids);
	public signal void medias_updated(LinkedList<int> ids);
	public signal void medias_removed(LinkedList<int> ids);
	public signal void media_queued(int id);
	public signal void media_played(int id, int old_id);
	public signal void playback_stopped(int was_playing);
	
	public abstract bool playing_queued_song();
	
	public abstract Shuffle shuffle { set; get; }
	
	public abstract BeatBox.MediaInfo media_info { set; get; }
	
	/* FIXME: this should be clear_current to follow style guidelines */
	public abstract void clearCurrent();
	public abstract void addToCurrent(int i);
	public abstract Collection<int> current_medias();
	/* FIXME: style guidelines */
	public abstract void setShuffleMode(LibraryModel.Shuffle mode, bool reshuffle);
	public abstract Media media_from_id(int id);
	public abstract Collection<int> queue();
	public abstract void remove_medias(LinkedList<Media> toRemove, bool trash);
	public abstract void playMedia(int id, bool use_resume_pos);
	
	public abstract int current_index { set; get; }
	
	public enum Shuffle {
		OFF,
		ALL;
	}
	
	public enum Repeat {
		OFF,
		MEDIA,
		ALBUM,
		ARTIST,
		ALL;
	}
}
#endif

/** This is where all the media stuff happens. Here, medias are retrieved
 * from the db, added to the queue, sorted, and more. LibraryWindow is
 * the visual representation of this class
 */
public class BeatBox.LibraryManager : /*BeatBox.LibraryModel,*/ GLib.Object {
	public BeatBox.LibraryWindow lw;
	public BeatBox.Settings settings;
	public BeatBox.DataBaseManager dbm;
	public BeatBox.DataBaseUpdater dbu;
	public BeatBox.FileOperator fo;
	public BeatBox.Streamer player;
	public BeatBox.DeviceManager dm;
	public BeatBox.PodcastManager pm;
	
	private HashMap<int, SmartPlaylist> _smart_playlists; // rowid, smart playlist
	public HashMap<int, Playlist> _playlists; // rowid, playlist of all playlists
	private HashMap<int, Media> _media; // rowid, media of all medias
	private HashMap<int, Media> _songs;
	private HashMap<int, Media> _podcasts;
	private HashMap<int, Media> _audiobooks;
	private HashMap<int, Media> _stations;
	private LinkedList<int> _permanents; // list of all local medias
	private HashMap<string, DevicePreferences> _device_preferences;
	int local_song_count;
	public int current_view_size;
	
	private HashMap<int, int> _current; // id, media of current medias.
	private HashMap<int, int> _current_shuffled;//list of id's yet to be played while on shuffle
	private HashMap<int, int> _current_view; // id, media of currently showing medias
	private LinkedList<int> _queue; // rowid, Media of queue
	private LinkedList<int> _already_played; // Media of already played
	private HashMap<string, Gdk.Pixbuf> cover_album_art; // All album art
	
	public LastFM.Core lfm;
	private HashMap<string, LastFM.ArtistInfo> _artists;//key:artist
	private HashMap<string, LastFM.AlbumInfo> _albums;//key:artist<sep>album
	private HashMap<string, LastFM.TrackInfo> _tracks;//key:artist<sep>album<sep>track
	
	public TreeViewSetup music_setup { set; get; }
	public TreeViewSetup station_setup  { set; get; }
	public TreeViewSetup similar_setup  { set; get; }
	public TreeViewSetup queue_setup  { set; get; }
	public TreeViewSetup history_setup  { set; get; }
	public TreeViewSetup album_list_setup  { set; get; }
	
	public int _played_index;//if user press back, this goes back 1 until it hits 0. as new medias play, this goes with it
	public int _current_index;
	public int _current_shuffled_index;
	public BeatBox.MediaInfo media_info { set; get; }
	
	public bool playing;
	bool _playing_queued_song;
	public Repeat repeat { set; get; }
	public Shuffle shuffle { set; get; }
	public int next_gapless_id;
	
	
	public enum Shuffle {
		OFF,
		ALL;
	}
	
	public enum Repeat {
		OFF,
		MEDIA,
		ALBUM,
		ARTIST,
		ALL;
	}
	
	private string temp_add_folder;
	private LinkedList<string> temp_add_files;
	bool _doing_file_operations;
	bool in_fetch_thread;
	public bool have_fetched_new_podcasts;
	
	public signal void music_counted(int count);
	public signal void music_added(LinkedList<string> not_imported);
	public signal void music_imported(LinkedList<Media> new_medias, LinkedList<string> not_imported);
	public signal void music_rescanned(LinkedList<Media> new_medias, LinkedList<string> not_imported);
	public signal void progress_notification(string? message, double progress);
	public signal void file_operations_started();
	public signal void file_operations_done();
	public signal void progress_cancel_clicked();
	
	public signal void current_cleared();
	public signal void media_updated(int id);
	public signal void medias_added(LinkedList<int> ids);
	public signal void medias_updated(LinkedList<int> ids);
	public signal void medias_removed(LinkedList<int> ids);
	public signal void media_queued(int id);
	public signal void media_played(int id, int old_id);
	public signal void playback_stopped(int was_playing);
	
	private Mutex mutex = new Mutex();
	
	public LibraryManager(BeatBox.Settings sett, BeatBox.LibraryWindow lww, string[] args) {
		this.lw = lww;
		this.player = new Streamer(this, lw, args);
		this.settings = sett;
		
		this.dbm = new DataBaseManager(this);
		this.dbu = new DataBaseUpdater(this, dbm);
		this.fo = new BeatBox.FileOperator(this, settings);
		this.pm = new PodcastManager(this, lw);
		
		fo.fo_progress.connect(dbProgress);
		dbm.db_progress.connect(dbProgress);
		
		_smart_playlists = new HashMap<int, SmartPlaylist>();
		_playlists = new HashMap<int, Playlist>();
		_media = new HashMap<int, Media>();
		_songs = new HashMap<int, Media>(); // subset of _songs
		_podcasts = new HashMap<int, Media>(); // subset of _medias
		_audiobooks = new HashMap<int, Media>(); // subset of _medias
		_stations = new HashMap<int, Media>(); // subset of _medias
		_permanents = new LinkedList<int>();
		_device_preferences = new HashMap<string, DevicePreferences>();
		
		_current = new HashMap<int, int>();
		_current_shuffled = new HashMap<int, int>();
		_current_view = new HashMap<int, int>();
		_queue = new LinkedList<int>();
		_already_played = new LinkedList<int>();
		cover_album_art = new HashMap<string, Gdk.Pixbuf>();
		
		lfm = new LastFM.Core(this);
		_artists = new HashMap<string, LastFM.ArtistInfo>();
		_albums = new HashMap<string, LastFM.AlbumInfo>();
		_tracks = new HashMap<string, LastFM.TrackInfo>();
		
		_played_index = 0;
		
		media_info = new BeatBox.MediaInfo();
		media_info.track = new LastFM.TrackInfo.basic();
		media_info.artist = new LastFM.ArtistInfo.basic();
		media_info.album = new LastFM.AlbumInfo.basic();
		
		int repeatValue = settings.getRepeatMode();
		if(repeatValue == 0)
			repeat = LibraryManager.Repeat.OFF;
		else if(repeatValue == 1)
			repeat = LibraryManager.Repeat.MEDIA;
		else if(repeatValue == 2)
			repeat = LibraryManager.Repeat.ALBUM;
		else if(repeatValue == 3)
			repeat = LibraryManager.Repeat.ARTIST;
		else if(repeatValue == 4)
			repeat = LibraryManager.Repeat.ALL;
		
		_doing_file_operations = false;
		have_fetched_new_podcasts = false;
		
		music_setup = new TreeViewSetup("Artist", Gtk.SortType.ASCENDING, ViewWrapper.Hint.MUSIC);
		station_setup = new TreeViewSetup("Genre", Gtk.SortType.ASCENDING, ViewWrapper.Hint.STATION);
		similar_setup = new TreeViewSetup("#", Gtk.SortType.ASCENDING, ViewWrapper.Hint.SIMILAR);
		queue_setup = new TreeViewSetup("#", Gtk.SortType.ASCENDING, ViewWrapper.Hint.QUEUE);
		history_setup = new TreeViewSetup("#", Gtk.SortType.ASCENDING, ViewWrapper.Hint.HISTORY);
		album_list_setup = new TreeViewSetup("Track", Gtk.SortType.ASCENDING, ViewWrapper.Hint.ALBUM_LIST);
		
		//load all medias from db
		foreach(Media s in dbm.load_medias()) {
			_media.set(s.rowid, s);
			_permanents.add(s.rowid);
			
			if(File.new_for_uri(s.uri).get_path().has_prefix(settings.getMusicFolder()))
				++local_song_count;
			
			if(s.mediatype == 0)
				_songs.set(s.rowid, s);
			else if(s.mediatype == 1)
				_podcasts.set(s.rowid, s);
			else if(s.mediatype == 2)
				_audiobooks.set(s.rowid, s);
			else if(s.mediatype == 3)
				_stations.set(s.rowid, s);
		}
		
		foreach(SmartPlaylist p in dbm.load_smart_playlists()) {
			_smart_playlists.set(p.rowid, p);
		}
		
		//load all playlists from db
		var playlists_added = new LinkedList<string>();
		foreach(Playlist p in dbm.load_playlists()) {
			if(!playlists_added.contains(p.name)) { // sometimes we get duplicates. don't add duplicates
				_playlists.set(p.rowid, p);
			
				if(p.name == "autosaved_music") {
					music_setup = p.tvs;
					_playlists.unset(p.rowid);
				}
				else if(p.name == "autosaved_podcast") {
				    critical("Need reimplementation");
					//podcast_setup = p.tvs;
					_playlists.unset(p.rowid);
				}
				else if(p.name == "autosaved_station") {
					station_setup = p.tvs;
					_playlists.unset(p.rowid);
				}
				else if(p.name == "autosaved_similar") {
					similar_setup = p.tvs;
					_playlists.unset(p.rowid);				
				}
				else if(p.name == "autosaved_queue") {
					foreach(int i in medias_from_playlist(p.rowid)) {
						queue_media_by_id(i);
					}
					
					queue_setup = p.tvs;
					_playlists.unset(p.rowid);
				}
				else if(p.name == "autosaved_history") {
					history_setup = p.tvs;
					_playlists.unset(p.rowid);
				}
				
				playlists_added.add(p.name);
			}
		}
		
		foreach(LastFM.ArtistInfo a in dbm.load_artists()) {
			_artists.set(a.name, a);
		}
		
		foreach(LastFM.AlbumInfo a in dbm.load_albums()) {
			_albums.set(a.name + " by " + a.artist, a);
		}
		
		foreach(LastFM.TrackInfo t in dbm.load_tracks()) {
			_tracks.set(t.name + " by " + t.artist, t);
		}
		
		// pre-load devices and their preferences
		foreach(DevicePreferences dp in dbm.load_devices()) {
			_device_preferences.set(dp.id, dp);
		}
		
		dm = new DeviceManager(this);
		
		// set the volume
		player.setVolume(settings.getVolume());
		
		// start thread to load all the medias pixbuf's
		try {
			Thread.create<void*>(fetch_thread_function, false);
		}
		catch(GLib.ThreadError err) {
			warning("Could not create thread to load media pixbuf's: %s \n", err.message);
		}
	}

	/************ Library/Collection management stuff ************/
	public virtual void dbProgress(string? message, double progress) {
		progress_notification(message, progress);
	}
	
	public bool doProgressNotificationWithTimeout() {
		if(_doing_file_operations) {
			Gdk.threads_enter();
			progress_notification(null, (double)((double)fo.index)/((double)fo.item_count));
			Gdk.threads_leave();
		}
		
		if(fo.index < fo.item_count && _doing_file_operations) {
			return true;
		}
		
		return false;
	}
	
	public void set_music_folder(string folder) {
		if(start_file_operations("Importing music from <b>" + folder + "</b>...")) {
			lw.resetSideTree(true);
			lw.sideTree.removeAllStaticPlaylists();
			clear_medias();
			_queue.clear();
			_already_played.clear();
			lw.resetSideTree(false);
			lw.updateSensitivities();
			stopPlayback();
			
			settings.setMusicMountName("");
			settings.setMusicFolder(folder);
			
			try {
				Thread.create<void*>(set_music_thread_function, false);
			}
			catch(GLib.Error err) {
				warning("Could not create thread to set music folder: %s\n", err.message);
			}
		}
	}
	
	public void* set_music_thread_function () {
		var music_folder = GLib.File.new_for_path(settings.getMusicFolder());
		LinkedList<string> files = new LinkedList<string>();
		
		var items = fo.count_music_files(music_folder, ref files);
		debug ("found %d items to import\n", items);
		
		fo.resetProgress(items);
		Timeout.add(100, doProgressNotificationWithTimeout);
		fo.import_files(files, FileOperator.ImportType.SET);
		
		return null;
	}
	
	public void add_files_to_library(LinkedList<string> files) {
		if(start_file_operations("Adding files to library...")) {
			temp_add_files = files;
			
			try {
				Thread.create<void*>(add_files_to_library_thread, false);
			}
			catch(GLib.Error err) {
				warning ("Could not create thread to add music files: %s\n", err.message);
			}
		}
	}
	
	public void* add_files_to_library_thread () {
		fo.resetProgress(temp_add_files.size - 1);
		Timeout.add(100, doProgressNotificationWithTimeout);
		fo.import_files(temp_add_files, FileOperator.ImportType.IMPORT);
		
		return null;
	}
	
	public void add_folder_to_library(string folder) {
		if(start_file_operations("Adding music from <b>" + folder + "</b> to library...")) {
			temp_add_folder = folder;
			
			try {
				Thread.create<void*>(add_folder_to_library_thread, false);
			}
			catch(GLib.Error err) {
				warning ("Could not create thread to add music folder: %s\n", err.message);
			}
		}
	}
	
	public void* add_folder_to_library_thread () {
		var file = GLib.File.new_for_path(temp_add_folder);
		var files = new LinkedList<string>();
		
		var items = fo.count_music_files(file, ref files);
		fo.resetProgress(items);
		Timeout.add(100, doProgressNotificationWithTimeout);
		fo.import_files(files, FileOperator.ImportType.IMPORT);
		
		return null;
	}
    
	public void rescan_music_folder() {
		if(start_file_operations("Rescanning music for changes. This may take a while...")) {
			try {
					Thread.create<void*>(rescan_music_thread_function, false);
			}
			catch(GLib.Error err) {
				warning ("Could not create thread to rescan music folder: %s\n", err.message);
			}
		}
	}
        
	public void* rescan_music_thread_function () {
		HashMap<string, Media> paths = new HashMap<string, Media>();
		LinkedList<Media> to_remove = new LinkedList<Media>();
		LinkedList<string> to_import = new LinkedList<string>();
		
		fo.resetProgress(100);
		Timeout.add(100, doProgressNotificationWithTimeout);
		
		string music_folder = settings.getMusicFolder();
		foreach(Media s in _media.values) {
			if(!s.isTemporary && !s.isPreview && s.uri.contains(music_folder))
				paths.set(s.uri, s);
				
			if(s.uri.contains(music_folder) && !File.new_for_uri(s.uri).query_exists())
				to_remove.add(s);
		}
		fo.index = 5;
		
		// get a list of the current files
		var files = new LinkedList<string>();
		fo.count_music_files(File.new_for_path(music_folder), ref files);
		fo.index = 10;
		
		foreach(string s in files) {
			if(paths.get("file://" + s) == null)
				to_import.add(s);
		}
		
		debug ("Importing %d new songs\n", to_import.size);
		if(to_import.size > 0) {
			fo.resetProgress(to_import.size);
			Timeout.add(100, doProgressNotificationWithTimeout);
			fo.import_files(to_import, FileOperator.ImportType.RESCAN);
		}
		else {
			fo.index = 90;
		}
		Idle.add( () => {
			if(!fo.cancelled)	remove_medias(to_remove, false);
			if(to_import.size == 0) {
				finish_file_operations();
			}
			
			return false; 
		});
		
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
		
		dbm.add_playlist(p);
		
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
	
	public SmartPlaylist? smart_playlist_from_name(string name) {
		foreach(var p in _smart_playlists.values) {
			if(p.name == name)
				return p; 
		}
		
		return null;
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
			warning ("Could not create thread to save smart playlists: %s\n", err.message);
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
	
	/******************** Media stuff ******************/
	public void clear_medias() {
		debug ("clearing...\n");
		var unset = new LinkedList<Media>();//HashMap<int, Media>();
		foreach(int i in _media.keys) {
			Media s = _media.get(i);
			if(!(s.isTemporary || s.isPreview || s.uri.has_prefix("http://"))) {
				if( (s.mediatype == 1 && s.podcast_url != null && s.podcast_url.has_prefix("http://")) || s.mediatype == 3) {
					s.uri = s.podcast_url;
				}
				else {
					unset.add(s);
				}
			}
		}
		
		foreach(Media s in unset) {
			_media.unset(s.rowid);
			_permanents.remove(s.rowid);
			
			if(File.new_for_uri(s.uri).get_path().has_prefix(settings.getMusicFolder()))
				--local_song_count;
			
			if(s.mediatype == 0)
				_songs.unset(s.rowid);
			else if(s.mediatype == 1)
				_podcasts.unset(s.rowid);
			else if(s.mediatype == 2)
				_audiobooks.unset(s.rowid);
			else if(s.mediatype == 3)
				_stations.unset(s.rowid);
				
			foreach(var p in _playlists.values) {
				p.removeMedia(s.rowid);
			}
		}
		
		dbm.clear_medias();
		dbm.add_medias(_media.values);
		//remove_medias(unset, false);
		debug ("cleared\n");
	}
	
	public int media_count() {
		return _media.size;
	}
	
	public Collection<Media> media() {
		return _media.values;
	}
	
	public Collection<int> media_ids() {
		return _media.keys;
	}
	
	public Collection<int> permanent_ids() { // this should be permanent_ids
		return _permanents;
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
	
	public Collection<int> station_ids() {
		return _stations.keys;
	}
	
	public HashMap<int, Media> media_hash() {
		return _media;
	}
	
	public void update_media(Media s, bool updateMeta, bool record_time) {
		LinkedList<Media> one = new LinkedList<Media>();
		one.add(s);
		
		update_medias(one, updateMeta, record_time);
	}
	
	public void update_medias(Collection<Media> updates, bool updateMeta, bool record_time) {
		LinkedList<int> rv = new LinkedList<int>();
		
		foreach(Media s in updates) {
			/*_media.set(s.rowid, s);*/
			rv.add(s.rowid);
			
			if(record_time)
				s.last_modified = (int)time_t();
		}
		
		debug ("%d medias updated from lm.update_medias 677\n", rv.size);
		medias_updated(rv);
		if(updates.size == 1)
			media_updated(updates.to_array()[0].rowid);
		
		/* now do background work. even if updateMeta is true, so must user preferences */
		if(updateMeta)
			fo.save_medias(updates);
		
		foreach(Media s in updates)
			dbu.update_media(s);
	}
	
	public void* update_views_thread () {
		// update them
		foreach(Widget w in lw.mainViews.get_children()) {
			if(!w.visible && w is ViewWrapper) {
				ViewWrapper vw = (ViewWrapper)w;
				vw.doUpdate(vw.currentView, vw.get_media_ids(), false, false, true);
			}
		}
		
		return null;
	}
	
	public void save_media() {
		try {
			Thread.create<void*>( () => { 
				lock(_media) {
					dbm.update_medias(_media.values);
				} 
				
				return null; 
			}, false);
		}
		catch(GLib.Error err) {
			warning ("Could not create thread to save media: %s\n", err.message);
		}
	}
	
	/** Used extensively. All other media data stores a media rowid, and then
	 * use this to retrieve the media. This is for memory saving and 
	 * consistency
	 */
	public Media media_from_id(int id) {
		return _media.get(id);
	}
	
	public int match_media_to_list(int id, Collection<int> to_match) {
		Media m = media_from_id(id);
		
		foreach(int i in to_match) {
			Media test = media_from_id(i);
			if(id != i && test.title.down() == m.title.down() && test.artist.down() == m.artist.down()) {
				return i;
			}
		}
		
		return 0;
	}
	
	public Media media_from_name(string title, string artist) {
		Media rv = new Media("");
		rv.title = title;
		rv.artist = artist;
		Media[] searchable;
		
		mutex.lock();
		searchable = _media.values.to_array();
		mutex.unlock();
		
		for(int i = 0; i < searchable.length; ++i) {
			Media s = searchable[i];
			if(s.title.down() == title.down() && s.artist.down() == artist.down())
				return s;
		}
		
		return rv;
	}
	
	public void medias_from_name(LinkedList<Media> tests, ref LinkedList<int> found, ref LinkedList<Media> not_found) {
		Media[] searchable;
		
		mutex.lock();
		searchable = _media.values.to_array();
		mutex.unlock();
		
		foreach(Media test in tests) {
			bool found_match = false;
			for(int i = 0; i < searchable.length; ++i) {
				Media s = searchable[i];
				if(test.title.down() == s.title.down() && test.artist.down() == s.artist.down()) {
					found.add(s.rowid);
					found_match = true;
					break;
				}
			}
			
			if(!found_match)
				not_found.add(test);
		}
	}
	
	public Media? media_from_file(string uri) {
		lock(_media) {
			foreach(Media s in _media.values) {
				if(s.uri == uri)
					return s;
			}
		}
		
		return null;
	}
	
	public void do_search(string search, ViewWrapper.Hint hint, string album_artist, string album,
	Collection<int> to_search, ref LinkedList<int> results, ref LinkedList<int> album_results) {
		string l_search = search.down();
		int mediatype = 0;
		bool include_temps = (hint == ViewWrapper.Hint.CDROM || hint == ViewWrapper.Hint.DEVICE_AUDIO || 
						hint == ViewWrapper.Hint.DEVICE_PODCAST || hint == ViewWrapper.Hint.DEVICE_AUDIOBOOK ||
						hint == ViewWrapper.Hint.QUEUE || hint == ViewWrapper.Hint.HISTORY || hint == ViewWrapper.Hint.ALBUM_LIST);
		
		if(hint == ViewWrapper.Hint.PODCAST || hint == ViewWrapper.Hint.DEVICE_PODCAST) {
			mediatype = 1;
		}
		else if(hint == ViewWrapper.Hint.AUDIOBOOK || hint == ViewWrapper.Hint.DEVICE_AUDIOBOOK) {
			mediatype = 2;
		}
		else if(hint == ViewWrapper.Hint.STATION) {
			mediatype = 3;
		}
		else if(hint == ViewWrapper.Hint.QUEUE || hint == ViewWrapper.Hint.HISTORY ||
		hint == ViewWrapper.Hint.PLAYLIST || hint == ViewWrapper.Hint.SMART_PLAYLIST ||
		hint == ViewWrapper.Hint.ALBUM_LIST) {
			mediatype = -1; // some lists should be able to have ALL media types
		}
		
		foreach(int i in to_search) {
			Media s = media_from_id(i);
			if(s != null && (s.mediatype == mediatype || mediatype == -1) && (!s.isTemporary || include_temps) &&
			(l_search in s.title.down() || l_search in s.album_artist.down() || 
			l_search in s.artist.down() || l_search in s.album.down() || l_search in s.genre.down())) {
				if(album_artist == "All Artists" || s.album_artist == album_artist) {
					if(album == "All Albums" || s.album == album) {
						results.add(i);
					}
					
					album_results.add(i);
				}
			}
		}
	}
	
	public LinkedList<int> medias_from_playlist(int id) {
		return _playlists.get(id).analyze(this);
	}
	
	public LinkedList<int> medias_from_smart_playlist(int id) {
		return _smart_playlists.get(id).analyze(this, media_ids());
	}
	
	public void add_media(Media s, bool permanent) {
		var coll = new LinkedList<Media>();
		coll.add(s);
		add_medias(coll, permanent);
	}
	
	public void add_medias(Collection<Media> new_media, bool permanent) {
		if(new_media.size == 0) // happens more often than you would think
			return;
		
		int top_index = 0;
		
		lock(_media) {
			foreach(int i in _media.keys) {
				if(i > top_index)
					top_index = i;
			}
		}
		
		var added = new LinkedList<int>();
		foreach(var s in new_media) {
			if(s.rowid == 0)
				s.rowid = ++top_index;
			
			added.add(s.rowid);
			_media.set(s.rowid, s);
			
			if(permanent && !s.isTemporary)
				_permanents.add(s.rowid);
				
			if(settings.getMusicFolder() != "" && s.uri.has_prefix(File.new_for_path(settings.getMusicFolder()).get_uri()))
				++local_song_count;
			
			if(s.mediatype == 0)
				_songs.set(s.rowid, s);
			else if(s.mediatype == 1)
				_podcasts.set(s.rowid, s);
			else if(s.mediatype == 2)
				_audiobooks.set(s.rowid, s);
			else if(s.mediatype == 3)
				_stations.set(s.rowid, s);
		}
		
		if(new_media.size > 0 && new_media.to_array()[0].rowid != -2 && permanent) {
			dbm.add_medias(new_media);
		}
		
		Idle.add( () => {
			medias_added(added);
			
			return false;
		});
	}
	
	public void convert_temp_to_permanent(int i) {
		var temps = new LinkedList<int>();
		temps.add(i);
		convert_temps_to_permanents(temps);
	}
	
	public void convert_temps_to_permanents(LinkedList<int> temps) {
		LinkedList<Media> temps_medias = new LinkedList<Media>();
		foreach(int i in temps) {
			if(media_from_id(i).isTemporary)
				temps_medias.add(media_from_id(i));
		}
		
		foreach(var s in temps_medias) {
			s.isTemporary = false;
			s.date_added = (int)time_t();
			_permanents.add(s.rowid);
			
			if(File.new_for_uri(s.uri).get_path().has_prefix(settings.getMusicFolder()))
				++local_song_count;
		}
		
		dbm.add_medias(temps_medias);
		warning("TODO: call media_added signal afterconvert_temps_to_permanents\n");
	}
	
	public void remove_medias(LinkedList<Media> toRemove, bool trash) {
		LinkedList<int> removedIds = new LinkedList<int>();
		LinkedList<string> removeURIs = new LinkedList<string>();
		
		foreach(Media s in toRemove) {
			removedIds.add(s.rowid);
			removeURIs.add(s.uri);
		}
		
		dbu.removeItem(removeURIs);
		
		if(trash) {
			fo.remove_medias(removeURIs);
		}
		
		foreach(Media s in toRemove) {
			_media.unset(s.rowid);
			_permanents.remove(s.rowid);
			
			if(settings.getMusicFolder() != "" && File.new_for_uri(s.uri).get_path().has_prefix(settings.getMusicFolder()))
				--local_song_count;
			
			if(s.mediatype == 0)
				_songs.unset(s.rowid);
			else if(s.mediatype == 1)
				_podcasts.unset(s.rowid);
			else if(s.mediatype == 2)
				_audiobooks.unset(s.rowid);
			else if(s.mediatype == 3)
				_stations.unset(s.rowid);
				
			foreach(var p in _playlists.values) {
				p.removeMedia(s.rowid);
			}
		}
		
		medias_removed(removedIds);
		
		if(_media.size == 0)
			settings.setMusicFolder(Environment.get_user_special_dir(UserDirectory.MUSIC));
		
		lw.updateSensitivities();
	}
	
	public int get_local_song_count() {
		return local_song_count;
	}
	
	/**************** Queue Stuff **************************/
	public bool queue_empty() {
		return (_queue.size == 0);
	}
	
	public void clear_queue() {
		_queue.clear();
	}
	
	public void queue_media_by_id(int id) {
		_queue.offer_tail(id);
	}
	
	public void unqueue_media_by_id(int id) {
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
		if(!_already_played.contains(i))
			_already_played.offer_tail(i);
	}
	
	public LinkedList<int> already_played() {
		return _already_played;
	}
	
	/************ Current medialist stuff ***************/
	public bool playing_queued_song() {
		return _playing_queued_song;
	}
	
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
				_current_shuffled_index = value;
			}
		}
	}
	
	public int mediaFromCurrentIndex(int index_in_current) {
		if(shuffle == Shuffle.OFF)
			return _current.get(index_in_current);
		else
			return _current_shuffled.get(index_in_current);
	}
	
	public Collection<int> current_medias() {
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
			if(media_info.media != null) {
				//make sure we continue playing where we left off
				for(int i = 0; i < _current.size; ++i) {
					if(_current.get(i) == media_info.media.rowid) {
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
			//create temp list of all of current's media id's
			LinkedList<int> temp = new LinkedList<int>();
			foreach(int i in _current.values) {
				temp.add(i);
			}
			
			//loop through all current media id's and pick a random one remaining
			//and set that int i as one of those this is confusing just a sort
			//_current_shuffled.set(0, media_info.media.rowid);
			for(int i = 1;i < _current.size; ++i) {
				int random = GLib.Random.int_range(0, temp.size);
				
				//if(temp.get(random) != media_info.media.rowid) {
				if(media_info.media != null && temp.get(random) == media_info.media.rowid) {
					_current_shuffled.set(0, media_info.media.rowid);
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
		
		// next check if user has queued medias
		if(!queue_empty()) {
			rv = poll_queue();
			_playing_queued_song = true;
		}
		else if(_current_shuffled.size != 0) {
			_playing_queued_song = false;
			
			if(media_info.media == null) {
				_current_shuffled_index = 0;
				rv = _current_shuffled.get(0);
			}
			else if(repeat == Repeat.MEDIA) {
				rv = _current_shuffled.get(_current_shuffled_index);
			}
			else if(_current_shuffled_index == (_current_shuffled.size - 1)) {// consider repeat options
				if(repeat == Repeat.ALL)
					_current_shuffled_index = 0;
				else {
					/* reset to no media playing */
					media_info.media = null;
					_current_shuffled.clear();
					_current.clear();
					_current_shuffled_index = 0;
					_current_index = 0;
					
					if(play)
						stopPlayback();
					
					return 0;
				}
				
				rv = _current_shuffled.get(0);
			}
			else if(_current_shuffled_index >= 0 && _current_shuffled_index < (_current_shuffled.size - 1)){
				// make sure we are repeating what we need to be
				if(repeat == Repeat.ARTIST && media_from_id(_current_shuffled.get(_current_shuffled_index + 1)).artist != media_from_id(_current_shuffled.get(_current_shuffled_index)).artist) {
					while(media_from_id(_current_shuffled.get(_current_shuffled_index - 1)).artist == media_info.media.artist)
						--_current_shuffled_index;
				}
				else if(repeat == Repeat.ALBUM && media_from_id(_current_shuffled.get(_current_shuffled_index + 1)).album != media_from_id(_current_shuffled.get(_current_shuffled_index)).album) {
					while(media_from_id(_current_shuffled.get(_current_shuffled_index - 1)).album == media_info.media.album)
						--_current_shuffled_index;
				}
				else {
					++_current_shuffled_index;
				}
				
				rv = _current_shuffled.get(_current_shuffled_index);
			}
			else {
				foreach(Media s in _media.values)
					addToCurrent(s.rowid);
				
				_current_shuffled_index = 0;
				setShuffleMode(Shuffle.ALL, true);
				rv = _current_shuffled.get(0);
			}
		}
		else {
			_playing_queued_song = false;
			
			if(media_info.media == null) {
				_current_index = 0;
				rv = _current.get(0);
			}
			else if(repeat == Repeat.MEDIA) {
				rv = _current.get(_current_index);
			}
			else if(_current_index == (_current.size - 1)) {// consider repeat options
				if(repeat == Repeat.ALL)
					_current_index = 0;
				else {
					if(play)
						stopPlayback();
					return 0;
				}
				
				rv = _current.get(0);
			}
			else if(_current_index >= 0 && _current_index < (_current.size - 1)){
				// make sure we are repeating what we need to be
				if(repeat == Repeat.ARTIST && media_from_id(_current.get(_current_index + 1)).artist != media_from_id(_current.get(_current_index)).artist) {
					while(media_from_id(_current.get(_current_index - 1)).artist == media_info.media.artist)
						--_current_index;
				}
				else if(repeat == Repeat.ALBUM && media_from_id(_current.get(_current_index + 1)).album != media_from_id(_current.get(_current_index)).album) {
					while(media_from_id(_current.get(_current_index - 1)).album == media_info.media.album)
						--_current_index;
				}
				else
					++_current_index;
				
				rv = _current.get(_current_index);
			}
			else {
				foreach(Media s in _media.values)
					addToCurrent(s.rowid);
				
				_current_index = 0;
				rv = _current.get(0);
			}
		}
		
		if(play)
			playMedia(rv, false);
		
		return rv;
	}
	
	public int getPrevious(bool play) {
		int rv;
		
		if(_current_shuffled.size != 0) {
			_playing_queued_song = false;
			
			if(media_info.media == null) {
				_current_shuffled_index = _current_shuffled.size - 1;
				rv = _current_shuffled.get(_current_shuffled_index);
			}
			else if(repeat == Repeat.MEDIA) {
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
				if(repeat == Repeat.ARTIST && media_from_id(_current_shuffled.get(_current_shuffled_index - 1)).artist != media_from_id(_current_shuffled.get(_current_shuffled_index)).artist) {
					while(media_from_id(_current_shuffled.get(_current_shuffled_index + 1)).artist == media_info.media.artist)
						++_current_shuffled_index;
				}
				else if(repeat == Repeat.ALBUM && media_from_id(_current_shuffled.get(_current_shuffled_index - 1)).album != media_from_id(_current_shuffled.get(_current_shuffled_index)).album) {
					while(media_from_id(_current_shuffled.get(_current_shuffled_index + 1)).album == media_info.media.album)
						++_current_shuffled_index;
				}
				else
					--_current_shuffled_index;
				
				rv = _current_shuffled.get(_current_shuffled_index);
			}
			else {
				foreach(Media s in _media.values)
					addToCurrent(s.rowid);
				
				_current_shuffled_index = _current_shuffled.size - 1;
				rv = _current_shuffled.get(_current_shuffled_index);
			}
		}
		else {
			_playing_queued_song = false;
			
			if(media_info.media == null) {
				_current_index = _current.size - 1;
				rv = _current.get(_current_index);
			}
			else if(repeat == Repeat.MEDIA) {
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
				if(repeat == Repeat.ARTIST && media_from_id(_current.get(_current_index - 1)).artist != media_from_id(_current.get(_current_index)).artist) {
					while(media_from_id(_current.get(_current_index + 1)).artist == media_info.media.artist)
						++_current_index;
				}
				else if(repeat == Repeat.ALBUM && media_from_id(_current.get(_current_index - 1)).album != media_from_id(_current.get(_current_index)).album) {
					while(media_from_id(_current.get(_current_index + 1)).album == media_info.media.album)
						++_current_index;
				}
				else
					--_current_index;
				
				rv = _current.get(_current_index);
			}
			else {
				foreach(Media s in _media.values)
					addToCurrent(s.rowid);
				
				_current_index = _current.size - 1;
				rv = _current.get(_current_index);
			}
		}
		
		if(play)
			playMedia(rv, false);
		
		return rv;
	}
	
	public void playMedia(int id, bool use_resume_pos) {
		int old_id = -1;
		
		if(id == 0 || media_from_id(id) == null)
			return;
		
		// save previous media's id
		if(media_info.media != null)
			old_id = media_info.media.rowid;
		
		// set the current media
		media_info.media = media_from_id(id);
		Media m = media_from_id(id);
		
		// check that the file exists
		if((settings.getMusicFolder() != "" && File.new_for_uri(m.uri).get_path().has_prefix(settings.getMusicFolder()) && !GLib.File.new_for_uri(m.uri).query_exists())) {
			m.unique_status_image = Icons.PROCESS_ERROR_ICON.render(IconSize.MENU, ((ViewWrapper)lw.sideTree.getWidget(lw.sideTree.library_music_iter)).list.get_style_context());
			m.location_unknown = true;
			lw.media_not_found(id);
			stopPlayback();
			return;
		}
		else {
			if(m.location_unknown && m.unique_status_image != null) {
				m.unique_status_image = null;
				m.location_unknown = false;
			}
		}
		
		player.checked_video = false;
		
		if(m.mediatype == 1 || m.mediatype == 2 || use_resume_pos)
			player.set_resume_pos = false;
		
		// actually play the media asap
		if(next_gapless_id == 0) {
			player.setURI(m.uri);
		}
		else {
			next_gapless_id = 0;
		}
		
		//pause if paused
		if(!playing)
			player.pause();
		
		//update settings
		if(id != -2)
			settings.setLastMediaPlaying(id);
		
		media_played(id, old_id);
		
		try {
			Thread.create<void*>(change_gains_thread, false);
		}
		catch(GLib.Error err) {
			warning("Could not create thread to change gains: %s\n", err.message);
		}
		
		/* if same media 1 second later...
		 * check for embedded art if need be (not loaded from on file) and use that
		 * check that the s.getAlbumArtPath() exists, if not set to "" and call updateCurrentMedia
		 * save old media's resume_pos
		 */
		Timeout.add(1000, () => {
			if(media_info.media.rowid == id) {
				if(!File.new_for_path(media_info.media.getAlbumArtPath()).query_exists()) {
					media_info.media.setAlbumArtPath("");
				}
				
				// potentially fix media length
				if((player.getDuration()/1000000000) > 1) {
					media_info.media.length = (int)(player.getDuration()/1000000000);
					update_media(media_info.media, true, false);
				}
			}
			
			return false;
			
		});
	}
	
	public void* change_gains_thread () {
		if(settings.getEqualizerEnabled()) {
			bool automatic_enabled = settings.getAutoSwitchPreset();
			string selected_preset = settings.getSelectedPreset();

			foreach(var p in settings.getDefaultPresets ()) {
				if(p != null && media_info.media != null)  {
					var preset_name = p.name.down ();
					var media_genre = media_info.media.genre.down();

					bool match_genre = (preset_name in media_genre) || (media_genre in preset_name);

					if ( (automatic_enabled && match_genre) ||
					     (!automatic_enabled && p.name == selected_preset))
					{
						for(int i = 0; i < 10; ++i)
							player.setEqualizerGain(i, p.getGain(i));
					
						return null;
					}
				}
			}

			foreach(var p in settings.getCustomPresets ()) {
				if(p != null && media_info.media != null)  {
					var preset_name = p.name.down ();
					var media_genre = media_info.media.genre.down();

					bool match_genre = (preset_name in media_genre) || (media_genre in preset_name);

					if ( (automatic_enabled && match_genre) ||
					     (!automatic_enabled && p.name == selected_preset))
					{
						for(int i = 0; i < 10; ++i)
							player.setEqualizerGain(i, p.getGain(i));
					
						return null;
					}
				}
			}
		}

		for (int i = 0; i < 10; ++i)
			player.setEqualizerGain(i, 0);		
		
		return null;
	}
	
	public void playTrackPreview(Store.Track track, string uri) {
		Media s = new Media(uri);
		s.isPreview = true;
		s.rowid = -2;
		s.title = track.title;
		s.artist = track.artist.name;
		s.album = track.release.title;
		s.length = 30;
		
		LinkedList<Media> temps = new LinkedList<Media>();
		temps.add(s);
		add_medias(temps, false);
		
		playMedia(-2, false);
		
		if(!playing) {
			lw.playClicked();
		}
	}
	
	public void stopPlayback() {
		player.pause();
		
		int was_playing = 0;
		if(media_info.media != null)
			was_playing = media_info.media.rowid;
		
		settings.setLastMediaPlaying(0);
		media_info.update(null, null, null, null);
		
		playback_stopped(was_playing);
	}
	
	/************* Last FM Artist Stuff ************/
	public Collection<LastFM.ArtistInfo> artists() {
		return _artists.values;
	}
	
	public void save_artist(LastFM.ArtistInfo artist) {
		_artists.set(artist.name, artist);
		
		save_artists();
	}
	
	public void save_artists() {
		/*try {
			Thread.create<void*>( () => { 
				lock(_artists) {
					dbm.save_artists(_artists.values);
				}
				
				return null; 
			}, false);
		}
		catch(GLib.Error err) {
			warning("Could not create thread to save last fm artists: %s\n", err.message);
		}*/
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
	public Collection<LastFM.AlbumInfo> albums() {
		return _albums.values;
	}
	
	public void save_album(LastFM.AlbumInfo album) {
		_albums.set(album.name + " by " + album.artist, album);
		
		save_albums();
	}
	
	public void save_albums() {
		/*try {
			Thread.create<void*>( () => { 
				lock(_albums) {
					dbm.save_albums(_albums.values);
				}
				
				return null; 
			}, false);
		}
		catch(GLib.Error err) {
			warning("Could not create thread to save last fm albums: %s\n", err.message);
		}*/
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
	public Collection<LastFM.TrackInfo> tracks() {
		return _tracks.values;
	}
	
	public void save_track(LastFM.TrackInfo track) {
		_tracks.set(track.name + " by " + track.artist, track);
		
		save_tracks();
	}
	
	public void save_tracks() {
		/*try {
			Thread.create<void*>( () => { 
				lock(_tracks) {
					dbm.save_tracks(_tracks.values);
				}
				
				return null; 
			}, false);
		}
		catch(GLib.Error err) {
			warning("Could not create thread to save last fm albums: %s\n", err.message);
		}*/
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
		return _media.get(id).getAlbumArtPath();
	}
	
	public void save_album_locally(int id, string album) {
		fo.save_album(_media.get(id), album);
	}
	
	public string getArtistImagePath(int id) {
		return _media.get(id).getArtistImagePath();
	}
	
	public Gdk.Pixbuf? save_artist_image_locally(int id, string image) {
		return fo.save_artist_image(_media.get(id), image);
	}
	
	/* at the start, load all the pixbufs */
	public void* fetch_thread_function () {
		if(in_fetch_thread)
			return null;
		
		in_fetch_thread = true;
		//GStreamerTagger tagger = new GStreamerTagger(this);
		
		// first get from file
		foreach(var s in _media.values) {
			string key = get_media_coverart_key (s), path = "";

			if(!cover_album_art.has_key (key) && s.mediatype == 0) {
				
				if(key != null) {
					Gdk.Pixbuf? coverart_pixbuf = fo.get_cached_album_art (key, out path);
					Gdk.Pixbuf? pix = null;

					// try to get image from cache (faster)					
					if (coverart_pixbuf != null) {
						pix = Icons.get_pixbuf_shadow (coverart_pixbuf);
					}
					else {
						/* TODO: Get image from the tagger object (i.e. song metadata) */
						//coverart_pixbuf = tagger.get_embedded_art(s);

						if ((path = fo.get_best_album_art_file(s)) != null && path != "") {
							try {
								coverart_pixbuf = new Gdk.Pixbuf.from_file (path);
								pix = Icons.get_pixbuf_shadow (coverart_pixbuf);
								
								// Add image to cache
								fo.save_album_art_in_cache (key, coverart_pixbuf);
							}
							catch(GLib.Error err) {
								warning (err.message);
							}
						}
					}

					if(pix != null)
						cover_album_art.set(key, pix);
				}
			}
			
			if (cover_album_art.has_key (key))
				s.setAlbumArtPath (fo.get_cached_album_art_path (key));
		}
		
		// now queue failures to fetch from embedded art
		/*previousAlbum = "";
		var to_check_art = new LinkedList<int>();
		foreach(Media s in toShowS) {
			if(_album_art.get(s.artist+s.album) == null)
				to_check_art.add(s.rowid);
		}
		tagger.fetch_art(to_check_art);*/
		
		//_album_art.set_all(to_set);
		
		in_fetch_thread = false;
		return null;
	}
	
	public static int mediaCompareFunc(Media a, Media b) {
		if(a.album_artist != b.album_artist)
			return (a.album > b.album) ? 1 : -1;
		else
			return (a.album_artist > b.album_artist) ? 1 : -1;
	}
	
	public void cancel_operations() {
		progress_cancel_clicked();
	}
	
	public Gdk.Pixbuf? get_album_art_from_file(int id) {
		Media s = _media.get(id);
		
		if(s == null)
			return null;
			
		string path = "";
		if(s.getAlbumArtPath().contains("/usr/share") &&
		(path = fo.get_best_album_art_file(s)) != null && path != "") {
			s.setAlbumArtPath(path);
		}
		
		Gdk.Pixbuf? pix = null;
		try {
			pix = new Gdk.Pixbuf.from_file(path);
		}
		catch(GLib.Error err) {}
		
		return pix;
	}
	
	public Gdk.Pixbuf? get_cover_album_art(int id) {
		Media s = _media.get(id);
		
		if(s == null)
			return null;
		
		return cover_album_art.get(get_media_coverart_key (s));
	}
	
	// Returns a key to get a coverart from the cover_album_art hashmap
	private string get_media_coverart_key (Media s) {
		return s.album_artist + " - " + s.album;
	}
	
	public Gdk.Pixbuf? get_cover_album_art_from_key(string album_artist, string album) {
		return cover_album_art.get(album_artist + " - " + album);
	}
	
	public void set_album_art(int id, Gdk.Pixbuf pix) {
		if(pix == null)
			return;
		
		Media s = media_from_id(id);
		string key = get_media_coverart_key (s);
		
		if(key != null)
			cover_album_art.set(key, Icons.get_pixbuf_shadow(pix));
	}
	
	/* Device Preferences */
	public Collection<DevicePreferences> device_preferences() {
		return _device_preferences.values;
	}
	
	public DevicePreferences? get_device_preferences(string id) {
		return _device_preferences.get(id);
	}
	
	public void add_device_preferences(DevicePreferences dp) {
		_device_preferences.set(dp.id, dp);
		save_device_preferences();
	}
	
	public void save_device_preferences() {
		/*try {
			Thread.create<void*>( () => { 
				lock(_device_preferences) {
					dbm.save_devices(_device_preferences.values);
				}
				
				return null; 
			}, false);
		}
		catch(GLib.Error err) {
			warning("Could not create thread to save device preferences: %s\n", err.message);
		}*/
	}
	
	public bool start_file_operations(string? message) {
		if(_doing_file_operations)
			return false;
		
		progress_notification(message, 0.0);
		_doing_file_operations = true;
		lw.updateSensitivities();
		file_operations_started();
		return true;
	}
	
	public bool doing_file_operations() {
		return _doing_file_operations;
	}
	
	public void finish_file_operations() {
		_doing_file_operations = false;
		debug("file operations finished or cancelled\n");
		
		if(!have_fetched_new_podcasts) {
			pm.find_new_podcasts();
		}
		else {
			try {
				Thread.create<void*>(fetch_thread_function, false);
			}
			catch(GLib.ThreadError err) {
				warning("Could not create thread to load media pixbuf's: %s \n", err.message);
			}
			
			lw.updateSensitivities();
			lw.updateInfoLabel();
			file_operations_done();
		}
	}
}

