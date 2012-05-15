// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012 Noise Developers (http://launchpad.net/noise)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Victor Eduardo <victoreduardm@gmail.com>
 */

public class BeatBox.ViewContainer : Gtk.Notebook {

    public ViewContainer () {
        // Hide notebook tabs and border
        show_tabs = false;
        show_border = false;
    }

    /**
     * Appends a widget to the main views.
     *
     * @return the index of the view in the view container
     */
    public int add_view (Gtk.Widget? view) {
        if (view == null)
            return -1;
        return append_page (view);
    }

    /**
     * Removes a widget from the main views.
     *
     * @return the index of the view in the view container
     */
    public void remove_view (Gtk.Widget? view) {
        if (view == null)
            return;
        remove_page (get_view_index (view));
    }

    public Gtk.Widget? get_view (int index) {
        return get_nth_page (index);
    }

    public int get_view_index (Gtk.Widget? view) {
        if (view == null)
            return -1;
        return page_num (view);
    }

    public Gtk.Widget? get_current_view () {
        return get_view (get_current_index ());
    }

    public int get_current_index () {
        return get_current_page ();
    }

    /**
     * Tries to set the given view as current.
     * @return false if fails. true if succeeds
     */
    public bool set_current_view (Gtk.Widget? view) {
        if (view == null)
            return false;

        int index = get_view_index (view);

       // GtkNotebooks don't show hidden widgets.
       // Let's show the view just in case ...
        view.show ();

        return set_current_view_from_index (index);
    }

    /**
     * Tries to set the given view index as current.
     * @return false if fails. true if succeeds
     */
    public bool set_current_view_from_index (int index) {
        if (index < 0) {
            critical ("Cannot set " + get_view (index).name + " as the active view");
            return false;
        }
        else {
            set_current_page (index);
        }

        return true;
    }
 
}


