/*-
 * Copyright (c) 2011       Scott Ringwelski <sgringwe@mtu.edu>
 *
 * Originaly Written by Scott Ringwelski for BeatBox Music Player
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

public class BeatBox.Beatbox : GLib.Object {
	public static LibraryWindow _program;
	public static bool enableStore;
	
	/*public const string STOCK_BEATBOX = "beatbox";
	public const string STOCK_MUSIC_LIBRARY = "folder-music";
	public const string STOCK_MEDIA_QUEUE = "media-audio";
	public const string STOCK_MEDIA_ALREADY_PLAYED = "emblem-urgent";
	public const string STOCK_PLAYLIST = "playlist";
	public const string STOCK_PLAYLIST_AUTOMATIC = "playlist-automatic";
	public const string STOCK_SONG_STARRED = "starred";
	public const string STOCK_SONG_NOT_STARRED = "not-starred";
	public const string STOCK_NOW_PLAYING = "audio-volume-high";*/
	
	const Gtk.StockItem[] stock_items = {
		{ "beatbox", null, 0, 0 },
		{ "folder-music", null, 0, 0 },
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
		
		//Unique.App app = new Unique.App ("org.elementary.beatbox", null);
		
		//enableStore = (args[1] == "elementary") && (args[2] == "rocks");
	
		/*if (app.is_running) { //not starting if already running
			Unique.Command command = Unique.Command.ACTIVATE;
			Unique.MessageData message = new Unique.MessageData();
			app.send_message (command, message);
		} else {*/
			Gdk.threads_init();
			Notify.init("beatbox");
			
			//check for .desktop file
			/*var desktop_file = File.new_for_path("/usr/share/applications/beatbox.desktop");
			
			if(!desktop_file.query_exists()) {
				stdout.printf("Creating .desktop file\n");
				try {
					var file_stream = desktop_file.create (FileCreateFlags.NONE);
					var data_stream = new DataOutputStream (file_stream);
					data_stream.put_string (desktopString());
				}
				catch(GLib.Error err) {
					stdout.printf("Could not create .desktop file: %s\n", err.message);
				}
			}*/
			
			add_stock_images();
						
			_program = new BeatBox.LibraryWindow(args);
			//app.watch_window(_program);
			
			Gtk.main();
		//}
		
        return 1;
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
	
	/*private static string desktopString() {
		string rv = "[Desktop Entry]";
		rv += "Type=Application";
		rv += "Version=0.1";
		rv += "Name=BeatBox";
		rv += "GenericName=Music Player";
		rv += "Exec=beatbox";
		rv += "Icon=beatbox";
		rv += "Terminal=false";
		rv += "Categories=GNOME;Audio;Music;Player;AudioVideo;";
		rv += "MimeType=x-content/audio-player;";
		rv += "StartupNotify=true";
		
		return rv;
	}*/
}
