// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012-2017 elementary LLC. (https://elementary.io)
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
 * Authored by: Scott Ringwelski <sgringwe@mtu.edu>
 */

/**
* Base widget displaying an icon, and allowing you to choose between
* various options by clicking on it.
*
* For instance, it's the widget used to choose the repeat mode.
*/
public class Noise.SimpleOptionChooser : Gtk.EventBox {
	private Gee.ArrayList<Gtk.Image> options { get; set; }

    public int current_option { get; private set; }

	public signal void option_changed ();

	construct {
		options = new Gee.ArrayList<Gtk.Image> ();
		current_option = 0;

		// make the event box transparent
		above_child = true;
		visible_window = false;
	}

	public void set_option (int index) {
		if (index >= options.size) {
			return;
		}

        option_changed ();

		if (get_child () != null) {
			remove (get_child ());
		}
		add (options[index]);
		show_all ();

		current_option = index;
	}

	public int append_item (string icon, string tooltip) {
		var image = new Gtk.Image.from_icon_name (icon, Gtk.IconSize.MENU);
		image.set_tooltip_text (tooltip);

		options.add (image);

		return options.size - 1;
	}

	public override bool button_press_event (Gdk.EventButton event) {
		if (event.type == Gdk.EventType.BUTTON_PRESS) {
			var next = current_option + 1 < options.size
				? current_option + 1
				: 0;
			set_option (next);
		}

                option_changed (true); // #true since the user made the change
            } else if (menu != null && items.size > 1) {
                menu.popup (null, null, null, 3, event.time);
            }
        }

        return false;
    }
}
