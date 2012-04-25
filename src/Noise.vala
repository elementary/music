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
#if HAVE_STORE
        public bool enable_store = false;
#endif
        public bool debug = false;
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

        Gtk.init(ref args);
        Gst.init (ref args);

        var app = new Beatbox();
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

        public static const OptionEntry[] app_options = {
            { "debug", 'd', 0, OptionArg.NONE, ref Options.debug, "Enable debug logging", null },
            { null }
        };

        construct {
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

            plugins_manager = new Plugins.Manager (settings.plugins, settings.ENABLED_PLUGINS, PLUGINS_DIR);

            // Connect command line handler and file open handler
            command_line.connect (command_line_event);
        }

        public int command_line_event (Application appl, ApplicationCommandLine command) {
            message ("Received command line event. Command line interface not yet implemented");
            return 0;
        }

        public override void open (File[] files, string hint) {
            message ("File opening still not implemented. [hint = %s]", hint);

            if (library_window == null || library_window.lm == null || !library_window.initialization_finished)
                return;

            // Let's add this stuff to the queue
            for (int i = 0; i < files.length; i++) {
                var file = files[i];
                if (file != null) {
                    message ("Adding %s to play queue", file.get_uri ());
                }                                    
            }
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

            library_window = new BeatBox.LibraryWindow (this);
            library_window.build_ui ();
            plugins_manager.hook_new_window (library_window);
        }
    }
}

