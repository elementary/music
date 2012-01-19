using Gtk;
using Gee;

public class BeatBox.AlbumView : ContentView, ScrolledWindow {
	LibraryManager lm;
	LibraryWindow lw;
	Collection<int> medias;
	
	private Collection<int> _show_next; // these are populated if necessary when user opens this view.
	private Collection<int> _showing_medias;
	private string last_search;
	LinkedList<string> timeout_search;
	
	public IconView icons;
	AlbumViewModel model;
	
	Gdk.Pixbuf defaultPix;
	
	bool _is_current;
	bool _is_current_view;
	bool needsUpdate;
	
	AlbumListView alv;
	
	public signal void itemClicked(string artist, string album);
	
	/* medias should be mutable, as we will be sorting it */
	public AlbumView(LibraryManager lmm, LibraryWindow lww, Collection<int> smedias) {
		lm = lmm;
		lw = lww;
		medias = smedias;
		
		_showing_medias = new LinkedList<int>();
		last_search = "";
		timeout_search = new LinkedList<string>();
		
		defaultPix = lm.icons.default_album_art.render (null, null);
		
		buildUI();
		
		lm.medias_removed.connect(medias_removed);
	}
	
	public void buildUI() {
		Viewport v = new Viewport(null, null);
		alv = new AlbumListView(lm);
		
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
		
		icons.button_release_event.connect(buttonReleaseEvent);
		icons.button_press_event.connect(buttonReleaseEvent);
		//icons.item_activated.connect(itemActivated);
		this.size_allocate.connect(resized);
		this.focus_out_event.connect(on_focus_out);
		
		this.grab_focus ();
	}
	
	public void set_is_current(bool val) {
		_is_current = val;
		stdout.printf("album icon view is no %d\n", val ? 1 : 0);
	}
	
	public bool get_is_current() {
		return _is_current;
	}
	
	public void set_is_current_view(bool val) {
		_is_current_view = val;
		
		if(!val)
			alv.hide();
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
		return medias;
	}
	
	public Collection<int> get_showing_medias() {
		return _showing_medias;
	}
	
	public void set_as_current_list(int media_id, bool is_initial) {
		set_is_current(true);
	}
	
	public void set_statusbar_text() {
		uint count = 0;
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
		
		lw.set_statusbar_text(count.to_string() + " items, " + fancy + ", " + fancy_size);
	}
	
	/*public void set_medias(Collection<int> new_medias) {
		medias = new_medias;
	}*/
	
	public void resized(Allocation alloc) {
		icons.set_columns((alloc.width - (icons.margin * 2))/( icons.get_item_width()));
	}
	
	public void append_medias(Collection<int> new_medias) {
		/*_showing_medias.add_all(new_medias);
		
		var toShowS = new LinkedList<Media>();
        foreach(int i in new_medias)
			toShowS.add(lm.media_from_id(i));
        
        // first sort the medias so we know they are grouped by artists, then albums
		toShowS.sort((CompareFunc)mediaCompareFunc);
		
		LinkedList<int> albs = new LinkedList<int>();
		string previousAlbum = "";
		
		foreach(Media s in toShowS) {
			if(s.album != previousAlbum) {
				albs.add(s.rowid);
				
				previousAlbum = s.album;
			}
		}*/
		
		//model.appendMedias(albs, false);
		//model.resort();
		queue_draw();
	}
	
	public void remove_medias(Collection<int> to_remove) {
		
	}
	
	/** Goes through the hashmap and generates html. If artist,album, or genre
	 * is set, makes sure that only items that fit those filters are
	 * shown
	*/
	public void populate_view() {
		if(_show_next == _showing_medias) {
			return;
		}
		
		_showing_medias = _show_next;
		
        var toShowS = new LinkedList<Media>();
        foreach(int i in _showing_medias)
			toShowS.add(lm.media_from_id(i));
        
        // first sort the medias so we know they are grouped by artists, then albums
		toShowS.sort((CompareFunc)mediaCompareFunc);
		
		LinkedList<int> albs = new LinkedList<int>();
		string previousAlbum = "";
		
		foreach(Media s in toShowS) {
			if(s.album != previousAlbum) {
				albs.add(s.rowid);
				
				previousAlbum = s.album;
			}
		}
		
		var hPos = this.vadjustment.get_value();
		
		model = new AlbumViewModel(lm, defaultPix);
		model.appendMedias(albs, false);
		icons.set_model(model);
		
		grab_focus();
		
		/* this is required to make the iconview initially scrollable */
		if(albs.size > 0) {
			//icons.select_path(new TreePath.from_string((albs.size - 1).to_string()));
			//icons.unselect_all();
		}
		
		//if(visible)
		//	stdout.printf("get_is_current(): %d\n", get_is_current() ? 1 : 0);
		
		if(visible && lm.media_info.media != null)
			scrollToCurrent();
		else
			this.vadjustment.set_value((int)hPos);
		
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
		stdout.printf("button was pressed\n");
		if(ev.type == Gdk.EventType.BUTTON_RELEASE && ev.button == 1) {
			TreePath path;
			TreeIter iter;
			CellRenderer cell;
				
			icons.get_item_at_pos((int)ev.x, (int)ev.y, out path, out cell);
				
			if(!model.get_iter(out iter, path)) {
				alv.hide();
				stdout.printf("could not get iter from path\n");
				return false;
			}
			
			icons.select_path(path);
			
			stdout.printf("showing!\n");
			Media s = lm.media_from_id(((AlbumViewModel)model).get_media_id(iter));
			
			alv.set_songs_from_media(s);
			alv.move_to_coords((int)ev.x_root, (int)ev.y_root);
			alv.show_all();
			alv.present();
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
	
	void medias_removed(LinkedList<int> ids) {
		model.removeMedias(ids);
		//_showing_medias.remove_all(ids);
		//_show_next.remove_all(ids);
	}
	
	public void scrollToCurrent() {
		if(!visible || lm.media_info.media == null)
			return;
			
		stdout.printf("scrolling to current\n");
		
		TreeIter iter;
		model.iter_nth_child(out iter, null, 0);
		while(model.iter_next(ref iter)) {
			Value vs;
			model.get_value(iter, 2, out vs);

			if(icons is IconView && lm.media_from_id(vs.get_int()).album == lm.media_info.media.album) {
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
