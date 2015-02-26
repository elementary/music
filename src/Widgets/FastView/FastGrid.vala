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

public class Noise.FastGrid : Widgets.TileView {

    public enum Column {
        PIXBUF,
        TITLE,
        SUBTITLE,
        TOOLTIP,
        N_COLUMNS
    }

    FastGridModel fm;
    Gee.HashMap<int, GLib.Object> table; // is not the same object as showing.
    Gee.HashMap<int, GLib.Object> showing; // should never point to table.

    /* sortable stuff */
    public delegate int SortCompareFunc (GLib.Object a, GLib.Object b);
    private unowned SortCompareFunc compare_func;

    public delegate void ViewSearchFunc (string search, Gee.HashMap<int, Object> table, Gee.HashMap<int, Object> showing);
    private unowned ViewSearchFunc search_func;
    public bool research_needed = false;

    public FastGrid () {
        table = new Gee.HashMap<int, GLib.Object> ();
        showing = new Gee.HashMap<int, GLib.Object> ();
        fm = new FastGridModel ();

        set_table (table, true);
        set_model (fm);

        image_column = Column.PIXBUF;
        title_column = Column.TITLE;
        subtitle_column = Column.SUBTITLE;
        tooltip_column = Column.TOOLTIP;
    }

    public void set_search_func (ViewSearchFunc func) {
        search_func = func;
    }

    /** Should not be manipulated by client */
    public Gee.Map<int, GLib.Object> get_table () {
        return table.read_only_view;
    }

    /** Should not be manipulated by client */
    public Gee.Map<int, GLib.Object> get_visible_table () {
        return showing.read_only_view;
    }

    public int get_index_from_iter (Gtk.TreeIter iter) {
        return (int) iter.user_data;
    }

    public GLib.Object get_object_from_index (int index) {
        return showing.get (index);
    }

    public void set_value_func (FastGridModel.ValueReturnFunc func) {
        fm.set_value_func (func);
    }

    public void set_table (Gee.HashMap<int, GLib.Object> table, bool do_resort) {
        this.table.clear ();
        this.table.set_all (table);

        if (do_resort)
            resort (); // this also calls search
        else
            do_search (null);
    }

    // If a GLib.Object is in objects but not in table, will just ignore
    public void remove_objects (Gee.Collection<Object> objects) {
        var to_remove = new Gee.HashMap<int, Object> ();
        foreach (var entry in table.entries) {
            if (objects.contains (entry.value))
                to_remove.set (entry.key, entry.value);
        }

        table.unset_all (to_remove);

        do_search (null);
    }

    // Does NOT check for duplicates
    public void add_objects (Gee.Collection<Object> objects) {
        // skip calling set_table and just do it ourselves (faster)
        foreach (var o in objects)
            table.set (table.size, o);

        // resort the new songs in. this will also call do_search
        resort ();
    }
    
    public void do_search (string? search) {
        if (search_func == null || research_needed == false)
            return;

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
    public void set_compare_func (SortCompareFunc func) {
        compare_func = func;
    }
    
    public void resort () {
        quicksort (0, table.size - 1);
        do_search (null);
    }
    
    void swap (int a, int b) {
        GLib.Object temp = table.get (a);
        table.set (a, table.get (b));
        table.set (b, temp);
    }
    
    public void quicksort (int start, int end) {
        GLib.Object pivot = table.get ( (start+end)/2);
        int i = start;
        int j = end;
        
        while (i <= j) {
            while (i < end && compare_func (table.get (i), pivot) < 0) ++i;
            while (j > start && compare_func (table.get (j), pivot) > 0) --j;

            if (i <= j) {
                swap (i, j);
                ++i; --j;
            }
        }
        
        if (start < j)    quicksort (start, j);
        if (i < end)        quicksort (i, end);
    }
}
