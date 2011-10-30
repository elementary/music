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

/* Merely a place holder for multiple pieces of information regarding
 * the current song playing. Mostly here because of dependence. */

using Xml;
using Json;

public class LastFM.TrackInfo : GLib.Object {
	static const string api = "a40ea1720028bd40c66b17d7146b3f3b";
	
	private int _id;
	private string _name;
	private string _artist;
	private string _album;
	private string _url;
	private int _duration;
	private int _streamable;
	private int _listeners;
	private int _playcount;
	
	private string _summary;
	private string _content;
	
	private Gee.ArrayList<LastFM.Tag> _tags;
	private LastFM.Tag tagToAdd;
	
	//public signal void track_info_retrieved(LastFM.TrackInfo info);
	
	public TrackInfo.basic() {
		_name = "Unknown Track";
		_tags = new Gee.ArrayList<LastFM.Tag>();
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
					_name = node_content;
				else if(node_name == "id")
					_id = int.parse(node_content);
				else if(node_name == "url")
					_url = node_content;
				else if(node_name == "duration")
					_duration = int.parse(node_content);
				else if(node_name == "streamable")
					_streamable = int.parse(node_content);
				else if(node_name == "playcount")
					_playcount = int.parse(node_content);
				else if(node_name == "listeners")
					_listeners = int.parse(node_content);
			}
			else if(parent == "trackalbum") {
				if(node_name == "title")
					_album = node_content;
			}
			else if(parent == "trackartist") {
				if(node_name == "name")
					_artist = node_content;
			}
			else if(parent == "trackwiki") {
				if(node_name == "summary")
					_summary = node_content;
				else if(node_name == "content")
					_content = node_content;
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
    
    public int id {
		get { return _id; }
		set { _id = value; }
	}
	
	public string name {
		get { return _name; }
		set { _name = value; }
	}
	
	public string artist {
		get { return _artist; }
		set { _artist = value; }
	}
	
	public string album {
		get { return _album; }
		set { _album = value; }
	}
	
	public string url {
		get { return _url; }
		set { _url = value; }
	}
	
	public int duration {
		get { return _duration; }
		set { _duration = value; }
	}
	
	public int streamable {
		get { return _streamable; }
		set { _streamable = value; }
	}
	
	public int playcount {
		get { return _playcount; }
		set { _playcount = value; }
	}
	
	public int listeners {
		get { return _listeners; }
		set { _listeners = value; }
	}
	
	public string summary {
		get { return _summary; }
		set { _summary = value; }
	}
	
	public string content {
		get { return _content; }
		set { _content = value; }
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
