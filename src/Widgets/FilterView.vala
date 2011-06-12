using Gtk;
using Gee;

public class BeatBox.FilterView : ScrolledWindow {
	LibraryManager lm;
	LibraryWindow lw;
	LinkedList<int> songs;
	
	private Collection<int> showingSongs;
	private string last_search;
	LinkedList<string> timeout_search;
	
	IconView icons;
	AlbumViewModel model;
	
	Gdk.Pixbuf defaultPix;
	
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
		
		defaultPix = new Gdk.Pixbuf.from_file(GLib.Path.build_filename("/usr", "share", "icons", "hicolor", "128x128", "mimetypes", "media-audio.svg", null));
		
		buildUI();
	}
	
	public void buildUI() {
		Viewport v = new Viewport(null, null);
		
        set_policy(PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
		
		v.set_shadow_type(ShadowType.NONE);
		icons = new IconView();
		model = new AlbumViewModel(lm, defaultPix);
		
		icons.set_pixbuf_column(0);
		icons.set_markup_column(1);
		icons.set_item_width(200);
		v.add(icons);
		
		add(v);
		
		show_all();
		lw.searchField.changed.connect(searchFieldChanged);
		this.size_allocate.connect(resized);
	}
	
	public void resized(Gdk.Rectangle alloc) {
		icons.set_columns(alloc.width/icons.get_item_width());
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
        
        stdout.printf("sorting songs\n");
        // first sort the songs so we know they are grouped by artists, then albums
		toShow.sort((CompareFunc)songCompareFunc);
		
		LinkedList<AlbumViewModelObject> albs = new LinkedList<AlbumViewModelObject>();
		string previousAlbum = "";
		stdout.printf("creating html with loop\n");
		foreach(Song s in toShow) {
			if(s.album != previousAlbum) {
				albs.add( new AlbumViewModelObject(defaultPix, s.album.replace("&", "&amp;"), s.artist.replace("&", "&amp;")));
				
				previousAlbum = s.album;
			}
		}
		stdout.printf("populating %d\n", albs.size);
		model = new AlbumViewModel(lm, defaultPix);
		model.appendAlbums(albs, false);
		icons.set_model(model);
		
		showingSongs = toShow;
		needsUpdate = false;
	}
	
	public static int songCompareFunc(Song a, Song b) {
		if(a.artist.down() == b.artist.down())
			return (a.album.down() > b.album.down()) ? 1 : -1;
		else
			return (a.artist.down() > b.artist.down()) ? 1 : -1;
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
					
					if(showingSongs.size != toSearch.size || needsUpdate) {
						generateHTML(toSearch);
					}
				}
				
				return false;
			});
		}
	}
	
}
