/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2021 elementary, Inc. (https://elementary.io)
 */

public class Music.AlbumImage : Gtk.Grid {
    public Gtk.Image image;

    private static Gtk.CssProvider css_provider;

    class construct {
        set_css_name ("album");
    }

    static construct {
        css_provider = new Gtk.CssProvider ();
        css_provider.load_from_resource ("/io/elementary/music/AlbumImage.css");
    }

    construct {
        unowned var style_context = get_style_context ();
        style_context.add_class (Granite.STYLE_CLASS_CARD);
        style_context.add_class (Granite.STYLE_CLASS_ROUNDED);
        style_context.add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        image = new Gtk.Image () {
            height_request = 32,
            width_request = 32
        };

        halign = Gtk.Align.CENTER;
        valign = Gtk.Align.CENTER;
        add (image);
    }

    public override Gtk.SizeRequestMode get_request_mode () {
        return Gtk.SizeRequestMode.HEIGHT_FOR_WIDTH;
    }

    public override void get_preferred_height_for_width (int width, out int minimum_height, out int natural_height) {
        minimum_height = natural_height = width;
        image.pixel_size = width;
    }
}
