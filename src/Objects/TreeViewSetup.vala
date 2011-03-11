using Gee;
using Gtk;

public class BeatBox.TreeViewSetup : GLib.Object {
	private string _sort_column; // Artist, Album
	private Gtk.SortType _sort_direction; // ASCENDING, DESCENDING
	private LinkedList<TreeViewColumn> _columns;
	
	TreeViewSetup() {
		_sort_column = "Artist";
		_sort_direction = Gtk.SortType.ASCENDING;
		_columns = new LinkedList<TreeViewColumn>();
	}
}
