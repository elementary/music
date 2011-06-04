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
	
	VBox mainBox; // put comboboxes in top, artistBox in bottom
	
	WebView view;
	ScrolledWindow viewScroll;
	
	private string last_search;
	LinkedList<string> timeout_search;
	
	public signal void itemClicked(string artist, string album);
	
	/* songs should be mutable, as we will be sorting it */
	public FilterView(LibraryManager lmm, LibraryWindow lww, LinkedList<int> ssongs) {
		lm = lmm;
		lw = lww;
		songs = ssongs;
		
		last_search = "";
		timeout_search = new LinkedList<string>();
		
		buildUI();
	}
	
	public void buildUI() {
		mainBox = new VBox(false, 0);
		view = new WebView();
		viewScroll = new ScrolledWindow(null, null);
		Label infoLabel = new Label("");
		EventBox infoBox = new EventBox();
		
        viewScroll.set_policy(PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
        viewScroll.add (view);
		
		view.settings.enable_default_context_menu = false;
		
		Gdk.Color c = Gdk.Color();
		Gdk.Color.parse("#FFFFFF", out c);
		infoBox.modify_bg(StateType.NORMAL, c);
		
		infoLabel.xalign = 0.5f;
		infoLabel.justify = Justification.CENTER;
		infoLabel.set_markup("<span weight=\"bold\" size=\"larger\">NOTICE</span>\nThank you for using the BeatBox development PPA! This 'view' is new and under development.\n However, we want your opinions. \nAfter you try it out a little bit, let us know what you think at https://answers.launchpad.net/beat-box/+question/160089.\nThank you!");
		
		infoBox.add(infoLabel);
		mainBox.pack_start(infoBox, false, true, 0);
		mainBox.pack_start(viewScroll, true, true, 0);
		
		Viewport vp = new Viewport(null, null);
		vp.set_shadow_type(ShadowType.NONE);
		vp.add(mainBox);
		
		add(vp);
		
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
		string html = """<!DOCTYPE html> <html lang="en"><head> 
        <style media="screen" type="text/css"> 
            body { 
                background: #fff; 
                font-family: "Droid Sans",sans-serif; 
                margin: 0 auto; 
                width: 100%; 
            }
            #main {
				margin: auto;
			}
            #main ul {
                height: auto;
                padding-bottom: 10px;
                margin-left: 0px;
                padding-left: 0px;
                margin-top: -10px;
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
        
        // first sort the songs so we know they are grouped by artists, then albums
		toShow.sort((CompareFunc)songCompareFunc);
		
		string previousAlbum = "";
		
		// NOTE: things to keep in mind are search, miller column, artist="", album="" cases
		foreach(Song s in toShow) {
			if(s.album != previousAlbum) {
				html += "<li><a href=\"" + s.album + "<seperater>" + s.artist + "\"><img src=\"file://" + s.getAlbumArtPath() + "\" /></a><p>" + ( (s.album == "") ? "Miscellaneous" : s.album) + "</p><p>" + s.artist + "</p></li>";
				previousAlbum = s.album;
			}
		}
		
		html += "</ul></div></body></html>"; // finish up the last song, finish up html
		
		view.load_string(html, "text/html", "utf8", "file://");
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
		if(/*is_current_view && */lw.searchField.get_text().length != 1) {
			timeout_search.offer_head(lw.searchField.get_text().down());
			Timeout.add(100, () => {
				string to_search = timeout_search.poll_tail();
				
				var toSearch = new LinkedList<Song>();
				foreach(int id in lm.songs_from_search(to_search, songs)) {
					toSearch.add(lm.song_from_id(id));
				}
					
				generateHTML(toSearch);
				
				return false;
			});
		}
	}
	
}
