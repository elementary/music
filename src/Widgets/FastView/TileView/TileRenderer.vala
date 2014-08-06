/**
 * Copyright 2013 elementary
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 3 or later). See the COPYING file in this distribution.
 */

internal class Noise.Widgets.TileRenderer : Gtk.CellRenderer {
    public Gdk.Pixbuf pixbuf { get; set; }
    public string title { get; set; }
    public string subtitle { get; set; }

    private const int BRIGHTEN_SHIFT = 0x18;
    private const int IMAGE_SHADOW_MARGIN = 12;
    private const int IMAGE_SHADOW_RADIUS = 4;
    private const double IMAGE_SHADOW_ALPHA = 0.65;

    private int last_image_width = 0;
    private int last_image_height = 0;
    private Granite.Drawing.BufferSurface shadow_buffer;
    private Pango.Layout title_text_layout;
    private Pango.Layout subtitle_text_layout;
    private Gtk.Border margin;
    private Gtk.Border padding;
    private Gtk.Border border;

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
                   + margin.top + margin.bottom
                   + padding.top + padding.bottom
                   + border.top + border.bottom
                   + 2 * y_padding
                   + IMAGE_SHADOW_RADIUS;

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

        // Apply margin
        x += margin.right;
        y += margin.top;
        width -= margin.left + margin.right;
        height -= margin.top + margin.bottom;

        var ctx = widget.get_style_context ();

        // Apply border width and padding offsets
        x += border.right + padding.right;
        y += border.top + padding.top;

        width -= border.left + border.right + padding.left + padding.right;
        height -= border.top + border.bottom + padding.top + padding.bottom;

        render_image (ctx, cr, ref x, ref y, width, flags);
        render_title (ctx, cr, x, ref y, width);
        render_subtitle (ctx, cr, x, y, width);
    }

    private void render_image (Gtk.StyleContext ctx, Cairo.Context cr, ref int x,
                               ref int y, int width, Gtk.CellRendererState flags)
    {
        int image_width = compute_total_image_width ();
        int image_height = compute_total_image_height ();
        int offset = IMAGE_SHADOW_MARGIN;

        // this cell renderer is not optimized for pixbufs of different dimensions
        if (shadow_buffer == null || image_width != last_image_width
         || image_height != last_image_height)
        {
            shadow_buffer = new Granite.Drawing.BufferSurface (image_width, image_height);

            var context = shadow_buffer.context;
            context.rectangle (offset, offset, pixbuf.width, pixbuf.height);
            context.set_source_rgba (0, 0, 0, IMAGE_SHADOW_ALPHA);
            context.fill ();
            shadow_buffer.exponential_blur (IMAGE_SHADOW_RADIUS);

            last_image_width = image_width;
            last_image_height = image_height;
        }

        x += (width - image_width) / 2;

        cr.set_source_surface (shadow_buffer.surface, x, y);
        cr.paint ();

        Gdk.Pixbuf image;
        if (should_brighten_image (flags))
            image = get_brightened_pixbuf (pixbuf);
        else
            image = pixbuf;

        ctx.render_icon (cr, image, x + offset, y + offset);

        if (should_draw_highlight (flags)) {
            ctx.save ();
            ctx.add_class (Gtk.STYLE_CLASS_IMAGE);
            ctx.render_frame (cr, x + offset - border.left,
                              y + offset - border.top,
                              pixbuf.width + border.left + border.right,
                              pixbuf.height + border.top + border.bottom);
            ctx.restore ();
        }

        y += image_height;

        // move x to the start of the actual image
        x += (image_width - image.width) / 2;
    }

    private void render_title (Gtk.StyleContext ctx, Cairo.Context cr, int x,
                               ref int y, int width)
    {
        ctx.save ();
        ctx.add_class ("title-text");
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
        var state = ctx.get_state ();

        ctx.save ();
        ctx.add_class (Gtk.STYLE_CLASS_IMAGE);
        margin = ctx.get_margin (state);
        padding = ctx.get_padding (state);
        border = ctx.get_border (state);
        ctx.restore ();

        subtitle_text_layout = widget.create_pango_layout (subtitle);
        unowned Pango.FontDescription font_description;
        ctx.get (state, Gtk.STYLE_PROPERTY_FONT, out font_description);
        subtitle_text_layout.set_font_description (font_description);
        subtitle_text_layout.set_ellipsize (Pango.EllipsizeMode.END);
        subtitle_text_layout.set_alignment (Pango.Alignment.LEFT);
        int text_width = pixbuf != null ? pixbuf.width * Pango.SCALE : 0;
        subtitle_text_layout.set_width (text_width);

        ctx.save ();
        ctx.add_class ("title-text");
        title_text_layout = widget.create_pango_layout (title);
        ctx.get (state, Gtk.STYLE_PROPERTY_FONT, out font_description);
        title_text_layout.set_font_description (font_description);
        title_text_layout.set_width (text_width);
        title_text_layout.set_ellipsize (Pango.EllipsizeMode.END);
        title_text_layout.set_alignment (Pango.Alignment.LEFT);
        ctx.restore ();
    }

    private int compute_total_image_width () {
        return pixbuf != null ? pixbuf.width + 2 * IMAGE_SHADOW_MARGIN : 0;
    }

    private int compute_total_image_height () {
        return pixbuf != null ? pixbuf.height + 2 * IMAGE_SHADOW_MARGIN : 0;
    }

    private static bool should_brighten_image (Gtk.CellRendererState flags) {
        return (flags & Gtk.CellRendererState.PRELIT) != 0;
    }

    private static bool should_draw_highlight (Gtk.CellRendererState flags) {
        return (flags & Gtk.CellRendererState.SELECTED) != 0;
    }

    private static Gdk.Pixbuf? get_brightened_pixbuf (Gdk.Pixbuf pixbuf) {
        if (pixbuf == null)
            return null;

        // create a new lightened pixbuf to display
        var brightened = pixbuf.copy ();
        ImageUtils.shift_colors (brightened, BRIGHTEN_SHIFT, BRIGHTEN_SHIFT, BRIGHTEN_SHIFT, 0);
        return brightened;
    }
}
