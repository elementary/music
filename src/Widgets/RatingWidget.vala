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

public class BeatBox.RatingWidget : EventBox {
	internal int rating;
	
	private bool centered;
	private bool menuItem;
	private Pixbuf _canvas;
	private Pixbuf not_starred;
	private Pixbuf starred;
	
	public signal void rating_changed(int new_rating);
	
	public RatingWidget(Color? c, bool centered, bool isMenu) {
		this.centered = centered;
		menuItem = isMenu;
		
		if(c != null)
			modify_bg(StateType.NORMAL, c);
		
		// i hate doing this but it is a must
		starred = BeatBox.Beatbox._program.lm.icons.starred_icon;
		not_starred = BeatBox.Beatbox._program.lm.icons.not_starred_icon;
		
		width_request  = starred.width * 5;
		height_request = starred.height;
		_canvas = new Gdk.Pixbuf(Gdk.Colorspace.RGB, true, 8, width_request, height_request);
		
		set_rating(0);
		updateRating(0);
		
        add_events(Gdk.EventMask.BUTTON_PRESS_MASK
                  | Gdk.EventMask.BUTTON_RELEASE_MASK
                  | Gdk.EventMask.POINTER_MOTION_MASK
                  | Gdk.EventMask.LEAVE_NOTIFY_MASK);
		//motion_notify_event.connect(mouseOver);
		button_press_event.connect(buttonPress);
		draw.connect(exposeEvent);
	}
	
	public override bool leave_notify_event(Gdk.EventCrossing ev)
	{
	    updateRating(rating);
	    return true;
	}
	
	public void set_rating(int new_rating) {
		if(rating == new_rating)
			return;
			
		rating = new_rating;
		updateRating(rating);
		rating_changed(rating);
	}
	
	public int get_rating() {
		return rating;
	}
	
	/* just draw new rating */
	public override bool motion_notify_event(EventMotion event) {
		int new_rating = 0;
		
		Allocation al;
		get_allocation(out al);
		
		int buffer = 0;
		if(centered)
			buffer = (al.width - width_request) / 2;
		else if(menuItem)
			buffer = 32;
		
		if(event.x - buffer > 5)
			new_rating = (int)((event.x - buffer + 18) / 18);
		else
			new_rating = 0;
		
		updateRating(new_rating);
		
		return true;
	}
	
	/* draw new rating AND update rating */
	public virtual bool buttonPress(Gdk.EventButton event) {
		int new_rating = 0;
		
		Allocation al;
		get_allocation(out al);
		
		// buffer for !centered off for new menu problems
		int buffer = 0;
		if(centered)
			buffer = (al.width - width_request) / 2;
		else if(menuItem)
			buffer = 32;
		
		if(event.x - buffer > 5)
			new_rating = (int)((event.x - buffer + 18) / 18);
		else
			new_rating = 0;
		
		set_rating(new_rating);
		
		return true;
	}
	
	public void updateRating(int fake_rating) {
			_canvas.fill((uint) 0xffffff00);
			
			/* generate the canvas image */
			
			for (int i = 0; i < 5; i++) {
				if (i < fake_rating) {
					starred.copy_area(0, 0, starred.width, starred.height, _canvas, i * starred.width, 0);
				}
				else {
					not_starred.copy_area(0, 0, not_starred.width, not_starred.height, _canvas, i * not_starred.width, 0);
				}
			}

			queue_draw();
		}
	
	/** @override on_expose_event to paint our own custom widget **/
	public virtual bool exposeEvent(Cairo.Context cairo) {
		Allocation al;
		get_allocation(out al);
		
		if(centered) {
			Gdk.cairo_set_source_pixbuf(cairo, _canvas, (al.width - width_request) / 2, (al.height - height_request) / 2);
		}
		else {
			Gdk.cairo_set_source_pixbuf(cairo, _canvas, 0, 0);
		}
		
		cairo.paint();
		
		return true;
	}
}
public class BeatBox.RatingWidgetMenu : Gtk.MenuItem {
    RatingWidget rating;
    public bool already_drawn = false;
    public int rating_value{ get{ return rating.get_rating(); } set{rating.set_rating(value); }}
    public RatingWidgetMenu() {
		//holder = new EventBox();
        rating = new RatingWidget(null, false, true);
        //label = new Label("Test test");
        
        //holder.add(rating);
        add(rating);
        
        /*var rgba = get_style_context().get_background_color(StateFlags.NORMAL);
        stdout.printf(rgba.to_string());
        Color c;
        Color.parse(rgba.to_string(), out c);
        stdout.printf(c.to_string());
        rating.modify_bg(StateType.NORMAL, c);*/
        
        //height_request = 20;
        //margin_left = 24;
    }
    
    public override bool motion_notify_event(Gdk.EventMotion ev) {
        rating.motion_notify_event(ev);
        rating.queue_draw();
        return true;
    }
    
    public override bool draw(Cairo.Context context) {
        if(already_drawn) {
			//rating.exposeEvent(context);
		}
		
        already_drawn = true;
        return false;
    }
    
    public override bool button_press_event(Gdk.EventButton ev) {
        rating.button_press_event(ev);
        activate();
        return true;
    }
	public override bool leave_notify_event(Gdk.EventCrossing ev) {
	    rating.updateRating(rating.rating);
	    return true;
	}
}
