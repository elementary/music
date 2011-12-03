using Gee;

public class BeatBox.DeviceViewWrapper : ViewWrapper {
	Device d;
	bool cancelled;
	
	public DeviceViewWrapper(LibraryManager lmm, LibraryWindow lww, Collection<int> songs, string sort, Gtk.SortType dir, MusicTreeView.Hint the_hint, int id, Device d) {
		the_hint = MusicTreeView.Hint.DEVICE;
		base(lmm, lww, songs, sort, dir, the_hint, id);
		
		list.hide();
		albumView.hide();
		
		//dbar.option_changed.connect(devicebar_changed);
		
		
		this.d = d;
	}
	
	/*void devicebar_changed(int option) {
		stdout.printf("option is %d\n", option);
		if(option == 0) {
			dsw.show();
			list.hide();
			albumView.hide();
		}
		else {
			dsw.hide();
			
			if(getView() == ViewType.LIST) {
				albumView.hide();
				list.show();
			}
			else {
				albumView.show();
				list.hide();
			}
		}
	}*/
	
	
	public bool pulser() {
		/*if(song_being_ripped != null) {
			song_being_ripped.pulseProgress++;
			
			var updated = new LinkedList<int>();
			updated.add(song_being_ripped.rowid);
			list.songs_updated(updated);
			
			return true;
		}
		else {
			return false;
		}*/
		return false;
	}
}
