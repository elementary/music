// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012-2018 elementary LLC. (https://elementary.io)
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
 * The Music authors hereby grant permission for non-GPL compatible
 * GStreamer plugins to be used and distributed together with GStreamer
 * and Music. This permission is above and beyond the permissions granted
 * by the GPL license by which Music is covered. If you modify this code
 * you may extend this exception to your version of the code, but you are not
 * obligated to do so. If you do not wish to do so, delete this exception
 * statement from your version.
 *
 * Authored by: Scott Ringwelski <sgringwe@mtu.edu>,
 *              Victor Eduardo <victoreduardm@gmail.com>
 */

public class Music.BrowserColumnModel : Object, Gtk.TreeModel, Gtk.TreeSortable {
    /* all iters must match this */
    private int stamp = (int)Random.next_int ();

    public int n_items { get { return rows.get_length () - 1; } } // Doesn't count the first ("All..") item

    /* data storage variables */
    private Sequence<string> rows;

    /* first iter. This helps us to track the "All" row */
    Gtk.TreeIter? first_iter;

    /* treesortable stuff */
    private int sort_column_id;
    private Gtk.SortType sort_direction;
    private unowned Gtk.TreeIterCompareFunc default_sort_func;

    private BrowserColumn.Category category;

    /** Initialize data storage, columns, etc. **/
    public BrowserColumnModel (BrowserColumn.Category category) {
        rows = new Sequence<string> ();

        this.category = category;

        sort_column_id = -2;
        sort_direction = Gtk.SortType.ASCENDING;
    }

    /** Returns a set of flags supported by this interface **/
    public Gtk.TreeModelFlags get_flags () {
        return Gtk.TreeModelFlags.LIST_ONLY;
    }

    /** Sets iter to a valid iterator pointing to path **/
    public bool get_iter (out Gtk.TreeIter iter, Gtk.TreePath path) {
        iter = Gtk.TreeIter ();
        int path_index = path.get_indices ()[0];

        if (rows.get_length () == 0 || path_index < 0 || path_index >= rows.get_length ())
            return false;

        var seq_iter = rows.get_iter_at_pos (path_index);
        if (seq_iter == null)
            return false;

        iter.stamp = this.stamp;
        iter.user_data = seq_iter;

        return true;
    }

    /** Returns the number of columns supported by tree_model. **/
    public int get_n_columns () {
        return 1;
    }

    public Type get_column_type (int col) {
        return typeof (string);
    }

    /** Returns a newly-created Gtk.TreePath referenced by iter. **/
    public Gtk.TreePath? get_path (Gtk.TreeIter iter) {
        return new Gtk.TreePath.from_string ( ( (SequenceIter)iter.user_data).get_position ().to_string ());
    }

    /** Initializes and sets value to that at column. **/
    public void get_value (Gtk.TreeIter iter, int column, out Value val) {
        val = Value (typeof (string));
        if (iter.stamp != this.stamp || column < 0 || column >= 1)
            return;

        if (!((SequenceIter<string>) iter.user_data).is_end ()) {
            val = ((SequenceIter<string>) iter.user_data).get ();
        }
    }

    /** Sets iter to point to the first child of parent. **/
    public bool iter_children (out Gtk.TreeIter iter, Gtk.TreeIter? parent) {
        iter = Gtk.TreeIter ();

        return false;
    }

    /** Returns true if iter has children, false otherwise. **/
    public bool iter_has_child (Gtk.TreeIter iter) {

        return false;
    }

    /** Returns the number of children that iter has. **/
    public int iter_n_children (Gtk.TreeIter? iter) {
        if (iter == null)
            return rows.get_length ();

        return 0;
    }

    /** Sets iter to point to the node following it at the current level. **/
    public bool iter_next (ref Gtk.TreeIter iter) {
        if (iter.stamp != this.stamp)
            return false;

        iter.user_data = ( (SequenceIter)iter.user_data).next ();

        if ( ( (SequenceIter)iter.user_data).is_end ())
            return false;

        return true;
    }

    /** Sets iter to be the child of parent, using the given index. **/
    public bool iter_nth_child (out Gtk.TreeIter iter, Gtk.TreeIter? parent, int n) {
        iter = Gtk.TreeIter ();
        if (n < 0 || n >= rows.get_length () || parent != null)
            return false;

        iter.stamp = this.stamp;
        iter.user_data = rows.get_iter_at_pos (n);

        return true;
    }

    /** Sets iter to be the parent of child. **/
    public bool iter_parent (out Gtk.TreeIter iter, Gtk.TreeIter child) {
        iter = Gtk.TreeIter ();

        return false;
    }

    /** Lets the tree ref the node. **/
    public void ref_node (Gtk.TreeIter iter) {}

    /** Lets the tree unref the node. **/
    public void unref_node (Gtk.TreeIter iter) {}

    /** simply adds iter to the model **/
    public void append (out Gtk.TreeIter iter) {
        iter = Gtk.TreeIter ();
        SequenceIter<string> added = rows.append ("");
        iter.stamp = this.stamp;
        iter.user_data = added;
    }

    /** convenience method to insert strings into the model. No iters returned. **/
    public void append_items (Gee.Collection<string> strings, bool emit) {
        if (first_iter == null)
            add_first_element ();

        foreach (string s in strings) {
            SequenceIter<string> added = rows.append (s);

            if (emit) {
                var path = new Gtk.TreePath.from_string (added.get_position ().to_string ());
                var iter = Gtk.TreeIter ();

                iter.stamp = this.stamp;
                iter.user_data = added;

                row_inserted (path, iter);
            }
        }

        update_first_item ();
    }

    /* Add the "All" item */
    private void add_first_element () {
        SequenceIter<string> added = rows.append ("All");

        first_iter = Gtk.TreeIter ();

        first_iter.stamp = this.stamp;
        first_iter.user_data = added;
    }

    /* Updates the "All" item */
    private void update_first_item () {
        ((SequenceIter<string>)first_iter.user_data).set (get_first_item_text (n_items));
    }


    // The text to use for the first item.
    private string get_first_item_text (int n_items) {
        string rv = "";

        switch (category) {
            case BrowserColumn.Category.GENRE:
                if (n_items == 1)
                    rv = _ ("All Genres");
                else if (n_items > 1)
                    rv = _ ("All %i Genres").printf (n_items);
                else
                    rv = _ ("No Genres");
            break;

            case BrowserColumn.Category.ARTIST:
                if (n_items == 1)
                    rv = _ ("All Artists");
                else if (n_items > 1)
                    rv = _ ("All %i Artists").printf (n_items);
                else
                    rv = _ ("No Artists");
            break;

            case BrowserColumn.Category.ALBUM:
                if (n_items == 1)
                    rv = _ ("All Albums");
                else if (n_items > 1)
                    rv = _ ("All %i Albums").printf (n_items);
                else
                    rv = _ ("No Albums");
            break;

            case BrowserColumn.Category.YEAR:
                if (n_items == 1)
                    rv = _ ("All Years");
                else if (n_items > 1)
                    rv = _ ("All %i Years").printf (n_items);
                else
                    rv = _ ("No Years");
            break;

            case BrowserColumn.Category.RATING:
                if (n_items >= 1)
                    rv = _ ("All Ratings");
                else
                    rv = _ ("No Ratings");
            break;

            case BrowserColumn.Category.GROUPING:
                if (n_items == 1)
                    rv = _ ("All Groupings");
                else if (n_items > 1)
                    rv = _ ("All %i Groupings").printf (n_items);
                else
                    rv = _ ("No Groupings");
            break;

            case BrowserColumn.Category.COMPOSER:
                if (n_items == 1)
                    rv = _ ("All Composers");
                else if (n_items > 1)
                    rv = _ ("All %i Composers").printf (n_items);
                else
                    rv = _ ("No Composers");
            break;
        }

        return rv;
    }


    public new void set (Gtk.TreeIter iter, ...) {
        if (iter.stamp != this.stamp)
            return;

        var args = va_list (); // now call args.arg () to poll

        while (true) {
            int col = args.arg ();
            if (col < 0 || col >= 1)
                return;
            else if (col == 0) {
                string val = args.arg ();
                ((SequenceIter<string>)iter.user_data).set (val);
            }
        }
    }

    public void remove (Gtk.TreeIter iter) {
        if (iter.stamp != this.stamp)
            return;

        var sequence_iter = (SequenceIter<string>)iter.user_data;
        var path = new Gtk.TreePath.from_string (sequence_iter.get_position ().to_string ());
        sequence_iter.remove ();
        row_deleted (path);
    }

    /** Fills in sort_column_id and order with the current sort column and the order. **/
    public bool get_sort_column_id (out int sort_column_id, out Gtk.SortType order) {
        sort_column_id = this.sort_column_id;
        order = sort_direction;

        return true;
    }

    /** Returns true if the model has a default sort function. **/
    public bool has_default_sort_func () {
        return (default_sort_func != null);
    }

    /** Sets the default comparison function used when sorting to be sort_func. **/
    public void set_default_sort_func (owned Gtk.TreeIterCompareFunc sort_func) {
        default_sort_func = sort_func;
    }

    /** Sets the current sort column to be sort_column_id. **/
    public void set_sort_column_id (int sort_column_id, Gtk.SortType order) {
        bool changed = (this.sort_column_id != sort_column_id || order != sort_direction);

        this.sort_column_id = sort_column_id;
        sort_direction = order;

        if (changed && sort_column_id >= 0) {
            /* do the sort for reals */
            rows.sort_iter (sequenceIterCompareFunc);

            sort_column_changed ();
        }
    }

    public void set_sort_func (int sort_column_id, owned Gtk.TreeIterCompareFunc sort_func) {

    }


    /** Custom function to use built in sort in Sequence to our advantage **/
    public int sequenceIterCompareFunc (SequenceIter<string> a, SequenceIter<string> b) {
        int rv = 1;

        if (sort_column_id < 0)
            return 0;

        if (sort_column_id == 0) {
            var first_sequence_iter = (SequenceIter)first_iter.user_data;

            // "All" is always the first
            if (a == first_sequence_iter) {
                rv = -1;
            }
            else if (b == first_sequence_iter) {
                rv = 1;
            }
            else {
                if (category == BrowserColumn.Category.ARTIST || category == BrowserColumn.Category.ALBUM)
                    rv = String.compare (a.get (), b.get ());
                else
                    rv = String.compare (a.get (), b.get ());
            }
        }

        if (sort_direction == Gtk.SortType.DESCENDING)
            rv = (rv > 0) ? -1 : 1;

        return rv;
    }
}

