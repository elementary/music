/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2021 elementary, Inc. (https://elementary.io)
 */

public class Music.TrackRow : Gtk.ListBoxRow {
    public AudioObject audio_object { get; construct; }

    private static Gtk.CssProvider css_provider;
    private static PlaybackManager playback_manager;

    public TrackRow (AudioObject audio_object) {
        Object (audio_object: audio_object);
    }

    static construct {
        playback_manager = PlaybackManager.get_default ();

        css_provider = new Gtk.CssProvider ();
        css_provider.load_from_resource ("io/elementary/music/PlaybackIndicator.css");
    }

    construct {
        var play_icon = new Gtk.Spinner ();

        unowned var play_icon_context = play_icon.get_style_context ();
        play_icon_context.add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        var title_label = new Gtk.Label (audio_object.title) {
            ellipsize = Pango.EllipsizeMode.MIDDLE,
            hexpand = true,
            xalign = 0
        };

        var time_label = new Gtk.Label (null) {
            use_markup = true
        };
        time_label.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);

        var grid = new Gtk.Grid () {
            column_spacing = 6,
            margin_top = 6,
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 6
        };
        grid.attach (play_icon, 0, 0);
        grid.attach (title_label, 1, 0);
        grid.attach (time_label, 2, 0);

        child = grid;

        audio_object.bind_property ("title", title_label, "label");

        audio_object.notify["duration"].connect (() => {
            // time_label.label = "<span font-features='tnum'>%s</span>".printf (
            //     Granite.DateTime.seconds_to_time ((int) (audio_object.duration / Gst.SECOND))
            // );
        });

        playback_manager.notify["current-audio"].connect (() => {
            play_icon.spinning = playback_manager.current_audio == audio_object;
        });

        GLib.Application.get_default ().action_state_changed.connect ((name, new_state) => {
            if (name == Application.ACTION_PLAY_PAUSE) {
                if (new_state.get_boolean () == true) {
                    play_icon_context.add_class ("playing");
                } else {
                    play_icon_context.remove_class ("playing");
                }
            }
        });

    }
}
