/*-
 * Copyright (c) 2011       Scott Ringwelski <sgringwe@mtu.edu>
 *
 * Originaly Written by Scott Ringwelski for BeatBox Music Player
 * BeatBox Music Player: http://www.launchpad.net/beat-box
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

using Gee;
using Gtk;

public class BeatBox.MusicTreeView : ScrolledWindow {
	public BeatBox.LibraryManager lm;
	public BeatBox.LibraryWindow lw;
	private BeatBox.SortHelper sh;
	private TreeView view;
	private MusicTreeModel music_model; // this is always full of songs, for quick unsearching
	
	private Collection<int> _songs;
	private Collection<int> _showing_songs;
	private LinkedList<string> _columns;
	
	public int relative_id;// if playlist, playlist id, etc.
	public Hint hint; // playlist, queue, smart_playlist, etc. changes how it behaves.
	string sort_column;
	SortType sort_direction;
	private bool playlistSaveTimeoutAdded;
	public bool removing_songs;
	
	public bool is_current_view;
	private bool _is_current;
	public bool dragging;
	public bool needsUpdate;
	
	LinkedList<string> timeout_search;//stops from doing useless search (timeout)
	string last_search;//stops from searching same thing multiple times
	bool showing_all; // stops from searching unnecesarilly when changing b/w 0 words and search hint, etc.
	
	bool scrolled_recently;
	
	CellDataFunctionHelper cellHelper;
	
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
	RatingWidgetMenu rating_item;
	MenuItem songRemove;
	
	Gdk.Pixbuf starred;
	Gdk.Pixbuf not_starred;
	
	// for editing cells in-treeview
	CellRendererText cellTrack;
	CellRendererText cellTitle;
	CellRendererText cellLength;
	CellRendererText cellArtist;
	CellRendererText cellAlbum;
	CellRendererText cellGenre;
	CellRendererText cellYear;
	CellRendererPixbuf cellRating;
	CellRendererText cellSkips;
	CellRendererText cellPlays;
	CellRendererText cellBitrate;
	
	
	public signal void view_being_searched(string key);
	
	public enum Hint {
		MUSIC,
		SIMILAR,
		QUEUE,
		HISTORY,
		PLAYLIST,
		SMART_PLAYLIST;
	}
	
	public bool is_current {
		get { return _is_current; }
		set {
			_is_current = value;
			music_model.is_current = value;
		}
	}
	
	public void set_songs(LinkedList<int> new_songs) {
		_songs = new_songs;
	}
	
	public Collection<int> get_songs() {
		return _songs;
	}
	
	public LinkedList<TreeViewColumn> get_columns() {
		var rv = new LinkedList<TreeViewColumn>();
		
		foreach(TreeViewColumn tvc in view.get_columns())
			rv.add(tvc);
		
		return rv;
	}
	
	public LinkedList<string> get_column_strings() {
		var rv = new LinkedList<string>();
		
		foreach(TreeViewColumn tvc in view.get_columns())
			rv.add(tvc.title);
		
		return rv;
	}
	
	/**
	 * for sort_id use 0+ for normal, -1 for auto, -2 for none
	 */
	public MusicTreeView(BeatBox.LibraryManager lmm, BeatBox.LibraryWindow lww, string sort, Gtk.SortType dir, Hint the_hint, int id) {
		lm = lmm;
		lw = lww;
		sh = new SortHelper(lm);
		
		_songs = new LinkedList<int>();
		_showing_songs = new LinkedList<int>();
		_columns = new LinkedList<string>();
		
		last_search = "";
		timeout_search = new LinkedList<string>();
		showing_all = true;
		removing_songs = false;
		
		sort_column = sort;
		sort_direction = dir;
		hint = the_hint;
		playlistSaveTimeoutAdded = false;
		relative_id = id;
		
		cellHelper = new CellDataFunctionHelper(this);
		
		//generate star pixbuf
		starred = this.render_icon("starred", IconSize.MENU, null);
		not_starred = this.render_icon("not-starred", IconSize.MENU, null);
		
		lm.songs_updated.connect(songs_updated);
		lm.songs_removed.connect(songs_removed);
		lm.song_played.connect(song_played);
		lm.playback_stopped.connect(playback_stopped);
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
			columnNumber.set_active(false);
			columnNumber.set_visible(false);
		}
		else if(hint == Hint.SIMILAR) {
			songRemove.set_sensitive(false);
		}
		else if(hint == Hint.QUEUE) {
			songRemove.set_sensitive(true);
			songRemove.set_label("Remove from Queue");
			songMenuQueue.set_sensitive(false);
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
		
		cellTrack = new CellRendererText();
		cellTitle = new CellRendererText();
		cellLength = new CellRendererText();
		cellArtist = new CellRendererText();
		cellAlbum = new CellRendererText();
		cellGenre = new CellRendererText();
		cellYear = new CellRendererText();
		cellRating = new CellRendererPixbuf();
		cellSkips = new CellRendererText();
		cellPlays = new CellRendererText();
		cellBitrate = new CellRendererText();
		
		cellRating.xalign = 0.0f;
		
		//cellTitle.editable = false;
		//cellTitle.edited.connect(cellTitleEdited);
		
		/* id is always first and is stored as an int. Then the rest are (1)
		 * strings (for simplicity), and include:
		 * #, track, title, artist, album, genre, comment, year, rating, (9)
		 * bitrate, play count, last played, date added, file name, (5)
		 * bpm, length, file size, (3) */
		LinkedList<TreeViewColumn> to_use = new LinkedList<TreeViewColumn>();
		LinkedList<TreeViewColumn> originalOrder = new LinkedList<TreeViewColumn>();
		LinkedList<string> correctStringOrder = new LinkedList<string>();
		
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
		
		/* put them in the order for treemodel */
		foreach(var tvc in to_use) {
			if(tvc.title == "id")
				originalOrder.add(tvc);
			else if(tvc.title == " ")
				originalOrder.add(tvc);
			else if(tvc.title == "#")
				originalOrder.add(tvc);
			else if(tvc.title == "Track")
				originalOrder.add(tvc);
			else if(tvc.title == "Length")
				originalOrder.add(tvc);
			else if(tvc.title == "Title")
				originalOrder.add(tvc);
			else if(tvc.title == "Artist")
				originalOrder.add(tvc);
			else if(tvc.title == "Album")
				originalOrder.add(tvc);
			else if(tvc.title == "Genre")
				originalOrder.add(tvc);
			else if(tvc.title == "Year")
				originalOrder.add(tvc);
			else if(tvc.title == "Bitrate")
				originalOrder.add(tvc);
			else if(tvc.title == "Rating")
				originalOrder.add(tvc);
			else if(tvc.title == "Plays")
				originalOrder.add(tvc);
			else if(tvc.title == "Skips")
				originalOrder.add(tvc);
			else if(tvc.title == "Date Added")
				originalOrder.add(tvc);
			else if(tvc.title == "Last Played")
				originalOrder.add(tvc);
			else if(tvc.title == "BPM")
				originalOrder.add(tvc);
				
			correctStringOrder.add(tvc.title);
		}
		
		int index = 0;
		foreach(TreeViewColumn tvc in originalOrder) {
			if(!(tvc.title == " " || tvc.title == "id")) {
				if(tvc.title == "Bitrate")
					view.insert_column_with_data_func(-1, tvc.title, cellBitrate, cellHelper.bitrateTreeViewFiller);
				else if(tvc.title == "Length")
					view.insert_column_with_data_func(-1, tvc.title, cellLength, cellHelper.lengthTreeViewFiller);
				else if(tvc.title == "Date Added")
					view.insert_column_with_data_func(-1, tvc.title, new CellRendererText(), cellHelper.dateTreeViewFiller);
				else if(tvc.title == "Last Played")
					view.insert_column_with_data_func(-1, tvc.title, new CellRendererText(), cellHelper.dateTreeViewFiller);
				else if(tvc.title == "Rating")
					view.insert_column_with_data_func(-1, tvc.title, cellRating, cellHelper.ratingTreeViewFiller);
				else if(tvc.title == "Year")
					view.insert_column_with_data_func(-1, tvc.title, cellYear, cellHelper.intelligentTreeViewFiller);
				else if(tvc.title == "#")
					view.insert_column_with_data_func(-1, tvc.title, new CellRendererText(), cellHelper.intelligentTreeViewFiller);
				else if(tvc.title == "Track")
					view.insert_column_with_data_func(-1, tvc.title, cellTrack, cellHelper.intelligentTreeViewFiller);
				else if(tvc.title == "Plays")
					view.insert_column_with_data_func(-1, tvc.title, cellPlays, cellHelper.intelligentTreeViewFiller);
				else if(tvc.title == "Skips")
					view.insert_column_with_data_func(-1, tvc.title, cellSkips, cellHelper.intelligentTreeViewFiller);
				else if(tvc.title == "Title")
					view.insert_column_with_data_func(-1, tvc.title, cellTitle, cellHelper.stringTreeViewFiller);
				else if(tvc.title == "Artist")
					view.insert_column_with_data_func(-1, tvc.title, cellArtist, cellHelper.stringTreeViewFiller);
				else if(tvc.title == "Album")
					view.insert_column_with_data_func(-1, tvc.title, cellAlbum, cellHelper.stringTreeViewFiller);
				else if(tvc.title == "Genre")
					view.insert_column_with_data_func(-1, tvc.title, cellGenre, cellHelper.stringTreeViewFiller);
				else if(tvc.title == "BPM")
					view.insert_column_with_data_func(-1, tvc.title, new CellRendererText(), cellHelper.intelligentTreeViewFiller);
				
				
				view.get_column(index).resizable = true;
				view.get_column(index).reorderable = false;
				view.get_column(index).clickable = true;
				view.get_column(index).sort_column_id = index;
				view.get_column(index).set_sort_indicator(false);
				view.get_column(index).visible = tvc.visible;
				view.get_column(index).sizing = Gtk.TreeViewColumnSizing.FIXED;
				view.get_column(index).fixed_width = tvc.fixed_width;
			}
			else if(tvc.title == " ") {
				view.insert_column(tvc, index);
				
				tvc.fixed_width = 24;
				tvc.clickable = false;
				tvc.sort_column_id = -1;
				tvc.resizable = false;
				tvc.reorderable = false;
			}
			else if(tvc.title == "id") {
				view.insert_column(tvc, index);
			}
			else {
				view.insert_column(tvc, index);
			}
			
			// add this widget crap so we can get right clicks
			view.get_column(index).widget = new Gtk.Label(tvc.title);
			view.get_column(index).widget.show();
			view.get_column(index).set_sort_indicator(false);
			Gtk.Widget ancestor = view.get_column(index).widget.get_ancestor(typeof(Gtk.Button));
			GLib.assert(ancestor != null);
			
			ancestor.button_press_event.connect(viewHeaderClick);
			view.get_column(index).notify["width"].connect(viewHeadersResized);
			
			++index;
		}
		//rearrangeColumns(correctStringOrder);
		viewColumnsChanged();
		
		music_model = new MusicTreeModel(lm, get_column_strings(), render_icon("audio-volume-high", IconSize.MENU, null));
		
		music_model.set_sort_column_id(_columns.index_of(sort_column), sort_direction);
		
		view.set_model(music_model);
		view.set_headers_clickable(true);
		view.set_fixed_height_mode(true);
		view.rules_hint = true;
		view.set_reorderable(false);
		
		view.row_activated.connect(viewDoubleClick);
		view.button_press_event.connect(viewClick);
		
		view.cursor_changed.connect_after(() => { update_rating_menu(); });
		view.button_release_event.connect(viewClickRelease);
		view.columns_changed.connect(viewColumnsChanged);
		view.key_press_event.connect(keyPressed);
		
		// allow selecting multiple rows
		view.get_selection().set_mode(SelectionMode.MULTIPLE);
		
		// drag source
		drag_source_set(view, Gdk.ModifierType.BUTTON1_MASK, {}, Gdk.DragAction.COPY);
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
		rating_item = new RatingWidgetMenu();
		songMenuActionMenu.append(songEditSong);
		songMenuActionMenu.append(songFileBrowse);
		
		songMenuActionMenu.append(rating_item);
		
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
		rating_item.activate.connect(songRateSong0Clicked);
		//songMenuActionMenu.show_all();
		
		updateSensitivities();
		
		this.set_policy(PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
		
		this.add(view);
		
		this.music_model.rows_reordered.connect(modelRowsReordered);
		this.music_model.sort_column_changed.connect(sortColumnChanged);
		this.view.drag_begin.connect(onDragBegin);
        this.view.drag_data_get.connect(onDragDataGet);
        this.view.drag_end.connect(onDragEnd);
		this.vadjustment.value_changed.connect(viewScroll);
		lw.searchField.changed.connect(searchFieldChanged);
		lw.miller.changed.connect(searchFieldChanged);
	}
	
	public void rearrangeColumns(LinkedList<string> correctOrder) {
		view.move_column_after(view.get_column(6), view.get_column(7));
		//stdout.printf("correctOrder.length = %d, view.get_columns.length() = %d\n", correctOrder.size, (int)view.get_columns().length());
		/* iterate through view.get_columns and if a column is not in the
		 * same location as correctOrder, move it there.
		*/
		for(int index = 0; index < view.get_columns().length(); ++index) {
			//stdout.printf("on index %d column %s originally moving to %d\n", index, view.get_column(index).title, correctOrder.index_of(view.get_column(index).title));
			if(view.get_column(index).title != correctOrder.get(index)) {
				view.move_column_after(view.get_column(index), view.get_column(correctOrder.index_of(view.get_column(index).title)));
			}
		}
	}
	
	public void cellTitleEdited(string path, string new_text) {
		/*int rowid;
		stdout.printf("done!\n");
		if((rowid = music_model.getRowidFromPath(path)) != 0) {
			lm.song_from_id(rowid).title = new_text;
			
			lm.update_song(lm.song_from_id(rowid), true);
		}
		cellTitle.editable = false; */
	}
	
	public virtual void millerChanged() {
		
	}
	
	public virtual void searchFieldChanged() {
		if(is_current_view && lw.searchField.get_text().length != 1) {
			timeout_search.offer_head(lw.searchField.get_text().down());
			Timeout.add(100, () => {
				
				string to_search = timeout_search.poll_tail();
				/*Collection<int> searched_songs = lm.songs_from_search(to_search, 
																		lw.miller.genres.selected, 
																		lw.miller.artists.selected,
																		lw.miller.albums.selected,
																		_songs);
					
				if(searched_songs.size == _showing_songs.size && !needsUpdate) {
					// do nothing
				}
				else {*/
					stdout.printf("populating\n");
					populateView(_songs, true, false);
				//}
					
				last_search = to_search;
				showing_all = (_showing_songs.size == _songs.size);
				
				scrollToCurrent();
				
				lm.settings.setSearchString(to_search);
				setStatusBarText();
				
				return false;
			});
		}
	}
	
	public virtual void sortColumnChanged() {
		updateTreeViewSetup();
	}
	
#if VALA_0_14
	public virtual void modelRowsReordered(TreePath path, TreeIter? iter, void* new_order) {
#else
	public virtual void modelRowsReordered(TreePath path, TreeIter iter, void* new_order) {
#endif
		/*if(hint == "queue") {
			lm.clear_queue();
			
			TreeIter item;
			for(int i = 0; music_model.get_iter_from_string(out item, i.to_string()); ++i) {
				int id;
				music_model.get(item, 0, out id);
				
				lm.queue_song_by_id(id);
			}
		}*/
		
		if(is_current) {
			setAsCurrentList(0);
		}
		
		if(!scrolled_recently) {
			scrollToCurrent();
		}
	}
	
	public virtual void viewColumnsChanged() {
		if((int)(view.get_columns().length()) != lm.music_setup.COLUMN_COUNT)
			return;
		
		_columns.clear();
		foreach(TreeViewColumn tvc in view.get_columns()) {
			_columns.add(tvc.title);
		}
		
		updateTreeViewSetup();
	}
	
	public void intelligentTreeViewFiller(TreeViewColumn tvc, CellRenderer cell, TreeModel tree_model, TreeIter iter) {
		if(removing_songs)
			return;
		
		/** all of the # based columns. only show # if not 0 **/
		if(tvc.title == "Track" || tvc.title == "Year" || tvc.title == "#" || tvc.title == "Plays" || tvc.title == "Skips") {
			Value val;
			tree_model.get_value(iter, tvc.sort_column_id, out val);
			
			if(val.get_int() <= 0)
				((CellRendererText)cell).text = "";
			else
				((CellRendererText)cell).text = val.get_int().to_string();
		}
		else if(tvc.title == "Bitrate") {
			Value val;
			tree_model.get_value(iter, tvc.sort_column_id, out val);
			
			if(val.get_int() <= 0)
				((CellRendererText)cell).text = "";
			else
				((CellRendererText)cell).text = val.get_int().to_string() + " kbps";
		}
		else if(tvc.title == "Length") {
			Value val;
			tree_model.get_value(iter, tvc.sort_column_id, out val);
			
			if(val.get_int() <= 0)
				((CellRendererText)cell).text = "";
			else
				((CellRendererText)cell).text = (val.get_int() / 60).to_string() + ":" + (((val.get_int() % 60) >= 10) ? (val.get_int() % 60).to_string() : ("0" + (val.get_int() % 60).to_string()));
		}
		else if(tvc.title == "Date Added") {
			Value val;
			tree_model.get_value(iter, 0, out val);
			
			Song s = lm.song_from_id(val.get_int());
			
			((CellRendererText)cell).text = s.pretty_date_added();
		}
		else if(tvc.title == "Last Played") {
			Value val;
			tree_model.get_value(iter, 0, out val);
			
			Song s = lm.song_from_id(val.get_int());
			
			((CellRendererText)cell).text = s.pretty_last_played();
		}
	}
	
	public void ratingsCellDataFunction(CellLayout cell_layout, CellRenderer cell, TreeModel tree_model, TreeIter iter) {
		if(removing_songs)
			return;
		
		/*bool cursor_over = false;
		int x = 0;
		int y = 0;
		view.get_pointer(out x, out y);
		
		TreePath cPath;
		TreeViewColumn cColumn;
		int cell_x;
		int cell_y;
		
		if(view.get_path_at_pos (x,  y, out cPath, out cColumn, out cell_x, out cell_y)) {
			//stdout.printf("valid path\n");
			if(cPath.to_string() == tree_model.get_path(iter).to_string() && cColumn.title == "Rating") {
				//stdout.printf("OVER RATING------------\n");
				cursor_over = true;
			}
		}*/
		
		Value rating;
		tree_model.get_value(iter, _columns.index_of("Rating"), out rating);
		
		if(cell_layout.get_cells().index(cell) < rating.get_int()/* || (cursor_over && cell_layout.get_cells().index(cell) * 18 <= cell_x)*/)
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
	
	public void addSongs(Collection<int> songs) {
		foreach(int i in songs) {
			_songs.add(i);
		}
		
		music_model.append_songs(songs, true);
	}
	
	public void populateView(Collection<int> songs, bool is_search, bool force) {
		/** NOTE: This could have a bad effect if user coincidentally
		 * searches for something that has same number of results as 
		 * a different search. However, this cuts lots of unecessary
		 * loading of lists/icon lists */
		/*if(lw.searchField.get_text() == "" && _showing_songs.size == songs.size && hint != Hint.HISTORY && hint != Hint.QUEUE && !force) {
			return;
		}*/
		
		if(!is_search) {
			_songs = songs;
		}
		
		var potentialShowing = new LinkedList<int>();
		if(lw.searchField.get_text() == "" && lw.miller.genres.selected == "All Genres" &&
		lw.miller.artists.selected == "All Artists" && lw.miller.albums.selected == "All Albums") {
			potentialShowing.add_all(songs);
		}
		else {
			potentialShowing.add_all(lm.songs_from_search(lw.searchField.get_text(), 
												lw.miller.genres.selected, 
												lw.miller.artists.selected,
												lw.miller.albums.selected,
												_songs));
		}
		
		stdout.printf("comparing %d to %d\n", _showing_songs.size, potentialShowing.size);
		if(_showing_songs.size == potentialShowing.size && hint != Hint.HISTORY && hint != Hint.QUEUE && !force)
			return;
		else
			_showing_songs = potentialShowing;
		
		stdout.printf("populating mtv\n");
		
		view.freeze_child_notify();
		view.set_model(null);
		
		int sort_col;
		SortType sort_dir;
		music_model.get_sort_column_id(out sort_col, out sort_dir);
		
		music_model = new MusicTreeModel(lm, get_column_strings(), render_icon("audio-volume-high", IconSize.MENU, null));
		
		//save song selection
		
		music_model.append_songs(_showing_songs, false);
		
		// restore song selection
		
		music_model.set_sort_column_id(sort_col, sort_dir);
		
		if(lm.song_info.song != null)
			music_model.updateSong(lm.song_info.song.rowid, is_current);
		
		view.set_model(music_model);
		view.thaw_child_notify();
		
		scrollToCurrent();
		
		needsUpdate = false;
		setStatusBarText();
	}
	
	public virtual void current_cleared() {
		this.is_current = false;
		
		if(lm.song_info.song != null)
			music_model.updateSong(lm.song_info.song.rowid, is_current);
	}
	
	public void setAsCurrentList(int song_id) {
		bool shuffle = (lm.shuffle == LibraryManager.Shuffle.ALL);
		
		lm.clearCurrent();
		TreeIter iter;
		for(int i = 0; music_model.get_iter_from_string(out iter, i.to_string()); ++i) {
			Value id;
			music_model.get_value(iter, 0, out id);
			
			lm.addToCurrent(id.get_int());
			
			if(lm.song_info.song != null && lm.song_info.song.rowid == id.get_int() && song_id == 0)
				lm.current_index = i;
			else if(lm.song_info.song != null && song_id == id.get_int())
				lm.current_index = i;
		}
		
		is_current = true;
		
		if(lm.song_info.song != null)
			music_model.updateSong(lm.song_info.song.rowid, is_current);
			
		if(shuffle)
			lm.setShuffleMode(LibraryManager.Shuffle.ALL);
	}
	
	public virtual void song_played(int id, int old) {
		if(old != -1) {
			music_model.updateSong(old, is_current);
			music_model.turnOffPixbuf(old);
		}
		
		if(!scrolled_recently) {
			scrollToCurrent();
		}
		
		music_model.updateSong(id, is_current);
		
		if(hint == Hint.QUEUE) {
			populateView(lm.queue(), false, false);
		}
	}
	
	public virtual void playback_stopped(int was_playing) {
		if(was_playing >= 1) {
			music_model.turnOffPixbuf(was_playing);
		}
	}
	
	public virtual void songs_updated(Collection<int> ids) {
		music_model.updateSongs(ids, is_current);
		
		//since a song may have changed location, reset current
		if(is_current)
			setAsCurrentList(0);
	}
	
	public virtual void songs_removed(LinkedList<int> ids) {
		removing_songs = true;
		music_model.removeSongs(ids);
		removing_songs = false;
	}
	
	public virtual void viewDoubleClick(TreePath path, TreeViewColumn column) {
		TreeIter item;
		
		// get db's rowid of row clicked
		music_model.get_iter(out item, path);
		Value id;
		music_model.get_value(item, 0, out id);
		
		setAsCurrentList(id.get_int());
		
		// play the song
		lm.playSong(id.get_int());
		lm.player.play();
		
		if(!lm.playing) {
			lw.playClicked();
		}
	}
	
	public bool keyPressed(Gdk.EventKey event) {
		// if(is char or number)
		//lw.searchField.grab_focus();
		//lw.searchField.insert_at_cursor(event.str);
		return false;
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
			
			songMenuActionMenu.show_all();
			//little hack to avoid a glitch, remove it if you know what you are doing
			rating_item.already_drawn = false;
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
			/*else if(view.get_selection().count_selected_rows() == 1 && view.get_selection().path_is_selected(path) &&
			!(((event.state & Gdk.ModifierType.SHIFT_MASK) == Gdk.ModifierType.SHIFT_MASK)|
			((event.state & Gdk.ModifierType.CONTROL_MASK) == Gdk.ModifierType.CONTROL_MASK))) {
				/*stdout.printf("edit!\n");
				if(column.title == "Title") {
					cellTitle.editable = true;
					view.set_cursor_on_cell(path, column, cellTitle, true);
				}*
					
				return false;
			}*/
			
			if(!music_model.get_iter(out iter, path) || column.title != "Rating")
				return false;
			
			Value id;	
			int new_rating = 0;
			
			if(cell_x > 5)
				new_rating = (cell_x + 16) / 18;
			
			music_model.get_value(iter, 0, out id);
			Song s = lm.song_from_id(id.get_int());
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
			updateTreeViewSetup();
			
			return false;
		}
		
		return false;
	}
	
	public virtual void viewHeadersResized() {
		updateTreeViewSetup();
	}
	
	public virtual void columnSmartSortingClick() {
		int main_sort = _columns.index_of("#");
		
		if(hint == Hint.MUSIC || hint == Hint.SMART_PLAYLIST)
			main_sort = _columns.index_of("Artist");
		else if(hint == Hint.SIMILAR || hint == Hint.QUEUE || hint == Hint.HISTORY || hint == Hint.PLAYLIST)
			main_sort = _columns.index_of("#");
		
		sort_column = _columns.get(main_sort);
		music_model.set_sort_column_id(main_sort, Gtk.SortType.ASCENDING);
		
		if(is_current)
			setAsCurrentList(0);
	}
	
	public void updateTreeViewSetup() {
		if(music_model == null || !(music_model is TreeSortable)) {
			return;
		}
		
		TreeViewSetup tvs;
			
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
		else/* if(hint == Hint.SMART_PLAYLIST)*/
			tvs = lm.smart_playlist_from_id(relative_id).tvs;
			
		if(tvs == null)
			return;
		
		int sort_id = 7;
		SortType sort_dir = Gtk.SortType.ASCENDING;
		music_model.get_sort_column_id(out sort_id, out sort_dir);
		
		if(sort_id <= 0)
			sort_id = 7;
		
		sort_column = _columns.get(sort_id);
		sort_direction = sort_dir;
		
		tvs.set_columns(get_columns());
		tvs.sort_column = _columns.get(sort_id);
		tvs.sort_direction = sort_dir;
		
		if(!playlistSaveTimeoutAdded) {
			playlistSaveTimeoutAdded = true;
			Timeout.add(2000, () => {
				lm.save_playlists(); 
				playlistSaveTimeoutAdded = false;
				
				return false; 
			});
		}
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
		
		SongEditor se = new SongEditor(lw, to_edit, lm.get_track(lastfmStuff.get("track")), 
										lm.get_artist(lastfmStuff.get("artist")), 
										lm.get_album(lastfmStuff.get("album")));
		se.songs_saved.connect(songEditorSaved);
	}
	
	public virtual void songEditorSaved(LinkedList<Song> songs) {
		lm.update_songs(songs, true);
		
		if(hint == Hint.SMART_PLAYLIST) {
			// make sure these songs still belongs here
		}
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
				Gtk.show_uri(null, file.get_parent().get_uri(), 0);
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
			music_model.get_iter(out item, path);
			
			Value id;
			music_model.get_value(item, 0, out id);
			
			p.addSong(lm.song_from_id(id.get_int()));
		}
		
		PlaylistNameWindow pnw = new PlaylistNameWindow(lw, p);
		pnw.playlist_saved.connect( (newP) => { 
			lm.add_playlist(p);
			lw.addSideListItem(p); 
		});
	}
	
	public virtual void songRemoveClicked() {
		TreeSelection selected = view.get_selection();
		selected.set_mode(SelectionMode.MULTIPLE);
		
		LinkedList<Song> toRemove = new LinkedList<Song>();
		LinkedList<int> toRemoveIDs = new LinkedList<int>();
		TreeModel temp;
		
		foreach(TreePath path in selected.get_selected_rows(out temp)) {
			TreeIter item;
			temp.get_iter(out item, path);
			
			int id;
			temp.get(item, 0, out id);
			Song s = lm.song_from_id(id);
			
			toRemoveIDs.add(id);
			
			if(hint == Hint.QUEUE) {
				lm.unqueue_song_by_id(s.rowid);
			}
			else if(hint == Hint.PLAYLIST) {
				lm.playlist_from_id(relative_id).removeSong(s);
			}
			else if(hint == Hint.MUSIC) {
				toRemove.add(s);
			}
		}
		
		if(hint == Hint.MUSIC)
			lm.remove_songs(toRemove);
		if(hint == Hint.PLAYLIST)
			lm.save_playlists();
		else if(hint == Hint.QUEUE)
			lm.save_playlists();
			
		music_model.removeSongs(toRemoveIDs);
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
			
			s.rating = rating_item.rating_value;
			los.add(s);
		}
		
		lm.update_songs(los, false);
	}
	
	public void update_rating_menu() {
		TreeSelection selected = view.get_selection();
		selected.set_mode(SelectionMode.MULTIPLE);
		TreeModel l_model;

		foreach(TreePath path in selected.get_selected_rows(out l_model)) {
			TreeIter item;
			l_model.get_iter(out item, path);
			
			int id;
			l_model.get(item, 0, out id);
			Song s = lm.song_from_id(id);
			
			rating_item.rating_value = s.rating;
		}
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
		for(int i = 0; music_model.get_iter_from_string(out iter, i.to_string()); ++i) {
			Value id;
			music_model.get_value(iter, 0, out id);

			if(id.get_int() == lm.song_info.song.rowid) {
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
		lw.dragging_from_music = true;
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
		lw.dragging_from_music = false;
		
		stdout.printf("drag end\n");
		
		//unset_rows_drag_dest();
		Gtk.drag_dest_set(this,
		                  Gtk.DestDefaults.ALL,
		                  {},
		                  Gdk.DragAction.COPY|
		                  Gdk.DragAction.MOVE
		                  );
	}
	
	public void setStatusBarText() {
		if(is_current_view) {
			int count = 0;
			int total_time = 0;
			int total_mbs = 0;
			
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
			
			lw.setStatusBarText(count.to_string() + " items, " + fancy + ", " + fancy_size);
		}
	}
}
