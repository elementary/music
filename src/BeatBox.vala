/*-
 * Copyright (c) 2011       Scott Ringwelski <sgringwe@mtu.edu>
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

public class BeatBox.Beatbox : Granite.Application {
	public static LibraryWindow _program;
	public static bool enableStore;
	public static unowned string[] args;
	
	const Gtk.StockItem[] stock_items = {
		{ "beatbox", null, 0, 0 },
		{ "library-music", null, 0, 0 },
		{ "library-podcast", null, 0, 0},
		{ "library-audiobook", null, 0, 0},
		{ "media-audio", null, 0, 0 },
		{ "emblem-urgent", null, 0, 0 },
		{ "playlist", null, 0, 0 },
		{ "playlist-automatic", null, 0, 0 },
		{ "starred", null, 0, 0 },
		{ "not-starred", null, 0, 0 },
		{ "audio-volume-high", null, 0, 0 },
		{ "media-playlist-repeat-active-symbolic", null, 0, 0},
		{ "media-playlist-repeat-symbolic", null, 0, 0},
		{ "media-playlist-shuffle-active-symbolic", null, 0, 0},
		{ "media-playlist-shuffle-symbolic", null, 0, 0},
		{ "info", null, 0, 0 },
		{ "lastfm-love", null, 0, 0},
		{ "lastfm-ban", null, 0, 0},
		{ "view-list-icons-symbolic", null, 0, 0},
		{ "view-list-details-symbolic", null, 0, 0},
		{ "view-list-column-symbolic", null, 0, 0},
		{ "drop-album", null, 0, 0},
		{ "view-list-video-symbolic", null, 0, 0},
		{ "media-optical-audio", null, 0, 0},
		{ "phone", null, 0, 0},
		{ "multimedia-player", null, 0, 0},
		{ "media-eject", null, 0, 0 },
		{ "process-completed-symbolic", null, 0, 0},
		{ "process-error-symbolic", null, 0, 0}
		
    };
    
    public static int main(string[] args) {
		Gtk.init(ref args);
		Gdk.threads_init();
		Notify.init("beatbox");
		add_stock_images();
		
		var app = new Beatbox();
		app.args = args;
		return app.run(args);
	}
	
	construct {
		// App info
		build_data_dir = Build.DATADIR;
		build_pkg_data_dir = Build.PKG_DATADIR;
		build_release_name = Build.RELEASE_NAME;
		build_version = Build.VERSION;
		build_version_info = Build.VERSION_INFO;
		
		program_name = "BeatBox";
		exec_name = "beatbox";
		
		app_copyright = "2011";
		application_id = "net.launchpad.beatbox";
		app_icon = "beatbox";
		app_launcher = "beatbox.desktop";
		app_years = "2010-2011";
		
		main_url = "https://launchpad.net/beat-box";
		bug_url = "https://bugs.launchpad.net/beat-box/+filebug";
		help_url = "https://answers.launchpad.net/beat-box";
		translate_url = "https://translations.launchpad.net/beat-box";
		
		about_authors = {"Scott Ringwelski <sgringwe@mtu.edu>"};
	}
    
	protected override void activate () {
		if (_program != null) {
			_program.present (); // present window if app is already open
			return;
		}
		
		_program = new BeatBox.LibraryWindow(this, args);
		_program.build_ui();
		_program.set_application(this);
	}
	
	public static void add_stock_images() {
		var iFactory = new Gtk.IconFactory();
		
		//add beatbox's items
		foreach(StockItem stockItem in stock_items) {
			var iconSet = new IconSet();
			var iconSource = new IconSource();
			
			if(stockItem.translation_domain != null) {
				iconSource.set_icon_name(stockItem.translation_domain);
				stockItem.translation_domain = null;
                iconSet.add_source(iconSource);
			}
			iconSource.set_icon_name(stockItem.stock_id);
			iconSet.add_source(iconSource);
			iFactory.add(stockItem.stock_id, iconSet);
		}
		
		Gtk.Stock.add(stock_items);
		iFactory.add_default();
	}
}
