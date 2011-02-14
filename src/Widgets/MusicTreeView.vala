using Gee;
using Gtk;

public class BeatBox.MusicTreeView : ScrolledWindow {
	private BeatBox.LibraryManager lm;
	private BeatBox.LibraryWindow lw;
	private TreeView view;
	private ListStore model;
	private LinkedList<int> songs;
	private LinkedList<int> tempSongs;
	private Song current_song;
	private TreePath current_path;
	
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
	CheckMenuItem columnComment;// new
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
	MenuItem songMenuPsychic;
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
	
	public LinkedList<int> get_songs() {
		return songs;
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
		this.songs = new LinkedList<int>();
		this.tempSongs = new LinkedList<int>();
		this.sort_id = sort;
		
		//generate star pixbuf
		starred = this.render_icon("starred", IconSize.MENU, null);
		not_starred = this.render_icon("not-starred", IconSize.MENU, null);
		
		lm.song_updated.connect(song_updated);
		lm.song_played.connect(song_played);
		lm.current_cleared.connect(current_cleared);
		buildUI();
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
			if(tvc.title != "Rating" && tvc.title != " ")
				view.insert_column_with_data_func(-1, tvc.title, new CellRendererText(), intelligentTreeViewFiller);
			else
				view.insert_column_with_data_func(-1, tvc.title, new CellRendererPixbuf(), intelligentTreeViewFiller);
				
			if(view.get_column(index).title == "Rating") {
				view.get_column(index).clear();
				
				for(int i = 0; i <=4; ++i) {
					var cell = new CellRendererPixbuf();
					view.get_column(index).pack_start(cell, false);
					view.get_column(index).set_cell_data_func(cell, ratingsCellDataFunction);
				}
			}
			
			view.get_column(index).resizable = true;
			view.get_column(index).reorderable = true;
			view.get_column(index).clickable = true;
			view.get_column(index).sort_column_id = index;
			view.get_column(index).set_sort_indicator(false);
			view.get_column(index).visible = tvc.visible;
			view.get_column(index).sizing = Gtk.TreeViewColumnSizing.FIXED;
			view.get_column(index).fixed_width = tvc.fixed_width;
			
			// add this widget crap so we can get right clicks
			//tvc.visible = column_visibilities.get(index);
			view.get_column(index).widget = new Gtk.Label(tvc.title);
			view.get_column(index).widget.show();
			view.get_column(index).set_sort_indicator(false);
			Gtk.Widget ancestor = view.get_column(index).widget.get_ancestor(typeof(Gtk.Button));
			GLib.assert(ancestor != null);
			
			ancestor.button_press_event.connect(viewHeaderClick);
			
			++index;
		}
		
		model = new ListStore.newv(getColumnTypes());
		
		if(sort_id >= 0)
			model.set_sort_column_id(sort_id, Gtk.SortType.ASCENDING);
		
		view.set_model(model);
		view.set_reorderable(true);
		view.set_headers_clickable(true);
		view.set_enable_search(true);
		
		view.row_activated.connect(viewDoubleClick);
		view.button_press_event.connect(viewClick);
		view.key_press_event.connect( (type) => {
			view_being_searched(type.str);
			return false;
		});
		
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
		columnComment = new CheckMenuItem.with_label("Comment");
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
		columnChooserMenu.append(columnComment);
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
		columnComment.toggled.connect(columnMenuToggled);
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
		songMenuPsychic = new MenuItem.with_label("Use Psychic");
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
		songMenuActionMenu.append(songMenuPsychic);
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
		//songMenuPsychic.activate.connect(songMenuPsychicClicked);
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
		else if(tvc.title == " ") {
			int id;
			tree_model.get(iter, 0, out id);
			
			if(lm.song_info.song != null && lm.song_info.song.rowid == id && is_current)
				((CellRendererPixbuf)cell).pixbuf = this.render_icon("folder-music", IconSize.MENU, null);
			else
				((CellRendererPixbuf)cell).pixbuf = null;
		}
		else if(tree_model.get_column_type(tvc.sort_column_id) == typeof(string)) { // all other columns
			string val;
			tree_model.get(iter, tvc.sort_column_id, out val);
			
			((CellRendererText)cell).text = val;
		}
	}
	
	public void ratingsCellDataFunction(CellLayout cell_layout, CellRenderer cell, TreeModel tree_model, TreeIter iter) {
		int id = 0;
		tree_model.get(iter, 0, out id);
		
		if(cell_layout.get_cells().index(cell) < lm.song_from_id(id).rating)
			((CellRendererPixbuf)cell).pixbuf = starred;
		else
			((CellRendererPixbuf)cell).pixbuf = not_starred;
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
			else if(tvc.title == "Comment")
				columnComment.active = view.get_column(index).visible;
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
		Type[] types = new Type[19];
		
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
			else if(tvc.title == "Comment")
				types[index] = typeof(string);
			else if(tvc.title == "Year")
				types[index] = typeof(string);
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
			this.songs.clear();
		}
		
		//get selected songs and put in temp array
		
		model.clear();
		int index = 0;
		foreach(int i in songs) {
			if(!is_search)
				this.songs.add(i);
			
			addSong(lm.song_from_id(i));
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
			else if(tvc.title == "Comment")
				model.set_value(item, index, s.comment);
			else if(tvc.title == "Year" && s.year != 0)
				model.set_value(item, index, ((s.year != 0) ? s.year.to_string() : ""));
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
	
	public bool updateCurrentSong() {
		int index = 0;
		TreeIter item;
		if(!model.get_iter_from_string(out item, current_path.to_string()))
			return false;
		
		foreach(TreeViewColumn tvc in view.get_columns()) {
			if(tvc.title == "id")
				model.set_value(item, index, current_song.rowid);
			/*else if(tvc.title == "#")
				model.set_value(item, index, (model.get_path(item).to_string().to_int() + 1).to_string());*/
			else if(tvc.title == "Track")
				model.set_value(item, index, current_song.track.to_string());
			else if(tvc.title == "Title")
				model.set_value(item, index, current_song.title);
			else if(tvc.title == "Length")
				model.set_value(item, index, current_song.pretty_length());
			else if(tvc.title == "Artist")
				model.set_value(item, index, current_song.artist);
			else if(tvc.title == "Album")
				model.set_value(item, index, current_song.album);
			else if(tvc.title == "Genre")
				model.set_value(item, index, current_song.genre);
			else if(tvc.title == "Comment")
				model.set_value(item, index, current_song.comment);
			else if(tvc.title == "Year")
				model.set_value(item, index, ((current_song.year != 0) ? current_song.year.to_string() : ""));
			else if(tvc.title == "Bitrate")
				model.set_value(item, index, current_song.bitrate.to_string());
			else if(tvc.title == "Rating")
				model.set_value(item, index, current_song.rating.to_string());
			else if(tvc.title == "Playcount")
				model.set_value(item, index, ((current_song.play_count > 0) ? current_song.play_count.to_string() : ""));
			else if(tvc.title == "Date Added")
				model.set_value(item, index, current_song.pretty_date_added());
			else if(tvc.title == "Last Played")
				model.set_value(item, index, ((current_song.last_played != 0) ? current_song.pretty_last_played() : ""));
			else if(tvc.title == "BPM")
				model.set_value(item, index, current_song.bpm.to_string());
			else if(tvc.title == "File Name")
				model.set_value(item, index, current_song.file_name);
			else if(tvc.title == "File Size")
				model.set_value(item, index, current_song.file_size.to_string());
			
			++index;
		}
		
		return false;
	}
	
	public bool updateTempSongs(TreeModel model, TreePath path, TreeIter item) {
		int id;
		this.model.get(item, 0, out id);
		
		if(tempSongs.contains(id)) {
			Song s = lm.song_from_id(id);
			
			int index = 0;
			foreach(TreeViewColumn tvc in view.get_columns()) {
				if(tvc.title == "id")
					this.model.set_value(item, index, s.rowid);
				if(tvc.title == " " && lm.song_info.song != null && id == lm.song_info.song.rowid)
					this.model.set_value(item, index, view.render_icon(Gtk.Stock.MEDIA_PLAY, IconSize.MENU, null));
				else if(tvc.title == "Track")
					this.model.set_value(item, index, s.track);
				else if(tvc.title == "Title")
					this.model.set_value(item, index, s.title);
				else if(tvc.title == "Length")
					this.model.set_value(item, index, s.pretty_length());
				else if(tvc.title == "Artist")
					this.model.set_value(item, index, s.artist);
				else if(tvc.title == "Album")
					this.model.set_value(item, index, s.album);
				else if(tvc.title == "Genre")
					this.model.set_value(item, index, s.genre);
				else if(tvc.title == "Comment")
					this.model.set_value(item, index, s.comment);
				else if(tvc.title == "Year")
					this.model.set_value(item, index, ((s.year != 0) ? s.year.to_string() : ""));
				else if(tvc.title == "Bitrate")
					this.model.set_value(item, index, s.bitrate);
				else if(tvc.title == "Rating")
					this.model.set_value(item, index, s.rating);
				else if(tvc.title == "Playcount")
					this.model.set_value(item, index, s.play_count);
				else if(tvc.title == "Date Added")
					this.model.set_value(item, index, s.pretty_date_added());
				else if(tvc.title == "Last Played")
					this.model.set_value(item, index, ((s.last_played != 0) ? s.pretty_last_played() : ""));
				else if(tvc.title == "BPM")
					this.model.set_value(item, index, s.bpm);
				else if(tvc.title == "File Name")
					this.model.set_value(item, index, s.file_name);
				else if(tvc.title == "File Size")
					this.model.set_value(item, index, s.file_size);
				
				++index;
			}
		}
		
		return false;
	}
	
	public virtual void current_cleared() {
		this.is_current = false;
	}
	
	public bool updatePlayingIcon(TreeModel model, TreePath path, TreeIter iter) {
		int id;
		model.get(iter, 0, out id);
		Gdk.Pixbuf? old_pix;
		model.get(iter, 1, out old_pix);
		
		int index = 0;
		foreach(TreeViewColumn tvc in view.get_columns()) {
			if(tvc.title == " ") {
				if(id == lm.song_info.song.rowid && is_current)
					this.model.set_value(iter, index, view.render_icon(Gtk.Stock.MEDIA_PLAY, IconSize.MENU, null));
				else
					this.model.set(iter, index, null);
			}
				
			++index;
		}
		
		return false;
	}
	
	public virtual void song_played(int id) {
		model.foreach(updatePlayingIcon);
	}
	
	public virtual void song_updated(int id) {
		tempSongs.clear();
		tempSongs.add(id);
	}
	
	public virtual void song_removed(int id) {
		
	}
	
	public virtual void viewDoubleClick(TreePath path, TreeViewColumn column) {
		TreeIter item;
		
		current_path = path;
		lm.current_index = current_path.to_string().to_int();
		lm.clearCurrent();
		is_current = true;
		model.foreach(buildCurrentList);
		
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
		current_path = new TreePath.from_string(current_song_path);
		lm.current_index = current_song_path.to_int();
		lm.clearCurrent();
		model.foreach(buildCurrentList);
	}
	
	public bool buildCurrentList(TreeModel model, TreePath path, TreeIter iter) {
		TreeIter item;
		model.get_iter(out item, path);
		
		int id;
		model.get(item, 0, out id);
		
		lm.addToCurrent(id);
		return false;
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
		foreach(int i in this.songs) {
			the_songs.add(i);
		}
		
		populateView(the_songs, false);
	}
	
	public virtual void columnSmartSortingClick() {
		sort_id = -1;
		
		var the_songs = new LinkedList<int>();
		foreach(int i in this.songs) {
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
			else if(tvc.title == "Comment")
				view.get_column(index).visible = columnComment.active;
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
		
		tempSongs.clear();
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
			tempSongs.add(id);
		}
		
		SongEditor se = new SongEditor(to_edit, lm.get_track(lastfmStuff.get("track")), 
										lm.get_artist(lastfmStuff.get("artist")), 
										lm.get_album(lastfmStuff.get("album")));
		se.songs_saved.connect(songEditorSaved);
	}
	
	public virtual void songEditorSaved(LinkedList<Song> songs) {
		foreach(Song s in songs)
			lm.update_song(s, true);
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
				this.songs.remove(id);
			}
			else if(hint == "playlist") {
				lm.playlist_from_id(relative_id).removeSong(s);
				model.remove(item);
				this.songs.remove(id);
			}
			else if(hint == "collection") {
				lm.remove_song_from_id(s.rowid);
				model.remove(item);
				this.songs.remove(id);
				
				//should prompt user about being sure about this and annoy them
				
			}
			
			//must somehow update all other views if removed from collection
		}
	}
	
	public virtual void songRateSong0Clicked() {
		TreeSelection selected = view.get_selection();
		selected.set_mode(SelectionMode.MULTIPLE);
		TreeModel l_model;
		
		// this actually only goes through once
		foreach(TreePath path in selected.get_selected_rows(out l_model)) {
			TreeIter item;
			model.get_iter(out item, path);
			
			int id;
			model.get(item, 0, out id);
			Song s = lm.song_from_id(id);
			
			s.rating = 0;
			lm.update_song(s, false);
		}
	}
	
	public virtual void songRateSong1Clicked() {
		TreeSelection selected = view.get_selection();
		selected.set_mode(SelectionMode.MULTIPLE);
		TreeModel l_model;
		
		// this actually only goes through once
		foreach(TreePath path in selected.get_selected_rows(out l_model)) {
			TreeIter item;
			model.get_iter(out item, path);
			
			int id;
			model.get(item, 0, out id);
			Song s = lm.song_from_id(id);
			
			s.rating = 1;
			lm.update_song(s, false);
		}
	}
	
	public virtual void songRateSong2Clicked() {
		TreeSelection selected = view.get_selection();
		selected.set_mode(SelectionMode.MULTIPLE);
		TreeModel l_model;
		
		// this actually only goes through once
		foreach(TreePath path in selected.get_selected_rows(out l_model)) {
			TreeIter item;
			model.get_iter(out item, path);
			
			int id;
			model.get(item, 0, out id);
			Song s = lm.song_from_id(id);
			
			s.rating = 2;
			lm.update_song(s, false);
		}
	}
	
	public virtual void songRateSong3Clicked() {
		TreeSelection selected = view.get_selection();
		selected.set_mode(SelectionMode.MULTIPLE);
		TreeModel l_model;
		
		// this actually only goes through once
		foreach(TreePath path in selected.get_selected_rows(out l_model)) {
			TreeIter item;
			model.get_iter(out item, path);
			
			int id;
			model.get(item, 0, out id);
			Song s = lm.song_from_id(id);
			
			s.rating = 3;
			lm.update_song(s, false);
		}
	}
	
	public virtual void songRateSong4Clicked() {
		TreeSelection selected = view.get_selection();
		selected.set_mode(SelectionMode.MULTIPLE);
		TreeModel l_model;
		
		// this actually only goes through once
		foreach(TreePath path in selected.get_selected_rows(out l_model)) {
			TreeIter item;
			model.get_iter(out item, path);
			
			int id;
			model.get(item, 0, out id);
			Song s = lm.song_from_id(id);
			
			s.rating = 4;
			lm.update_song(s, false);
		}
	}
	
	public virtual void songRateSong5Clicked() {
		TreeSelection selected = view.get_selection();
		selected.set_mode(SelectionMode.MULTIPLE);
		TreeModel l_model;
		
		// this actually only goes through once
		foreach(TreePath path in selected.get_selected_rows(out l_model)) {
			TreeIter item;
			model.get_iter(out item, path);
			
			int id;
			model.get(item, 0, out id);
			Song s = lm.song_from_id(id);
			
			s.rating = 5;
			lm.update_song(s, false);
		}
	}
}
