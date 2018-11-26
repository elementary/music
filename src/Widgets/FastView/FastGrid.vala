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

public class Noise.FastGrid : Gtk.IconView {
    public delegate void ViewSearchFunc (Gee.HashMap<int, Object> showing);
    public unowned ViewSearchFunc search_func { get; set; }

    public delegate int SortCompareFunc (GLib.Object a, GLib.Object b);
    public unowned SortCompareFunc compare_func { get; set; }

    public bool research_needed = false;

    private Gtk.CellRenderer cell_renderer;
    private FastGridModel fm;
    private Gee.HashMap<int, GLib.Object> table; // is not the same object as showing.
    private Gee.HashMap<int, GLib.Object> showing; // should never point to table.

    construct {
        table = new Gee.HashMap<int, GLib.Object> ();
        showing = new Gee.HashMap<int, GLib.Object> ();
        fm = new FastGridModel ();

        set_table (table, true);
        set_model (fm);

        cell_renderer = new Noise.Widgets.TileRenderer ();
        pack_start (cell_renderer, false);
        activate_on_single_click = false;
        add_attribute (cell_renderer, "album", 0);
        tooltip_column = 1;

        // padding needs to be 0 for pixel-perfect even spacing
        item_padding = 0;

        // use fixed vertical and horizontal margin
        margin = 24;
    }

    /** Should not be manipulated by client */
    public Gee.Map<int, GLib.Object> get_table () {
        return table.read_only_view;
    }

    /** Should not be manipulated by client */
    public Gee.Map<int, GLib.Object> get_visible_table () {
        return showing.read_only_view;
    }

    public GLib.Object get_object_from_index (int index) {
        return showing.get (index);
    }

    public void set_table (Gee.HashMap<int, GLib.Object> new_table, bool do_resort) {
        table.clear ();
        table.set_all (new_table);

        if (do_resort) {
            resort (); // this also calls search
        } else {
            do_search ();
        }
    }

    // If a GLib.Object is in objects but not in table, will just ignore
    public void remove_objects (Gee.Collection<Object> objects) {
        var to_remove = new Gee.HashMap<int, Object> ();
        foreach (var entry in table.entries) {
            if (objects.contains (entry.value)) {
                to_remove.set (entry.key, entry.value);
            }
        }

        table.unset_all (to_remove);

        do_search ();
    }

    // Does NOT check for duplicates
    public void add_objects (Gee.Collection<Object> objects) {
        // skip calling set_table and just do it ourselves (faster)
        foreach (var o in objects) {
            table.set (table.size, o);
        }

        // resort the new songs in. this will also call do_search
        resort ();
    }

    public void do_search () {
        if (search_func == null || research_needed == false) {
            return;
        }

        research_needed = false;
        var old_size = showing.size;

        showing.clear ();
        search_func (showing);

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

    private void resort () {
        quicksort (0, table.size - 1);
        do_search ();
    }

    private void swap (int a, int b) {
        GLib.Object temp = table.get (a);
        table.set (a, table.get (b));
        table.set (b, temp);
    }

    private void quicksort (int start, int end) {
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

        if (start < j) { 
            quicksort (start, j);
        }
        if (i < end) {
            quicksort (i, end);
        }
    }

    public override void size_allocate (Gtk.Allocation alloc) {
        // This assumes that the width of the sample is the width of every item
        Gtk.Requisition minimum_size, natural_size;
        cell_renderer.get_preferred_size (this, out minimum_size, out natural_size);
        int item_width = minimum_size.width;

        if (item_width <= 0) {
            base.size_allocate (alloc);
        }

        int total_width = alloc.width;

        // Find out how many items fit in a single row
        double num = total_width - 2 * margin;
        double denom = item_width;
        columns = (int) (num / denom);

        // Find ideal column spacing
        num = total_width - columns * item_width - 2 * margin;
        denom = columns - 1;
        column_spacing = (int) (num / denom);

        base.size_allocate (alloc);
    }
}
