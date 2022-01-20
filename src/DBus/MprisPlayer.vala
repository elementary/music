/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2022 elementary, Inc. (https://elementary.io)
 */

[DBus (name = "org.mpris.MediaPlayer2.Player")]
public class Music.MprisPlayer : Object {
    [DBus (visible = false)]
    public unowned DBusConnection connection { get; construct; }

    private bool _can_go_next = false;
    public bool can_go_next {
        get {
            return _can_go_next;
        }
    }

    private bool _can_go_previous = false;
    public bool can_go_previous {
        get {
            return _can_go_previous;
        }
    }

    private bool _can_play = false;
    public bool can_play {
        get {
            return _can_play;
        }
    }

    private string _playback_status = "Stopped";
    public string playback_status {
        owned get {
            return _playback_status;
        }
    }

    public HashTable<string, Variant>? metadata {
        owned get {
            var _metadata = new HashTable<string, Variant> (null, null);

            var audio = playback_manager.current_audio;
            if (audio != null) {
                if (audio.artist != null) {
                    string[] array = { audio.artist };
                    _metadata.insert ("xesam:artist", array);
                }

                if (audio.title != null) {
                    _metadata.insert ("xesam:title", audio.title);
                }
            }

            return _metadata;
        }
    }

    public MprisPlayer (DBusConnection connection) {
        Object (connection: connection);
    }

    private GLib.Application application;
    private PlaybackManager playback_manager;

    construct {
        application = GLib.Application.get_default ();
        playback_manager = PlaybackManager.get_default ();

        playback_manager.notify["current-audio"].connect (() => {
            send_property_change ("Metadata", metadata);
        });

        application.action_state_changed.connect ((name, new_state) => {
            if (name == Application.ACTION_PLAY_PAUSE) {
                if (new_state.get_boolean () == false) {
                    _playback_status = "Stopped";
                } else {
                    _playback_status = "Playing";
                }

                send_property_change ("PlaybackStatus", playback_status);
            }
        });

        application.action_enabled_changed.connect ((name, enabled) => {
            switch (name) {
                case Application.ACTION_NEXT:
                    _can_go_next = enabled;
                    send_property_change ("CanGoNext", can_go_next);
                    break;
                case Application.ACTION_PREVIOUS:
                    _can_go_previous = enabled;
                    send_property_change ("CanGoPrevious", can_go_previous);
                    break;
                case Application.ACTION_PLAY_PAUSE:
                    _can_play = enabled;
                    send_property_change ("CanPlay", can_play);
                    break;
            }
        });
    }

    private void send_property_change (string name, Variant variant) {
        var invalidated_builder = new VariantBuilder (new VariantType ("as"));

        var builder = new VariantBuilder (VariantType.ARRAY);
        builder.add ("{sv}", name, variant);

        try {
            connection.emit_signal (
                null,
                "/org/mpris/MediaPlayer2",
                "org.freedesktop.DBus.Properties",
                "PropertiesChanged",
                new Variant (
                    "(sa{sv}as)",
                    "org.mpris.MediaPlayer2.Player",
                    builder,
                    invalidated_builder
                )
            );
        } catch (Error e) {
            print ("Could not send MPRIS property change: %s\n", e.message);
        }
    }

    public void next () throws GLib.Error {
        application.activate_action (Application.ACTION_NEXT, null);
    }

    public void previous () throws GLib.Error {
        application.activate_action (Application.ACTION_PREVIOUS, null);
    }

    public void play_pause () throws GLib.Error {
        application.activate_action (Application.ACTION_PLAY_PAUSE, null);
    }
}
