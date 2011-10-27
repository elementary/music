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
	
	public LyricFetcher(string artist, string title) {
		this.artist = (string)artist.replace(" ","").replace(".","").replace("-", "").down().to_utf8();
		this.title = (string)title.replace(" ","").replace(".","").replace("-", "").down().to_utf8();
		
		url = urlFormat.printf(this.artist, this.title);
		stdout.printf("generated url of %s\n", url);
	}
	
	public string fetch_lyrics() {
		// Thanks to BadChoice for this regex which i obtained from covergloobus.
		//var regex = """<div id="lyric_space">(?:\s*?<.*?>)?(.*)---<br />""";
		//var regex = """<div id="lyric_space">.*</div>""";
		var page = File.new_for_uri(url);
		//Regex ex = new Regex(regex, RegexCompileFlags.DOTALL, RegexMatchFlags.ANCHORED);
		
		uint8[] uintcontent;
		string etag_out;
		
		page.load_contents(null, out uintcontent, out etag_out);
		
		string content = (string)uintcontent;
		
		//MatchInfo matches;
		
		//bool matchFound = ex.match(content, RegexMatchFlags.ANCHORED, out matches);
		
		var startString = "<!-- start of lyrics -->";
		var endString = "<!-- end of lyrics -->";
		var start = content.index_of(startString, 0) + startString.length;
		var end = content.index_of(endString, start);
		
		stdout.printf("getting content from %d->%d\n", start, end);
		
		if(start != -1 && end != -1 && end > start) {
			string lyrics = content.substring(start, end - start);
			lyrics = lyrics.replace("<br><br>", "").replace("<br>","").replace("<i>","").replace("</i>","").strip();
			return lyrics;
		}
		
		return "No lyrics found.";
		
		/*if(matchFound) {
			string lyrics = matches.fetch(0);
			return lyrics;
		}
		else {
			stdout.printf("No lyrics found\n");
			return "";
		}*/
	}
}
