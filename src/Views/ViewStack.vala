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
 * Authored by: Victor Eduardo <victoreduardm@gmail.com>
 */

public class Noise.ViewStack : Gtk.Stack {
    private int nextview_number { get; set; default = 0; }

    construct {
        expand = true;
    }

    /**
     * Appends a widget to the main views.
     * @return the index of the view in the view container
     */
    public int add_view (Gtk.Widget view) {
        view.expand = true;
        view.visible = true;
        add_named (view, nextview_number.to_string ());

        return nextview_number++;
    }

    /**
     * Removes a widget from the main views.
     * @return the index of the view in the view container
     */
    public void remove_view (Gtk.Widget view) {
        remove (view);
        view.destroy ();
    }
}
