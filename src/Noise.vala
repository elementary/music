// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012-2017 elementary LLC. (https://elementary.io)
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
 * The Noise authors hereby grant permission for non-GPL compatible
 * GStreamer plugins to be used and distributed together with GStreamer
 * and Noise. This permission is above and beyond the permissions granted
 * by the GPL license by which Noise is covered. If you modify this code
 * you may extend this exception to your version of the code, but you are not
 * obligated to do so. If you do not wish to do so, delete this exception
 * statement from your version.
 *
 * Authored by: Victor Eduardo <victoreduardm@gmail.com>
 */

public class Noise.App : Granite.Application {
    public static PlaybackManager player { get; private set; }
    private LocalLibrary library_manager { get; private set; }
    public static LibraryWindow main_window { get; private set; }

    construct {
        // This allows opening files. See the open() method below.
        flags |= ApplicationFlags.HANDLES_OPEN;

        // App info
        build_data_dir = Build.DATADIR;
        build_pkg_data_dir = Build.PKG_DATADIR;
        build_release_name = Build.RELEASE_NAME;
        build_version = Build.VERSION;
        build_version_info = Build.VERSION_INFO;

        program_name = _(Build.APP_NAME);
        exec_name = "noise";

        application_id = "org.pantheon.noise";
        app_launcher = "org.pantheon.noise.desktop";

        weak Gtk.IconTheme default_theme = Gtk.IconTheme.get_default ();
        default_theme.add_resource_path ("/io/elementary/music");

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
            main_window = new LibraryWindow ();
            main_window.build_ui ();
            main_window.set_application (this);

            MediaKeyListener.instance.init ();

            var plugins = Plugins.Manager.get_default ();
            plugins.hook_app (this);
            plugins.hook_new_window (main_window);
        }

        main_window.present ();
    }
}
