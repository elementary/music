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

public class LastFM.AlbumInfo : GLib.Object {
    public string image_uri  { get; set; default=""; }

    private string url { get; set; default=""; }
    private Gee.TreeSet<LastFM.Tag> _tags = new Gee.TreeSet<LastFM.Tag>();
    private LastFM.Tag tagToAdd;
    private Noise.Media media;

    public AlbumInfo (Noise.Media m) {
        media = m;
        string album_fixed = GLib.Uri.escape_string (m.album);
        string artist_fixed = GLib.Uri.escape_string (m.artist);
        if (artist_fixed == "")
            artist_fixed = GLib.Uri.escape_string (m.artist);
        var url = "http://ws.audioscrobbler.com/2.0/?method=album.getinfo&api_key=" + API + "&artist=" + artist_fixed + "&album=" + album_fixed;
        Xml.Doc* doc = Xml.Parser.parse_file(url);
        
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
            if (iter->type != Xml.ElementType.ELEMENT_NODE) {
                continue;
            }

            string node_name = iter->name;
            string node_content = iter->get_content ();
            if (parent == "album") {
                if (node_name == "name" && media.album == "")
                    media.album = node_content;
                else if (node_name == "artist" && media.artist == "")
                    media.artist = node_content;
                else if (node_name == "releasedate" && media.year == 0) {
                    var date = GLib.Date ();
                    date.set_parse (node_content);
                    var year = date.get_year ();
                    if (year != GLib.DateYear.BAD_YEAR)
                        media.year = (int)year;
                } else if (node_name == "playcount" && media.play_count == 0)
                    media.play_count = int.parse (node_content);
                else if (node_name == "image") {
                    if (iter->get_prop ("size") == "large")
                        image_uri = node_content;
                }
            } else if (parent == "albumtoptagstag") {
                if (node_name == "name") {
                    if (tagToAdd != null)
                        _tags.add (tagToAdd);
                    
                    tagToAdd = new LastFM.Tag ();
                    tagToAdd.tag = node_content;
                } else if (node_name == "url")
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

    public Gee.Collection<LastFM.Tag> tags() {
        return _tags;
    }

    public Gee.Collection<string> tagStrings() {
        var tags = new Gee.TreeSet<string>();
        foreach(LastFM.Tag t in _tags) {
            tags.add(t.tag);
        }

        return tags;
    }
}
