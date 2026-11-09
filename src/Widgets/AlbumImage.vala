/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2021 elementary, Inc. (https://elementary.io)
 */

public class Music.AlbumImage : Gtk.Grid {
    public Gtk.Widget image { get; construct; }

    class construct {
        set_css_name ("album");
    }

    public AlbumImage (Gtk.Widget image) {
        Object (image: image);
    }

    construct {
        add_css_class (Granite.STYLE_CLASS_CARD);
        add_css_class (Granite.STYLE_CLASS_ROUNDED);
        overflow = Gtk.Overflow.HIDDEN;
        attach (image, 0, 0);
    }
}
