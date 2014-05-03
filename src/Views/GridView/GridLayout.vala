// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012 Noise Developers (http://launchpad.net/noise)
 *
 * This software is licensed under the GNU General Public License
 * (version 2 or later). See the COPYING file in this distribution.
 *
 * The Noise authors hereby grant permission for non-GPL compatible
 * GStreamer plugins to be used and distributed together with GStreamer
 * and Noise. This permission is above and beyond the permissions granted
 * by the GPL license by which Noise is covered. If you modify this code
 * you may extend this exception to your version of the code, but you are not
 * obligated to do so. If you do not wish to do so, delete this exception
 * statement from your version.
 *
 * Authored by: Victor Eduardo <victoreduardm@gmail.com>
 */

public abstract class Noise.GridLayout : ViewTextOverlay {
    public ViewWrapper parent_view_wrapper { get; protected set; }

    private FastGrid icon_view;
    private Gtk.ScrolledWindow scroll;

    public GridLayout (ViewWrapper view_wrapper) {
        parent_view_wrapper = view_wrapper;
        build_ui ();
        clear_objects ();

        view_wrapper.library.search_finished.connect (() => {this.icon_view.research_needed = true;});
        icon_view.set_search_func (search_func);
    }

    protected abstract void item_activated (Object? object);
    protected abstract Value? val_func (int row, int column, Object o);
    protected abstract int compare_func (Object a, Object b);
    protected abstract void search_func (string search, HashTable<int, Object> table, ref HashTable<int, Object> showing);

    protected void set_research_needed (bool value) {
        this.icon_view.research_needed = value;
    }
    
    protected void add_objects (Gee.Collection<Object> objects) {
        icon_view.add_objects (objects);
    }

    protected void do_search (string? search) {
        icon_view.do_search (search);
    }

    protected void remove_objects (Gee.HashSet<Object> objects) {
        icon_view.remove_objects (objects);
    }

    protected void clear_objects () {
        icon_view.set_table (new HashTable<int, Album> (null, null), true);
    }

    protected List<unowned Object> get_objects () {
        return icon_view.get_table ().get_values ();
    }

    protected List<unowned Object> get_visible_objects () {
        return icon_view.get_visible_table ().get_values ();
    }


    private void build_ui () {
        scroll = new Gtk.ScrolledWindow (null, null);
        scroll.set_policy (Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
        add (scroll);

        icon_view = new FastGrid ();
        icon_view.set_compare_func (compare_func);
        icon_view.set_value_func (val_func);

        icon_view.set_columns (-1);

        scroll.add (icon_view);
        icon_view.item_activated.connect (on_item_activated);

        show_all ();
    }

    private void on_item_activated (Gtk.TreePath? path) {
        if (path == null)
            item_activated (null);

        var obj = icon_view.get_object_from_index (int.parse (path.to_string ()));
        item_activated (obj);
    }
}