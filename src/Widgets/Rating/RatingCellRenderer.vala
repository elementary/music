/*-
 * Copyright (c) 2012-2018 elementary LLC. (https://elementary.io)
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
 * Authored by: Lucas Baudin <xapantu@gmail.com>,
 *              Victor Eduardo <victoreduardm@gmail.com>
 */

/**
 * This class makes setting the rating from a cell possible. Unlike the other widgets,
 * it only allows doing so by clicking over a star.
 *
 * When the rating changes by activating (i.e. clicking) the cell renderer, it doesn't re-draw itself
 * automatically and/or apply the new rating right away, since there could be client code wanting
 * to check the new value. Instead, it passes the responsability off to the rating_changed signal handler.
 * That signal handler *must* take care of setting the new rating on the proper cell, and only then
 * the new value will take effect.
 */
public class Music.RatingCellRenderer : Gtk.CellRendererPixbuf {
    /**
     * The rating was set. It is only emmited when the rating changes by activating the renderer.
     */
    public signal void rating_changed (int new_rating, Gtk.Widget widget, string path);

    private RatingWidget.Renderer renderer;

    public RatingCellRenderer (Gtk.IconSize icon_size = Gtk.IconSize.MENU) {
        this.xalign = 0.0f;
        this.mode = Gtk.CellRendererMode.ACTIVATABLE;

        renderer = new RatingWidget.Renderer (icon_size, true, null);

        // We'll only redraw from render() for performance reasons
        renderer.delayed_render_mode = true;

        // Set rating to 1 star and render to init the 'width' property
        rating = 1;
        renderer.render ();
        update_pixbuf ();
    }

    public int star_spacing {
        get { return renderer.star_spacing; }
        set { renderer.star_spacing = value; }
    }

    private uint _rating = 0;
    public uint rating {
        get { return _rating; }
        set {
            _rating = value;
            renderer.rating = _rating;
        }
    }

    public int n_stars {
        get { return renderer.n_stars; }
        set { renderer.n_stars = value; }
    }

    private void update_pixbuf () {
        this.pixbuf = renderer.canvas;
        this.set_fixed_size (this.pixbuf.width, this.pixbuf.height);
    }

    public override void render (Cairo.Context ctx, Gtk.Widget widget, Gdk.Rectangle background_area, Gdk.Rectangle cell_area, Gtk.CellRendererState flags) {
        var style_context = widget.get_style_context ();
        var state = style_context.get_state ();
        int old_n_stars = n_stars;

        // Only draw stars of 0-rating if the cursor is over the cell
        if (_rating == 0 && ((state & Gtk.StateFlags.SELECTED) != state) && ((state & Gtk.StateFlags.PRELIGHT) != state)) {
            return;
        }

        // Only show the filled stars if the row is neither selected nor mouseovered
        if (0 < _rating && ((state & Gtk.StateFlags.SELECTED) != state) && ((state & Gtk.StateFlags.PRELIGHT) != state)) {
            n_stars = (int)rating;
        }

        renderer.style_context = style_context;
        renderer.render ();
        update_pixbuf ();
        base.render (ctx, widget, background_area, cell_area, flags);
        n_stars = old_n_stars;
    }

    public override bool activate (Gdk.Event event, Gtk.Widget widget, string path, Gdk.Rectangle background_area, Gdk.Rectangle cell_area, Gtk.CellRendererState flags) {
        int old_rating = (int) rating;
        int new_rating = renderer.get_new_rating (event.button.x - cell_area.x);

        // If the user clicks again over the same star, decrease the rating (i.e. "unset" the star)
        if (new_rating == old_rating && new_rating > 0)
            new_rating--;

        // emit signal
        rating_changed (new_rating, widget, path);

        return true;
    }
}
