using Gee;

public class BeatBox.DeviceViewWrapper : ViewWrapper {
	Device d;
	
	public DeviceViewWrapper(LibraryManager lmm, LibraryWindow lww, Collection<int> medias, string sort, Gtk.SortType dir, ViewWrapper.Hint the_hint, int id, Device d) {
		base(lmm, lww, medias, sort, dir, the_hint, id);
		
		list.import_requested.connect(import_request);
		albumView.import_requested.connect(import_request);
		
		this.d = d;
		d.sync_finished.connect(sync_finished);
	}
	
	void import_request(LinkedList<int> to_import) {
		if(!lm.doing_file_operations()) {
			d.transfer_to_library(to_import);
		}
	}
	
	void sync_finished(bool success) {
		needs_update = true;
	}
}
