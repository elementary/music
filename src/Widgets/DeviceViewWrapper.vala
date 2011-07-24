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
		
		ripper = new CDRipper(d.getUnixDevicePath(), songs.size);
		
		if(!ripper.initialize()) {
			stdout.printf("Could not create CD Ripper\n");
			return;
		}
		
		ripper.song_ripped.connect(songRipped);
		
		ripper.ripSong(1, lm.settings.getMusicFolder() + "/beatbox_temp_cd_rip_location.mp3", lm.song_from_id(songs.to_array()[0]));
	}
	
	public void songRipped(Song s) {
		// when this song was added to the library before, it was added temporarily
		// remove and re-add permanently this time
		s.file = lm.settings.getMusicFolder() + "/beatbox_temp_cd_rip_location.mp3";
		
		var temp = new LinkedList<Song>();
		temp.add(s);
		lm.remove_songs(temp);
		lm.add_songs(temp, true);
		
		// now we have to find the right location for it
		lm.fo.update_file_hierarchy(s, true);
		
		// do it again on next track
		if(s.track < ripper.track_count) {
			ripper.ripSong(s.track + 1, lm.settings.getMusicFolder() + "/beatbox_temp_cd_rip_location.mp3", lm.song_from_id(songs.to_array()[s.track]));
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
