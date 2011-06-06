using Gtk;
using Gee;

public class BeatBox.MillerColumns : HPaned {
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
		
		HPaned artistsToAlbums = new HPaned();
		
		artistsToAlbums.pack1(artists, true, false);
		artistsToAlbums.pack2(albums, true, false);
		
		pack1(genres, true, false);
		pack2(artistsToAlbums, true, false);
		
		genres.selectedChanged.connect(genreSelected);
		artists.selectedChanged.connect(artistSelected);
		albums.selectedChanged.connect(albumSelected);
		
		genres.resetRequested.connect(resetColumns);
		artists.resetRequested.connect(resetColumns);
		albums.resetRequested.connect(resetColumns);
	}
	
	public void resetColumns() {
		artists.selected = "All Artists";
		albums.selected = "All Albums";
		genres.selected = "All Genres";
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
	
	public signal void selectedChanged(string selected);
	public signal void resetRequested();
	
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
		
		view.insert_column_with_attributes(-1, category, new CellRendererText(), "text", 0, null);
		
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
		
		add(view);
		
		//set_policy(PolicyType.NEVER, PolicyType.AUTOMATIC);
		
		view.get_selection().changed.connect(selectionChanged);
		view.row_activated.connect(viewDoubleClick);
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
