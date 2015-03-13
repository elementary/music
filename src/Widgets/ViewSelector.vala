// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012 Noise Developers (http://launchpad.net/noise)
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
 */

public class Noise.Widgets.ViewSelector : Gtk.ToolItem {
    public signal void mode_changed (Mode new_mode);
    public signal void column_browser_toggled (bool new_value);

    public enum Mode {
        GRID = 0,
        LIST = 1,
        COLUMN = 2;
    }


    // The COLUMN mode is still not considered as a single mode, and thus it's
    // never returned by @selected. See complementary API below
    public Mode selected {
        get { return (mode != Mode.COLUMN) ? mode : Mode.LIST; }
        set {
            if (this.mode == value)
                return;
            this.mode = value;
            mode_button.set_active ((int)value);

            bool is_column_mode = value == Mode.COLUMN;
            column_browser_toggled (is_column_mode);
            mode_changed (is_column_mode ? Mode.LIST : value);
        }
    }

    private Granite.Widgets.ModeButton mode_button;
    private Mode mode;

    public ViewSelector () {
        // Allocate enough space for all the buttons
        set_size_request (90, -1);

        mode_button = new Granite.Widgets.ModeButton ();
        mode_button.valign = Gtk.Align.CENTER;
        mode_button.halign = Gtk.Align.START;

        var image = Icons.VIEW_ICONS.render_image (Gtk.IconSize.MENU);
        image.tooltip_text = _("View as Albums");
        mode_button.append (image);

        var list = Icons.VIEW_DETAILS.render_image (Gtk.IconSize.MENU);
        list.tooltip_text = _("View as List");
        mode_button.append (list);
        
        var column = Icons.VIEW_COLUMN.render_image (Gtk.IconSize.MENU);
        column.tooltip_text = _("View in Columns");
        mode_button.append (column);

        // extra invisible mode to allow apparent de-selection
        mode_button.append_text ("");
        mode_button.set_item_visible (3, false);

        add (mode_button);

        mode_button.mode_changed.connect ( () => {
            int new_mode = mode_button.selected;
            if (new_mode <= 2) // only consider first 3 items
                selected = (Mode)new_mode;
            else if (mode_button.sensitive)
                selected = mode; // restore last valid mode
        });
    }

    private void set_mode_visible (Mode mode, bool visible) {
        mode_button.set_item_visible ((int)mode, visible);
    }

    private bool get_mode_visible (Mode mode) {
        return mode_button.get_children ().nth_data ((int)mode).visible;
    }

    // De-select items when the widget is made insensitive, for appearance reasons
    public new void set_sensitive (bool sensitive) {
        // select fourth invisible mode to appear as de-selected
        mode_button.set_sensitive (sensitive);
        mode_button.set_active (sensitive ? (int)mode : 3);
    }

    public new bool get_sensitive () {
        return mode_button.get_sensitive ();
    }

    // CRAPPY API
    // XXX ugly workaround to avoid dealing with API breaks, since there's no time
    // to come up with a fancy solution. Needs rewrite

    public bool get_column_browser_toggle_active () {
        return mode == Mode.COLUMN;
    }

    public void set_column_browser_toggle_active (bool active) {
        if (active) {
            selected = Mode.COLUMN;
        } else if (get_column_browser_toggle_active ()) {
            selected = Mode.LIST;
        }
    }

    public bool get_column_browser_toggle_visible () {
        return get_mode_visible (Mode.COLUMN);
    }

    public void set_column_browser_toggle_visible (bool val) {
        set_mode_visible (Mode.COLUMN, val);
    }
}
