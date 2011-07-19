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

public class BeatBox.RatingWidget : EventBox {
	internal int rating;
	
	private bool centered;
	private Pixbuf _canvas;
	private Pixbuf not_starred;
	private Pixbuf starred;
	
	public signal void rating_changed(int new_rating);
	
	public RatingWidget(Color? c, bool centered) {
		this.centered = centered;
		
		if(c != null)
			modify_bg(StateType.NORMAL, c);
		
		starred = this.render_icon("starred", IconSize.SMALL_TOOLBAR, null);
		not_starred = this.render_icon("not-starred", IconSize.SMALL_TOOLBAR, null);
		
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
		
		int buffer = (al.width - width_request)/2;
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
		
		int buffer = (al.width - width_request)/2;
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
		if(centered) {
			Gdk.cairo_set_source_pixbuf(cairo, _canvas, 0, 0);
		}
		else {
			Gdk.cairo_set_source_pixbuf(cairo, _canvas, 0, 0);
		}
		return true;
	}
}
public class BeatBox.RatingWidgetMenu : Gtk.MenuItem
{
    RatingWidget rating;
    public bool already_drawn = false;
    public int rating_value{ get{ return rating.get_rating(); } set{rating.set_rating(value); }}
    public RatingWidgetMenu()
    {
        rating = new RatingWidget(null, false);
        add(rating);
    }
    
    public override bool motion_notify_event(Gdk.EventMotion ev)
    {
        rating.motion_notify_event(ev);
        //rating.queue_draw();
        return false;
    }
    
    public override bool draw(Cairo.Context context)
    {
        if(already_drawn)
        rating.exposeEvent(context);
        already_drawn = true;
        return true;
    }
    
    public override bool button_press_event(Gdk.EventButton ev)
    {
        rating.button_press_event(ev);
        activate();
        return true;
    }
	public override bool leave_notify_event(Gdk.EventCrossing ev)
	{
	    rating.updateRating(rating.rating);
	    return true;
	}
}
