using GPod;
using Gee;

public class BeatBox.iPodDevice : GLib.Object, BeatBox.Device {
	LibraryManager lm;
	DevicePreferences pref;
	iTunesDB db;
	Mount mount;
	GLib.Icon icon;
	bool currently_syncing;
	bool sync_cancelled;
	LinkedList<int> list; // used to pass data to thread
	int index = 0;
	int total = 0;
	string current_operation;
	
	HashMap<unowned GPod.Track, int> media;
	HashMap<unowned GPod.Track, int> songs;
	HashMap<unowned GPod.Track, int> podcasts;
	HashMap<unowned GPod.Track, int> audiobooks;
	HashMap<unowned GPod.Playlist, int> playlists;
	HashMap<unowned GPod.Playlist, int> smart_playlists;
	
	
	public iPodDevice(LibraryManager lm, Mount mount) {
		this.lm = lm;
		this.mount = mount;
		
		pref = lm.get_device_preferences(get_unique_identifier());
		if(pref == null) {
			pref = new DevicePreferences(get_unique_identifier());
			lm.add_device_preferences(pref);
		}
		
		icon = mount.get_icon();
		currently_syncing = false;
		sync_cancelled = false;
		
		index = 0;
		total = 0;
		current_operation = "";
		
		media = new HashMap<unowned GPod.Track, int>();
		songs = new HashMap<unowned GPod.Track, int>();
		podcasts = new HashMap<unowned GPod.Track, int>();
		audiobooks = new HashMap<unowned GPod.Track, int>();
		playlists = new HashMap<unowned GPod.Playlist, int>();
		smart_playlists = new HashMap<unowned GPod.Playlist, int>();
	}
	
	public DevicePreferences get_preferences() {
		return pref;
	}
	
	public bool start_initialization() {
		try {
			db = iTunesDB.parse(get_path());
		}
		catch(Error err) {
			stdout.printf("Error parsing db at %s: %s\n", get_path(), err.message);
			return false;
		}
		
		return true;
	}
	
	public void finish_initialization() {
		device_unmounted.connect( () => {
			
		});
		
		try {
			Thread.create<void*>(finish_initialization_thread, false);
		}
		catch(GLib.ThreadError err) {
			stdout.printf("ERROR: Could not create thread to finish ipod initialization: %s \n", err.message);
		}
	}
	
	void* finish_initialization_thread() {
		var toAdd = new HashMap<unowned GPod.Track, Song>();
		for(int i = 0; i < db.tracks.length(); ++i) {
			unowned GPod.Track t = db.tracks.nth_data(i);
			//stdout.printf("found track and rating is %d and app rating %d and id is %d\n", (int)db.tracks.nth_data(i).rating, (int)db.tracks.nth_data(i).app_rating, (int)db.tracks.nth_data(i).id);
			var s = Song.from_track(get_path(), t);
			s.isTemporary = true;
			
			var existing = lm.song_from_name(s.title, s.artist);
			
			if(existing.rowid > 0) {
				//stdout.printf("found match for %s\n", s.title);
				this.media.set(t, existing.rowid);
				
				if(t.mediatype == GPod.MediaType.AUDIO)
					this.songs.set(t, existing.rowid);
				else if(t.mediatype == GPod.MediaType.PODCAST)
					this.podcasts.set(t, existing.rowid);
				else if(t.mediatype == GPod.MediaType.AUDIOBOOK)
					this.audiobooks.set(t, existing.rowid);
			}
			else {
				toAdd.set(t, s);
			}
		}
		
		lm.add_songs(toAdd.values, false);
		foreach(var e in toAdd.entries) {
			this.media.set(e.key, e.value.rowid);
			
			if(e.key.mediatype == GPod.MediaType.AUDIO)
				this.songs.set(e.key, e.value.rowid);
			else if(e.key.mediatype == GPod.MediaType.PODCAST)
				this.podcasts.set(e.key, e.value.rowid);
			else if(e.key.mediatype == GPod.MediaType.AUDIOBOOK)
				this.audiobooks.set(e.key, e.value.rowid);
		}
		
		//lock(lm._songs) {
			//lm.add_songs(trToSo, false);
		//}
		/*
		for(int i = 0; i < db.playlists.length(); ++i) {
			unowned GPod.Playlist p = db.playlists.nth_data(i);
			
			if(!p.is_spl) {
				Playlist bbPlaylist = Playlist.from_ipod(p);
				
				foreach(unowned GPod.Track t in songs.keys) {
					if(p.contains_track(t)) {
						bbPlaylist.addSong(songs.get(t));
					}
				}
				
				lm.add_playlist(bbPlaylist);
				playlists.set(p, bbPlaylist.rowid);
			}
			else {
				SmartPlaylist sp = SmartPlaylist.from_ipod(p);
				
				
			}
		}*/
		
		Idle.add( () => {
			initialized(this);
			
			return false;
		});
		
		return null;
	}
	
	public bool isNew() {
		return mount.get_default_location().get_parse_name().has_prefix("afc://");
	}
	
	public string getContentType() {
		if(isNew())
			return "ipod-new";
		else
			return "ipod-old";
	}
	
	public string getDisplayName() {
		return db.playlist_mpl().name;
	}
	
	public void setDisplayName(string name) {
		db.playlist_mpl().name = name;
		try {
			mount.get_default_location().set_display_name(name);
		}
		catch(GLib.Error err) {
			stdout.printf("Could not set iPod Mount Display Name: %s\n", err.message);
		}
		lm.lw.sideTree.setNameFromObject(lm.lw.sideTree.convertToFilter(lm.lw.sideTree.devices_iter), this, name);
	}
	
	public string get_fancy_description() {
		/*unowned GPod.iPodInfo ipod_info = db.device.get_ipod_info();
		stdout.printf("got here\n");
		GPod.iPodModel enum_model = ipod_info.ipod_model;
		GPod.iPodGeneration enum_gen = ipod_info.ipod_generation;*/
		stdout.printf("got here\n");
		string model = "model here";//GPod.iPodInfo.get_ipod_model_name_string(enum_model);
		stdout.printf("got here\n");
		//var gen = GPod.iPodInfo.get_ipod_generation_string(enum_gen);
		string gen = "gen 1";
		return gen + " " + model;
	}
	
	public void set_mount(Mount mount) {
		this.mount = mount;
	}
	
	public Mount get_mount() {
		return mount;
	}
	
	public string get_path() {
		return mount.get_default_location().get_path();
	}
	
	public void set_icon(GLib.Icon icon) {
		this.icon = icon;
	}
	
	public GLib.Icon get_icon() {
		return icon;
	}
	
	public uint64 get_capacity() {
		var file_info = File.new_for_path(get_path()).query_filesystem_info("filesystem::*", null);
		return file_info.get_attribute_uint64(GLib.FILE_ATTRIBUTE_FILESYSTEM_SIZE);
	}
	
	public string get_fancy_capacity() {
		return "Unknown Capacity";//db.device.get_ipod_info().capacity.to_string() + "GB";
	}
	
	public uint64 get_used_space() {
		return get_capacity() - get_free_space();
	}
	
	public uint64 get_free_space() {
		var file_info = File.new_for_path(get_path()).query_filesystem_info("filesystem::*", null);
		return file_info.get_attribute_uint64(GLib.FILE_ATTRIBUTE_FILESYSTEM_FREE);
	}
	
	public void unmount() {
		
	}
	
	public void eject() {
		
	}
	
	public void get_device_type() {
		
	}
	
	public bool supports_podcasts() {
		return db.device.supports_podcast();
	}
	
	public bool supports_audiobooks() {
		return true; // no device.supports_audiobook(), but there is audiobook playlist
	}
	
	public Collection<int> get_songs() {
		return songs.values;
	}
	
	public Collection<int> get_podcasts() {
		return podcasts.values;
	}
	
	public Collection<int> get_audiobooks() {
		return audiobooks.values;
	}
	
	public Collection<int> get_playlists() {
		return playlists.values;
	}
	
	public Collection<int> get_smart_playlists() {
		return smart_playlists.values;
	}
	
	public bool sync_songs(LinkedList<int> list) {
		if(currently_syncing) {
			stdout.printf("Tried to sync when already syncing\n");
			return false;
		}
		else if(lm.doing_file_operations()) {
			stdout.printf("Can't sync. Already doing file operations\n");
			return false;
		}
		
		bool fits = will_fit(list);
		if(!fits) {
			stdout.printf("Tried to sync songs that will not fit\n");
			return false;
		}
		
		lm.start_file_operations("Syncing <b>" + getDisplayName() + "</b>...");
		current_operation = "Syncing <b>" + getDisplayName() + "</b>...";
		this.list = list;
		
		try {
			Thread.create<void*>(sync_songs_thread, false);
		}
		catch(GLib.ThreadError err) {
			stdout.printf("ERROR: Could not create thread to sync songs: %s \n", err.message);
			return false;
		}
		
		return true;
	}
	
	public bool is_syncing() {
		return currently_syncing;
	}
	
	public void cancel_sync() {
		sync_cancelled = true;
	}
	
	public bool will_fit(LinkedList<int> list) {
		uint64 list_size = 0;
		foreach(int i in list) {
			list_size += lm.song_from_id(i).file_size * 1000000; // convert from MB to bytes
		}
		
		return get_capacity() > list_size;
	}
	
	void* sync_songs_thread() {
		currently_syncing = true;
		bool error_occurred = false;
		index = 0;
		int sub_index = 0;
		total = 100;
		Timeout.add(500, doProgressNotificationWithTimeout);
		
		db.start_sync();
		
		// sync local files with new info
		foreach(unowned GPod.Track t in media.keys) {
			Song s = lm.song_from_id(media.get(t));
			
			if(!s.isTemporary) {
				// update the song with data from device
				//stdout.printf("t.rating is %d, s.rating is %d\n", (int)t.rating, (int)s.rating);
				if(pref.last_sync_time >= s.last_modified) { // song has not been modified since last sync
					if(t.rating > 0)
						stdout.printf("%s rating %d\n", t.title, (int)t.rating);
					s.rating = t.rating / 20;
				}
				
				s.play_count += t.recent_playcount;
				s.skip_count += t.recent_skipcount;
				s.last_played = (s.last_played > (int)t.time_played) ? s.last_played : (int)t.time_played;
			}
		}
		
		/* first remove removed songs */
		current_operation = "Removing old songs from iPod and updating current ones";
		var removed = new HashMap<unowned GPod.Track, int>();
		foreach(var entry in media.entries) {
			if(!sync_cancelled) {
				if(!list.contains(entry.value)) {
					unowned GPod.Track t = entry.key;
					
					if(t != null) {
						remove_song(t);
						removed.set(t, entry.value);
					}
				}
				else if(entry.key.ipod_path == null || entry.key.ipod_path == "" || !File.new_for_path(Path.build_path("/", get_path(), GPod.iTunesDB.filename_ipod2fs(entry.key.ipod_path))).query_exists()) {
					remove_song(entry.key);
					removed.set(entry.key, entry.value);
				}
			}
			
			++sub_index;
			index = (int)(15.0 * (double)((double)sub_index/(double)songs.size));
		}
		media.unset_all(removed);
		songs.unset_all(removed);
		podcasts.unset_all(removed);
		audiobooks.unset_all(removed);
		
		// no matter where index is, set it to 1/3 now
		//index = total/4;
		
		stdout.printf("Updating existing tracks...\n");
		sub_index = 0;
		/* anything left will be synced. update songs that are already on list */
		foreach(var entry in media.entries) {
			if(!sync_cancelled) {
				Song s = lm.song_from_id(entry.value);
				
				unowned GPod.Track t = entry.key;
				s.update_track(ref t);
				
				if(lm.get_album_art(s.rowid) != null)
					t.set_thumbnails_from_pixbuf(lm.get_album_art(s.rowid));
			}
			
			index = (int)(15.0 + (double)(10.0 * (double)((double)sub_index /(double)songs.size)));
		}
		
		//index = total/2;
		
		stdout.printf("Adding new songs...\n");
		/* now add all in list that weren't in songs */
		current_operation = "Adding new songs to iPod...";
		sub_index = 0;
		int new_song_size = 0;
		foreach(var i in list) {
			if(!media.values.contains(i)) {
				new_song_size++;
			}
		}
		foreach(var i in list) {
			if(!sync_cancelled) {
				if(!media.values.contains(i)) {
					add_song(i);
					++sub_index;
				}
			}
			
			index = (int)(25.0 + (double)(50.0 * (double)((double)sub_index/(double)new_song_size)));
		}
		
		if(!sync_cancelled) {
			// sync playlists
			sync_playlists();
			sync_podcasts();
			
			current_operation = "Finishing sync process...";
			
			try {
				db.write();
			}
			catch(GLib.Error err) {
				error_occurred = true;
				sync_cancelled = true;
			}
			
			index = 98;
			
			/** Clean up unused files **/
			stdout.printf("Cleaning up iPod File System\n");
			var music_folder = File.new_for_path(GPod.Device.get_music_dir(get_path()));
			var used_paths = new LinkedList<string>();
			foreach(unowned GPod.Track t in media.keys) {
				used_paths.add(Path.build_path("/", get_path(), GPod.iTunesDB.filename_ipod2fs(t.ipod_path)));
			}
			cleanup_files(music_folder, used_paths);
			
			index = 101;
			
			db.stop_sync();
		}
		else {
			current_operation = "Cancelling Sync...";
			db.write();
			db.stop_sync();
			index = total + 1;
			sync_cancelled = false;
		}
		
		Idle.add( () => {
			LinkedList<Song> temps = new LinkedList<Song>();
			foreach(int i in media.values)
				temps.add(lm.song_from_id(i));
			
			// update songs before we set last_sync_time
			lm.update_songs(temps, false, true);
			pref.last_sync_time = (int)time_t();
			lm.save_device_preferences();
			lm.lw.searchField.changed();
			currently_syncing = false;
			
			sync_finished(!sync_cancelled);
			lm.finish_file_operations();
			
			return false;
		});
		
		return null;
	}
	
	/* Adds to track list, mpl, and copies the file over */
	void add_song(int i) {
		Song s = lm.song_from_id(i);
		GPod.Track t = s.track_from_song();
		
		if(lm.get_album_art(s.rowid) != null)
			t.set_thumbnails_from_pixbuf(lm.get_album_art(s.rowid));
		
		current_operation = "Adding song <b>" + t.title + "</b> by <b>" + t.artist + "</b> to iPod";
		stdout.printf("Adding song %s by %s\n", t.title, t.artist);
		db.track_add((owned)t, -1);
		
		unowned GPod.Track added = db.tracks.nth_data(db.tracks.length() - 1);
		
		if(added == null || added.title != s.title) {
			stdout.printf("Track was not properly appended. Returning.\n");
			return;
		}
		
		unowned GPod.Playlist mpl = db.playlist_mpl();
		mpl.add_track(added, -1);
		
		if(added.mediatype == GPod.MediaType.PODCAST) {
			unowned GPod.Playlist ppl = db.playlist_podcasts();
			ppl.add_track(added, -1);
		}
		/*else if(added.mediatype == GPod.MediaType.AUDIOBOOK) {
			unowned GPod.Playlist apl = db.playlist_audiobooks();
			apl.add_track(added, -1);
		}*/
		
		stdout.printf("copying track to ipod\n");
		if(db.cp_track_to_ipod(added, s.file)) {
			media.set(added, i);
			
			if(added.mediatype == GPod.MediaType.AUDIO)
				this.songs.set(added, i);
			else if(added.mediatype == GPod.MediaType.PODCAST)
				this.podcasts.set(added, i);
			else if(added.mediatype == GPod.MediaType.AUDIOBOOK)
				this.audiobooks.set(added, i);
		}
		else {
			stdout.printf("Failed to copy track %s to iPod. Removing it from database.\n", added.title);
			remove_song(added);
		}
		stdout.printf("copyied\n");
	}
	
	void remove_song(GPod.Track t) {
		string title = t.title;
		
		/* first delete it off disk */
		if(t.ipod_path != null) {
			var path = Path.build_path("/", get_path(), GPod.iTunesDB.filename_ipod2fs(t.ipod_path));
			var file = File.new_for_path(path);
			
			if(file.query_exists()) {
				file.delete();
				stdout.printf("Successfully removed music file %s from iPod Disk\n", path);
			}
			else {
				stdout.printf("Could not delete iPod File at %s. Unused file on iPod\n", path);
			}
		}
		
		t.remove();
		
		foreach(unowned GPod.Playlist p in db.playlists) {
			if(p.contains_track(t));
				p.remove_track(t);
		}
		
		stdout.printf("Removed song %s\n", title);
	}
	
	void cleanup_files(GLib.File music_folder, LinkedList<string> used_paths) {
		GLib.FileInfo file_info = null;
		
		try {
			var enumerator = music_folder.enumerate_children(FILE_ATTRIBUTE_STANDARD_NAME + "," + FILE_ATTRIBUTE_STANDARD_TYPE, 0);
			while ((file_info = enumerator.next_file ()) != null) {
				var file_path = Path.build_path("/", music_folder.get_path(), file_info.get_name());
				
				if(file_info.get_file_type() == GLib.FileType.REGULAR && !used_paths.contains(file_path)) { /* delete it, it's unused */
					stdout.printf("Deleting unused file %s\n", file_path);
					var file = File.new_for_path(file_path);
					file.delete();
				}
				else if(file_info.get_file_type() == GLib.FileType.REGULAR) {
					used_paths.remove(file_path);
				}
				else if(file_info.get_file_type() == GLib.FileType.DIRECTORY) {
					cleanup_files(GLib.File.new_for_path(file_path), used_paths);
				}
			}
		}
		catch(GLib.Error err) {
			stdout.printf("Could not pre-scan music folder. Progress percentage may be off: %s\n", err.message);
		}
	}
	
	public bool doProgressNotificationWithTimeout() {
		progress_notification(current_operation.replace("&", "&amp;"), (double)((double)index)/((double)total));
		
		if(index < total && is_syncing()) {
			return true;
		}
		
		return false;
	}
	
	void sync_podcasts() {
		
	}
	
	/* should be called from thread */
	// index = 75 at this point. will go to 95
	private void sync_playlists() {
		current_operation = "Syncing playlists";
		// first remove all playlists from db
		var all_playlists = new LinkedList<unowned GPod.Playlist>();
		foreach(unowned GPod.Playlist p in db.playlists) {
			if(!p.is_mpl() && !p.is_podcasts() && !p.is_audiobooks()) {
				all_playlists.add(p);
			}
		}
		foreach(unowned GPod.Playlist p in all_playlists) {
			p.remove();
		}
		index = 78;
		
		var to_sync = new LinkedList<unowned GPod.Playlist>();
		int sub_index = 0;
		foreach(var playlist in lm.playlists()) {
			GPod.Playlist p = playlist.get_gpod_playlist();
			db.playlist_add((owned)p, -1);
			
			unowned GPod.Playlist added = db.playlists.nth_data(db.playlists.length() - 1);
			foreach(var entry in songs.entries) {
				if(playlist.contains_song(entry.value)) {
					added.add_track(entry.key, -1);
					++sub_index;
					index = (int)(78.0 + (double)(7.0 * (double)((double)sub_index/(double)lm.playlists().size)));
				}
			}
		}
		index = 85;
		sub_index = 0;
		foreach(var smart_playlist in lm.smart_playlists()) {
			GPod.Playlist p = smart_playlist.get_gpod_playlist();
			
			db.playlist_add((owned)p, -1);
			unowned GPod.Playlist pl = db.playlists.nth_data(db.playlists.length() - 1);
			smart_playlist.set_playlist_properties(pl);
			
			++sub_index;
			index = (int)(85.0 + (double)(5.0 * (double)((double)sub_index/(double)lm.smart_playlists().size)));
		}
		index = 90;
		db.spl_update_live();
		index = 95;
	}
}
