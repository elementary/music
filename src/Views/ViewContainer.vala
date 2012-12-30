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

public class Noise.ViewContainer : Gtk.Notebook {

    private Gee.HashMap<int, unowned Gtk.Widget> match_views;
    private int nextview_number { get; set; default=0; }
    private int current_view = 0;

    public ViewContainer () {
        expand = true;
        halign = valign = Gtk.Align.FILL;

        show_tabs = false;
        show_border = false;
        match_views = new Gee.HashMap<int, unowned Gtk.Widget>();
    }

    /**
     * Appends a widget to the main views.
     * @return the index of the view in the view container
     */
    public int add_view (Gtk.Widget view) {
        return_val_if_fail (!has_view (view), -1);
        view.expand = true;
        match_views.set (nextview_number, view);
        nextview_number++;
        append_page (view);
        return nextview_number-1;
    }

    /**
     * Removes a widget from the main views.
     * @return the index of the view in the view container
     */
    public void remove_view (Gtk.Widget view) {
        remove_page (page_num (view));
        foreach (var entry in match_views.entries) {
            if (entry.value == view) {
                match_views.unset (entry.key);
                break;
            }
        }
    }

    public Gtk.Widget? get_view (int index) {
        return match_views.get (index);
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
        return current_view;
    }

    public Gtk.Widget? get_current_view () {
        return get_view (get_current_index ());
    }

    /**
     * Tries to set the given view as current.
     * @return false if fails.
     */
    public bool set_current_view (Gtk.Widget view) {
        int index = get_view_index (view);

        // GtkNotebooks don't show hidden widgets. Let's show the view
        // just in case it's still not visible.
        view.visible = true;

        if (index < 0 || !has_view_index (index)) {
            critical ("Cannot set view with index %i as current view", index);
            return false;
        }
        current_view = get_view_index (view);

        set_current_page (page_num (view));
        if (get_view (index) is ViewWrapper)
            (get_view (index) as ViewWrapper).set_as_current_view ();

        return true;
    }

    /**
     * Tries to set the given view index as current.
     * @return false if fails.
     */
    public bool set_current_view_from_index (int index) {
        if (index < 0 || !has_view_index (index)) {
            critical ("Cannot set view with index %i as current view", index);
            return false;
        }
        current_view = index;

        set_current_page (page_num (match_views.get(index)));
        if (get_view (index) is ViewWrapper)
            (get_view (index) as ViewWrapper).set_as_current_view ();
        else if (get_view (index) is Gtk.Grid) {
            App.main_window.viewSelector.selected = Noise.Widgets.ViewSelector.Mode.LIST;
            App.main_window.viewSelector.set_sensitive (false);
            App.main_window.searchField.set_sensitive (false);
        }

        return true;
    }
}
