/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2021 elementary, Inc. (https://elementary.io)
 */

public class Music.TrackRow : Granite.Bin {
    private AudioObject _audio_object = null;
    public AudioObject audio_object {
        get {
            return _audio_object;
        }

        set {
            if (_audio_object != null) {
                artist_binding.unbind ();
                texture_binding.unbind ();
                title_binding.unbind ();
            }

            _audio_object = value;

            if (_audio_object == null) {
                return;
            }

            artist_binding = _audio_object.bind_property ("artist", artist_label, "label", SYNC_CREATE);
            title_binding = _audio_object.bind_property ("title", title_label, "label", SYNC_CREATE);
            texture_binding = _audio_object.bind_property ("texture", album_image.image, "paintable", SYNC_CREATE);
        }
    }

    private static PlaybackManager playback_manager;

    private Binding artist_binding;
    private Binding texture_binding;
    private Binding title_binding;

    private Gtk.Label artist_label;
    private Gtk.Label title_label;
    private Gtk.Spinner play_icon;
    private Music.AlbumImage album_image;

    static construct {
        playback_manager = PlaybackManager.get_default ();
    }

    construct {
        play_icon = new Gtk.Spinner ();
        play_icon.add_css_class ("play-indicator");

        album_image = new Music.AlbumImage ();
        album_image.image.height_request = 32;
        album_image.image.width_request = 32;

        title_label = new Gtk.Label (null) {
            ellipsize = Pango.EllipsizeMode.MIDDLE,
            hexpand = true,
            xalign = 0
        };

        artist_label = new Gtk.Label (null) {
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

        playback_manager.notify["current-audio"].connect (() => {
            play_icon.spinning = playback_manager.current_audio == audio_object;
        });

        var play_pause_action = (SimpleAction) GLib.Application.get_default ().lookup_action (Application.ACTION_PLAY_PAUSE);
        update_playing (play_pause_action.get_state ().get_boolean ());

        GLib.Application.get_default ().action_state_changed.connect ((name, new_state) => {
            if (name == Application.ACTION_PLAY_PAUSE) {
                update_playing (new_state.get_boolean ());
            }
        });

        notify["audio-object"].connect (() => {
            play_icon.spinning = playback_manager.current_audio == audio_object;
        });
    }

    private void update_playing (bool playing) {
        if (playing) {
            play_icon.add_css_class ("playing");
        } else {
            play_icon.remove_css_class ("playing");
        }
    }
}
