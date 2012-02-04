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
using Xml;

public class Store.Artist : Store.SearchResult {
	public int artistID;
	public string name;
	public string sortName;
	public string appearsAs;
	public string imagePath;
	public string url;
	public double popularity;
	public Gdk.Pixbuf image;
	
	public signal void artist_fetched();
	
	/* Gets all the details of the artist */
	public Artist(int id) {
		artistID = id;
	}
	
	public LinkedList<Store.Release>? getReleases(string? type, int page) {
		var rv = new LinkedList<Store.Release>();
		
		string url = Store.store.api + "artist/releases" + "?artistid=" + artistID.to_string() + 
					"&oauth_consumer_key=" + Store.store.key + 
					"&country=" + Store.store.country + 
					"&page=" + page.to_string() + 
					((type != null) ? ("&type=" + type) : "") + 
					"&imagesize=100";
		
		stdout.printf("parsing %s\n", url);
		
		var session = new Soup.SessionSync();
		var message = new Soup.Message ("GET", url);
		session.send_message(message);
		
		Xml.Node* node = Store.XMLParser.getRootNode(message);
		if(node == null)
			return rv;
        
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			if (iter->type != ElementType.ELEMENT_NODE) {
				continue;
			}
			
			if(iter->name == "release") {
				Store.Release toAdd = Store.XMLParser.parseRelease(iter);
				
				if(toAdd != null) {
					stdout.printf("release result: %s %s %s\n", toAdd.title, toAdd.artist.name, toAdd.url);
					rv.add(toAdd);
				}
			}
		}
		
		return rv;
	}
	
	public LinkedList<Store.Artist>? getSimilar(int page) {
		var rv = new LinkedList<Store.Artist>();
		
		string url = Store.store.api + "artist/similar" + "?artistid=" + artistID.to_string() + 
					"&oauth_consumer_key=" + Store.store.key + 
					"&country=" + Store.store.country + 
					"&page=" + page.to_string();
		
		stdout.printf("parsing %s\n", url);
		
		var session = new Soup.SessionSync();
		var message = new Soup.Message ("GET", url);
		session.send_message(message);
		
		Xml.Node* node = Store.XMLParser.getRootNode(message);
		if(node == null)
			return rv;
        
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			if (iter->type != ElementType.ELEMENT_NODE) {
				continue;
			}
			
			if(iter->name == "artist") {
				Store.Artist toAdd = Store.XMLParser.parseArtist(iter);
				
				if(toAdd != null)
					rv.add(toAdd);
			}
		}
		
		return rv;
	}
	
	public LinkedList<Store.Track> getTopTracks(int page, int max) {
		var rv = new LinkedList<Store.Track>();
		
		string url = Store.store.api + "track/search" + "?q=" + name + 
					"&oauth_consumer_key=" + Store.store.key + 
					"&country=" + Store.store.country + 
					"&page=" + page.to_string() + 
					"&pagesize=100";
		
		stdout.printf("parsing %s\n", url);
		
		var session = new Soup.SessionSync();
		var message = new Soup.Message ("GET", url);
		session.send_message(message);
		
		Xml.Node* node = Store.XMLParser.getRootNode(message);
		if(node == null)
			return rv;
        
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
				
				if(toAdd != null && toAdd.artist.name == name) {
					stdout.printf("track result: %s %s %s\n", toAdd.title, toAdd.artist.name, toAdd.url);
					toAdd.searchType = "track";
					rv.add(toAdd);
					
					if(rv.size >= max)
						return rv;
				}
			}
		}
		
		return rv;
	}
	
	public LinkedList<Store.Tag> getTags(int page) {
		var rv = new LinkedList<Store.Tag>();
		
		string url = Store.store.api + "artist/tags" + "?artistid=" + artistID.to_string() + 
					"&oauth_consumer_key=" + Store.store.key + 
					"&country=" + Store.store.country + 
					"&page=" + page.to_string();
		
		stdout.printf("parsing %s\n", url);
		
		var session = new Soup.SessionSync();
		var message = new Soup.Message ("GET", url);
		session.send_message(message);
		
		Xml.Node* node = Store.XMLParser.getRootNode(message);
		if(node == null)
			return rv;
        
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			if (iter->type != ElementType.ELEMENT_NODE) {
				continue;
			}
			
			if(iter->name == "tag") {
				Store.Tag toAdd = Store.XMLParser.parseTag(iter);
				
				if(toAdd != null)
					rv.add(toAdd);
			}
		}
		
		return rv;
	}
	
	
}
