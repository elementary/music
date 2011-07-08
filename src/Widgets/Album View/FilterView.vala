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

using Gtk;
using Gee;
using WebKit;

public class BeatBox.FilterView : VBox {
	LibraryManager lm;
	LibraryWindow lw;
	Collection<int> songs;
	
	ScrolledWindow scroll;
	WebView view;
	Table table;
	
	private Collection<int> showingSongs;
	private string last_search;
	LinkedList<string> timeout_search;
	
	//string defaultPath;
	
	public bool isCurrentView;
	public bool needsUpdate;
	
	public signal void itemClicked(string artist, string album);
	
	/* songs should be mutable, as we will be sorting it */
	public FilterView(LibraryManager lmm, LibraryWindow lww, Collection<int> ssongs) {
		lm = lmm;
		lw = lww;
		songs = ssongs;
		
		showingSongs = new LinkedList<int>();
		last_search = "";
		timeout_search = new LinkedList<string>();
		
		//defaultPath = GLib.Path.build_filename("/usr", "share", "icons", "hicolor", "128x128", "mimetypes", "media-audio.png", null);
		
		buildUI();
	}
	
	public void set_songs(LinkedList<int> new_songs) {
		songs = new_songs;
	}
	
	public void buildUI() {
		scroll = new ScrolledWindow(null, null);
		view = new WebView();
		
		scroll.add(view);
		
        //set_policy(PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
		
		view.settings.enable_default_context_menu = false;
		view.settings.auto_resize_window = true;
		
		//v.set_shadow_type(ShadowType.NONE);
		//v.add(view);
		pack_start(scroll, true, true, 0);
		
		show_all();
		
		view.navigation_requested.connect(navigationRequested);
		lw.searchField.changed.connect(searchFieldChanged);
		
	}
	
	/** Goes through the hashmap and generates html. If artist,album, or genre
	 * is set, makes sure that only items that fit those filters are
	 * shown
	*/
	public void generateHTML(LinkedList<int> toShow, bool force) {
		
		/** NOTE: This could have a bad effect if user coincidentally
		 * searches for something that has same number of results as 
		 * a different search. However, this cuts lots of unecessary
		 * loading of lists/icon lists */
		if(showingSongs.size == toShow.size && !force)
			return;
		
		string html = """<!DOCTYPE html> <html lang="en"><head> 
        <style media="screen" type="text/css"> 
            body { 
                background: #363636;
                font-family: "Droid Sans",sans-serif; 
                margin-top: 10px;
                color: #ffffff;
            }
            #main {
				margin: 0px auto;
				width: 100%;
			}
            #main ul {
                padding-bottom: 10px;
                margin-left: -20px;
            }
            #main ul li {
                float: left;
                width: 128px;
                height: 175px;
                display: inline-block;
                list-style-type: none;
                padding-right: 10px;
                padding-left: 10px;
                padding-bottom: 12px;
                overflow: hidden;
            }
            #main ul li img {
                width: 128px;
                height: 128px;
                -webkit-box-shadow:0 2px 10px rgba(0,0,0,.69);
            }
            #main ul li p {
                clear: both;
                overflow: hidden;
                text-align: center;
                margin-top: 0px;
                font-size: 12px;
                margin-bottom: 0px;
                color: #ffffff;
            }
        </style></head><body><div id="main"><ul>""";
        
        // first sort the songs so we know they are grouped by artists, then albums
		toShow.sort((CompareFunc)songCompareFunc);
		
		string previousAlbum = "";
		foreach(int i in toShow) {
			Song s = lm.song_from_id(i);
			
			if(s.album != previousAlbum) {
				html += "<li><a href=\"" + s.album.replace("\"", "'") + "<seperater>" + s.artist.replace("\"", "'") + "\"><img width=\"128\" height=\"128\" src=\"file://" + s.getAlbumArtPath() + "\" /></a><p>" + ( (s.album == "") ? "Unknown" : s.album.replace("\"", "'")) + "</p><p>" + s.artist.replace("\"", "'") + "</p></li>";
				previousAlbum = s.album;
			}
		}
			
		html += "</ul></div></body></html>"; // finish up the last song, finish up html
		
		view.load_html_string(html, "file://");
		needsUpdate = false;
		
		showingSongs = toShow;
	}
	
	public static int songCompareFunc(Song a, Song b) {
		return (a.album > b.album) ? 1 : -1;
	}
	
	public virtual NavigationResponse navigationRequested(WebFrame frame, NetworkRequest request) {
		if(request.uri.contains("<seperater>")) {
			// switch the view
			string[] splitUp = request.uri.split("<seperater>", 0);
			
			itemClicked(splitUp[0], splitUp[1]);
			
			return WebKit.NavigationResponse.IGNORE;
		}
		
		return WebKit.NavigationResponse.ACCEPT;
	}
	
	public virtual void searchFieldChanged() {
		if(isCurrentView && lw.searchField.get_text().length != 1) {
			timeout_search.offer_head(lw.searchField.get_text().down());
			Timeout.add(100, () => {
				string to_search = timeout_search.poll_tail();
				stdout.printf("searching for %s\n", to_search);
				
				if(timeout_search.size == 0) {
					var toSearch = new LinkedList<int>();
					foreach(int id in lm.songs_from_search(to_search, "All Genres", 
														"All Artists",
														"All Albums",
														songs)) {
						
						toSearch.add(id);
					}
					
					if(showingSongs.size != toSearch.size) {
						generateHTML(toSearch, false);
					}
				}
				
				return false;
			});
		}
	}
}
