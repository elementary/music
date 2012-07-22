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

public class BeatBox.ViewContainer : Gtk.EventBox {

    private Gtk.Notebook? notebook = null;

    public ViewContainer () {
        this.visible_window = false;

        this.push_composite_child ();
        this.notebook = new Gtk.Notebook ();
        this.notebook.set_composite_name ("notebook");
        this.pop_composite_child ();

        this.notebook.show_tabs = false;
        this.notebook.show_border = false;

        base.add (this.notebook);
    }

    public override void remove (Gtk.Widget widget) { }
    public override void add (Gtk.Widget widget) { }

    /**
     * Appends a widget to the main views.
     * @return the index of the view in the view container
     */
    public int add_view (Gtk.Widget view) {
        return_val_if_fail (!has_view (view), -1);
        view.expand = true;
        return this.notebook.append_page (view);
    }

    /**
     * Removes a widget from the main views.
     * @return the index of the view in the view container
     */
    public void remove_view (Gtk.Widget view) {
        this.notebook.remove_page (get_view_index (view));
    }

    public Gtk.Widget? get_view (int index) {
        return this.notebook.get_nth_page (index);
    }

    public int get_view_index (Gtk.Widget view) {
        return this.notebook.page_num (view);
    }

    public bool has_view (Gtk.Widget view) {
        return get_view_index (view) >= 0;
    }

    public bool has_view_index (int index) {
        return get_view (index) != null;
    }

    public int get_current_index () {
        return this.notebook.get_current_page ();
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

        return set_current_view_from_index (index);
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

        this.notebook.set_current_page (index);

        return true;
    }
}
