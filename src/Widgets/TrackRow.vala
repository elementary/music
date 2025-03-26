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
                _audio_object.notify["artist"].disconnect (update_artist_label);
                _audio_object.notify["title"].disconnect (update_title_label);
                _audio_object.notify["texture"].disconnect (update_cover_art);
            }

            _audio_object = value;

            if (_audio_object == null) {
                return;
            }

            artist_label.label = _audio_object.artist;
            title_label.label = _audio_object.title;
            album_image.image.paintable = _audio_object.texture;

            _audio_object.notify["artist"].connect (update_artist_label);
            _audio_object.notify["title"].connect (update_title_label);
            _audio_object.notify["texture"].connect (update_cover_art);

        }
    }

    private static PlaybackManager playback_manager;

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

        var action_remove = new SimpleAction ("remove", null);
        action_remove.activate.connect (() => {
            playback_manager.remove (this.audio_object);
        });

        var row_action_group = new SimpleActionGroup ();
        row_action_group.add_action (action_remove);

        insert_action_group ("trackrow", row_action_group);
        add_binding_action (Gdk.Key.Delete, Gdk.ModifierType.NO_MODIFIER_MASK, "trackrow.remove", null);

        var menu = new Menu ();
        menu.append (_("Remove"), "trackrow.remove");

        var context_menu = new Gtk.PopoverMenu.from_model (menu) {
            halign = Gtk.Align.START,
            has_arrow = false,
            position = Gtk.PositionType.BOTTOM
        };
        context_menu.set_parent (this);

        var right_click = new Gtk.GestureClick () {
            button = Gdk.BUTTON_SECONDARY
        };
        right_click.pressed.connect ((n_press, x, y) => {
            menu_popup_at_pointer (context_menu, x, y);
        });

        var long_press = new Gtk.GestureLongPress ();
        long_press.pressed.connect ((x, y) => {
            menu_popup_at_pointer (context_menu, x, y);
        });

        add_controller (right_click);
        add_controller (long_press);
    }

    private void menu_popup_at_pointer (Gtk.PopoverMenu popover, double x, double y) {
        var rect = Gdk.Rectangle () {
            x = (int) x,
            y = (int) y
        };
        popover.pointing_to = rect;
        popover.popup ();
    }

    private void update_playing (bool playing) {
        if (playing) {
            play_icon.add_css_class ("playing");
        } else {
            play_icon.remove_css_class ("playing");
        }
    }

    private void update_title_label () {
        title_label.label = _audio_object.title;
    }

    private void update_artist_label () {
        artist_label.label = _audio_object.artist;
    }

    private void update_cover_art () {
        album_image.image.paintable = _audio_object.texture;
    }
}
