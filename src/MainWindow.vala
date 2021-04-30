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

        var play_pause_image = new Gtk.Image.from_icon_name (
            "media-playback-start-symbolic",
            Gtk.IconSize.LARGE_TOOLBAR
        );

        var play_button = new Gtk.Button () {
            action_name = Application.ACTION_PREFIX + Application.ACTION_PLAY_PAUSE,
            image = play_pause_image
        };
        play_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var grid = new Gtk.Grid () {
            row_spacing = 24,
            margin_bottom = 24
        };
        grid.attach (headerbar, 0, 0);
        grid.attach (play_button, 0, 1);

        add (grid);

        GLib.Application.get_default ().action_state_changed.connect ((name, new_state) => {
            if (name == Application.ACTION_PLAY_PAUSE) {
                if (new_state.get_boolean () == false) {
                    play_pause_image.icon_name = "media-playback-start-symbolic";
                    play_button.tooltip_text = _("Play");
                } else {
                    play_pause_image.icon_name = "media-playback-pause-symbolic";
                    play_button.tooltip_text = _("Pause");
                }
            }
        });
    }
}
