using Gtk;
using Gee;

public class BeatBox.AlbumView : ContentView, ScrolledWindow {
	LibraryManager lm;
	LibraryWindow lw;
	HashMap<string, LinkedList<int>> medias; // album+album_artist, list of related songs
	
	Collection<int> _show_next; // these are populated if necessary when user opens this view.
	HashMap<string, LinkedList<int>> _showing_medias;
	private string last_search;
	LinkedList<string> timeout_search;
	
	public IconView icons;
	AlbumViewModel model;
	
	Gdk.Pixbuf defaultPix;
	
	bool _is_current;
	bool _is_current_view;
	bool needsUpdate;
	
	public signal void itemClicked(string artist, string album);
	
	/* medias should be mutable, as we will be sorting it */
	public AlbumView(LibraryManager lmm, LibraryWindow lww, Collection<int> smedias) {
		lm = lmm;
		lw = lww;
		
		medias = new HashMap<string, LinkedList<int>>();
		_show_next = new LinkedList<int>();
		foreach(int i in smedias) {
			Media s = lm.media_from_id(i);
			string key = s.album_artist + s.album;
			
			if(medias.get(key) == null)
				medias.set(key, new LinkedList<int>());
				
			medias.get(key).add(i);
		}
		
		_showing_medias = new HashMap<string, LinkedList<int>>();
		last_search = "";
		timeout_search = new LinkedList<string>();
		
		defaultPix = lm.icons.DEFAULT_ALBUM_ART.render (null);
		
		buildUI();
		
		lm.medias_removed.connect(medias_removed);
	}
	
	public void buildUI() {
		set_policy(PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
		
		icons = new IconView();
		model = new AlbumViewModel(lm, defaultPix);
		
		icons.set_pixbuf_column(0);
		icons.set_markup_column(1);
		icons.set_item_width(134);
		icons.item_padding = 0;
		icons.spacing = 2;
		icons.margin = 20;
		add(icons);
		
		show_all();
		
		icons.button_release_event.connect(buttonReleaseEvent);
		icons.button_press_event.connect(buttonReleaseEvent);
		icons.item_activated.connect(itemActivated);
		this.size_allocate.connect(resized);
		this.focus_out_event.connect(on_focus_out);
		
		//this.grab_focus ();
	}
	
	public void set_is_current(bool val) {
		_is_current = val;
	}
	
	public bool get_is_current() {
		return _is_current;
	}
	
	public void set_is_current_view(bool val) {
		_is_current_view = val;
		
		if(!val)
			lw.alv.hide();
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
	
	public void set_show_next(Collection<int> medias) {
		_show_next = medias;
	}
	
	public void set_relative_id(int id) {
		// do nothing
	}
	
	public int get_relative_id() {
		return 0;
	}
	
	public Collection<int> get_medias() {
		return medias.keys;
	}
	
	public Collection<int> get_showing_medias() {
		return _showing_medias.keys;
	}
	
	public void set_as_current_list(int media_id, bool is_initial) {
		set_is_current(true);
	}
	
	public void set_statusbar_text() {
		/*uint count = 0;
		uint total_time = 0;
		uint total_mbs = 0;
		
		foreach(int id in _showing_medias) {
			++count;
			total_time += lm.media_from_id(id).length;
			total_mbs += lm.media_from_id(id).file_size;
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
		
		lw.set_statusbar_text(count.to_string() + " items, " + fancy + ", " + fancy_size);*/
	}
	
	/*public void set_medias(Collection<int> new_medias) {
		medias = new_medias;
	}*/
	
	public void resized(Allocation alloc) {
		icons.set_columns((alloc.width - (icons.margin * 2))/( icons.get_item_width()));
	}
	
	public void append_medias(Collection<int> new_medias) {
		var to_append = new LinkedList<Media>();
		
		foreach(int i in new_medias) {
			Media s = lm.media_from_id(i);
			string key = s.album_artist + s.album;
			
			if(medias.get(key) == null)
				medias.set(key, new LinkedList<int>());
			if(_showing_medias.get(key) == null) {
				_showing_medias.set(key, new LinkedList<int>());
				
				Media alb = new Media("");
				alb.album_artist = s.album_artist;
				alb.album = s.album;
				to_append.add(alb);
			}
			
			_showing_medias.get(key).add(i);
			medias.get(key).add(i);
		}
		
		model.appendMedias(to_append, true);
		model.resort();
		queue_draw();
	}
	
	public void remove_medias(Collection<int> to_remove) {
		var medias_remove = new LinkedList<Media>();
		
		foreach(int i in to_remove) {
			Media s = lm.media_from_id(i);
			if(s == null)
				continue;
			
			string key = s.album_artist + s.album;
			if(key == null)
				continue;
			
			if(medias.get(key) != null) {
				medias.get(key).remove(i);
				if(medias.get(key).size == 0)
					medias.unset(key);
			}
			if(_showing_medias.get(key) != null) {
				_showing_medias.get(key).remove(i);
				if(_showing_medias.get(key).size == 0) {
					medias.unset(key);
					
					Media alb = new Media("");
					alb.album_artist = s.album_artist;
					alb.album = s.album;
					medias_remove.add(alb);
				}
			}
		}
		
		model.removeMedias(medias_remove, true);
		queue_draw();
	}
	
	/** Goes through the hashmap and generates html. If artist,album, or genre
	 * is set, makes sure that only items that fit those filters are
	 * shown
	*/
	public void populate_view() {
		icons.freeze_child_notify();
		icons.set_model(null);
		
		_showing_medias.clear();
        var to_append = new LinkedList<Media>();
		foreach(int i in _show_next) {
			Media s = lm.media_from_id(i);
			string key = s.album_artist + s.album;
			
			if(medias.get(key) == null)
				medias.set(key, new LinkedList<int>());
			if(_showing_medias.get(key) == null) {
				_showing_medias.set(key, new LinkedList<int>());
				
				Media alb = new Media("");
				alb.album_artist = s.album_artist;
				alb.album = s.album;
				to_append.add(alb);
			}
			
			_showing_medias.get(key).add(i);
			medias.get(key).add(i);
		}
		
		model = new AlbumViewModel(lm, defaultPix);
		model.appendMedias(to_append, false);
		model.set_sort_column_id(0, SortType.ASCENDING);
		icons.set_model(model);
		icons.thaw_child_notify();
		
		//icons.realize();
		//realize();
		
		/* this is required to make the iconview initially scrollable */
		if(to_append.size > 0) {
			//icons.select_path(new TreePath.from_string((albs.size - 1).to_string()));
			//icons.unselect_all();
		}
		
		//if(visible)
		//	stdout.printf("get_is_current(): %d\n", get_is_current() ? 1 : 0);
		
		if(visible && lm.media_info.media != null)
			scrollToCurrent();
		//else
		//	this.vadjustment.set_value((int)hPos);
		
		needsUpdate = false;
	}
	
	public void update_medias(Collection<int> medias) {
		// nothing to do
	}
	
	public static int mediaCompareFunc(Media a, Media b) {
		if(a.album_artist.down() == b.album_artist.down())
			return (a.album > b.album) ? 1 : -1;
			
		return a.album_artist.down() > b.album_artist.down() ? 1 : -1;
	}
	
	public bool buttonReleaseEvent(Gdk.EventButton ev) {
		if(ev.type == Gdk.EventType.BUTTON_RELEASE && ev.button == 1) {
			TreePath path;
			CellRenderer cell;
				
			icons.get_item_at_pos((int)ev.x, (int)ev.y, out path, out cell);
			
			if(path == null)
				return false;
			
			itemActivated(path);
		}
		
		return false;
	}
	
	void itemActivated(TreePath path) {
		TreeIter iter;
		
		if(!model.get_iter(out iter, path)) {
			lw.alv.hide();
			
			return;
		}
		
		Media s = ((AlbumViewModel)model).get_media_representation(iter);
		
		lw.alv.set_songs_from_media(s);
		
		// find window's location
		int x, y;
		Gtk.Allocation alloc;
		lm.lw.get_position(out x, out y);
		get_allocation(out alloc);
		
		// move down to icon view's allocation
		x += lm.lw.sourcesToMedias.get_position();
		y += alloc.y;
		
		// center it on this icon view
		x += (alloc.width/2) - 175;
		y += (alloc.height/2) - 100;
		lw.alv.move(x, y);
		
		lw.alv.show_all();
		lw.alv.present();
	}
	
	void medias_removed(LinkedList<int> ids) {
		//model.removeMedias(ids, false);
		//_showing_medias.remove_all(ids);
		//_show_next.remove_all(ids);
	}
	
	public void scrollToCurrent() {
		if(!visible || lm.media_info.media == null)
			return;
			
		debug ("scrolling to current\n");
		
		TreeIter iter;
		model.iter_nth_child(out iter, null, 0);
		while(model.iter_next(ref iter)) {
			Value vs;
			model.get_value(iter, 2, out vs);

			if(icons is IconView && ((Media)vs).album == lm.media_info.media.album) {
				icons.scroll_to_path(model.get_path(iter), false, 0.0f, 0.0f);
				
				return;
			}
		}
	}
	
	public bool on_focus_out () {
		// Make sure that the search entry is not selected before grabbing focus
		if (!lw.searchField.has_focus)
			this.grab_focus ();

		return true;
	}
}
