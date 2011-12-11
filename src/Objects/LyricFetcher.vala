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

public class BeatBox.LyricFetcher : GLib.Object {

	private static const string URL_FORMAT = "http://www.azlyrics.com/lyrics/%s/%s.html";
	
	private string url;
	
	public signal void lyrics_fetched(string lyrics);
	
	public LyricFetcher() {
	
	}
	
	public void fetch_lyrics(string artist, string title) {
		
		parse_url (artist, title);
		
		try {
			Thread.create<void*>(fetch_lyrics_thread, false);
		}
		catch(GLib.ThreadError err) {
			stdout.printf("ERROR: Could not create lyrics thread: %s \n", err.message);
		}
	}
	
	public void* fetch_lyrics_thread () {
		File page = File.new_for_uri(url);
		
		uint8[] uintcontent;
		string etag_out;
		bool load_successful = false;
		string lyrics = "";
		
		try {
			page.load_contents(null, out uintcontent, out etag_out);
			load_successful = true;
		}
		catch(Error err) {
			stdout.printf("Could not load contents of %s: %s\n", url, err.message);
			load_successful = false;
		}
		
		if(load_successful) {
			string content = (string)uintcontent;
			
			const string START_STRING = "<!-- start of lyrics -->";
			const string END_STRING = "<!-- end of lyrics -->";
			
			var start = content.index_of(START_STRING, 0) + START_STRING.length;
			var end = content.index_of(END_STRING, start);
			
			if(start != -1 && end != -1 && end > start) {
				lyrics = content.substring(start, end - start);
				lyrics = lyrics.replace("<br><br>", "").replace("<br>","").replace("<i>","").replace("</i>","").strip();
			}
		}
		
		Idle.add( () => {
			lyrics_fetched(lyrics);
			return false;
		});
		
		
		return null;
	}
	
	private void parse_url (string artist, string title) {

		url = URL_FORMAT.printf (fix_string (artist), fix_string (title));
	}
	
	private string fix_string (string? str) {

		string rv = "";

		if (str == null)
			return rv;

		for (int i = 0; i < str.length; ++i) {
			if (('a' <= str[i] && str[i] <= 'z') || ('A' <= str[i] && str[i] <= 'Z') ||
			    ('0' <= str[i] && str[i] <= '9')) {
				rv += str[i].to_string ();
			}
		}

		rv =  (string) rv.down ().to_utf8 ();

		return rv;
	}

}
