/*-
 * Copyright (c) 2011       Scott Ringwelski <sgringwe@mtu.edu>
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
	Menu menu;
	LinkedList<CheckMenuItem> items;
	Pixbuf enabled;
	Pixbuf disabled;
	
	int clicked_index;
	int previous_index; // for left click
	bool toggling;
	
	public signal void option_changed(int index);
	
	public SimpleOptionChooser(Pixbuf enabled, Pixbuf disabled) {
		this.enabled = enabled;
		this.disabled = disabled;
		menu = new Menu();
		items = new LinkedList<CheckMenuItem>();
		toggling = false;
		
		width_request  = (enabled.width > disabled.width) ? enabled.width : disabled.width;
		height_request = (enabled.height > disabled.height) ? enabled.height : disabled.height;
		
		clicked_index = 0;
		previous_index = 0;
		
		// make the background white
		Gdk.Color c = Gdk.Color();
		Gdk.Color.parse("#FFFFFF", out c);
		modify_bg(StateType.NORMAL, c);
		
		button_press_event.connect(buttonPress);
		draw.connect(exposeEvent);
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
		
		queue_draw();
	}
	
	public int appendItem(string text) {
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
		if(event.type == Gdk.EventType.BUTTON_PRESS && event.button == 1) {
			if(clicked_index == 0)
				setOption(previous_index);
			else {
				previous_index = clicked_index;
				setOption(0);
			}
		}
		else if(event.type == Gdk.EventType.BUTTON_PRESS && event.button == 3) {
			menu.popup (null, null, null, 3, get_current_event_time());
		}
		
		return false;
	}
	
	public virtual bool exposeEvent(Cairo.Context context) {
		Gdk.cairo_set_source_pixbuf(context, (clicked_index != 0) ? enabled : disabled, 0, 0);
		context.paint();
		
		return true;
	}
}
