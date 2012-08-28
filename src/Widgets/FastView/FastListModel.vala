/*
 * Copyright (c) 2012 Noise Developers
 *
 * This is a free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this program; see the file COPYING.  If not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Scott Ringwelski <sgringwe@mtu.edu>
 */
using Gtk;

/** Since this class is not publicly facing (the FastView is public part),
 * this model is low level and optimized. We are not worried about stupid
 * users here.
**/
public class Noise.FastModel : GLib.Object, TreeModel, TreeSortable {
	int stamp; // all iters must match this
	
	/* data storage variables */
	HashTable<int, Object> rows; // internal id -> user specified object
	List<Type> columns;
	
	private int sort_column_id;
	private SortType sort_direction;
	
	/* user specific function for get_value() */
	public delegate Value ValueReturnFunc (int row, int column, Object o);
	private unowned ValueReturnFunc value_func;
	
	public signal void reorder_requested (int column, Gtk.SortType direction);

	/** Initialize data storage, columns, etc. **/
	public FastModel (List<Type> column_types) {
		columns = column_types.copy();
		rows = new HashTable<int, Object>(null, null);
		
		sort_column_id = -2;
		sort_direction = SortType.ASCENDING;
		
		stamp = (int)GLib.Random.next_int();
	}

	public Type get_column_type (int col) {
		return columns.nth_data(col);
	}

	public TreeModelFlags get_flags () {
		return TreeModelFlags.LIST_ONLY;
	}

	public bool get_iter (out TreeIter iter, TreePath path) {
		iter = TreeIter();
		int path_index = path.get_indices()[0];
		if(rows.size() == 0 || path_index < 0 || path_index >= rows.size() || rows.get(path_index) == null)
			return false;

		iter.stamp = this.stamp;
		iter.user_data = (void*)path_index;

		return true;
	}

	public int get_n_columns () {
		return (int)columns.length();
	}

	public TreePath? get_path (TreeIter iter) {
		return new TreePath.from_string (((int)iter.user_data).to_string());
	}
	
	public void get_value (TreeIter iter, int column, out Value val) {
		val = Value(get_column_type(column));
		
		if(iter.stamp != this.stamp || column < 0 || column >= get_n_columns()) {
			return;
		}
		
		int row = (int)iter.user_data;
		if(!(row >= rows.size())) {
			var object = rows.get(row);
			val = value_func(row, column, object);
		}
	}

	public Object get_object (TreeIter iter) {
        Object? object = null;

		int row = (int)iter.user_data;
		if (row < rows.size ())
			object = rows.get (row);

        return object;
	}

	public bool iter_children (out TreeIter iter, TreeIter? parent) {
		iter = TreeIter();
		return false;
	}

	public bool iter_has_child (TreeIter iter) {

		return false;
	}

	public int iter_n_children (TreeIter? iter) {
		if(iter == null)
			return (int)rows.size();

		return 0;
	}

	public bool iter_next (ref TreeIter iter) {
		if(iter.stamp != this.stamp)
			return false;

		iter.user_data = (void*)(((int)iter.user_data) + 1);

		if(((int)iter.user_data) >= rows.size())
			return false;

		return true;
	}

	public bool iter_nth_child (out TreeIter iter, TreeIter? parent, int n) {
		iter = TreeIter();

		if(n < 0 || n >= rows.size() || parent != null)
			return false;

		iter.stamp = this.stamp;
		iter.user_data = (void*)n;

		return true;
	}

	public bool iter_parent (out TreeIter iter, TreeIter child) {
		iter = TreeIter();

		return false;
	}
	
	public void append (out TreeIter iter) {
		iter = TreeIter();
		
		TreePath path = new TreePath.from_string(((int)rows.size()).to_string());
		rows.set((int)rows.size(), new Object());
		iter.stamp = this.stamp;
		iter.user_data = (void*)rows.size;
		
		row_inserted(path, iter);
	}
	
	public void remove (TreeIter iter) {
		if(iter.stamp != this.stamp)
			return;

		var path = new TreePath.from_string(((int)iter.user_data).to_string());
		rows.remove((int)iter.user_data);
		row_deleted(path);
		
		// TODO: swap all indices > this iter's index down to maintain that
		// the table has row ids 0..n where n is rows.size (consecutive ids)
	}
	
	// Not applicable to this custom treemodel
	public new void set (TreeIter iter, ...) {
		return;
	}
	
	public void ref_node (TreeIter iter) {}
	public void unref_node (TreeIter iter) {}

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
	public void set_table (HashTable<int, Object> table) {
		rows.remove_all();
		for(int i = 0; i < table.size(); ++i)
			rows.set(i, table.get(i));
	}
	
	/** Crucial. Must be set by user. Allows for this model to be abstract
	 * by allowing the user to specify the function that returns values
	 * based on the object (row) and column. **/
	public void set_value_func (ValueReturnFunc func) {
		value_func = func;
	}
	
	public void update_row (int index) {
		TreePath path = new TreePath.from_string(index.to_string());
		TreeIter iter = TreeIter();
		iter.stamp = this.stamp;
		iter.user_data = (void*)index;
		
		row_changed(path, iter);
	}
	
	/** The following functions are for implementing TreeSortable. We pass
	 * off responsibility to sort things to the view.
	**/
	public bool get_sort_column_id (out int sort_column_id, out SortType order) {
		sort_column_id = this.sort_column_id;
		order = this.sort_direction;
		
		return true;
	}
	
	public void set_sort_column_id (int column, SortType order) {
		sort_column_id = column;
		sort_direction = order;
		
		reorder_requested(column, order);
		sort_column_changed();
	}
	
	/** The following functions are only here to implement TreeSortable **/
	public bool has_default_sort_func () {
		return true; // place holder. not used.
	}
	
	public void set_sort_func (int sort_column_id, owned TreeIterCompareFunc sort_func) {
		// place holder. not used.
	}

	public void set_default_sort_func (owned TreeIterCompareFunc sort_func) {
		// place holder. not used.
	}
}

