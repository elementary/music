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

        var album_image = new Music.AlbumImage ();
        album_image.image.height_request = 32;
        album_image.image.width_request = 32;

        var title_label = new Gtk.Label (audio_object.title) {
            ellipsize = Pango.EllipsizeMode.MIDDLE,
            hexpand = true,
            xalign = 0
        };

        var artist_label = new Gtk.Label (audio_object.artist) {
            ellipsize = Pango.EllipsizeMode.MIDDLE,
            hexpand = true,
            xalign = 0
        };
        artist_label.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);
        artist_label.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);

        var grid = new Gtk.Grid () {
            column_spacing = 12,
            margin_top = 6,
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 6
        };
        grid.attach (album_image, 0, 0, 1, 2);
        grid.attach (title_label, 1, 0);
        grid.attach (artist_label, 1, 1);
        grid.attach (play_icon, 2, 0, 1, 2);

        child = grid;

        audio_object.bind_property ("artist", artist_label, "label");
        audio_object.bind_property ("title", title_label, "label");
        audio_object.bind_property ("texture", album_image.image, "paintable");

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
