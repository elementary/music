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

/**
 * Contains the views.
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
	public int add_view (Gtk.Widget view) {
		return append_page (view);
	}

    public int get_view_index (Gtk.Widget view) {
        return page_num (view);
    }

	public Gtk.Widget? get_current_view () {
		return get_current_page () as Gtk.Widget;
	}

	public int get_current_index () {
		return get_view_index (get_current_view ());
	}

    /**
     * Tries to set the given view as current.
     * @return false if fails. true if succeeds
     */
	public bool set_current_view (Gtk.Widget view) {
        int index = get_view_index (view);

		if (index < 0) {
			critical ("Cannot set " + view.name + " as the active view");
            return false;
        }
        else {
            // GtkNotebooks don't show hidden widgets.
            // Let's show the view just in case ...
            view.show ();
            set_current_page (index);
		}

		return true;
	}
}

