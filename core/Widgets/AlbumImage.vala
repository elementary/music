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
 *
 * Authored by: Corentin Noël <corentin@elementary.io>
 */

public class Noise.Widgets.AlbumImage : Gtk.Image {

    private const string STYLESHEET = """
        .album {
            background-clip: padding-box;
            border: 3px solid transparent;
            box-shadow: 0 1px 3px alpha (#000, 0.12),
                        0 1px 2px alpha (#000, 0.24);
            margin: 12px;
            transition: all 600ms ease-in-out;
        }

        .album:focused {
            border-color: @colorAccent;
            border-radius: 3px;
        }

        .album:hover {
            box-shadow: 0 3px 6px alpha (#000, 0.16),
                        0 3px 6px alpha (#000, 0.23);
        }
    """;

    private Gdk.Pixbuf internal_pixbuf;
    private int scale = 1;

    construct {
        get_style_context ().add_class ("album");
        pixel_size = 128;
        apply_album_style (this);
    }

    public override bool draw (Cairo.Context cr) {
        weak Gtk.StyleContext ctx = get_style_context ();
        var state = ctx.get_state ();
        var border = ctx.get_border (state);
        int width = get_allocated_width ();
        int height = get_allocated_height ();
        int x = (width - internal_pixbuf.width)/2;
        int y = (height - internal_pixbuf.height)/2;
        ctx.render_background (cr, x, y, internal_pixbuf.width, internal_pixbuf.height);
        render_pixbuf ();
        ctx.render_icon (cr, internal_pixbuf, x, y);
        cr.fill_preserve ();
        ctx.render_frame (cr, x - border.left, y - border.top, internal_pixbuf.width + border.left + border.right, internal_pixbuf.height + border.top + border.bottom);
        return false;
    }

    public override void get_preferred_width (out int minimum_width, out int natural_width) {
        weak Gtk.StyleContext ctx = get_style_context ();
        var state = ctx.get_state ();
        var margin = ctx.get_margin (state);
        var border = ctx.get_border (state);
        var padding = ctx.get_padding (state);
        render_pixbuf ();
        minimum_width = internal_pixbuf.width;
        minimum_width += margin.left + margin.right;
        minimum_width += border.left + border.right;
        minimum_width += padding.left + padding.right;
        natural_width = internal_pixbuf.width;;
        natural_width += margin.left + margin.right;
        natural_width += border.left + border.right;
        natural_width += padding.left + padding.right;
    }

    public override void get_preferred_height (out int minimum_height, out int natural_height) {
        weak Gtk.StyleContext ctx = get_style_context ();
        var state = ctx.get_state ();
        var margin = ctx.get_margin (state);
        var border = ctx.get_border (state);
        var padding = ctx.get_padding (state);
        render_pixbuf ();
        minimum_height = internal_pixbuf.height;
        minimum_height += margin.top + margin.bottom;
        minimum_height += border.top + border.bottom;
        minimum_height += padding.top + padding.bottom;
        natural_height = minimum_height;
    }

    public static void apply_album_style (Gtk.Widget widget) {
        var provider = new Gtk.CssProvider ();
        try {
            provider.load_from_buffer (STYLESHEET.data);
            var context = widget.get_style_context ();
            context.add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (GLib.Error e) {
            critical (e.message);
        }
    }

    private void render_pixbuf () {
        var ctx = get_style_context ();
        if (pixbuf != null && scale == ctx.get_scale ())
            return;

        scale = ctx.get_scale ();
        var icon_info = Gtk.IconTheme.get_default ().lookup_by_gicon_for_scale (gicon, 128, scale, Gtk.IconLookupFlags.GENERIC_FALLBACK);
        try {
            internal_pixbuf = icon_info.load_icon ();
        } catch (Error e) {
            critical (e.message);
        }
    }
}
