/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2022 elementary, Inc. (https://elementary.io)
 */

[DBus (name = "org.mpris.MediaPlayer2.Player")]
public class Music.MprisPlayer : Object {
    [DBus (visible = false)]
    public unowned DBusConnection connection { get; construct; }

    public bool can_go_next {
        get {
            return application.lookup_action (Application.ACTION_NEXT).enabled;
        }
    }

    public bool can_go_previous {
        get {
            return application.lookup_action (Application.ACTION_PREVIOUS).enabled;
        }
    }

    public bool can_play {
        get {
            return application.lookup_action (Application.ACTION_PLAY_PAUSE).enabled;
        }
    }


    public string playback_status {
        get {
            var state = (bool) application.lookup_action (Application.ACTION_PLAY_PAUSE).state;
            if (state == false) {
                return "Stopped";
            } else {
                return "Playing";
            }
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

    private GLib.Application application;
    private PlaybackManager playback_manager;

    public MprisPlayer (DBusConnection connection) {
        Object (connection: connection);
    }

    construct {
        application = GLib.Application.get_default ();
        playback_manager = PlaybackManager.get_default ();

        playback_manager.notify["current-audio"].connect (() => {
            send_property_change ("Metadata", metadata);
        });

        application.action_state_changed.connect ((name, new_state) => {
            if (name == Application.ACTION_PLAY_PAUSE) {
                send_property_change ("PlaybackStatus", playback_status);
            }
        });

        application.action_enabled_changed.connect ((name, enabled) => {
            switch (name) {
                case Application.ACTION_NEXT:
                    send_property_change ("CanGoNext", can_go_next);
                    break;
                case Application.ACTION_PREVIOUS:
                    send_property_change ("CanGoPrevious", can_go_previous);
                    break;
                case Application.ACTION_PLAY_PAUSE:
                    send_property_change ("CanPlay", can_play);
                    break;
            }
        });
    }

    private void send_property_change (string name, Variant variant) {
        var invalid_builder = new VariantBuilder (new VariantType ("as"));

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
                    invalid_builder
                )
            );
        } catch (Error e) {
            critical ("Could not send MPRIS property change: %s", e.message);
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
