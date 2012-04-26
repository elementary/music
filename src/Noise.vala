// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2011-2012 Scott Ringwelski <sgringwe@mtu.edu>
 * Copyright (c) 2012 Noise Developers
 *
 * Originally Written by Scott Ringwelski for BeatBox Music Player
 * BeatBox Music Player: http://www.launchpad.net/beat-box
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Scott Ringwelski <sgringwe@mtu.edu>
 *              Victor Eduardo <victoreduardm@gmail.com>
 */


namespace BeatBox {

    namespace Options {
        public bool debug = false;
        public bool disable_plugins = false;
    }

    public static int main (string[] args) {
        var context = new OptionContext ("- Noise help page.");
        context.add_main_entries (Beatbox.app_options, "noise");
        context.add_group (Gtk.get_option_group (true));

        try {
            context.parse (ref args);
        }
        catch (Error err) {
            warning ("Error parsing arguments: %s\n", err.message);
        }

        Gtk.init (ref args);
        Gst.init (ref args);

        var app = new Beatbox ();
        return app.run (args);
    }


    /**
     * Application class
     */

    public class Beatbox : Granite.Application {

        public BeatBox.Settings        settings        { get; private set; }
        public BeatBox.LibraryWindow   library_window  { get; private set; }
        public BeatBox.Plugins.Manager plugins_manager { get; private set; }

        private const string PLUGINS_DIR = Build.CMAKE_INSTALL_PREFIX + "/lib/noise/plugins/";

        public bool is_ready {
            get {
                return (library_window == null || library_window.lm == null ||
                        !library_window.initialization_finished);
            }
        }

        public static const OptionEntry[] app_options = {
            { "debug", 'd', 0, OptionArg.NONE, ref Options.debug, N_("Enable debug logging"), null },
            { "no-plugins", 'n', OptionArg.NONE, ref Options.disable_plugins, N_("Disable plugins"), null},
            { null }
        };

        construct {
            // This allows opening files. See the open() method below.
            flags |= ApplicationFlags.HANDLES_OPEN;

            // App info
            build_data_dir = Build.DATADIR;
            build_pkg_data_dir = Build.PKG_DATADIR;
            build_release_name = Build.RELEASE_NAME;
            build_version = Build.VERSION;
            build_version_info = Build.VERSION_INFO;

            program_name = "Noise";
            exec_name = "noise";

            app_copyright = "2012";
            application_id = "net.launchpad.noise";
            app_icon = "noise";
            app_launcher = "noise.desktop";
            app_years = "2012";

            main_url = "https://launchpad.net/noise";
            bug_url = "https://bugs.launchpad.net/noise/+filebug";
            help_url = "http://elementaryos.org/support/answers";
            translate_url = "https://translations.launchpad.net/noise";

            about_authors = {"Scott Ringwelski <sgringwe@mtu.edu>",
                             "Victor Eduardo M. <victoreduardm@gmail.com>", null};

            about_artists = {"Daniel Foré <daniel@elementaryos.org>", null};
        }

        public Beatbox () {
            // Create settings
            settings = new BeatBox.Settings ();

            if (!Options.disable_plugins)
                plugins_manager = new Plugins.Manager (settings.plugins, settings.ENABLED_PLUGINS, PLUGINS_DIR);
        }

        public override void open (File[] files, string hint) {
            if (is_ready) { // Open files right away
                open_files (files, hint);
            }
            else { // If the library manager is still not ready, keep trying
                // every 100ms ...
                Timeout.add (100, () => {
                    if (is_ready) {
                        open_files (files, hint);
                        return false;
                    }
                    return true; // keep trying...
                });
            }
        }

        private void open_files (File[] files, string hint) {
#if HAVE_EXTERNAL_FILE_SUPPORT
            var to_add = new Gee.LinkedList<string> ();
            for (int i = 0; i < files.length; i++) {
                var file = files[i];
                if (file != null)
                    to_add.add (file.get_uri ());
            }
            library_window.lm.add_files_and_queue (to_add);
#endif
        }

        /**
         * These methods are here to make transitioning to other Application APIs
         * easier in the future.
         */

        /**
         * We use this identifier to init everything inside the application.
         * For instance: MPRIS, libnotify, etc.
         */
        public string get_id () {
            return application_id;
        }

        /**
         * Returns:
         * the application's brand name. Should be used for anything that requires
         * branding. For instance: Ubuntu's sound menu, dialog titles, etc.
         */
        public string get_name () {
            return program_name;
        }

        /**
         * Returns:
         * the application's desktop file name.
         */
        public string get_desktop_file_name () {
            return app_launcher;
        }

        protected override void activate () {
            // present window if app is already open
            if (library_window != null) {
                library_window.present ();
                return;
            }

            // Setup debugger
            if (Options.debug)
                Granite.Services.Logger.DisplayLevel = Granite.Services.LogLevel.DEBUG;
            else
                Granite.Services.Logger.DisplayLevel = Granite.Services.LogLevel.INFO;

            if (!Options.disable_plugins)
                plugins_manager.hook_new_window (library_window);

            library_window = new BeatBox.LibraryWindow (this);
            library_window.build_ui ();
        }
    }
}

