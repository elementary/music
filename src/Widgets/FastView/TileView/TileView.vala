/**
 * Copyright 2013 elementary
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 3 or later). See the COPYING file in this distribution.
 */

public class Noise.Widgets.TileView : Gtk.IconView {
    private const int MIN_HORIZONTAL_SPACING = 12;

    private const string STYLESHEET = """
        /* general background color and texture */
        .tile-view {
            color: alpha(@fg_color, 0.95);
            background-color: @base_color;
        }

        /* workaround: suppress default cell borders for icon view */
        .tile-view.cell {
            background-image: none;
            background-color: @transparent;
            border-width: 0;
            border-style: solid;
            border-color: @transparent;
            box-shadow: inset 0 0 @transparent;
        }

        /* image selection frame */
        .tile-view.cell.image {
            border-width: 3px;
            border-radius: 3px;
            border-color: alpha(@selected_bg_color, 0.95);
        }

        /* apply bold font to titles */
        .tile-view.cell.title-text {
            font-weight: bold;
            color: @fg_color;
        }
    """;

    private Gtk.CellRenderer cell_renderer = new TileRenderer ();

    public int image_column {
        set {
            add_attribute (cell_renderer, "pixbuf", value);
        }
    }

    public int title_column {
        set {
            add_attribute (cell_renderer, "title", value);
        }
    }

    public int subtitle_column {
        set {
            add_attribute (cell_renderer, "subtitle", value);
        }
    }

    public TileView () {
        pack_start (cell_renderer, false);
        apply_default_theme ();
        activate_on_single_click = true;

        // padding needs to be 0 for pixel-perfect even spacing
        item_padding = 0;

        // use fixed vertical and horizontal margin
        margin = 24;
        row_spacing = 12;
    }

    private void apply_default_theme () {
        get_style_context ().remove_class (Gtk.STYLE_CLASS_VIEW);
        Granite.Widgets.Utils.set_theming (this, STYLESHEET, "tile-view",
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
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
        double num = total_width + MIN_HORIZONTAL_SPACING - 2 * margin;
        double denom = item_width + MIN_HORIZONTAL_SPACING;
        columns = (int) (num / denom);

        // Find ideal column spacing
        num = total_width - columns * item_width - 2 * margin;
        denom = columns - 1;
        column_spacing = (int) (num / denom);

        base.size_allocate (alloc);
    }
}