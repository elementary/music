/*-
 * Copyright (c) 2012       Victor Eduardo <victoreduardm@gmail.com>
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
                     int max_width = -1, int max_height = -1)
    {

        set_min_dimensions (min_width, min_height);
        set_max_dimensions (max_width, max_height);
    }

    /**
     * PUBLIC API
     */

    public void set_widget (Gtk.Widget widget, bool expand = true) {
        if (expand)
            widget.hexpand = widget.vexpand = true;

        var child = get_child ();
        if (child != null)
            remove (child);

        add (widget);
    }

    public void set_min_dimensions (int min_width, int min_height)
    {
        return_if_fail (min_width

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

        public override void get_preferred_width (out int? minimum_width, out int? natural_width) {
            base.get_preferred_width (out minimum_width, out natural_width);
            if (this.min_width > 0) {
                minimum_width = this.min_width;
                if (natural_width < minimum_width)
                    natural_width = minimum_width;
            }

            // TODO
        }

        public override void get_preferred_height_for_width (int width, out int? minimum_height,
                                                             out int? natural_height)
        {
            // TODO
        }
    }
    