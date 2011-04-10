/** A TreeModel implemented to support list-only sorting and filtering.
 * TreeIter data holds:
 *      user_data - SequenceIter?
 * 
 */

using Gtk;
using Gee;
using GLib;

public class BeatBox.CompareFuncHolder : GLib.Object {
	public TreeIterCompareFunc sort_func;
	
	public CompareFuncHolder(TreeIterCompareFunc func) {
		sort_func = func;
	}
}

public class BeatBox.MusicTreeModel : GLib.Object, TreeModel, TreeSortable {
	LibraryManager lm;
	int stamp; // all iters must match this
	Gdk.Pixbuf _playing;
	
    /* data storage variables */
    Sequence<ValueArray> rows;
    private LinkedList<string> _columns;
    
    /* treesortable stuff */
    private int sort_column_id;
    private SortType sort_direction;
    private TreeIterCompareFunc default_sort_func;
    private HashMap<int, CompareFuncHolder> column_sorts;
    
    /* custom signals for custom treeview. for speed */
    public signal void rows_changed(LinkedList<TreePath> paths, LinkedList<TreeIter?> iters);
    public signal void rows_deleted (LinkedList<TreePath> paths);
	public signal void rows_inserted (LinkedList<TreePath> paths, LinkedList<TreeIter?> iters);
	
	/** Initialize data storage, columns, etc. **/
	public MusicTreeModel(LibraryManager lm, LinkedList<string> column_types, Gdk.Pixbuf playing) {
		this.lm = lm;
		_columns = column_types;
		_playing = playing;
       rows = new Sequence<ValueArray>(null);
       
       sort_column_id = -2;
       sort_direction = SortType.ASCENDING;
       column_sorts = new HashMap<int, CompareFuncHolder>();
       
       stamp = (int)GLib.Random.next_int();
	}
	
	/** Returns Type of column at index_ **/
	public Type get_column_type (int col) {
		if(_columns[col] == " ") {
			return typeof(Gdk.Pixbuf);
		}
		else if(_columns[col] == "Title" || _columns[col] == "Artist" || _columns[col] == "Album" || _columns[col] == "Genre") {
			return typeof(string);
		}
		else {
			return typeof(int);
		}
	}

	/** Returns a set of flags supported by this interface **/
	public TreeModelFlags get_flags () {
		return TreeModelFlags.LIST_ONLY;
	}

	/** Sets iter to a valid iterator pointing to path **/
	public bool get_iter (out TreeIter iter, TreePath path) {
		int path_index = path.get_indices()[0];
		
		if(rows.get_length() == 0 || path_index < 0 || path_index >= rows.get_length())
			return false;
		
        var seq_iter = rows.get_iter_at_pos(path_index);
        if(seq_iter == null)
			return false;
        
		iter.stamp = this.stamp;
		iter.user_data = seq_iter;
        
		return true;
	}
	
	/** Returns the number of columns supported by tree_model. **/
	public int get_n_columns () {
		return _columns.size;
	}

	/** Returns a newly-created Gtk.TreePath referenced by iter. **/
	public TreePath get_path (TreeIter iter) {
		return new TreePath.from_string(((SequenceIter)iter.user_data).get_position().to_string());
	}

	/** Initializes and sets value to that at column. **/
	public void get_value (TreeIter iter, int column, out Value val) {
		if(iter.stamp != this.stamp || column < 0 || column >= _columns.size)
			return;
		
		if(!((SequenceIter<ValueArray>)iter.user_data).is_end())
			val = rows.get(((SequenceIter<ValueArray>)iter.user_data)).values[column];
	}

	/** Sets iter to point to the first child of parent. **/
	public bool iter_children (out TreeIter iter, TreeIter? parent) {
		
		return false;
	}

	/** Returns true if iter has children, false otherwise. **/
	public bool iter_has_child (TreeIter iter) {
		
		return false;
	}

	/** Returns the number of children that iter has. **/
	public int iter_n_children (TreeIter? iter) {
		if(iter == null)
			return rows.get_length();
		
		return 0;
	}

	/** Sets iter to point to the node following it at the current level. **/
	public bool iter_next (ref TreeIter iter) {
		if(iter.stamp != this.stamp)
			return false;
		
		iter.user_data = ((SequenceIter)iter.user_data).next();
		
		if(((SequenceIter)iter.user_data).is_end())
			return false;
		
		return true;
	}

	/** Sets iter to be the child of parent, using the given index. **/
	public bool iter_nth_child (out TreeIter iter, TreeIter? parent, int n) {
		if(n < 0 || n >= rows.get_length() || parent != null)
			return false;
		
		iter.stamp = this.stamp;
		iter.user_data = rows.get_iter_at_pos(n);
		
		return true;
	}

	/** Sets iter to be the parent of child. **/
	public bool iter_parent (out TreeIter iter, TreeIter child) {
		
		return false;
	}

	/** Lets the tree ref the node. **/
	public void ref_node (TreeIter iter) {}

	/** Lets the tree unref the node. **/
	public void unref_node (TreeIter iter) {}
    
    /** Some actual functions to use this model **/
    public TreeIter? getIterFromRowid(int id) {
		SequenceIter s_iter = rows.get_begin_iter();
		
		for(int index = 0; index < rows.get_length(); ++index) {
			s_iter = rows.get_iter_at_pos(index);
			
			if(id == rows.get(s_iter).values[0].get_int()) {
				TreeIter iter = TreeIter();
				iter.stamp = this.stamp;
				iter.user_data = s_iter;
				
				return iter;
			}
		}
		
		return null;
	}
    
    /** simply adds iter to the model **/
    public void append(out TreeIter iter) {
		SequenceIter<ValueArray> added = rows.append(new ValueArray(0));
		iter.stamp = this.stamp;
		iter.user_data = added;
	}
	
	/** convenience method to insert songs into the model. No iters returned. **/
    public void append_songs(Collection<int> songs, bool emit) {
		foreach(int id in songs) {
			Song s = lm.song_from_id(id);
			
			ValueArray va = new ValueArray(17);
			
			/*va.append(s.rowid);
			va.append(true);
			va.append(Value(typeof(Gdk.Pixbuf)));
			va.append(rows.get_length());
			va.append(s.track);
			va.append(s.title);
			va.append(s.length.to_string());
			va.append(s.artist);
			va.append(s.album);
			va.append(s.genre);
			va.append(s.year);
			va.append(s.bitrate);
			va.append(s.rating);
			va.append(s.play_count);
			va.append(s.skip_count);
			va.append(s.date_added);
			va.append(s.last_played);
			va.append(s.bpm);*/

			for(int i = 0;i < _columns.size; ++i) {
				if(_columns.get(i) == "id")
					va.append(s.rowid);
				else if(_columns.get(i) == " ")
					va.append(Value(typeof(Gdk.Pixbuf)));
				else if(_columns.get(i) == "#")
					va.append(rows.get_length() + 1);
				else if(_columns.get(i) == "Track")
					va.append(s.track);
				else if(_columns.get(i) == "Title")
					va.append(s.title);
				else if(_columns.get(i) == "Length")
					va.append(s.length);
				else if(_columns.get(i) == "Artist")
					va.append(s.artist);
				else if(_columns.get(i) == "Album")
					va.append(s.album);
				else if(_columns.get(i) == "Genre")
					va.append(s.genre);
				else if(_columns.get(i) == "Year")
					va.append(s.year);
				else if(_columns.get(i) == "Bitrate")
					va.append(s.bitrate);
				else if(_columns.get(i) == "Rating")
					va.append(s.rating);
				else if(_columns.get(i) == "Plays")
					va.append(s.play_count);
				else if(_columns.get(i) == "Skips")
					va.append(s.skip_count);
				else if(_columns.get(i) == "Date Added")
					va.append(s.date_added);
				else if(_columns.get(i) == "Last Played")
					va.append(s.last_played);
				else if(_columns.get(i) == "BPM")
					va.append(s.bpm);
			}
			
			SequenceIter<ValueArray> added = rows.append(va.copy());
			
			if(emit) {
				TreePath path = new TreePath.from_string(added.get_position().to_string());
			
				TreeIter iter = TreeIter();
				iter.stamp = this.stamp;
				iter.user_data = added;
				
				row_inserted(path, iter);
			}
		}
	}
	
	public void turnOffPixbuf(int id) {
		SequenceIter s_iter = rows.get_begin_iter();
		
		for(int index = 0; index < rows.get_length(); ++index) {
			s_iter = rows.get_iter_at_pos(index);
			
			if(id == rows.get(s_iter).values[0].get_int()) {
				rows.get(s_iter).values[_columns.index_of(" ")] = Value(typeof(Gdk.Pixbuf));;
				
				TreePath path = new TreePath.from_string(s_iter.get_position().to_string());
				
				TreeIter iter = TreeIter();
				iter.stamp = this.stamp;
				iter.user_data = s_iter;
				
				row_changed(path, iter);
				return;
			}
		}
	}
	
	// just a convenience function
	public void updateSong(int id, bool is_current) {
		ArrayList<int> temp = new ArrayList<int>();
		temp.add(id);
		updateSongs(temp, is_current);
	}
	
	public void updateSongs(owned Collection<int> rowids, bool is_current) {
		SequenceIter s_iter = rows.get_begin_iter();
		
		for(int index = 0; index < rows.get_length(); ++index) {
			s_iter = rows.get_iter_at_pos(index);
			
			if(rowids.contains(rows.get(s_iter).values[0].get_int())) {
				int rowid = rows.get(s_iter).values[0].get_int();
				Song s = lm.song_from_id(rowid);
				
				rows.get(s_iter).values[_columns.index_of(" ")] = (lm.song_info.song != null && rowid == lm.song_info.song.rowid && is_current) ? _playing : Value(typeof(Gdk.Pixbuf));
				rows.get(s_iter).values[_columns.index_of("Track")] = s.track;
				rows.get(s_iter).values[_columns.index_of("Title")] = s.title;
				rows.get(s_iter).values[_columns.index_of("Length")] = (int)s.length;
				rows.get(s_iter).values[_columns.index_of("Artist")] = (string)s.artist;
				rows.get(s_iter).values[_columns.index_of("Album")] = (string)s.album;
				rows.get(s_iter).values[_columns.index_of("Genre")] = s.genre;
				rows.get(s_iter).values[_columns.index_of("Year")] = s.year;
				rows.get(s_iter).values[_columns.index_of("Bitrate")] = s.bitrate;
				rows.get(s_iter).values[_columns.index_of("Rating")] = s.rating;
				rows.get(s_iter).values[_columns.index_of("Plays")] = s.play_count;
				rows.get(s_iter).values[_columns.index_of("Skips")] = s.skip_count;
				rows.get(s_iter).values[_columns.index_of("Date Added")] = s.date_added;
				rows.get(s_iter).values[_columns.index_of("Last Played")] = s.last_played;
				rows.get(s_iter).values[_columns.index_of("BPM")] = s.bpm;
				
				if(rowid == lm.song_info.song.rowid) {
					TreePath path = new TreePath.from_string(s_iter.get_position().to_string());
				
					TreeIter iter = TreeIter();
					iter.stamp = this.stamp;
					iter.user_data = s_iter;
					
					row_changed(path, iter);
				}
				
				rowids.remove(rowid);
			}
			
			if(rowids.size <= 0)
				return;
		}
	}
	
	public new void set(TreeIter iter, ...) {
		if(iter.stamp != this.stamp)
			return;
		
		var args = va_list(); // now call args.arg() to poll
		
		while(true) {
			int col = args.arg();
			if(col < 0 || col >= _columns.size)
				return;
			
			else if(_columns[col] == " ") {
				stdout.printf("set oh hi3\n");
				Gdk.Pixbuf val = args.arg();
				((SequenceIter<ValueArray>)iter.user_data).get().get_nth(col).set_object(val);
			}
			else if(_columns[col] == "Title" || _columns[col] == "Artist" || _columns[col] == "Album" || _columns[col] == "Genre") {
				stdout.printf("set oh hi2\n");
				string val = args.arg();
				((SequenceIter<ValueArray>)iter.user_data).get().get_nth(col).set_string(val);
			}
			else {
				stdout.printf("set oh hi\n");
				int val = args.arg();
				((SequenceIter<ValueArray>)iter.user_data).get().get_nth(col).set_int(val);
			}
		}
	}
	
	public void remove(TreeIter iter) {
		if(iter.stamp != this.stamp)
			return;
			
		var path = new TreePath.from_string(((SequenceIter)iter.user_data).get_position().to_string());
		rows.remove((SequenceIter<ValueArray>)iter.user_data);
		row_deleted(path);
	}
	
	public void removeSongs(Collection<int> rowids) {
		SequenceIter s_iter = rows.get_begin_iter();
		
		for(int index = 0; index < rows.get_length(); ++index) {
			s_iter = rows.get_iter_at_pos(index);
			
			if(rowids.contains(rows.get(s_iter).values[0].get_int())) {
				int rowid = rows.get(s_iter).values[0].get_int();
				TreePath path = new TreePath.from_string(s_iter.get_position().to_string());
					
				rows.remove(s_iter);
					
				row_deleted(path);
				rowids.remove(rowid);
				--index;
			}
			
			if(rowids.size <= 0)
				return;
		}
	}
	
	/** Fills in sort_column_id and order with the current sort column and the order. **/
	public bool get_sort_column_id(out int sort_column_id, out SortType order) {
		sort_column_id = this.sort_column_id;
		order = sort_direction;
		
		return true;
	}
	
	/** Returns true if the model has a default sort function. **/
	public bool has_default_sort_func() {
		return (default_sort_func != null);
	}
	
	/** Sets the default comparison function used when sorting to be sort_func. **/
	public void set_default_sort_func(owned TreeIterCompareFunc sort_func) {
		default_sort_func = sort_func;
	}
	
	/** Sets the current sort column to be sort_column_id. **/
	public void set_sort_column_id(int sort_column_id, SortType order) {
		bool changed = (this.sort_column_id != sort_column_id || order != sort_direction);
		
		this.sort_column_id = sort_column_id;
		sort_direction = order;
		
		if(changed && sort_column_id >= 0) {
			/* do the sort for reals */
			rows.sort_iter(sequenceIterCompareFunc);
			
			sort_column_changed();
		}
	}
	
	/** Sets the comparison function used when sorting to be sort_func. **/
	public void set_sort_func(int sort_column_id, owned TreeIterCompareFunc sort_func) {
		column_sorts.set(sort_column_id, new CompareFuncHolder(sort_func));
	}
	
	/** Custom function to use built in sort in GLib.Sequence to our advantage **/
	public int sequenceIterCompareFunc(SequenceIter<ValueArray> a, SequenceIter<ValueArray> b) {
		int rv;
		
		if(sort_column_id < 0)
			return 0;
		
		if(_columns.get(sort_column_id) == "Artist") {
			Song a_song = lm.song_from_id(rows.get(a).values[0].get_int());
			Song b_song = lm.song_from_id(rows.get(b).values[0].get_int());
			
			if(a_song.artist.down() == b_song.artist.down()) {
				if(a_song.album.down() == b_song.album.down())
					rv = (sort_direction == SortType.ASCENDING) ? a_song.track - b_song.track : b_song.track - a_song.track;
				else
					rv = advancedStringCompare(a_song.album.down(), b_song.album.down());
			}
			else
				rv = advancedStringCompare(a_song.artist.down(), b_song.artist.down());
		}
		else if(_columns.get(sort_column_id) == "Album") {
			Song a_song = lm.song_from_id(rows.get(a).values[0].get_int());
			Song b_song = lm.song_from_id(rows.get(b).values[0].get_int());
			
			if(a_song.album.down() == b_song.album.down())
				rv = (sort_direction == SortType.ASCENDING) ? a_song.track - b_song.track : b_song.track - a_song.track;
			else {
				if(a_song.album == "")
					rv = 1;
				else
					rv = advancedStringCompare(a_song.album.down(), b_song.album.down());
			}
		}
		else {
			/* just do a default, basic sort */
			if(rows.get(a).values[sort_column_id].holds(typeof(int))) {
				rv = rows.get(a).values[sort_column_id].get_int() - rows.get(b).values[sort_column_id].get_int();
			}
			else if(rows.get(a).values[sort_column_id].holds(typeof(string))) {
				rv = advancedStringCompare(rows.get(a).values[sort_column_id].get_string().down(), rows.get(b).values[sort_column_id].get_string().down());
			}
			else {
				rv = ((rows.get(a).values[sort_column_id].get_object() != null) ? 1 : -1);
			}
		}
		
		if(sort_direction == SortType.DESCENDING)
			rv = (rv > 0) ? -1 : 1;
		
		return rv;
	}
	
	private int advancedStringCompare(string a, string b) {
		if(a == "" && b != "")
			return 1;
		else if(a != "" && b == "")
			return -1;
		
		return (a > b) ? 1 : -1;
	}
}
