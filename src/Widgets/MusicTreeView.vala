using Gee;
using Gtk;

public class BeatBox.MusicTreeView : ScrolledWindow {
	private BeatBox.LibraryManager lm;
	private BeatBox.LibraryWindow lw;
	private TreeView view;
	private ListStore model;
	private TreeModelFilter filter;
	private TreeModelSort sort; //one to use.
	
	private LinkedList<int> _songs;
	private HashMap<int, TreeRowReference> _rows;
	private LinkedList<string> _columns;
	
	//private string current_path; // based on sort, always up to date.
	public int relative_id;// if playlist, playlist id, etc.
	public Hint hint; // playlist, queue, smart_playlist, etc. changes how it behaves.
	string sort_column;
	SortType sort_direction;
	public bool removing_songs;
	
	public bool is_current_view;
	public bool is_current;
	public bool dragging;
	
	LinkedList<string> timeout_search;//stops from doing useless search
	string last_search;//stops from searching same thing multiple times
	bool scrolled_recently;
	
	//for header column chooser
	Menu columnChooserMenu;
	MenuItem columnSmartSorting;
	CheckMenuItem columnNumber;
	CheckMenuItem columnTrack;
	CheckMenuItem columnTitle;
	CheckMenuItem columnLength;
	CheckMenuItem columnArtist;
	CheckMenuItem columnAlbum;
	CheckMenuItem columnGenre;
	CheckMenuItem columnYear;
	CheckMenuItem columnBitRate;
	CheckMenuItem columnRating;
	CheckMenuItem columnPlayCount;
	CheckMenuItem columnSkipCount;
	CheckMenuItem columnDateAdded;
	CheckMenuItem columnLastPlayed;
	CheckMenuItem columnBPM;
	//for song list right click
	Menu songMenuActionMenu;
	MenuItem songEditSong;
	MenuItem songFileBrowse;
	MenuItem songMenuQueue;
	MenuItem songMenuNewPlaylist;
	MenuItem songMenuAddToPlaylist; // make menu on fly
	MenuItem songRateSong;
	Menu songRateSongMenu;
	MenuItem songRateSong0;
	MenuItem songRateSong1;
	MenuItem songRateSong2;
	MenuItem songRateSong3;
	MenuItem songRateSong4;
	MenuItem songRateSong5;
	MenuItem songRemove;
	
	Gdk.Pixbuf starred;
	Gdk.Pixbuf not_starred;
	
	public signal void view_being_searched(string key);
	
	public enum Hint {
		MUSIC,
		SIMILAR,
		QUEUE,
		HISTORY,
		PLAYLIST,
		SMART_PLAYLIST;
	}
	
	public Set<int> get_songs() {
		return _rows.keys;
	}
	
	public LinkedList<TreeViewColumn> get_columns() {
		var rv = new LinkedList<TreeViewColumn>();
		
		foreach(TreeViewColumn tvc in view.get_columns())
			rv.add(tvc);
		
		return rv;
	}
	
	/**
	 * for sort_id use 0+ for normal, -1 for auto, -2 for none
	 */
	public MusicTreeView(BeatBox.LibraryManager lmm, BeatBox.LibraryWindow lww, string sort, Gtk.SortType dir, Hint the_hint, int id) {
		lm = lmm;
		lw = lww;
		
		_songs = new LinkedList<int>();
		_rows = new HashMap<int, TreeRowReference>();
		_columns = new LinkedList<string>();
		
		last_search = "";
		timeout_search = new LinkedList<string>();
		removing_songs = false;
		
		sort_column = sort;
		sort_direction = dir;
		hint = the_hint;
		relative_id = id;
		
		//generate star pixbuf
		starred = this.render_icon("starred", IconSize.MENU, null);
		not_starred = this.render_icon("not-starred", IconSize.MENU, null);
		
		lm.songs_updated.connect(songs_updated);
		lm.songs_removed.connect(songs_removed);
		lm.song_played.connect(song_played);
		lm.current_cleared.connect(current_cleared);
		
		buildUI();
	}
	
	public void set_hint(Hint the_hint) {
		hint = the_hint;
		updateSensitivities();
	}
	
	public void set_id(int id) {
		relative_id = id;
	}
	
	public void updateSensitivities() {
		if(hint == Hint.MUSIC) {
			songRemove.set_sensitive(true);
			songRemove.set_label("Move to Trash");
		}
		else if(hint == Hint.SIMILAR) {
			songRemove.set_sensitive(false);
		}
		else if(hint == Hint.QUEUE) {
			songRemove.set_sensitive(true);
			songRemove.set_label("Remove from Queue");
		}
		else if(hint == Hint.HISTORY) {
			songRemove.set_sensitive(false);
		}
		else if(hint == Hint.PLAYLIST) {
			songRemove.set_sensitive(true);
		}
		else if(hint == Hint.SMART_PLAYLIST) {
			songRemove.set_sensitive(false);
		}
		else {
			songRemove.set_sensitive(false);
		}
	}
	
	public void buildUI() {
		view = new TreeView();
		
		/* id is always first and is stored as an int. Then the rest are (1)
		 * strings (for simplicity), and include:
		 * #, track, title, artist, album, genre, comment, year, rating, (9)
		 * bitrate, play count, last played, date added, file name, (5)
		 * bpm, length, file size, (3) */
		LinkedList<TreeViewColumn> to_use = new LinkedList<TreeViewColumn>();
		
		if(hint == Hint.MUSIC)
			to_use = lm.music_setup.get_columns();
		else if(hint == Hint.SIMILAR)
			to_use = lm.similar_setup.get_columns();
		else if(hint == Hint.QUEUE)
			to_use = lm.queue_setup.get_columns();
		else if(hint == Hint.HISTORY)
			to_use = lm.history_setup.get_columns();
		else if(hint == Hint.PLAYLIST)
			to_use = lm.playlist_from_id(relative_id).tvs.get_columns();
		else if(hint == Hint.SMART_PLAYLIST)
			to_use = lm.smart_playlist_from_id(relative_id).tvs.get_columns();
		
		bool is_initial = false;
		if(to_use.size != lm.dbm.COLUMN_COUNT) {
			is_initial = true;
			stdout.printf("Change in column schema. Resetting columns.\n");
			lm.dbm.initialize_columns();
			to_use = lm.fresh_columns();
			
			if(hint == Hint.MUSIC)
				lm.music_setup.set_columns(lm.fresh_columns());
			else if(hint == Hint.SIMILAR)
				lm.similar_setup.set_columns(lm.fresh_columns());
			else if(hint == Hint.QUEUE)
				lm.queue_setup.set_columns(lm.fresh_columns());
			else if(hint == Hint.HISTORY)
				lm.history_setup.set_columns(lm.fresh_columns());
			else if(hint == Hint.PLAYLIST)
				lm.playlist_from_id(relative_id).tvs.set_columns(lm.fresh_columns());
			else if(hint == Hint.SMART_PLAYLIST)
				lm.smart_playlist_from_id(relative_id).tvs.set_columns(lm.fresh_columns());
		}
		
		int index = 0;
		foreach(TreeViewColumn tvc in to_use) {
			if(tvc.title == "Bitrate" || tvc.title == "Year" || tvc.title == "#" || tvc.title == "Track" || tvc.title == "Plays" || tvc.title == "Skips") {
				view.insert_column_with_data_func(-1, tvc.title, new CellRendererText(), intelligentTreeViewFiller);
				
				view.get_column(index).resizable = true;
				view.get_column(index).reorderable = true;
				view.get_column(index).clickable = true;
				view.get_column(index).sort_column_id = index;
				view.get_column(index).set_sort_indicator(false);
				view.get_column(index).visible = tvc.visible;
				view.get_column(index).sizing = Gtk.TreeViewColumnSizing.FIXED;
				view.get_column(index).fixed_width = tvc.fixed_width;
				
				if(is_initial) {
					if(hint == Hint.MUSIC) {
						if(tvc.title == "#")
							view.get_column(index).visible = false;
						else if(tvc.title == "Track")
							view.get_column(index).visible = true;
					}
					else if(hint == Hint.SIMILAR) {
						if(tvc.title == "#")
							view.get_column(index).visible = true;
						else if(tvc.title == "Track")
							view.get_column(index).visible = false;
					}
					else if(hint == Hint.QUEUE) {
						if(tvc.title == "#")
							view.get_column(index).visible = true;
						else if(tvc.title == "Track")
							view.get_column(index).visible = false;
					}
					else if(hint == Hint.HISTORY) {
						if(tvc.title == "#")
							view.get_column(index).visible = true;
						else if(tvc.title == "Track")
							view.get_column(index).visible = false;
					}
					else if(hint == Hint.PLAYLIST) {
						if(tvc.title == "#")
							view.get_column(index).visible = true;
						else if(tvc.title == "Track")
							view.get_column(index).visible = false;
					}
					else if(hint == Hint.SMART_PLAYLIST) {
						if(tvc.title == "#")
							view.get_column(index).visible = false;
						else if(tvc.title == "Track")
							view.get_column(index).visible = true;
					}
				}
			}
			else if(tvc.title == "Rating") {
				view.insert_column(tvc, index);
				//tvc.resizable = false;
				tvc.fixed_width = 92;
				
				view.get_column(index).clear();
				for(int i = 0; i <=4; ++i) {
					var cell = new CellRendererPixbuf();
					view.get_column(index).pack_start(cell, false);
					view.get_column(index).set_cell_data_func(cell, ratingsCellDataFunction);
				}
			}
			else if(tvc.title == " ") {
				view.insert_column(tvc, index);
				
				tvc.fixed_width = 24;
				tvc.clickable = false;
				tvc.sort_column_id = -1;
				tvc.resizable = false;
			}
			else {
				view.insert_column(tvc, index);
				
				//foreach(CellRenderer cell in tvc.cell_list)
				//	cell.ellipsize = Pango.EllipsizeMode.END;
			}
			
			// add this widget crap so we can get right clicks
			view.get_column(index).widget = new Gtk.Label(tvc.title);
			view.get_column(index).widget.show();
			view.get_column(index).set_sort_indicator(false);
			Gtk.Widget ancestor = view.get_column(index).widget.get_ancestor(typeof(Gtk.Button));
			GLib.assert(ancestor != null);
			
			ancestor.button_press_event.connect(viewHeaderClick);
			
			++index;
		}
		viewColumnsChanged();
		
		model = new ListStore.newv(getColumnTypes());
		filter = new TreeModelFilter(model, null);
		sort = new TreeModelSort.with_model(filter);
		
		filter.set_visible_column(_columns.index_of("visible"));
		
		stdout.printf("setting sort column as %d or %s\n", _columns.index_of(sort_column), sort_column);
		sort.set_sort_column_id(_columns.index_of(sort_column), sort_direction);
		
		view.set_model(sort);
		view.set_headers_clickable(true);
		view.set_fixed_height_mode(true);
		
		view.row_activated.connect(viewDoubleClick);
		view.button_press_event.connect(viewClick);
		view.button_release_event.connect(viewClickRelease);
		view.columns_changed.connect(viewColumnsChanged);
		
		sort.set_sort_func(_columns.index_of("Artist"), artistCompareFunc);
		
		// allow selecting multiple rows
		view.get_selection().set_mode(SelectionMode.MULTIPLE);
		
		// drag source
		drag_source_set(view, Gdk.ModifierType.BUTTON1_MASK, {}, Gdk.DragAction.MOVE);
		Gtk.drag_source_add_uri_targets(view);
		
		// column chooser menu
		columnChooserMenu = new Menu();
		columnSmartSorting = new MenuItem.with_label("Smart sorting");
		columnNumber = new CheckMenuItem.with_label("#");
		columnTrack = new CheckMenuItem.with_label("Track");
		columnTitle = new CheckMenuItem.with_label("Title");
		columnLength = new CheckMenuItem.with_label("Length");
		columnArtist = new CheckMenuItem.with_label("Artist");
		columnAlbum = new CheckMenuItem.with_label("Album");
		columnGenre = new CheckMenuItem.with_label("Genre");
		columnYear = new CheckMenuItem.with_label("Year");
		columnBitRate = new CheckMenuItem.with_label("Bitrate");
		columnRating = new CheckMenuItem.with_label("Rating");
		columnPlayCount = new CheckMenuItem.with_label("Plays");
		columnSkipCount = new CheckMenuItem.with_label("Skips");
		columnDateAdded = new CheckMenuItem.with_label("Date Added");
		columnLastPlayed = new CheckMenuItem.with_label("Last Played");
		columnBPM = new CheckMenuItem.with_label("BPM");
		updateColumnVisibilities();
		columnChooserMenu.append(columnSmartSorting);
		columnChooserMenu.append(new SeparatorMenuItem());
		columnChooserMenu.append(columnNumber);
		columnChooserMenu.append(columnTrack);
		columnChooserMenu.append(columnTitle);
		columnChooserMenu.append(columnLength);
		columnChooserMenu.append(columnArtist);
		columnChooserMenu.append(columnAlbum);
		columnChooserMenu.append(columnGenre);
		columnChooserMenu.append(columnYear);
		columnChooserMenu.append(columnBitRate);
		columnChooserMenu.append(columnRating);
		columnChooserMenu.append(columnPlayCount);
		columnChooserMenu.append(columnSkipCount);
		columnChooserMenu.append(columnDateAdded);
		columnChooserMenu.append(columnLastPlayed);
		columnChooserMenu.append(columnBPM);
		columnSmartSorting.activate.connect(columnSmartSortingClick);
		columnNumber.toggled.connect(columnMenuToggled);
		columnTrack.toggled.connect(columnMenuToggled);
		columnTitle.toggled.connect(columnMenuToggled);
		columnLength.toggled.connect(columnMenuToggled);
		columnArtist.toggled.connect(columnMenuToggled);
		columnAlbum.toggled.connect(columnMenuToggled);
		columnGenre.toggled.connect(columnMenuToggled);
		columnYear.toggled.connect(columnMenuToggled);
		columnBitRate.toggled.connect(columnMenuToggled);
		columnRating.toggled.connect(columnMenuToggled);
		columnPlayCount.toggled.connect(columnMenuToggled);
		columnSkipCount.toggled.connect(columnMenuToggled);
		columnDateAdded.toggled.connect(columnMenuToggled);
		columnLastPlayed.toggled.connect(columnMenuToggled);
		columnBPM.toggled.connect(columnMenuToggled);
		columnChooserMenu.show_all();
		
		
		//song list right click menu
		songMenuActionMenu = new Menu();
		songEditSong = new MenuItem.with_label("Edit Song Info");
		songFileBrowse = new MenuItem.with_label("Show in File Browser");
		songMenuQueue = new MenuItem.with_label("Queue");
		songMenuNewPlaylist = new MenuItem.with_label("New Playlist");
		songMenuAddToPlaylist = new MenuItem.with_label("Add to Playlist");
		songRemove = new MenuItem.with_label("Remove song");
		songRateSongMenu = new Menu();
		songRateSong = new MenuItem.with_label("Rate Song");
		songRateSong0 = new MenuItem.with_label("No Stars");
		songRateSong1 = new MenuItem.with_label("1 Stars");
		songRateSong2 = new MenuItem.with_label("2 Stars");
		songRateSong3 = new MenuItem.with_label("3 Stars");
		songRateSong4 = new MenuItem.with_label("4 Stars");
		songRateSong5 = new MenuItem.with_label("5 Stars");
		songMenuActionMenu.append(songEditSong);
		songMenuActionMenu.append(songFileBrowse);
		
		songRateSongMenu.append(songRateSong0);
		songRateSongMenu.append(songRateSong1);
		songRateSongMenu.append(songRateSong2);
		songRateSongMenu.append(songRateSong3);
		songRateSongMenu.append(songRateSong4);
		songRateSongMenu.append(songRateSong5);
		songMenuActionMenu.append(songRateSong);
		songRateSong.submenu = songRateSongMenu;
		
		songMenuActionMenu.append(new SeparatorMenuItem());
		songMenuActionMenu.append(songMenuQueue);
		songMenuActionMenu.append(songMenuNewPlaylist);
		songMenuActionMenu.append(songMenuAddToPlaylist);
		songMenuActionMenu.append(new SeparatorMenuItem());
		songMenuActionMenu.append(songRemove);
		songEditSong.activate.connect(songMenuEditClicked);
		songFileBrowse.activate.connect(songFileBrowseClicked);
		songMenuQueue.activate.connect(songMenuQueueClicked);
		songMenuNewPlaylist.activate.connect(songMenuNewPlaylistClicked);
		songRemove.activate.connect(songRemoveClicked);
		songRateSong0.activate.connect(songRateSong0Clicked);
		songRateSong1.activate.connect(songRateSong1Clicked);
		songRateSong2.activate.connect(songRateSong2Clicked);
		songRateSong3.activate.connect(songRateSong3Clicked);
		songRateSong4.activate.connect(songRateSong4Clicked);
		songRateSong5.activate.connect(songRateSong5Clicked);
		songMenuActionMenu.show_all();
		
		updateSensitivities();
		
		this.set_policy(PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
		
		this.add(view);
		
		this.sort.rows_reordered.connect(modelRowsReordered);
		this.sort.sort_column_changed.connect(sortColumnChanged);
		this.view.drag_begin.connect(onDragBegin);
        this.view.drag_data_get.connect(onDragDataGet);
        this.view.drag_end.connect(onDragEnd);
		this.vadjustment.value_changed.connect(viewScroll);
		lw.searchField.changed.connect(searchFieldChanged);
	}
	
	/* A custom sort function for the artist column. Considers album name and track */
	public int artistCompareFunc (TreeModel model, TreeIter a, TreeIter b) {
		int a_id, b_id;
		Song a_song, b_song;
		
		model.get(a, 0, out a_id);
		model.get(b, 0, out b_id);
		
		a_song = lm.song_from_id(a_id);
		b_song = lm.song_from_id(b_id);
		
		if(a_song.artist.down() == b_song.artist.down() && a_song.album.down() == b_song.album.down() && a_song.track == b_song.track)
			return (a_song.file.down() > b_song.file.down()) ? 1 : -1;
		else if(a_song.artist.down() == b_song.artist.down() && a_song.album.down() == b_song.album.down())
			return a_song.track - b_song.track;
		else if(a_song.artist.down() == b_song.artist.down())
			return (a_song.album.down() > b_song.album.down()) ? 1 : -1;
		else
			return (a_song.artist.down() > b_song.artist.down()) ? 1 : -1;
	}
	
	public virtual void searchFieldChanged() {
		if(is_current_view) {
			timeout_search.offer_head(lw.searchField.get_text());
			Timeout.add(200, () => {
				view.set_model(null);
				
				if(lw.searchField.get_text() == timeout_search.poll_tail() && lw.searchField.get_text() != last_search && !(lw.searchField.get_text() == "" || lw.searchField.get_text() == lw.searchField.hint_string)) {
					TreeIter iter;
					for(int i = 0; model.get_iter_from_string(out iter, i.to_string()); ++i) {
						int id;
						Song s;
						
						model.get(iter, 0, out id);
						s = lm.song_from_id(id);
						
						bool show = false;
						if(lw.searchField.get_text() in s.title.down() || lw.searchField.get_text() in s.artist.down() || lw.searchField.get_text() in s.album.down() || lw.searchField.get_text() in s.genre.down())
							show = true;
						
						model.set(iter, 1, show);
					}
					
					last_search = lw.searchField.get_text();
				}
				else if(lw.searchField.get_text() != last_search && (lw.searchField.get_text() == "" || lw.searchField.get_text() == lw.searchField.hint_string)) {
					TreeIter iter;
					for(int i = 0; model.get_iter_from_string(out iter, i.to_string()); ++i) {
						model.set(iter, 1, true);
					}
					last_search = lw.searchField.get_text();
				}
				view.set_model(sort);
				
				if(!scrolled_recently)
					scrollToCurrent();
				return false;
			});
		}
	}
	
	public virtual void sortColumnChanged() {
		updateTreeViewSetup();
	}
	
	public virtual void modelRowsReordered(TreePath path, TreeIter iter, void* new_order) {
		/*if(hint == "queue") {
			lm.clear_queue();
			
			TreeIter item;
			for(int i = 0; sort.get_iter_from_string(out item, i.to_string()); ++i) {
				int id;
				sort.get(item, 0, out id);
				
				lm.queue_song_by_id(id);
			}
		}*/
		
		if(is_current) {
			setAsCurrentList( (lm.song_info.song != null) ? _rows.get(lm.song_info.song.rowid).get_path().to_string() : "0");
		}
	}
	
	public virtual void viewColumnsChanged() {
		if((int)(view.get_columns().length()) != lm.dbm.COLUMN_COUNT)
			return;
		
		if(_columns.size == 0) {
			_columns.clear();
			foreach(TreeViewColumn tvc in view.get_columns()) {
				_columns.add(tvc.title);
			}
		}
		
		updateTreeViewSetup();
		
	}
	
	public void intelligentTreeViewFiller(TreeViewColumn tvc, CellRenderer cell, TreeModel tree_model, TreeIter iter) {
		if(removing_songs)
			return;
		
		/** all of the # based columns. only show # if not 0 **/
		if(tvc.title == "Track" || tvc.title == "Year" || tvc.title == "#" || tvc.title == "Plays" || tvc.title == "Skips") {
			int val;
			tree_model.get(iter, tvc.sort_column_id, out val);
			
			if(val <= 0)
				((CellRendererText)cell).text = "";
			else
				((CellRendererText)cell).text = val.to_string();
		}
		else if(tvc.title == "Bitrate") {
			int val;
			tree_model.get(iter, tvc.sort_column_id, out val);
			
			if(val <= 0)
				((CellRendererText)cell).text = "";
			else
				((CellRendererText)cell).text = val.to_string() + " kbps";
		}
	}
	
	public void ratingsCellDataFunction(CellLayout cell_layout, CellRenderer cell, TreeModel tree_model, TreeIter iter) {
		if(removing_songs)
			return;
		
		int rating = 0;
		tree_model.get(iter, _columns.index_of("Rating"), out rating);
		
		if(cell_layout.get_cells().index(cell) < rating/* || (cursor_over && cell_layout.get_cells().index(cell) * 18 <= cell_x)*/)
			((CellRendererPixbuf)cell).pixbuf = starred;
		else if(view.get_selection().iter_is_selected(iter))
			((CellRendererPixbuf)cell).pixbuf = not_starred;
		else
			((CellRendererPixbuf)cell).pixbuf = null;//was null at one point but that messed with stuff
	}
	
	public void updateColumnVisibilities() {
		int index = 0;
		foreach(TreeViewColumn tvc in view.get_columns()) {
			if(tvc.title == "#")
				columnNumber.active = view.get_column(index).visible;
			else if(tvc.title == "Track")
				columnTrack.active = view.get_column(index).visible;
			else if(tvc.title == "Title")
				columnTitle.active = view.get_column(index).visible;
			else if(tvc.title == "Length")
				columnLength.active = view.get_column(index).visible;
			else if(tvc.title == "Artist")
				columnArtist.active = view.get_column(index).visible;
			else if(tvc.title == "Album")
				columnAlbum.active = view.get_column(index).visible;
			else if(tvc.title == "Genre")
				columnGenre.active = view.get_column(index).visible;
			else if(tvc.title == "Year")
				columnYear.active = view.get_column(index).visible;
			else if(tvc.title == "Bitrate")
				columnBitRate.active = view.get_column(index).visible;
			else if(tvc.title == "Rating")
				columnRating.active = view.get_column(index).visible;
			else if(tvc.title == "Plays")
				columnPlayCount.active = view.get_column(index).visible;
			else if(tvc.title == "Skips")
				columnSkipCount.active = view.get_column(index).visible;
			else if(tvc.title == "Date Added")
				columnDateAdded.active = view.get_column(index).visible;
			else if(tvc.title == "Last Played")
				columnLastPlayed.active = view.get_column(index).visible;
			else if(tvc.title == "BPM")
				columnBPM.active = view.get_column(index).visible;
			
			++index;
		}
	}
	
	public Type[] getColumnTypes() {
		Type[] types = new Type[lm.dbm.COLUMN_COUNT];
		
		int index = 0;
		foreach(TreeViewColumn tvc in view.get_columns()) {
			if(tvc.title == "id")
				types[index] = typeof(int);
			else if(tvc.title == "visible")
				types[index] = typeof(bool);
			else if(tvc.title == " ")
				types[index] = typeof(Gdk.Pixbuf);
			else if(tvc.title == "#")
				types[index] = typeof(int);
			else if(tvc.title == "Track")
				types[index] = typeof(int);
			else if(tvc.title == "Title")
				types[index] = typeof(string);
			else if(tvc.title == "Length")
				types[index] = typeof(string);
			else if(tvc.title == "Artist")
				types[index] = typeof(string);
			else if(tvc.title == "Album")
				types[index] = typeof(string);
			else if(tvc.title == "Genre")
				types[index] = typeof(string);
			else if(tvc.title == "Year")
				types[index] = typeof(int);
			else if(tvc.title == "Bitrate")
				types[index] = typeof(int);
			else if(tvc.title == "Rating")
				types[index] = typeof(int);
			else if(tvc.title == "Plays")
				types[index] = typeof(int);
			else if(tvc.title == "Skips")
				types[index] = typeof(int);
			else if(tvc.title == "Date Added")
				types[index] = typeof(string);
			else if(tvc.title == "Last Played")
				types[index] = typeof(string);
			else if(tvc.title == "BPM")
				types[index] = typeof(int);
			
			++index;
		}
		
		//this.model.set_column_types(types);
		
		return types;
	}
	
	public void populateView(Collection<int> songs, bool is_search) {
		view.freeze_child_notify();
		view.set_model(null);
		
		//get selected songs and put in temp array
		
		if(!is_search) {
			model.clear();
			this._rows.clear();
			
			foreach(int i in songs) {
				addSong(lm.song_from_id(i));
			}
		}
		
		//reselect songs that were selected before populateview update
		
		view.set_model(sort);
		view.thaw_child_notify();
	}
	
	public TreeIter? addSong(Song s) {
		TreeIter item;
		model.append(out item);
		
		/* allows for easy updating, removing of songs */
		_rows.set(s.rowid, new TreeRowReference(model, model.get_path(item)));
		
		model.set(item, _columns.index_of("id"), s.rowid,
								_columns.index_of("visible"), true,
								_columns.index_of(" "), (lm.song_info.song != null && s.rowid == lm.song_info.song.rowid && is_current) ? view.render_icon("audio-volume-high", IconSize.MENU, null) : null,
								_columns.index_of("#"), _rows.size,
								_columns.index_of("Track"), s.track,
								_columns.index_of("Title"), s.title,
								_columns.index_of("Length"), s.pretty_length(),
								_columns.index_of("Artist"), s.artist,
								_columns.index_of("Album"), s.album,
								_columns.index_of("Genre"), s.genre,
								_columns.index_of("Year"), s.year,
								_columns.index_of("Bitrate"), s.bitrate,
								_columns.index_of("Rating"), s.rating,
								_columns.index_of("Plays"), s.play_count,
								_columns.index_of("Skips"), s.skip_count,
								_columns.index_of("Date Added"), s.pretty_date_added(),
								_columns.index_of("Last Played"), s.pretty_last_played(),
								_columns.index_of("BPM"), s.bpm);
		
		return item;
	}
	
	public bool updateSong(int i) {
		if(!_rows.has_key(i))
			return false;
		
		TreeIter item;
		TreePath path = _rows.get(i).get_path();
		
		if(path == null) {
			_rows.unset(i);
			return false;
		}
		
		model.get_iter(out item, path);
		Song s = lm.song_from_id(i);
		
		model.set(item, _columns.index_of("id"), s.rowid,
								_columns.index_of(" "), (lm.song_info.song != null && i == lm.song_info.song.rowid && is_current) ? view.render_icon("audio-volume-high", IconSize.MENU, null) : null,
								_columns.index_of("Track"), s.track,
								_columns.index_of("Title"), s.title,
								_columns.index_of("Length"), s.pretty_length(),
								_columns.index_of("Artist"), s.artist,
								_columns.index_of("Album"), s.album,
								_columns.index_of("Genre"), s.genre,
								_columns.index_of("Year"), s.year,
								_columns.index_of("Bitrate"), s.bitrate,
								_columns.index_of("Rating"), s.rating,
								_columns.index_of("Plays"), s.play_count,
								_columns.index_of("Skips"), s.skip_count,
								_columns.index_of("Date Added"), s.pretty_date_added(),
								_columns.index_of("Last Played"), s.pretty_last_played(),
								_columns.index_of("BPM"), s.bpm);
		
		return true;
	}
	
	public bool removeSong(int i) {
		if(!_rows.has_key(i))
			return false;
		
		stdout.printf("has key %d\n", i);
		
		TreeIter item;
		TreePath path = _rows.get(i).get_path();
		
		if(path == null) {
			_rows.unset(i);
			stdout.printf("path was invalid.. unsetting row %d\n", i);
			return false;
		}
		
		model.get_iter(out item, path);
		model.remove(item);
		
		_rows.unset(i);
		
		stdout.printf("Removed song %s by %s from model************\n", lm.song_from_id(i).title, lm.song_from_id(i).artist);
		return true;
	}
	
	public virtual void current_cleared() {
		this.is_current = false;
		
		if(lm.song_info.song != null)
			updateSong(lm.song_info.song.rowid);
	}
	
	public virtual void song_played(int id, int old) {
		if(old != -1)
			updateSong(old);
		
		if(!scrolled_recently) {
			scrollToCurrent();
		}
		
		updateSong(id);
	}
	
	public virtual void songs_updated(Collection<int> ids) {
		foreach(int id in ids) {
			updateSong(id);
		}
		
		//since a song may have changed location, reset current
		if(is_current)
			setAsCurrentList(null);
	}
	
	public virtual void songs_removed(LinkedList<int> ids) {
		removing_songs = true;
		foreach(int id in ids) {
			//stdout.printf("removing id %d\n", id);
			removeSong(id);
		}
		removing_songs = false;
	}
	
	public virtual void viewDoubleClick(TreePath path, TreeViewColumn column) {
		TreeIter item;
		
		setAsCurrentList(path.to_string());
		
		// get db's rowid of row clicked
		sort.get_iter(out item, path);
		int id;
		sort.get(item, 0, out id);
		
		// play the song
		lm.playSong(id);
		lm.player.play_stream();
		
		if(!lm.playing) {
			lw.playClicked();
		}
	}
	
	public void setAsCurrentList(string? current_song_path) {
		if(current_song_path != null) {
			lm.current_index = int.parse(current_song_path);
		}
		else if(_rows.get(0) != null) {
			lm.current_index = int.parse(_rows.get(0).get_path().to_string());
		}
		
		//we will update the path to the current song in the loop if 
		//current_song_path is null
		
		lm.clearCurrent();
		
		TreeIter iter;
		for(int i = 0; sort.get_iter_from_string(out iter, i.to_string()); ++i) {
			int id;
			sort.get(iter, 0, out id);
			
			lm.addToCurrent(id);
			
			if(lm.song_info.song.rowid == id && current_song_path == null)
				lm.current_index = i;
		}
		
		is_current = true;
		
		if(lm.song_info.song != null)
			updateSong(lm.song_info.song.rowid);
			
		if(lm.is_shuffled())
			lm.shuffleMusic();
	}
	
	/* button_press_event */
	public virtual bool viewClick(Gdk.EventButton event) {
		if(event.type == Gdk.EventType.BUTTON_PRESS && event.button == 3) { //right click
			/* create add to playlist menu */
			Menu addToPlaylistMenu = new Menu();
			foreach(Playlist p in lm.playlists()) {
				MenuItem playlist = new MenuItem.with_label(p.name);
				addToPlaylistMenu.append(playlist);
				
				playlist.activate.connect( () => {
					TreeModel temp;
					foreach(TreePath path in view.get_selection().get_selected_rows(out temp)) {
						TreeIter item;
						temp.get_iter(out item, path);
						
						int id;
						temp.get(item, 0, out id);
						p.addSong(lm.song_from_id(id));
					}
				});
			}
			
			addToPlaylistMenu.show_all();
			songMenuAddToPlaylist.submenu = addToPlaylistMenu;
			
			if(lm.playlists().size == 0)
				songMenuAddToPlaylist.set_sensitive(false);
			else
				songMenuAddToPlaylist.set_sensitive(true);
			
			songMenuActionMenu.popup (null, null, null, 3, get_current_event_time());
			
			TreeSelection selected = view.get_selection();
			selected.set_mode(SelectionMode.MULTIPLE);
			if(selected.count_selected_rows() > 1)
				return true;
			else
				return false;
		}
		else if(event.type == Gdk.EventType.BUTTON_PRESS && event.button == 1) {
			TreeIter iter;
			TreePath path;
			TreeViewColumn column;
			int cell_x;
			int cell_y;
			
			view.get_path_at_pos((int)event.x, (int)event.y, out path, out column, out cell_x, out cell_y);
			
			/* don't unselect everything if multiple selected until button release
			 * for drag and drop reasons */
			if(view.get_selection().count_selected_rows() > 1) {
				if(view.get_selection().path_is_selected(path)) {
					if(((event.state & Gdk.ModifierType.SHIFT_MASK) == Gdk.ModifierType.SHIFT_MASK)|
						((event.state & Gdk.ModifierType.CONTROL_MASK) == Gdk.ModifierType.CONTROL_MASK)) {
							view.get_selection().unselect_path(path);
					}
					return true;
				}
				else if(!(((event.state & Gdk.ModifierType.SHIFT_MASK) == Gdk.ModifierType.SHIFT_MASK)|
						((event.state & Gdk.ModifierType.CONTROL_MASK) == Gdk.ModifierType.CONTROL_MASK))) {
					return true;
				}
				
				return false;
			}
			
			if(!sort.get_iter(out iter, path) || column.title != "Rating")
				return false;
			
			int id = 0;	
			int new_rating = 0;
			
			if(cell_x > 5)
				new_rating = (cell_x + 18) / 18;
			
			sort.get(iter, 0, out id);
			Song s = lm.song_from_id(id);
			s.rating = new_rating;
			
			lm.update_song(s, false);
		}
		
		return false;
	}
	
	/* button_release_event */
	private bool viewClickRelease(Gtk.Widget sender, Gdk.EventButton event) {
		/* if we were dragging, then set dragging to false */
		if(dragging && event.button == 1) {
			dragging = false;
			return true;
		}
		else if(((event.state & Gdk.ModifierType.SHIFT_MASK) == Gdk.ModifierType.SHIFT_MASK) | ((event.state & Gdk.ModifierType.CONTROL_MASK) == Gdk.ModifierType.CONTROL_MASK)) {
			return true;
		}
		else {
			TreePath path;
			TreeViewColumn tvc;
			int cell_x;
			int cell_y;
			int x = (int)event.x;
			int y = (int)event.y;
			
			if(!(view.get_path_at_pos(x, y, out path, out tvc, out cell_x, out cell_y))) return false;
			view.get_selection().unselect_all();
			view.get_selection().select_path(path);
			return false;
		}
	}
	
	private bool viewHeaderClick(Gtk.Widget w, Gdk.EventButton e) {
		if(e.button == 3) {
			columnChooserMenu.popup (null, null, null, 3, get_current_event_time());
			return true;
		}
		else if(e.button == 1) {
			
			return false;
		}
		
		return false;
	}
	
	public virtual void viewHeadersResized() {
		stdout.printf("headers resized\n");
		updateTreeViewSetup();
	}
	
	public virtual void columnSmartSortingClick() {
		int main_sort = _columns.index_of("#");
		
		if(hint == Hint.MUSIC || hint == Hint.SMART_PLAYLIST)
			main_sort = _columns.index_of("Artist");
		else if(hint == Hint.SIMILAR || hint == Hint.QUEUE || hint == Hint.HISTORY || hint == Hint.PLAYLIST)
			main_sort = _columns.index_of("#");
		
		sort_column = _columns.get(main_sort);
		sort.set_sort_column_id(main_sort, Gtk.SortType.ASCENDING);
		updateTreeViewSetup();
		
		if(is_current)
			setAsCurrentList( (lm.song_info.song != null) ? _rows.get(lm.song_info.song.rowid).get_path().to_string() : "0");
	}
	
	public void updateTreeViewSetup() {
		if(sort == null || !(sort is TreeModelSort)) {
			return;
		}
		
		TreeViewSetup tvs = new TreeViewSetup("#", SortType.ASCENDING);
			
		if(hint == Hint.MUSIC)
			tvs = lm.music_setup;
		else if(hint == Hint.SIMILAR)
			tvs = lm.similar_setup;
		else if(hint == Hint.QUEUE)
			tvs = lm.queue_setup;
		else if(hint == Hint.HISTORY)
			tvs = lm.history_setup;
		else if(hint == Hint.PLAYLIST)
			tvs = lm.playlist_from_id(relative_id).tvs;
		else if(hint == Hint.SMART_PLAYLIST)
			tvs = lm.smart_playlist_from_id(relative_id).tvs;
		
		int sort_id = 7;
		SortType sort_dir = Gtk.SortType.ASCENDING;
		sort.get_sort_column_id(out sort_id, out sort_dir);
		
		if(sort_id <= 0)
			sort_id = 7;
		
		tvs.set_columns(get_columns());
		tvs.sort_column = _columns.get(sort_id);
		tvs.sort_direction = sort_dir;
	}
	
	/** When the column chooser popup menu has a change/toggle **/
	public virtual void columnMenuToggled() {
		int index = 0;
		foreach(TreeViewColumn tvc in view.get_columns()) {
			if(tvc.title == "Track")
				view.get_column(index).visible = columnTrack.active;
			else if(tvc.title == "#")
				view.get_column(index).visible = columnNumber.active;
			else if(tvc.title == "Title")
				view.get_column(index).visible = columnTitle.active;
			else if(tvc.title == "Length")
				view.get_column(index).visible = columnLength.active;
			else if(tvc.title == "Artist")
				view.get_column(index).visible = columnArtist.active;
			else if(tvc.title == "Album")
				view.get_column(index).visible = columnAlbum.active;
			else if(tvc.title == "Genre")
				view.get_column(index).visible = columnGenre.active;
			else if(tvc.title == "Year")
				view.get_column(index).visible = columnYear.active;
			else if(tvc.title == "Bitrate")
				view.get_column(index).visible = columnBitRate.active;
			else if(tvc.title == "Rating")
				view.get_column(index).visible = columnRating.active;
			else if(tvc.title == "Plays")
				view.get_column(index).visible = columnPlayCount.active;
			else if(tvc.title == "Skips")
				view.get_column(index).visible = columnSkipCount.active;
			else if(tvc.title == "Date Added")
				view.get_column(index).visible = columnDateAdded.active;
			else if(tvc.title == "Last Played")
				view.get_column(index).visible = columnLastPlayed.active;//add bpm, file size, file path
			else if(tvc.title == "BPM")
				view.get_column(index).visible = columnBPM.active;
			
			++index;
		}
		
		if(hint == Hint.MUSIC)
			lm.music_setup.set_columns(get_columns());
		else if(hint == Hint.SIMILAR)
			lm.similar_setup.set_columns(get_columns());
		else if(hint == Hint.QUEUE)
			lm.queue_setup.set_columns(get_columns());
		else if(hint == Hint.HISTORY)
			lm.history_setup.set_columns(get_columns());
		else if(hint == Hint.PLAYLIST)
			lm.playlist_from_id(relative_id).tvs.set_columns(get_columns());
		else if(hint == Hint.SMART_PLAYLIST)
			lm.smart_playlist_from_id(relative_id).tvs.set_columns(get_columns());
	}
	
	/** song menu popup clicks **/
	public virtual void songMenuEditClicked() {
		TreeSelection selected = view.get_selection();
		selected.set_mode(SelectionMode.MULTIPLE);
		TreeModel temp;
		
		HashMap<string, string> lastfmStuff = new HashMap<string, string>();
		
		//tempSongs.clear();
		var to_edit = new LinkedList<Song>();
		foreach(TreePath path in selected.get_selected_rows(out temp)) {
			TreeIter item;
			temp.get_iter(out item, path);
			
			int id;
			temp.get(item, 0, out id);
			Song s = lm.song_from_id(id);
			
			if(!lastfmStuff.has_key("track"))
				lastfmStuff.set("track", s.title + " by " + s.artist);
			else if(lastfmStuff.get("track") != (s.title + " by " + s.artist))
				lastfmStuff.set("track", "");
			
			if(!lastfmStuff.has_key("artist"))
				lastfmStuff.set("artist", s.artist);
			else if(lastfmStuff.get("artist") != s.artist)
				lastfmStuff.set("artist", "");
			
			if(!lastfmStuff.has_key("album"))
				lastfmStuff.set("album", s.album + " by " + s.artist);
			else if(lastfmStuff.get("album") != (s.album + " by " + s.artist))
				lastfmStuff.set("album", "");
			
			to_edit.add(s);
		}
		
		SongEditor se = new SongEditor(to_edit, lm.get_track(lastfmStuff.get("track")), 
										lm.get_artist(lastfmStuff.get("artist")), 
										lm.get_album(lastfmStuff.get("album")));
		se.songs_saved.connect(songEditorSaved);
	}
	
	public virtual void songEditorSaved(LinkedList<Song> songs) {
		lm.update_songs(songs, true);
	}
	
	public virtual void songFileBrowseClicked() {
		TreeSelection selected = view.get_selection();
		selected.set_mode(SelectionMode.MULTIPLE);
		TreeModel temp;
		
		foreach(TreePath path in selected.get_selected_rows(out temp)) {
			TreeIter item;
			temp.get_iter(out item, path);
			
			int id;
			temp.get(item, 0, out id);
			Song s = lm.song_from_id(id);
			
			try {
				var file = File.new_for_path(s.file);
				GLib.AppInfo.launch_default_for_uri (file.get_parent().get_path(), null);
			}
			catch(GLib.Error err) {
				stdout.printf("Could not browse song %s: %s\n", s.file, err.message);
			}
			
			return;
		}
	}
	
	public virtual void songMenuQueueClicked() {
		TreeSelection selected = view.get_selection();
		selected.set_mode(SelectionMode.MULTIPLE);
		
		TreeModel model;
		
		foreach(TreePath path in selected.get_selected_rows(out model)) {
			TreeIter item;
			model.get_iter(out item, path);
			
			int id;
			model.get(item, 0, out id);
			
			lm.queue_song_by_id(id);
		}
	}
	
	public virtual void songMenuNewPlaylistClicked() {
		Playlist p = new Playlist();
		TreeSelection selected = view.get_selection();
		selected.set_mode(SelectionMode.MULTIPLE);
		
		TreeModel temp;
		foreach(TreePath path in selected.get_selected_rows(out temp)) {
			TreeIter item;
			sort.get_iter(out item, path);
			
			int id;
			sort.get(item, 0, out id);
			
			p.addSong(lm.song_from_id(id));
		}
		
		PlaylistNameWindow pnw = new PlaylistNameWindow(p);
		pnw.playlist_saved.connect( (newP) => { 
			lm.add_playlist(p);
			lw.addSideListItem(p); 
		});
	}
	
	public virtual void songRemoveClicked() {
		TreeSelection selected = view.get_selection();
		selected.set_mode(SelectionMode.MULTIPLE);
		
		LinkedList<Song> toRemove = new LinkedList<Song>();
		TreeModel temp;
		
		/* reverse list of selected rows so when we remove multiple rows
		 * our treepaths aren't messed up
		 */
		GLib.List<TreePath> paths = new GLib.List<TreePath>();
		foreach(TreePath path in selected.get_selected_rows(out temp)) {
			paths.prepend(path);
		}
		
		foreach(TreePath path in paths) {
			TreeIter item;
			temp.get_iter(out item, path);
			
			int id;
			temp.get(item, 0, out id);
			Song s = lm.song_from_id(id);
			stdout.printf("Song is %s by %s\n", s.title, s.artist);
			
			if(hint == Hint.QUEUE) {
				lm.unqueue_song_by_id(s.rowid);
				removeSong(id);
			}
			else if(hint == Hint.PLAYLIST) {
				lm.playlist_from_id(relative_id).removeSong(s);
				removeSong(id);
			}
			else if(hint == Hint.MUSIC) {
				toRemove.add(s);
			}
		}
		
		if(hint == Hint.MUSIC)
			lm.remove_songs(toRemove);
	}
	
	public virtual void songRateSong0Clicked() {
		TreeSelection selected = view.get_selection();
		selected.set_mode(SelectionMode.MULTIPLE);
		TreeModel l_model;
		
		var los = new LinkedList<Song>();
		foreach(TreePath path in selected.get_selected_rows(out l_model)) {
			TreeIter item;
			l_model.get_iter(out item, path);
			
			int id;
			l_model.get(item, 0, out id);
			Song s = lm.song_from_id(id);
			
			s.rating = 0;
			los.add(s);
		}
		
		lm.update_songs(los, false);
	}
	
	public virtual void songRateSong1Clicked() {
		TreeSelection selected = view.get_selection();
		selected.set_mode(SelectionMode.MULTIPLE);
		TreeModel l_model;
		
		var los = new LinkedList<Song>();
		foreach(TreePath path in selected.get_selected_rows(out l_model)) {
			TreeIter item;
			l_model.get_iter(out item, path);
			
			int id;
			l_model.get(item, 0, out id);
			Song s = lm.song_from_id(id);
			
			s.rating = 1;
			los.add(s);
		}
		
		lm.update_songs(los, false);
	}
	
	public virtual void songRateSong2Clicked() {
		TreeSelection selected = view.get_selection();
		selected.set_mode(SelectionMode.MULTIPLE);
		TreeModel l_model;
		
		var los = new LinkedList<Song>();
		foreach(TreePath path in selected.get_selected_rows(out l_model)) {
			TreeIter item;
			l_model.get_iter(out item, path);
			
			int id;
			l_model.get(item, 0, out id);
			Song s = lm.song_from_id(id);
			
			s.rating = 2;
			los.add(s);
		}
		
		lm.update_songs(los, false);
	}
	
	public virtual void songRateSong3Clicked() {
		TreeSelection selected = view.get_selection();
		selected.set_mode(SelectionMode.MULTIPLE);
		TreeModel l_model;
		
		var los = new LinkedList<Song>();
		foreach(TreePath path in selected.get_selected_rows(out l_model)) {
			TreeIter item;
			l_model.get_iter(out item, path);
			
			int id;
			l_model.get(item, 0, out id);
			Song s = lm.song_from_id(id);
			
			s.rating = 3;
			los.add(s);
		}
		
		lm.update_songs(los, false);
	}
	
	public virtual void songRateSong4Clicked() {
		TreeSelection selected = view.get_selection();
		selected.set_mode(SelectionMode.MULTIPLE);
		TreeModel l_model;
		
		var los = new LinkedList<Song>();
		foreach(TreePath path in selected.get_selected_rows(out l_model)) {
			TreeIter item;
			l_model.get_iter(out item, path);
			
			int id;
			l_model.get(item, 0, out id);
			Song s = lm.song_from_id(id);
			
			s.rating = 4;
			los.add(s);
		}
		
		lm.update_songs(los, false);
	}
	
	public virtual void songRateSong5Clicked() {
		TreeSelection selected = view.get_selection();
		selected.set_mode(SelectionMode.MULTIPLE);
		TreeModel l_model;
		
		var los = new LinkedList<Song>();
		foreach(TreePath path in selected.get_selected_rows(out l_model)) {
			TreeIter item;
			l_model.get_iter(out item, path);
			
			int id;
			l_model.get(item, 0, out id);
			Song s = lm.song_from_id(id);
			
			s.rating = 5;
			los.add(s);
		}
		
		lm.update_songs(los, false);
	}
	
	public void scrollToCurrent() {
		if(!is_current || lm.song_info.song == null)
			return;
		
		TreeIter iter;
		for(int i = 0; sort.get_iter_from_string(out iter, i.to_string()); ++i) {
			int id;
			sort.get(iter, 0, out id);
			
			if(id == lm.song_info.song.rowid) {
				view.scroll_to_cell(new TreePath.from_string(i.to_string()), null, false, 0.0f, 0.0f);
				scrolled_recently = false;
				
				return;
			}
		}
		
		scrolled_recently = false;
	}
	
	public virtual void viewScroll() {
		if(!scrolled_recently && is_current) {
			Timeout.add(30000, () => {
				scrolled_recently = false;
				
				return false;
			});
			
			scrolled_recently = true;
		}
	}
	
	public virtual void onDragBegin(Gtk.Widget sender, Gdk.DragContext context) {
		dragging = true;
		stdout.printf("drag begin\n");

		Gdk.drag_abort(context, Gtk.get_current_event_time());
		
		if(view.get_selection().count_selected_rows() == 1) {
			drag_source_set_icon_stock(this, Gtk.Stock.DND);
		}
		else if(view.get_selection().count_selected_rows() > 1) {
			drag_source_set_icon_stock(this, Gtk.Stock.DND_MULTIPLE);
		}
		else {
			return;
		}
	}
	
	public virtual void onDragDataGet(Gdk.DragContext context, Gtk.SelectionData selection_data, uint info, uint time_) {
        Gtk.TreeIter iter;
        Gtk.TreeModel temp_model;
        
        var rows = view.get_selection().get_selected_rows(out temp_model);
        string[] uris = null;
        
        foreach(TreePath path in rows) {
            temp_model.get_iter_from_string (out iter, path.to_string ());
            
			int id;
			temp_model.get (iter, 0, out id);
			stdout.printf("adding %s\n", lm.song_from_id(id).file);
			uris += ("file://" + lm.song_from_id(id).file);
		}
		
        if (uris != null)
            selection_data.set_uris(uris);
    }
    
    public virtual void onDragEnd(Gtk.Widget sender, Gdk.DragContext context) {
		dragging = false;
		
		stdout.printf("drag end\n");
		
		//unset_rows_drag_dest();
		Gtk.drag_dest_set(this,
		                  Gtk.DestDefaults.ALL,
		                  {},
		                  Gdk.DragAction.COPY|
		                  Gdk.DragAction.MOVE
		                  );
	}
}
