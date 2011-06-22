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

using Gee;
using Rest;
using Xml;

public class Store.store : GLib.Object {
	public static string api = "http://api.7digital.com/1.2/";
	public static string country = "US";
	public static string key = "7dtjyu9qbu";
	
	public store() {
		
	}
	
	public static Store.Release? getRelease(int id, int imagesize) {
		string url = api + "release/details" + "?releaseid=" + id.to_string() + "&oauth_consumer_key=" + key + "&country=" + country + "&imagesize=" + imagesize.to_string();
		
		stdout.printf("release: %s\n", url);
		
		// create an HTTP session to twitter
		var session = new Soup.SessionSync();
		var message = new Soup.Message ("GET", url);
		
		// send the HTTP request
		session.send_message(message);
		
		Xml.Node* node = Store.XMLParser.getRootNode(message);
		if(node == null)
			return null;
		
		return Store.XMLParser.parseRelease(node);
	}
	
	public static Store.Artist? getArtist(int id) {
		string url = api + "artist/details" + "?artistid=" + id.to_string() + "&oauth_consumer_key=" + key + "&country=" + country;
		
		stdout.printf("artist: %s\n", url);
		
		// create an HTTP session to twitter
		var session = new Soup.SessionSync();
		var message = new Soup.Message ("GET", url);
		
		// send the HTTP request
		session.send_message(message);
		
		Xml.Node* node = Store.XMLParser.getRootNode(message);
		if(node == null)
			return null;
		
		return Store.XMLParser.parseArtist(node);
	}
	
	/** Search methods
	 * simply return objects matching the search string
	 * @search the string to search
	 * @sort Either name, popularity, or score.
	*/
	public LinkedList<Store.Artist> searchArtists(string search, string? sort, int page) {
		var rv = new LinkedList<Store.Artist>();
		
		string url = Store.store.api + "artist/search" + "?q=" + search + 
					((sort != null) ? ("&sort=" + sort) : "") +
					"&oauth_consumer_key=" + Store.store.key + 
					"&country=" + Store.store.country + 
					"&page=" + page.to_string();
		
		stdout.printf("parsing %s\n", url);
		
		var session = new Soup.SessionSync();
		var message = new Soup.Message ("GET", url);
		session.send_message(message);
		
		Xml.Node* node = Store.XMLParser.getRootNode(message);
		if(node == null)
			return null;
        
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			if (iter->type != ElementType.ELEMENT_NODE) {
				continue;
			}
			
			if(iter->name == "searchResult") {
				Store.Artist toAdd = new Store.Artist(0);
				double score = 0.0;
				
				for(Xml.Node* subIter = iter->children; subIter != null; subIter = subIter->next) {
					if(subIter->name == "score")
						score = double.parse(subIter->get_content());
					else if(subIter->name == "artist")
						toAdd = Store.XMLParser.parseArtist(subIter);
				}
				
				if(toAdd != null) {
					stdout.printf("serachArtists: %s %s %s\n", score.to_string(), toAdd.name, toAdd.url);
					toAdd.searchScore = score;
					toAdd.searchType = "artist";
					rv.add(toAdd);
				}
			}
		}
		
		return rv;
	}
	
	public LinkedList<Store.Release> searchReleases(string search, int page) {
		var rv = new LinkedList<Store.Release>();
		
		string url = Store.store.api + "release/search" + "?q=" + search + 
					"&oauth_consumer_key=" + Store.store.key + 
					"&country=" + Store.store.country + 
					"&page=" + page.to_string();
		
		stdout.printf("parsing %s\n", url);
		
		var session = new Soup.SessionSync();
		var message = new Soup.Message ("GET", url);
		session.send_message(message);
		
		Xml.Node* node = Store.XMLParser.getRootNode(message);
		if(node == null)
			return null;
        
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			if (iter->type != ElementType.ELEMENT_NODE) {
				continue;
			}
			
			if(iter->name == "searchResult") {
				Store.Release toAdd = new Store.Release(0);
				
				for(Xml.Node* subIter = iter->children; subIter != null; subIter = subIter->next) {
					if(subIter->name == "release")
						toAdd = Store.XMLParser.parseRelease(subIter);
				}
				
				if(toAdd != null) {
					stdout.printf("release result: %s %s %s\n", toAdd.title, toAdd.artist.name, toAdd.url);
					toAdd.searchType = "release";
					rv.add(toAdd);
				}
			}
		}
		
		return rv;
	}
	
	public LinkedList<Store.Track> searchTracks(string search, int page) {
		var rv = new LinkedList<Store.Track>();
		
		string url = Store.store.api + "track/search" + "?q=" + search + 
					"&oauth_consumer_key=" + Store.store.key + 
					"&country=" + Store.store.country + 
					"&page=" + page.to_string();
		
		stdout.printf("parsing %s\n", url);
		
		var session = new Soup.SessionSync();
		var message = new Soup.Message ("GET", url);
		session.send_message(message);
		
		Xml.Node* node = Store.XMLParser.getRootNode(message);
		if(node == null)
			return null;
        
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			if (iter->type != ElementType.ELEMENT_NODE) {
				continue;
			}
			
			if(iter->name == "searchResult") {
				Store.Track toAdd = new Store.Track(0);
				
				for(Xml.Node* subIter = iter->children; subIter != null; subIter = subIter->next) {
					if(subIter->name == "track")
						toAdd = Store.XMLParser.parseTrack(subIter);
				}
				
				if(toAdd != null) {
					stdout.printf("track result: %s %s %s\n", toAdd.title, toAdd.artist.name, toAdd.url);
					toAdd.searchType = "track";
					rv.add(toAdd);
				}
			}
		}
		
		return rv;
	}
	
	
	/** Chart methods
	 * Return current top x objects
	 * @period Either week, month, or year
	 * @toDate The last day to include, in YYYYDDMM format
	 * @tag an optional tag (rock, pop). If null, ignored
	 * 
	*/
	public LinkedList<Store.Artist> topArtists(string period, string? toDate, string? tags, int page) {
		var rv = new LinkedList<Store.Artist>();
		
		if(tags == null) {
			string url = Store.store.api + "artist/chart" + "?period=" + period + 
						((toDate != null) ? ("&todate=" + toDate) : "") +
						"&oauth_consumer_key=" + Store.store.key + 
						"&country=" + Store.store.country + 
						"&page=" + page.to_string() + "&pagesize=30";
			
			stdout.printf("parsing %s\n", url);
			
			var session = new Soup.SessionSync();
			var message = new Soup.Message ("GET", url);
			session.send_message(message);
			stdout.printf("sent\n");
			Xml.Node* node = Store.XMLParser.getRootNode(message);
			if(node == null)
				return null;
			
			for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
				if (iter->type != ElementType.ELEMENT_NODE) {
					continue;
				}
				
				if(iter->name == "chartItem") {
					Store.Artist toAdd = new Store.Artist(0);
					int position = 0;
					string change = "";
					
					for(Xml.Node* subIter = iter->children; subIter != null; subIter = subIter->next) {
						if(subIter->name == "position")
							position = int.parse(subIter->get_content());
						else if(subIter->name == "change")
							change = subIter->get_content();
						else if(subIter->name == "artist")
							toAdd = Store.XMLParser.parseArtist(subIter);
					}
					
					if(toAdd != null) {
						stdout.printf("artist result: %s %s\n", toAdd.name, toAdd.url);
						toAdd.searchPosition = position;
						toAdd.searchUpDown = change;
						rv.add(toAdd);
					}
				}
			}
		}
		else {
			string url = Store.store.api + "artist/bytag/top" + "?tags=" + tags + 
						"&oauth_consumer_key=" + Store.store.key + 
						"&country=" + Store.store.country + 
						"&page=" + page.to_string() + "&pagesize=30";
			
			stdout.printf("parsing %s\n", url);
			
			var session = new Soup.SessionSync();
			var message = new Soup.Message ("GET", url);
			session.send_message(message);
			
			Xml.Node* node = Store.XMLParser.getRootNode(message);
			if(node == null)
				return null;
			
			for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
				if (iter->type != ElementType.ELEMENT_NODE) {
					continue;
				}
				
				if(iter->name == "taggedItem") {
					Store.Artist toAdd = new Store.Artist(0);
					
					for(Xml.Node* subIter = iter->children; subIter != null; subIter = subIter->next) {
						if(subIter->name == "artist")
							toAdd = Store.XMLParser.parseArtist(subIter);
					}
					
					if(toAdd != null) {
						stdout.printf("artist result: %s %s\n", toAdd.name, toAdd.url);
						rv.add(toAdd);
					}
				}
			}
		}
		
		return rv;
	}
	
	public LinkedList<Store.Release> topReleases(string period, string? toDate, string? tags, int page) {
		var rv = new LinkedList<Store.Release>();
		
		if(tags == null) {
			string url = Store.store.api + "release/chart" + "?period=" + period + 
						((toDate != null) ? ("&todate=" + toDate) : "") +
						"&oauth_consumer_key=" + Store.store.key + 
						"&country=" + Store.store.country + 
						"&page=" + page.to_string() + "&pagesize=30" +
						"&imagesize=200" + "&type=album" + "&sort=popularity";
			
			stdout.printf("parsing %s\n", url);
			
			var session = new Soup.SessionSync();
			var message = new Soup.Message ("GET", url);
			session.send_message(message);
			
			Xml.Node* node = Store.XMLParser.getRootNode(message);
			if(node == null)
				return null;
			
			for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
				if (iter->type != ElementType.ELEMENT_NODE) {
					continue;
				}
				
				if(iter->name == "chartItem") {
					Store.Release toAdd = new Store.Release(0);
					int position = 0;
					string change = "";
				
					for(Xml.Node* subIter = iter->children; subIter != null; subIter = subIter->next) {
						if(subIter->name == "position")
							position = int.parse(subIter->get_content());
						else if(subIter->name == "change")
							change = subIter->get_content();
						else if(subIter->name == "release")
							toAdd = Store.XMLParser.parseRelease(subIter);
					}
					
					if(toAdd != null) {
						stdout.printf("release result: %s %s %s\n", toAdd.title, toAdd.artist.name, toAdd.searchPosition.to_string());
						toAdd.searchType = "release";
						toAdd.searchPosition = position;
						toAdd.searchUpDown = change;
						rv.add(toAdd);
					}
				}
			}
		}
		else {
			string url = Store.store.api + "release/bytag/top" + "?period=" + period +
						"&tags=" + tags + 
						"&oauth_consumer_key=" + Store.store.key + 
						"&country=" + Store.store.country + 
						"&page=" + page.to_string() + "&pagesize=30";
			
			stdout.printf("parsing %s\n", url);
			
			var session = new Soup.SessionSync();
			var message = new Soup.Message ("GET", url);
			session.send_message(message);
			
			Xml.Node* node = Store.XMLParser.getRootNode(message);
			if(node == null)
				return null;
			
			for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
				if (iter->type != ElementType.ELEMENT_NODE) {
					continue;
				}
				
				if(iter->name == "taggedItem") {
					Store.Release toAdd = new Store.Release(0);
				
					for(Xml.Node* subIter = iter->children; subIter != null; subIter = subIter->next) {
						if(subIter->name == "release")
							toAdd = Store.XMLParser.parseRelease(subIter);
					}
					
					if(toAdd != null) {
						stdout.printf("release result: %s %s %s\n", toAdd.title, toAdd.artist.name, toAdd.url);
						toAdd.searchType = "release";
						rv.add(toAdd);
					}
				}
			}
		}
		
		return rv;
	}
	
	public LinkedList<Store.Track> topTracks(string period, string? toDate, int page) {
		var rv = new LinkedList<Store.Track>();
		
		string url = Store.store.api + "track/chart" + "?period=" + period + 
					((toDate != null) ? ("&todate=" + toDate) : "") +
					"&oauth_consumer_key=" + Store.store.key + 
					"&country=" + Store.store.country + 
					"&page=" + page.to_string() + "&pagesize=30";
		
		stdout.printf("parsing %s\n", url);
		
		var session = new Soup.SessionSync();
		var message = new Soup.Message ("GET", url);
		session.send_message(message);
		
		Xml.Node* node = Store.XMLParser.getRootNode(message);
		if(node == null)
			return null;
		
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			if (iter->type != ElementType.ELEMENT_NODE) {
				continue;
			}
			
			if(iter->name == "chartItem") {
				Store.Track toAdd = new Store.Track(0);
				int position = 0;
				string change = "";
				
				for(Xml.Node* subIter = iter->children; subIter != null; subIter = subIter->next) {
					if(subIter->name == "position")
						position = int.parse(subIter->get_content());
					else if(subIter->name == "change")
						change = subIter->get_content();
					else if(subIter->name == "track")
						toAdd = Store.XMLParser.parseTrack(subIter);
				}
				
				if(toAdd != null) {
					stdout.printf("track result: %s %s %s\n", toAdd.title, toAdd.artist.name, toAdd.url);
					toAdd.searchUpDown = change;
					toAdd.searchPosition = position;
					rv.add(toAdd);
				}
			}
		}
		
		return rv;
	}
	
	/** Get releases of certain timeframe
	 * @fromDate the first day in YYYYMMDD format. Defaults today
	 * @toDate the last day in YYYYMMDD format. Defaults today
	*/
	public LinkedList<Store.Release> getReleasesInRange(string? fromDate, string? toDate, int page) {
		var rv = new LinkedList<Store.Release>();
		
		string url = Store.store.api + "release/bydate" + 
					"?oauth_consumer_key=" + Store.store.key + 
					"&country=" + Store.store.country + 
					"&page=" + page.to_string() + 
					((fromDate != null) ? ("&fromDate=" + fromDate) : "") +
					((toDate != null) ? ("&toDate=" + toDate) : "");
		
		stdout.printf("parsing %s\n", url);
		
		var session = new Soup.SessionSync();
		var message = new Soup.Message ("GET", url);
		session.send_message(message);
		
		Xml.Node* node = Store.XMLParser.getRootNode(message);
		if(node == null)
			return null;
		
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			if (iter->type != ElementType.ELEMENT_NODE) {
				continue;
			}
			
			if(iter->name == "release") {
				Store.Release toAdd = Store.XMLParser.parseRelease(iter);
				
				stdout.printf("release result: %s %s\n", toAdd.title, toAdd.artist.name);
				if(toAdd != null)
					rv.add(toAdd);
			}
		}
		
		return rv;
	}
	
	/** Returns releases matching all tag(s), starting with most recent
	 * @tags One or more tags to match
	 * 
	*/
	public LinkedList<Store.Release> newReleasesByTag(string tags, int page) {
		var rv = new LinkedList<Store.Release>();
		
		string url = Store.store.api + "release/bytag/new" + "?tags=" + tags +
					"&oauth_consumer_key=" + Store.store.key + 
					"&country=" + Store.store.country + 
					"&page=" + page.to_string();
		
		stdout.printf("parsing %s\n", url);
		
		var session = new Soup.SessionSync();
		var message = new Soup.Message ("GET", url);
		session.send_message(message);
		
		Xml.Node* node = Store.XMLParser.getRootNode(message);
		if(node == null)
			return null;
		
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			if (iter->type != ElementType.ELEMENT_NODE) {
				continue;
			}
			
			if(iter->name == "taggedItem") {
				Store.Release toAdd = new Store.Release(0);
				
				for(Xml.Node* subIter = iter->children; subIter != null; subIter = subIter->next) {
					if(subIter->name == "release")
						toAdd = Store.XMLParser.parseRelease(subIter);
				}
				
				if(toAdd != null) {
					stdout.printf("release result: %s %s %s\n", toAdd.title, toAdd.artist.name, toAdd.url);
					toAdd.searchType = "release";
					rv.add(toAdd);
				}
			}
		}
		
		return rv;
	}
	
	/** Helper to parse uri images into pixbufs from store **/
	public static Gdk.Pixbuf? getPixbuf(string url, int width, int height) {
		Gdk.Pixbuf rv;
		
		if(url == null || url == "") {
			return null;
		}
		
		File file = File.new_for_uri(url);
		FileInputStream filestream;
		
		try {
			filestream = file.read(null);
			rv = new Gdk.Pixbuf.from_stream_at_scale(filestream, width, height, true, null);
		}
		catch(GLib.Error err) {
			stdout.printf("Could not fetch album art from %s: %s\n", url, err.message);
			rv = null;
		}
		
		return rv;
	}
}
