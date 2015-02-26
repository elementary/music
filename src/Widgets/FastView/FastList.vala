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

public class Noise.FastView : Gtk.TreeView {
#if HAVE_BUILTIN_SHUFFLE
    public static const int SHUFFLE_COLUMN_ID = -3;
#endif
    public static const int OPTIMAL_COLUMN = -2;
    FastModel fm;
    Gee.LinkedList<Type> columns = new Gee.LinkedList<Type> ();
    protected Gee.HashMap<int, Media> table = new Gee.HashMap<int, Media> (); // is not the same object as showing.
    protected Gee.HashMap<int, Media> showing = new Gee.HashMap<int, Media>(); // should never point to table.

    /* sortable stuff */
    public delegate int SortCompareFunc (int sort_column_id,
                                         Gtk.SortType sort_direction,
                                         Media a, Media b,
                                         int index_a, int index_b); // position of items in the view's @table

    protected int sort_column_id;
    protected Gtk.SortType sort_direction;
    public bool research_needed = false;
    private unowned SortCompareFunc compare_func;
    
    // search stuff
    public delegate void ViewSearchFunc (string search, Gee.HashMap<int, Media> table, Gee.HashMap<int, Media> showing);
    private unowned ViewSearchFunc search_func;
    
    public signal void rows_reordered ();
    
    public FastView (Gee.Collection<Type> types) {
        columns.add_all (types);
        fm = new FastModel (types);

        sort_column_id = OPTIMAL_COLUMN;
        sort_direction = Gtk.SortType.ASCENDING;
        
        fm.reorder_requested.connect(reorder_requested);
        
        set_table(table, true);
        set_model(fm);
    }
    
    /** Should not be manipulated by client */
    public Gee.Map<int, Media> get_table () {
        return table.read_only_view;
    }
    
    /** Should not be manipulated by client */
    public Gee.Map<int, Media> get_visible_table () {
        return showing.read_only_view;
    }
    
    public static int get_index_from_iter(Gtk.TreeIter iter) {
        return (int) iter.user_data;
    }
    
    public Media? get_object_from_index(int index) {
        return showing.get(index);
    }
    
    public void set_value_func(FastModel.ValueReturnFunc func) {
        fm.set_value_func(func);
    }

    public void set_table (Gee.HashMap<int, Media> table, bool do_resort) {
        this.table.clear ();
        this.table.set_all (table);
        
        if (do_resort)
            resort (); // this also calls search
        else
            do_search (null);
    }

    public void set_search_func (ViewSearchFunc func) {
        search_func = func;
    }

    public void do_search (string? search = null) {
        if (search_func == null || research_needed == false)
            return;

        research_needed = false;
        var old_size = showing.size;

        showing.clear ();
        search_func (search ?? "", table, showing);

        if(showing.size == old_size) {
            fm.set_table(showing);
            queue_draw();
        } else if(old_size == 0) { // if first population, just do normal
            set_model(null);
            fm.set_table(showing);
            set_model(fm);
        } else if(old_size > showing.size) { // removing
            while(fm.iter_n_children(null) > showing.size) {
                Gtk.TreeIter iter;
                fm.iter_nth_child(out iter, null, fm.iter_n_children(null) - 1);
                fm.remove(iter);
            }
            
            fm.set_table(showing);
            queue_draw();
        } else if(showing.size > old_size) { // adding
            Gtk.TreeIter iter;
            
            while(fm.iter_n_children(null) < showing.size) {
                fm.append(out iter);
            }
            
            fm.set_table(showing);
            queue_draw();
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
        fm.set_sort_column_id(sort_column_id, order); // The model will then go back to us at reorder_requested
    }
    
    public void get_sort_column_id (out int sort_column, out Gtk.SortType order) {
        sort_column = sort_column_id;
        order = sort_direction;
    }
    
    void reorder_requested (int column, Gtk.SortType direction) {
        if(column == sort_column_id && direction == sort_direction) {
            return;
        }
        
        sort_column_id = column;
        sort_direction = direction;

#if HAVE_BUILTIN_SHUFFLE        
        if(column != SHUFFLE_COLUMN_ID)
            quicksort(0, (int)(table.size - 1));
        else
            shuffle ();
#else
        quicksort (0, (int)table.size - 1);
#endif
        research_needed = true;
        do_search (null);
        
        // Let it be known the row order changed
        rows_reordered();
    }
    
    public void resort () {
#if HAVE_BUILTIN_SHUFFLE
        if(sort_column_id != SHUFFLE_COLUMN_ID)
#endif
            quicksort(0, (int)(table.size - 1));
        
        
        research_needed = true;
        do_search (null);
    }
    
    public void set_compare_func (SortCompareFunc func) {
        compare_func = func;
    }
    
    void swap (int a, int b) {
        var temp = table.get (a);
        table.set (a, table.get(b));
        table.set (b, temp);
    }
    
    public void quicksort (int start, int end) {
        int pivot_index = (start + end) / 2;
        var pivot = table.get (pivot_index);
        int i = start;
        int j = end;
        
        while(i <= j) {
            while(i < end && compare_func (sort_column_id, sort_direction, table.get(i), pivot, i, pivot_index) < 0) ++i;
            while(j > start && compare_func (sort_column_id, sort_direction, table.get(j), pivot, j, pivot_index) > 0) --j;
            if(i <= j) {
                swap(i, j);
                ++i; --j;
            }
        }
        
        if(start < j)
            quicksort (start, j);
        if(i < end)
            quicksort (i, end);
    }

#if HAVE_BUILTIN_SHUFFLE
    protected void shuffle() {
        sort_column_id = SHUFFLE_COLUMN_ID;
        
        int m = table.size;
        int i;
        
        // While there remain elements to shuffle
        while (m > 0) {
        
            // Pick a remaining element
            i = (int)(GLib.Random.next_int() % m--);
            
            // And swap it with the current element.
            swap(m, i);
        }
        
        do_search ();
    }
#endif
}
