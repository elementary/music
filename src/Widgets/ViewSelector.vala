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
        get {
            return (mode != Mode.COLUMN) ? mode : Mode.LIST;
        }
        set {
            if (mode == value) {
                return;
            }

            mode = value;
            mode_button.selected = (int) value;

            bool is_column_mode = value == Mode.COLUMN;
            column_browser_toggled (is_column_mode);
            mode_changed (is_column_mode ? Mode.LIST : value);
        }
    }

    // De-select items when the widget is made insensitive, for appearance reasons
    public new bool sensitive {
        get {
            return mode_button.sensitive;
        }
        set {
            // select fourth invisible mode to appear as de-selected
            mode_button.sensitive = value;
            mode_button.set_active (value ? (int) mode : -1);
            ((SimpleAction) App.main_window.actions.lookup_action (App.main_window.ACTION_VIEW_ALBUMS)).set_enabled (value);
            ((SimpleAction) App.main_window.actions.lookup_action (App.main_window.ACTION_VIEW_LIST)).set_enabled (value);
            ((SimpleAction) App.main_window.actions.lookup_action (App.main_window.ACTION_VIEW_COLUMNS)).set_enabled (value);
        }
    }

    private Granite.Widgets.ModeButton mode_button;
    private Mode mode;

    public ViewSelector () {
        var image = new Gtk.Image.from_icon_name ("view-grid-symbolic", Gtk.IconSize.MENU);
        image.tooltip_text = _("View as Albums");

        var list = new Gtk.Image.from_icon_name ("view-list-symbolic", Gtk.IconSize.MENU);
        list.tooltip_text = _("View as List");

        var column = new Gtk.Image.from_icon_name ("view-column-symbolic", Gtk.IconSize.MENU);
        column.tooltip_text = _("View in Columns");

        mode_button = new Granite.Widgets.ModeButton ();
        mode_button.append (image);
        mode_button.append (list);
        mode_button.append (column);

        add (mode_button);

        mode_button.mode_changed.connect (() => {
            int new_mode = mode_button.selected;
            if (new_mode <= 2) { // only consider first 3 items
                selected = (Mode) new_mode;
            } else if (mode_button.sensitive) {
                selected = mode; // restore last valid mode
            }
        });
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
}
