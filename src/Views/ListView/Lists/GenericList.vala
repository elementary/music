using Gee;
using Gtk;

public abstract class Noise.GenericList : FastView {

    private class TextFieldRenderer : Gtk.CellRendererText {
	    public TextFieldRenderer () {
		    ellipsize = Pango.EllipsizeMode.END;
		    ellipsize_set = true;
	    }
    }

	public signal void import_requested (Gee.LinkedList<Media> to_import);

	//for header column chooser
	protected Gtk.Menu column_chooser_menu;
    private Gtk.MenuItem autosize_menu_item;
#if HAVE_SMART_ALBUM_COLUMN
    private Gtk.CheckMenuItem smart_album_art_menu_item;
#endif

	protected LibraryManager lm;
	protected LibraryWindow lw;
	protected ViewWrapper parent_wrapper;
	
	protected TreeViewSetup tvs;
	protected int relative_id;
	protected bool is_current_list;
	
	protected bool scrolled_recently;
	protected bool dragging;
	
	protected GLib.Icon playing_icon;
	protected GLib.Icon completed_icon;

    private CellDataFunctionHelper cell_data_helper;

	public GenericList (ViewWrapper view_wrapper, GLib.List<Type> types, TreeViewSetup tvs) {
		base (types);
		this.tvs = tvs;
		set_parent_wrapper (view_wrapper);

        cell_data_helper = new CellDataFunctionHelper (this);

		// Set sort data from saved session
		set_sort_column_id (tvs.sort_column_id, tvs.sort_direction);

        enable_search = false; // we don't want the built-in search

		set_headers_clickable(true);
		set_headers_visible (tvs.column_headers_visible);
		set_fixed_height_mode(true);
#if HAVE_SMART_ALBUM_COLUMN
		set_rules_hint (!CellDataFunctionHelper.smart_album_art_enabled);
#else
        set_rules_hint (true);
#endif
		set_reorderable(false);

		playing_icon = Icons.NOW_PLAYING_SYMBOLIC.gicon;
		completed_icon = Icons.PROCESS_COMPLETED.gicon;
		
		// drag source
		TargetEntry te = { "text/uri-list", TargetFlags.SAME_APP, 0};
		drag_source_set(this, Gdk.ModifierType.BUTTON1_MASK, { te }, Gdk.DragAction.COPY);
		//enable_model_drag_source(Gdk.ModifierType.BUTTON1_MASK, {te}, Gdk.DragAction.COPY);
		
		// allow selecting multiple rows
		get_selection().set_mode(SelectionMode.MULTIPLE);

        key_press_event.connect ((event) => {
                if (event.type == Gdk.EventType.KEY_PRESS && event.keyval == Gdk.Key.Delete)
                    mediaRemoveClicked ();

                return false;
        });

		//vadjustment.value_changed.connect(view_scroll);
		drag_begin.connect(on_drag_begin);
		drag_data_get.connect(on_drag_data_get);
		drag_end.connect(on_drag_end);
		row_activated.connect(row_activated_signal);
		rows_reordered.connect(updateTreeViewSetup);
		lm.media_updated.connect (media_updated);

		App.player.current_cleared.connect (current_cleared);
		App.player.media_played.connect (media_played);
	}

    protected abstract void mediaRemoveClicked ();

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

        if (col_name == TreeViewSetup.COLUMN_TITLE)
            return;

		if (column_chooser_menu == null) {
			column_chooser_menu = new Gtk.Menu ();

            autosize_menu_item = new Gtk.MenuItem.with_label (_("Autosize Columns"));
            autosize_menu_item.activate.connect (columns_autosize);

            column_chooser_menu.append (autosize_menu_item);
            column_chooser_menu.append (new Gtk.SeparatorMenuItem ());

#if HAVE_SMART_ALBUM_COLUMN
            smart_album_art_menu_item = new Gtk.CheckMenuItem.with_label (_("Display Album Art"));
            column_chooser_menu.append (smart_album_art_menu_item);
            column_chooser_menu.append (new Gtk.SeparatorMenuItem ());

            smart_album_art_menu_item.active = CellDataFunctionHelper.smart_album_art_enabled;

            smart_album_art_menu_item.toggled.connect ( () => {
                CellDataFunctionHelper.smart_album_art_enabled = smart_album_art_menu_item.active;
         	    set_rules_hint (!CellDataFunctionHelper.smart_album_art_enabled);
                queue_draw ();
            });
#endif

            column_chooser_menu.show_all ();
        }

		var menu_item = new Gtk.CheckMenuItem.with_label (col_name);
		menu_item.active = tvc.visible;

		column_chooser_menu.append (menu_item);
		column_chooser_menu.show_all ();

		// Show/hide the current column
		menu_item.toggled.connect ( () => {
			tvc.visible = menu_item.active;

            columns_autosize ();
		});
	}

	public void set_media (Gee.Collection<Media> to_add, Cancellable? cancellable = null) {
		var new_table = new HashTable<int, Object> (null, null);

		foreach (var m in to_add) {
            if (Utils.is_cancelled (cancellable))
                return;
			new_table.set ((int)new_table.size(), m);
        }

		// set table and resort
        if (!Utils.is_cancelled (cancellable))
    		set_table (new_table, true, cancellable);
	}

	/* If a Media is in to_remove but not in table, will just ignore */
	public void remove_media (Gee.Collection<Media> to_remove, Cancellable? cancellable = null) {
		var to_remove_set = new Gee.HashSet<Media> (null, null);
		foreach (var m in to_remove) {
            if (Utils.is_cancelled (cancellable))
                return;
			to_remove_set.add (m);
        }

		var new_table = new HashTable<int, Object> (null, null);
		for (int i = 0; i < table.size (); ++i) {
            if (Utils.is_cancelled (cancellable))
                return;

			var m = table.get (i) as Media;
			// create a new table. if not in to_remove, and is in table, add it.
			if (m != null && !to_remove_set.contains (m))
				new_table.set ((int)new_table.size(), m);
	    }
		
		// no need to resort, just removing
        if (!Utils.is_cancelled (cancellable)) {
		    set_table(new_table, false, cancellable);
		    get_selection().unselect_all(); // XXX
        }
	}
	
	/** Does NOT check for duplicates */
	public void add_media (Gee.Collection<Media> to_add, Cancellable? cancellable = null) {
		// skip calling set_table and just do it ourselves (faster)
		foreach (var m in to_add) {
            if (Utils.is_cancelled (cancellable))
                return;
			table.set ((int)table.size(), m);
        }

		// resort the new songs in. this will also call do_search
        if (!Utils.is_cancelled (cancellable))
		    resort (cancellable);
	}


	
	public abstract void update_sensitivities();
	
	/** TreeViewColumn header functions. Has to do with sorting and
	 * remembering column widths/sort column/sort direction between
	 * sessions.
	**/
	protected abstract void updateTreeViewSetup();

    private void set_fixed_column_width (Gtk.Widget treeview, Gtk.TreeViewColumn column,
                                        Gtk.CellRendererText renderer, string[] strings, int padding)
    {
        UI.set_tree_view_column_fixed_width (treeview, column, renderer, strings, padding);
    }

    private void reset_column_widths () {
        foreach (var column in get_columns ()) {
            if (column.min_width > 0)
                column.fixed_width = column.min_width;
        }
    }

    public new void columns_autosize () {
        reset_column_widths ();
        base.columns_autosize ();
    }

	protected void add_columns () {
		int index = 0;

		foreach (TreeViewColumn tvc in tvs.get_columns()) {
            bool column_resizable = true;
            int column_width = -1;
            var test_strings = new string[0];

            Gtk.CellRenderer? renderer = null;

			if (tvc.title != TreeViewSetup.COLUMN_BLANK && tvc.title != TreeViewSetup.COLUMN_ID) {
				if (tvc.title == TreeViewSetup.COLUMN_BITRATE) {
					renderer = new TextFieldRenderer ();
					insert_column_with_data_func (index, tvc.title, renderer, cell_data_helper.bitrate_func);
					column_resizable = false;
                    test_strings += _("1234 kbps");
				}
				else if (tvc.title == TreeViewSetup.COLUMN_LENGTH) {
					renderer = new TextFieldRenderer ();
					insert_column_with_data_func (index, tvc.title, renderer, cell_data_helper.length_func);
					column_resizable = false;
                    test_strings += "0000:00";
				}
				else if (tvc.title == TreeViewSetup.COLUMN_DATE_ADDED) {
					renderer = new TextFieldRenderer ();
					insert_column_with_data_func (index, tvc.title, renderer, cell_data_helper.date_func);
                    test_strings += cell_data_helper.get_date_func_sample_string ();
                    test_strings += _("Never");
				}
				else if (tvc.title == TreeViewSetup.COLUMN_LAST_PLAYED) {
				    renderer = new TextFieldRenderer ();
					insert_column_with_data_func (index, tvc.title, renderer, cell_data_helper.date_func);
                    test_strings += cell_data_helper.get_date_func_sample_string ();
                    test_strings += _("Never");
				}
				else if (tvc.title == TreeViewSetup.COLUMN_RATING) {
					var rating_renderer = new Granite.Widgets.CellRendererRating ();
					rating_renderer.rating = 5; // just "init"
					rating_renderer.rating_changed.connect (on_rating_cell_changed);

                    renderer = rating_renderer;
					insert_column_with_data_func (index, tvc.title, rating_renderer, cell_data_helper.rating_func);

					column_resizable = false;
                    column_width = rating_renderer.width + 5;
				}
				else if (tvc.title == TreeViewSetup.COLUMN_YEAR) {
				    renderer = new TextFieldRenderer ();
					insert_column_with_data_func (index, tvc.title, renderer, cell_data_helper.intelligent_func);
					column_resizable = false;
                    test_strings += "0000";
			    }
				else if (tvc.title == TreeViewSetup.COLUMN_NUM) {
				    var text_renderer = new TextFieldRenderer ();
				    text_renderer.style = Pango.Style.ITALIC;
				    renderer = text_renderer;
				    insert_column_with_data_func (index, tvc.title, renderer, cell_data_helper.intelligent_func);
					column_resizable = false;
                    test_strings += "00000";
				}
				else if (tvc.title == TreeViewSetup.COLUMN_TRACK) {
				    renderer = new TextFieldRenderer ();
				    insert_column_with_data_func (index, tvc.title, renderer, cell_data_helper.intelligent_func);
					column_resizable = false;
                    test_strings += "000";
				}
				else if (tvc.title == TreeViewSetup.COLUMN_PLAYS) {
				    renderer = new TextFieldRenderer ();
				    insert_column_with_data_func (index, tvc.title, renderer, cell_data_helper.intelligent_func);
					column_resizable = false;
                    test_strings += "9999";
				}
				else if (tvc.title == TreeViewSetup.COLUMN_SKIPS) {
				    renderer = new TextFieldRenderer ();
				    insert_column_with_data_func (index, tvc.title, renderer, cell_data_helper.intelligent_func);
					column_resizable = false;
                    test_strings += "9999";
				}
				else if (tvc.title == TreeViewSetup.COLUMN_TITLE) {
				    renderer = new TextFieldRenderer ();
				    insert_column_with_data_func (index, tvc.title, renderer, cell_data_helper.string_func);
                    test_strings += _("Sample Title");
				}
				else if (tvc.title == TreeViewSetup.COLUMN_ARTIST) {
				    renderer = new TextFieldRenderer ();
				    insert_column_with_data_func (index, tvc.title, renderer, cell_data_helper.string_func);
                    test_strings += _("Sample Artist");
				}
				else if (tvc.title == TreeViewSetup.COLUMN_ALBUM) {
                    test_strings += _("Sample Album");
#if HAVE_SMART_ALBUM_COLUMN
                    renderer = new SmartAlbumRenderer ();
					insert_column_with_data_func (index, tvc.title, renderer, cell_data_helper.album_art_func);
					// XXX set_row_separator_func (cell_data_helper.row_separator_func);
#else
				    renderer = new TextFieldRenderer ();
					insert_column_with_data_func (index, tvc.title, renderer, cell_data_helper.string_func);
#endif
				}
				else if (tvc.title == TreeViewSetup.COLUMN_GENRE) {
				    renderer = new TextFieldRenderer ();
				    insert_column_with_data_func (index, tvc.title, renderer, cell_data_helper.string_func);
                    test_strings += _("Sample Genre");
				}
				else if (tvc.title == TreeViewSetup.COLUMN_BPM) {
				    renderer = new TextFieldRenderer ();
					insert_column_with_data_func (index, tvc.title, renderer, cell_data_helper.intelligent_func);
					column_resizable = false;
                    test_strings += "9999";
			    }
			    else {
			        insert_column (tvc, index);
			    }

                var inserted_column = get_column (index);

                assert (inserted_column != null);

                if (column_width > 0) {
                    inserted_column.fixed_width = column_width;
                } else if (renderer != null) {
                    var text_renderer = renderer as Gtk.CellRendererText;
                    if (text_renderer != null)
                        set_fixed_column_width (this, inserted_column, text_renderer, test_strings, 5);
                }

				inserted_column.reorderable = false;
				inserted_column.clickable = true;

                inserted_column.visible = tvc.visible;
                inserted_column.resizable = column_resizable;
                inserted_column.expand = column_resizable;
				inserted_column.sizing = Gtk.TreeViewColumnSizing.FIXED;

				inserted_column.sort_column_id = index;
				inserted_column.sort_indicator = true;

                var header_button = inserted_column.get_button ();

                // Make sure the title text is always fully displayed when the headers are visible
                if (headers_visible) {
                    Gtk.Requisition natural_size;
                    header_button.get_preferred_size (null, out natural_size);

                    if (natural_size.width > inserted_column.fixed_width)
                        inserted_column.fixed_width = natural_size.width;

                    // Add extra width for the order indicator arrows
                    if (inserted_column.sort_indicator)
                        inserted_column.fixed_width += 5; // roughly estimated arrow width
                }

                inserted_column.min_width = inserted_column.fixed_width;

				// This is probably the best place to disable the columns we don't want
				// for especific views, like the CD view. FIXME: we need to properly abstract this
				// and keep this class GENERIC rather than SHARED. This should be done in a subclass,
				// like CDRomList
				if (get_hint () == ViewWrapper.Hint.CDROM) {
					if (inserted_column.title != TreeViewSetup.COLUMN_BLANK &&
					    inserted_column.title != TreeViewSetup.COLUMN_NUM &&
					    inserted_column.title != TreeViewSetup.COLUMN_TRACK &&
					    inserted_column.title != TreeViewSetup.COLUMN_TITLE &&
					    inserted_column.title != TreeViewSetup.COLUMN_LENGTH &&
					    inserted_column.title != TreeViewSetup.COLUMN_ALBUM &&
					    inserted_column.title != TreeViewSetup.COLUMN_ARTIST)
					{
						// hide the column and don't add a menuitem
						inserted_column.visible = false;
					}
					else {
						inserted_column.visible = inserted_column.title != TreeViewSetup.COLUMN_NUM;
						// Add menuitem
						add_column_chooser_menu_item (inserted_column);
					}
				}
				else {
					// Add menuitem
					add_column_chooser_menu_item (inserted_column);
				}

                header_button.button_press_event.connect ( (e) => {
                    return view_header_click (e, false);
                });
			}
			else if (tvc.title == TreeViewSetup.COLUMN_BLANK) {
				// Icon column
                insert_column (tvc, index);

				tvc.fixed_width = 24;
				tvc.clickable = true;
				tvc.sort_column_id = -1; //index; 
				tvc.resizable = false;
				tvc.reorderable = false;
				tvc.sort_indicator = false;

				tvc.clear_attributes (tvc.get_cells().nth_data(0));
				tvc.clear_attributes (tvc.get_cells().nth_data(1));

				tvc.set_cell_data_func (tvc.get_cells().nth_data(0), cell_data_helper.icon_func);
				tvc.set_cell_data_func (tvc.get_cells().nth_data(1), cell_data_helper.icon_func);

                tvc.get_button ().button_press_event.connect ( (e) => {
                    return view_header_click (e, true);
                });
			}
			else {
				tvc.fixed_width = 24;
				tvc.clickable = true;
				tvc.sort_column_id = index; 
				tvc.resizable = false;
				tvc.reorderable = false;
				tvc.sort_indicator = false;

			    insert_column (tvc, index);
                tvc.get_button ().button_press_event.connect ( (e) => {
                    return view_header_click (e, false);
                });

			}

            var inserted_column = get_column (index);
            assert (inserted_column != null);

		    inserted_column.notify["width"].connect (viewHeadersResized);

            index++;
		}
	}

	public Media? get_media_from_index (int index) {
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

	protected bool view_header_click (Gdk.EventButton e, bool is_selector_col) {
		if (e.button == Gdk.BUTTON_SECONDARY || is_selector_col) {
			column_chooser_menu.popup (null, null, null, Gdk.BUTTON_SECONDARY, e.time);
			return true;
		}

		if (e.button == Gdk.BUTTON_PRIMARY)
			updateTreeViewSetup();

		return false;
	}
	
	void row_activated_signal(TreePath path, TreeViewColumn column) {
		if (tvs.get_hint() == ViewWrapper.Hint.DEVICE_AUDIO || tvs.get_hint() == ViewWrapper.Hint.DEVICE_PODCAST) {
			lw.doAlert("Playing not Supported", "Due to issues with playing songs on certain iOS devices, playing songs off devices is currently not supported.");
			return;
		}
		
		var m = get_media_from_index(int.parse(path.to_string()));
		
		// We need to first set this as the current list
		App.player.clearCurrent();
		is_current_list = true;
		
		// Now update current_list and current_index in LM
		set_as_current_list(m);
		
		// Now play the song
		App.player.playMedia(m, false);
		
		if (!App.player.playing) {
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
	}
	
	public void media_updated(LinkedList<int> ids) {
        queue_draw ();
	}
	
	void current_cleared() {
		is_current_list = false;
	}
	
	public void set_as_current_list(Media? m = null) {
		Media to_set;
		if (m != null)
			to_set = m;
		else
			to_set = App.player.media_info.media;
		
		App.player.clearCurrent();
		is_current_list = true;
		
		App.player.current_index = 0;
		var vis_table = get_visible_table();
		for(int i = 0; i < vis_table.size(); ++i) {
			var test = vis_table.get(i) as Media;
			App.player.addToCurrent(test);

			
			if (to_set == test) {
				App.player.current_index = i;
			}
		}
		
		media_played(App.player.media_info.media);
	}
	
	protected GLib.List<Media> get_selected_medias() {
		var rv = new GLib.List<Media>();
		TreeModel temp;
		
		foreach (TreePath path in get_selection().get_selected_rows(out temp)) {
			var m = get_media_from_index(int.parse(path.to_string()));
			rv.append(m);
		}
		
		return rv;
	}
	
	protected void mediaScrollToCurrentRequested() {
		scroll_to_current_media(true);
	}
	
	public void scroll_to_current_media(bool unfilter_if_not_found) {
		if (!visible || App.player.media_info.media == null)
			return;
		
		for(int i = 0; i < get_visible_table().size(); ++i) {
			var m = get_media_from_index(i);

			if (m.rowid == App.player.media_info.media.rowid) {
				scroll_to_cell(new TreePath.from_string(i.to_string()), null, false, 0.0f, 0.0f);
				scrolled_recently = false;

				return;
			}
		}
		
		if (unfilter_if_not_found) {
			// At this point, it was not scrolled to. Let's see if it's in ALL the songs
			// and if so, undo the search and filters and scroll to it.
			var whole_table = get_table();
			for(int i = 0; i < whole_table.size(); ++i) {
				var m = whole_table.get(i) as Media;

				if (m.rowid == App.player.media_info.media.rowid) {
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

		if (get_selection().count_selected_rows() == 1) {
			drag_source_set_icon_stock(this, Gtk.Stock.DND);
		}
		else if (get_selection().count_selected_rows() > 1) {
			drag_source_set_icon_stock(this, Gtk.Stock.DND_MULTIPLE);
		}
		else {
			return;
		}
	}
	
	void on_drag_data_get (Gdk.DragContext context, Gtk.SelectionData selection_data, uint info, uint time_) {
		string[] uris = null;

		foreach (Media m in get_selected_medias())
			uris += m.uri;

		if (uris != null)
			selection_data.set_uris (uris);
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

