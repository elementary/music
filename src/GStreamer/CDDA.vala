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

using Gst;
using Gee;

public class BeatBox.CDDA : GLib.Object {
	public static LinkedList<Media> getMediaList(string device_path) {
		var rv = new LinkedList<Media>();
		File device_file;
		FileInfo device_info;
		string album_name;
		string album_artist;
		string album_genre;
		
		device_file = File.new_for_path(device_path);
		if(!device_file.query_exists()) {
			warning("Could not locate device file at %s. Audio disc will be invalid\n", device_file.get_path());
			return rv;
		}
		
		try {
			device_info = device_file.query_info("xattr::*", FileQueryInfoFlags.NONE);
			
			if(device_info == null) {
				warning("could not get device attr\n");
				return rv;
			}
			
			album_name = device_info.get_attribute_string("xattr::org.gnome.audio.title");
			album_artist = device_info.get_attribute_string("xattr::org.gnome.audio.artist");
			album_genre = device_info.get_attribute_string("xattr::org.gnome.audio.genre");
		
			var enumerator = device_file.enumerate_children("xattr::*", FileQueryInfoFlags.NONE);
			if(enumerator == null) {
				warning("Could not enumerate tracks\n");
				return rv;
			}
		
			int index = 1;
			for (device_info = enumerator.next_file(); device_info != null; device_info = enumerator.next_file()) {
				Media s = new Media("cdda://" + index.to_string());
				s.isTemporary = true;
				
				var title = device_info.get_attribute_string("xattr::org.gnome.audio.title");
				var artist = device_info.get_attribute_string("xattr::org.gnome.audio.artist");
				var length = (int)device_info.get_attribute_uint64("xattr::org.gnome.audio.duration");
				
				s.track = index;
				s.length = length; // no need to check, it's our best guess either way
				
				if(title != null)
					s.title = title;
				else
					s.title = _("Unknown Title");
					
				if(artist != null)
					s.artist = artist;
				else
					s.artist = _("Unknown Artist");
					
				if((album_name == null || album_name != "" || album_genre == null || album_genre == "") && index == 1) {
					var info = getInfoFromTitleArtist(s.artist, s.title);
					
					if(info != null) {
						if(album_name == null || album_name == "")
							album_name = info.album;
						if((album_genre == null || album_genre == "") && info.tagStrings().size > 0)
							album_genre = info.tagStrings().get(0);
						
					}
				}
					
				if(album_name != null && album_name != "")
					s.album = album_name;
				else {
					s.album = _("Unknown Album");
				}
				
				if(album_genre != null && album_genre != "")
					s.genre = album_genre;
				else
					s.genre = "";
				
				if(album_artist != null)
					s.album_artist = album_artist;
				if(album_genre != null)
					s.genre = album_genre;
				
				// do some checks
				bool artistValid = (s.artist != null && s.artist != _("Unknown Artist"));
				bool albumArtistValid = (album_artist != null && album_artist != _("Unknown Artist"));
				
				if(artistValid && !albumArtistValid)
					s.album_artist = s.artist;
				else if(!artistValid && albumArtistValid)
					s.artist = s.album_artist;
					
				// remove artist name from title
				s.title = remove_artist_from_title(s.title, s.artist);
				
				// capatalize nicely
				s.title = to_caps(s.title);
				s.artist = to_caps(s.artist);
				s.album_artist = to_caps(s.album_artist);
				s.album = to_caps(s.album);
				s.genre = to_caps(s.genre);
				
				message("Added %s %s %s %s\n", s.title, s.artist, s.album_artist, s.genre);
				rv.add(s);
				
				++index;
			}
		} catch(GLib.Error err) {
			warning("Could not enumerate tracks or access album info\n");
		}
		
		return rv;
	}
	
	public static string remove_artist_from_title(string orig, string artist) {
		string s = orig.down();
		string art = artist.down();
		
		int needle_index = s.index_of(art);
		
		if(needle_index != -1) {
			s = s.replace(art, "");
			s = s.strip();
			
			if(s.get_char(0) == '-' || s.get_char(s.length - 1) == '-') {
				s = s.replace("-", "");
				s = s.strip();
			}
		}
		
		return s;
	}
	
	public static string to_caps(string orig) {
		var builder = new StringBuilder ();
		
		string s = orig.down();
		unichar c;
		bool capNext = true;
		for (int i = 0; s.get_next_char(ref i, out c);) {
			if(capNext) {
				builder.append(c.to_string().up());
				capNext = false;
			}
			else if(c.to_string() == " ") {
				capNext = true;
				builder.append(c.to_string());
			}
			else {
				builder.append(c.to_string());
			}
		}
		
		return builder.str;
	}
	
	public static LastFM.TrackInfo getInfoFromTitleArtist(string artist, string title) {
		LastFM.TrackInfo track = new LastFM.TrackInfo.basic();
		
		track = new LastFM.TrackInfo.with_info(artist, title);
		
		return track;
	}
	
}
