using Gee;
using Gtk;

public class BeatBox.TreeViewSetup : GLib.Object {
	private string _sort_column; // Artist, Album
	private Gtk.SortType _sort_direction; // ASCENDING, DESCENDING
	private LinkedList<TreeViewColumn> _columns;
	
	public TreeViewSetup(string sort_col, SortType sort_dir) {
		_sort_column = sort_col;
		_sort_direction = sort_dir;
		_columns = new LinkedList<TreeViewColumn>();
	}
	
	public string sort_column {
		get { return _sort_column; }
		set { _sort_column = value; }
	}
	
	public SortType sort_direction {
		get { return _sort_direction; }
		set { _sort_direction = value; }
	}
	
	public string sort_direction_to_string() {
		if(_sort_direction == SortType.ASCENDING)
			return "ASCENDING";
		else
			return "DESCENDING";
	}
	
	public void set_sort_direction_from_string(string dir) {
		if(dir == "ASCENDING")
			_sort_direction = SortType.ASCENDING;
		else
			_sort_direction = SortType.DESCENDING;
	}
	
	public LinkedList<TreeViewColumn> get_columns() {
		return _columns;
	}
	
	public void set_columns(LinkedList<TreeViewColumn> cols) {
		_columns = cols;
	}
	
	public void import_columns(string cols) {
		string[] col_strings = cols.split("<column_seperator>", 0);
		
		int index;
		for(index = 0; index < col_strings.length - 1; ++index) {
			string[] pieces_of_column = col_strings[index].split("<value_seperator>", 0);
			
			TreeViewColumn tvc;
			if(pieces_of_column[0] != " " && pieces_of_column[0] != "Rating")
				tvc = new Gtk.TreeViewColumn.with_attributes(pieces_of_column[0], new Gtk.CellRendererText(), "text", index, null);
			else
				tvc = new Gtk.TreeViewColumn.with_attributes(pieces_of_column[0], new Gtk.CellRendererPixbuf(), "pixbuf", index, null);
			
			tvc.resizable = true;
			tvc.reorderable = true;
			tvc.clickable = true;
			tvc.sort_column_id = index;
			tvc.set_sort_indicator(false);
			tvc.sizing = Gtk.TreeViewColumnSizing.FIXED;
			
			tvc.fixed_width = int.parse(pieces_of_column[1]);
			tvc.visible = (int.parse(pieces_of_column[2]) == 1);
			
			_columns.add(tvc);
		}
	}
	
	public string columns_to_string() {
		string rv = "";
		
		foreach(TreeViewColumn tvc in _columns) {
			rv += tvc.title + "<value_seperator>" + tvc.fixed_width.to_string() + "<value_seperator>" + ( (tvc.visible) ? "1" : "0" ) + "<column_seperator>";
		}
		
		return rv;
	}
}
