using Gee;
using Gtk;

public abstract class BeatBox.GenericList : FastView {
	//for header column chooser
	Gee.HashMap<string, Gtk.CheckMenuItem> column_chooser_menu_items;
	Gtk.Menu column_chooser_menu;


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
	
	// To select which columns are showing
	protected Gtk.Menu columnChooserMenu;
	
	public signal void import_requested(LinkedList<Media> to_import);
	
	public GenericList(ViewWrapper view_wrapper,  GLib.List<Type> types, TreeViewSetup tvs) {
		base(types);

		set_parent_wrapper (view_wrapper);
		
		set_headers_clickable(true);
		set_headers_visible(true);
		set_fixed_height_mode(true);
		set_rules_hint(true);
		set_reorderable(false);
		
		cellHelper = new CellDataFunctionHelper(lm, this);
		playing_icon = Icons.NOW_PLAYING_SYMBOLIC.get_gicon ();
		completed_icon = Icons.PROCESS_COMPLETED.get_gicon ();
		
		// drag source
		TargetEntry te = { "text/uri-list", TargetFlags.SAME_APP, 0};
		drag_source_set(this, Gdk.ModifierType.BUTTON1_MASK, { te }, Gdk.DragAction.COPY);
		//enable_model_drag_source(Gdk.ModifierType.BUTTON1_MASK, {te}, Gdk.DragAction.COPY);
		
		// allow selecting multiple rows
		get_selection().set_mode(SelectionMode.MULTIPLE);
		
		columnChooserMenu = new Gtk.Menu();
		
		set_headers_visible (tvs.column_headers_visible);
		
		//vadjustment.value_changed.connect(view_scroll);
		drag_begin.connect(on_drag_begin);
		drag_data_get.connect(on_drag_data_get);
		drag_end.connect(on_drag_end);
		row_activated.connect(row_activated_signal);
		rows_reordered.connect(updateTreeViewSetup);
		lm.current_cleared.connect(current_cleared);
		lm.media_played.connect (media_played);
		lm.media_updated.connect (media_updated);
	}

	public void set_parent_wrapper(ViewWrapper parent) {
		this.parent_wrapper = parent;
		this.lm = parent_wrapper.lm;
		this.lw = parent_wrapper.lw;
		this.relative_id = parent_wrapper.relative_id;
	}

	private void add_column_chooser_menu_item (TreeViewColumn tvc) {
		var column_id = tvc.title;

		if (column_chooser_menu == null)
			column_chooser_menu = new Gtk.Menu ();
		if (column_chooser_menu_items == null)
			column_chooser_menu_items = new Gee.HashMap<string, Gtk.CheckMenuItem> ();

		var menu_item = new Gtk.CheckMenuItem.with_label (column_id);
		menu_item.active = tvc.visible;

		column_chooser_menu.append (menu_item);
		column_chooser_menu_items.set (column_id, menu_item);

		column_chooser_menu.show_all ();

		menu_item.toggled.connect (column_menu_item_toggled);
	}


	public void set_media (Gee.Collection<Media> to_add) {
		var new_table = new HashTable<int, Media> (null, null);
		foreach (var m in to_add) {
			new_table.set ((int)new_table.size(), m);
		}
		// set table and resort
		set_table (new_table, true);
	}

	/* If a Media is in to_remove but not in table, will just ignore */
	public void remove_media (Gee.Collection<Media> to_remove) {
		var to_remove_table = new HashTable<Media, int> (null, null);
		foreach (var m in to_remove) {
			to_remove_table.set (m, 1);
		}

		var new_table = new HashTable<int, Media> (null, null);
		int index = 0;
		for(int i = 0; i < table.size(); ++i) {
			Media? m = null;
			// create a new table. if not in objects, and is in table, add it.
			if ((m = table.get (i)) != null && to_remove_table.contains (m)) {
				new_table.set(index++, m);
			}
		}
		
		// no need to resort, just removing
		set_table(new_table, false);
		get_selection().unselect_all();
	}
	
	/** Does NOT check for duplicates */
	public void add_media (Gee.Collection<Media> to_add) {
		// skip calling set_table and just do it ourselves (faster)
		foreach(var m in to_add) {
			table.set((int)table.size(), m);
		}

		// resort the new songs in. this will also call do_search
		resort ();
	}


	
	public abstract void update_sensitivities();
	
	/** TreeViewColumn header functions. Has to do with sorting and
	 * remembering column widths/sort column/sort direction between
	 * sessions.
	**/
	protected abstract void updateTreeViewSetup();
	
	protected void add_columns() {
		int index = 0;
		
		foreach(TreeViewColumn tvc in tvs.get_columns()) {
			if(!(tvc.title == TreeViewSetup.COLUMN_BLANK || tvc.title == TreeViewSetup.COLUMN_ID)) {
				if (tvc.title == TreeViewSetup.COLUMN_BITRATE) {
					insert_column_with_data_func(-1, tvc.title, new CellRendererText(), cellHelper.bitrateTreeViewFiller);
				}
				else if (tvc.title == TreeViewSetup.COLUMN_LENGTH)
					insert_column_with_data_func(-1, tvc.title, new CellRendererText(), cellHelper.lengthTreeViewFiller);
				else if(tvc.title == TreeViewSetup.COLUMN_DATE_ADDED)
					insert_column_with_data_func(-1, tvc.title, new CellRendererText(), cellHelper.dateTreeViewFiller);
				else if(tvc.title == TreeViewSetup.COLUMN_LAST_PLAYED)
					insert_column_with_data_func(-1, tvc.title, new CellRendererText(), cellHelper.dateTreeViewFiller);
				else if(tvc.title == TreeViewSetup.COLUMN_RATING)
					insert_column_with_data_func(-1, tvc.title, new Granite.Widgets.CellRendererRating (), cellHelper.ratingTreeViewFiller);
				else if(tvc.title == TreeViewSetup.COLUMN_YEAR)
					insert_column_with_data_func(-1, tvc.title, new CellRendererText(), cellHelper.intelligentTreeViewFiller);
				else if(tvc.title == TreeViewSetup.COLUMN_NUM)
					insert_column_with_data_func(-1, tvc.title, new CellRendererText(), cellHelper.intelligentTreeViewFiller);
				else if(tvc.title == TreeViewSetup.COLUMN_TRACK)
					insert_column_with_data_func(-1, tvc.title, new CellRendererText(), cellHelper.intelligentTreeViewFiller);
				else if(tvc.title == TreeViewSetup.COLUMN_PLAYS)
					insert_column_with_data_func(-1, tvc.title, new CellRendererText(), cellHelper.intelligentTreeViewFiller);
				else if(tvc.title == TreeViewSetup.COLUMN_SKIPS)
					insert_column_with_data_func(-1, tvc.title, new CellRendererText(), cellHelper.intelligentTreeViewFiller);
				else if(tvc.title == TreeViewSetup.COLUMN_TITLE)
					insert_column_with_data_func(-1, tvc.title, new CellRendererText(), cellHelper.stringTreeViewFiller);
				else if(tvc.title == TreeViewSetup.COLUMN_ARTIST)
					insert_column_with_data_func(-1, tvc.title, new CellRendererText(), cellHelper.stringTreeViewFiller);
				else if(tvc.title == TreeViewSetup.COLUMN_ALBUM)
#if HAVE_SMART_ALBUM_COLUMN
					insert_column_with_data_func(-1, tvc.title, new SmartAlbumRenderer (), cellHelper.smartAlbumFiller);
#else
					insert_column_with_data_func(-1, tvc.title, new CellRendererText(), cellHelper.stringTreeViewFiller);
#endif
				else if(tvc.title == TreeViewSetup.COLUMN_GENRE)
					insert_column_with_data_func(-1, tvc.title, new CellRendererText(), cellHelper.stringTreeViewFiller);
				else if(tvc.title == TreeViewSetup.COLUMN_BPM)
					insert_column_with_data_func(-1, tvc.title, new CellRendererText(), cellHelper.intelligentTreeViewFiller);
				else
					insert_column(tvc, index);

				// FIXME! this can be tvc!

				get_column(index).resizable = true;
				get_column(index).reorderable = false;
				get_column(index).clickable = true;
				get_column(index).sort_column_id = index;
				get_column(index).set_sort_indicator(false);
				get_column(index).visible = tvc.visible;
				get_column(index).sizing = Gtk.TreeViewColumnSizing.FIXED;
				get_column(index).fixed_width = tvc.fixed_width;

				// Add menuitem
				add_column_chooser_menu_item (tvc);
			}
			else if(tvc.title == TreeViewSetup.COLUMN_BLANK) {
				// Icon column
				
				insert_column(tvc, index);

				tvc.fixed_width = 24;
				tvc.clickable = false;
				tvc.sort_column_id = -1;
				tvc.resizable = false;
				tvc.reorderable = false;

				tvc.clear_attributes (tvc.get_cells().nth_data(0));
				tvc.clear_attributes (tvc.get_cells().nth_data(1));

				tvc.set_cell_data_func(tvc.get_cells().nth_data(0), cellHelper.iconDataFunc);
				tvc.set_cell_data_func(tvc.get_cells().nth_data(1), cellHelper.iconDataFunc);
			}
			else if(tvc.title == TreeViewSetup.COLUMN_ID) {
				insert_column(tvc, index);
			}
			else {
				warning ("Adding UNKNOWN column!");
				insert_column(tvc, index);
			}

			// FIXME! this can be tvc!
			get_column(index).get_button().button_press_event.connect(view_header_click);
			get_column(index).notify["width"].connect(viewHeadersResized);

			++index;
		}
	}


	void viewHeadersResized() {
		updateTreeViewSetup();
	}


	private void update_column_header_items () {
		int index = 0;
		foreach(TreeViewColumn tvc in get_columns()) {
#if 0
			if(tvc.title == TreeViewSetup.COLUMN_NUM)
				columnNumber.active = get_column(index).visible;
			else if(tvc.title == TreeViewSetup.COLUMN_TRACK)
				columnTrack.active = get_column(index).visible;
			else if(tvc.title == TreeViewSetup.COLUMN_TITLE)
				columnTitle.active = get_column(index).visible;
			else if(tvc.title == TreeViewSetup.COLUMN_LENGTH)
				columnLength.active = get_column(index).visible;
			else if(tvc.title == TreeViewSetup.COLUMN_ARTIST)
				columnArtist.active = get_column(index).visible;
			else if(tvc.title == TreeViewSetup.COLUMN_ALBUM)
				columnAlbum.active = get_column(index).visible;
			else if(tvc.title == TreeViewSetup.COLUMN_GENRE)
				columnGenre.active = get_column(index).visible;
			else if(tvc.title == TreeViewSetup.COLUMN_YEAR)
				columnYear.active = get_column(index).visible;
			else if(tvc.title == TreeViewSetup.COLUMN_BITRATE)
				columnBitRate.active = get_column(index).visible;
			else if(tvc.title == TreeViewSetup.COLUMN_RATING)
				columnRating.active = get_column(index).visible;
			else if(tvc.title == TreeViewSetup.COLUMN_PLAYS)
				columnPlayCount.active = get_column(index).visible;
			else if(tvc.title == TreeViewSetup.COLUMN_SKIPS)
				columnSkipCount.active = get_column(index).visible;
			else if(tvc.title == TreeViewSetup.COLUMN_DATE_ADDED)
				columnDateAdded.active = get_column(index).visible;
			else if(tvc.title == TreeViewSetup.COLUMN_LAST_PLAYED)
				columnLastPlayed.active = get_column(index).visible;
			else if(tvc.title == TreeViewSetup.COLUMN_BPM)
				columnBPM.active = get_column(index).visible;
#endif

			// this is equivalent
			var column_item = column_chooser_menu_items.get (tvc.title);
			if (column_item != null)
				// FIXME! this can be tvc!
				column_item.active = get_column (index).visible;
			else
				debug ("column item '%s' is null", tvc.title);

			++index;
		}
	}

	/** When the column chooser popup menu has a change/toggle
	 * FIXME: This relies extremely in the order of the 'else if' control lines.
	 *         Fetch columns by col_id<string>
	 **/
	public virtual void column_menu_item_toggled () {
		int index = 0;
		
		foreach(TreeViewColumn tvc in get_columns()) {
#if 0
			if(tvc.title == TreeViewSetup.COLUMN_TRACK)
				get_column(index).visible = column_chooser_menu_items.get (TreeViewSetup.COLUMN_TRACK).active;
			else if(tvc.title == TreeViewSetup.COLUMN_NUM)
				get_column(index).visible = column_chooser_menu_items.get (TreeViewSetup.COLUMN_NUM).active;
			else if(tvc.title == TreeViewSetup.COLUMN_TITLE)
				get_column(index).visible = column_chooser_menu_items.get (TreeViewSetup.COLUMN_TITLE).active;
			else if(tvc.title == TreeViewSetup.COLUMN_LENGTH)
				get_column(index).visible = column_chooser_menu_items.get (TreeViewSetup.COLUMN_LENGTH).active;
			else if(tvc.title == TreeViewSetup.COLUMN_ARTIST)
				get_column(index).visible = column_chooser_menu_items.get (TreeViewSetup.COLUMN_ARTIST).active;
			else if(tvc.title == TreeViewSetup.COLUMN_ALBUM)
				get_column(index).visible = column_chooser_menu_items.get (TreeViewSetup.COLUMN_ALBUM).active;
			else if(tvc.title == TreeViewSetup.COLUMN_GENRE)
				get_column(index).visible = column_chooser_menu_items.get (TreeViewSetup.COLUMN_GENRE).active;
			else if(tvc.title == TreeViewSetup.COLUMN_YEAR)
				get_column(index).visible = column_chooser_menu_items.get (TreeViewSetup.COLUMN_YEAR).active;
			else if(tvc.title == TreeViewSetup.COLUMN_BITRATE)
				get_column(index).visible = column_chooser_menu_items.get (TreeViewSetup.COLUMN_BITRATE).active;
			else if(tvc.title == TreeViewSetup.COLUMN_RATING)
				get_column(index).visible = column_chooser_menu_items.get (TreeViewSetup.COLUMN_RATING).active;
			else if(tvc.title == TreeViewSetup.COLUMN_PLAYS)
				get_column(index).visible = column_chooser_menu_items.get (TreeViewSetup.COLUMN_PLAYS).active;
			else if(tvc.title == TreeViewSetup.COLUMN_SKIPS)
				get_column(index).visible = column_chooser_menu_items.get (TreeViewSetup.COLUMN_SKIPS).active;
			else if(tvc.title == TreeViewSetup.COLUMN_DATE_ADDED)
				get_column(index).visible = column_chooser_menu_items.get (TreeViewSetup.COLUMN_DATE_ADDED).active;
			else if(tvc.title == TreeViewSetup.COLUMN_LAST_PLAYED)
				get_column(index).visible = column_chooser_menu_items.get (TreeViewSetup.COLUMN_LAST_PLAYED).active;//add bpm, file size, file path
			else if(tvc.title == TreeViewSetup.COLUMN_BPM)
				get_column(index).visible = column_chooser_menu_items.get (TreeViewSetup.COLUMN_BPM).active;
#endif

			// this is equivalent
			var column_item = column_chooser_menu_items.get (tvc.title);
			if (column_item != null)
				// FIXME! this can be tvc!
				get_column (index).visible = column_item.active;

			++index;
		}

		tvs.set_columns(get_columns());
	}

	protected bool view_header_click(Gtk.Widget w, Gdk.EventButton e) {
		if(e.button == 3) {
			columnChooserMenu.popup (null, null, null, 3, get_current_event_time());
			return true;
		}
		else if(e.button == 1) {
			updateTreeViewSetup();
			
			return false;
		}

		return false;
	}
	
	void row_activated_signal(TreePath path, TreeViewColumn column) {
		if(tvs.get_hint() == ViewWrapper.Hint.DEVICE_AUDIO || tvs.get_hint() == ViewWrapper.Hint.DEVICE_PODCAST) {
			lw.doAlert("Playing not Supported", "Due to issues with playing songs on certain iOS devices, playing songs off devices is currently not supported.");
			return;
		}
		
		Media m = get_media_from_index(int.parse(path.to_string()));
		
		// We need to first set this as the current list
		lm.clearCurrent();
		is_current_list = true;
		
		// Now update current_list and current_index in LM
		set_as_current_list(m);
		
		// Now play the song
		lm.playMedia(m, false);
		
		if(!lm.playing) {
			lw.playClicked();
		}
	}

	// FIXME: find a way to re-draw old media cells
	void media_played(Media m) {
		// find index of given media
		int id_index = -1;
		for(int i = 0; i < get_visible_table().size(); ++i) {
			if (get_visible_table().get(i) == m) {
				id_index = i;
			}
		}
		
		if(id_index != -1)
			redraw_row(id_index);
#if 0
		if(!scrolled_recently) {
			//scroll_to_current_media();
		}
#endif
	}
	
	public void media_updated(LinkedList<int> ids) {
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
	
	public void set_as_current_list(Media? m = null) {
		Media to_set;
		if(m != null)
			to_set = m;
		else
			to_set = lm.media_info.media;
		
		lm.clearCurrent();
		is_current_list = true;
		
		lm.current_index = 0;
		var vis_table = get_visible_table();
		for(int i = 0; i < vis_table.size(); ++i) {
			Media test = vis_table.get(i);
			lm.addToCurrent(test);

			
			if(to_set == test) {
				lm.current_index = i;
			}
		}
		
		media_played(lm.media_info.media);
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
	
	/*void view_scroll() {
		if(!scrolled_recently) {
			Timeout.add(30000, () => {
				scrolled_recently = false;

				return false;
			});

			scrolled_recently = true;
		}
	}*/
	
	protected void mediaScrollToCurrentRequested() {
		scroll_to_current_media(true);
	}
	
	public void scroll_to_current_media(bool unfilter_if_not_found) {
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
		
		if(unfilter_if_not_found) {
			// At this point, it was not scrolled to. Let's see if it's in ALL the songs
			// and if so, undo the search and filters and scroll to it.
			var whole_table = get_table();
			for(int i = 0; i < whole_table.size(); ++i) {
				Media m = whole_table.get(i);

				if(m.rowid == lm.media_info.media.rowid) {
					// Undo search and filter
					parent_wrapper.clear_filters();
					
					// And now scroll to it.
					scroll_to_cell(new TreePath.from_string(i.to_string()), null, false, 0.0f, 0.0f);
					scrolled_recently = false;

					return;
				}
			}
		}
		
		scrolled_recently = false;
	}
	
	/***************************************
	 * Simple setters and getters
	 * *************************************/
	public void set_hint(ViewWrapper.Hint hint) {
		tvs.set_hint(hint);
	}
	
	public ViewWrapper.Hint get_hint() {
		return tvs.get_hint();
	}
	
	public void set_relative_id (int id) {
		this.relative_id = id;
	}
	
	public int get_relative_id() {
		return relative_id;
	}
	
	public bool get_is_current_list() {
		return is_current_list;
	}
	
	/** **********************************************************
	 * Drag and drop support. GenericView is a source for uris and can
	 * be dragged to a playlist in the sidebar. No support for reordering
	 * is implemented yet.
	***************************************************************/
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
	
	/************************************************
	 * Used by all views to sort list
	 * ******************************************/
	protected int advanced_string_compare(string a, string b) {
		if(a == "" && b != "")
			return 1;
		else if(a != "" && b == "")
			return -1;
		
		return (a > b) ? 1 : -1;
	}
}

