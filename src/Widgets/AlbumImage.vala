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
        style_context.add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        image = new Gtk.Image () {
            height_request = 200,
            width_request = 200,
            hexpand = true,
            vexpand = true
        };

        add_css_class (Granite.STYLE_CLASS_CARD);
        add_css_class (Granite.STYLE_CLASS_ROUNDED);
        overflow = Gtk.Overflow.HIDDEN;
        attach (image, 0, 0);
    }
}
