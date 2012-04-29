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

using GPod;
using Gee;

public class BeatBox.iPodDevice : GLib.Object, BeatBox.Device {
	LibraryManager lm;
	DevicePreferences pref;
	iTunesDB db;
	Mount mount;
	GLib.Icon icon;
	bool currently_syncing;
	bool currently_transferring;
	bool sync_cancelled;
	bool transfer_cancelled;
	LinkedList<int> list; // used to pass data to thread
	int index = 0;
	int total = 0;
	string current_operation;
	
	HashMap<unowned GPod.Track, int> medias;
	HashMap<unowned GPod.Track, int> songs;
	HashMap<unowned GPod.Track, int> podcasts;
	HashMap<unowned GPod.Track, int> audiobooks;
	HashMap<unowned GPod.Playlist, int> playlists;
	HashMap<unowned GPod.Playlist, int> smart_playlists;
	
	HashMap<Media, unowned GPod.Track> to_add; // used to add all new songs at the end when idle
	
	public iPodDevice(LibraryManager givedlm, Mount mount) {
		this.lm = givedlm;
		this.mount = mount;
		
		pref = lm.device_manager.get_device_preferences(get_unique_identifier());
		if(pref == null) {
			pref = new DevicePreferences(get_unique_identifier());
			lm.device_manager.add_device_preferences(pref);
		}
		
		icon = mount.get_icon();
		currently_syncing = false;
		currently_transferring = false;
		sync_cancelled = false;
		transfer_cancelled = false;
		
		index = 0;
		total = 0;
		current_operation = "";
		
		medias = new HashMap<unowned GPod.Track, int>();
		songs = new HashMap<unowned GPod.Track, int>();
		podcasts = new HashMap<unowned GPod.Track, int>();
		audiobooks = new HashMap<unowned GPod.Track, int>();
		playlists = new HashMap<unowned GPod.Playlist, int>();
		smart_playlists = new HashMap<unowned GPod.Playlist, int>();
		to_add = new HashMap<Media, unowned GPod.Track>();
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
		var all = new LinkedList<Media>();
		
		// get all songs first
		for(int i = 0; i < db.tracks.length(); ++i) {
			unowned GPod.Track t = db.tracks.nth_data(i);
			//stdout.printf("found track and rating is %d and app rating %d and id is %d\n", (int)db.tracks.nth_data(i).rating, (int)db.tracks.nth_data(i).app_rating, (int)db.tracks.nth_data(i).id);
			var s = Media.from_track(get_path(), t);
			
			all.add(s);
		}
		
		lm.add_medias(all, false);
		
		// set hashmaps
		for(int i = 0; i < db.tracks.length(); ++i) {
			unowned GPod.Track t = db.tracks.nth_data(i);
			
			int match = 0;
			foreach(var m in all) {
				if(m.title.down() == t.title.down() && m.artist.down() == t.artist.down()) {
					match = m.rowid;
					break;
				}
			}
			
			if(match != 0) {
				this.medias.set(t, match);
				if(t.mediatype == GPod.MediaType.AUDIO)
					this.songs.set(t, match);
				else if(t.mediatype == GPod.MediaType.PODCAST || t.mediatype == 0x00000006) // 0x00000006 = video podcast
					this.podcasts.set(t, match);
				else if(t.mediatype == GPod.MediaType.AUDIOBOOK)
					this.audiobooks.set(t, match);
					
				all.remove(lm.media_from_id(match));
			}
			else {
				stdout.printf("wtf no match man\n");
			}
		}
		
		//lock(lm._medias) {
			//lm.add_medias(trToSo, false);
		//}
		/*
		for(int i = 0; i < db.playlists.length(); ++i) {
			unowned GPod.Playlist p = db.playlists.nth_data(i);
			
			if(!p.is_spl) {
				Playlist bbPlaylist = Playlist.from_ipod(p);
				
				foreach(unowned GPod.Track t in medias.keys) {
					if(p.contains_track(t)) {
						bbPlaylist.addMedia(medias.get(t));
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
		uint64 rv = 0;
		
		try {
			var file_info = File.new_for_path(get_path()).query_filesystem_info("filesystem::*", null);
			rv = file_info.get_attribute_uint64(GLib.FileAttribute.FILESYSTEM_SIZE);
		}
		catch(Error err) {
			stdout.printf("Error calculating capacity of iPod: %s\n", err.message);
		}
		
		return rv;
	}
	
	public string get_fancy_capacity() {
		return "Unknown Capacity";//db.device.get_ipod_info().capacity.to_string() + "GB";
	}
	
	public uint64 get_used_space() {
		return get_capacity() - get_free_space();
	}
	
	public uint64 get_free_space() {
		uint64 rv = 0;
		
		try {
			var file_info = File.new_for_path(get_path()).query_filesystem_info("filesystem::*", null);
			rv = file_info.get_attribute_uint64(GLib.FileAttribute.FILESYSTEM_FREE);
		}
		catch(Error err) {
			stdout.printf("Error calculating free space on iPod: %s\n", err.message);
		}
		
		return rv;
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
	
	public Collection<int> get_medias() {
		return medias.values;
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
	
	public bool sync_medias(LinkedList<int> list) {
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
			stdout.printf("Tried to sync medias that will not fit\n");
			return false;
		}
		
		lm.start_file_operations("Syncing <b>" + getDisplayName() + "</b>...");
		current_operation = "Syncing <b>" + getDisplayName() + "</b>...";
		lm.lw.update_sensitivities();
		to_add = new HashMap<Media, unowned GPod.Track>();
		this.list = list;
		
		try {
			Thread.create<void*>(sync_medias_thread, false);
		}
		catch(GLib.ThreadError err) {
			stdout.printf("ERROR: Could not create thread to sync medias: %s \n", err.message);
			return false;
		}
		
		return true;
	}
	
	public bool is_syncing() {
		return currently_syncing;
	}
	
	public bool is_transferring() {
		return currently_transferring;
	}
	
	public void cancel_sync() {
		sync_cancelled = true;
	}
	
	public void cancel_transfer() {
		transfer_cancelled = true;
	}
	
	public bool will_fit(LinkedList<int> list) {
		uint64 list_size = 0;
		foreach(int i in list) {
			list_size += lm.media_from_id(i).file_size * 1000000; // convert from MB to bytes
		}
		
		return get_capacity() > list_size;
	}
	
	void* sync_medias_thread() {
		currently_syncing = true;
		bool error_occurred = false;
		index = 0;
		int sub_index = 0;
		total = 100;
		Timeout.add(500, doProgressNotificationWithTimeout);
		
		db.start_sync();
		
		// for each song that is on device, but not in this.list, remove
		current_operation = "Removing old medias from iPod and updating current ones";
		var removed = new HashMap<unowned GPod.Track, int>();
		foreach(var e in medias.entries) {
			if(!sync_cancelled) {
				int match = lm.match_media_to_list(e.value, list);
				
				if(match == 0) {
					unowned GPod.Track t = e.key;
					
					if(t != null) {
						remove_media(t);
						removed.set(t, e.value);
					}
				}
			}
			
			++sub_index;
			index = (int)(15.0 * (double)((double)sub_index/(double)medias.size));
		}
		medias.unset_all(removed);
		songs.unset_all(removed);
		podcasts.unset_all(removed);
		audiobooks.unset_all(removed);
		
		stdout.printf("Updating existing tracks...\n");
		sub_index = 0;
		// anything left will be synced. update medias that are already on list
		foreach(var entry in medias.entries) {
			if(!sync_cancelled) {
				int i = lm.match_media_to_list(entry.value, this.list);
				if(i != 0) {
					Media m = lm.media_from_id(i);
					
					unowned GPod.Track t = entry.key;
					m.update_track(ref t);
					stdout.printf("updated trac and its rating is %d\n", (int)t.rating);
					
					var pix_from_file = lm.get_album_art_from_file(m.rowid);
					if(pix_from_file != null)
						t.set_thumbnails_from_pixbuf(pix_from_file);
				}
				else {
					stdout.printf("Could not update %s, no match in sync list\n", entry.key.title);
				}
			}
			
			index = (int)(15.0 + (double)(10.0 * (double)((double)sub_index /(double)medias.size)));
		}
		
		stdout.printf("Adding new medias...\n");
		// now add all in list that weren't in medias
		current_operation = "Adding new medias to iPod...";
		sub_index = 0;
		int new_media_size = 0;
		foreach(var i in list) {
			int match = lm.match_media_to_list(i, medias.values);
			if(match == 0) {
				new_media_size++;
			}
		}
		foreach(var i in list) {
			if(!sync_cancelled) {
				int match = lm.match_media_to_list(i, medias.values);
				if(match == 0) {
					add_media(i);
					++sub_index;
				}
			}
			
			index = (int)(25.0 + (double)(50.0 * (double)((double)sub_index/(double)new_media_size)));
		}
		
		stdout.printf("finished adding\n");
		
		if(!sync_cancelled) {
			// sync playlists
			index = 78;
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
			foreach(unowned GPod.Track t in medias.keys) {
				used_paths.add(Path.build_path("/", get_path(), GPod.iTunesDB.filename_ipod2fs(t.ipod_path)));
			}
			foreach(unowned GPod.Track t in to_add.values) {
				used_paths.add(Path.build_path("/", get_path(), GPod.iTunesDB.filename_ipod2fs(t.ipod_path)));
			}
			cleanup_files(music_folder, used_paths);
			
			index = 101;
			
			db.stop_sync();
		}
		else {
			current_operation = "Cancelling Sync...";
			try {
				db.write();
			}
			catch(Error err) {
				critical("Error when writing iPod database. iPod contents may be incorrect: %s\n", err.message);
			}
			db.stop_sync();
			index = total + 1;
			sync_cancelled = false;
		}
		
		Idle.add( () => {
			lm.add_medias(to_add.keys, false);
			foreach(var e in to_add.entries) {
				unowned GPod.Track added = e.value;
				var on_ipod = e.key;
				medias.set(added, on_ipod.rowid);
				if(added.mediatype == GPod.MediaType.AUDIO)
					this.songs.set(added, on_ipod.rowid);
				else if(added.mediatype == GPod.MediaType.PODCAST)
					this.podcasts.set(added, on_ipod.rowid);
				else if(added.mediatype == GPod.MediaType.AUDIOBOOK)
					this.audiobooks.set(added, on_ipod.rowid);
			}
			
			LinkedList<Media> temps = new LinkedList<Media>();
			foreach(int i in medias.values)
				temps.add(lm.media_from_id(i));
			
			// update medias before we set last_sync_time
			lm.update_medias(temps, false, true);
			pref.last_sync_time = (int)time_t();
			currently_syncing = false;
			
			sync_finished(!sync_cancelled);
			lm.finish_file_operations();
			
			return false;
		});
		
		return null;
	}
	
	/* Adds to track list, mpl, and copies the file over */
	void add_media(int i) {
		Media s = lm.media_from_id(i);
		GPod.Track t = s.track_from_media();
		
		var pix_from_file = lm.get_album_art_from_file(s.rowid);
		if(pix_from_file != null)
			t.set_thumbnails_from_pixbuf(pix_from_file);
		
		current_operation = "Adding media <b>" + t.title + "</b> by <b>" + t.artist + "</b> to iPod";
		stdout.printf("Adding media %s by %s\n", t.title, t.artist);
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
		bool success = false;
		try {
			success = db.cp_track_to_ipod(added, File.new_for_uri(s.uri).get_path());
		}
		catch(Error err) {
			stdout.printf("Error adding/copying song %s to iPod: %s\n", s.title, err.message);
		}
		
		if(success) {
			Media on_ipod = Media.from_track(get_path(), added);
			to_add.set(on_ipod, added);
		}
		else {
			stdout.printf("Failed to copy track %s to iPod. Removing it from database.\n", added.title);
			remove_media(added);
		}
		stdout.printf("copyied\n");
	}
	
	void remove_media(GPod.Track t) {
		string title = t.title;
		
		/* first delete it off disk */
		if(t.ipod_path != null) {
			var path = Path.build_path("/", get_path(), GPod.iTunesDB.filename_ipod2fs(t.ipod_path));
			var file = File.new_for_path(path);
			
			if(file.query_exists()) {
				try {
					file.delete();
					stdout.printf("Successfully removed music file %s from iPod Disk\n", path);
				}
				catch(Error err) {
					stdout.printf("Could not delete iPod File at %s. Unused file will remain on iPod: %s\n", path, err.message);
				}
			}
			else {
				stdout.printf("File not found, could not delete iPod File at %s. File may already be deletedd\n", path);
			}
		}
		
		t.remove();
		
		foreach(unowned GPod.Playlist p in db.playlists) {
			if(p.contains_track(t));
				p.remove_track(t);
		}
		
		stdout.printf("Removed media %s\n", title);
	}
	
	void cleanup_files(GLib.File music_folder, LinkedList<string> used_paths) {
		GLib.FileInfo file_info = null;
		
		try {
			var enumerator = music_folder.enumerate_children(FileAttribute.STANDARD_NAME + "," + FileAttribute.STANDARD_TYPE, 0);
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
		
		if(index < total && (is_syncing() || is_transferring())) {
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
		
		int sub_index = 0;
		foreach(var playlist in lm.playlists()) {
			GPod.Playlist p = playlist.get_gpod_playlist();
			db.playlist_add((owned)p, -1);
			
			unowned GPod.Playlist added = db.playlists.nth_data(db.playlists.length() - 1);
			foreach(var entry in medias.entries) {
				int match = lm.match_media_to_list(entry.value, lm.medias_from_playlist(playlist.rowid));
				if(match != 0) {
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
	
	public bool transfer_to_library(LinkedList<int> list) {
		if(currently_transferring) {
			stdout.printf("Tried to sync when already syncing\n");
			return false;
		}
		else if(lm.doing_file_operations()) {
			stdout.printf("Can't sync. Already doing file operations\n");
			return false;
		}
		
		lm.start_file_operations("Importing <b>" + ((list.size > 1) ? list.size.to_string() : (lm.media_from_id(list.get(0)).title)) + "</b> to library...");
		current_operation = "Importing <b>" + ((list.size > 1) ? list.size.to_string() : (lm.media_from_id(list.get(0)).title)) + "</b> items to library...";
		this.list = list;
		
		try {
			Thread.create<void*>(transfer_medias_thread, false);
		}
		catch(GLib.ThreadError err) {
			stdout.printf("ERROR: Could not create thread to transfer medias: %s \n", err.message);
			return false;
		}
		
		return true;
	}
	
	void* transfer_medias_thread() {
		if(this.list == null || this.list.size == 0)
			return null;
		
		currently_transferring = true;
		transfer_cancelled = false;
		index = 0;
		total = list.size;
		Timeout.add(500, doProgressNotificationWithTimeout);
		
		foreach(var i in list) {
			if(transfer_cancelled)
				break;
			
			Media temp = lm.media_from_id(i);
			if(File.new_for_uri(temp.uri).query_exists() && temp.isTemporary) {
				Media s = temp.copy();
				s.rowid = 0;
				s.isTemporary = false;
				s.date_added = (int)time_t();
				lm.add_media(s, true);
				
				current_operation = "Importing <b>" + s.title + "</b> to library";
				lm.fo.update_file_hierarchy(s, false, false);
			}
			else {
				stdout.printf("Skipped transferring media %s. Either already in library, or has invalid file path to ipod.\n", temp.title);
			}
			
			++index;
		}
		
		index = total + 1;
		
		Idle.add( () => {
			lm.finish_file_operations();
			currently_transferring = false;
			
			return false;
		});
		
		return null;
	}
}
