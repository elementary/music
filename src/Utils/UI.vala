// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*
 * Copyright (c) 2012 Noise Developers
 *
 * This library is free software; you can redistribute it and/or
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
}

