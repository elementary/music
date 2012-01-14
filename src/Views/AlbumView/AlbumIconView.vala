using Gtk;
using Gee;

class BeatBox.Albums.Sidebar : Gtk.Grid
{
    public signal void close();
    public Sidebar()
    {
        var close = new Gtk.Button();
        close.set_image(new Gtk.Image.from_stock("gtk-close", Gtk.IconSize.MENU));
        attach(close, 0, 0, 1, 1);
        close.hexpand = close.vexpand = false;
        close.halign = Gtk.Align.START;
        close.set_relief(Gtk.ReliefStyle.NONE);
        close.clicked.connect( () =>  { this.close(); });
    }

    Gtk.Widget? content;
    public void set_content(Gtk.Widget widget)
    {
        if(content != null)
            remove(content);
        attach(widget, 0, 1, 1, 1);
        content = widget;
    }
}

public class BeatBox.Albums.IconView : Gtk.IconView
{
	internal LibraryManager lm;
	internal LibraryWindow lw;
    public signal void expand_widget(Gtk.Widget widget, int size);
    public signal void collapse_widget();
    Gtk.ListStore album_list;
    public IconView(AlbumViewModel model)
    {
        set_model(model);
        album_list = new Gtk.ListStore(2, typeof(string), typeof(string), null);
        add_title("L'Effet Papillion");
        add_title("Allez !");
        add_title("Les Numéros");
        add_title("Malgré Tout");
        add_title("Tout Vu Tout Lu");
        add_title("Pas Du Tout");
        add_title("Ou T'Etais Passé");
        add_title("Voir Sans Etre Vu");
        add_title("A La Campagne");
        add_title("Infréquentable");

        item_activated.connect(on_activate);
        button_press_event.connect(on_button_press);
    }

    void add_title(string title) {
        Gtk.TreeIter iter = Gtk.TreeIter();
        album_list.append(out iter);
        album_list.set(iter, 1, title, 0, track.to_string());
        track++;
    }
    
    void on_activate (Gtk.TreePath path) {
        
        /* Get the name and the author */
        
	    TreeIter iter;
	
	    if(!model.get_iter(out iter, path))
		    return;
	
	    Media s = ((AlbumViewModel)model).get_media(iter);
	    Gdk.Pixbuf pix;
	    model.get(iter, 0, out pix);
        
        var grid = new Gtk.Grid();
        var title = new Gtk.Label(s.album);
        var author = new Gtk.Label(s.artist);
        var image = new Gtk.Image.from_pixbuf(pix);
        author.sensitive = false;
        grid.attach(image, 0, 0, 1, 1);
        image.halign = Gtk.Align.CENTER;
        image.hexpand = true;
        grid.attach(title, 0, 1, 1, 1);
        grid.attach(author, 0, 2, 1, 1);

        /* Fake list view */
		var rv = new LinkedList<string>();
		rv.add("Title");
		rv.add("Album");
		rv.add("Artist");
		rv.add("Artist");
		rv.add("Artist");
		
		Collection<int> songs = new LinkedList<int>();
		Collection<int> albums = new LinkedList<int>();
		var tree_model = new MusicTreeModel (lm, rv, lm.icons.now_playing_icon.render (IconSize.MENU, get_style_context()));
		lm.do_search("", ViewWrapper.Hint.MUSIC, "All Genres", s.artist, s.album, lm.media_ids(), ref songs, ref albums);
		tree_model.append_medias(songs, false);
		
		var tree_view = new Gtk.TreeView();
		tree_view.set_model(tree_model);
        tree_view.append_column(new Gtk.TreeViewColumn.with_attributes("Tracks", new Gtk.CellRendererPixbuf(), "pixbuf", 1, null));
        tree_view.append_column(new Gtk.TreeViewColumn.with_attributes("Tracks", new Gtk.CellRendererText(), "text", 4, null));
        tree_view.headers_visible = false;
        tree_view.row_activated.connect( (path, c) => {
            Gtk.TreeIter tree_iter;
            tree_model.get_iter(out tree_iter, path);
            int id;
            tree_model.get(tree_iter, 0, out id);
		    lm.playMedia(id);
        });
        
        var scrolled = new Gtk.ScrolledWindow(null, null);
        scrolled.add(tree_view);
        scrolled.vexpand = true;

        grid.attach(scrolled, 0, 3, 1, 1);
        expand_widget(grid, (int)(get_allocated_width()*0.3));

        grid.margin_right= grid.margin_left = grid.margin_top = grid.margin_bottom = 10;
    }

    int track = 1;
    bool on_button_press(Gdk.EventButton event)
    {
        collapse_widget();
        return false;
    }

}

class BeatBox.Albums.View : GtkClutter.Embed
{
    Clutter.Container stage;
    GtkClutter.Actor icon_view;
    GtkClutter.Actor expand_view;
    IconView icon_view_widget;
    Sidebar sidebar;

    Clutter.CairoTexture shadow;

    public View()
    {
        stage = get_stage() as Clutter.Container;

        height_request = 600;
        width_request = 800;

        icon_view = new GtkClutter.Actor();
        icon_view.opacity = 255;
        stage.add_actor(icon_view);
        icon_view.height = height_request;
        icon_view.width = width_request;

        expand_view = new GtkClutter.Actor();
        stage.add_actor(expand_view);

        shadow = new Clutter.CairoTexture(10, height_request);
        shadow.draw.connect((cr) => {
            var lg1 = new Cairo.Pattern.linear(4.0, 0.0, 10.0, 0.0);
           
            lg1.add_color_stop_rgba(0, 0.3, 0.3, 0.3, 0);
            lg1.add_color_stop_rgba(1, 0.3, 0.3, 0.3, 0.3);


            cr.rectangle(4, 0, 6.0, height_request);
            cr.set_source(lg1);
            cr.fill();
            return false;
        });
        shadow.invalidate();
        stage.add_actor(shadow);
        shadow.x = get_allocated_width();
        sidebar = new Sidebar();
        (expand_view.get_widget() as Gtk.Bin).add(sidebar);
        sidebar.close.connect(on_collapse);
        
        size_allocate.connect(on_size_allocate);
    }
    
    bool expanded = false;
    
    void on_size_allocate(Gtk.Allocation alloc)
    {
        icon_view.height = alloc.height;
        icon_view.width = alloc.width;
        shadow.height = alloc.height;
        expand_view.height = alloc.height;
        if(!expanded) {
            shadow.x = alloc.width;
            expand_view.x = alloc.width + 10;
        }
        else {
            shadow.x = alloc.width - expand_width - 10;
            expand_view.x = alloc.width - expand_width;
        }
    }

    public void set_icon_view(IconView icon_view_wi)
    {
        var scrolled = new Gtk.ScrolledWindow(null, null);
        scrolled.add_with_viewport(icon_view_wi);
        icon_view_widget = icon_view_wi;
        icon_view_widget.expand_widget.connect(on_expand);
        icon_view_widget.collapse_widget.connect(on_collapse);

        (icon_view.get_widget() as Gtk.Bin).add(scrolled);
        scrolled.show_all();
    }

    void on_collapse()
    {
        expanded = false;
        double x = get_allocated_width() + 10;
        double x2 = get_allocated_width();
        expand_view.animate(Clutter.AnimationMode.EASE_OUT_QUAD, 400, x:x);
        shadow.animate(Clutter.AnimationMode.EASE_OUT_QUAD, 400, x:x2);
        icon_view.animate(Clutter.AnimationMode.EASE_OUT_QUAD, 400, opacity:255);
    }
    
    int expand_width = 0;

    void on_expand(Gtk.Widget label, int width)
    {
        expanded = true;
        expand_width = width;
        expand_view.x = get_allocated_width() + 10;
        shadow.x = get_allocated_width();
        shadow.opacity = 255;
        expand_view.width = width;
        double x = get_allocated_width() - width;
        double x2 = get_allocated_width() - width - 10;
        expand_view.animate(Clutter.AnimationMode.EASE_OUT_QUAD, 400, x:x);
        shadow.animate(Clutter.AnimationMode.EASE_OUT_QUAD, 400, x:x2);
        icon_view.animate(Clutter.AnimationMode.EASE_OUT_QUAD, 400, opacity:50);
        sidebar.set_content(label); 
        sidebar.show_all();
    }
}

public class BeatBox.AlbumView : ContentView, ScrolledWindow {
	LibraryManager lm;
	LibraryWindow lw;
	Collection<int> medias;
	
	private Collection<int> _show_next; // these are populated if necessary when user opens this view.
	private Collection<int> _showing_medias;
	private string last_search;
	LinkedList<string> timeout_search;
	
	public BeatBox.Albums.IconView icons;
	AlbumViewModel model;
	
	Gdk.Pixbuf defaultPix;
	
	bool _is_current;
	bool _is_current_view;
	bool needsUpdate;
	BeatBox.Albums.View view;
	
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
		/*Viewport v = new Viewport(null, null);*/
		
        /*set_policy(PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);*/
        view = new BeatBox.Albums.View();
		
		/*v.set_shadow_type(ShadowType.NONE);*/
		model = new AlbumViewModel(lm, defaultPix);
		icons = new BeatBox.Albums.IconView(model);
		view.set_icon_view(icons);
		
		icons.set_pixbuf_column(0);
		icons.set_markup_column(1);
		icons.set_item_width(134);
		icons.item_padding = 0;
		icons.spacing = 2;
		icons.margin = 20;
		icons.lm = lm;
		icons.lw = lw;
		//v.add(icons);
		
		add_with_viewport(view);
		
		show_all();
		
		//icons.button_press_event.connect(buttonPressEvent);
		//icons.item_activated.connect(itemActivated);
		this.size_allocate.connect(resized);
		this.focus_out_event.connect(on_focus_out);
		
		this.grab_focus ();
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
	    
		//_showing_medias.add_all(new_medias); /* apparently we mustn't do that */
		
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
		}
		
		model.appendMedias(albs, false);
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
		
		//var hPos = this.vadjustment.get_value();
		
		model = new AlbumViewModel(lm, defaultPix);
		model.appendMedias(albs, false);
		icons.set_model(model);
		
		//move_focus_out(DirectionType.UP);
		
		/* this is required to make the iconview initially scrollable */
		if(albs.size > 0) {
			//icons.select_path(new TreePath.from_string((albs.size - 1).to_string()));
			//icons.unselect_all();
		}
		
		/*if(get_is_current() && lm.media_info.media != null)
			scrollToCurrent();
		else
			this.vadjustment.set_value((int)hPos);*/
		
		needsUpdate = false;
	}
	
	public void update_medias(Collection<int> medias) {
		// nothing to do
	}
	
	public static int mediaCompareFunc(Media a, Media b) {
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
	
	void medias_removed(LinkedList<int> ids) {
		model.removeMedias(ids);
		//_showing_medias.remove_all(ids);
		//_show_next.remove_all(ids);
	}
	
	public void scrollToCurrent() {
		if(!get_is_current() || lm.media_info.media == null)
			return;
		
		TreeIter iter;
		for(int i = 0; model.get_iter_from_string(out iter, i.to_string()); ++i) {
			Value vs;
			model.get_value(iter, 2, out vs);

			if(icons is IconView && ((Media)vs).album == lm.media_info.media.album) {
				icons.scroll_to_path(new TreePath.from_string(i.to_string()), false, 0.0f, 0.0f);
				
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
