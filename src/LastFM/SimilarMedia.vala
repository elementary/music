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

public class LastFM.SimilarMedias : Object {
	public static const int MAX_FETCHED = 20;
	
	BeatBox.LibraryManager _lm;
	BeatBox.Media _base;
	bool working;
	
	Gee.LinkedList<BeatBox.Media> similar;
	
	BeatBox.Media similarToAdd;
	
	public signal void similar_retrieved(Gee.LinkedList<int> similarIDs, Gee.LinkedList<BeatBox.Media> similarDont);
	
	public class SimilarMedias(BeatBox.LibraryManager lm) {
		_lm = lm;
		working = false;
	}
	
	public virtual void queryForSimilar(BeatBox.Media s) {
		_base = s;
		
		if(!working) {
			working = true;
			
			try {
				new Thread<void*>.try (null, similar_thread_function);
			}
			catch (GLib.Error err) {
				warning("ERROR: Could not create similar thread: %s \n", err.message);
			}
		}
	}
	
	public void* similar_thread_function () {	
		similar = new Gee.LinkedList<BeatBox.Media>();
		var similarIDs = new Gee.LinkedList<int>();
		var similarDont = new Gee.LinkedList<BeatBox.Media>();
		
		getSimilarTracks(_base.title, _base.artist);
		_lm.medias_from_name(similar, ref similarIDs, ref similarDont);
		similarIDs.offer_head(_base.rowid);
		
		Idle.add( () => {
			similar_retrieved(similarIDs, similarDont);
			return false;
		});
		
		working = false;
		
		return null;	
    }
	
	/** Gets similar medias
	 * @param artist The artist of media to get similar to
	 * @param title The title of media to get similar to
	 * @return The media that are similar
	 */
	public void getSimilarTracks(string title, string artist) {
		var artist_fixed = LastFM.Core.fix_for_url(artist);
		var title_fixed =  LastFM.Core.fix_for_url(title);
		var url = "http://ws.audioscrobbler.com/2.0/?method=track.getsimilar&artist=" + artist_fixed + "&track=" + title_fixed + "&api_key=" + LastFM.Core.api;
		
		Soup.SessionSync session = new Soup.SessionSync();
		Soup.Message message = new Soup.Message ("GET", url);
		
		session.timeout = 30;// after 30 seconds, give up
		
		/* send the HTTP request */
		session.send_message(message);
		
		Xml.Doc* doc = Xml.Parser.parse_memory((string)message.response_body.data, (int)message.response_body.length);
		
		if(doc == null)
			GLib.message("Could not load similar artist information for %s by %s\n", title, artist);
		else if(doc->get_root_element() == null)
			GLib.message("Oddly, similar artist information was invalid\n");
		else {
			//message("Getting similar tracks with %s... \n", url);
			similarToAdd = null;
			
			parse_similar_nodes(doc->get_root_element(), "");
		}
		
		delete doc;
	}
	
	public void parse_similar_nodes(Xml.Node* node, string parent) {
		Xml.Node* iter;
		for (iter = node->children; iter != null; iter = iter->next) {
			
            if (iter->type != ElementType.ELEMENT_NODE) {
                continue;
            }

            string node_name = iter->name;
            string node_content = iter->get_content ();
            
            if(parent == "similartrackstrack") {
				if(node_name == "name") {
					if(similarToAdd != null) {
						similar.add(similarToAdd);
					}
					
					similarToAdd = new BeatBox.Media("");
					similarToAdd.title = node_content;
				}
				else if(node_name == "url") {
					similarToAdd.lastfm_url = node_content;
				}
			}
			else if(parent == "similartrackstrackartist") {
				if(node_name == "name") {
					similarToAdd.artist = node_content;
				}
			}
			
			parse_similar_nodes(iter, parent+node_name);
		}
		
		delete iter;
	}
}
