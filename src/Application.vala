/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2021 elementary, Inc. (https://elementary.io)
 */

public class Music.Application : Gtk.Application {
    public const string ACTION_PREFIX = "app.";
    public const string ACTION_NEXT = "action-next";
    public const string ACTION_PLAY_PAUSE = "action-play-pause";
    public const string ACTION_PREVIOUS = "action-previous";
    public const string ACTION_SHUFFLE = "action-shuffle";
    public const string ACTION_FIND = "action-find";
    public const string ACTION_CLEAR_QUEUE = "action-clear-queue";
    public const string ACTION_QUIT = "action-quit";

    private const ActionEntry[] ACTION_ENTRIES = {
        { ACTION_FIND, action_find },
        { ACTION_QUIT, quit }
    };

    private PlaybackManager? playback_manager = null;

    public Application () {
        Object (
            application_id: "io.elementary.music",
            flags: ApplicationFlags.HANDLES_OPEN
        );
    }

    construct {
        GLib.Intl.setlocale (LocaleCategory.ALL, "");
        GLib.Intl.bindtextdomain (Constants.GETTEXT_PACKAGE, Constants.LOCALEDIR);
        GLib.Intl.bind_textdomain_codeset (Constants.GETTEXT_PACKAGE, "UTF-8");
        GLib.Intl.textdomain (Constants.GETTEXT_PACKAGE);
    }

    protected override void startup () {
        base.startup ();

        Granite.init ();

        playback_manager = PlaybackManager.get_default ();

        add_action_entries (ACTION_ENTRIES, this);

        set_accels_for_action (ACTION_PREFIX + ACTION_FIND, {"<Ctrl>F"});
        set_accels_for_action (ACTION_PREFIX + ACTION_QUIT, {"<Ctrl>Q"});

        var granite_settings = Granite.Settings.get_default ();
        var gtk_settings = Gtk.Settings.get_default ();

        gtk_settings.gtk_icon_theme_name = "elementary";
        gtk_settings.gtk_theme_name = "io.elementary.stylesheet.orange";

        gtk_settings.gtk_application_prefer_dark_theme = (
            granite_settings.prefers_color_scheme == DARK
        );

        granite_settings.notify["prefers-color-scheme"].connect (() => {
            gtk_settings.gtk_application_prefer_dark_theme = (
                granite_settings.prefers_color_scheme == DARK
            );
        });
    }

    protected override void activate () {
        if (active_window != null) {
            active_window.present ();
            return;
        }

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
            title = _("Music")
        };
        main_window.present ();

        add_window (main_window);

        /*
        * This is very finicky. Bind size after present else set_titlebar gives us bad sizes
        * Set maximize after height/width else window is min size on unmaximize
        * Bind maximize as SET else get get bad sizes
        */
        var settings = new Settings ("io.elementary.music");
        settings.bind ("window-height", main_window, "default-height", SettingsBindFlags.DEFAULT);
        settings.bind ("window-width", main_window, "default-width", SettingsBindFlags.DEFAULT);

        if (settings.get_boolean ("window-maximized")) {
            main_window.maximize ();
        }

        settings.bind ("window-maximized", main_window, "maximized", SettingsBindFlags.SET);

        // This needs to be done after window is constructed
        // Else music plays but the queue seems empty
        playback_manager.restore_queue ();
    }

    private static File[] list_directory (string directory) {
        Dir dir;
        try {
            dir = Dir.open (directory, 0);
        } catch (FileError e) {
            warning (e.message);
            return {};
        }

        string? name = null;
        File[] elements = {};

        while ((name = dir.read_name ()) != null) {
            var file_path = Path.build_filename (directory, name);
            var file = File.new_for_path (file_path);

            elements += file;
        }

        return elements;
    }

    public static File[] loop_through_files (File[] files) {
        // All of these will be returned later in bulk
        File[] elements = {};

        foreach (var file in files) {
            var file_path = file.get_path ();

            if (FileUtils.test (file_path, FileTest.IS_DIR)) {
                var directory_elements = list_directory (file_path);
                var directory_files = loop_through_files (directory_elements);

                foreach (var directory_file in directory_files) {
                    elements += directory_file;
                }

                continue;
            }

            if (M3U.is_playlist (file)) {

                File[]? tracks = null;
                try {
                    tracks = M3U.parse_playlist (file);

                } catch (Error e) {
                    warning (e.message);
                }

                if (tracks == null) {
                    continue;
                }

                foreach (var track in tracks) {
                    elements += track;
                }

                // Avoid adding the m3u - Else its content gets re-added every startup
                continue;
            }

            elements += file;
        }

        return elements;
    }

    protected override void open (File[] files, string hint) {
        if (active_window == null) {
            activate ();
        }

        var files_to_play = loop_through_files (files);
        debug ("Application: Number of files to play %u", files_to_play.length);
        playback_manager.queue_files (files_to_play);
    }

    private void action_find () {
        ((MainWindow)active_window).start_search ();
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
