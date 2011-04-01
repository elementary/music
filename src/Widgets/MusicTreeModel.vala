/** A TreeModel implemented to support list-only sorting and filtering.
 * TreeIter data holds:
 *      user_data - SequenceIter?
 * 
 */

using Gtk;
using Gee;
using GLib;

public class BeatBox.MusicTreeModel : GLib.Object, TreeModel, TreeSortable {
	LibraryManager lm;
	int stamp; // all iters must match this
	
    /* data storage variables */
    Sequence<ValueArray> rows;
    
    Type[] _columns; // an array of the column types
    int visible_column;
    int sort_column;
    
    /* custom signals for custom treeview. for speed */
    public signal void rows_changed(LinkedList<TreePath> paths, LinkedList<TreeIter?> iters);
    public signal void rows_deleted (LinkedList<TreePath> paths);
	public signal void rows_inserted (LinkedList<TreePath> paths, LinkedList<TreeIter?> iters);
	
	/** Initialize data storage, columns, etc. **/
	public MusicTreeModel(LibraryManager lm, Type[] column_types) {
		this.lm = lm;
		_columns = column_types;
       rows = new Sequence<ValueArray>(null);
       
       stamp = (int)GLib.Random.next_int();
	}
	
	/** calls func on each node in model in a depth-first fashion **/
	public void foreach(TreeModelForeachFunc func) {
		stdout.printf("foreach\n");
		SequenceIter s_iter = rows.get_begin_iter();
		bool walk = true;;
		
		while(true) {
			s_iter = s_iter.next();
			
			TreePath path = new TreePath.from_string(s_iter.get_position().to_string());
			
			TreeIter iter = new TreeIter();
			iter.stamp = this.stamp;
			iter.user_data = s_iter;
			
			walk = func(this, path, iter);
			
			if(s_iter.is_end() || !walk)
				return;
		}
	}

	/** Sets params of each id-value pair of the value of that iter **/
	public void get (TreeIter iter, ...) {
		if(iter.stamp != this.stamp)
			return;
		
		var args = va_list(); // now call args.arg() to poll
	}

	/** Returns Type of column at index_ **/
	public Type get_column_type (int index_) {
		return _columns[index_];
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

	/** Initializes iter with the first iterator in the tree (the one at the path "0") and returns true. **/
	public bool get_iter_first (out TreeIter iter) {
		if(rows.get_length() == 0)
			return false;
		
		iter.stamp = this.stamp;
		iter.user_data = rows.get_begin_iter();
		
		return true;
	}

	/** Sets iter to a valid iterator pointing to path_string, if it exists. **/
	public bool get_iter_from_string (out TreeIter iter, string path_string) {
		int path_index = int.parse(path_string);
		
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
		return _columns.length;
	}

	/** Returns a newly-created Gtk.TreePath referenced by iter. **/
	public TreePath get_path (TreeIter iter) {
		return new TreePath.from_string(((SequenceIter)iter.user_data).get_position().to_string());
	}

	/** Generates a string representation of the iter. **/
	public string get_string_from_iter (TreeIter iter) {
		return ((SequenceIter)iter.user_data).get_position().to_string();
	}

	/**   **/
	public void get_valist (TreeIter iter, void* var_args) {
		if(iter.stamp != this.stamp)
			return;
	}

	/** Initializes and sets value to that at column. **/
	public void get_value (TreeIter iter, int column, out Value value) {
		if(iter.stamp != this.stamp || column < 0 || column >= _columns.length)
			return;
		
		value = ((SequenceIter<ValueArray>)iter.user_data).get().get_nth(column);
		
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
		if(iter.stamp != this.stamp || ((SequenceIter)iter.user_data).is_end())
			return false;
		
		iter.user_data = ((SequenceIter)iter.user_data).next();
		
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
    
    /** simply adds iter to the model **/
    public void append(out TreeIter iter) {
		SequenceIter<ValueArray> added = rows.append(new ValueArray(0));
		iter.stamp = this.stamp;
		iter.user_data = added;
	}
	
	/** convenience method to insert songs into the model. No iters returned. **/
    public void append_songs(Collection<int> songs) {
		foreach(int id in songs) {
			Song s = lm.song_from_id(id);
			ValueArray va = new ValueArray(17);
			
			va.append(s.rowid);
			va.append(true);
			va.append(new Value(typeof(Gdk.Pixbuf)));
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
			va.append(s.pretty_date_added());
			va.append(s.pretty_last_played());
			va.append(s.bpm);
			
			SequenceIter<ValueArray> added = rows.append(va.copy());
		}
	}
    
    
    /** TreeSortable Interface. **/
    
    /** Fills in sort_column_id and order with the current sort column and the order. **/
    public bool get_sort_column_id (out int sort_column_id, out SortType order) {
        sort_column_id = 0;
        order = SortType.ASCENDING;
        
        return false;
    }
    
    /**  Returns true if the model has a default sort function. **/
    public bool has_default_sort_func () {
        
        return false;
    }
    
    /** Sets the default comparison function used when sorting to be sort_func. **/
    public void set_default_sort_func (owned TreeIterCompareFunc sort_func) {
        
    }
    
    /** Sets the current sort column to be sort_column_id. **/
    public void set_sort_column_id (int sort_column_id, SortType order) {
        
    }
    
    /** Sets the comparison function used when sorting to be sort_func. **/
    public void set_sort_func (int sort_column_id, owned TreeIterCompareFunc sort_func) {
        
    }
    
    /** This is for filtering. Same approach as TreeModelFilter for the most part
     * set_visible_column: sets the index of the column to use for filtering
     * get_real_iter() : returns an iter that is relative to ALL iters, not just filtered ones
     * filter() : The model is not filtered on visible_column_change, it is filtered on filter()
     */
    
    /* Sets the column that is checked for whether or not the row is visible */
    public void set_visible_column(int index) {
        visible_column = index;
    }
    
    /* Gets the visible column */
    public int get_visible_column() {
        return visible_column;
    }
    
    /* If you give it an iter of filtered rows, it will return an iter of all rows */
    public void get_overall_iter(out TreeIter real_iter, TreeIter filtered_iter) {
        
    }
    
    /* This does all the filtering. I am not sure how this works yet. */
    public void filter() {
        
    }
}
