/*-
 * Copyright (c) 2011-2012       Scott Ringwelski <sgringwe@mtu.edu>
 *
 * Originally Written by Scott Ringwelski for BeatBox Music Player
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
	public LibraryManager lm;
	public LibraryWindow lw;
	public Collection<int> medias;
	
	public MillerColumn genres;
	public MillerColumn artists;
	public MillerColumn albums;
	
	public signal void changed();
	
	public MillerColumns(LibraryManager lmm, LibraryWindow lww) {
		lm = lmm;
		lw = lww;
		
		artists = new MillerColumn(this, "Artists");
		
		pack_start(artists, true, true, 1);
		
		artists.selectedChanged.connect(artistSelected);
		artists.resetRequested.connect(resetColumns);
		
		lw.searchField.changed.connect(searchFieldChanged);
	}
	
	public void resetColumns() {
		artists.set_selected("All Artists");
	}
	
	public virtual void searchFieldChanged() {
		if(visible) {
			populateColumns("dont care", medias);
		}
	}
	
	public void populateColumns(string trigger, Collection<int> medias) {
		this.medias = medias;
		
		Widget w = lw.sideTree.getSelectedWidget();
		ViewWrapper.Hint hint = ViewWrapper.Hint.MUSIC;
		
		if(w is ViewWrapper) {
			hint = ((ViewWrapper)w).hint;
		}
		else {
			// no need to populate if not viewing viewwrapper
			return;
		}
		
		LinkedList<int> searched_medias = new LinkedList<int>();
		LinkedList<int> searched_medias_albums = new LinkedList<int>();
		lm.do_search(lw.searchField.get_text(), hint,
					"All Genres", "All Artists", "All Albums",
					medias, ref searched_medias, ref searched_medias_albums);
		
		var artistSet = new HashMap<string, int>();
		
		foreach(int id in searched_medias) {
			artistSet.set(lm.media_from_id(id).album_artist, 1);
		}
		
		artists.populate(artistSet);
	}
	
	public virtual void artistSelected(string cat, string text) {
		changed();
	}
}




public class BeatBox.MillerColumn : ScrolledWindow {
	LibraryManager lm;
	LibraryWindow lw;
	MillerColumns millerParent;
	string category;
	TreeView view;
	MillerModel model;
	
	string _selected;
	
	public signal void selectedChanged(string cat, string val);
	public signal void resetRequested();
	
	public MillerColumn(MillerColumns parent, string categ) {
		this.millerParent = parent;
		lw = parent.lw;
		lm = parent.lm;
		view = new TreeView();
		model = new MillerModel(categ);
		category = categ;
		
		var cell = new CellRendererText();
		cell.ellipsize = Pango.EllipsizeMode.END;
		view.insert_column_with_attributes(-1, category, cell, "text", 0, null);
		
		view.set_headers_visible(false);
		
		add(view);
		
		view.get_selection().changed.connect(selectionChanged);
		view.row_activated.connect(viewDoubleClick);
		view.key_press_event.connect(keyPressed);
	}
	
	public string get_selected() {
		if(_selected == null)
			_selected = "All " + category;
		
		if(!this.visible || millerParent.lw.viewSelector.selected != 2)
			return "All " + category;
		
		return _selected;
	}
	
	public void set_selected(string val) {
		if(!lw.initializationFinished || !this.visible || val == _selected)
			return;
		
		_selected = val;
		selectedChanged(category, _selected);
		model.foreach(selectProperString);
	}
	
	public bool keyPressed(Gdk.EventKey event) {
		if(Regex.match_simple("[a-zA-Z0-9]", event.str)) {
			millerParent.lw.searchField.grab_focus();
			millerParent.lw.searchField.insert_at_cursor(event.str);
		}
		return true;
	}
	
	public virtual void selectionChanged() {
		TreeModel tempModel;
		TreeIter iter;
		string text;
		if(view.get_selection().get_selected(out tempModel, out iter)) {
			tempModel.get(iter, 0, out text);
			set_selected(text);
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
	
	public void populate(HashMap<string, int> items) {
		if(items.size == model.iter_n_children(null))
			return;
		
		items.unset("");
		items.set("All " + category, 1);
		
		if(items.get(get_selected()) == 0) {
			_selected = "All " + category;
			selectedChanged(category, _selected);
		}
		
		model = new MillerModel(category);
		model.append_items(items.keys, false);
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
			
			view.scroll_to_cell(path, null, false, 0.0f, 0.0f);
			
			return true;
		}
		else
			view.get_selection().unselect_iter(item);
		
		return false;
	}
}
