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
using Xml;

public class Store.XMLParser : GLib.Object {
	
	public static Xml.Node* getRootNode(Soup.Message message) {
		Xml.Parser.init();
		Xml.Doc* doc = Xml.Parser.parse_memory((string)message.response_body.data, (int)message.response_body.length);
		if(doc == null)
			return null;
		//stdout.printf("%s\n", (string)message.response_body.data);
        Xml.Node* root = doc->get_root_element ();
        if (root == null) {
            delete doc;
            return null;
        }
        
        // make sure we got an 'ok' response
		for (Xml.Attr* prop = root->properties; prop != null && prop->name != "status" ; prop = prop->next) {
			if(prop->children->content != "ok")
				return null;
		}
		
		// we actually want one level down from root. top level is <response status="ok" ... >
		return root->children;
	}
	
	
	public static Store.Artist? parseArtist(Xml.Node* node) {
		int id = int.parse(node->properties->children->content);
		if(id <= 0)
			return null;
		
		Store.Artist rv = new Store.Artist(id);
		
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			if (iter->type != ElementType.ELEMENT_NODE) {
				continue;
			}
			
			string name = iter->name;
			string content = iter->get_content();
			
			if(name == "name")
				rv.name = content;
			else if(name == "sortName")
				rv.sortName = content;
			else if(name == "appearsAs")
				rv.appearsAs = content;
			else if(name == "image")
				rv.imagePath = content;
			else if(name == "url")
				rv.url = content;
			else if(name == "popularity")
				rv.popularity = double.parse(content);
		}
		
		return rv;
	}
	
	public static Store.Release? parseRelease(Xml.Node* node) {
		int id = int.parse(node->properties->children->content);
		if(id <= 0)
			return null;
		
		Store.Release rv = new Store.Release(id);
		
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			if (iter->type != ElementType.ELEMENT_NODE) {
				continue;
			}
			
			string name = iter->name;
			string content = iter->get_content();
			
			if(name == "title")
				rv.title = content;
			else if(name == "version")
				rv.version = content;
			else if(name == "type")
				rv.type = content;
			else if(name == "barcode")
				rv.barcode = int.parse(content);
			else if(name == "year")
				rv.year = int.parse(content);
			else if(name == "explicitContent")
				rv.explicitContent = (content == "true") ? true : false;
			else if(name == "artist")
				rv.artist = parseArtist(iter);
			else if(name == "image")
				rv.imagePath = content;
			else if(name == "url")
				rv.url = content;
			else if(name == "releaseDate")
				rv.releaseDate = content;
			else if(name == "addedDate")
				rv.addedDate = content;
			else if(name == "price")
				rv.price = parsePrice(iter);
			else if(name == "formats") {
				rv.availableDrmFree = (node->properties->children->content == "True") ? true : false;
				
				for(Xml.Node* format = iter->children; format != null; format = format->next) {
					rv.formats.add(parseFormat(format));
				}
			}
			else if(name == "label") {
				rv.label = parseLabel(iter);
			}
		}
		
		return rv;
	}
	
	public static Store.Label? parseLabel(Xml.Node* node) {
		int id = int.parse(node->properties->children->content);
		if(id <= 0)
			return null;
		
		Store.Label rv = new Store.Label(id);
		
		rv.name = node->children->content;
		
		return rv;
	}
	
	public static Store.Track? parseTrack(Xml.Node* node) {
		int id = int.parse(node->properties->children->content);
		if(id <= 0)
			return null;
		
		Store.Track rv = new Store.Track(id);
		
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			if (iter->type != ElementType.ELEMENT_NODE) {
				continue;
			}
			
			string name = iter->name;
			string content = iter->get_content();
			
			if(name == "title")
				rv.title = content;
			else if(name == "version")
				rv.version = content;
			else if(name == "artist")
				rv.artist = parseArtist(iter);
			else if(name == "trackNumber")
				rv.trackNumber = int.parse(content);
			else if(name == "duration")
				rv.duration = int.parse(content);
			else if(name == "explicitContent")
				rv.explicitContent = (content == "true") ? true : false;
			else if(name == "isrc")
				rv.isrc = content;
			else if(name == "release")
				rv.release = parseRelease(iter);
			else if(name == "url")
				rv.url = content;
			else if(name == "price")
				rv.price = parsePrice(iter);
		}
		
		return rv;
	}
	
	public static Store.Price? parsePrice(Xml.Node* node) {
		Store.Price rv = new Store.Price();
		
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			if (iter->type != ElementType.ELEMENT_NODE) {
				continue;
			}
			
			string name = iter->name;
			string content = iter->get_content();
			
			if(name == "currency")
				rv.currencyCode = iter->properties->children->content;
			else if(name == "value")
				rv.val = double.parse(content);
			else if(name == "formattedPrice")
				rv.formattedPrice = content;
			else if(name == "rrp")
				rv.rrp = double.parse(content);
			else if(name == "formattedRrp")
				rv.formattedRrp = content;
			else if(name == "onSale")
				rv.onSale = (content == "true") ? true : false;
		}
		
		return rv;
	}
	
	public static Store.Format? parseFormat(Xml.Node* node) {
		int id = int.parse(node->properties->children->content);
		if(id <= 0)
			return null;
		
		Store.Format rv = new Store.Format(id);
		
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			if (iter->type != ElementType.ELEMENT_NODE) {
				continue;
			}
			
			string name = iter->name;
			string content = iter->get_content();
			
			if(name == "fileFormat")
				rv.fileFormat = content;
			else if(name == "bitRate")
				rv.bitrate = int.parse(content);
			else if(name == "drmFree")
				rv.drmFree = (content == "True") ? true : false;
		}
		
		return rv;
	}
	
	public static Store.Tag? parseTag(Xml.Node* node) {
		string id = node->properties->children->content;
		
		Store.Tag rv = new Store.Tag(id);
		
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			if (iter->type != ElementType.ELEMENT_NODE) {
				continue;
			}
			
			string name = iter->name;
			string content = iter->get_content();
			
			if(name == "text")
				rv.text = content;
			else if(name == "url")
				rv.url = content;
		}
		
		return rv;
	}
}
