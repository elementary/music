/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2021 elementary, Inc. (https://elementary.io)
 */

public class Music.Application : Gtk.Application {
    public const string ACTION_PREFIX = "app.";
    public const string ACTION_NEXT = "action-next";
    public const string ACTION_PLAY_PAUSE = "action-play-pause";
    public const string ACTION_PREVIOUS = "action-previous";

    private const ActionEntry[] ACTION_ENTRIES = {
        { ACTION_PLAY_PAUSE, action_play_pause, null, "false" },
        { ACTION_NEXT, action_next },
        { ACTION_PREVIOUS, action_previous }
    };

    private PlaybackManager? playback_manager = null;

    public Application () {
        Object (
            application_id: "io.elementary.music",
            flags: ApplicationFlags.HANDLES_OPEN
        );
    }

    protected override void activate () {
        if (active_window == null) {
            add_action_entries (ACTION_ENTRIES, this);

            ((SimpleAction) lookup_action (ACTION_PLAY_PAUSE)).set_enabled (false);
            ((SimpleAction) lookup_action (ACTION_PLAY_PAUSE)).set_state (false);
            ((SimpleAction) lookup_action (ACTION_NEXT)).set_enabled (false);
            ((SimpleAction) lookup_action (ACTION_PREVIOUS)).set_enabled (false);

            playback_manager = PlaybackManager.get_default ();

            var mpris_id = Bus.own_name (
                BusType.SESSION,
                "org.mpris.MediaPlayer2.io.elementary.music",
                BusNameOwnerFlags.NONE,
                on_bus_acquired,
                null,
                null
            );

            if (mpris_id == 0) {
                warning ("Could not initialize MPRIS session.\n");
            }

            var main_window = new MainWindow () {
                default_width = 650,
                title = _("Music")
            };

            add_window (main_window);

            Gtk.IconTheme.get_for_display (Gdk.Display.get_default ()).add_resource_path ("/io/elementary/music");

            var granite_settings = Granite.Settings.get_default ();
            var gtk_settings = Gtk.Settings.get_default ();

            gtk_settings.gtk_application_prefer_dark_theme = (
                granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK
            );

            granite_settings.notify["prefers-color-scheme"].connect (() => {
                gtk_settings.gtk_application_prefer_dark_theme = (
                    granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK
                );
            });
        }

        active_window.present_with_time (Gdk.CURRENT_TIME);
    }

    protected override void open (File[] files, string hint) {
        if (active_window == null) {
            activate ();
        }

        playback_manager.queue_files (files);
    }

    private void action_play_pause () {
        var play_pause_action = lookup_action (ACTION_PLAY_PAUSE);
        if (play_pause_action.get_state ().get_boolean ()) {
            ((SimpleAction) play_pause_action).set_state (false);
        } else {
            ((SimpleAction) play_pause_action).set_state (true);
        }
    }

    private void action_next () {
        playback_manager.next ();
    }

    private void action_previous () {
        playback_manager.previous ();
    }

    private void on_bus_acquired (DBusConnection connection, string name) {
        try {
            connection.register_object ("/org/mpris/MediaPlayer2", new MprisRoot ());
            connection.register_object ("/org/mpris/MediaPlayer2", new MprisPlayer (connection));
        } catch (IOError e) {
            warning ("could not create MPRIS player: %s\n", e.message);
        }
    }

    public static int main (string[] args) {
        Gst.init (ref args);
        return new Music.Application ().run (args);
    }
}
