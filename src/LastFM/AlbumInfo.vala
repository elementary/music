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

public class LastFM.AlbumInfo : Object {
	static const string api = "a40ea1720028bd40c66b17d7146b3f3b";
	
	private string _name;
	private string _artist;
	private string _mbid;
	private string _url;
	private string _releasedate;
	
	private int _listeners;
	private int _playcount;
	
	private LastFM.Image _url_image;
	
	private Gee.ArrayList<LastFM.Tag> _tags;
	
	private LastFM.Tag tagToAdd;
	
	//public signal void album_info_retrieved(LastFM.AlbumInfo info);
	
	public AlbumInfo.basic() {
		_name = "Unknown Album";
		_artist = "Unknown Artist";
		_tags = new Gee.ArrayList<LastFM.Tag>();
		url_image = new LastFM.Image.basic();
	}
	
	public AlbumInfo.with_info(string artist, string album) {
		string album_fixed = LastFM.Core.fix_for_url(album);
		string artist_fixed = LastFM.Core.fix_for_url(artist);
		
		var url = "http://ws.audioscrobbler.com/2.0/?method=album.getinfo&api_key=" + api + "&artist=" + artist_fixed + "&album=" + album_fixed;
		
		/*Soup.SessionSync session = new Soup.SessionSync();
		Soup.Message message = new Soup.Message ("GET", url);
		
		session.timeout = 30;// after 30 seconds, give up
		
		/* send the HTTP request *
		session.send_message(message);
		
		Xml.Doc* doc = Xml.Parser.parse_memory((string)message.response_body.data, (int)message.response_body.length); */
		Xml.Doc* doc = Xml.Parser.parse_file(url);
		AlbumInfo.with_doc(doc);
	}
	
	public AlbumInfo.no_query(string artist, string album) {
		AlbumInfo.basic();
		
		_name = album;
		_artist = artist;
		
	}
	
	public AlbumInfo.with_doc( Xml.Doc* doc) {
		AlbumInfo.basic();
		
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
        
        //we now have an album info
        //album_info_retrieved(this);

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
                       
            if(parent == "album") {
				if(node_name == "name")
					_name = node_content;
				else if(node_name == "artist")
					_artist = node_content;
				else if(node_name == "mbid")
					_mbid = node_content;
				else if(node_name == "url")
					_url = node_content;
				else if(node_name == "releasedate")
					_releasedate = node_content;
				else if(node_name == "playcount")
					_playcount = int.parse(node_content);
				else if(node_name == "listeners")
					_listeners = int.parse(node_content);
				else if(node_name == "image") {
					if(iter->get_prop("size") == "large") {
						url_image = new LastFM.Image.with_url(node_content, true);
						url_image.set_size(500, 500);
					}
				}
			}
			else if(parent == "albumtoptagstag") {
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
    
    public string name {
		get { return _name; }
		set { _name = value; }
	}
	
	public string artist {
		get { return _artist; }
		set { _artist = value; }
	}
	
	public string mbid {
		get { return _mbid; }
		set { _mbid = value; }
	}
	
	public string url {
		get { return _url; }
		set { _url = value; }
	}
	
	public string releasedate {
		get { return _releasedate; }
		set { _releasedate = value; }
	}
	
	public int listeners {
		get { return _listeners; }
		set { _listeners = value; }
	}
	
	public int playcount {
		get { return _playcount; }
		set { _playcount = value; }
	}
    
    public LastFM.Image url_image {
		get { return _url_image; }
		set { _url_image = value; }
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
