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

public class LastFM.ArtistInfo : Noise.ArtistInfo {

    public string url;// last fm url
    public int streamable; // 1 = true
    
    public LastFM.Image url_image = new LastFM.Image();
    
    public Gee.ArrayList<LastFM.Tag> tags = new Gee.ArrayList<LastFM.Tag>();
    public Gee.ArrayList<LastFM.ArtistInfo> similarArtists = new Gee.ArrayList<LastFM.ArtistInfo>();
    
    //public signal void artist_info_retrieved(LastFM.ArtistInfo info);
    
    // used by parser
    ArtistInfo similarToAdd;
    Tag tagToAdd;
    
    public ArtistInfo () {
        // nothing to do
    }

    public ArtistInfo.with_artist(string artist) {
        var artist_fixed = LastFM.Core.fix_for_url(artist);
        
        var url = "http://ws.audioscrobbler.com/2.0/?method=artist.getinfo&api_key=" + api + "&artist=" + artist_fixed;
        
        /*Soup.SessionSync session = new Soup.SessionSync();
        Soup.Message message = new Soup.Message ("GET", url);
        
        session.timeout = 30;// after 30 seconds, give up
        
        /* send the HTTP request *
        session.send_message(message);
        
        Xml.Doc* doc = Xml.Parser.parse_memory((string)message.response_body.data, (int)message.response_body.length);*/
        Xml.Doc* doc = Xml.Parser.parse_file(url);
        ArtistInfo.with_doc(doc);
    }
    
    public ArtistInfo.with_artist_and_url(string name, string url) {
        new ArtistInfo();
        this.name = name;
        this.url = url;
    }
    
    public ArtistInfo.with_doc(Xml.Doc* doc) {
        new ArtistInfo();
        similarToAdd = null;
        tagToAdd = null;
        
        if (doc == null) {
            return;
        }

        // Get the root node.
        Xml.Node* root = doc->get_root_element ();
        if (root == null) {
            delete doc;
            return;
        }
        
        // Let's parse those nodes
        parse_node (root, "");
        
        // We now have artist info
        //artist_info_retrieved(this);

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
            
            if(parent == "artist") {
                if(node_name == "name")
                    this.name = node_content;
                else if(node_name == "mbid")
                    this.mbid = node_content;
                else if(node_name == "url")
                    this.url = node_content;
                else if(node_name == "streamable")
                    this.streamable = int.parse(node_content);
                else if(node_name == "image") {
                    if(iter->get_prop("size") == "extralarge") {
                        url_image = new LastFM.Image.with_url(node_content, true);
                        url_image.set_size(200, 300);
                        if (url_image.image != null)
                            image_uri = this.get_image_uri_from_pixbuf(url_image.image);
                    }
                }
            }
            else if(parent == "artiststats") {
                if(node_name == "playcount")
                    this.playcount = int.parse(node_content);
                else if(node_name == "listeners")
                    this.listeners = int.parse(node_content);
            }
            else if(parent == "artistsimilarartist") {
                if(node_name == "name") {
                    if(similarToAdd != null)
                        similarArtists.add(similarToAdd);
                    
                    similarToAdd = new ArtistInfo();
                    similarToAdd.name = node_content;
                }
                else if(node_name == "url")
                    similarToAdd.url = node_content;
                else if(node_name == "image") {
                    //TODO
                }
            }
            else if(parent == "artisttagstag") {
                if(node_name == "name") {
                    if(tagToAdd != null)
                        tags.add(tagToAdd);
                    
                    tagToAdd = new LastFM.Tag();
                    tagToAdd.tag = node_content;
                }
                else if(node_name == "url")
                    tagToAdd.url = node_content;
            }
            else if(parent == "artistbio") {
                if(node_name == "published")
                    published = node_content;
                else if(node_name == "summary")
                    summary = node_content;
                else if(node_name == "content")
                    content = node_content;
            }
            
            // Now parse the node's properties (attributes) ...
            //parse_properties (iter);

            // Followed by its children nodes
            parse_node (iter, parent + node_name);
        }
    }
    
    public void addSimilarArtist(LastFM.ArtistInfo artist) {
        similarArtists.add(artist);
    }
    
    public void addTag(Tag t) {
        tags.add(t);
    }
    
    public void addTagString(string t) {
        tags.add(new LastFM.Tag.with_string(t));
    }
    
    public Gee.ArrayList<string> tagStrings() {
        var tags = new Gee.ArrayList<string>();
        
        foreach(LastFM.Tag t in this.tags) {
            tags.add(t.tag);
        }
        
        return tags;
    }
    
}
