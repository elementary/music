// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012-2017 elementary LLC. (https://elementary.io)
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
 */

public class Noise.Widgets.TileView : Gtk.IconView {
    private Gtk.CellRenderer cell_renderer;

    public TileView () {
    }

    construct {
        cell_renderer = new TileRenderer ();
        pack_start (cell_renderer, false);
        AlbumImage.apply_album_style (this);
        activate_on_single_click = true;
        add_attribute (cell_renderer, "album", 0);
        tooltip_column = 1;

        // padding needs to be 0 for pixel-perfect even spacing
        item_padding = 0;

        // use fixed vertical and horizontal margin
        margin = 24;
    }

    public override void size_allocate (Gtk.Allocation alloc) {
        // This assumes that the width of the sample is the width of every item
        Gtk.Requisition minimum_size, natural_size;
        cell_renderer.get_preferred_size (this, out minimum_size, out natural_size);
        int item_width = minimum_size.width;

        if (item_width <= 0)
            base.size_allocate (alloc);

        int total_width = alloc.width;

        // Find out how many items fit in a single row
        double num = total_width - 2 * margin;
        double denom = item_width;
        columns = (int) (num / denom);

        // Find ideal column spacing
        num = total_width - columns * item_width - 2 * margin;
        denom = columns - 1;
        column_spacing = (int) (num / denom);

        base.size_allocate (alloc);
    }
}
