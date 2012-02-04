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

public class Store.Release : Store.SearchResult {
	public int releaseID;
	public string title;
	public string version;
	public string type;
	public int barcode;
	public int year;
	public bool explicitContent;
	public Store.Artist artist;
	public string imagePath;
	public string url;
	public string releaseDate;
	public string addedDate;
	public Store.Price price;
	public bool availableDrmFree;
	public LinkedList<Store.Format> formats;
	public Store.Label label;
	public Gdk.Pixbuf image;
	
	public Release(int id) {
		releaseID = id;
		
		formats = new LinkedList<Store.Format>();
		price = new Store.Price();
	}
	
	public LinkedList<Store.Release> getSimilar(int page) {
		var rv = new LinkedList<Store.Release>();
		
		string url = Store.store.api + "release/recommend" + "?releaseid=" + releaseID.to_string() + 
					"&oauth_consumer_key=" + Store.store.key + 
					"&country=" + Store.store.country + 
					"&page=" + page.to_string() + 
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
			
			if(iter->name == "recommendedItem") {
				Store.Release toAdd = Store.XMLParser.parseRelease(iter->children);
				
				stdout.printf("recommended: %s %s %s\n", toAdd.title, toAdd.artist.name, toAdd.url);
				if(toAdd != null)
					rv.add(toAdd);
			}
		}
		
		return rv;
	}
	
	public LinkedList<Store.Track> getTracks() {
		var rv = new LinkedList<Store.Track>();
		
		string url = Store.store.api + "release/tracks" + "?releaseid=" + releaseID.to_string() + 
					"&oauth_consumer_key=" + Store.store.key + 
					"&country=" + Store.store.country +
					"&pageSize=50";
		
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
			
			if(iter->name == "track") {
				Store.Track toAdd = Store.XMLParser.parseTrack(iter);
				
				stdout.printf("added: %s %s %s %s\n", toAdd.title, toAdd.artist.name, toAdd.isrc, toAdd.duration.to_string());
				if(toAdd != null)
					rv.add(toAdd);
			}
		}
		
		return rv;
	}
	
	public LinkedList<Store.Tag> getTags(int page) {
		var rv = new LinkedList<Store.Tag>();
		
		string url = Store.store.api + "release/tags" + "?releaseid=" + releaseID.to_string() + 
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
