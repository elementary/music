/*-
 * Copyright (c) 2011-2012       Scott Ringwelski <sgringwe@mtu.edu>
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
 */

using Gtk;
using Granite.Services;

namespace Option {
//		[CCode (array_length = false, array_null_terminated = true)]
//		static string[] to_add;
//		static string to_play;
#if HAVE_STORE
		static bool enable_store = false;
#endif
		static bool debug = false;
}

public class BeatBox.Beatbox : Granite.Application {
	public static Granite.Application app;

	public static LibraryWindow _program;
	unowned string[] args;
	BeatBox.Settings settings;

	static const OptionEntry[] my_options = {
		{ "debug", 'd', 0, OptionArg.NONE, ref Option.debug, "Enable debug logging", null },
/*
		{ "add-to-library", 'a', 0, OptionArg.FILENAME_ARRAY, ref Option.to_add, "Adds the list of files to the BeatBox library", "FILE1 FILE2 ..." },
		{ "play-uri", 'p', 0, OptionArg.STRING, ref Option.to_play, "Plays given uri", "URI" },
*/
		{ null }
	};

	public static int main(string[] args) {
		var opt_context = new OptionContext("- Noise help page.");
		opt_context.set_help_enabled(true);
		opt_context.add_main_entries(my_options, "noise");
		opt_context.add_group(Gtk.get_option_group(true));

		try {
			opt_context.parse(ref args);
		}
		catch(Error err) {
			stdout.printf("Error parsing arguments: %s\n", err.message);
		}

		Gdk.threads_init();
		Gdk.threads_enter();
		Gtk.init(ref args);
		Gdk.threads_leave();
		//BeatBox.clutter_usable = GtkClutter.init(ref args) == Clutter.InitError.SUCCESS;

		Notify.init("noise");

		app = new Beatbox();
		app.set_application_id("net.launchpad.noise");
		app.flags = ApplicationFlags.FLAGS_NONE;
		//((Beatbox)app).args = args;

		app.command_line.connect(command_line_event);

		// FIXME: passing any args will crash app
		string[] fake = {};
		unowned string[] fake_u = fake;
		return app.run(fake_u);
	}

	construct {
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

		about_authors = {"Scott Ringwelski <sgringwe@mtu.edu>", "Victor Eduardo <victoreduardm@gmail.com>", null};

		about_artists = {"Daniel Foré <daniel@elementaryos.org>", null};
	}

	public static int command_line_event() {
		return 0;
	}

	Plugins.Manager plugins_manager;

	public Beatbox () {
		// Load settings
		settings = new BeatBox.Settings ();
		plugins_manager = new Plugins.Manager (settings.plugins, settings.ENABLED_PLUGINS,
		                                        Build.CMAKE_INSTALL_PREFIX + "/lib/noise/plugins/");
	}

	protected override void activate () {
		if (_program != null) {
			_program.present (); // present window if app is already open
			//stdout.printf("to play is %s\n", Option.to_play);
			return;
		}

		// Setup debugger
		if (Option.debug)
			Logger.DisplayLevel = LogLevel.DEBUG;
		else
			Logger.DisplayLevel = LogLevel.INFO;


		_program = new BeatBox.LibraryWindow(this, settings, args);
		_program.build_ui();
		plugins_manager.hook_new_window (_program);

#if HAVE_PODCASTS
		Timeout.add(15000, () => {
			if(!_program.lm.have_fetched_new_podcasts) {
				_program.lm.pm.find_new_podcasts();
			}

			return false;
		});
#endif

#if 0
		// a test
		/*bool connected = false;
		try {
			connected = File.new_for_uri("http://www.google.com").query_exists();
		}
		catch(Error err) {
			connected = false;
		}
		stdout.printf("connected is %d\n", connected ? 1 : 0);*/
		// finish test
		if(Option.to_play != null) {
			stdout.printf("not null\n");
			File f = File.new_for_uri(Option.to_play);
			if(f.query_exists()) {
				stdout.printf("query exists\n");

				/*Media temp = _program.lm.fo.import_media(f.get_path());

				temp.isTemporary = true;
				_program.lm.add_media(temp, false);
				_program.lm.playMedia(temp.rowid);
				stdout.printf("media played %s %s %d\n", temp.title, temp.artist, temp.rowid);*/
			}
		}
		else if(Option.to_add.length > 0) {

		}
#endif

		_program.set_application(this);
	}
}

