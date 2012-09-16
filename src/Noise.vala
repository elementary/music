// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012 Noise Developers (http://launchpad.net/noise)
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
    private static App _instance;
    public static App instance {
        get {
            if (_instance == null)
                _instance = new App ();
            return _instance;
        }
    }

    // TODO: Expose Noise.Player instead of PlaybackManager
    public static PlaybackManager player { get; private set; }
    public static LibraryManager library_manager { get; private set; }
    public static LibraryWindow main_window { get; private set; }
    public static Noise.Plugins.Manager plugins { get; private set; }


    // Should always match those used in the .desktop file 
    public const string[] CONTENT_TYPES = {
        "x-content/audio-player",
        "x-content/audio-cdda",
        "application/x-ogg",
        "application/ogg",
        "audio/x-vorbis+ogg",
        "audio/x-scpls",
        "audio/x-mp3",
        "audio/x-mpeg",
        "audio/mpeg",
        "audio/x-mpegurl",
        "audio/x-flac"
    };


#if ENABLE_EXPERIMENTAL
    /**
     * @return whether the application is the default for handling audio files
     */
    public bool is_default_application {
        get {
            foreach (string content_type in CONTENT_TYPES) {
                var default_app = AppInfo.get_default_for_type (content_type, true).get_id ();
                if (default_app != get_desktop_file_name ())
                    return false;
            }

            return true;
        }
        set {
            var info = new DesktopAppInfo (get_desktop_file_name ());

            foreach (string content_type in CONTENT_TYPES) {
                try {
                    if (value)
                        info.set_as_default_for_type (content_type);
                    else
                        info.reset_type_associations (content_type);
                } catch (Error err) {
                    warning ("Cannot set Noise as default audio player for %s: %s",
                             content_type, err.message);
                }
            }
        }
    }
#endif


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
        application_id = "org.pantheon.noise";
        app_icon = "noise";
        app_launcher = "noise.desktop";
        app_years = "2012";

        main_url = "https://launchpad.net/noise";
        bug_url = "https://bugs.launchpad.net/noise/+filebug";
        help_url = "http://elementaryos.org/support/answers";
        translate_url = "https://translations.launchpad.net/noise";

        about_authors = {"Scott Ringwelski <sgringwe@mtu.edu>",
                         "Victor Eduardo M. <victoreduardm@gmail.com>",
                         "Corentin Noël <tintou@mailoo.org>", null};

        about_artists = {"Daniel Foré <daniel@elementaryos.org>", null};
    }


    public override void open (File[] files, string hint) {
        // Activate, then play files
        this.activate ();
        library_manager.play_files (files);
    }


    protected override void activate () {
        // Setup debugger
        if (DEBUG)
            Granite.Services.Logger.DisplayLevel = Granite.Services.LogLevel.DEBUG;
        else
            Granite.Services.Logger.DisplayLevel = Granite.Services.LogLevel.INFO;


        // present window if app is already open
        if (main_window != null) {
            main_window.present ();
            return;
        }

        plugins = new Noise.Plugins.Manager (Build.PLUGIN_DIR, exec_name, null);
        plugins.hook_app (this);

        // Load icon information. Needed until vala supports initialization of static
        // members. See https://bugzilla.gnome.org/show_bug.cgi?id=543189
        Icons.init ();

        player = new PlaybackManager ();
        library_manager = new LibraryManager ();
        main_window = new LibraryWindow ();
        main_window.build_ui ();
        main_window.set_application (this);

        MediaKeyListener.instance.init ();

        plugins.hook_new_window (main_window);
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
