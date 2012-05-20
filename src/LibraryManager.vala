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

/** This is where all the media stuff happens. Here, media is retrieved
 * from the db, added to the queue, sorted, and more. LibraryWindow is
 * the visual representation of this class
 */
public class BeatBox.LibraryManager : GLib.Object {
	// FIXME: Define proper enum types in Media.vala
	public static const int PREVIEW_MEDIA_ID = -2;

	/**
	 * SIGNALS
	 */

	public signal void music_counted(int count);
	public signal void music_added(LinkedList<string> not_imported);
	public signal void music_imported(LinkedList<Media> new_media, LinkedList<string> not_imported);
	public signal void music_rescanned(LinkedList<Media> new_media, LinkedList<string> not_imported);
	public signal void progress_notification(string? message, double progress);
	public signal void file_operations_started();
	public signal void file_operations_done();
	public signal void progress_cancel_clicked();
	
	public signal void current_cleared();
	public signal void media_added(LinkedList<int> ids);
	public signal void media_updated(LinkedList<int> ids);
	public signal void media_removed(LinkedList<int> ids);

	public signal void history_changed ();

	public signal void queue_cleared  ();
	public signal void media_queued   (Gee.Collection<Media> queued);
	public signal void media_unqueued (Gee.Collection<Media> unqueued);

	public signal void media_played (Media played_media);
	public signal void playback_stopped(int was_playing);


	/**
	 * DATA
	 */

	public BeatBox.LibraryWindow lw;
	public BeatBox.Settings settings;
	public BeatBox.DataBaseManager dbm;
	public BeatBox.DataBaseUpdater dbu;
	public BeatBox.FileOperator fo;
	public BeatBox.Streamer player;
	public BeatBox.DeviceManager device_manager;


	private HashMap<int, Playlist> _playlists; // rowid, playlist of all playlists
	private HashMap<int, SmartPlaylist> _smart_playlists; // rowid, smart playlist

	private HashMap<int, Media> _media; // rowid, media of all media
	private HashMap<int, Media> _songs;
	
	// id, media of current media.
	private HashMap<int, Media> _current = new Gee.HashMap<int, Media>();

	//list of id's yet to be played while on shuffle
	private HashMap<int, Media> _current_shuffled = new Gee.HashMap<int, Media>();

	// rowid, Media of queue
	private LinkedList<Media> _queue = new Gee.LinkedList<Media>();

	// Media of already played
	private LinkedList<Media> _already_played = new Gee.LinkedList<Media>();

	// All album art
	private HashMap<string, Gdk.Pixbuf> cover_album_art = new HashMap<string, Gdk.Pixbuf> ();

	public LastFM.Core lfm;

	private Mutex _media_lock; // lock for _media. use this around _media, _songs, ...

	private Mutex _playlists_lock; // lock for _playlists
	private Mutex _smart_playlists_lock; // lock for _smart_playlists
	

	public int _played_index;//if user press back, this goes back 1 until it hits 0. as new media play, this goes with it
	public int _current_index;
	public int _current_shuffled_index;
	public BeatBox.MediaInfo media_info { private set; get; }
	
	// Whether or not a media is being played. Returns true even if the media is paused
	public bool media_active { get { return media_info.media != null; } }
	
	public bool playing;
	bool _playing_queued_song;
	public Repeat repeat;
	public Shuffle shuffle;
	public int next_gapless_id;


	public TreeViewSetup music_setup   { get; private set; default = null; }
	public TreeViewSetup similar_setup { get; private set; default = null; }
	public TreeViewSetup queue_setup   { get; private set; default = null; }
	public TreeViewSetup history_setup { get; private set; default = null; }

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
	private string[] temp_add_other_folders;
	private int other_folders_added;
	private LinkedList<string> temp_add_files;

	// FIXME use mutex
	bool _doing_file_operations;
	bool in_fetch_thread;

	public LibraryManager(BeatBox.LibraryWindow lww) {
		this.lw = lww;
		this.player = new Streamer(this, lw);
		this.settings = lw.settings;
		
		this.dbm = new DataBaseManager(this);
		this.dbu = new DataBaseUpdater(this, dbm);
		this.fo = new BeatBox.FileOperator(this, settings);
#if HAVE_PODCASTS
		this.pm = new PodcastManager(this, lw);
#endif

		
		fo.fo_progress.connect(dbProgress);
		dbm.db_progress.connect(dbProgress);
		
		_smart_playlists = new HashMap<int, SmartPlaylist>();
		_playlists = new HashMap<int, Playlist>();
		_media = new HashMap<int, Media>();
		_songs = new HashMap<int, Media>(); // subset of _songs
		
		lfm = new LastFM.Core(this);
		
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

		//load all media from db
		_media_lock.lock ();
		foreach(Media s in dbm.load_media ()) {
			_media.set(s.rowid, s);
			
			if(s.mediatype == Media.MediaType.SONG)
				_songs.set(s.rowid, s);
		}
		_media_lock.unlock();
		
		_smart_playlists_lock.lock();
		foreach(SmartPlaylist p in dbm.load_smart_playlists()) {
			_smart_playlists.set(p.rowid, p);
		}
		_smart_playlists_lock.unlock();
		
		//load all playlists from db
		_playlists_lock.lock();
		var playlists_added = new HashMap<string, int> ();
		foreach (Playlist p in dbm.load_playlists()) {
			if(!playlists_added.has_key (p.name)) { // sometimes we get duplicates. don't add duplicates
				_playlists.set(p.rowid, p);
			    // TODO: these names should be constants defined in
			    // Database Manager
				if(p.name == "autosaved_music") {
					music_setup = p.tvs;
					music_setup.set_hint (ViewWrapper.Hint.MUSIC);
					_playlists.unset (p.rowid);
				}
#if HAVE_PODCASTS
				else if(p.name == "autosaved_podcast") {
					podcast_setup = p.tvs;
					podcast_setup.set_hint(ViewWrapper.Hint.PODCAST);
					_playlists.unset(p.rowid);
				}
#endif
#if HAVE_INTERNET_RADIO
				else if(p.name == "autosaved_station") {
					station_setup = p.tvs;
					station_setup.set_hint(ViewWrapper.Hint.STATION);
					_playlists.unset(p.rowid);
				}
#endif
				else if(p.name == "autosaved_similar") {
					similar_setup = p.tvs;
					similar_setup.set_hint(ViewWrapper.Hint.SIMILAR);
					_playlists.unset(p.rowid);				
				}
				else if(p.name == "autosaved_queue") {
					var to_queue = new LinkedList<Media>();
					
					foreach (var m in media_from_playlist (p.rowid)) {
						to_queue.add (m);
					}
					
					queue_media (to_queue);
					
					queue_setup = p.tvs;
					queue_setup.set_hint(ViewWrapper.Hint.QUEUE);
					_playlists.unset(p.rowid);
				}
				else if(p.name == "autosaved_history") {
					history_setup = p.tvs;
					history_setup.set_hint (ViewWrapper.Hint.HISTORY);
					_playlists.unset (p.rowid);
				}
			
				playlists_added.set (p.name, 1);
			}
		}
		_playlists_lock.unlock();

        if (music_setup == null)
            music_setup = new TreeViewSetup (MusicListView.MusicColumn.ARTIST,
                                             Gtk.SortType.ASCENDING,
                                             ViewWrapper.Hint.MUSIC);
        if (similar_setup == null)
            similar_setup = new TreeViewSetup (MusicListView.MusicColumn.NUMBER,
                                               Gtk.SortType.ASCENDING,
                                               ViewWrapper.Hint.SIMILAR);

        if (queue_setup == null)
            queue_setup = new TreeViewSetup (MusicListView.MusicColumn.NUMBER,
                                             Gtk.SortType.ASCENDING,
                                             ViewWrapper.Hint.QUEUE);

        if (history_setup == null)
            history_setup = new TreeViewSetup (MusicListView.MusicColumn.NUMBER,
                                               Gtk.SortType.ASCENDING,
                                               ViewWrapper.Hint.HISTORY);

		// Create device manager
		device_manager = new DeviceManager(this);

		other_folders_added = 0;
		file_operations_done.connect ( ()=> {
			if (temp_add_other_folders != null) {
				other_folders_added++;
				add_folder_to_library (temp_add_other_folders[other_folders_added-1]);
				if (other_folders_added == temp_add_other_folders.length) {
					other_folders_added = 0;
					temp_add_other_folders = null;
				}
			}
		});
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
		if (start_file_operations (_("Importing music from %s...").printf ("<b>" + String.escape (folder) + "</b>"))) {

			lw.resetSideTree(true);
			lw.sideTree.removeAllStaticPlaylists();

			clear_media ();
			
			// FIXME: DOESN'T MAKE SENSE ANYMORE SINCE WE'RE NOT LIMITED TO
			// PLAYING LIBRARY MUSIC. Use unqueue_media ();
			clear_queue ();

			_already_played.clear();
			lw.resetSideTree(false);
			lw.update_sensitivities();
			stopPlayback();

			settings.setMusicFolder (folder);

			settings.setMusicMountName("");

			set_music_folder_async ();
		}
	}
	
	private async void set_music_folder_async () {
		try {
			new Thread<void*>.try (null, () => {
				var music_folder_file = GLib.File.new_for_path(settings.getMusicFolder ());
				LinkedList<string> files = new LinkedList<string>();
		
				var items = fo.count_music_files(music_folder_file, ref files);
				debug ("found %d items to import\n", items);
		
				fo.resetProgress(items);
				Timeout.add(100, doProgressNotificationWithTimeout);
				fo.import_files(files, FileOperator.ImportType.SET);

				return null;
			});
		} catch (Error err) {
			warning (err.message);
		}

	}
	
	public void add_files_to_library (LinkedList<string> files) {
		if (start_file_operations (_("Adding files to library..."))) {
			temp_add_files = files;
			add_files_to_library_async ();			
		}
	}

	private async void add_files_to_library_async () {

		try {
			new Thread<void*>.try (null, () => {
				fo.resetProgress(temp_add_files.size - 1);
				Timeout.add(100, doProgressNotificationWithTimeout);
				fo.import_files(temp_add_files, FileOperator.ImportType.IMPORT);

				return null;
			});
		} catch (Error err) {
			warning (err.message);
		}
	}

	public void add_folder_to_library (string folder, string[]? other_folders = null) {
	    if (other_folders != null)
	        temp_add_other_folders = other_folders;
	        
		if(start_file_operations (_("Adding music from %s to library...").printf ("<b>" + String.escape (folder) + "</b>"))) {
			temp_add_folder = folder;
			add_folder_to_library_async ();
		}
	}
	
	private async void add_folder_to_library_async () {
		try {
			new Thread<void*>.try (null, () => {
				var file = GLib.File.new_for_path(temp_add_folder);
				var files = new LinkedList<string>();

				var items = fo.count_music_files(file, ref files);

				fo.resetProgress(items);
				Timeout.add(100, doProgressNotificationWithTimeout);
				fo.import_files(files, FileOperator.ImportType.IMPORT);

				return null;
			});
		} catch (Error err) {
			warning (err.message);
		}
	}
    
	public void rescan_music_folder() {
		if(start_file_operations (_("Rescanning music for changes. This may take a while..."))) {
			rescan_music_folder_async ();
		}
	}
        
	private async void rescan_music_folder_async () {
		try {
			new Thread<void*>.try (null, () => {
				HashMap<string, Media> paths = new HashMap<string, Media>();
				LinkedList<Media> to_remove = new LinkedList<Media>();
				LinkedList<string> to_import = new LinkedList<string>();
	
				fo.resetProgress(100);
				Timeout.add(100, doProgressNotificationWithTimeout);
	
				var music_folder_dir = settings.getMusicFolder ();
				foreach(Media s in _media.values) {
					if(!s.isTemporary && !s.isPreview && s.uri.contains(music_folder_dir))
						paths.set(s.uri, s);
						
					if(s.uri.contains(music_folder_dir) && !File.new_for_uri(s.uri).query_exists())
							to_remove.add(s);
				}
				fo.index = 5;
				
				// get a list of the current files
				var files = new LinkedList<string>();
				fo.count_music_files(File.new_for_path(music_folder_dir), ref files);
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
					if (!fo.cancelled)
						remove_media(to_remove, false);
					if (to_import.size == 0) {
						finish_file_operations();
					}
		
					// after we're done with that, rescan album arts
					fetch_all_cover_art_async ();

					return false; 
				});

				return null;
			});
		} catch (Error err) {
			warning (err.message);
		}
	}









	public void recheck_files_not_found() {
		try {
			new Thread<void*>.try (null, recheck_files_not_found_thread);
		}
		catch(GLib.Error err) {
			warning ("Could not create thread to check file locations: %s\n", err.message);
		}
	}
	
	public void* recheck_files_not_found_thread () {
		message ("IMPLEMENT FILE NOT FOUND CHECK !!");

#if 0
		Media[] cache_media;
		var not_found = new LinkedList<Media>();
		var found = new LinkedList<Media>(); // files that location were unknown but now are found
		var not_found_pix = Icons.PROCESS_ERROR.render(IconSize.MENU, ((ViewWrapper)lw.sideTree.getWidget(lw.sideTree.library_music_iter)).list_view.get_style_context());
		
		_media_lock.lock();
		cache_media = _media.values.to_array();
		_media_lock.unlock();
		
		for(int i = 0; i < cache_media.length; ++i) {
			var m = cache_media[i];
			if(m.mediatype == Media.MediaType.STATION || 
			(m.mediatype == Media.MediaType.PODCAST && m.uri.has_prefix("http:/"))) {
				// don't try to find this
			}
			else {
				if(File.new_for_uri(m.uri).query_exists() && m.location_unknown) {
					m.unique_status_image = null;
					m.location_unknown = false;
					found.add(m);
				}
				else if(!File.new_for_uri(m.uri).query_exists() && !m.location_unknown) {
					m.unique_status_image = not_found_pix;
					m.location_unknown = true;
					not_found.add(m);
				}
			}
		}
		
		Idle.add( () => {
			if(not_found.size > 0) {
				warning("Some media files could not be found and are being marked as such.\n");
				update_medias(not_found, false, false, true);
				foreach(var m in not_found) {
					lw.media_not_found(m.rowid);
				}
			}
			if(found.size > 0) {
				warning("Some media files whose location were unknown were found.\n");
				update_medias(found, false, false, true);
				foreach(var m in found) {
					lw.media_found(m.rowid);
				}
			}
			
			return false;
		});
#endif
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
		Playlist? rv = null;

		_playlists_lock.lock ();
		foreach(var p in playlists ()) {
			if(p.name == name)
				rv = p;
				break;
		}
		_playlists_lock.unlock ();

		return rv;
	}
	
	public int add_playlist(Playlist p) {
		_playlists_lock.lock ();
		p.rowid = _playlists.size + 1;
		_playlists.set(p.rowid, p);
		_playlists_lock.unlock ();

		dbm.add_playlist(p);
		
		return p.rowid;
	}
	
	public void remove_playlist(int id) {
		Playlist removed;

		_playlists_lock.lock ();
		_playlists.unset(id, out removed);
		_playlists_lock.unlock ();

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
		SmartPlaylist? rv = null;

		_smart_playlists_lock.lock ();
		foreach(var p in smart_playlists ()) {
			if(p.name == name)
				rv = p;
				break; 
		}
		_smart_playlists_lock.unlock ();
		
		return rv;
	}
	
	public async void save_smart_playlists() {
		try {
			new Thread<void*>.try (null, () => {
				_smart_playlists_lock.lock ();
				dbm.save_smart_playlists(smart_playlists ());
				_smart_playlists_lock.unlock ();

				return null;
			});
		} catch (Error err) {
			warning (err.message);
		}
	}
	
	public int add_smart_playlist(SmartPlaylist p) {
		_smart_playlists_lock.lock ();
		p.rowid = _smart_playlists.size + 1;// + 1 for 1-based db
		_smart_playlists.set(p.rowid, p);
		_smart_playlists_lock.unlock ();
		
		save_smart_playlists();
		
		return p.rowid;
	}
	
	public void remove_smart_playlist(int id) {
		SmartPlaylist removed;
		_smart_playlists_lock.lock ();
		_smart_playlists.unset(id, out removed);
		_smart_playlists_lock.unlock ();
		
		dbu.removeItem(removed);
	}
	
	/******************** Media stuff ******************/
	public void clear_media () {
		debug ("Clearing media");

		// We really only want to clear the songs that are permanent and on the file system
		// Dont clear podcasts that link to a url, device media, temporary media, previews, songs
		_media_lock.lock();

		var unset = new LinkedList<Media> ();
		var unset_ids = new LinkedList<int> ();

		foreach (int i in _media.keys) {
			Media s = _media.get (i);

			if(!(s.isTemporary || s.isPreview || s.uri.has_prefix("http://"))) {
				if( (s.mediatype == Media.MediaType.PODCAST && s.podcast_url != null && s.podcast_url.has_prefix("http://")) || 
					s.mediatype == Media.MediaType.STATION) {
					s.uri = s.podcast_url;
				}
				else {
					unset.add(s);
					unset_ids.add(s.rowid);
				}
			}
		}
		
		foreach(Media s in unset) {
			_media.unset(s.rowid);
			
			if(s.mediatype == Media.MediaType.SONG)
				_songs.unset(s.rowid);
#if 0
			else if(s.mediatype == Media.MediaType.PODCAST)
				_podcasts.unset(s.rowid);
			else if(s.mediatype == Media.MediaType.AUDIOBOOK)
				_audiobooks.unset(s.rowid);
			else if(s.mediatype == Media.MediaType.STATION)
				_stations.unset(s.rowid);
#endif
		}
		_media_lock.unlock ();
		
		_playlists_lock.lock ();
		foreach (var p in playlists ()) {
			p.remove_media (unset_ids);
		}		
		_playlists_lock.unlock ();

		// Analyze sets the matching media as the playlist's media,
		// so we have to pass all the ids.
		_smart_playlists_lock.lock ();
		foreach (var p in smart_playlists ()) {
			p.analyze (this, media ());
		}
		_smart_playlists_lock.unlock ();

		dbm.clear_media ();
		dbm.add_media (_media.values);

		debug ("--- MEDIA CLEARED ---");
	}


	public int song_count() {
		return _songs.size;
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
	
	public Collection<int> song_ids() {
		return _songs.keys;
	}
#if HAVE_PODCASTS
	public Collection<int> podcast_ids() {
		return _podcasts.keys;
	}
#endif	
	
#if HAVE_INTERNET_RADIO
	public Collection<int> station_ids() {
		return _stations.keys;
	}
#endif
	
	public HashMap<int, Media> media_hash() {
		return _media;
	}
	
	public void update_media_item (Media s, bool updateMeta, bool record_time) {
		LinkedList<Media> one = new LinkedList<Media>();
		one.add(s);
		
		update_media(one, updateMeta, record_time);
	}
	
	public void update_media (Collection<Media> updates, bool updateMeta, bool record_time) {
		LinkedList<int> rv = new LinkedList<int>();
		
		foreach(Media s in updates) {
			/*_media.set(s.rowid, s);*/
			rv.add(s.rowid);
			
			if(record_time)
				s.last_modified = (int)time_t();
		}

		// Analyze sets the matching media as the playlist's media,
		// so we have to pass the entire media list.
		_smart_playlists_lock.lock ();
		foreach (var p in smart_playlists ()) {
			p.analyze (this, media ());
		}
		_smart_playlists_lock.unlock ();


		debug ("%d media updated from lm.update_media 677\n", rv.size);
		media_updated(rv);

		/* now do background work. even if updateMeta is true, so must user preferences */
		if(updateMeta)
			fo.save_media(updates);
		
		foreach(Media s in updates)
			dbu.update_media(s);
	}

	public async void save_media() {

		try {
			new Thread<void*>.try (null, () => {
				_media_lock.lock ();
				dbm.update_media (_media.values);
				_media_lock.unlock ();

				return null;
			});
		} catch (Error err) {
			warning (err.message);
		}
	}
	
	/** Used extensively. All other media data stores a media rowid, and then
	 * use this to retrieve the media. This is for memory saving and 
	 * consistency
	 */
	public Media media_from_id(int id) {
		return _media.get(id);
	}

	public Gee.Collection<Media> media_from_ids (Gee.Collection<int> ids) {
		var media_collection = new Gee.LinkedList<Media> ();

		foreach (int id in ids) {
			var m = media_from_id (id);
			if (m != null)
				media_collection.add (m);
		}

		return media_collection;
	} 

	public Media? match_media_to_list(Media m, Collection<Media> to_match) {
		Media? rv = null;
		
		_media_lock.lock();
		foreach(var test in to_match) {
			if(!test.isTemporary && test != m && test.title.down() == m.title.down() && test.artist.down() == m.artist.down()) {
				rv = test;
			}
		}
		_media_lock.unlock();
		
		return rv;
	}

	public Media media_item_from_name(string title, string artist) {
		Media rv = new Media("");
		rv.title = title;
		rv.artist = artist;
		Media[] searchable;
		
		_media_lock.lock();
		searchable = _media.values.to_array();
		_media_lock.unlock();
		
		for(int i = 0; i < searchable.length; ++i) {
			Media s = searchable[i];
			if(s.title.down() == title.down() && s.artist.down() == artist.down())
				return s;
		}
		
		return rv;
	}
	
	public void media_from_name(Collection<Media> tests, ref LinkedList<int> found, ref LinkedList<Media> not_found) {
		Media[] searchable;
		
		_media_lock.lock();
		searchable = _media.values.to_array();
		_media_lock.unlock();
		
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
		Media? rv = null;

		_media_lock.lock ();
		foreach(Media s in _media.values) {
			if(s.uri == uri)
				rv = s;
		}
		_media_lock.unlock ();
		
		return rv;
	}

	/**
	 * Search function
	 */
	public void do_search (Collection<int> to_search,
	                        out LinkedList<int> ? results,
	                        out LinkedList<int> ? album_results,
	                        out LinkedList<int> ? genre_results,
	                        out LinkedList<int> ? year_results,
	                        out LinkedList<int> ? rating_results,
	                        ViewWrapper.Hint hint,
	                        string search = "", // Search string
	                        string album_artist = "",
	                        string album = "",
	                        string genre = "",
	                        int year = -1, // All years
	                        int rating = -1 // All ratings
	                        )
	{
		results = new LinkedList<int>();
		album_results = new LinkedList<int>();
		genre_results = new LinkedList<int>();
		year_results = new LinkedList<int>();
		rating_results = new LinkedList<int>();

		string l_search = search.down();
		int mediatype = 0;

		bool include_temps = hint == ViewWrapper.Hint.CDROM ||
		                     hint == ViewWrapper.Hint.DEVICE_AUDIO || 
		                     hint == ViewWrapper.Hint.DEVICE_PODCAST ||
		                     hint == ViewWrapper.Hint.DEVICE_AUDIOBOOK ||
		                     hint == ViewWrapper.Hint.QUEUE ||
		                     hint == ViewWrapper.Hint.HISTORY ||
		                     hint == ViewWrapper.Hint.ALBUM_LIST;

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
		         hint == ViewWrapper.Hint.ALBUM_LIST)
		{
			mediatype = -1; // some lists should be able to have ALL media types
		}
		
		foreach(int i in to_search) {
			Media s = media_from_id(i);

			bool valid_song =   s != null &&
			                  ( s.mediatype == mediatype || mediatype == -1 ) &&
			                  ( !s.isTemporary || include_temps ) &&
			                  ( l_search in s.title.down() ||
			                    l_search in s.album_artist.down() ||
			                    l_search in s.artist.down() ||
			                    l_search in s.album.down() ||
			                    l_search in s.genre.down() ||
			                    l_search == s.year.to_string()); // We want full match here

			if (valid_song)
			{
				if (rating == -1 || (int)s.rating == rating)
				{
					if (year == -1 || (int)s.year == year)
					{
						if (album_artist == "" || s.album_artist == album_artist)
						{
							if (genre == "" || s.genre == genre)
							{
								if (album == "" || s.album == album)
								{
									results.add (i);
								}

								genre_results.add (i);
							}
					
							album_results.add (i);
						}

						year_results.add (i);
					}

					rating_results.add (i);
				}
			}
		}
	}


	public Gee.Collection<Media> media_from_playlist (int id) {
		return _playlists.get (id).media ();
	}
	
	public Collection<Media> media_from_smart_playlist (int id) {
		return _smart_playlists.get (id).analyze (this, media ());
	}
	
	public void add_media_item (Media s) {
		var coll = new LinkedList<Media>();
		coll.add(s);
		add_media (coll);
	}
	
	public void add_media(Collection<Media> new_media) {
		if(new_media.size < 1) // happens more often than you would think
			return;
		
		int top_index = 0;
		
		_media_lock.lock();
		foreach(int i in _media.keys) {
			if(i > top_index)
				top_index = i;
		}
		
		var added = new LinkedList<int>();
		foreach(var s in new_media) {
			if(s.rowid == 0)
				s.rowid = ++top_index;
			
			added.add(s.rowid);
			
			_media.set(s.rowid, s);
			
			if(s.mediatype == Media.MediaType.SONG)
				_songs.set(s.rowid, s);
#if 0
			else if(s.mediatype == Media.MediaType.PODCAST)
				_podcasts.set(s.rowid, s);
			else if(s.mediatype == Media.MediaType.AUDIOBOOK)
				_audiobooks.set(s.rowid, s);
			else if(s.mediatype == Media.MediaType.STATION)
				_stations.set(s.rowid, s);
#endif
		}
		_media_lock.unlock();
		
		if(new_media.size > 0) {
			dbm.add_media(new_media);
		}
		
		Idle.add( () => {
			media_added(added);
			
			return false;
		});
	}
	
	public void remove_media(LinkedList<Media> toRemove, bool trash) {
		var removedIds = new LinkedList<int>();
		var removeURIs = new LinkedList<string>();
		
		foreach(Media s in toRemove) {
			removedIds.add(s.rowid);
			removeURIs.add(s.uri);
			
			if(s == media_info.media)
				stopPlayback();
		}
		
		dbu.removeItem(removeURIs);
		
		if(trash) {
			fo.remove_media(removeURIs);
		}
		
		_media_lock.lock();
		foreach(Media s in toRemove) {
			_media.unset(s.rowid);
			
			if(s.mediatype == Media.MediaType.SONG)
				_songs.unset(s.rowid);
#if 0
			else if(s.mediatype == Media.MediaType.PODCAST)
				_podcasts.unset(s.rowid);
			else if(s.mediatype == Media.MediaType.AUDIOBOOK)
				_audiobooks.unset(s.rowid);
			else if(s.mediatype == Media.MediaType.STATION)
				_stations.unset(s.rowid);
#endif
		}
		_media_lock.unlock();
		
		_playlists_lock.lock();
		foreach(var p in playlists ()) {
			p.remove_media (toRemove);
		}
		_playlists_lock.unlock();

		// Analyze sets the matching media as the playlist's media,
		// so we have to pass the entire media list.
		_smart_playlists_lock.lock ();
		foreach (var p in smart_playlists ()) {
			p.analyze (this, media ());
		}
		_smart_playlists_lock.unlock ();


		if(_media.size == 0)
			settings.setMusicFolder(Environment.get_user_special_dir(UserDirectory.MUSIC));

		media_removed(removedIds);
		
		// TODO: move away. It's called twice due to LW's internal handlers		
		lw.update_sensitivities();
	}
	
	/**************** Queue Stuff **************************/
	public bool queue_empty() {
		return (_queue.size == 0);
	}
	
	public void clear_queue() {
		_queue.clear();
		queue_cleared ();
	}

	public void queue_media (Gee.Collection<Media> to_queue) {
		if (to_queue.size < 1)
			return;
		
		foreach (var m in to_queue)
			_queue.offer_tail (m);

		media_queued (to_queue);
	}

	public void queue_media_by_id (Collection<int> ids) {
		queue_media (media_from_ids (ids));		
	}


	public void unqueue_media (Gee.Collection<Media> to_unqueue) {
		foreach (var m in to_unqueue)
			_queue.remove (m);
		media_unqueued (to_unqueue);
	}

	public void unqueue_media_by_id (Collection<int> ids) {
		unqueue_media (media_from_ids (ids));		
	}

	public Media peek_queue() {
		return _queue.peek_head();
	}
	
	public Media poll_queue() {
		var m = _queue.poll_head ();
		var unqueued = new Gee.LinkedList<Media> ();
		unqueued.add (m);
		media_unqueued (unqueued);
		return m;
	}

	public Collection<Media> queue() {
		return _queue;
	}

	/************ Already Played Stuff **************/
	public void reset_already_played() {
		_already_played.clear();
		history_changed ();
	}

	public void add_already_played (Media m) {
		if(!_already_played.contains (m))
			_already_played.offer_tail (m);
		history_changed ();
	}
	
	public LinkedList<Media> already_played() {
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
	
	public Media mediaFromCurrentIndex (int index_in_current) {
		if(shuffle == Shuffle.OFF)
			return _current.get(index_in_current);
		else
			return _current_shuffled.get(index_in_current);
	}
	
	public Collection<Media> current_media () {
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
	
	public void addToCurrent (Media m) {
		_current.set (_current.size, m);
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
			if(media_active) {
				//make sure we continue playing where we left off
				for(int i = 0; i < _current.size; ++i) {
					if(_current.get(i) == media_info.media) {
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
			//create temp list of all of current's media
			var temp = new LinkedList<Media>();
			foreach(var m in _current.values) {
				temp.add (m);
			}
			
			//loop through all current media id's and pick a random one remaining
			//and set that int i as one of those this is confusing just a sort
			//_current_shuffled.set(0, media_info.media.rowid);
			for(int i = 1;i < _current.size; ++i) {
				int random = GLib.Random.int_range(0, temp.size);
				
				//if(temp.get(random) != media_info.media.rowid) {
				if(media_active && temp.get(random) == media_info.media) {
					_current_shuffled.set(0, media_info.media);
					--i;
				}
				else {
					_current_shuffled.set(i, temp.get(random));
				}
				temp.remove(temp.get(random));
			}
		}
	}
	
	public Media? getNext(bool play) {
		Media? rv = null;
		
		// next check if user has queued media
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
					
					return null;
				}
				
				rv = _current_shuffled.get(0);
			}
			else if(_current_shuffled_index >= 0 && _current_shuffled_index < (_current_shuffled.size - 1)){
				// make sure we are repeating what we need to be
				if(repeat == Repeat.ARTIST && _current_shuffled.get(_current_shuffled_index + 1).artist != _current_shuffled.get(_current_shuffled_index).artist) {
					while(_current_shuffled.get(_current_shuffled_index - 1).artist == media_info.media.artist)
						--_current_shuffled_index;
				}
				else if(repeat == Repeat.ALBUM && _current_shuffled.get(_current_shuffled_index + 1).album != _current_shuffled.get(_current_shuffled_index).album) {
					while(_current_shuffled.get(_current_shuffled_index - 1).album == media_info.media.album)
						--_current_shuffled_index;
				}
				else {
					++_current_shuffled_index;
				}
				
				rv = _current_shuffled.get(_current_shuffled_index);
			}
			else {
				foreach(Media s in _media.values)
					addToCurrent(s);
				
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
					return null;
				}
				
				rv = _current.get(0);
			}
			else if(_current_index >= 0 && _current_index < (_current.size - 1)){
				// make sure we are repeating what we need to be
				if(repeat == Repeat.ARTIST && _current.get(_current_index + 1).artist != _current.get(_current_index).artist) {
					while(_current.get(_current_index - 1).artist == media_info.media.artist)
						--_current_index;
				}
				else if(repeat == Repeat.ALBUM && _current.get(_current_index + 1).album != _current.get(_current_index).album) {
					while(_current.get(_current_index - 1).album == media_info.media.album)
						--_current_index;
				}
				else
					++_current_index;
				
				rv = _current.get(_current_index);
			}
			else {
				foreach(Media s in _media.values)
					addToCurrent(s);
				
				_current_index = 0;
				rv = _current.get(0);
			}
		}
		
		if(play)
			playMedia(rv, false);
		
		return rv;
	}
	
	// TODO: remove code redundancy
	public Media? getPrevious(bool play) {
		Media? rv = null;
		
		if(_current_shuffled.size != 0) {
			_playing_queued_song = false;
			
			if(media_info.media == null) {
				_current_shuffled_index = _current_shuffled.size - 1;
				rv = _current_shuffled.get (_current_shuffled_index);
			}
			else if(repeat == Repeat.MEDIA) {
				rv = _current_shuffled.get(_current_shuffled_index);
			}
			else if(_current_shuffled_index == 0) {// consider repeat options
				if(repeat == Repeat.ALL)
					_current_shuffled_index = _current_shuffled.size - 1;
				else {
					stopPlayback();
					return null;
				}
				
				rv = _current_shuffled.get(_current_shuffled_index);
			}
			else if(_current_shuffled_index > 0 && _current_shuffled_index < _current_shuffled.size){
				// make sure we are repeating what we need to be
				if(repeat == Repeat.ARTIST && _current_shuffled.get(_current_shuffled_index - 1).artist != _current_shuffled.get(_current_shuffled_index).artist) {
					while(_current_shuffled.get(_current_shuffled_index + 1).artist == media_info.media.artist)
						++_current_shuffled_index;
				}
				else if(repeat == Repeat.ALBUM && _current_shuffled.get(_current_shuffled_index - 1).album != _current_shuffled.get(_current_shuffled_index).album) {
					while(_current_shuffled.get(_current_shuffled_index + 1).album == media_info.media.album)
						++_current_shuffled_index;
				}
				else
					--_current_shuffled_index;
				
				rv = _current_shuffled.get(_current_shuffled_index);
			}
			else {
				foreach(Media s in _media.values)
					addToCurrent(s);
				
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
					return null;
				}
				
				rv = _current.get(_current_index);
			}
			else if(_current_index > 0 && _current_index < _current.size){
				// make sure we are repeating what we need to be
				
				if(repeat == Repeat.ARTIST && _current.get(_current_index - 1).artist != _current.get(_current_index).artist) {
					while(_current.get(_current_index + 1).artist == media_info.media.artist)
						++_current_index;
				}
				else if(repeat == Repeat.ALBUM && _current.get(_current_index - 1).album != _current.get(_current_index).album) {
					while(_current.get(_current_index + 1).album == media_info.media.album)
						++_current_index;
				}
				else
					--_current_index;
				
				rv = _current.get(_current_index);
			}
			else {
				foreach(Media s in _media.values)
					addToCurrent(s);
				
				_current_index = _current.size - 1;
				rv = _current.get(_current_index);
			}
		}
		
		if(play)
			playMedia(rv, false);
		
		return rv;
	}
	
	
	public void playMedia(Media m, bool use_resume_pos) {
		if(m.isTemporary) {
			_media.set(PREVIEW_MEDIA_ID, m);
			playMediaInternal(PREVIEW_MEDIA_ID, use_resume_pos);
		}
		else {
			playMediaInternal(m.rowid, use_resume_pos);
		}
	}
	
	void playMediaInternal(int id, bool use_resume_pos) {
		int old_id = -1;
		
		if(id == 0 || media_from_id(id) == null)
			return;
		
		// save previous media's id
		if(media_active)
			old_id = media_info.media.rowid;
		
		// set the current media
		media_info.media = media_from_id(id);
		Media m = media_from_id(id);
		
		// To avoid infinite loop, if we come across a song we already know does not exist
		// stop playback
		if(m.location_unknown) {
			if(File.new_for_uri(m.uri).query_exists()) { // we did not know location, but it has re-appearred
				m.location_unknown = false;
				m.unique_status_image = null;
				//lw.media_found(m.rowid);
			}
			else { // to avoid infinite loop with repeat on, don't try to play next again
				stopPlayback();
				return;
			}
		}
		
		// check that the file exists FIXME: Avoid reading settings everytime a song is played
		var music_folder_uri = File.new_for_path(settings.getMusicFolder()).get_uri();
		if((settings.getMusicFolder() != "" && m.uri.has_prefix(music_folder_uri) && !GLib.File.new_for_uri(m.uri).query_exists())) {
			m.unique_status_image = Icons.PROCESS_ERROR.render(IconSize.MENU, ((ViewWrapper)lw.sideTree.getWidget(lw.sideTree.library_music_iter)).list_view.get_style_context());
			m.location_unknown = true;
			//lw.media_not_found(id);
			getNext(true);
			return;
		}
		else {
			if(m.location_unknown && m.unique_status_image != null) {
				m.unique_status_image = null;
				m.location_unknown = false;
			}
		}
		
		if(m.mediatype == Media.MediaType.PODCAST || m.mediatype == Media.MediaType.AUDIOBOOK || use_resume_pos)
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
		if(id != PREVIEW_MEDIA_ID)
			settings.setLastMediaPlaying(id);
		
		if (m != null)
			media_played (m);
		
		/* if same media 1 second later...
		 * check for embedded art if need be (not loaded from on file) and use that
		 * check that the s.getAlbumArtPath() exists, if not set to "" and call updateCurrentMedia
		 * save old media's resume_pos
		 */
		Timeout.add(1000, () => {
			if(media_info.media == m) {
				try {
					new Thread<void*>.try (null, change_gains_thread);
				}
				catch(GLib.Error err) {
					warning("Could not create thread to change gains: %s\n", err.message);
				}
		
				if(!File.new_for_path(media_info.media.getAlbumArtPath()).query_exists()) {
					media_info.media.setAlbumArtPath("");
				}
				
				// potentially fix media length
				int player_duration = (int)(player.getDuration()/1000000000);
				if(player_duration > 1 && Math.fabs((double)(player_duration - media_info.media.length)) > 3) {
					media_info.media.length = (int)(player.getDuration()/1000000000);
					update_media_item (media_info.media, false, false);
				}
			}
			
			return false;
			
		});
	}

	
	public void* change_gains_thread () {
		if(settings.getEqualizerEnabled()) {
			bool automatic_enabled = settings.getAutoSwitchPreset();
			string selected_preset = settings.getSelectedPreset();

			foreach(var p in settings.getCustomPresets ()) {
				if(p != null && media_active)  {
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

			foreach(var p in Equalizer.get_default_presets ()) {
				if(p != null && media_active)  {
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

#if HAVE_STORE
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
		add_media(temps, false);
		
		playMedia(-2, false);
		
		if(!playing) {
			lw.playClicked();
		}
	}
#endif
	
	public void stopPlayback() {
		player.pause();
		
		int was_playing = 0;
		if(media_active)
			was_playing = media_info.media.rowid;
		
		settings.setLastMediaPlaying(0);
		media_info.update(null, null, null, null);
		
		playback_stopped(was_playing);
	}
	

	
	/************ Image stuff ********************/
	public string getAlbumArtPath(int id) {
		return _media.get(id).getAlbumArtPath();
	}
	
	public void save_album_locally(int id, string image_uri) {
		GLib.File file = GLib.File.new_for_uri(image_uri);
		if(file == null) {
			stdout.printf("Could not read image_uri as file\n");
			return;
		}
		
		FileInputStream filestream;
		Gdk.Pixbuf? pix = null;

		try {
			filestream = file.read(null);
			pix = new Gdk.Pixbuf.from_stream(filestream, null);
		} catch(GLib.Error err) {
			warning ("Failed to save album art locally from %s: %s\n", image_uri, err.message);
		}

		if (pix != null) {
			debug ("got pix and saving it now\n");
			fo.save_album_art_in_cache(_media.get(id), pix);
			set_album_art(id, pix);
		}
	}

	public async void fetch_cover_art_from_cache_async () {
		try {
			new Thread<void*>.try (null, () => { fetch_cover_art (true); return null; });
		} catch (Error err) {
			warning (err.message);
		}
	}

	public async void fetch_all_cover_art_async () {
		try {
			new Thread<void*>.try (null, () => { fetch_cover_art (false); return null; });
		} catch (Error err) {
			warning (err.message);
		}
	}

	private void fetch_cover_art (bool cache_only) {
		if(in_fetch_thread)
			return;

		debug ("----------- READING CACHED COVERART -------------");

		in_fetch_thread = true;
		//GStreamerTagger tagger = new GStreamerTagger(this);
		
		foreach(var s in _media.values) {
			string key = get_media_coverart_key (s), path = "";
			Gdk.Pixbuf? pix = null;

			if(!cover_album_art.has_key (key) && s.mediatype == 0) {
				
				if(key != null) {
					// try to get image from cache (faster)					
					Gdk.Pixbuf? coverart_pixbuf = fo.get_cached_album_art (key, out path);
					if (coverart_pixbuf != null) {
						// get_pixbuf_shadow automatically scales the pixbuf down
						// to Icons.ALBUM_VIEW_IMAGE_SIZE
						pix = get_pixbuf_shadow (coverart_pixbuf);
					}
					else if (!cache_only) {
						/* TODO: Get image from the tagger object (i.e. song metadata) */
						//coverart_pixbuf = tagger.get_embedded_art(s);

						if ((path = fo.get_best_album_art_file(s)) != null && path != "") {
							try {
								coverart_pixbuf = new Gdk.Pixbuf.from_file (path);
								//coverart_pixbuf = _pix.scale_simple (200, 200, Gdk.InterpType.BILINEAR);
								pix = get_pixbuf_shadow (coverart_pixbuf);
								
								// Add image to cache
								fo.save_album_art_in_cache (s, coverart_pixbuf);
							}
							catch(GLib.Error err) {
								warning (err.message);
							}
						}
					}

					// we set the pixbuf even if it's null to avoid entering
					// the loop for the same album later.
					cover_album_art.set(key, pix);
				}
			}
			
			if (cover_album_art.get (key) != null)
				s.setAlbumArtPath (fo.get_cached_album_art_path (key));
		}

		in_fetch_thread = false;

		debug ("----------- FINISHED LOADING CACHED COVERART -------------");
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
	public string get_media_coverart_key (Media s) {
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
			cover_album_art.set(key, get_pixbuf_shadow (pix));
	}

	public Gdk.Pixbuf get_pixbuf_shadow (Gdk.Pixbuf pix) {
		return PixbufUtils.get_pixbuf_shadow (pix, Icons.ALBUM_VIEW_IMAGE_SIZE);
	}

	public bool start_file_operations(string? message) {
		if(_doing_file_operations)
			return false;
		
		progress_notification(message, 0.0);
		_doing_file_operations = true;
		lw.update_sensitivities();
		file_operations_started();
		return true;
	}

	public bool doing_file_operations() {
		return _doing_file_operations;
	}
	
	public void finish_file_operations() {
		_doing_file_operations = false;
		debug("file operations finished or cancelled\n");
		
#if HAVE_PODCASTS
		if(!have_fetched_new_podcasts) {
			pm.find_new_podcasts();
		}
		else {
			fetch_all_cover_art_async ();
			
			lw.update_sensitivities();
			lw.updateInfoLabel();
			file_operations_done();
		}
#else
		fetch_all_cover_art_async ();
		
		lw.update_sensitivities();
		lw.updateInfoLabel();
		file_operations_done();
#endif
	}
}

