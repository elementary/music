/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2021 elementary, Inc. (https://elementary.io)
 */

public class Music.Application : Gtk.Application {
    public const string ACTION_PREFIX = "app.";
    public const string ACTION_PLAY_PAUSE = "action-play-pause";

    private const ActionEntry[] ACTION_ENTRIES = {
        { ACTION_PLAY_PAUSE, action_play_pause, null, "false" },
    };

    private PlaybackManager playback_manager;

    public Application () {
        Object (
            application_id: "io.elementary.music",
            flags: ApplicationFlags.HANDLES_OPEN
        );
    }

    protected override void activate () {
        MediaKeyListener.get_default ();
        playback_manager = PlaybackManager.get_default ();

        add_action_entries (ACTION_ENTRIES, this);

        var main_window = new MainWindow () {
            application = this,
            title = _("Music")
        };
        main_window.show_all ();

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

    protected override void open (File[] files, string hint) {
        activate ();
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

    public static int main (string[] args) {
        Gst.init (ref args);
        return new Music.Application ().run (args);
    }
}
