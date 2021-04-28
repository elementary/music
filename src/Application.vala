// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012-2018 elementary LLC. (https://elementary.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * The Music authors hereby grant permission for non-GPL compatible
 * GStreamer plugins to be used and distributed together with GStreamer
 * and Music. This permission is above and beyond the permissions granted
 * by the GPL license by which Music is covered. If you modify this code
 * you may extend this exception to your version of the code, but you are not
 * obligated to do so. If you do not wish to do so, delete this exception
 * statement from your version.
 *
 * Authored by: Victor Eduardo <victoreduardm@gmail.com>
 */

public class Music.App : Gtk.Application {
    public static GLib.Settings equalizer_settings { get; private set; }
    public static GLib.Settings settings { get; private set; }
    public static GLib.Settings saved_state { get; private set; }
    public static PlaybackManager player { get; private set; }
    private LocalLibrary library_manager { get; private set; }
    public static LibraryWindow main_window { get; private set; }

    static construct {
        equalizer_settings = new GLib.Settings ("io.elementary.music.equalizer");
        saved_state = new GLib.Settings ("io.elementary.music.saved-state");
        settings = new GLib.Settings ("io.elementary.music.settings");
    }

    construct {
        // This allows opening files. See the open() method below.
        flags |= ApplicationFlags.HANDLES_OPEN;

        // App info
        application_id = "io.elementary.music";

        weak Gtk.IconTheme default_theme = Gtk.IconTheme.get_default ();
        default_theme.add_resource_path ("/io/elementary/music");

        var provider = new Gtk.CssProvider ();
        provider.load_from_resource ("io/elementary/music/application.css");
        Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        var granite_settings = Granite.Settings.get_default ();
        var gtk_settings = Gtk.Settings.get_default ();

        gtk_settings.gtk_application_prefer_dark_theme = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;

        granite_settings.notify["prefers-color-scheme"].connect (() => {
            gtk_settings.gtk_application_prefer_dark_theme = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
        });

        var present_action = new SimpleAction ("app.present", null);
        present_action.activate.connect (() => {
            if (main_window != null) {
                main_window.present_with_time ((uint32) GLib.get_monotonic_time ());
            }
        });

        add_action (present_action);
    }

    public override void open (File[] files, string hint) {
        // Activate, then play files
        if (library_manager == null) {
            activate ();
        }
        library_manager.play_files (files);
    }


    protected override void activate () {
        if (main_window == null) {
            libraries_manager = new LibrariesManager ();

            library_manager = new LocalLibrary ();
            player = new PlaybackManager ();
            library_manager.initialize_library ();
            libraries_manager.add_library (library_manager);
            main_window = new LibraryWindow (this);
            main_window.build_ui ();

            MediaKeyListener.instance.init ();

            MPRIS.initialize ();

            var plugins = Plugins.Manager.get_default ();
            plugins.hook_app (this);
            plugins.hook_new_window (main_window);
        }

        main_window.present ();
    }
}

public static int main (string[] args) {
    Gtk.init (ref args);
    Gda.init ();

    try {
        Gst.init_check (ref args);
    } catch (Error err) {
        error ("Could not init GStreamer: %s", err.message);
    }

    GLib.Environ.set_variable ({"PULSE_PROP_media.role"}, "audio", "true");

    var app = new Music.App ();
    return app.run (args);
}
