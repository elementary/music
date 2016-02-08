/**
 * Copyright 2013 elementary
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 3 or later). See the COPYING file in this distribution.
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
