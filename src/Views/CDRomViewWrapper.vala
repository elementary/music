using Gee;

public class BeatBox.CDRomViewWrapper : ViewWrapper {
	//DeviceView dv;
	Device d;
	CDRipper ripper;
	
	Song song_being_ripped;
	Song previous_song;
	
	bool cancelled;
	
	public CDRomViewWrapper(LibraryManager lmm, LibraryWindow lww, Collection<int> songs, string sort, Gtk.SortType dir, ViewWrapper.Hint the_hint, int id, Device d) {
		base(lmm, lww, songs, sort, dir, the_hint, id);
		this.d = d;
		cancelled = false;
		
		song_being_ripped = null;
		previous_song = null;
		
		// in thread get song list
		try {
			if(d.getContentType() == "cdrom")
				Thread.create<void*>(prepare_cdrom_list, false);
		}
		catch(GLib.ThreadError err) {
			stdout.printf("ERROR: Could not create cdrom thread: %s \n", err.message);
		}
		
		ulong connector = lm.progress_cancel_clicked.connect( () => { 
			cancelled = true;
			lw.doAlert("Cancelling Import", "CD Import has been cancelled. Importing will stop after this song.");
		});
		d.device_unmounted.connect( () => {
			d.disconnect(connector);
		});
	}
	
	public void ripSongs() {
		if(d.getContentType() != "cdrom")
			return;
			
		if(!GLib.File.new_for_path(lm.settings.getMusicFolder()).query_exists()) {
			lw.doAlert("Could not find Music Folder", "Please make sure that your music folder is accessible and mounted before importing the CD.");
			return;
		}
		
		if(lm.doing_file_operations()) {
			lw.doAlert("BeatBox is already doing an import", "Please wait until BeatBox is finished with the current import before importing the CD.");
			return;
		}
		
		ripper = new CDRipper(d.get_path(), songs.size);
		cancelled = false;
		ripper.progress_notification.connect( (progress) => {
			
			lw.progressNotification(null, progress);
			
		});
		
		if(!ripper.initialize()) {
			stdout.printf("Could not create CD Ripper\n");
			return;
		}
		
		ripper.song_ripped.connect(songRipped);
		ripper.error.connect(ripperError);
		
		Song s = lm.song_from_id(songs.to_array()[0]);
		song_being_ripped = s;
		
		s.showIndicator = true;
		lm.update_song(s, false, false);
		
		ripper.ripSong(1, lm.settings.getMusicFolder() + "/beatbox_temp_cd_rip_location.mp3", s);
		
		var update = "Ripping track 1: <b>" + s.title.replace("&", "&amp;") + "</b>" + ((s.artist != "Unknown Artist") ? " by " : "") + "<b>" + s.artist.replace("&", "&amp;") + "</b>" + ((s.album != "Unknown Album") ? " on " : "") + "<b>" + s.album.replace("&", "&amp;") + "</b>";
		lm.start_file_operations(update);
		lw.updateSensitivities();
		
		// this refreshes so that the spinner shows
		doUpdate(currentView, songs, true, true);
		
		// this spins the spinner for the current song being imported
		Timeout.add(100, pulser);
	}
	
	public bool pulser() {
		if(song_being_ripped != null) {
			song_being_ripped.pulseProgress++;
			
			var updated = new LinkedList<int>();
			updated.add(song_being_ripped.rowid);
			list.update_songs(updated);
			
			return true;
		}
		else {
			return false;
		}
	}
	
	public void songRipped(Song s) {
		// when this song was added to the library before, it was added temporarily
		// remove and re-add permanently this time
		s.file = lm.settings.getMusicFolder() + "/beatbox_temp_cd_rip_location.mp3";
		
		// set the song's date_added and file size
		s.date_added = (int)time_t();
		
		if(GLib.File.new_for_path(s.file).query_exists()) {
			try {
				s.file_size = (int)(GLib.File.new_for_path(s.file).query_info("*", FileQueryInfoFlags.NONE).get_size()/1000000);
			}
			catch(Error err) {
				s.file_size = 5; // best guess
				stdout.printf("Could not ripped song's file_size: %s\n", err.message);
			}
		}
		else {
			s.file_size = 5; // best guess
		}
		
		s.isTemporary = false;
		s.showIndicator = false;
		
		// then save the metadata to the file
		var temp = new LinkedList<Song>();
		temp.add(s);
		lm.add_songs(temp, true);
		
		// now we have to find the right location for it
		previous_song = s.copy();
		lm.fo.update_file_hierarchy(s, true, false);
		/*try {
			Thread.create<void*>(update_file_location_thread, false);
		}
		catch(GLib.ThreadError err) {
			stdout.printf("ERROR: Could not create thread to move the song: %s \n", err.message);
			
			if(previous_song != null)
				lm.fo.update_file_hierarchy(previous_song, true);
		}*/
		
		// now we have to find the right location for it
		s.unique_status_image = render_icon("process-completed-symbolic", Gtk.IconSize.MENU, null);
		// do it again on next track
		if(s.track < ripper.track_count && !cancelled) {
			Song next = lm.song_from_id(songs.to_array()[s.track]);
			song_being_ripped = next;
			ripper.ripSong(next.track, lm.settings.getMusicFolder() + "/beatbox_temp_cd_rip_location.mp3", next);
			
			next.showIndicator = true;
			lm.update_song(next, false, false);
			
			var update = "<b>Importing</b> track " + next.track.to_string() + ": <b>" + next.title.replace("&", "&amp;") + "</b>" + ((next.artist != "Unknown Artist") ? " by " : "") + "<b>" + next.artist.replace("&", "&amp;") + "</b>" + ((next.album != "Unknown Album") ? " on " : "") + "<b>" + next.album.replace("&", "&amp;") + "</b>";
			lw.progressNotification(update, 0.0);
		}
		else {
			song_being_ripped = null;
			
			lm.finish_file_operations();
			
			/* Show notification that song ripping has finished */
			// TODO: ..^
		}
	}
	
	public void* update_file_location_thread() {
		if(previous_song != null)
			lm.fo.update_file_hierarchy(previous_song, true, false);
		
		return null;
	}
	
	public void* prepare_cdrom_list () {
		var tSongs = CDDA.getSongList(d.get_path());
		
		lm.add_songs(tSongs, false);
		
		var ids = new LinkedList<int>();
		foreach(var s in tSongs)
			ids.add(s.rowid);
			
		d.device_unmounted.connect( () => {
			foreach(Song s in tSongs) {
				s.unique_status_image = null;
				lm.update_songs(tSongs, false, false);
			}
		});
		
		Idle.add( () => {
			doUpdate(currentView, ids, true, true);
			
			return false;
		});
		
		return null;
	}
	
	public void ripperError(string err, Gst.Message message) {
		if(err == "missing element") {
			if(message.get_structure() != null && Gst.is_missing_plugin_message(message)) {
					InstallGstreamerPluginsDialog dialog = new InstallGstreamerPluginsDialog(lm, lw, message);
					dialog.show();
				}
		}
	}
}
