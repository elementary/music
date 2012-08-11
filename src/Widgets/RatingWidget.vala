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

    private bool _symbolic = false;
    public bool symbolic {
        get { return _symbolic; }
        set { _symbolic = value; render_stars (); }
    }

    private Gtk.IconSize _icon_size = Gtk.IconSize.MENU;
    public Gtk.IconSize icon_size {
        get { return _icon_size; }
        set { _icon_size = value; render_stars (); }
    }

    private Gtk.StyleContext? _style_context = null;
    public Gtk.StyleContext? style_context {
        get {
            return _style_context;
        }
        set {
            _style_context = value ?? get_style_context ();
            style_context.changed.connect (render_stars);
            redraw ();
        }
    }

    public Gdk.RGBA background_color {
        set {
            transparent = false;
            var flags = Gtk.StateFlags.NORMAL | Gtk.StateFlags.ACTIVE | Gtk.StateFlags.PRELIGHT;
            override_background_color (flags, value);
            redraw ();
        }
    }

    public bool transparent {
        set {
            // Make the eventbox transparent
            this.set_above_child (value);
            this.set_visible_window (!value);
        }
    }

    /**
     * Total number of stars. It also represents the maximum rating possible.
     * That is, possible ratings are between 0 and n_stars.
     *
     * Allowed values: >= 0. Default: 5.
     */
    private int _n_stars = 5;
    public int n_stars {
        get {
            return _n_stars;
        }
        set {
            if (n_stars == value)
                return;

            _n_stars = (value >= 1) ? value : 1;

            // Validate and potentially redraw current rating
            rating = _rating;

            // Allocate new area
            star_spacing = _star_spacing;

            redraw ();
        }
    }

    int _star_spacing = 3;
    public int star_spacing {
        get {
            return _star_spacing;
        }
        set {
            draw.disconnect (on_expose_event);

            _star_spacing = (value < 0) ? 0 : value;

            // Decide size
            item_width  = (starred.width  > not_starred.width)  ? starred.width  : not_starred.width;
            item_height = (starred.height > not_starred.height) ? starred.height : not_starred.height;

            width_request = item_width * n_stars + star_spacing * (n_stars - 1);
            height_request = item_height;

            // Generate canvas pixbuf
            canvas = new Gdk.Pixbuf (Gdk.Colorspace.RGB, true, 8, width_request, height_request);

            draw.connect (on_expose_event);

            redraw ();
        }
    }

    private int _rating = 0;
    public int rating {
        get {
            return _rating;
        }
        set {
            _rating = (value > n_stars) ? n_stars : ((value < 0) ? 0 : value);
            update_rating (rating);
        }
    }

    public double rating_offset { get; set; default = 0.0; }

    internal Gdk.Pixbuf canvas { get; private set; }

    public int hover_rating { get; private set; default = 0; }
    public int item_width   { get; private set; default = 0; }
    public int item_height  { get; private set; default = 0; }

    private bool _centered = false;
    public bool centered {
        get {
            return _centered;
        }
        set {
            _centered = value;
            redraw ();
        }
    }

    private Gdk.Pixbuf not_starred;
    private Gdk.Pixbuf starred;

    public Rating (bool centered, Gtk.IconSize size, bool symbolic = false, Gtk.StyleContext? ctx = null) {
        this.centered = centered;
        this.style_context = ctx;
        this.symbolic = symbolic;
        this.icon_size = size;
        this.transparent = true;
        this.n_stars = 5;
        this.star_spacing = 3; // this handles size allocation and connects the draw signal as well
        this.rating = 0;

        add_events (Gdk.EventMask.BUTTON_PRESS_MASK |
                    Gdk.EventMask.BUTTON_RELEASE_MASK |
                    Gdk.EventMask.POINTER_MOTION_MASK |
                    Gdk.EventMask.LEAVE_NOTIFY_MASK);

        state_flags_changed.connect (render_stars);
    }

    private void render_stars () {
        // TODO: This needs to be icon-system-independent in order to be included in Granite.
        if (symbolic) {
            starred = Icons.STARRED_SYMBOLIC.render (icon_size, style_context);
            not_starred = Icons.NOT_STARRED_SYMBOLIC.render (icon_size, style_context);
        }
        else {
            starred = Icons.STARRED.render (icon_size, null);
            not_starred = Icons.NOT_STARRED.render (icon_size, null);
        }

        redraw ();
    }

    public void redraw () {
        // No need to duplicate code. update_rating() does exactly this
        // and also calls queue_draw().
        update_rating (rating);    
    }

    /** Just draw new rating. Needed by menuitems **/
    public override bool motion_notify_event (Gdk.EventMotion event) {
        hover_rating = get_new_rating (event.x);
        update_rating (hover_rating);
        return true;
    }

    /** draw new rating AND update rating **/
    public override bool button_press_event (Gdk.EventButton event) {
        rating = hover_rating;
        rating_changed (rating);
        return true;
    }

    public override bool leave_notify_event (Gdk.EventCrossing ev) {
        update_rating (rating);
        return true;
    }

    internal void update_rating (int fake_rating) {
        if (canvas == null)
            return;

        canvas.fill ((uint)0xffffff00);

        /* generate the canvas image */
        for (int i = 0; i < n_stars; i++) {
            if (i < fake_rating)
                starred.copy_area (0, 0, item_width, item_height, canvas,
                                   i * (item_width + (i > 0 ? star_spacing : 0)), 0);
            else
                not_starred.copy_area (0, 0, item_width, item_height, canvas,
                                       i * (item_width + (i > 0 ? star_spacing : 0)), 0);
        }

        queue_draw ();
    }

    /** @override on_expose_event to paint our own custom widget **/
    public virtual bool on_expose_event (Cairo.Context cairo) {
        Gtk.Allocation al;
        get_allocation (out al);

        if (centered) {
            Gdk.cairo_set_source_pixbuf (cairo, canvas, (al.width - width_request) / 2,
                                         (al.height - height_request) / 2);
        }
        else {
            Gdk.cairo_set_source_pixbuf (cairo, canvas, 0,  (al.height - height_request) / 2);
        }

        cairo.paint ();

        return true;
    }


    /**
     * Returns a new rating value between 0 and n_stars, based on the cursor position
     * relative to the left side of the widget (x = 0).
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
     * - spacing  : space inserted between stars (star_spacing).
     * - n_stars  : total number of stars. It also represents the maximum rating.
     *
     * As you can see, you can modify the placement of the invisible value separators ("|")
     * by changing the value of x_offset. For instance, if you wanted the next star to be activated
     * when the cursor is at least halfway towards it, just modify x_offset. It should be similar
     * for other cases as well. 'rating_offset' uses exactly that mechanism to apply its value.
     */
    internal int get_new_rating (double x) {
        int x_offset = 0;

        if (centered) {
            Gtk.Allocation al;
            get_allocation (out al);
            x_offset = (al.width - width_request) / 2;
        }

        x_offset -= (int)rating_offset;

        int cursor_x_pos = (int)x;
        int new_rating = 0;

        for (int i = 0; i < n_stars; i++) {
            if (cursor_x_pos > x_offset + i * (item_width + star_spacing))
                new_rating ++;
        }

        return new_rating;
    }
}


public class RatingMenuItem : Gtk.MenuItem {

    public Rating rating { get; private set; }

    public int rating_value {
        get { return rating.rating; }
        set { rating.rating = value; }
    }

    public RatingMenuItem () {
        rating = new Rating (false, Gtk.IconSize.MENU, false);
        add (rating);

        // Workaround. Move the offset one star to the left for menuitems.
        rating.rating_offset = -(double)rating.item_width - (double)rating.star_spacing;

        this.state_flags_changed.connect ( () => {
            // Suppress SELECTED and PRELIGHT states, since these are usually obtrusive
            var selected_flags = Gtk.StateFlags.SELECTED | Gtk.StateFlags.PRELIGHT;
            if ((get_state_flags() & selected_flags) != 0)
                unset_state_flags (selected_flags);
        });
    }

    public override bool motion_notify_event (Gdk.EventMotion ev) {
        rating.motion_notify_event (ev);
        rating.queue_draw ();
        return true;
    }

    public override bool button_press_event (Gdk.EventButton ev) {
        rating.button_press_event (ev);
        activate ();
        return true;
    }

    public override bool leave_notify_event (Gdk.EventCrossing ev) {
        rating.update_rating (rating_value);
        return true;
    }
}

public class CellRendererRating : Gtk.CellRendererPixbuf {

    /** Only emmited when the rating changes by clicking over the cellrenderer **/
    public signal void rating_changed (int new_rating, Gtk.Widget widget, string path);

    /**
     * This class is here to make setting the rating from a cell possible.
     * Unlike the other widgets, it only allows doing so by clicking over a
     * star, since it's not possible to get an in-hover preview (it actually is
     * but that would require this widget to be aware of the GtkTreeView or other
     * widget containing it. We will implement that later).
     *
     * We use a normal rating widget. It does the drawing and processing internally,
     * and after that, we set the rendered image as this cell renderer's pixbuf.
     *
     * When the rating changes by activating (i.e. clicking) the cell renderer, we
     * don't re-draw automatically and/or apply the new rating right away, since there
     * could be client code wanting to check the new value. So we pass the responsability
     * off to the rating_changed signal handler. That signal handler *must* take care of
     * setting the new rating on the proper cell, and only then the new value will take effect.
     */
    protected Rating? rating_widget = null;

    public CellRendererRating (Gtk.IconSize icon_size = Gtk.IconSize.MENU) {
        rating_widget = new Rating (false, icon_size, true);
        this.xalign = 0.0f; // left-aligned
        update_pixbuf ();

        // Make this cell renderer activatable. This allows receiving click (activate) events.
        this.mode = Gtk.CellRendererMode.ACTIVATABLE;
    }

    /** Common Rating API functions **/
    public int star_spacing {
        get { return rating_widget.star_spacing; }
        set { rating_widget.star_spacing = value; update_pixbuf (); }
    }

    public int rating {
        get { return rating_widget.rating; }
        set { rating_widget.rating = value; update_pixbuf (); }
    }

    public int n_stars {
        get { return rating_widget.n_stars; }
        set { rating_widget.n_stars = value; update_pixbuf (); }
    }

    private void update_pixbuf () {
        this.pixbuf = rating_widget.canvas;
        this.width = this.pixbuf.width;
    }

    public override void render (Cairo.Context ctx, Gtk.Widget widget,
                                 Gdk.Rectangle background_area, Gdk.Rectangle cell_area,
                                 Gtk.CellRendererState flags)
    {
        rating_widget.style_context = widget.get_style_context ();

        if ((flags & Gtk.CellRendererState.SELECTED) != 0)
            rating_widget.set_state_flags (Gtk.StateFlags.SELECTED, false);
        else
            rating_widget.unset_state_flags (Gtk.StateFlags.SELECTED);

        if ((flags & Gtk.CellRendererState.FOCUSED) != 0)
            rating_widget.set_state_flags (Gtk.StateFlags.FOCUSED, false);
        else
            rating_widget.unset_state_flags (Gtk.StateFlags.FOCUSED);

        if ((flags & Gtk.CellRendererState.PRELIT) != 0)
            rating_widget.set_state_flags (Gtk.StateFlags.PRELIGHT, false);
        else
            rating_widget.unset_state_flags (Gtk.StateFlags.PRELIGHT);

        update_pixbuf ();
        base.render (ctx, widget, background_area, cell_area, flags);
    }

    /**
     * Handles activate events (clicks)
     */
    public override bool activate (Gdk.Event event, Gtk.Widget widget, string path,
                                   Gdk.Rectangle background_area, Gdk.Rectangle cell_area,
                                   Gtk.CellRendererState flags)
    {
        int old_rating = rating;
        int new_rating = rating_widget.get_new_rating (event.button.x - (double) cell_area.x);

        // If the user clicks again over the same star, decrease the rating (i.e. "unset" the star)
        if (new_rating == old_rating)
            new_rating--;

        // emit signal
        rating_changed (new_rating, widget, path);

        return true;
    }
}

}
