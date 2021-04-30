/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2021 elementary, Inc. (https://elementary.io)
 */

[DBus (name = "org.gnome.SettingsDaemon.MediaKeys")]
public interface GnomeMediaKeys : Object {
    public abstract void grab_media_player_keys (string application, uint32 time) throws GLib.Error;
    public abstract void release_media_player_keys (string application) throws GLib.Error;
    public signal void media_player_key_pressed (string application, string key);
}

public class Music.MediaKeyListener : Object {
    private GnomeMediaKeys? media_object;
    private Gtk.Application application;

    private static MediaKeyListener? _instance;
    public static MediaKeyListener get_default () {
        if (_instance == null) {
            _instance = new MediaKeyListener ();
        }

        return _instance;
    }

    private MediaKeyListener () {
        assert (media_object == null);

        application = (Gtk.Application) GLib.Application.get_default ();

        try {
            media_object = Bus.get_proxy_sync (
                BusType.SESSION,
                "org.gnome.SettingsDaemon.MediaKeys",
                "/org/gnome/SettingsDaemon/MediaKeys"
            );
        } catch (Error e) {
            critical ("Mediakeys error: %s", e.message);
        }

        if (media_object != null) {
            media_object.media_player_key_pressed.connect (media_key_pressed);
            try {
                media_object.grab_media_player_keys (application.application_id, (uint32)0);
            } catch (Error err) {
                critical ("Could not grab media player keys: %s", err.message);
            }
        }
    }

    public void release_media_keys () {
        try {
            media_object.release_media_player_keys (GLib.Application.get_default ().application_id);
        } catch (Error err) {
            critical ("Could not release media player keys: %s", err.message);
        }
    }

    private void media_key_pressed (dynamic Object bus, string media_application, string key) {
        if (media_application != application.application_id) {
            return;
        }

        var main_window = (Gtk.ApplicationWindow)(application).active_window;

        switch (key) {
            case "Play":
                main_window.activate_action (
                    Music.MainWindow.ACTION_PLAY_PAUSE,
                    null
                );
                break;
            default:
                debug ("Unused media key pressed: %s", key);
                break;
        }
    }
}
