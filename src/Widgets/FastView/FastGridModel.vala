// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012-2017 elementary LLC. (https://elementary.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * The Noise authors hereby grant permission for non-GPL compatible
 * GStreamer plugins to be used and distributed together with GStreamer
 * and Noise. This permission is above and beyond the permissions granted
 * by the GPL license by which Noise is covered. If you modify this code
 * you may extend this exception to your version of the code, but you are not
 * obligated to do so. If you do not wish to do so, delete this exception
 * statement from your version.
 */

/** Since this class is not publicly facing (the FastView is public part),
 * this model is low level and optimized. We are not worried about stupid
 * users here.
**/
public class Noise.FastGridModel : GLib.Object, Gtk.TreeModel, Gtk.TreeDragSource {
	int stamp; // all iters must match this

	/* data storage variables */
	Gee.HashMap<int, GLib.Object> rows; // internal id -> user specified object

	/** Initialize data storage, columns, etc. **/
	public FastGridModel () {
		rows = new Gee.HashMap<int, GLib.Object>();

		stamp = (int)GLib.Random.next_int();
	}

	public Type get_column_type (int col) {
		if (col == 1) {
			return typeof (string);
		} else {
			return typeof (Album);
		}
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
		return 2;
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
			val = rows.get(row);
			if (column == 1) {
				var album = (Album) val;
				val = "<span size=\"large\"><b>%s</b></span>\n%s".printf (Markup.escape_text (album.get_display_name ()), Markup.escape_text (album.get_display_artist ()));
			}
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
