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

public class Noise.ViewContainer : Gtk.Stack {

    private Gee.HashMap<int, unowned Gtk.Widget> match_views;
    private int nextview_number { get; set; default=0; }

    public ViewContainer () {
        expand = true;
        halign = valign = Gtk.Align.FILL;

        match_views = new Gee.HashMap<int, unowned Gtk.Widget>();
    }

    /**
     * Appends a widget to the main views.
     * @return the index of the view in the view container
     */
    public int add_view (Gtk.Widget view) {
        return_val_if_fail (!has_view (view), -1);

        view.expand = true;
        view.visible = true;
        match_views.set (nextview_number, view);
        add_named (view, nextview_number.to_string ());

        return nextview_number++;
    }

    /**
     * Removes a widget from the main views.
     * @return the index of the view in the view container
     */
    public void remove_view (Gtk.Widget view) {
        foreach (var entry in match_views.entries) {
            if (entry.value == view) {
                match_views.unset (entry.key);
                break;
            }
        }
        remove (view);
        view.destroy ();
    }

    public Gtk.Widget? get_view (int index) {
        return match_views.get (index);
    }

    public Gtk.Widget? get_nth_page (int index) {
        return get_view (index);
    }

    public int get_view_index (Gtk.Widget view) {
        int index = -1;
        foreach (var entry in match_views.entries) {
            if (entry.value == view) {
                index = entry.key;
                break;
            }
        }
        return index;
    }

    public bool has_view (Gtk.Widget view) {
        return get_view_index (view) >= 0;
    }

    public bool has_view_index (int index) {
        return get_view (index) != null;
    }

    public int get_current_index () {
        return int.parse (visible_child_name);
    }

    public Gtk.Widget? get_current_view () {
        return visible_child;
    }

    public int get_n_pages ()
    {
        return match_views.size;
    }

    /**
     * Tries to set the given view as current.
     * @return false if fails.
     */
    public bool set_current_view (Gtk.Widget view) {
        visible_child = view;

        if (visible_child == null) {
            critical ("Cannot set view as current view");
            return false;
        }

        update_visible ();

        return true;
    }

    /**
     * Tries to set the given view index as current.
     * @return false if fails.
     */
    public bool set_current_view_from_index (int index) {
        visible_child_name = index.to_string ();

        if (visible_child == null) {
            critical ("Cannot set view index %i as current view", index);
            return false;
        }

        update_visible ();

        return true;
    }

    void update_visible () {
        if (visible_child == null)
            return;

        if (visible_child is ViewWrapper)
            ((ViewWrapper) visible_child).set_as_current_view ();
        else if (visible_child is Gtk.Grid) {
            App.main_window.viewSelector.selected = Noise.Widgets.ViewSelector.Mode.LIST;
            App.main_window.viewSelector.set_sensitive (false);
            App.main_window.searchField.set_sensitive (false);
        }
    }
}
