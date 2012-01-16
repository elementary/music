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
    
    public Gtk.Widget get_content() { return content; }
}

public class BeatBox.Albums.IconView : Gtk.IconView
{
	internal LibraryManager lm;
	internal LibraryWindow lw;
    public signal void expand_widget(Gtk.Widget widget, int size);
    public signal void collapse_widget();
    public IconView(AlbumViewModel model)
    {
        set_model(model);

        item_activated.connect(on_activate);
        button_press_event.connect(on_button_press);
    }

    void on_activate (Gtk.TreePath path) {
        
        /* Get the name and the author */
        
	    TreeIter iter;
	
	    if(!model.get_iter(out iter, path))
	    {
            collapse_widget();
	        return;
	    }
	
	    Media s = ((AlbumViewModel)model).get_media(iter);
	    Gdk.Pixbuf pix;
	    model.get(iter, 0, out pix);
        
        var grid = new Gtk.Grid();
        var title = new Granite.Widgets.WrapLabel(s.album);
        title.set_alignment(0.5f, 0.5f);
        title.set_justify(Gtk.Justification.CENTER);
        var author = new Granite.Widgets.WrapLabel(s.artist);
        author.set_alignment(0.5f, 0.5f);
        author.set_justify(Gtk.Justification.CENTER);
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
		
		LinkedList<int> songs = new LinkedList<int>();
		LinkedList<int> albums = new LinkedList<int>();
		var tree_view = new Gtk.TreeView();
		var tree_model = new MusicTreeModel (lm, rv, lm.icons.now_playing_icon.render (IconSize.MENU, get_style_context()), ViewWrapper.Hint.MUSIC, tree_view);
		lm.do_search("", ViewWrapper.Hint.MUSIC, "All Genres", s.artist, s.album, lm.media_ids(), ref songs, ref albums);
		tree_model.append_medias(songs, false);
		
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
    public bool expanded = false;
    bool on_button_press(Gdk.EventButton event)
    {
        /*if(expanded)
        {
            collapse_widget();
            return true;
        }*/
        base.button_press_event(event);
        var selection = get_selected_items();
        if(selection.length() == 0)
            collapse_widget();
        else
        {
            on_activate(selection.nth_data(0));
        }
        return true;
    }

}

class BeatBox.Albums.View : GtkClutter.Embed
{
    Clutter.Container stage;
    GtkClutter.Actor icon_view;
    GtkClutter.Actor expand_view;
    GtkClutter.Actor old_expand_view;
    IconView icon_view_widget;
    Sidebar sidebar;
    Sidebar old_sidebar;

    Clutter.Group shadow;
    Clutter.CairoTexture shadow_left;
    Clutter.CairoTexture shadow_top;
    Clutter.CairoTexture shadow_bottom;
    

    public View()
    {
        stage = get_stage() as Clutter.Container;

        height_request = width_request = 50;
        shadow = new Clutter.Group();
        shadow_left = new Clutter.CairoTexture(shadow_size*3, height_request);
        shadow.add(shadow_left);
        shadow_top = new Clutter.CairoTexture(20, shadow_size*2);
        shadow_top.x = 3*shadow_size + 1;
        shadow_bottom = new Clutter.CairoTexture(20, shadow_size*2);
        shadow.add(shadow_bottom);
        shadow_bottom.x = 3*shadow_size + 1;
        shadow.add(shadow_top);
        shadow.y = margin_top - shadow_size;
        stage.add_actor(shadow);
        
        shadow_left.draw.connect((cr) => {
            cr.set_source_surface(buffer_shadow.surface, 0, 0);
            cr.paint();
            return false;
        });
        shadow_left.auto_resize = true;
        shadow_top.draw.connect((cr) => {
            cr.set_source_surface(buffer_shadow.surface, -2*shadow_size, 0);
            cr.paint();
            return false;
        });
        shadow_bottom.draw.connect((cr) => {
            cr.set_source_surface(buffer_shadow.surface, -2*shadow_size, - buffer_shadow.height + 2*shadow_size);
            cr.paint();
            return false;
        });

        icon_view = new GtkClutter.Actor();
        icon_view.opacity = 255;
        stage.add_actor(icon_view);
        icon_view.height = height_request;
        icon_view.width = width_request;

        expand_view = new GtkClutter.Actor();
        stage.add_actor(expand_view);

        old_expand_view = new GtkClutter.Actor();
        stage.add_actor(old_expand_view);
        old_sidebar = new Sidebar();
        (old_expand_view.get_widget() as Gtk.Bin).add(old_sidebar);
    
        shadow.x = get_allocated_width();
        sidebar = new Sidebar();
        (expand_view.get_widget() as Gtk.Bin).add(sidebar);
        sidebar.close.connect(on_collapse);
        
        size_allocate.connect(on_size_allocate);
    }
    
    const int shadow_size = 5;
    const int margin_top = 30;

    Granite.Drawing.BufferSurface buffer_shadow;
    void update_shadow_surface(int? height = null)
    {
        height = height ?? get_allocated_height();
        buffer_shadow = new Granite.Drawing.BufferSurface(expand_width + shadow_size, height - 2*margin_top + 2*shadow_size);
        buffer_shadow.context.rectangle(shadow_size, shadow_size, expand_width, height - 2*margin_top);
        buffer_shadow.context.set_source_rgb(0,0,0);
        buffer_shadow.context.fill();
        buffer_shadow.fast_blur(2, 2);
    }
    
    bool expanded = false;
    
    void on_size_allocate(Gtk.Allocation alloc)
    {
        icon_view.height = alloc.height;
        icon_view.width = alloc.width;
        shadow.height = alloc.height;
        shadow_bottom.y =  shadow.height - 2*margin_top - 1;
        expand_view.height = alloc.height - 2*margin_top - 1;
        old_expand_view.height = alloc.height - 2*margin_top - 1;
        expand_view.y = margin_top;
        old_expand_view.y = margin_top;
        if(!expanded) {
            shadow.x = alloc.width;
            expand_view.x = alloc.width + shadow_size;
        }
        else {
            shadow.x = alloc.width - expand_width - shadow_size;
            expand_view.x = alloc.width - expand_width;
        }
        if(expanded) {
            update_shadow_surface(alloc.height);
            shadow_left.height = alloc.height - margin_top - shadow_size;
        }
    }

    public void set_icon_view(IconView icon_view_wi) {
        var scrolled = new Gtk.ScrolledWindow(null, null);
        scrolled.set_policy(PolicyType.NEVER, PolicyType.AUTOMATIC);
        scrolled.add_with_viewport(icon_view_wi);
        icon_view_widget = icon_view_wi;
        icon_view_widget.expand_widget.connect(on_expand);
        icon_view_widget.collapse_widget.connect(on_collapse);

        (icon_view.get_widget() as Gtk.Bin).add(scrolled);
        scrolled.show_all();
    }

    void on_collapse() {
        expanded = false;
        icon_view_widget.expanded = false;
        double x = get_allocated_width() + 10;
        double x2 = get_allocated_width();
        expand_view.animate(Clutter.AnimationMode.EASE_OUT_QUAD, 400, x:x);
        shadow.animate(Clutter.AnimationMode.EASE_OUT_QUAD, 400, x:x2);
        icon_view.animate(Clutter.AnimationMode.EASE_OUT_QUAD, 400, opacity:255);
        
    }
    
    int expand_width = 0;

    bool first = false;
    void on_expand(Gtk.Widget label, int width) {
        if(expanded) {
            var w = sidebar.get_content();
            sidebar.set_content(label);
            old_sidebar.set_content(w);
            old_sidebar.show_all();
            old_expand_view.x = get_allocated_width() - expand_width;
            old_expand_view.opacity = 255;
            old_expand_view.animate(Clutter.AnimationMode.EASE_OUT_QUAD, 400, opacity:0);
            Timeout.add(400, () => {
                old_expand_view.x = - expand_width;
                return false;
            }); /* and hide it */
        }
        else {
            expand_width = width;
            update_shadow_surface();
            shadow_bottom.width = shadow_top.width = expand_width - shadow_size;
            if(!first) {
                shadow_top.invalidate();
                shadow_bottom.invalidate();
                first = true;
            }
            shadow_left.height = get_allocated_height() - margin_top - shadow_size;
            expand_view.x = get_allocated_width() + 10;
            shadow.x = get_allocated_width();
            shadow.width = expand_width + 5;
            shadow.opacity = 255;
            expand_view.width = width;
            double x = get_allocated_width() - width;
            double x2 = get_allocated_width() - width - shadow_size;
            expand_view.animate(Clutter.AnimationMode.EASE_OUT_QUAD, 400, x:x);
            shadow.animate(Clutter.AnimationMode.EASE_OUT_QUAD, 400, x:x2);
            icon_view.animate(Clutter.AnimationMode.EASE_OUT_QUAD, 400, opacity:120);
            sidebar.set_content(label);
        }
        expanded = true;
        icon_view_widget.expanded = true;

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
		if(_show_next == _showing_medias || _show_next == null) {
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
