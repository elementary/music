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

using Gtk;
using Gdk;
using Gee;

public class BeatBox.SimpleOptionChooser : EventBox {
	Gtk.Menu? menu = null;
	LinkedList<CheckMenuItem> items;
	Gtk.Image enabled;
	Gtk.Image disabled;

	int clicked_index;
	int previous_index; // for left click
	bool toggling;

	public signal void option_changed(int index);

	public SimpleOptionChooser.from_pixbuf (Pixbuf enabled, Pixbuf? disabled = null) {
		this.enabled = new Image.from_pixbuf (enabled);
		this.disabled = new Image.from_pixbuf (disabled ?? enabled);

		initialize ();
	}

	public SimpleOptionChooser.from_image (Gtk.Image enabled, Gtk.Image? disabled = null) {
		this.enabled = enabled;
		this.disabled = disabled ?? enabled;

		initialize ();
	}

	private void initialize () {
		items = new LinkedList<CheckMenuItem>();
		toggling = false;

		clicked_index = 0;
		previous_index = 0;

		// make the event box transparent
		set_above_child(true);
		set_visible_window(false);

		button_press_event.connect(buttonPress);

		set_image ();
	}

	public void setTooltip (string enabled_tooltip, string? disabled_tooltip = null) {
		enabled.set_tooltip_text (enabled_tooltip);
		disabled.set_tooltip_text (disabled_tooltip ?? enabled_tooltip);
	}

	public void setOption(int index) {
		if(index >= items.size)
			return;

		for(int i = 0;i < items.size; ++i) {
			if(i == index)
				items.get(i).set_active(true);
			else
				items.get(i).set_active(false);
		}

		clicked_index = index;
		option_changed(index);

		set_image ();
	}

	public int appendItem(string text) {
		if (menu == null)
			menu = new Gtk.Menu();

		var item = new CheckMenuItem.with_label(text);
		items.add(item);
		menu.append(item);

		item.toggled.connect( () => {
			if(!toggling) {
				toggling = true;

				if(clicked_index != items.index_of(item))
					setOption(items.index_of(item));
				else
					setOption(0);

				toggling = false;
			}
		});

		item.show();
		previous_index = items.size - 1; // my lazy way of making sure the bottom item is the default on/off on click

		return items.size - 1;
	}

	public virtual bool buttonPress(Gdk.EventButton event) {
		if (event.type == Gdk.EventType.BUTTON_PRESS) {
			if(event.button == 1) {
				if(clicked_index == 0) {
					setOption(previous_index);
				}
				else {
					previous_index = clicked_index;
					setOption(0);
				}
			}
			else if(event.button == 3 && menu != null) {
				menu.popup (null, null, null, 3, get_current_event_time());
			}
		}

		return false;
	}

	private void set_image () {
		if (get_child () != null)
			remove (get_child ());

		if (clicked_index != 0)
			add (enabled);
		else
			add (disabled);

		show_all ();
	}
}

