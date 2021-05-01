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

        var album_image = new Music.AlbumImage () {
            width_request = 200
        };

        var title_label = new Gtk.Label (_("Unknown"));
        title_label.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);

        var artist_label = new Gtk.Label (_("Unknown"));

        var info_grid = new Gtk.Grid () {
            halign = Gtk.Align.CENTER
        };
        info_grid.attach (title_label, 0, 0);
        info_grid.attach (artist_label, 0, 1);

        var seekbar = new Music.SeekBar ();

        var play_pause_image = new Gtk.Image.from_icon_name (
            "media-playback-start-symbolic",
            Gtk.IconSize.LARGE_TOOLBAR
        );

        var play_button = new Gtk.Button () {
            action_name = Application.ACTION_PREFIX + Application.ACTION_PLAY_PAUSE,
            halign = Gtk.Align.CENTER,
            image = play_pause_image
        };
        play_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var now_playing_grid = new Gtk.Grid () {
            margin = 12,
            margin_bottom = 24,
            row_spacing = 24,
            valign = Gtk.Align.CENTER,
            vexpand = true
        };
        now_playing_grid.attach (album_image, 0, 0);
        now_playing_grid.attach (info_grid, 0, 1);
        now_playing_grid.attach (seekbar, 0, 2);
        now_playing_grid.attach (play_button, 0, 3);

        var grid = new Gtk.Grid ();
        grid.attach (headerbar, 0, 0);
        grid.attach (now_playing_grid, 0, 1);

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

        var playback_manager = PlaybackManager.get_default ();
        playback_manager.bind_property ("playback-duration", seekbar, "playback-duration");
        playback_manager.bind_property ("playback-position", seekbar, "playback-position");
        playback_manager.bind_property ("artist", artist_label, "label");
        playback_manager.bind_property ("title", title_label, "label");
    }
}
