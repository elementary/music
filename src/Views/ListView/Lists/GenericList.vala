using Gee;
using Gtk;

public abstract class BeatBox.GenericList : FastView {
	protected LibraryManager lm;
	protected LibraryWindow lw;
	protected ViewWrapper parent_wrapper;

	protected TreeViewSetup tvs;
	protected int relative_id;
	protected bool is_current_list;
	
	protected bool scrolled_recently;
	protected bool dragging;
	
	protected CellDataFunctionHelper cellHelper;
	
	protected GLib.Icon playing_icon;
	protected GLib.Icon completed_icon;
	protected GLib.Icon saved_locally_icon;
	protected GLib.Icon new_podcast_icon;
	
	public signal void import_requested(LinkedList<int> to_import);

	public bool has_grid_lines {
		get {
			return enable_grid_lines == TreeViewGridLines.HORIZONTAL;
		}
		set {
			set_grid_lines (value? TreeViewGridLines.HORIZONTAL : TreeViewGridLines.NONE);
		}
	}
	
	public GenericList(ViewWrapper view_wrapper, GLib.List<Type> types, TreeViewSetup tvs) {
		base(types);
		
		this.parent_wrapper = view_wrapper;
		this.lm = view_wrapper.lm;
		this.lw = view_wrapper.lw;
		this.tvs = tvs;
		this.relative_id = view_wrapper.relative_id;
		
		set_headers_clickable(true);
		set_headers_visible(tvs.column_headers_visible);
		set_fixed_height_mode(true);
		set_rules_hint(true);
		set_reorderable(false);
		
		cellHelper = new CellDataFunctionHelper((BeatBox.LibraryManager)lm, this);
		playing_icon = Icons.NOW_PLAYING_SYMBOLIC.get_gicon ();
		completed_icon = Icons.PROCESS_COMPLETED.get_gicon ();
		saved_locally_icon = new GLib.ThemedIcon.with_default_fallbacks (Gtk.Stock.SAVE);
		new_podcast_icon = Icons.NEW_PODCAST.get_gicon ();
		
		// drag source
		drag_source_set(this, Gdk.ModifierType.BUTTON1_MASK, {}, Gdk.DragAction.MOVE);
		Gtk.drag_source_add_uri_targets(this);
		
		// allow selecting multiple rows
		get_selection().set_mode(SelectionMode.MULTIPLE);
		
		//rating_item.activate.connect(mediaRateMediaClicked);
		//vadjustment.value_changed.connect(view_scroll);
		drag_begin.connect(on_drag_begin);
		drag_data_get.connect(on_drag_data_get);
		drag_end.connect(on_drag_end);
		row_activated.connect(row_activated_signal);
		lm.current_cleared.connect(current_cleared);
		lm.media_played.connect(media_played);
		lm.medias_updated.connect(medias_updated);
	}
	
	public void set_parent_wrapper(ViewWrapper parent) {
		this.parent_wrapper = parent;
	}
	
	public abstract void update_sensitivities();
	
	void row_activated_signal(TreePath path, TreeViewColumn column) {
		int id = get_media_from_index(int.parse(path.to_string())).rowid;
		set_as_current_list(id, true);
		
		lm.playMedia(id, false);
		if(!lm.playing) {
			lw.playClicked();
		}
	}
	
	void media_played(int id, int old) {
		// find index of given media
		int old_index = -1;
		int id_index = -1;
		for(int i = 0; i < get_visible_table().size(); ++i) {
			if(get_visible_table().get(i).rowid == old) {
				old_index = i;
				if(id_index != -1) break;
			}
			else if(get_visible_table().get(i).rowid == id) {
				id_index = i;
				if(old_index != -1) break;
			}
		}
		
		if(old_index != -1)		redraw_row(old_index);
		if(id_index != -1)		redraw_row(id_index);

		if(!scrolled_recently) {
			//scroll_to_current_media();
		}
	}
	
	public void medias_updated(LinkedList<int> ids) {
		var map = new HashMap<int, int>();
		foreach(var i in ids)
			map.set(i, 1);
		
		for(int i = 0; i < get_visible_table().size(); ++i) {
			if(map.get(get_visible_table().get(i).rowid) == 1) {
				redraw_row (i);
			}
		}
	}
	
	void current_cleared() {
		is_current_list = false;
	}
	
	public void set_as_current_list(int media_id, bool is_initial = false) {
		lm.clearCurrent();
		is_current_list = true;
		
		lm.current_index = 0;
		var table = get_visible_table();
		for(int i = 0; i < table.size(); ++i) {
			int id = table.get(i).rowid;
			lm.addToCurrent(id);

			if(lm.media_info.media != null && lm.media_info.media.rowid == id && media_id == 0)
				lm.current_index = i;
			else if(lm.media_info.media != null && media_id == id)
				lm.current_index = i;
		}
		
		media_played(lm.media_info.media.rowid, -1);
	}

	public GLib.List<Media> get_media () {
		return get_table().get_values();
	}

	public GLib.List<Media> get_showing_media () {
		return get_visible_table ().get_values ();
	}
	
	protected GLib.List<Media> get_selected_medias() {
		var rv = new GLib.List<Media>();
		TreeModel temp;
		
		foreach(TreePath path in get_selection().get_selected_rows(out temp)) {
			Media m = get_media_from_index(int.parse(path.to_string()));
			rv.append(m);
		}
		
		return rv;
	}
	
	void view_scroll() {
		if(!scrolled_recently) {
			Timeout.add(30000, () => {
				scrolled_recently = false;

				return false;
			});

			scrolled_recently = true;
		}
	}
	
	public void scroll_to_current_media() {
		if(!visible || lm.media_info.media == null)
			return;
		
		for(int i = 0; i < get_visible_table().size(); ++i) {
			Media m = get_media_from_index(i);

			if(m.rowid == lm.media_info.media.rowid) {
				scroll_to_cell(new TreePath.from_string(i.to_string()), null, false, 0.0f, 0.0f);
				scrolled_recently = false;

				return;
			}
		}

		scrolled_recently = false;
	}
	
	public void iconDataFunc(CellLayout layout, CellRenderer renderer, TreeModel model, TreeIter iter) {
		Value id;
		bool showIndicator = false;
		model.get_value(iter, 0, out id);

		Media s = lm.media_from_id(id.get_int());
		if(s == null)
			return;
		else
			showIndicator = s.showIndicator;

		if(renderer is CellRendererPixbuf) {
			Value? icon;
			model.get_value (iter, 1, out icon);

			/* Themed icon */
			(renderer as CellRendererPixbuf).follow_state = true;
			(renderer as CellRendererPixbuf).gicon = icon as GLib.Icon;

			renderer.visible = !showIndicator;
			renderer.width = showIndicator ? 0 : 16;
		}
		if(renderer is CellRendererSpinner) {
			if(showIndicator) {
				((CellRendererSpinner)renderer).active = true;
			}
			renderer.visible = showIndicator;
			renderer.width = showIndicator ? 16 : 0;
		}
	}

	public void set_hint(ViewWrapper.Hint hint) {
		tvs.set_hint(hint);
	}


	public ViewWrapper.Hint get_hint() {
		return tvs.get_hint ();
	}

	public void set_relative_id(int id) {
		this.relative_id = id;
	}


	public int get_relative_id() {
		return relative_id;
	}

	public bool get_is_current_list() {
		return is_current_list;
	}
	
	void on_drag_begin(Gtk.Widget sender, Gdk.DragContext context) {
		dragging = true;
		lw.dragging_from_music = true;
		debug("drag begin\n");

		Gdk.drag_abort(context, Gtk.get_current_event_time());

		if(get_selection().count_selected_rows() == 1) {
			drag_source_set_icon_stock(this, Gtk.Stock.DND);
		}
		else if(get_selection().count_selected_rows() > 1) {
			drag_source_set_icon_stock(this, Gtk.Stock.DND_MULTIPLE);
		}
		else {
			return;
		}
	}
	
	void on_drag_data_get(Gdk.DragContext context, Gtk.SelectionData selection_data, uint info, uint time_) {
		string[] uris = null;

		foreach(Media m in get_selected_medias()) {
			uris += (m.uri);
		}

		if (uris != null)
			selection_data.set_uris(uris);
	}
	
	void on_drag_end(Gtk.Widget sender, Gdk.DragContext context) {
		dragging = false;
		lw.dragging_from_music = false;

		debug("drag end\n");

		//unset_rows_drag_dest();
		Gtk.drag_dest_set(this,
						  Gtk.DestDefaults.ALL,
						  {},
						  Gdk.DragAction.COPY|
						  Gdk.DragAction.MOVE
						  );
	}
	
	//public abstract void set_statusbar_info();
	//public abstract void update_medias(Collection<int> medias); // request to update displayed information
	
	protected int advanced_string_compare(string a, string b) {
		if(a == "" && b != "")
			return 1;
		else if(a != "" && b == "")
			return -1;
		
		return (a > b) ? 1 : -1;
	}

#if HAVE_BUILTIN_SEARCH

	protected void view_search_func (string search, HashTable<int, Media> table, ref HashTable<int, Media> show) {
		int show_index = 0;
		
		for(int i = 0; i < table.size(); ++i) {
			Media m = table.get(i);
			
			if(search in m.artist.down() || search in m.album_artist.down() ||
			search in m.album.down() || search in m.title.down() ||
			search in m.genre.down()) {
				if((m.album_artist.down() == parent_wrapper.artist_filter.down() || parent_wrapper.artist_filter == "") &&
				(m.album.down() == parent_wrapper.album_filter.down() || parent_wrapper.album_filter == "") &&
				(m.genre.down() == parent_wrapper.genre_filter.down() || parent_wrapper.genre_filter == "")) {
					show.set(show_index++, table.get(i));
				}
			}
		}
	}
#endif
}
