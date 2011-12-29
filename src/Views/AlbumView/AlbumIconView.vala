using Gtk;
using Gee;

public class BeatBox.AlbumView : ContentView, ScrolledWindow {
	LibraryManager lm;
	LibraryWindow lw;
	Collection<int> songs;
	
	private Collection<int> _show_next; // these are populated if necessary when user opens this view.
	private Collection<int> _showing_songs;
	private string last_search;
	LinkedList<string> timeout_search;
	
	public IconView icons;
	AlbumViewModel model;
	
	Gdk.Pixbuf defaultPix;
	
	bool _is_current;
	bool _is_current_view;
	bool needsUpdate;
	
	public signal void itemClicked(string artist, string album);
	
	/* songs should be mutable, as we will be sorting it */
	public AlbumView(LibraryManager lmm, LibraryWindow lww, Collection<int> ssongs) {
		lm = lmm;
		lw = lww;
		songs = ssongs;
		
		_showing_songs = new LinkedList<int>();
		last_search = "";
		timeout_search = new LinkedList<string>();
		
		defaultPix = lm.icons.default_album_art;
		
		buildUI();
		
		lm.songs_removed.connect(songs_removed);
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
		
		//icons.button_press_event.connect(buttonPressEvent);
		icons.item_activated.connect(itemActivated);
		this.size_allocate.connect(resized);
	}
	
	public void set_is_current(bool val) {
		_is_current = val;
		//model.is_current = val;
	}
	
	public bool get_is_current() {
		return _is_current;
	}
	
	public void set_is_current_view(bool val) {
		_is_current_view = val;
	}
	
	public bool get_is_current_view() {
		return _is_current_view;
	}
	
	public void set_hint(ViewWrapper.Hint hint) {
		// nothing
	}
	
	public ViewWrapper.Hint get_hint() {
		return ViewWrapper.Hint.MUSIC;
	}
	
	public void set_show_next(Collection<int> songs) {
		_show_next = songs;
	}
	
	public void set_relative_id(int id) {
		// do nothing
	}
	
	public int get_relative_id() {
		return 0;
	}
	
	public Collection<int> get_songs() {
		return songs;
	}
	
	public Collection<int> get_showing_songs() {
		return _showing_songs;
	}
	
	public void set_as_current_list(int song_id, bool is_initial) {
		set_is_current(true);
	}
	
	public void set_statusbar_text() {
		uint count = 0;
		uint total_time = 0;
		uint total_mbs = 0;
		
		foreach(int id in _showing_songs) {
			++count;
			total_time += lm.song_from_id(id).length;
			total_mbs += lm.song_from_id(id).file_size;
		}
		
		string fancy = "";
		if(total_time < 3600) { // less than 1 hour show in minute units
			fancy = (total_time/60).to_string() + " minutes";
		}
		else if(total_time < (24 * 3600)) { // less than 1 day show in hour units
			fancy = (total_time/3600).to_string() + " hours";
		}
		else { // units in days
			fancy = (total_time/(24 * 3600)).to_string() + " days";
		}
		
		string fancy_size = "";
		if(total_mbs < 1000)
			fancy_size = ((float)(total_mbs)).to_string() + " MB";
		else 
			fancy_size = ((float)(total_mbs/1000.0f)).to_string() + " GB";
		
		lw.set_statusbar_text(count.to_string() + " items, " + fancy + ", " + fancy_size);
	}
	
	/*public void set_songs(Collection<int> new_songs) {
		songs = new_songs;
	}*/
	
	public void resized(Allocation alloc) {
		icons.set_columns((alloc.width - (icons.margin * 2))/( icons.get_item_width()));
	}
	
	/** Goes through the hashmap and generates html. If artist,album, or genre
	 * is set, makes sure that only items that fit those filters are
	 * shown
	*/
	public void populate_view() {
		if(_show_next == _showing_songs) {
			return;
		}
		
		_showing_songs = _show_next;
		
        var toShowS = new LinkedList<Song>();
        foreach(int i in _showing_songs)
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
		
		var hPos = this.vadjustment.get_value();
		
		model = new AlbumViewModel(lm, defaultPix);
		model.appendSongs(albs, false);
		icons.set_model(model);
		
		move_focus_out(DirectionType.UP);
		
		/* this is required to make the iconview initially scrollable */
		if(albs.size > 0) {
			//icons.select_path(new TreePath.from_string((albs.size - 1).to_string()));
			//icons.unselect_all();
		}
		
		if(get_is_current() && lm.song_info.song != null)
			scrollToCurrent();
		else
			this.vadjustment.set_value((int)hPos);
		
		needsUpdate = false;
	}
	
	public void update_songs(Collection<int> songs) {
		// nothing to do
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
	
	void songs_removed(LinkedList<int> ids) {
		model.removeSongs(ids);
		//_showing_songs.remove_all(ids);
		//_show_next.remove_all(ids);
	}
	
	public void scrollToCurrent() {
		if(!get_is_current() || lm.song_info.song == null)
			return;
		
		TreeIter iter;
		for(int i = 0; model.get_iter_from_string(out iter, i.to_string()); ++i) {
			Value vs;
			model.get_value(iter, 2, out vs);

			if(icons is IconView && ((Song)vs).album == lm.song_info.song.album) {
				icons.scroll_to_path(new TreePath.from_string(i.to_string()), false, 0.0f, 0.0f);
				
				return;
			}
		}
	}
}
