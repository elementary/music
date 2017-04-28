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

        app_copyright = "2012-2016";
        application_id = "org.pantheon.noise";
        app_icon = "multimedia-audio-player";
        app_launcher = "org.pantheon.noise.desktop";
        app_years = "2012-2016";

        main_url = "https://github.com/elementary/music";
        bug_url = "https://github.com/elementary/music/issues";
        help_url = "https://elementary.io/help/noise";
        translate_url = "https://l10n.elementary.io/projects/music";

        about_authors = {"Corentin Noël <corentin@elementary.io>",
                         "Scott Ringwelski <sgringwe@mtu.edu>", null};

        about_artists = {"Daniel Foré <daniel@elementary.io>", null};
        about_translators = _("translator-credits");
        
        var present_action = new SimpleAction ("app.present", null);
        present_action.activate.connect (() => {
            if (main_window != null) {
                main_window.present_with_time ((uint32) GLib.get_monotonic_time ());
            }
        });

        this.add_action (present_action);
    }

    public override void open (File[] files, string hint) {
        // Activate, then play files
        if (library_manager == null) {
            this.activate ();
        }
        library_manager.play_files (files);
    }


    protected override void activate () {
        if (main_window == null) {
            if (DEBUG)
                Granite.Services.Logger.DisplayLevel = Granite.Services.LogLevel.DEBUG;
            else
                Granite.Services.Logger.DisplayLevel = Granite.Services.LogLevel.INFO;

            libraries_manager = new LibrariesManager ();

            // Load icon information. Needed until vala supports initialization of static
            // members. See https://bugzilla.gnome.org/show_bug.cgi?id=543189
            Icons.init ();

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

    /**
     * We use this identifier to init everything inside the application.
     * For instance: libnotify, etc.
     */
    public string get_id () {
        return application_id;
    }

    /**
     * @return the application's brand name. Should be used for anything that requires
     * branding. For instance: Ubuntu's sound menu, dialog titles, etc.
     */
    public string get_name () {
        return program_name;
    }

    /**
     * @return the application's desktop file name.
     */
    public string get_desktop_file_name () {
        return app_launcher;
    }
}
