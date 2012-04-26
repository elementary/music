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

using Gee;

public class Store.Track : Store.SearchResult {
	public int trackID;
	public string title;
	public string version;
	public Store.Artist artist;
	public int trackNumber;
	public int duration;
	public bool explicitContent;
	public string isrc;
	public Store.Release release;
	public string url;
	public Store.Price price;
	
	public Track(int id) {
		trackID = id;
		price = new Store.Price();
	}
	
	public string prettyDuration() {
		int minute = 0;
		int seconds = duration;
		
		while(seconds >= 60) {
			++minute;
			seconds -= 60;
		}
		
		return minute.to_string() + ":" + ((seconds < 10 ) ? "0" + seconds.to_string() : seconds.to_string());
	}
	
	public string? getPreviewLink() {
		var rv = "";
		
		string url = Store.store.api + "track/preview" + "?trackid=" + trackID.to_string() + 
					"&oauth_consumer_key=" + Store.store.key + 
					"&country=" + Store.store.country + 
					"&redirect=false";
		
		stdout.printf("parsing %s\n", url);
		
		var session = new Soup.SessionSync();
		var message = new Soup.Message ("GET", url);
		session.send_message(message);
		
		Xml.Node* node = Store.XMLParser.getRootNode(message);
		if(node == null)
			return null;
		
		if(node->name == "url")
			rv = node->get_content();
		
		return rv;
	}
}
