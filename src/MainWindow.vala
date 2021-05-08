/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2021 elementary, Inc. (https://elementary.io)
 */

public class Music.MainWindow : Hdy.ApplicationWindow {
    construct {
        Hdy.init ();

        var headerbar = new Hdy.HeaderBar () {
            hexpand = true,
            show_close_button = true
        };

        unowned var header_context = headerbar.get_style_context ();
        header_context.add_class (Granite.STYLE_CLASS_DEFAULT_DECORATION);
        header_context.add_class (Gtk.STYLE_CLASS_FLAT);

        var now_playing_view = new NowPlayingView () {
            margin = 12,
            margin_bottom = 24,
            valign = Gtk.Align.CENTER,
            vexpand = true
        };

        var grid = new Gtk.Grid ();
        grid.attach (headerbar, 0, 0);
        grid.attach (now_playing_view, 0, 1);

        add (grid);
    }
}
