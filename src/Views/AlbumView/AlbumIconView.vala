using Gtk;
using Gee;

public class BeatBox.AlbumView : ScrolledWindow {
	LibraryManager lm;
	LibraryWindow lw;
	Collection<int> songs;
	
	private Collection<int> showingSongs;
	private string last_search;
	LinkedList<string> timeout_search;
	
	public IconView icons;
	AlbumViewModel model;
	
	Gdk.Pixbuf defaultPix;
	
	public bool isCurrentView;
	public bool needsUpdate;
	
	public signal void itemClicked(string artist, string album);
	
	/* songs should be mutable, as we will be sorting it */
	public AlbumView(LibraryManager lmm, LibraryWindow lww, Collection<int> ssongs) {
		lm = lmm;
		lw = lww;
		songs = ssongs;
		
		showingSongs = new LinkedList<int>();
		last_search = "";
		timeout_search = new LinkedList<string>();
		
		defaultPix = new Gdk.Pixbuf.from_file(GLib.Path.build_filename("/usr", "share", "icons", "hicolor", "128x128", "mimetypes", "media-audio.png", null));
		
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
		icons.set_item_width(134);
		icons.item_padding = 0;
		icons.spacing = 2;
		icons.margin = 20;
		v.add(icons);
		
		add(v);
		
		show_all();
		
		icons.button_press_event.connect(buttonPressEvent);
		icons.item_activated.connect(itemActivated);
		this.size_allocate.connect(resized);
	}
	
	public void set_songs(Collection<int> new_songs) {
		songs = new_songs;
	}
	
	public void resized(Allocation alloc) {
		icons.set_columns((alloc.width - (icons.margin * 2))/( icons.get_item_width()));
	}
	
	/** Goes through the hashmap and generates html. If artist,album, or genre
	 * is set, makes sure that only items that fit those filters are
	 * shown
	*/
	public void populateView(Collection<int> toShow, bool force) {
		
		showingSongs = toShow;
		
        var toShowS = new LinkedList<Song>();
        foreach(int i in showingSongs)
			toShowS.add(lm.song_from_id(i));
        
        // first sort the songs so we know they are grouped by artists, then albums
		toShowS.sort((CompareFunc)songCompareFunc);
		
		LinkedList<int> albs = new LinkedList<int>();
		string previousAlbum = "";
		
		foreach(Song s in toShowS) {
			if(s.album != previousAlbum) {
				albs.add(s.rowid);
				
				previousAlbum = s.album;
			}
		}
		
		model = new AlbumViewModel(lm, defaultPix);
		model.appendSongs(albs, false);
		icons.set_model(model);
		
		needsUpdate = false;
	}
	
	public static int songCompareFunc(Song a, Song b) {
		return (a.album > b.album) ? 1 : -1;
	}
	
	public bool buttonPressEvent(Gdk.EventButton ev) {
		stdout.printf("button was pressed\n");
		if(ev.type == Gdk.EventType.BUTTON_PRESS && ev.button == 1) {
			// select one based on mouse position
			TreeIter iter;
			TreePath path;
			TreeViewColumn column;
			CellRenderer cell;
			
			icons.get_item_at_pos((int)ev.x, (int)ev.y, out path, out cell);
			
			if(!model.get_iter(out iter, path))
				return false;
			
			string s;
			model.get(iter, 1, out s);
			
			string[] pieces = s.split("\n", 0);
		
			itemClicked(pieces[0], pieces[1]);
		}
		
		return false;
	}
	
	public virtual void itemActivated(TreePath path) {
		TreeIter iter;
		
		if(!model.get_iter(out iter, path))
			return;
		
		string s;
		model.get(iter, 1, out s);
		
		string[] pieces = s.split("\n", 0);
		
		itemClicked(pieces[0], pieces[1]);
	}
	
}
