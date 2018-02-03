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
 *
 * Authored by: Scott Ringwelski <sgringwe@mtu.edu>
 */

/**
* A widget display a list of medias.
*/
public class Noise.FastView : Gtk.TreeView {
    public const int OPTIMAL_COLUMN = -2;
    protected FastModel fm;
    public Gee.List<Type> columns { get; construct set; }

    /**
    * A list of all the medias to display
    */
    protected Gee.ArrayList<Media> table = new Gee.ArrayList<Media> (); // is not the same object as showing.

    /**
    * The media that are presently shown (some of them can be absent because of search)
    */
    protected Gee.ArrayList<Media> showing = new Gee.ArrayList<Media> (); // should never point to table.

    /* sortable stuff */
    public delegate int SortCompareFunc (int sort_column_id, Gtk.SortType sort_direction, Media a, Media b,
                                         int index_a, int index_b); // position of items in the view's @table

    protected int sort_column_id;
    protected Gtk.SortType sort_direction;
    public bool research_needed { get; set; default = false; }
    private unowned SortCompareFunc compare_func;

    // search stuff
    public delegate void ViewSearchFunc (string search, Gee.ArrayList<Media> table, Gee.ArrayList<Media> showing);
    private unowned ViewSearchFunc search_func;

    public signal void rows_reordered ();

    construct {
        columns = new Gee.ArrayList<Type> ();
        foreach (var type in ListColumn.get_all ()) {
            columns.add (type.get_data_type ());
        }

        fm = new FastModel (columns);
        sort_column_id = OPTIMAL_COLUMN;
        sort_direction = Gtk.SortType.ASCENDING;

        fm.reorder_requested.connect (reorder_requested);

        set_table (table, true);
        set_model (fm);
    }

    /** Should not be manipulated by client */
    public Gee.BidirList<Media> get_table () {
        return table.read_only_view;
    }

    /** Should not be manipulated by client */
    public Gee.BidirList<Media> get_visible_table () {
        return showing.read_only_view;
    }

    public static int get_index_from_iter (Gtk.TreeIter iter) {
        return (int) iter.user_data;
    }

    public Media? get_object_from_index (int index) {
        return index < showing.size ? showing[index] : null;
    }

    public void set_value_func (FastModel.ValueReturnFunc func) {
        fm.set_value_func (func);
    }

    public void set_table (Gee.ArrayList<Media> table, bool do_resort) {
        this.table = table;

        if (do_resort) {
            resort (); // this also calls search
        } else {
            do_search (null);
        }
    }

    public void set_search_func (ViewSearchFunc func) {
        search_func = func;
    }

    public void do_search (string? search = null) {
        if (search_func == null || research_needed == false) {
            return;
        }

        research_needed = false;
        var old_size = showing.size;

        showing.clear ();
        search_func (search ?? "", table, showing);

        if (showing.size == old_size) {
            fm.set_table (showing);
            queue_draw ();
        } else if (old_size == 0) { // if first population, just do normal
            set_model (null);
            fm.set_table (showing);
            set_model (fm);
        } else if (old_size > showing.size) { // removing
            while (fm.iter_n_children (null) > showing.size) {
                Gtk.TreeIter iter;
                fm.iter_nth_child (out iter, null, fm.iter_n_children (null) - 1);
                fm.remove (iter);
            }

            fm.set_table (showing);
            queue_draw ();
        } else if (showing.size > old_size) { // adding
            Gtk.TreeIter iter;

            while (fm.iter_n_children (null) < showing.size) {
                fm.append (out iter);
            }

            fm.set_table (showing);
            queue_draw ();
        }
    }

    public void redraw_row (int row_index) {
        fm.update_row (row_index);
    }

    /** Sorting is done in the treeview, not the model. That way the whole
     * table is sorted and ready to go and we do not need to resort every
     * time we repopulate/search the model
    **/
    public void set_sort_column_id (int sort_column_id, Gtk.SortType order) {
        fm.set_sort_column_id (sort_column_id, order); // The model will then go back to us at reorder_requested
    }

    public void get_sort_column_id (out int sort_column, out Gtk.SortType order) {
        sort_column = sort_column_id;
        order = sort_direction;
    }

    void reorder_requested (int column, Gtk.SortType direction) {
        if (column == sort_column_id && direction == sort_direction) {
            return;
        }

        sort_column_id = column;
        sort_direction = direction;

        quicksort (0, table.size - 1);
        research_needed = true;
        do_search (null);

        // Let it be known the row order changed
        rows_reordered ();
    }

    public void resort () {
        quicksort (0, table.size - 1);

        research_needed = true;
        do_search (null);
    }

    public void set_compare_func (SortCompareFunc func) {
        compare_func = func;
    }

    void swap (int a, int b) {
        var temp = table[a];
        table[a] = table[b];
        table[b] = temp;
    }

    public void quicksort (int start, int end) {
        if (table.size == 0) {
            return;
        }

        int pivot_index = (start + end) / 2;
        var pivot = table[pivot_index];
        int i = start;
        int j = end;

        while (i <= j) {
            while (i < end && compare_func (sort_column_id, sort_direction, table[i], pivot, i, pivot_index) < 0) ++i;
            while (j > start && compare_func (sort_column_id, sort_direction, table[j], pivot, j, pivot_index) > 0) --j;
            if (i <= j) {
                swap (i, j);
                ++i; --j;
            }
        }

        if (start < j) {
            quicksort (start, j);
        }
        if (i < end) {
            quicksort (i, end);
        }
    }
}
