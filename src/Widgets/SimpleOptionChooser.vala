/*-
 * Copyright (c) 2011-2012	   Scott Ringwelski <sgringwe@mtu.edu>
 *
 * Originally Written by Scott Ringwelski for BeatBox Music Player
 * BeatBox Music Player: http://www.launchpad.net/beat-box
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
 */

public class Noise.SimpleOptionChooser : Gtk.EventBox {
	Gtk.Menu? menu = null;
	public Gee.LinkedList<Gtk.RadioMenuItem> items;
	public Gee.LinkedList<Gtk.Image> images;

	int clicked_index;
	int previous_index; // for left click
	bool toggling;

    public int current_option { get { return clicked_index; } }

	public signal void option_changed (bool by_user = false);

    private bool menu_only_mode;

	public SimpleOptionChooser (bool menu_only_mode = false) {
        this.menu_only_mode = menu_only_mode;

		items = new Gee.LinkedList<Gtk.RadioMenuItem>();
		images = new Gee.LinkedList<Gtk.Image>();
		toggling = false;

		clicked_index = 0;
		previous_index = 0;

		// make the event box transparent
		set_above_child(true);
		set_visible_window(false);
	}

	public void setOption(int index, bool notify = true) {
		if(index >= items.size)
			return;

		items.get(index).set_active(true);

		clicked_index = index;

        if (notify)
    		option_changed ();

		if (get_child () != null)
			remove (get_child ());

		add (images.get(index));

		show_all ();
	}

	public int appendItem(string text, Gtk.Image image, string tooltip) {
		if (menu == null)
			menu = new Gtk.Menu();

		Gtk.RadioMenuItem item;
		if (items.size == 0)
		    item = new Gtk.RadioMenuItem.with_label(new SList<Gtk.RadioMenuItem>(), text);
	    else
	        item = new Gtk.RadioMenuItem.with_label_from_widget (items.get(0), text);
		Gtk.Image item_image = image;
		image.set_tooltip_text (tooltip);
		items.add(item);
		images.add(item_image);
		menu.append(item);

		item.toggled.connect( () => {
            if (!item.active)
                return;

    		setOption (items.index_of (item));
		});

		item.show();
		previous_index = items.size - 1; // my lazy way of making sure the bottom item is the default on/off on click

		return items.size - 1;
	}

	public override bool button_press_event (Gdk.EventButton event) {
		if (event.type == Gdk.EventType.BUTTON_PRESS) {
			if(event.button == 1 && !menu_only_mode) {
				// Silently set the options. We emit the option_changed signal below.
				if(clicked_index == 0) {
					setOption(previous_index, false);
				}
				else {
					previous_index = clicked_index;
					setOption(0, false);
				}

				option_changed (true); // #true since the user made the change
			}
			else if (menu != null && items.size > 1) {
				menu.popup (null, null, null, 3, event.time);
			}
		}

		return false;
	}

}

