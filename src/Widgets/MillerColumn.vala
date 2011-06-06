using Gtk;
using Gee;

public class BeatBox.MillerColumns : HBox {
	LibraryManager lm;
	LibraryWindow lw;
	Collection<int> songs;
	
	public MillerColumn genres;
	public MillerColumn artists;
	public MillerColumn albums;
	
	public signal void changed();
	
	public MillerColumns(LibraryManager lmm, LibraryWindow lww) {
		lm = lmm;
		lw = lww;
		
		artists = new MillerColumn("Artists");
		albums = new MillerColumn("Albums");
		genres = new MillerColumn("Genres");
		
		/*HPaned artistsToAlbums = new HPaned();
		
		artistsToAlbums.pack1(artists, true, false);
		artistsToAlbums.pack2(albums, true, false);
		
		pack1(genres, true, false);
		pack2(artistsToAlbums, true, false);*/
		
		pack_start(genres, true, true, 1);
		pack_start(artists, true, true, 1);
		pack_start(albums, true, true, 1);
		
		genres.selectedChanged.connect(genreSelected);
		artists.selectedChanged.connect(artistSelected);
		albums.selectedChanged.connect(albumSelected);
		
		genres.resetRequested.connect(resetColumns);
		artists.resetRequested.connect(resetColumns);
		albums.resetRequested.connect(resetColumns);
		
		genres.columnVisibilityUpdate.connect(updateColumnVisibilities);
		artists.columnVisibilityUpdate.connect(updateColumnVisibilities);
		albums.columnVisibilityUpdate.connect(updateColumnVisibilities);
		
		lw.searchField.changed.connect(searchFieldChanged);
	}
	
	public void updateColumnVisibilities(bool genreV, bool artistV, bool albumV) {
		genres.set_visible(genreV);
		artists.set_visible(artistV);
		albums.set_visible(albumV);
		
		genres.setColumnVisibilities(genreV, artistV, albumV);
		artists.setColumnVisibilities(genreV, artistV, albumV);
		albums.setColumnVisibilities(genreV, artistV, albumV);
		
		lm.settings.setMillerColumnVisibilities(genreV, artistV, albumV);
	}
	
	public void resetColumns() {
		artists.selected = "All Artists";
		albums.selected = "All Albums";
		genres.selected = "All Genres";
	}
	
	public virtual void searchFieldChanged() {
		populateColumns(songs);
	}
	
	public void populateColumns(Collection<int> songs) {
		Collection<int> searched_songs = lm.songs_from_search("", 
															lw.miller.genres.selected, 
															lw.miller.artists.selected,
															lw.miller.albums.selected,
															songs);
		
		this.songs = songs;
		
		var artistsSet = new HashSet<string>();
		var albumsSet = new HashSet<string>();
		var genresSet = new HashSet<string>();
		
		foreach(int id in searched_songs) {
			if((genres.selected == "All Genres" || genres.selected == lm.song_from_id(id).genre) &&
				(artists.selected == "All Artists" || artists.selected == lm.song_from_id(id).artist) &&
				(albums.selected == "All Albums" || albums.selected == lm.song_from_id(id).album))
			artistsSet.add(lm.song_from_id(id).artist);
			albumsSet.add(lm.song_from_id(id).album);
			genresSet.add(lm.song_from_id(id).genre);
		}
		
		artists.populate(artistsSet);
		albums.populate(albumsSet);
		genres.populate(genresSet);
	}
	
	public virtual void genreSelected(string text) {
		populateColumns(songs);
		
		changed();
	}
	public virtual void artistSelected(string text) {
		populateColumns(songs);
		
		changed();
	}
	public virtual void albumSelected(string text) {
		populateColumns(songs);
		
		changed();
	}
}




public class BeatBox.MillerColumn : ScrolledWindow {
	string category;
	TreeView view;
	ListStore model;
	TreeModelSort sortModel;
	
	string _selected;
	
	Menu columnChooserMenu;
	CheckMenuItem columnGenres;
	CheckMenuItem columnArtists;
	CheckMenuItem columnAlbums;
	
	public signal void selectedChanged(string selected);
	public signal void resetRequested();
	public signal void columnVisibilityUpdate(bool genres, bool artists, bool albums);
	
	public string selected {
		get {
			if(_selected == null)
				_selected = "All " + category;
			
			return _selected;
		}
		set {
			_selected = value;
			sortModel.foreach(selectProperString);
			selectedChanged(_selected);
		}
	}
	
	public MillerColumn(string categ) {
		view = new TreeView();
		model = new ListStore(1, typeof(string));
		category = categ;
		
		var cell = new CellRendererText();
		cell.ellipsize = Pango.EllipsizeMode.END;
		view.insert_column_with_attributes(-1, category, cell, "text", 0, null);
		
		// add this widget crap so we can get right clicks
		view.get_column(0).clickable = true;
		view.get_column(0).widget = new Gtk.Label(category);
		view.get_column(0).widget.show();
		view.get_column(0).set_sort_indicator(false);
		Gtk.Widget ancestor = view.get_column(0).widget.get_ancestor(typeof(Gtk.Button));
		GLib.assert(ancestor != null);
		ancestor.button_press_event.connect(viewHeaderClick);
		
		sortModel = new TreeModelSort.with_model(model);
		//view.set_headers_visible(false);
		view.set_model(sortModel);
		view.get_column(0).set_alignment((float)0.5);
		view.get_column(0).sizing = Gtk.TreeViewColumnSizing.FIXED;
		
		sortModel.set_sort_column_id(0, Gtk.SortType.ASCENDING);
		sortModel.set_sort_func(0, (tModel, a, b) => {
			string aString, bString;
			tModel.get(a, 0, out aString);
			tModel.get(b, 0, out bString);
			
			if(aString != "All " + category && (aString > bString))
				return 1;
			else
				return -1;
		});
		
		columnChooserMenu = new Menu();
		columnGenres = new CheckMenuItem.with_label("Genres");
		columnArtists = new CheckMenuItem.with_label("Artists");
		columnAlbums = new CheckMenuItem.with_label("Albums");
		columnChooserMenu.append(columnGenres);
		columnChooserMenu.append(columnArtists);
		columnChooserMenu.append(columnAlbums);
		columnGenres.toggled.connect(columnMenuToggled);
		columnArtists.toggled.connect(columnMenuToggled);
		columnAlbums.toggled.connect(columnMenuToggled);
		columnChooserMenu.show_all();
		
		add(view);
		
		//set_policy(PolicyType.NEVER, PolicyType.AUTOMATIC);
		
		view.get_selection().changed.connect(selectionChanged);
		view.row_activated.connect(viewDoubleClick);
	}
	
	public virtual void columnMenuToggled() {
		columnVisibilityUpdate(columnGenres.active, columnArtists.active, columnAlbums.active);
	}
	
	public void setColumnVisibilities(bool genres, bool artists, bool albums) {
		columnGenres.active = genres;
		columnArtists.active = artists;
		columnAlbums.active = albums;
	}
	
	private bool viewHeaderClick(Gtk.Widget w, Gdk.EventButton e) {
		if(e.button == 3) {
			columnChooserMenu.popup(null, null, null, 3, get_current_event_time());
			return true;
		}
		
		return false;
	}
	
	public virtual void selectionChanged() {
		TreeModel tempModel;
		TreeIter iter;
		string text;
		if(view.get_selection().get_selected(out tempModel, out iter)) {
			tempModel.get(iter, 0, out text);
			_selected = text;
			selectedChanged(_selected);
		}
	}
	
	public virtual void viewDoubleClick(TreePath path, TreeViewColumn column) {
		TreeIter item;
		sortModel.get_iter(out item, path);
		
		string text;
		sortModel.get(item, 0, out text);
		
		if(text == "All " + category)
			resetRequested();
	}
	
	public void populate(HashSet<string> items) {
		model.clear();
		items.remove("");
		TreeIter iter;
		
		model.append(out iter);
		model.set(iter, 0, "All " + category);
		
		foreach(string s in items) {
			model.append(out iter);
			model.set(iter, 0, s);
		}
		
		// select All <category> item
		view.get_selection().changed.disconnect(selectionChanged);
		sortModel.foreach(selectProperString);
		view.get_selection().changed.connect(selectionChanged);
	}
	
	public void addItem(string text) {
		TreeIter iter;
		
		model.append(out iter);
		model.set(iter, 0, text);
	}
	
	public bool selectProperString(TreeModel tmodel, TreePath path, TreeIter item) {
		string s;
		tmodel.get(item, 0, out s);
		
		if(s == _selected) {
			view.get_selection().select_iter(item);
			return true;
		}
		else
			view.get_selection().unselect_iter(item);
		
		return false;
	}
}
