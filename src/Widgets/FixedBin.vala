/*-
 * Copyright (c) 2012       Victor Eduardo <victoreduardm@gmail.com>
 *                          Marcus Lundgren <marcus.lundgren@gmail.com>
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

// FixedBin
// This containers allows to set maximum and minimun dimensions
// for expandable child widgets (widget.hexpand = widget.vexpand = true).
// For it to work properly, the child widget *must not* allocate a bigger
// size than the maximum allowed by this container, or it will fail.
public class FixedBin : Gtk.EventBox {
    // Size constraints. Use a negative value to mean "unset".
    public int max_width  { get; private set; default = -1; }
    public int max_height { get; private set; default = -1; }
    public int min_width  { get; private set; default = -1; }
    public int min_height { get; private set; default = -1; }
    
    public FixedBin (int min_width = -1, int min_height = -1,
                     int max_width = -1, int max_height = -1,
                     bool visible_window = false)
    {
        //hexpand = true;
        set_min_dimensions (min_width, min_height);
        set_max_dimensions (max_width, max_height);

        this.visible_window = visible_window;
    }

    /**
     * PUBLIC API
     */

    public void set_widget (Gtk.Widget widget, bool hexpand = true,
                            bool vexpand = true) {
        widget.hexpand = hexpand;
        widget.vexpand = vexpand;

        var child = get_child ();
        if (child != null)
            remove (child);

        add (widget);
    }

    public void set_min_dimensions (int min_width, int min_height) {
        this.min_width = min_width;
        this.min_height = min_height;
        queue_resize ();
    }

    public void set_max_dimensions (int max_width, int max_height) {
        this.max_width = max_width;
        this.max_height = max_height;
        queue_resize ();
    }
    
    /**
     * INTERNAL GEOMETRY MANAGEMENT
     */
    
    public override Gtk.SizeRequestMode get_request_mode () {
        return Gtk.SizeRequestMode.HEIGHT_FOR_WIDTH;
    }
    
    public override void get_preferred_width (out int minimum_width, out int natural_width) {
        // TODO
        // - Check what has been allocated to this
        // - If the widget is set to expand, then simply set the padding
        //   of the child to compensate it getting larger than it should
        base.get_preferred_width (out minimum_width, out natural_width);

        int ch_min_width, ch_nat_width;
        get_child ().get_preferred_width (out ch_min_width, out ch_nat_width);

        int allocated_width = get_allocated_width ();
        
        stdout.printf("BEFOR - MIN_WIDTH: <%d> NATURAL_WIDTH: <%d>\n", minimum_width, natural_width);
        stdout.printf("ALLOC - WIDTH: <%d>\n", allocated_width);
        // We have minimum width set, see if it should be used
        if (this.min_width > 0) {
            minimum_width = this.min_width;
            // If the widget wants a smaller width than the minimum,
            // then force it to be the minimum one
            //if (natural_width < minimum_width)
            //    natural_width = minimum_width;
        }
        
        // We have a maximum width set and the natural width exceeds it
        if (this.max_width > 0) {
            //if (this.max_width < natural_width)
            //    natural_width = this.max_width;
            if (this.max_width < allocated_width)
            {
                int padding_width = (allocated_width - this.max_width) / 2;
                //get_child ().adjust_size_request(Gtk.Orientation.HORIZONTAL, ref new_width, ref new_width);
                get_child ().margin_left = padding_width;
                get_child ().margin_right = padding_width;
                //minimum_width = this.max_width;
            }
        }
        int new_width = this.max_width;
        
        stdout.printf("AFTER - MIN_WIDTH: <%d> NATURAL_WIDTH: <%d> NEW_WIDTH: <%d>\n", minimum_width, natural_width, new_width);
    }
    
    /*public override void get_preferred_height_for_width (int width, out int minimum_height,
                                                         out int natural_height)
    {
        // TODO ?
        base.get_preferred_height_for_width (width, out minimum_height, out natural_height);
        }*/
}
