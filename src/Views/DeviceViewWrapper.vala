using Gee;

public class BeatBox.DeviceViewWrapper : ViewWrapper {
	//DeviceView dv;
	Device d;
	CDRipper ripper;
	
	bool cancelled;
	
	public DeviceViewWrapper(LibraryManager lmm, LibraryWindow lww, Collection<int> songs, string sort, Gtk.SortType dir, MusicTreeView.Hint the_hint, int id, Device d) {
		base(lmm, lww, songs, sort, dir, the_hint, id);
		this.d = d;
		cancelled = false;
		
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
		
		if(lm.doing_file_operations) {
			lw.doAlert("BeatBox is already doing an import", "Please wait until BeatBox is finished with the current import before importing the CD.");
			return;
		}
		
		ripper = new CDRipper(d.getMountLocation(), songs.size);
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
		
		s.unique_status_image = render_icon(Gtk.Stock.NO, Gtk.IconSize.MENU, null);
		lm.update_song(s, false);
		
		ripper.ripSong(1, lm.settings.getMusicFolder() + "/beatbox_temp_cd_rip_location.mp3", s);
		
		var update = "Ripping track 1: <b>" + s.title.replace("&", "&amp;") + "</b>" + ((s.artist != "Unknown Artist") ? " by " : "") + "<b>" + s.artist.replace("&", "&amp;") + "</b>" + ((s.album != "Unknown Album") ? " on " : "") + "<b>" + s.album.replace("&", "&amp;") + "</b>";
		lw.progressNotification(update, 0.0);
		
		
		lm.doing_file_operations = true;
		lw.updateSensitivities();
	}
	
	public void songRipped(Song s) {
		// when this song was added to the library before, it was added temporarily
		// remove and re-add permanently this time
		stdout.printf("sR0\n");
		s.file = lm.settings.getMusicFolder() + "/beatbox_temp_cd_rip_location.mp3";
		
		// set the song's date_added and file size
		s.date_added = (int)time_t();
		s.file_size = (int)(GLib.File.new_for_path(s.file).query_info("*", FileQueryInfoFlags.NONE).get_size()/1000000);
		s.isTemporary = false;
		
		// then save the metadata to the file
		var temp = new LinkedList<Song>();
		temp.add(s);
		
		lm.add_songs(temp, true);
		
		// now we have to find the right location for it
		lm.fo.update_file_hierarchy(s, true);
		
		stdout.printf("sR2\n");
		// now we have to find the right location for it
		stdout.printf("sR3\n");
		s.unique_status_image = render_icon(Gtk.Stock.OK, Gtk.IconSize.MENU, null);
		stdout.printf("sR4\n");
		// do it again on next track
		if(s.track < ripper.track_count && !cancelled) {
			Song next = lm.song_from_id(songs.to_array()[s.track]);
			ripper.ripSong(next.track, lm.settings.getMusicFolder() + "/beatbox_temp_cd_rip_location.mp3", next);
			stdout.printf("sR5\n");
			next.unique_status_image = render_icon(Gtk.Stock.NO, Gtk.IconSize.MENU, null);
			lm.update_song(next, false);
			stdout.printf("sR6\n");
			var update = "<b>Importing</b> track " + next.track.to_string() + ": <b>" + next.title.replace("&", "&amp;") + "</b>" + ((next.artist != "Unknown Artist") ? " by " : "") + "<b>" + next.artist.replace("&", "&amp;") + "</b>" + ((next.album != "Unknown Album") ? " on " : "") + "<b>" + next.album.replace("&", "&amp;") + "</b>";
			lw.progressNotification(update, 0.0);
		}
		else {
			lm.doing_file_operations = false;
			
			if(lm.song_info.song != null) {
				var song_label = "<b>" + lm.song_info.song.title.replace("&", "&amp;") + "</b>" + ((lm.song_info.song.artist != "") ? " by " : "") + "<b>" + lm.song_info.song.artist.replace("&", "&amp;") + "</b>" + ((lm.song_info.song.album != "") ? " on " : "") + "<b>" + lm.song_info.song.album.replace("&", "&amp;") + "</b>";
				lw.topDisplay.set_label_markup(song_label);
			}
			
			lw.updateSensitivities();
			
			/* Show notification that song ripping has finished */
			// TODO: ..^
		}
	}
	
	public void* prepare_cdrom_list () {
		var songs = CDDA.getSongList(d.getMountLocation());
		
		lm.add_songs(songs, false);
		
		var ids = new LinkedList<int>();
		foreach(var s in songs)
			ids.add(s.rowid);
			
		d.device_unmounted.connect( () => {
			foreach(Song s in songs) {
				s.unique_status_image = null;
				lm.update_songs(songs, false);
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
				}
		}
	}
}
