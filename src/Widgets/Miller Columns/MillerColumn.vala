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

using Gtk;
using Gee;

public class BeatBox.MillerColumns : HBox {
	LibraryManager lm;
	public LibraryWindow lw;
	Collection<int> songs;
	
	public MillerColumn genres;
	public MillerColumn artists;
	public MillerColumn albums;
	
	public signal void changed();
	
	public MillerColumns(LibraryManager lmm, LibraryWindow lww) {
		lm = lmm;
		lw = lww;
		
		artists = new MillerColumn(this, "Artists");
		albums = new MillerColumn(this, "Albums");
		genres = new MillerColumn(this, "Genres");
		
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
		if(visible)
			populateColumns(songs);
	}
	
	public void populateColumns(Collection<int> songs) {
		Collection<int> searched_songs = lm.songs_from_search(lw.searchField.get_text(), 
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
		
		if(artists.selected == "All Artists")
			artists.populate(artistsSet);
			
		if(albums.selected == "All Albums")
			albums.populate(albumsSet);
		
		if(genres.selected == "All Genres")
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
	MillerColumns millerParent;
	string category;
	TreeView view;
	MillerModel model;
	
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
			model.foreach(selectProperString);
			selectedChanged(_selected);
		}
	}
	
	public MillerColumn(MillerColumns parent, string categ) {
		this.millerParent = parent;
		view = new TreeView();
		model = new MillerModel(categ);
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
		
		//view.set_headers_visible(false);
		view.get_column(0).set_alignment((float)0.5);
		view.get_column(0).sizing = Gtk.TreeViewColumnSizing.FIXED;
		
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
		view.key_press_event.connect(keyPressed);
	}
	
	public bool keyPressed(Gdk.EventKey event) {
		millerParent.lw.searchField.grab_focus();
		millerParent.lw.searchField.insert_at_cursor(event.str);
		return true;
	}
	
	public virtual void columnMenuToggled() {
		columnVisibilityUpdate(columnGenres.active, columnArtists.active, columnAlbums.active);
	}
	
	public void setColumnVisibilities(bool genres, bool artists, bool albums) {
		columnGenres.active = genres;
		columnArtists.active = artists;
		columnAlbums.active = albums;
		
		if(!genres && !artists) {
			columnAlbums.set_sensitive(false);
		}
		else if(!genres && !albums) {
			columnArtists.set_sensitive(false);
		}
		else if(!artists && !albums) {
			columnGenres.set_sensitive(false);
		}
		else {
			columnGenres.set_sensitive(true);
			columnArtists.set_sensitive(true);
			columnAlbums.set_sensitive(true);
		}
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
		model.get_iter(out item, path);
		
		Value text;
		model.get_value(item, 0, out text);
		
		if(text.get_string() == "All " + category)
			resetRequested();
	}
	
	public void populate(HashSet<string> items) {
		items.remove("");
		items.add("All " + category);
		TreeIter iter;
		
		model = new MillerModel(category);
		model.append_items(items, true);
		model.set_sort_column_id(0, Gtk.SortType.ASCENDING);
		view.set_model(model);
		
		// select selected item
		view.get_selection().changed.disconnect(selectionChanged);
		model.foreach(selectProperString);
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
