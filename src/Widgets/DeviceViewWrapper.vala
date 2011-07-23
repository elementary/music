using Gee;

public class BeatBox.DeviceViewWrapper : ViewWrapper {
	//DeviceView dv;
	Device d;
	
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
	
	public void* prepare_cdrom_list () {
		var cdda = new CDDA();
		var songs = cdda.getSongList(d.getMountLocation());
		
		lm.add_songs(songs);
		
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
