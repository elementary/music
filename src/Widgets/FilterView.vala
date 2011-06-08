using Gtk;
using Gee;
using WebKit;

public class ArtistItem : Widget {
	Label artistLabel;
}

public class BeatBox.FilterView : ScrolledWindow {
	LibraryManager lm;
	LibraryWindow lw;
	LinkedList<int> songs;
	
	WebView view;
	Table table;
	
	private Collection<int> showingSongs;
	private string last_search;
	LinkedList<string> timeout_search;
	
	string defaultPath;
	
	public bool isCurrentView;
	public bool needsUpdate;
	
	public signal void itemClicked(string artist, string album);
	
	/* songs should be mutable, as we will be sorting it */
	public FilterView(LibraryManager lmm, LibraryWindow lww, LinkedList<int> ssongs) {
		lm = lmm;
		lw = lww;
		songs = ssongs;
		
		showingSongs = new LinkedList<int>();
		last_search = "";
		timeout_search = new LinkedList<string>();
		
		defaultPath = GLib.Path.build_filename("/usr", "share", "icons", "hicolor", "128x128", "mimetypes", "media-audio.svg", null);
		stdout.printf("default path is %s\n", defaultPath);
		
		buildUI();
	}
	
	public void buildUI() {
		view = new WebView();
		Viewport v = new Viewport(null, null);
		
        set_policy(PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
		
		view.settings.enable_default_context_menu = false;
		
		v.set_shadow_type(ShadowType.NONE);
		v.add(view);
		add(v);
		
		show_all();
		
		view.navigation_requested.connect(navigationRequested);
		lw.searchField.changed.connect(searchFieldChanged);
	}
	
	public static Gtk.Alignment wrap_alignment (Gtk.Widget widget, int top, int right, int bottom, int left) {
		var alignment = new Gtk.Alignment(0.0f, 0.0f, 1.0f, 1.0f);
		alignment.top_padding = top;
		alignment.right_padding = right;
		alignment.bottom_padding = bottom;
		alignment.left_padding = left;
		
		alignment.add(widget);
		return alignment;
	}
	
	/** Goes through the hashmap and generates html. If artist,album, or genre
	 * is set, makes sure that only items that fit those filters are
	 * shown
	*/
	public void generateHTML(LinkedList<Song> toShow) {
		
		/** NOTE: This could have a bad effect if user coincidentally
		 * searches for something that has same number of results as 
		 * a different search. However, this cuts lots of unecessary
		 * loading of lists/icon lists */
		if(showingSongs.size == toShow.size)
			return;
		
		string html = """<!DOCTYPE html> <html lang="en"><head> 
        <style media="screen" type="text/css"> 
            body { 
                background: #fff; 
                font-family: "Droid Sans",sans-serif; 
                margin-top: 10px;
            }
            #main {
				width: 100%;
				margin: 0px auto;
			}
            #main ul {
                padding-bottom: 10px;
                margin: auto;
            }
            #main ul li {
                float: left;
                width: 150px;
                height: 200px;
                display: inline-block;
                list-style-type: none;
                padding-right: 10px;
                padding-left: 10px;
                padding-bottom: 5px;
                overflow: hidden;
            }
            #main ul li img {
                width: 150px;
                height: 150px;
            }
            #main ul li p {
                clear: both;
                overflow: hidden;
                text-align: center;
                margin-top: 0px;
                font-size: 12px;
                margin-bottom: 0px;
            }
        </style></head><body><div id="main"><ul>""";
        
        stdout.printf("sorting songs\n");
        // first sort the songs so we know they are grouped by artists, then albums
		toShow.sort((CompareFunc)songCompareFunc);
		
		string previousAlbum = "";
		stdout.printf("creating html with loop\n");
		// NOTE: things to keep in mind are search, miller column, artist="", album="" cases
		foreach(Song s in toShow) {
			if(s.album != previousAlbum) {
				html += "<li><a href=\"" + s.album + "<seperater>" + s.artist + "\"><img width=\"150\" height=\"150\" src=\"file://" + (GLib.File.new_for_path(s.getAlbumArtPath()).query_exists() ? s.getAlbumArtPath() : defaultPath) + "\" /></a><p>" + ( (s.album == "") ? "Miscellaneous" : s.album) + "</p><p>" + s.artist + "</p></li>";
				previousAlbum = s.album;
			}
		}
		
		html += "</ul></div></body></html>"; // finish up the last song, finish up html
		
		stdout.printf("loading string\n");
		view.load_string(html, "text/html", "utf8", "file://");
		needsUpdate = false;
		stdout.printf("loaded\n");
		
		showingSongs = toShow;
	}
	
	public static int songCompareFunc(Song a, Song b) {
		if(a.artist.down() == b.artist.down())
			return (a.album.down() > b.album.down()) ? 1 : -1;
		else
			return (a.artist.down() > b.artist.down()) ? 1 : -1;
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
					var toSearch = new LinkedList<Song>();
					foreach(int id in lm.songs_from_search(to_search, lw.miller.genres.selected, 
														lw.miller.artists.selected,
														lw.miller.albums.selected,
														songs)) {
						
						toSearch.add(lm.song_from_id(id));
					}
					
					if(showingSongs.size != toSearch.size) {
						generateHTML(toSearch);
					}
				}
				
				return false;
			});
		}
	}
	
}
