using Gee;
using Gtk;

internal class TextFieldRenderer : Gtk.CellRendererText {
	public TextFieldRenderer () {
		ellipsize = Pango.EllipsizeMode.END;
		ellipsize_set = true;
	}
}

public abstract class Noise.GenericList : FastView {
	public signal void import_requested (Gee.LinkedList<Media> to_import);

	//for header column chooser
	protected Gtk.Menu column_chooser_menu;

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
	
	public GenericList (ViewWrapper view_wrapper, GLib.List<Type> types, TreeViewSetup tvs) {
		base (types);
		this.tvs = tvs;
		set_parent_wrapper (view_wrapper);

		// Set sort data from saved session
		set_sort_column_id (tvs.sort_column_id, tvs.sort_direction);

		set_headers_clickable(true);
		set_headers_visible (tvs.column_headers_visible);
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

        key_press_event.connect ((event) => {
                if (event.type == Gdk.EventType.KEY_PRESS && event.keyval == Gdk.Key.Delete) {
                    var to_remove = new Gee.LinkedList<Noise.Media> ();
                    foreach (var m in get_selected_medias ())
                        to_remove.add (m);
                    lm.remove_media (to_remove, false);
                    remove_media (to_remove);
                }
                return false;
            });

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
		var col_name = tvc.title;
		if (get_hint () == ViewWrapper.Hint.MUSIC && col_name == TreeViewSetup.COLUMN_NUM)
			return;

		if (column_chooser_menu == null)
			column_chooser_menu = new Gtk.Menu ();

		var menu_item = new Gtk.CheckMenuItem.with_label (col_name);
		menu_item.active = tvc.visible;

		column_chooser_menu.append (menu_item);
		column_chooser_menu.show_all ();

		// Show/hide the current column
		menu_item.toggled.connect ( () => {
			tvc.visible = menu_item.active;
		});
	}

	public void set_media (Gee.Collection<Media> to_add, Cancellable? cancellable = null) {
		var new_table = new HashTable<int, Object> (null, null);
		foreach (var m in to_add) {
			new_table.set ((int)new_table.size(), m as Object);
		}
		// set table and resort
		set_table (new_table, true);
	}

	/* If a Media is in to_remove but not in table, will just ignore */
	public void remove_media (Gee.Collection<Media> to_remove, Cancellable? cancellable = null) {
		var to_remove_table = new HashTable<Media, int> (null, null);
		foreach (var m in to_remove) {
			to_remove_table.set (m, 1);
		}

		var new_table = new HashTable<int, Object> (null, null);
		int index = 0;
		for(int i = 0; i < table.size(); ++i) {
			var m = table.get (i) as Media;
			// create a new table. if not in to_remove, and is in table, add it.
			if (m != null && !to_remove_table.contains (m)) {
				new_table.set (index++, m as Object);
			}
		}
		
		// no need to resort, just removing
		set_table(new_table, false);
		get_selection().unselect_all();
	}
	
	/** Does NOT check for duplicates */
	public void add_media (Gee.Collection<Media> to_add, Cancellable? cancellable = null) {
		// skip calling set_table and just do it ourselves (faster)
		foreach(var m in to_add) {
			table.set((int)table.size(), m as Object);
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
					insert_column_with_data_func(-1, tvc.title, new TextFieldRenderer(), cellHelper.bitrateTreeViewFiller);
				}
				else if (tvc.title == TreeViewSetup.COLUMN_LENGTH)
					insert_column_with_data_func(-1, tvc.title, new TextFieldRenderer(), cellHelper.lengthTreeViewFiller);
				else if(tvc.title == TreeViewSetup.COLUMN_DATE_ADDED)
					insert_column_with_data_func(-1, tvc.title, new TextFieldRenderer(), cellHelper.dateTreeViewFiller);
				else if(tvc.title == TreeViewSetup.COLUMN_LAST_PLAYED)
					insert_column_with_data_func(-1, tvc.title, new TextFieldRenderer(), cellHelper.dateTreeViewFiller);
				else if(tvc.title == TreeViewSetup.COLUMN_RATING) {
					var rating_renderer = new Granite.Widgets.CellRendererRating ();
					rating_renderer.rating_changed.connect (on_rating_cell_changed);
					insert_column_with_data_func(-1, tvc.title, rating_renderer, cellHelper.ratingTreeViewFiller);
				}
				else if(tvc.title == TreeViewSetup.COLUMN_YEAR)
					insert_column_with_data_func(-1, tvc.title, new TextFieldRenderer(), cellHelper.intelligentTreeViewFiller);
				else if(tvc.title == TreeViewSetup.COLUMN_NUM)
					insert_column_with_data_func(-1, tvc.title, new TextFieldRenderer(), cellHelper.intelligentTreeViewFiller);
				else if(tvc.title == TreeViewSetup.COLUMN_TRACK)
					insert_column_with_data_func(-1, tvc.title, new TextFieldRenderer(), cellHelper.intelligentTreeViewFiller);
				else if(tvc.title == TreeViewSetup.COLUMN_PLAYS)
					insert_column_with_data_func(-1, tvc.title, new TextFieldRenderer(), cellHelper.intelligentTreeViewFiller);
				else if(tvc.title == TreeViewSetup.COLUMN_SKIPS)
					insert_column_with_data_func(-1, tvc.title, new TextFieldRenderer(), cellHelper.intelligentTreeViewFiller);
				else if(tvc.title == TreeViewSetup.COLUMN_TITLE)
					insert_column_with_data_func(-1, tvc.title, new TextFieldRenderer(), cellHelper.stringTreeViewFiller);
				else if(tvc.title == TreeViewSetup.COLUMN_ARTIST)
					insert_column_with_data_func(-1, tvc.title, new TextFieldRenderer(), cellHelper.stringTreeViewFiller);
				else if(tvc.title == TreeViewSetup.COLUMN_ALBUM)
#if HAVE_SMART_ALBUM_COLUMN
					insert_column_with_data_func(-1, tvc.title, new SmartAlbumRenderer (), cellHelper.smartAlbumFiller);
#else
					insert_column_with_data_func(-1, tvc.title, new TextFieldRenderer(), cellHelper.stringTreeViewFiller);
#endif
				else if(tvc.title == TreeViewSetup.COLUMN_GENRE)
					insert_column_with_data_func(-1, tvc.title, new TextFieldRenderer(), cellHelper.stringTreeViewFiller);
				else if(tvc.title == TreeViewSetup.COLUMN_BPM)
					insert_column_with_data_func(-1, tvc.title, new TextFieldRenderer(), cellHelper.intelligentTreeViewFiller);
				else
					insert_column(tvc, index);

				var inserted_column = get_column(index);

				inserted_column.resizable = tvc.resizable;

				inserted_column.reorderable = false;
				inserted_column.clickable = true;

				inserted_column.sort_column_id = index;
				inserted_column.set_sort_indicator (false);
				inserted_column.visible = tvc.visible;
				inserted_column.sizing = Gtk.TreeViewColumnSizing.FIXED;
				inserted_column.fixed_width = tvc.fixed_width;

				// This is probably the best place to disable the columns we don't want
				// for especific views, like the CD view.
				if (get_hint () == ViewWrapper.Hint.CDROM) {
					if (tvc.title != TreeViewSetup.COLUMN_BLANK &&
					    tvc.title != TreeViewSetup.COLUMN_NUM &&
					    tvc.title != TreeViewSetup.COLUMN_TRACK &&
					    tvc.title != TreeViewSetup.COLUMN_TITLE &&
					    tvc.title != TreeViewSetup.COLUMN_LENGTH &&
					    tvc.title != TreeViewSetup.COLUMN_ALBUM &&
					    tvc.title != TreeViewSetup.COLUMN_ARTIST)
					{
						// hide the column and don't add a menuitem
						inserted_column.visible = false;
					}
					else {
						inserted_column.visible = tvc.title != TreeViewSetup.COLUMN_NUM;
						// Add menuitem
						add_column_chooser_menu_item (inserted_column);
					}
				}
				else {
					// Add menuitem
					add_column_chooser_menu_item (inserted_column);
				}
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

			var inserted_column = get_column(index);

			inserted_column.get_button().button_press_event.connect(view_header_click);
			inserted_column.notify["width"].connect(viewHeadersResized);

			++index;
		}
	}

	private Media? get_media_from_index (int index) {
		return get_object_from_index (index) as Media;
	}

	// When the user clicks over a cell in the rating column, that cell renderer
	// emits the rating_changed signal. We need to update that rating...
	private void on_rating_cell_changed (int new_rating, Gtk.Widget widget, string path) {
		var m = get_media_from_index (int.parse (path));

		return_if_fail (m != null);

		m.rating = new_rating;

		var to_update = new Gee.LinkedList<Media> ();
		to_update.add (m);
		lm.update_media (to_update, true, true);
	}

	void viewHeadersResized() {
		updateTreeViewSetup();
	}

	protected bool view_header_click(Gtk.Widget w, Gdk.EventButton e) {
		if(e.button == 3) {
			column_chooser_menu.popup (null, null, null, 3, get_current_event_time());
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
		
		var m = get_media_from_index(int.parse(path.to_string()));
		
		// We need to first set this as the current list
		lm.clearCurrent();
		is_current_list = true;
		
		// Now update current_list and current_index in LM
		set_as_current_list(m);
		
		// Now play the song
		lm.playMedia(m, false);
		
		if(!App.player.playing) {
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

		queue_draw ();		
#if 0
		if(id_index != -1)
			redraw_row(id_index);
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
			var m = get_visible_table ().get (i) as Media;
			int rowid = m.rowid;
			if (map.get (rowid) == 1) {
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
			to_set = App.player.media_info.media;
		
		lm.clearCurrent();
		is_current_list = true;
		
		lm.current_index = 0;
		var vis_table = get_visible_table();
		for(int i = 0; i < vis_table.size(); ++i) {
			var test = vis_table.get(i) as Media;
			lm.addToCurrent(test);

			
			if(to_set == test) {
				lm.current_index = i;
			}
		}
		
		media_played(App.player.media_info.media);
	}
	
	protected GLib.List<Media> get_selected_medias() {
		var rv = new GLib.List<Media>();
		TreeModel temp;
		
		foreach(TreePath path in get_selection().get_selected_rows(out temp)) {
			var m = get_media_from_index(int.parse(path.to_string()));
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
		if(!visible || App.player.media_info.media == null)
			return;
		
		for(int i = 0; i < get_visible_table().size(); ++i) {
			var m = get_media_from_index(i);

			if(m.rowid == App.player.media_info.media.rowid) {
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
				var m = whole_table.get(i) as Media;

				if(m.rowid == App.player.media_info.media.rowid) {
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
}

