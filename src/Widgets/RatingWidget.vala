// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012 Granite Developers (http://launchpad.net/granite)
 *
 * Originally written by Lucas Baudin for BeatBox Music Player
 * BeatBox Music Player: http://launchpad.net/beat-box
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
 *
 * Authored by: Lucas Baudin <xapantu@gmail.com>
 *              Victor Eduardo <victoreduardm@gmail.com>
 */


namespace Granite.Widgets {

public class Rating : Gtk.EventBox {

    public signal void rating_changed (int new_rating);

    private int rating = 0;
    private int hover_rating = 0;
    private int n_stars = 5;
    private int spacing = 0;

    private int item_width = -1;
    private int item_height = -1;

    private bool centered = false;
    protected bool is_menu_item = false;

    private Gdk.Pixbuf _canvas;
    private Gdk.Pixbuf not_starred;
    private Gdk.Pixbuf starred;


    public Rating (Gtk.StyleContext? context, bool centered, Gtk.IconSize size, bool symbolic = false) {
        this.centered = centered;

        if (context != null)  {
            is_menu_item = context.has_class (Gtk.STYLE_CLASS_MENUITEM);
        }

        set_transparent (true);

        // TODO: This needs to be icon-system-independent in order to be included in Granite.
        if (symbolic) {
            starred = Icons.STARRED_SYMBOLIC.render (size, context);
            not_starred = Icons.NOT_STARRED_SYMBOLIC.render (size, context);
        }
        else {
            starred = Icons.STARRED.render (size, null);
            not_starred = Icons.NOT_STARRED.render (size, null);
        }

        // this handles size allocation and connects the draw signal as well
        set_star_spacing (3);

        // force a redraw...
        update_rating (rating);

        add_events(Gdk.EventMask.BUTTON_PRESS_MASK
                  | Gdk.EventMask.BUTTON_RELEASE_MASK
                  | Gdk.EventMask.POINTER_MOTION_MASK
                  | Gdk.EventMask.LEAVE_NOTIFY_MASK);

        button_press_event.connect (on_button_press);
    }

    public Gdk.Pixbuf get_canvas () {
        return _canvas;
    }

    public void set_background_color (Gdk.RGBA color) {
        override_background_color (Gtk.StateFlags.NORMAL, color);
        override_background_color (Gtk.StateFlags.ACTIVE, color);
        override_background_color (Gtk.StateFlags.PRELIGHT, color);
    }

    public void set_transparent (bool val) {
        // Make the eventbox transparent
        this.set_above_child (val);
        this.set_visible_window (!val);
    }

    public void set_star_spacing (int spacing) {
        if (spacing < 0) {
            warning ("Spacing values must be equal or greater than 0");
            return;
        }

        draw.disconnect (on_expose_event);

        this.spacing = spacing;

        // Decide size
        item_width  = (starred.width  > not_starred.width)  ? starred.width  : not_starred.width;
        item_height = (starred.height > not_starred.height) ? starred.height : not_starred.height;

        width_request = item_width * n_stars + spacing * (n_stars - 1);
        height_request = item_height;

        // Generate canvas pixbuf
        _canvas = new Gdk.Pixbuf(Gdk.Colorspace.RGB, true, 8, width_request, height_request);

        draw.connect (on_expose_event);

        update_rating (rating);

        queue_draw ();
    }

    public int get_star_spacing () {
        return spacing;
    }

    public void set_rating (int new_rating) {
        if(rating == new_rating)
            return;

        rating = (new_rating > n_stars) ? n_stars : new_rating;
        update_rating(rating);
        rating_changed(rating);
    }

    public int get_rating () {
        return rating;
    }

    /**
     * Returns the total number of stars. It also represents the maximum possible rating.
     *
     * @return total number of stars.
     */
    public int get_n_stars () {
        return n_stars;
    }

    /**
     * Sets the total number of stars. It also represents the maximum rating possible.
     * That is, possible ratings are between 0 and n_stars.
     *
     * @param n_stars total number of stars. Allowed values: >= 0. Default: 5.
     */
    public void set_n_stars (int n_stars) {
        if (this.n_stars == n_stars)
            return;

        if (n_stars <= 0) {
            warning ("The number of stars must be greater than 0");
            return;
        }

        this.n_stars = n_stars;

        // Validate and potentially redraw current rating just in case...
        set_rating (rating);

        // Allocate new area
        set_star_spacing (this.spacing);

        queue_draw ();
    }


    /** Just draw new rating. Needed by menuitems **/
    public override bool motion_notify_event (Gdk.EventMotion event) {
        hover_rating = get_new_rating (event.x);
        update_rating (hover_rating);
        return true;
    }

    /** draw new rating AND update rating **/
    public virtual bool on_button_press (Gdk.EventButton event) {
        set_rating(hover_rating);
        return true;
    }

    public override bool leave_notify_event (Gdk.EventCrossing ev) {
        update_rating(rating);
        return true;
    }

    internal void update_rating (int fake_rating) {
        if (_canvas == null)
            return;

        _canvas.fill((uint) 0xffffff00);

        /* generate the canvas image */
        for (int i = 0; i < n_stars; i++) {
            if (i < fake_rating)
                starred.copy_area (0, 0, item_width, item_height, _canvas, i * (item_width + (i > 0 ? spacing : 0)), 0);
            else
                not_starred.copy_area (0, 0, item_width, item_height, _canvas, i * (item_width + (i > 0 ? spacing : 0)), 0);
        }

        queue_draw();
    }

    /** @override on_expose_event to paint our own custom widget **/
    public virtual bool on_expose_event (Cairo.Context cairo) {
        Gtk.Allocation al;
        get_allocation(out al);

        if(centered) {
            Gdk.cairo_set_source_pixbuf (cairo, _canvas, (al.width - width_request) / 2, (al.height - height_request) / 2);
        }
        else {
            Gdk.cairo_set_source_pixbuf (cairo, _canvas, 0,  (al.height - height_request) / 2);
        }

        cairo.paint();

        return true;
    }


    /**
     * Returns a new rating value between 0 and n_stars based on the cursor position
     * (relative to the left side of the widget - x=0).
     *
     * LEGEND:
     * X : A STAR
     * - : SPACE
     *
     * |   x_offset   | | spacing | | spacing | | spacing | | spacing  ...  | remaining space...
     * <-------------> X --------- X --------- X --------- X --------- ... X ------------->
     * ... 0 stars    |   1 star  |  2 stars  |  3 stars  |   4 stars  ...| n_stars stars...
     *
     * The first row in the graphic above represents the values involved:
     * - x_offset : the value added in front of the first star.
     * - spacing  : space inserted between stars.
     * - n_stars  : total number of stars. It also represents the maximum rating.
     *
     * If you want the next star to be activated when the cursor is at least halfway
     * towards it, just modify x_offset. It should be similar for other cases as well.
     *
     * For instance:
     *
     *   x_offset = ... // compute offset
     *   x_offset -= spacing / 2;
     *
     * Now the next rating will start halfway earlier, rather than at the start of every star
     * (as shown in the representation above). Don't modify other values for this purpose!
     */

    internal int get_new_rating (double x) {
        int x_offset = 0;

        if (centered) {
            Gtk.Allocation al;
            get_allocation(out al);
            x_offset = (al.width - width_request) / 2;
        }

        if (is_menu_item) // Workaround. Move the offset one star to the left for menuitems.
            x_offset += (item_width + spacing);

        // If you want the next rating (value, not actual star!) to begin in the middle
        // between two stars, use:
        //    x_offset -= (int) ((double)spacing / (1.0 - 1.0 / 2.0));
        // For it to start when the cursor is 2/3 towards the next rating, use:
        //    x_offset -= (int) ((double)spacing * (1.0 - 2.0/3.0));
        // In general:
        //    x_offset -= (int) ((double)spacing * (1.0 - f_num / f_den));

        int cursor_x_pos = (int)x;
        int new_rating = 0;

        for (int i = 0; i < n_stars; i++) {
            if (cursor_x_pos > x_offset + i * (item_width + spacing))
                new_rating ++;
        }

        return new_rating;
    }
}


public class RatingMenuItem : Gtk.MenuItem {

    protected Rating rating;

    public int rating_value {
        get {
            return rating.get_rating();
        }
        set {
            rating.set_rating(value);
        }
    }

    public RatingMenuItem () {
        var style_context = get_style_context ();

        rating = new Rating (style_context, false, Gtk.IconSize.MENU);
        add (rating);


        // These states' theming is obtrusive. This seems to be the right way to get rid of them
        this.state_flags_changed.connect ( () => {
            unset_state_flags (Gtk.StateFlags.ACTIVE);
            unset_state_flags (Gtk.StateFlags.PRELIGHT);
            unset_state_flags (Gtk.StateFlags.FOCUSED);
            unset_state_flags (Gtk.StateFlags.SELECTED);
        });
    }

    public void set_background_color (Gdk.RGBA color) {
        rating.set_background_color (color);
    }

    public void set_transparent (bool val) {
        rating.set_transparent (val);
    }

    public void set_star_spacing (int spacing) {
        rating.set_star_spacing (spacing);
    }

    public int get_rating () {
        return rating.get_rating ();
    }

    public void set_rating (int new_rating) {
        rating.set_rating (new_rating);
    }

    public int get_star_spacing () {
        return rating.get_star_spacing ();
    }

    public void set_n_stars (int n_stars) {
        rating.set_n_stars (n_stars);
    }

    public int get_n_stars () {
        return rating.get_n_stars ();
    }

    /**
     * /!\ Don't use these methods
     */

    public override bool motion_notify_event(Gdk.EventMotion ev) {
        rating.motion_notify_event (ev);
        rating.queue_draw();
        return true;
    }

    public override bool button_press_event(Gdk.EventButton ev) {
        rating.button_press_event(ev);
        activate();
        return true;
    }

    public override bool leave_notify_event(Gdk.EventCrossing ev) {
        rating.update_rating (rating_value);
        return true;
    }
}

public class CellRendererRating : Gtk.CellRendererPixbuf {

    /** Only emmited when the rating changes by clicking over the cellrenderer **/
    public signal void rating_changed (int new_rating, Gtk.Widget widget, string path,
                                         Gtk.CellRendererState flags);

    /**
     * This class is here to make setting the rating from a cell possible.
     * Unlike the other widgets, it only allows doing so by clicking over a
     * star, and it's not possible to get an in-hover preview.
     *
     * We use a normal rating widget. It does the drawing and all we need
     * internally and after that we set the rendered image as this cell renderer's
     * pixbuf.
     */
    protected Rating? rating = null;

    public CellRendererRating (Gtk.IconSize icon_size = Gtk.IconSize.MENU) {
        rating = new Rating (null, false, icon_size);
        this.pixbuf = rating.get_canvas ();

        xalign = 0.0f; // left-aligned

        // Make this cell renderer activatable. This allows receiving click (activate) events.
        this.mode = Gtk.CellRendererMode.ACTIVATABLE;
    }

    /** Common Rating API functions **/

    public void set_star_spacing (int spacing) {
        rating.set_star_spacing (spacing);
        this.pixbuf = rating.get_canvas ();
        this.width = this.pixbuf.width;
    }

    public int get_star_spacing () {
        return rating.get_star_spacing ();
    }

    public int get_rating () {
        return rating.get_rating ();
    }

    public void set_rating (int new_rating) {
        rating.set_rating (new_rating);
        this.pixbuf = rating.get_canvas ();
    }

    public void set_n_stars (int n_stars) {
        rating.set_n_stars (n_stars);
        this.pixbuf = rating.get_canvas ();
        this.width = this.pixbuf.width;
    }

    public int get_n_stars () {
        return rating.get_n_stars ();
    }

    /** Handles activate events (clicks) **/
    public override bool activate (Gdk.Event event, Gtk.Widget widget, string path,
                                      Gdk.Rectangle background_area, Gdk.Rectangle cell_area,
                                      Gtk.CellRendererState flags)
    {
        int new_rating = rating.get_new_rating (event.button.x - (double) cell_area.x);

        // Don't re-draw automatically since doing so modifies the entire treeview column.
        // Let's pass off the responsability to the rating_changed signal handler
        // rating.set_rating (new_rating);
        //this.pixbuf = rating.get_canvas ();

        // emit signal
        rating_changed (new_rating, widget, path, flags);

        return true;
    }
}

}

