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

/* Merely a place holder for multiple pieces of information regarding
 * the current media playing. Mostly here because of dependence. */

using Xml;
using Json;

public class LastFM.TrackInfo : Noise.TrackInfo {
	
	public string url { get; set; default = ""; }
	public int streamable { get; set; default = 0; }
	
	private Gee.ArrayList<LastFM.Tag> _tags = new Gee.ArrayList<LastFM.Tag>();
	private LastFM.Tag tagToAdd;
	
	//public signal void track_info_retrieved(LastFM.TrackInfo info);
	
	public TrackInfo.basic() {
	}
	
	public TrackInfo.with_info(string artist, string track) {
		string track_fixed = LastFM.Core.fix_for_url(track);
		string artist_fixed = LastFM.Core.fix_for_url(artist);
		
		string url = "http://ws.audioscrobbler.com/2.0/?method=track.getinfo&api_key=" + api + "&artist=" + artist_fixed + "&track=" + track_fixed;
		
		/*Soup.SessionSync session = new Soup.SessionSync();
		Soup.Message message = new Soup.Message ("GET", url);
		
		session.timeout = 30;// after 30 seconds, give up
		
		/* send the HTTP request *
		session.send_message(message);
		
		Xml.Doc* doc = Xml.Parser.parse_memory((string)message.response_body.data, (int)message.response_body.length);*/
		Xml.Doc* doc = Xml.Parser.parse_file(url);
		TrackInfo.with_doc(doc);
	}
	
	
	public TrackInfo.with_doc(Xml.Doc* doc) {
		TrackInfo.basic();
		
		tagToAdd = null;
        if (doc == null) {
            return;
        }

        // Get the root node. notice the dereferencing operator -> instead of .
        Xml.Node* root = doc->get_root_element ();
        if (root == null) {
            // Free the document manually before returning
            delete doc;
            return;
        }
        
        // Let's parse those nodes
        parse_node (root, "");

        // Free the document
        delete doc;
	}
	
	/** recursively parses the nodes in a xml doc and also calls parse_properties
	 * @param node The node to parse
	 * @param parent the parent node
	 */
	private void parse_node (Xml.Node* node, string parent) {
        // Loop over the passed node's children
        for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
            // Spaces between tags are also nodes, discard them
            if (iter->type != ElementType.ELEMENT_NODE) {
                continue;
            }

            string node_name = iter->name;
            string node_content = iter->get_content ();
                       
            if(parent == "track") {
				if(node_name == "name")
					this.name = node_content;
				else if(node_name == "id")
					this.id = int.parse(node_content);
				else if(node_name == "url")
					url = node_content;
				else if(node_name == "duration")
					this.duration = int.parse(node_content);
				else if(node_name == "streamable")
					streamable = int.parse(node_content);
				else if(node_name == "playcount")
					this.playcount = int.parse(node_content);
				else if(node_name == "listeners")
					this.listeners = int.parse(node_content);
			}
			else if(parent == "trackalbum") {
				if(node_name == "title")
					this.album = node_content;
			}
			else if(parent == "trackartist") {
				if(node_name == "name")
					this.artist = node_content;
			}
			else if(parent == "trackwiki") {
				if(node_name == "summary")
					this.summary = node_content;
				else if(node_name == "content")
					this.content = node_content;
			}
			else if(parent == "tracktoptagstag") {
				if(node_name == "name") {
					if(tagToAdd != null)
						_tags.add(tagToAdd);
					
					tagToAdd = new LastFM.Tag();
					tagToAdd.tag = node_content;
				}
				else if(node_name == "url")
					tagToAdd.url = node_content;
			}

            // Followed by its children nodes
            parse_node (iter, parent + node_name);
        }
    }
	
	public void addTag(Tag t) {
		_tags.add(t);
	}
	
	public void addTagString(string t) {
		_tags.add(new LastFM.Tag.with_string(t));
	}
	
	public Gee.ArrayList<LastFM.Tag> tags() {
		return _tags;
	}
	
	public Gee.ArrayList<string> tagStrings() {
		var tags = new Gee.ArrayList<string>();
		
		foreach(LastFM.Tag t in _tags) {
			tags.add(t.tag);
		}
		
		return tags;
	}
    
}
