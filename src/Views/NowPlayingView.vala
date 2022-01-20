/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2021 elementary, Inc. (https://elementary.io)
 */

public class Music.NowPlayingView : Gtk.Box {
    construct {
        var album_image = new Music.AlbumImage ();

        var aspect_frame = new Gtk.AspectFrame (0.5f, 1.0f, 1, false) {
            child = album_image
        };

        var title_label = new Gtk.Label (_("Music")) {
            ellipsize = Pango.EllipsizeMode.MIDDLE
        };
        title_label.add_css_class (Granite.STYLE_CLASS_H3_LABEL);

        var artist_label = new Gtk.Label (_("Not playing"));

        var artist_revealer = new Gtk.Revealer () {
            child = artist_label
        };

        var info_grid = new Gtk.Grid () {
            halign = Gtk.Align.CENTER
        };
        info_grid.attach (title_label, 0, 0);
        info_grid.attach (artist_revealer, 0, 1);

        var seekbar = new Music.SeekBar ();

        var previous_image = new Gtk.Image.from_icon_name ("media-skip-backward-symbolic") {
            pixel_size = 24
        };

        var previous_button = new Gtk.Button () {
            action_name = Application.ACTION_PREFIX + Application.ACTION_PREVIOUS,
            child = previous_image,
            halign = Gtk.Align.END,
            tooltip_text = _("Previous")
        };
        previous_button.add_css_class ("image-button");

        var play_pause_image = new Gtk.Image.from_icon_name ("media-playback-start-symbolic") {
            pixel_size = 24
        };

        var play_button = new Gtk.Button () {
            action_name = Application.ACTION_PREFIX + Application.ACTION_PLAY_PAUSE,
            child = play_pause_image,
            halign = Gtk.Align.CENTER,
        };
        play_button.add_css_class ("image-button");

        var next_image = new Gtk.Image.from_icon_name ("media-skip-forward-symbolic") {
            pixel_size = 24
        };

        var next_button = new Gtk.Button () {
            action_name = Application.ACTION_PREFIX + Application.ACTION_NEXT,
            child = next_image,
            halign = Gtk.Align.START,
            tooltip_text = _("Next")
        };
        next_button.add_css_class ("image-button");

        var grid = new Gtk.Grid () {
            column_spacing = 12,
            row_spacing = 24,
            valign = Gtk.Align.START,
            vexpand = true
        };
        grid.attach (info_grid, 0, 1, 3);
        grid.attach (seekbar, 0, 2, 3);
        grid.attach (previous_button, 0, 3);
        grid.attach (play_button, 1, 3);
        grid.attach (next_button, 2, 3);

        orientation = Gtk.Orientation.VERTICAL;
        spacing = 24;
        append (aspect_frame);
        append (grid);

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
        play_pause_action.bind_property ("enabled", seekbar, "sensitive", BindingFlags.SYNC_CREATE);

        var playback_manager = PlaybackManager.get_default ();
        playback_manager.bind_property ("playback-position", seekbar, "playback-position");

        playback_manager.notify["current-audio"].connect (() => {
            if (playback_manager.current_audio != null) {
                playback_manager.current_audio.bind_property ("artist", artist_label, "label", BindingFlags.SYNC_CREATE);
                playback_manager.current_audio.bind_property ("title", title_label, "label", BindingFlags.SYNC_CREATE);
                playback_manager.current_audio.bind_property ("duration", seekbar, "playback-duration", BindingFlags.SYNC_CREATE);

                playback_manager.current_audio.notify["texture"].connect (() => {
                    var texture = playback_manager.current_audio.texture;
                    album_image.image.paintable = texture;
                });
            } else {
                album_image.image.paintable = null;
                artist_label.label = _("Not playing");
                title_label.label = _("Music");
                seekbar.playback_duration = 0;
                seekbar.playback_position = 0;
            }
        });

        artist_label.bind_property (
            "label", artist_revealer, "reveal-child", BindingFlags.SYNC_CREATE,
            (binding, src_val, ref target_val) => {
                target_val.set_boolean (src_val.get_string () != null);
            }
        );
    }
}
