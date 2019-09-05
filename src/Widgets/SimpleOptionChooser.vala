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
 * The Music authors hereby grant permission for non-GPL compatible
 * GStreamer plugins to be used and distributed together with GStreamer
 * and Music. This permission is above and beyond the permissions granted
 * by the GPL license by which Music is covered. If you modify this code
 * you may extend this exception to your version of the code, but you are not
 * obligated to do so. If you do not wish to do so, delete this exception
 * statement from your version.
 *
 * Authored by: Scott Ringwelski <sgringwe@mtu.edu>
 */

public class Music.SimpleOptionChooser : Gtk.EventBox {
    public Gee.ArrayList<Gtk.Image> options { get; set; }
    public int current_option { get; private set; }

    public signal void option_changed (bool by_user = false);

    construct {
        options = new Gee.ArrayList<Gtk.Image> ();
        current_option = 0;
    }

    public void set_option (int index, bool by_user = false) {
        if (index >= options.size) {
            return;
        }

        current_option = index;
        option_changed (by_user);

        if (get_child () != null) {
            remove (get_child ());
        }

        add (options[index]);
        show_all ();
    }

    public int append_item (string icon_name, string tooltip) {
        var image = new Gtk.Image.from_icon_name (icon_name, Gtk.IconSize.MENU);
        image.tooltip_text = tooltip;

        options.add (image);

        return options.size - 1;
    }

    public override bool button_press_event (Gdk.EventButton event) {
        if (event.type == Gdk.EventType.BUTTON_PRESS) {
            var next = current_option + 1 < options.size
                ? current_option + 1
                : 0;
            set_option (next, true);
        }

        return true;
    }
}
