using Gtk;
using Gee;

public class BeatBox.MillerColumn : HBox {
	LibraryManager lm;
	LibraryWindow lw;
	LinkedList<int> songs;
	
	
	public MillerColumn(LibraryManager lmm, LibraryWindow lww, LinkedList<int> songss) {
		lm = lmm;
		lw = lww;
		songs = songss;
		
		pack_start(new Label("MIller Column Goes Here Please"), true, true, 0);
	}
}
