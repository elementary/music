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

public class LastFM.SimilarSongs : Object {
	public static const int MAX_FETCHED = 20;
	
	BeatBox.LibraryManager _lm;
	BeatBox.Song _base;
	bool working;
	
	Gee.LinkedList<BeatBox.Song> similar;
	
	BeatBox.Song similarToAdd;
	
	public signal void similar_retrieved(Gee.LinkedList<int> similarIDs, Gee.LinkedList<BeatBox.Song> similarDont);
	
	public class SimilarSongs(BeatBox.LibraryManager lm) {
		_lm = lm;
		working = false;
	}
	
	public virtual void queryForSimilar(BeatBox.Song s) {
		_base = s;
		
		if(!working) {
			working = true;
			
			try {
				Thread.create<void*>(similar_thread_function, false);
			}
			catch(GLib.ThreadError err) {
				stdout.printf("ERROR: Could not create similar thread: %s \n", err.message);
			}
		}
	}
	
	public void* similar_thread_function () {	
		similar = new Gee.LinkedList<BeatBox.Song>();
		var similarIDs = new Gee.LinkedList<int>();
		var similarDont = new Gee.LinkedList<BeatBox.Song>();
		
		getSimilarTracks(_base.title, _base.artist);
		foreach(BeatBox.Song sim in similar) {
			BeatBox.Song s = _lm.song_from_name(sim.title, sim.artist);
			if(s.rowid != 0) {
				similarIDs.add(s.rowid);
			}
			else {
				similarDont.add(sim);
			}
		}
		
		similarIDs.offer_head(_base.rowid);
		
		Idle.add( () => {
			similar_retrieved(similarIDs, similarDont);
			return false;
		});
		
		working = false;
		
		return null;	
    }
	
	/** Gets similar songs
	 * @param artist The artist of song to get similar to
	 * @param title The title of song to get similar to
	 * @return The songs that are similar
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
			stdout.printf("Could not load similar artist information for %s by %s\n", title, artist);
		else if(doc->get_root_element() == null)
			stdout.printf("Oddly, similar artist information was invalid\n");
		else {
			//stdout.printf("Getting similar tracks with %s... \n", url);
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
					
					similarToAdd = new BeatBox.Song("");
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
