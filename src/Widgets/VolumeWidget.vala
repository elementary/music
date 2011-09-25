/*-
 * Copyright (c) 2011       Scott Ringwelski <sgringwe@mtu.edu>
 *
 * Originaly Written by Scott Ringwelski for BeatBox Music Player
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

public class BeatBox.VolumeWidget: HBox {
	Gtk.Image noSound;
	Gtk.Image fullSound;
	Gtk.HScale scale;
	
	public VolumeWidget() {
		noSound = new Gtk.Image.from_stock("", IconSize.MENU);
		fullSound = new Gtk.Image.from_stock("", IconSize.MENU);
		scale = new HScale.with_range(0.0, 100.0, 5.0);
		
		pack_start(noSound, false, false, 0);
		pack_start(scale, true, true, 0);
		pack_start(fullSound, false, false, 0);
		
		scale.draw_value = false;
		scale.set_value(50.0);
	}
}

public class BeatBox.VolumeMenuItem : Gtk.MenuItem
{
    VolumeWidget vol;
    
    public VolumeMenuItem() {
        vol = new VolumeWidget();
        add(vol);
    }
    
    /* stop the menu from closing on click */
    public override bool button_press_event(Gdk.EventButton ev) {
		stdout.printf("button_press_event\n");
        return true;
    }
    
    public virtual bool button_release_event (EventButton event) {
		stdout.printf("button_release_event\n");
		return true;
	}
    
}
