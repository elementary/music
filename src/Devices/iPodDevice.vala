using GPod;
using Gee;

public class BeatBox.iPodDevice : GLib.Object, BeatBox.Device {
	LibraryManager lm;
	iTunesDB db;
	Mount mount;
	GLib.Icon icon;
	bool currently_syncing;
	LinkedList<int> list; // used to pass data to thread
	int index = 0;
	int total = 0;
	string current_operation;
	
	HashMap<unowned GPod.Track, int> songs;
	HashMap<unowned GPod.Track, int> podcasts;
	HashMap<unowned GPod.Playlist, int> playlists;
	HashMap<unowned GPod.Playlist, int> smart_playlists;
	
	
	public iPodDevice(LibraryManager lm, Mount mount) {
		this.lm = lm;
		this.mount = mount;
		icon = mount.get_icon();
		currently_syncing = false;
		
		index = 0;
		total = 0;
		current_operation = "";
		
		songs = new HashMap<unowned GPod.Track, int>();
		podcasts = new HashMap<unowned GPod.Track, int>();
		playlists = new HashMap<unowned GPod.Playlist, int>();
		smart_playlists = new HashMap<unowned GPod.Playlist, int>();
	}
	
	public bool initialize() {
		try {
			db = iTunesDB.parse(get_path());
		}
		catch(Error err) {
			stdout.printf("Error parsing db at %s: %s\n", get_path(), err.message);
			return false;
		}
		
		for(int i = 0; i < db.tracks.length(); ++i) {
			var s = Song.from_track(get_path(), db.tracks.nth_data(i));
			s.isTemporary = true;
			
			var existing = lm.song_from_name(s.title, s.artist);
			
			if(existing.rowid > 0) {
				this.songs.set(db.tracks.nth_data(i), existing.rowid);
			}
			else {
				lm.add_song(s, false);
				this.songs.set(db.tracks.nth_data(i), s.rowid);
			}
		}
		
		unowned GPod.Playlist podcast = db.playlist_podcasts();
		stdout.printf("there are %d podcasts\n", (int)podcast.tracks_number());
		foreach(unowned GPod.Track t in db.tracks) {
			if(t.podcasturl != null && t.podcasturl.length > 5) {
				stdout.printf("found podcast\n");
				podcasts.set(t, songs.get(t));
				songs.unset(t);
			}
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
		
		device_unmounted.connect( () => {
			foreach(int i in songs.values) {
				Song s = lm.song_from_id(i);
				s.unique_status_image = null;
				lm.update_song(s, false);
			}
		});
		
		return true;
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
		return mount.get_name();
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
	
	public Collection<int> get_songs() {
		return songs.values;
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
		
		bool fits = will_fit(list);
		if(!fits) {
			stdout.printf("Tried to sync songs that will not fit\n");
			return false;
		}
		
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
	
	public bool will_fit(LinkedList<int> list) {
		uint64 list_size = 0;
		foreach(int i in list) {
			list_size += lm.song_from_id(i).file_size * 1000000; // convert from MB to bytes
		}
		
		stdout.printf("comparing %d to %d\n", (int)get_free_space(), (int)list_size);
		return get_free_space() > list_size;
	}
	
	void* sync_songs_thread() {
		currently_syncing = true;
		db.start_sync();
		
		index = 0;
		
		total = songs.entries.size + songs.entries.size + list.size + 10;
		Timeout.add(500, doProgressNotificationWithTimeout);
		
		/* first remove removed songs */
		current_operation = "Removing old songs from iPod and updating current ones";
		var removed = new HashMap<unowned GPod.Track, int>();
		foreach(var entry in songs.entries) {
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
			++index;
		}
		songs.unset_all(removed);
		
		// no matter where index is, set it to 1/3 now
		//index = total/4;
		
		stdout.printf("Updating existing tracks...\n");
		/* anything left will be synced. update songs that are already on list */
		foreach(var entry in songs.entries) {
			Song s = lm.song_from_id(entry.value);
			stdout.printf("Updating %s\n", s.title);
			unowned GPod.Track t = entry.key;
			s.update_track(ref t);
			
			t.set_thumbnails_from_pixbuf(lm.get_album_art(s.rowid));
			
			++index;
		}
		
		//index = total/2;
		
		stdout.printf("Adding new songs...\n");
		/* now add all in list that weren't in songs */
		current_operation = "Adding new songs to iPod...";
		foreach(var i in list) {
			if(!songs.values.contains(i)) {
				add_song(i);
			}
			
			++index;
		}
		
		// sync playlists
		sync_playlists();
		
		index += 3;
		
		current_operation = "Finishing sync process...";
		db.write();
		
		index += 3;
		
		/** Clean up unused files **/
		stdout.printf("Cleaning up iPod File System\n");
		var music_folder = File.new_for_path(GPod.Device.get_music_dir(get_path()));
		var used_paths = new LinkedList<string>();
		foreach(unowned GPod.Track t in songs.keys) {
			used_paths.add(Path.build_path("/", get_path(), GPod.iTunesDB.filename_ipod2fs(t.ipod_path)));
		}
		cleanup_files(music_folder, used_paths);
		
		index = total + 3;
		
		db.stop_sync();
		currently_syncing = false;
		
		Idle.add( () => {
			lm.lw.topDisplay.show_scale();
			lm.lw.updateInfoLabel();
			lm.lw.searchField.changed();
			
			return false;
		});
		
		return null;
	}
	
	/* Adds to track list, mpl, and copies the file over */
	void add_song(int i) {
		Song s = lm.song_from_id(i);
		GPod.Track t = s.track_from_song();
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
		
		if(db.cp_track_to_ipod(added, s.file)) {
			songs.set(added, i);
		}
		else {
			stdout.printf("Failed to copy track %s to iPod. Removing it from database.\n", added.title);
			remove_song(added);
		}
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
	
	/* should be called from thread */
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
			stdout.printf("removed playlist %s\n", p.name);
			p.remove();
		}
		
		var to_sync = new LinkedList<unowned GPod.Playlist>();
		foreach(var playlist in lm.playlists()) {
			GPod.Playlist p = playlist.get_gpod_playlist();
			db.playlist_add((owned)p, -1);
			
			unowned GPod.Playlist added = db.playlists.nth_data(db.playlists.length() - 1);
			stdout.printf("added playlist %s\n", added.name);
			foreach(var entry in songs.entries) {
				if(playlist.contains_song(entry.value)) {
					added.add_track(entry.key, -1);
				}
			}
		}
		foreach(var smart_playlist in lm.smart_playlists()) {
			GPod.Playlist p = smart_playlist.get_gpod_playlist();
			
			stdout.printf("created playlist and it has %d rules\n", (int)p.splrules.rules.length());
			
			db.playlist_add((owned)p, -1);
			unowned GPod.Playlist pl = db.playlists.nth_data(db.playlists.length() - 1);
			
			// remove the pre-added rule that libgpod already adds
			//unowned GPod.SPLRule stupidRule = pl.splrules.rules.nth_data(0);
			//pl.splr_remove(stupidRule);
			
			stdout.printf("pre-added playlist and it has %d rules\n", (int)pl.splrules.rules.length());
			
			smart_playlist.set_playlist_properties(pl);
			
			stdout.printf("added playlist and it has %d rules\n", (int)pl.splrules.rules.length());
		}
		
		db.spl_update_all();
		
		foreach(unowned GPod.Playlist p in db.playlists) {
			if(p.is_spl) {
				stdout.printf("found spl named %s. has %d rules with %d liveupdate\n", p.name, (int)p.splrules.rules.length(), (int)p.splpref.liveupdate);
				
				foreach(unowned GPod.SPLRule? r in p.splrules.rules) {
					stdout.printf("found a rule with field %d and action %d\n", (int)r.field, (int)r.action);
					if(r.@string == null)
						stdout.printf("@string is null\n");
					else
						stdout.printf("@string is %s\n", r.@string);
					//stdout.printf("playlist %Lu has rule %Lu and string %s\n", r.field, r.action, (r.@string != null) ? r.@string : "(is null)");
				}
			}
		}
	}
}
