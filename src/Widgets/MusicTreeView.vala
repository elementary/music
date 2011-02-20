using Gee;
using Gtk;

public class BeatBox.MusicTreeView : ScrolledWindow {
	private BeatBox.LibraryManager lm;
	private BeatBox.LibraryWindow lw;
	private TreeView view;
	private ListStore model;
	
	private HashMap<int, TreeRowReference> _rows;
	private LinkedList<string> _columns;
	
	public int relative_id;// if playlist, playlist id, etc.
	public string hint; // playlist, queue, smart_playlist, etc. changes how it behaves.
	int sort_id;
	
	bool is_current_view;
	bool is_current;
	
	//for header column chooser
	Menu columnChooserMenu;
	MenuItem columnTurnOffSorting;
	MenuItem columnSmartSorting;
	CheckMenuItem columnNumber;// new
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
	CheckMenuItem columnDateAdded;
	CheckMenuItem columnLastPlayed;
	CheckMenuItem columnBPM;
	CheckMenuItem columnFilePath;
	CheckMenuItem columnFileSize;
	//for song list right click
	Menu songMenuActionMenu;
	MenuItem songEditSong;
	MenuItem songMenuQueue;
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
	
	public Set<int> get_songs() {
		return _rows.keys;
	}
	
	public GLib.List<TreeViewColumn> get_columns() {
		return view.get_columns();
	}
	
	/**
	 * for sort_id use 0+ for normal, -1 for auto, -2 for none
	 */
	public MusicTreeView(BeatBox.LibraryManager lmm, BeatBox.LibraryWindow lww, int sort) {
		lm = lmm;
		lw = lww;
		
		_rows = new HashMap<int, TreeRowReference>();
		_columns = new LinkedList<string>();
		
		sort_id = sort;
		
		//generate star pixbuf
		starred = this.render_icon("starred", IconSize.MENU, null);
		not_starred = this.render_icon("not-starred", IconSize.MENU, null);
		
		lm.songs_updated.connect(songs_updated);
		lm.song_played.connect(song_played);
		lm.current_cleared.connect(current_cleared);
		
		buildUI();
		
		//initialize rows
		viewColumnsChanged();
	}
	
	public void set_hint(string the_hint) {
		hint = the_hint;
		updateSensitivities();
	}
	
	public void set_id(int id) {
		relative_id = id;
	}
	
	public void updateSensitivities() {
		if(hint == "collection") {
			songRemove.set_sensitive(false);
		}
		else if(hint == "queue") {
			songRemove.set_sensitive(true);
			songRemove.set_label("Remove from Queue");
			columnNumber.active = true;
			columnTrack.active = false;
		}
		else if(hint == "already played") {
			songRemove.set_sensitive(false);
			columnNumber.active = true;
			columnTrack.active = false;
		}
		else if(hint == "playlist") {
			songRemove.set_sensitive(true);
			columnNumber.active = true;
			columnTrack.active = false;
		}
		else if(hint == "smart playlist") {
			songRemove.set_sensitive(false);
			columnNumber.active = false;
			columnTrack.active = true;
		}
		else {
			songRemove.set_sensitive(false);
		}
		
		updateColumnVisibilities();
	}
	
	public void buildUI() {
		view = new TreeView();
		
		/* id is always first and is stored as an int. Then the rest are (1)
		 * strings (for simplicity), and include:
		 * #, track, title, artist, album, genre, comment, year, rating, (9)
		 * bitrate, play count, last played, date added, file name, (5)
		 * bpm, length, file size, (3) */
		int index = 0;
		foreach(TreeViewColumn tvc in lm.fresh_columns()) {
			if(tvc.title == "Bitrate" || tvc.title == "#" || tvc.title == "Year" || tvc.title == "Track" || tvc.title == "Playcount") {
				view.insert_column_with_data_func(-1, tvc.title, new CellRendererText(), intelligentTreeViewFiller);
				
				view.get_column(index).resizable = true;
				view.get_column(index).reorderable = true;
				view.get_column(index).clickable = true;
				view.get_column(index).sort_column_id = index;
				view.get_column(index).set_sort_indicator(false);
				view.get_column(index).visible = tvc.visible;
				view.get_column(index).sizing = Gtk.TreeViewColumnSizing.FIXED;
				view.get_column(index).fixed_width = tvc.fixed_width;
			}
			else if(tvc.title == "Rating") {
				view.insert_column(tvc, index);
				tvc.resizable = false;
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
		
		model = new ListStore.newv(getColumnTypes());
		
		//if(sort_id >= 0)
			//model.set_sort_column_id(sort_id, Gtk.SortType.ASCENDING);
		
		view.set_model(model);
		view.set_reorderable(true);
		view.set_headers_clickable(true);
		
		view.row_activated.connect(viewDoubleClick);
		view.button_press_event.connect(viewClick);
		view.columns_changed.connect(viewColumnsChanged);
		
		// allow selecting multiple rows
		view.get_selection().set_mode(SelectionMode.MULTIPLE);
		
		// column chooser menu
		columnChooserMenu = new Menu();
		columnTurnOffSorting = new MenuItem.with_label("Turn off sorting");
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
		columnPlayCount = new CheckMenuItem.with_label("Playcount");
		columnDateAdded = new CheckMenuItem.with_label("Date Added");
		columnLastPlayed = new CheckMenuItem.with_label("Last Played");
		columnBPM = new CheckMenuItem.with_label("BPM");
		columnFilePath= new CheckMenuItem.with_label("File Path");
		columnFileSize = new CheckMenuItem.with_label("File Size");
		updateColumnVisibilities();
		columnChooserMenu.append(columnTurnOffSorting);
		columnChooserMenu.append(columnSmartSorting);
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
		columnChooserMenu.append(columnDateAdded);
		columnChooserMenu.append(columnLastPlayed);
		columnChooserMenu.append(columnBPM);
		columnChooserMenu.append(columnFilePath);
		columnChooserMenu.append(columnFileSize);
		columnTurnOffSorting.activate.connect(columnTurnOffSortingClick);
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
		columnDateAdded.toggled.connect(columnMenuToggled);
		columnLastPlayed.toggled.connect(columnMenuToggled);
		columnBPM.toggled.connect(columnMenuToggled);
		columnFilePath.toggled.connect(columnMenuToggled);
		columnFileSize.toggled.connect(columnMenuToggled);
		columnChooserMenu.show_all();
		
		
		//song list right click menu
		songMenuActionMenu = new Menu();
		songEditSong = new MenuItem.with_label("Edit Song Info");
		songMenuQueue = new MenuItem.with_label("Queue");
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
		songMenuActionMenu.append(songMenuQueue);
		songMenuActionMenu.append(songRemove);
		songRateSongMenu.append(songRateSong0);
		songRateSongMenu.append(songRateSong1);
		songRateSongMenu.append(songRateSong2);
		songRateSongMenu.append(songRateSong3);
		songRateSongMenu.append(songRateSong4);
		songRateSongMenu.append(songRateSong5);
		songMenuActionMenu.append(songRateSong);
		songRateSong.submenu = songRateSongMenu;
		songEditSong.activate.connect(songMenuEditClicked);
		songMenuQueue.activate.connect(songMenuQueueClicked);
		songRemove.activate.connect(songRemoveClicked);
		songRateSong0.activate.connect(songRateSong0Clicked);
		songRateSong1.activate.connect(songRateSong1Clicked);
		songRateSong2.activate.connect(songRateSong2Clicked);
		songRateSong3.activate.connect(songRateSong3Clicked);
		songRateSong4.activate.connect(songRateSong4Clicked);
		songRateSong5.activate.connect(songRateSong5Clicked);
		songMenuActionMenu.show_all();
		
		this.set_policy(PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
		
		this.add(view);
	}
	
	public virtual void viewColumnsChanged() {
		_columns.clear();
		foreach(TreeViewColumn tvc in view.get_columns()) {
			_columns.add(tvc.title);
		}
	}
	
	public void intelligentTreeViewFiller(TreeViewColumn tvc, CellRenderer cell, TreeModel tree_model, TreeIter iter) {
		/** all of the # based columns. only show # if not 0 **/
		if(tvc.title == "#") {
			int val;
			tree_model.get(iter, tvc.sort_column_id, out val);
			
			if(val <= 0)
				((CellRendererText)cell).text = "";
			else
				((CellRendererText)cell).text = val.to_string();
		}
		else if(tvc.title == "Track") {
			int val;
			tree_model.get(iter, tvc.sort_column_id, out val);
			
			if(val <= 0)
				((CellRendererText)cell).text = "";
			else
				((CellRendererText)cell).text = val.to_string();
		}
		else if(tvc.title == "Year") {
			int val;
			tree_model.get(iter, tvc.sort_column_id, out val);
			
			if(val <= 0)
				((CellRendererText)cell).text = "";
			else
				((CellRendererText)cell).text = val.to_string();
		}
		else if(tvc.title == "Playcount") {
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
		int id = 0;
		tree_model.get(iter, 0, out id);
		
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
		}
		*/
		if(cell_layout.get_cells().index(cell) < lm.song_from_id(id).rating/* || (cursor_over && cell_layout.get_cells().index(cell) * 18 <= cell_x)*/)
			((CellRendererPixbuf)cell).pixbuf = starred;
		else if(view.get_selection().iter_is_selected(iter))
			((CellRendererPixbuf)cell).pixbuf = not_starred;
		else
			((CellRendererPixbuf)cell).pixbuf = null;
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
			else if(tvc.title == "Playcount")
				columnPlayCount.active = view.get_column(index).visible;
			else if(tvc.title == "Date Added")
				columnDateAdded.active = view.get_column(index).visible;
			else if(tvc.title == "Last Played")
				columnLastPlayed.active = view.get_column(index).visible;
			else if(tvc.title == "BPM")
				columnBPM.active = view.get_column(index).visible;
			else if(tvc.title == "File Path")
				columnFilePath.active = view.get_column(index).visible;
			else if(tvc.title == "File Size")
				columnFileSize.active = view.get_column(index).visible;
			
			++index;
		}
	}
	
	public Type[] getColumnTypes() {
		Type[] types = new Type[18];
		
		int index = 0;
		foreach(TreeViewColumn tvc in view.get_columns()) {
			if(tvc.title == "id")
				types[index] = typeof(int);
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
			else if(tvc.title == "Playcount")
				types[index] = typeof(int);
			else if(tvc.title == "Date Added")
				types[index] = typeof(string);
			else if(tvc.title == "Last Played")
				types[index] = typeof(string);
			else if(tvc.title == "BPM")
				types[index] = typeof(int);
			else if(tvc.title == "File Path")
				types[index] = typeof(string);
			else if(tvc.title == "File Size")
				types[index] = typeof(int);
			
			++index;
		}
		
		//this.model.set_column_types(types);
		
		return types;
	}
	
	public void populateView(Collection<int> songs, bool is_search) {
		view.freeze_child_notify();
		Gtk.SortType sort_type;
		int temp_sort_id;
		model.get_sort_column_id(out temp_sort_id, out sort_type);
		model.set_sort_column_id(-2, Gtk.SortType.ASCENDING);
		
		if(!is_search) {
			this._rows.clear();
		}
		
		//get selected songs and put in temp array
		
		model.clear();
		int index = 0;
		foreach(int i in songs) {
			TreeIter iter = addSong(lm.song_from_id(i));
			
			if(!is_search)
				_rows.set(i, new TreeRowReference(model, model.get_path(iter)));
			
			++index;
		}
		
		//reselect songs that were selected before populateview update
		
		if(temp_sort_id >= 0 || sort_id == -1) {
			int track_id = 0;
			int album_id = 0;
			int main_sort = 0;
			
			index = 0;
			foreach(TreeViewColumn tvc in view.get_columns()) {
				if(tvc.title == "Track")
					track_id = index;
				else if(tvc.title == "Album")
					album_id = index;
				
				if(hint == "music" && sort_id == -1 && tvc.title == "Artist")
					main_sort = index;
				else if(hint == "similar" && sort_id == -1 && tvc.title == "#")
					main_sort = index;
				else if(hint == "queue" && sort_id == -1 && tvc.title == "#")
					main_sort = index;
				else if(hint == "history" && sort_id == -1 && tvc.title == "#")
					main_sort = index;
				else if(hint == "playlist" && sort_id == -1 && tvc.title == "#")
					main_sort = index;
				else if(hint == "smart playlist" && sort_id == -1 && tvc.title == "Artist")
					main_sort = index; // in future, observe smart playlist values to make decision
				
				++index;
			}
			
			model.set_sort_column_id(track_id, sort_type);
			model.set_sort_column_id(album_id, sort_type);
			model.set_sort_column_id(main_sort, sort_type);
		}
		
		view.thaw_child_notify();
	}
	
	public TreeIter? addSong(Song s) {
		TreeIter item;
		model.append(out item);
		
		int index = 0;
		foreach(TreeViewColumn tvc in view.get_columns()) {
			if(tvc.title == "id")
				model.set_value(item, index, s.rowid);
			if(tvc.title == " " && lm.song_info.song != null && s.rowid == lm.song_info.song.rowid)
				this.model.set_value(item, index, view.render_icon(Gtk.Stock.MEDIA_PLAY, IconSize.MENU, null));
			else if(tvc.title == "#")
				model.set_value(item, index, (model.get_path(item).to_string().to_int() + 1));
			else if(tvc.title == "Track" && s.track != 0)
				model.set_value(item, index, s.track);
			else if(tvc.title == "Title")
				model.set_value(item, index, s.title);
			else if(tvc.title == "Length")
				model.set_value(item, index, s.pretty_length());
			else if(tvc.title == "Artist")
				model.set_value(item, index, s.artist);
			else if(tvc.title == "Album")
				model.set_value(item, index, s.album);
			else if(tvc.title == "Genre")
				model.set_value(item, index, s.genre);
			else if(tvc.title == "Year")
				model.set_value(item, index, s.year);
			else if(tvc.title == "Bitrate" && s.bitrate != 0)
				model.set_value(item, index, s.bitrate);
			else if(tvc.title == "Rating")
				model.set_value(item, index, s.rating);
			else if(tvc.title == "Playcount" && s.play_count != 0)
				model.set_value(item, index, s.play_count);
			else if(tvc.title == "Date Added")
				model.set_value(item, index, s.pretty_date_added());
			else if(tvc.title == "Last Played")
				model.set_value(item, index, ((s.last_played != 0) ? s.pretty_last_played() : ""));
			else if(tvc.title == "BPM" && s.bpm != 0)
				model.set_value(item, index, s.bpm);
			else if(tvc.title == "File Name")
				model.set_value(item, index, s.file_name);
			else if(tvc.title == "File Size")
				model.set_value(item, index, s.file_size);
			
			++index;
		}
		
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
								_columns.index_of(" "), (lm.song_info.song != null && i == lm.song_info.song.rowid && is_current) ? view.render_icon(Gtk.Stock.MEDIA_PLAY, IconSize.MENU, null) : null,
								_columns.index_of("#"), (path.to_string().to_int() + 1),
								_columns.index_of("Track"), s.track,
								_columns.index_of("Title"), s.title,
								_columns.index_of("Length"), s.pretty_length(),
								_columns.index_of("Artist"), s.artist,
								_columns.index_of("Album"), s.album,
								_columns.index_of("Genre"), s.genre,
								_columns.index_of("Year"), s.year,
								_columns.index_of("Bitrate"), s.bitrate,
								_columns.index_of("Rating"), s.rating,
								_columns.index_of("Playcount"), s.play_count,
								_columns.index_of("Date Added"), s.pretty_date_added(),
								_columns.index_of("Last Played"), s.pretty_last_played(),
								_columns.index_of("BPM"), s.bpm,
								_columns.index_of("File Name"), s.file_name,
								_columns.index_of("File Size"), s.file_size);
		
		return true;
	}
	
	public virtual void current_cleared() {
		this.is_current = false;
		
		if(lm.song_info.song != null)
			updateSong(lm.song_info.song.rowid);
	}
	
	public virtual void song_played(int id, int old) {
		updateSong(old);
		updateSong(id);
	}
	
	public virtual void songs_updated(Collection<int> ids) {
		foreach(int id in ids) {
			updateSong(id);
		}
	}
	
	public virtual void song_removed(int id) {
		//this is when song is removed from entire library. search and remove
		//if in our treeview
	}
	
	public virtual void viewDoubleClick(TreePath path, TreeViewColumn column) {
		TreeIter item;
		
		setAsCurrentList(path.to_string());
		
		if(lm.is_shuffled())
			lm.shuffleMusic();
		
		// get db's rowid of row clicked
		model.get_iter(out item, path);
		int id;
		model.get(item, 0, out id);
		
		// play the song
		lm.playSong(id);
		lm.player.play_stream();
		
		if(!lm.playing) {
			lw.playClicked();
		}
	}
	
	public void setAsCurrentList(string current_song_path) {
		lm.current_index = current_song_path.to_int();
		lm.clearCurrent();
		foreach(int i in _rows.keys)
			lm.addToCurrent(i);
		
		is_current = true;
		
		if(lm.song_info.song != null)
			updateSong(lm.song_info.song.rowid);
	}
	
	public virtual bool viewClick(Gdk.EventButton event) {
		if(event.type == Gdk.EventType.BUTTON_PRESS && event.button == 3) { //right click
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
			
			if(!model.get_iter(out iter, path) || column.title != "Rating")
				return false;
			
			int id = 0;	
			int new_rating = 0;
			
			if(cell_x > 5)
				new_rating = (cell_x + 18) / 18;
			
			model.get(iter, 0, out id);
			Song s = lm.song_from_id(id);
			s.rating = new_rating;
			
			model.set(iter, column.sort_column_id, new_rating);
			
			lm.update_song(s, false);
		}
		
		return false;
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
	
	public virtual void columnTurnOffSortingClick() {
		model.set_sort_column_id(-2, Gtk.SortType.ASCENDING);
		sort_id = -2;
		
		var the_songs = new LinkedList<int>();
		foreach(int i in this._rows.keys) {
			the_songs.add(i);
		}
		
		populateView(the_songs, false);
	}
	
	public virtual void columnSmartSortingClick() {
		sort_id = -1;
		
		var the_songs = new LinkedList<int>();
		foreach(int i in this._rows.keys) {
			the_songs.add(i);
		}
		
		populateView(the_songs, false);
	}
	
	/** When the column chooser popup menu has a change/toggle **/
	public virtual void columnMenuToggled() {
		int index = 0;
		foreach(TreeViewColumn tvc in view.get_columns()) {
			if(tvc.title == "#")
				view.get_column(index).visible = columnNumber.active;
			else if(tvc.title == "Track")
				view.get_column(index).visible = columnTrack.active;
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
			else if(tvc.title == "Playcount")
				view.get_column(index).visible = columnPlayCount.active;
			else if(tvc.title == "Date Added")
				view.get_column(index).visible = columnDateAdded.active;
			else if(tvc.title == "Last Played")
				view.get_column(index).visible = columnLastPlayed.active;//add bpm, file size, file path
			else if(tvc.title == "BPM")
				view.get_column(index).visible = columnBPM.active;
			else if(tvc.title == "File Path")
				view.get_column(index).visible = columnFilePath.active;
			else if(tvc.title == "File Size")
				view.get_column(index).visible = columnFileSize.active;
			
			++index;
		}
	}
	
	/** song menu popup clicks **/
	public virtual void songMenuEditClicked() {
		TreeSelection selected = view.get_selection();
		selected.set_mode(SelectionMode.MULTIPLE);
		TreeModel model;
		
		HashMap<string, string> lastfmStuff = new HashMap<string, string>();
		
		//tempSongs.clear();
		var to_edit = new LinkedList<Song>();
		foreach(TreePath path in selected.get_selected_rows(out model)) {
			TreeIter item;
			model.get_iter(out item, path);
			
			int id;
			model.get(item, 0, out id);
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
	
	public virtual void songRemoveClicked() {
		TreeSelection selected = view.get_selection();
		selected.set_mode(SelectionMode.MULTIPLE);
		TreeModel l_model;
		
		/* reverse list of selected rows so when we remove multiple rows
		 * our treepaths aren't messed up
		 */
		GLib.List<TreePath> paths = new GLib.List<TreePath>();
		foreach(TreePath path in selected.get_selected_rows(out l_model)) {
			paths.prepend(path);
		}
		
		foreach(TreePath path in paths) {
			TreeIter item;
			model.get_iter(out item, path);
			
			int id;
			model.get(item, 0, out id);
			Song s = lm.song_from_id(id);
			
			if(hint == "queue") {
				lm.unqueue_song_by_id(s.rowid);
				model.remove(item);
				_rows.unset(id);
			}
			else if(hint == "playlist") {
				lm.playlist_from_id(relative_id).removeSong(s);
				model.remove(item);
				_rows.unset(id);
			}
			else if(hint == "collection") {
				lm.remove_song_from_id(s.rowid);
				model.remove(item);
				_rows.unset(id);
				
				//should prompt user about being sure about this and annoy them
				try {
					var file = File.new_for_path(s.file);
					file.trash();
				}
				catch(GLib.Error err) {
					stdout.printf("Could not move file %s to trash: %s\n", s.file, err.message);
				}
			}
			
			//must somehow update all other views if removed from collection
		}
	}
	
	public virtual void songRateSong0Clicked() {
		TreeSelection selected = view.get_selection();
		selected.set_mode(SelectionMode.MULTIPLE);
		TreeModel l_model;
		
		var los = new LinkedList<Song>();
		foreach(TreePath path in selected.get_selected_rows(out l_model)) {
			TreeIter item;
			model.get_iter(out item, path);
			
			int id;
			model.get(item, 0, out id);
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
			model.get_iter(out item, path);
			
			int id;
			model.get(item, 0, out id);
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
			model.get_iter(out item, path);
			
			int id;
			model.get(item, 0, out id);
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
			model.get_iter(out item, path);
			
			int id;
			model.get(item, 0, out id);
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
			model.get_iter(out item, path);
			
			int id;
			model.get(item, 0, out id);
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
			model.get_iter(out item, path);
			
			int id;
			model.get(item, 0, out id);
			Song s = lm.song_from_id(id);
			
			s.rating = 5;
			los.add(s);
		}
		
		lm.update_songs(los, false);
	}
}
