/** Since this class is not publicly facing (the FastView is public part),
 * this model is low level and optimized. We are not worried about stupid
 * users here.
**/
public class Noise.FastGridModel : GLib.Object, Gtk.TreeModel, Gtk.TreeDragSource {
	int stamp; // all iters must match this
	
	/* data storage variables */
	Gee.HashMap<int, GLib.Object> rows; // internal id -> user specified object
	
	/* user specific function for get_value() */
	public delegate Value? ValueReturnFunc (int row, int column, GLib.Object o);
	private unowned ValueReturnFunc value_func;
	
	/** Initialize data storage, columns, etc. **/
	public FastGridModel () {
		rows = new Gee.HashMap<int, GLib.Object>();
		
		stamp = (int)GLib.Random.next_int();
	}

	public Type get_column_type (int col) {
		if(col == 0)
			return typeof(Gdk.Pixbuf);
		else if(col == 1)
			return typeof(string);
		else if(col == 2)
			return typeof(string);
		else if(col == 3)
			return typeof(string);
		else
			return typeof(GLib.Object);
	}

	public Gtk.TreeModelFlags get_flags () {
		return Gtk.TreeModelFlags.LIST_ONLY;
	}

	public bool get_iter (out Gtk.TreeIter iter, Gtk.TreePath path) {
		iter = Gtk.TreeIter();
		int path_index = path.get_indices()[0];
		if(rows.size == 0 || path_index < 0 || path_index >= rows.size || rows.get(path_index) == null)
			return false;

		iter.stamp = this.stamp;
		iter.user_data = (void*)path_index;

		return true;
	}

	public int get_n_columns () {
		return 5;
	}

	public Gtk.TreePath? get_path (Gtk.TreeIter iter) {
		return new Gtk.TreePath.from_string (((int)iter.user_data).to_string());
	}
	
	public void get_value (Gtk.TreeIter iter, int column, out Value val) {
		val = Value(get_column_type(column));

		if (iter.stamp != this.stamp || column < 0 || column >= get_n_columns())
			return;

		int row = (int)iter.user_data;
		if(!(row >= rows.size)) {
			var object = rows.get(row);
			var val_tmp = value_func(row, column, object);
			if (val_tmp != null)
			    val = val_tmp;
		}
	}

	public bool iter_children (out Gtk.TreeIter iter, Gtk.TreeIter? parent) {
		iter = Gtk.TreeIter();
		return false;
	}

	public bool iter_has_child (Gtk.TreeIter iter) {

		return false;
	}

	public int iter_n_children (Gtk.TreeIter? iter) {
		if(iter == null)
			return rows.size;

		return 0;
	}

	public bool iter_next (ref Gtk.TreeIter iter) {
		if(iter.stamp != this.stamp)
			return false;

		iter.user_data = (void*)(((int)iter.user_data) + 1);

		if(((int)iter.user_data) >= rows.size)
			return false;

		return true;
	}

	public bool iter_nth_child (out Gtk.TreeIter iter, Gtk.TreeIter? parent, int n) {
		iter = Gtk.TreeIter();

		if(n < 0 || n >= rows.size || parent != null)
			return false;

		iter.stamp = this.stamp;
		iter.user_data = (void*)n;

		return true;
	}

	public bool iter_parent (out Gtk.TreeIter iter, Gtk.TreeIter child) {
		iter = Gtk.TreeIter();

		return false;
	}
	
	public void append (out Gtk.TreeIter iter) {
		iter = Gtk.TreeIter();
		
		Gtk.TreePath path = new Gtk.TreePath.from_string((rows.size).to_string());
		rows.set(rows.size, new GLib.Object());
		iter.stamp = this.stamp;
		iter.user_data = (void*)rows.size;
		
		row_inserted(path, iter);
	}
	
	public void remove (Gtk.TreeIter iter) {
		if(iter.stamp != this.stamp)
			return;

		var path = new Gtk.TreePath.from_string(((int)iter.user_data).to_string());
		rows.unset ((int)iter.user_data);
		row_deleted(path);
		
		// TODO: swap all indices > this iter's index down to maintain that
		// the table has row ids 0..n where n is rows.size (consecutive ids)
	}
	
	// Not applicable to this custom treemodel
	public new void set (Gtk.TreeIter iter, ...) {
		return;
	}
	
	public void ref_node (Gtk.TreeIter iter) {}
	public void unref_node (Gtk.TreeIter iter) {}

	/** The beauty of this custom model. This tree model is simply a visual
	 * representation of a HashTable of objects. Before calling this
	 * method, the user should set tree_view.set_model(null). After
	 * calling this, set the tree_view.set_model(fast_model). By doing this
	 * the treeview will not listen for append events and will recalculate
	 * and draw when the model is re-added.
	 * 
	 * @objects Must be a consecutive ordered hash table with indexes 
	 * 0-n where n is size of the hashtable (no gaps).
	**/
	public void set_table (Gee.HashMap<int, GLib.Object> table) {
		rows.clear ();
		rows.set_all (table);

        Gtk.TreeIter iter;
        for (bool valid = get_iter_first (out iter); valid; valid = iter_next (ref iter)) {
            row_changed (get_path (iter), iter);
        }
	}
	
	/** Crucial. Must be set by user. Allows for this model to be abstract
	 * by allowing the user to specify the function that returns values
	 * based on the object (row) and column. **/
	public void set_value_func (ValueReturnFunc func) {
		value_func = func;
	}
	
	public void update_row (int index) {
		Gtk.TreePath path = new Gtk.TreePath.from_string(index.to_string());
		Gtk.TreeIter iter = Gtk.TreeIter();
		iter.stamp = this.stamp;
		iter.user_data = (void*)index;
		
		row_changed(path, iter);
	}
	
	/************************************
	 * Drag'n'drop
	 ************************************/
	bool drag_data_delete(Gtk.TreePath path) {
		return false;
	}
	
	bool drag_data_get(Gtk.TreePath path, Gtk.SelectionData data) {
		/*string[] old = data.get_uris();
		string[] cp = new string[old.length + 1];
		for(int i = 0; i < old.length; ++i)
			cp[i] = old[i];
		
		cp[cp.length - 1] = rows[int.parse(path.to_string())].uri;*/
		
		return true;
	}
	
	bool row_draggable(Gtk.TreePath path) {
		return true;
	}
}
