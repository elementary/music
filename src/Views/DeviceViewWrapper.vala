using Gee;

public class BeatBox.CDRomViewWrapper : ViewWrapper {
	//DeviceView dv;
	Device d;
	bool cancelled;
	
	public CDRomViewWrapper(LibraryManager lmm, LibraryWindow lww, Collection<int> songs, string sort, Gtk.SortType dir, MusicTreeView.Hint the_hint, int id, Device d) {
		base(lmm, lww, songs, sort, dir, the_hint, id);
		this.d = d;
		cancelled = false;
		
		ulong connector = lm.progress_cancel_clicked.connect( () => { 
			cancelled = true;
			lw.doAlert("Cancelling Import", "CD Import has been cancelled. Importing will stop after this song.");
		});
		d.device_unmounted.connect( () => {
			d.disconnect(connector);
		});
	}
	
	
	public bool pulser() {
		if(song_being_ripped != null) {
			song_being_ripped.pulseProgress++;
			
			var updated = new LinkedList<int>();
			updated.add(song_being_ripped.rowid);
			list.songs_updated(updated);
			
			return true;
		}
		else {
			return false;
		}
	}
}
