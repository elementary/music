// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*
 * Copyright (c) 2012-2013 Noise Developers (http://launchpad.net/noise)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
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

namespace Noise.UI {

    /**
     * Sets the alignment of a widget by modifying the margin and align properties.
     */
    public Gtk.Widget wrap_alignment (Gtk.Widget widget, int top, int right, int bottom, int left) {
        widget.valign = Gtk.Align.FILL;
        widget.halign = Gtk.Align.FILL;

        widget.margin_top = top;
        widget.margin_right = right;
        widget.margin_bottom = bottom;
        widget.margin_left = left;

        return widget;
    }

    /**
     * Makes a Gtk.Window draggable
     */
    public void make_window_draggable (Gtk.Window window) {
        window.add_events (Gdk.EventMask.BUTTON_PRESS_MASK | Gdk.EventMask.POINTER_MOTION_MASK);
        window.button_press_event.connect ( (event) => {
            window.begin_move_drag ((int)event.button, (int)event.x_root, (int)event.y_root, event.time);
            return true;
        });
    }

    /**
     * Sets a fixed size for a tree view column based on a set of strings to be displayed in the column.
     *
     * @param treeview the Gtk.TreeView containing the column
     * @param column the Gtk.TreeViewColumn to size
     * @param renderer the Gtk.CellRenderer used in the column
     * @param strings a set of strings to base the size on
     * @param padding a small amount of extra padding for the column
     */
    public void set_tree_view_column_fixed_width (Gtk.Widget treeview, Gtk.TreeViewColumn column,
                                                  Gtk.CellRendererText renderer, string[] strings, int padding)
    {
	    int max_width = 0;

	    foreach (var str in strings) {
		    renderer.text = str;

		    // XXX should we use minimum size instead?
		    Gtk.Requisition natural_size;
		    renderer.get_preferred_size (treeview, null, out natural_size);

		    if (natural_size.width > max_width)
			    max_width = natural_size.width;
	    }

	    column.fixed_width = max_width + padding;
    }
}

