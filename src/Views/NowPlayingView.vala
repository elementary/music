/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2021 elementary, Inc. (https://elementary.io)
 */

public class Music.NowPlayingView : Gtk.Grid {
    construct {
        var album_image = new Music.AlbumImage () {
            width_request = 200
        };

        var title_label = new Gtk.Label (null) {
            ellipsize = Pango.EllipsizeMode.MIDDLE
        };
        title_label.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);

        var artist_label = new Gtk.Label (null);

        var artist_revealer = new Gtk.Revealer ();
        artist_revealer.add (artist_label);

        var info_grid = new Gtk.Grid () {
            halign = Gtk.Align.CENTER
        };
        info_grid.attach (title_label, 0, 0);
        info_grid.attach (artist_revealer, 0, 1);

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

        row_spacing = 24;
        attach (album_image, 0, 0);
        attach (info_grid, 0, 1);
        attach (seekbar, 0, 2);
        attach (play_button, 0, 3);

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

        var play_pause_action = GLib.Application.get_default ().lookup_action (Application.ACTION_PLAY_PAUSE);
        play_pause_action.bind_property ("enabled", seekbar, "sensitive");

        var playback_manager = PlaybackManager.get_default ();
        playback_manager.bind_property ("playback-duration", seekbar, "playback-duration");
        playback_manager.bind_property ("playback-position", seekbar, "playback-position");
        playback_manager.bind_property ("artist", artist_label, "label");
        playback_manager.bind_property ("title", title_label, "label");

        playback_manager.bind_property (
            "artist", artist_revealer, "reveal-child", BindingFlags.SYNC_CREATE,
            (binding, src_val, ref target_val) => {
                target_val.set_boolean (src_val.get_string () != null);
            }
        );

        playback_manager.notify["pixbuf"].connect (() => {
            var pixbuf = playback_manager.pixbuf;
            var scaled = pixbuf.scale_simple (200, 200, Gdk.InterpType.BILINEAR);

            album_image.image.pixbuf = scaled;
        });
    }
}
