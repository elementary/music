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

public class BeatBox.LyricFetcher : GLib.Object {
	private static const string urlFormat = "http://www.azlyrics.com/lyrics/%s/%s.html";
	
	private string artist;
	private string title;
	private string url;
	
	public signal void lyrics_fetched(string lyrics);
	
	public LyricFetcher() {
		
	}
	
	public void fetch_lyrics(string artist, string title) {
		this.artist = (string)artist.replace(" ","").replace(".","").replace("-", "").replace("?","").replace("(","").replace(")","").replace("'","").down().to_utf8();
		this.title = (string)title.replace(" ","").replace(".","").replace("-", "").replace("?","").replace("(","").replace(")","").replace("'","").down().to_utf8();
		
		url = urlFormat.printf(this.artist, this.title);
		
		try {
			Thread.create<void*>(fetch_lyrics_thread, false);
		}
		catch(GLib.ThreadError err) {
			stdout.printf("ERROR: Could not create last fm thread: %s \n", err.message);
		}
	}
	
	public void* fetch_lyrics_thread () {
		File page = File.new_for_uri(url);
		
		uint8[] uintcontent;
		string etag_out;
		
		try {
			page.load_contents(null, out uintcontent, out etag_out);
		}
		catch(Error err) {
			stdout.printf("Could not load contents of %s: %s\n", url, err.message);
			return "";
		}
		
		string content = (string)uintcontent;
		
		var startString = "<!-- start of lyrics -->";
		var endString = "<!-- end of lyrics -->";
		var start = content.index_of(startString, 0) + startString.length;
		var end = content.index_of(endString, start);
		
		//stdout.printf("getting content from %d->%d\n", start, end);
		
		string lyrics = "";
		if(start != -1 && end != -1 && end > start) {
			lyrics = content.substring(start, end - start);
			lyrics = lyrics.replace("<br><br>", "").replace("<br>","").replace("<i>","").replace("</i>","").strip();
		}
		
		Idle.add( () => {
			lyrics_fetched(lyrics);
			return false;
		});
		
		
		return null;
	}
}
