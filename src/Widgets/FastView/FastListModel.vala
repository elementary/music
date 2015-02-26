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

/** Since this class is not publicly facing (the FastView is public part),
 * this model is low level and optimized. We are not worried about stupid
 * users here.
**/

public class Noise.FastModel : GLib.Object, Gtk.TreeModel, Gtk.TreeSortable {
    private int stamp; // all iters must match this
    
    /* data storage variables */
    Gee.HashMap<int, Object> rows = new Gee.HashMap<int, Object> (null, null); // internal id -> user specified object
    Gee.LinkedList<Type> columns = new Gee.LinkedList<Type> ();
    
    private int sort_column_id;
    private Gtk.SortType sort_direction;
    
    /* user specific function for get_value() */
    public delegate Value? ValueReturnFunc (int row, int column, Object o);
    private unowned ValueReturnFunc value_func;
    
    public signal void reorder_requested (int column, Gtk.SortType direction);

    /** Initialize data storage, columns, etc. **/
    public FastModel (Gee.Collection<Type> column_types) {
        columns.add_all (column_types);

        sort_column_id = -2;
        sort_direction = Gtk.SortType.ASCENDING;

        stamp = (int) GLib.Random.next_int();
    }

    public Type get_column_type (int col) {
        return columns.get (col);
    }

    public Gtk.TreeModelFlags get_flags () {
        return Gtk.TreeModelFlags.LIST_ONLY;
    }

    public bool get_iter (out Gtk.TreeIter iter, Gtk.TreePath path) {
        iter = Gtk.TreeIter();
        int path_index = path.get_indices ()[0];
        uint size = rows.size;

        if (size == 0 || path_index < 0 || path_index >= size || rows.get (path_index) == null)
            return false;

        iter.stamp = this.stamp;
        iter.user_data = (void*) path_index;

        return true;
    }

    public int get_n_columns () {
        return (int) columns.size;
    }

    public Gtk.TreePath? get_path (Gtk.TreeIter iter) {
        return new Gtk.TreePath.from_string (((int)iter.user_data).to_string());
    }
    
    public void get_value (Gtk.TreeIter iter, int column, out Value val) {
        val = Value (get_column_type (column));

        if (iter.stamp != this.stamp || column < 0 || column >= get_n_columns ())
            return;

        int row = (int) iter.user_data;
        var object = rows.get (row);
        Value? val_tmp = null;

        if (object != null)
            val_tmp = value_func (row, column, object);

        if (val_tmp != null)
            val = val_tmp;
    }

    public Object get_object (Gtk.TreeIter iter) {
        return rows.get ((int) iter.user_data);
    }

    public bool iter_children (out Gtk.TreeIter iter, Gtk.TreeIter? parent) {
        iter = Gtk.TreeIter();
        return false;
    }

    public bool iter_has_child (Gtk.TreeIter iter) {

        return false;
    }

    public int iter_n_children (Gtk.TreeIter? iter) {
        return (iter == null) ? (int) rows.size : 0;
    }

    public bool iter_next (ref Gtk.TreeIter iter) {
        if(iter.stamp != this.stamp)
            return false;

        int index = (int) iter.user_data;
        iter.user_data = (void*) (++index);

        return index < rows.size;
    }

    public bool iter_nth_child (out Gtk.TreeIter iter, Gtk.TreeIter? parent, int n) {
        iter = Gtk.TreeIter();

        if (n < 0 || n >= rows.size || parent != null)
            return false;

        iter.stamp = stamp;
        iter.user_data = (void*) n;

        return true;
    }

    public bool iter_parent (out Gtk.TreeIter iter, Gtk.TreeIter child) {
        iter = Gtk.TreeIter();

        return false;
    }
    
    public void append (out Gtk.TreeIter iter) {
        iter = Gtk.TreeIter();

        int index = (int) rows.size;

        Gtk.TreePath path = new Gtk.TreePath.from_indices (index, -1);
        rows.set (index, new Object());

        iter.stamp = stamp;
        iter.user_data = (void*) rows.size;

        row_inserted(path, iter);
    }
    
    public void remove (Gtk.TreeIter iter) {
        if(iter.stamp != this.stamp)
            return;

        int index = (int) iter.user_data;

        var path = new Gtk.TreePath.from_indices (index, -1);
        rows.unset (index);

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
    public void set_table (Gee.HashMap<int, Object> table) {
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
    
    /** The following functions are for implementing TreeSortable. We pass
     * off responsibility to sort things to the view.
    **/
    public bool get_sort_column_id (out int sort_column_id, out Gtk.SortType order) {
        sort_column_id = this.sort_column_id;
        order = this.sort_direction;
        
        return true;
    }
    
    public void set_sort_column_id (int column, Gtk.SortType order) {
        sort_column_id = column;
        sort_direction = order;

        if (column != -1) {
            reorder_requested(column, order);
            sort_column_changed();
        }
    }
    
    /** The following functions are only here to implement TreeSortable **/
    public bool has_default_sort_func () {
        return true; // place holder. not used.
    }
    
    public void set_sort_func (int sort_column_id, owned Gtk.TreeIterCompareFunc sort_func) {
        // place holder. not used.
    }

    public void set_default_sort_func (owned Gtk.TreeIterCompareFunc sort_func) {
        // place holder. not used.
    }
}
