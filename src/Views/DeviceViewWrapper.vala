using Gee;

public class BeatBox.DeviceViewWrapper : ViewWrapper {
	//DeviceView dv;
	Device d;
	CDRipper ripper;
	
	public DeviceViewWrapper(LibraryManager lmm, LibraryWindow lww, Collection<int> songs, string sort, Gtk.SortType dir, MusicTreeView.Hint the_hint, int id, Device d) {
		base(lmm, lww, songs, sort, dir, the_hint, id);
		this.d = d;
		
		// in thread get song list
		try {
			if(d.getContentType() == "cdrom")
				Thread.create<void*>(prepare_cdrom_list, false);
		}
		catch(GLib.ThreadError err) {
			stdout.printf("ERROR: Could not create cdrom thread: %s \n", err.message);
		}
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
		
		ripper = new CDRipper(d.getUnixDevicePath(), songs.size);
		ripper.progress_notification.connect( (progress) => {
			
			lw.progressNotification(null, progress);
			
		});
		
		if(!ripper.initialize()) {
			stdout.printf("Could not create CD Ripper\n");
			return;
		}
		
		ripper.song_ripped.connect(songRipped);
		
		Song s = lm.song_from_id(songs.to_array()[0]);
		
		ripper.ripSong(1, lm.settings.getMusicFolder() + "/beatbox_temp_cd_rip_location.mp3", s);
		
		var update = "Ripping track 1: <b>" + s.title.replace("&", "&amp;") + "</b>" + ((s.artist != "Unknown Artist") ? " by " : "") + "<b>" + s.artist.replace("&", "&amp;") + "</b>" + ((s.album != "Unknown Album") ? " on " : "") + "<b>" + s.album.replace("&", "&amp;") + "</b>";
		lw.progressNotification(update, 0.0);
		
		lm.doing_file_operations = true;
		lw.updateSensitivities();
	}
	
	public void songRipped(Song s) {
		// when this song was added to the library before, it was added temporarily
		// remove and re-add permanently this time
		s.file = lm.settings.getMusicFolder() + "/beatbox_temp_cd_rip_location.mp3";
		
		var temp = new LinkedList<Song>();
		temp.add(s);
		//lm.remove_songs(temp);
		lm.add_songs(temp, true);
		
		// now we have to find the right location for it
		lm.fo.update_file_hierarchy(s, true);
		
		// do it again on next track
		if(s.track < ripper.track_count) {
			Song next = lm.song_from_id(songs.to_array()[s.track]);
			ripper.ripSong(next.track, lm.settings.getMusicFolder() + "/beatbox_temp_cd_rip_location.mp3", next);
			
			var update = "<b>Importing</b> track " + next.track.to_string() + ": <b>" + next.title.replace("&", "&amp;") + "</b>" + ((next.artist != "Unknown Artist") ? " by " : "") + "<b>" + next.artist.replace("&", "&amp;") + "</b>" + ((next.album != "Unknown Album") ? " on " : "") + "<b>" + next.album.replace("&", "&amp;") + "</b>";
			lw.progressNotification(update, 0.0);
		}
		else {
			lm.doing_file_operations = false;
			lw.updateSensitivities();
		}
	}
	
	public void* prepare_cdrom_list () {
		var songs = CDDA.getSongList(d.getMountLocation());
		
		lm.add_songs(songs, false);
		
		var ids = new LinkedList<int>();
		foreach(var s in songs)
			ids.add(s.rowid);
		
		Idle.add( () => {
			doUpdate(currentView, ids, true);
			
			return false;
		});
		
		return null;
	}
}
