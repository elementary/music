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
* various options, through a menu, or by clicking on it.
*
* For instance, it's the widget used in the status bar (at the bottom
* of the main window) to choose the repeat mode.
*/
public class Noise.SimpleOptionChooser : Gtk.EventBox {
	private class SimpleOption : Object {
		public Gtk.Image icon { get; construct set; }
		public Gtk.RadioMenuItem menu_item { get; construct set; }
		public bool click_accessible { get; construct set; }

		public SimpleOption (Gtk.Image icon, Gtk.RadioMenuItem item, bool click_accessible) {
			Object (icon: icon, menu_item: item, click_accessible: click_accessible);
		}
	}

	Gtk.Menu menu;
	private Gee.ArrayList<SimpleOption> options { get; set; }

	int clicked_index = 0;

    public int current_option { get { return clicked_index; } }

	public signal void option_changed (bool by_user);

    public bool menu_only_mode { get; construct set; }

	public SimpleOptionChooser (bool menu_only_mode = false) {
		Object (menu_only_mode: menu_only_mode);
	}

	construct {
		menu = new Gtk.Menu ();
		options = new Gee.ArrayList<SimpleOption> ();

		// make the event box transparent
		above_child = true;
		visible_window = false;
	}

	public void set_option (int index, bool by_user = false) {
		if (index >= options.size) {
			return;
		}

		options[index].menu_item.active = true;

        if (notify) {
            option_changed ();
        }

		option_changed (by_user);

		if (get_child () != null) {
			remove (get_child ());
		}

		add (options[index].icon);

    public int append_item (string text, string icon_name, string tooltip) {
        Gtk.RadioMenuItem item;

	public int append_item (string text, string icon, string tooltip, bool click_accessible = false) {
		Gtk.RadioMenuItem item = options.size == 0
			? new Gtk.RadioMenuItem.with_label(new SList<Gtk.RadioMenuItem> (), text)
	     	: new Gtk.RadioMenuItem.with_label_from_widget (options[0].menu_item, text);

		menu.append (item);


		var image = new Gtk.Image.from_icon_name (icon, Gtk.IconSize.MENU);
		image.set_tooltip_text (tooltip);

		var option = new SimpleOption (image, item, click_accessible);
		options.add (option);

		item.toggled.connect (() => {
			if (item.active) {
				set_option (options.index_of (option));
			}
		});
		item.show ();

		return options.size - 1;
	}

	public override bool button_press_event (Gdk.EventButton event) {
		if (event.type == Gdk.EventType.BUTTON_PRESS) {
			if (event.button == 1 && !menu_only_mode) {
				// Find the next click-activable item
				for (int i = clicked_index + 1; i != clicked_index; i++) {
					if (i >= options.size) {
						i = 0;
					}

					if (options[i].click_accessible) {
						set_option (i, true);
						break;
					}
				}
			} else if (options.size > 1) {
				menu.popup (null, null, null, 3, event.time);
			}
		}

                option_changed (true); // #true since the user made the change
            } else if (menu != null && items.size > 1) {
                menu.popup (null, null, null, 3, event.time);
            }
        }

        return false;
    }
}
