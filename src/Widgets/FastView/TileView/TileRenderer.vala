/**
 * Copyright 2013 elementary
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 3 or later). See the COPYING file in this distribution.
 */

internal class Noise.Widgets.TileRenderer : Gtk.CellRenderer {
    public Album album { get; set; }

    private Pango.Layout title_text_layout;
    private Pango.Layout subtitle_text_layout;
    private Gtk.Border margin;
    private Gtk.Border padding;
    private Gtk.Border border;
    private Gdk.Pixbuf pixbuf;
    private Gdk.Pixbuf fallback_pixbuf;
    private int fallback_pixbuf_scale = 1;

    public TileRenderer () {
        notify["album"].connect (() => {
            pixbuf = null;
        });
    }

    public override void get_size (Gtk.Widget widget, Gdk.Rectangle? cell_area,
                                   out int x_offset, out int y_offset,
                                   out int width, out int height)
    {
        x_offset = y_offset = width = height = 0;
    }

    public override Gtk.SizeRequestMode get_request_mode () {
        return Gtk.SizeRequestMode.HEIGHT_FOR_WIDTH;
    }

    public override void get_preferred_width (Gtk.Widget widget,
                                              out int minimum_size,
                                              out int natural_size)
    {
        update_layout_properties (widget);

        int x_padding;
        get_padding (out x_padding, null);

        int width = compute_total_image_width ()
                  + margin.left + margin.right
                  + padding.left + padding.right
                  + border.left + border.right
                  + 2 * x_padding;

        minimum_size = natural_size = width;
    }

    public override void get_preferred_height_for_width (Gtk.Widget widget, int width,
                                                         out int minimum_height,
                                                         out int natural_height)
    {
        update_layout_properties (widget);

        int y_padding;
        get_padding (null, out y_padding);

        int subtitle_height, title_height;
        title_text_layout.get_pixel_size (null, out title_height);
        subtitle_text_layout.get_pixel_size (null, out subtitle_height);

        int height = compute_total_image_height ()
                   + title_height + subtitle_height
                   + margin.top + 2 * margin.bottom
                   + padding.top + padding.bottom
                   + border.top + border.bottom
                   + 2 * y_padding;

        minimum_height = natural_height = height;
    }

    public override void render (Cairo.Context cr, Gtk.Widget widget, Gdk.Rectangle bg_area,
                                 Gdk.Rectangle cell_area, Gtk.CellRendererState flags)
    {
        update_layout_properties (widget);

        Gdk.Rectangle aligned_area = get_aligned_area (widget, flags, cell_area);

        int x = aligned_area.x;
        int y = aligned_area.y;
        int width = aligned_area.width;
        int height = aligned_area.height;

        // Apply margin, border width and padding offsets
        x += margin.left + border.left + padding.left;
        y += margin.top + border.top + padding.top;

        weak Gtk.StyleContext ctx = widget.get_style_context ();

        width -= margin.left + margin.right + border.left + border.right + padding.left + padding.right;
        height -= margin.top + margin.bottom + border.top + border.bottom + padding.top + padding.bottom;

        render_image (ctx, cr, ref x, ref y, width, flags);
        render_title (ctx, cr, x, ref y, width);
        render_subtitle (ctx, cr, x, y, width);
    }

    private void render_image (Gtk.StyleContext ctx, Cairo.Context cr, ref int x,
                               ref int y, int width, Gtk.CellRendererState flags)
    {
        int image_width = compute_total_image_width ();
        int image_height = compute_total_image_height ();

        x += (width - image_width) / 2;

        ctx.save ();
        ctx.add_class ("album");
        ctx.render_background (cr, x, y, pixbuf.width, pixbuf.height);
        ctx.render_icon (cr, pixbuf, x, y);
        cr.fill_preserve ();
        ctx.render_frame (cr, x - border.left, y - border.top, pixbuf.width + border.left + border.right, pixbuf.height + border.top + border.bottom);
        ctx.restore ();

        y += image_height;

        // move x to the start of the actual image
        x += (image_width - pixbuf.width) / 2 - margin.left;
    }

    private void render_title (Gtk.StyleContext ctx, Cairo.Context cr, int x,
                               ref int y, int width)
    {
        ctx.save ();
        ctx.add_class ("h4");
        ctx.render_layout (cr, x, y, title_text_layout);
        ctx.restore ();

        int title_height;
        title_text_layout.get_pixel_size (null, out title_height);

        y += title_height;
    }

    private void render_subtitle (Gtk.StyleContext ctx, Cairo.Context cr, int x,
                                  int y, int width)
    {
        ctx.render_layout (cr, x, y, subtitle_text_layout);
    }

    private void update_layout_properties (Gtk.Widget widget) {
        var ctx = widget.get_style_context ();
        render_prixbuf (ctx);
        var state = ctx.get_state ();

        ctx.save ();
        ctx.add_class ("album");
        margin = ctx.get_margin (state);
        padding = ctx.get_padding (state);
        border = ctx.get_border (state);
        ctx.restore ();

        subtitle_text_layout = widget.create_pango_layout (album.get_display_artist ());
        unowned Pango.FontDescription font_description;
        ctx.get (state, Gtk.STYLE_PROPERTY_FONT, out font_description);
        subtitle_text_layout.set_font_description (font_description);
        subtitle_text_layout.set_ellipsize (Pango.EllipsizeMode.END);
        subtitle_text_layout.set_alignment (Pango.Alignment.LEFT);
        int text_width = pixbuf != null ? pixbuf.width * Pango.SCALE : 0;
        subtitle_text_layout.set_width (text_width);

        ctx.save ();
        ctx.add_class ("h4");
        title_text_layout = widget.create_pango_layout (album.get_display_name ());
        ctx.get (state, Gtk.STYLE_PROPERTY_FONT, out font_description);
        title_text_layout.set_font_description (font_description);
        title_text_layout.set_width (text_width);
        title_text_layout.set_ellipsize (Pango.EllipsizeMode.END);
        title_text_layout.set_alignment (Pango.Alignment.LEFT);
        ctx.restore ();
    }

    private int compute_total_image_width () {
        return pixbuf != null ? pixbuf.width + margin.left + margin.right : 0;
    }

    private int compute_total_image_height () {
        return pixbuf != null ? pixbuf.height + margin.top + margin.bottom : 0;
    }

    private void render_prixbuf (Gtk.StyleContext ctx) {
        var scale = ctx.get_scale ();
        if (fallback_pixbuf == null || fallback_pixbuf_scale != scale) {
            var icon_info = Gtk.IconTheme.get_default ().lookup_by_gicon_for_scale (new ThemedIcon ("albumart"), 128, scale, Gtk.IconLookupFlags.GENERIC_FALLBACK);
            try {
                fallback_pixbuf = icon_info.load_icon ();
            } catch (Error e) {
                critical (e.message);
            }
        }

        pixbuf = album.get_cached_cover_pixbuf (scale);
        if (pixbuf == null) {
            pixbuf = fallback_pixbuf;
        }
    }
}
