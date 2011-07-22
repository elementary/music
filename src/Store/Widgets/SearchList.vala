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

public class Store.SearchList : Gtk.ScrolledWindow {
	Store.StoreView storeView;
	
	private TreeView view;
	private ListStore store; // (-1, Object,  #, track/release/artist, extra[1,2,3,4], ...
	private SearchListType type;
	
	bool alreadyResized;
	
	public signal void stream_requested(Store.Track track);
	public signal void purchase_requested(Store.Track track);
	
	public enum SearchListType {
		TRACK,
		RELEASE,
		ARTIST
	}
	
	public SearchList(Store.StoreView storeView, SearchListType type) {
		this.type = type;
		this.storeView = storeView;
		
		buildUI();
		setType(type);
	}
	
	public void buildUI() {
		view = new TreeView();
		store = new ListStore(6, typeof(GLib.Object), typeof(string), typeof(string), typeof(string), typeof(string), typeof(string));
		view.set_model(store);
		
		// setup the columns
		TreeViewColumn col = new TreeViewColumn();
		col.title = "object";
		col.visible = false;
		col.sort_column_id = 0;
		view.insert_column(col, 0);
		
		var cell = new CellRendererText();
		cell.ellipsize = Pango.EllipsizeMode.END;
		view.insert_column_with_attributes(-1, "#", cell, "text", 1, null);
		view.get_column(1).fixed_width = 40;
		
		view.insert_column_with_attributes(-1, "Title", cell, "text", 2, null);
		view.insert_column_with_attributes(-1, "Artist", cell, "text", 3, null);
		view.insert_column_with_attributes(-1, "Length", cell, "text", 4, null);
		view.insert_column_with_attributes(-1, "Price", cell, "text", 5, null);
		
		view.get_column(1).sort_column_id = 1;
		view.get_column(2).sort_column_id = 2;
		view.get_column(3).sort_column_id = 3;
		view.get_column(4).sort_column_id = 4;
		view.get_column(5).sort_column_id = 5;
		
		view.get_column(2).fixed_width = 90;
		view.get_column(3).fixed_width = 90;
		view.get_column(4).fixed_width = 55;
		view.get_column(5).fixed_width = 80;
		
		foreach(var column in view.get_columns()) {
			column.sizing = TreeViewColumnSizing.FIXED;
		}
		
		view.button_press_event.connect(listClick);
		view.row_activated.connect(listDoubleClick);
		view.size_allocate.connect(resized);
		
		add(view);
		
		set_policy(PolicyType.NEVER, PolicyType.AUTOMATIC);
		
		show_all();
	}
	
	public void setType(SearchListType type) {
		this.type = type;
		
		if(type == SearchListType.TRACK) {
			foreach(var col in view.get_columns()) {
				if(col.title != "object")
					col.visible = true;
			}
			
			view.get_column(2).title = "Title";
			view.get_column(3).title = "Artist";
			view.get_column(4).title = "Length";
			view.get_column(5).title = "Price";
		}
		else if(type == SearchListType.RELEASE) {
			foreach(var col in view.get_columns()) {
				if(col.title != "object" && col.sort_column_id != 5)
					col.visible = true;
				else
					col.visible = false;
			}
			
			view.get_column(2).title = "Title";
			view.get_column(3).title = "Artist";
			view.get_column(4).title = "Price";
		}
		else if(type == SearchListType.ARTIST) {
			foreach(var col in view.get_columns()) {
				if(col.title != "object" && col.sort_column_id <= 3)
					col.visible = true;
				else
					col.visible = false;
			}
			
			view.get_column(2).title = "Name";
			view.get_column(3).title = "Popularity";
		}
	}
	
	public void clear() {
		store.clear();
	}
	
	public void addItem(GLib.Object obj) {
		TreeIter iter;
		store.append(out iter);
		
		if(obj is Store.Track) {
			Store.Track track = (Store.Track)obj;
			store.set(iter, 0, track, 1, store.iter_n_children(null).to_string(), 2, track.title, 3, track.artist.name, 4, track.prettyDuration(), 5, track.price.formattedPrice);
		}
		else if(obj is Store.Artist) {
			Store.Artist artist = (Store.Artist)obj;
			store.set(iter, 0, artist, 1, store.iter_n_children(null).to_string(), 2, artist.name, 3, artist.popularity.to_string());
		}
		else {
			Store.Release release = (Store.Release)obj;
			store.set(iter, 0, release, 1, store.iter_n_children(null).to_string(), 2, release.title, 3, release.artist.name, 4, release.price.formattedPrice);
		}
	
	
	}
	
	public virtual void resized(Allocation rectangle) {
		if(alreadyResized) {
			alreadyResized = false;
			return;
		}
		
		alreadyResized = true;
		
		int width = rectangle.width;
		int height = rectangle.height;
		
		int others; // total of other widths combined
		
		if(type == SearchListType.TRACK)
			others = 190;
		else if(type == SearchListType.RELEASE)
			others = 120;
		else
			others = 90;
		
		int remainder = width - others;
		stdout.printf("remainder: %d\n", remainder);
		
		view.get_column(1).fixed_width = 40;
		if(type == SearchListType.TRACK) {
			if(remainder <= 270) {
				view.get_column(2).fixed_width = 180;
				view.get_column(3).fixed_width = 90;
				view.get_column(4).fixed_width = 70;
				view.get_column(5).fixed_width = 80;
			}
			else {
				view.get_column(2).fixed_width = (int)(remainder * 0.7f);
				view.get_column(3).fixed_width = (int)(remainder * 0.3f);
				view.get_column(4).fixed_width = 70;
				view.get_column(5).fixed_width = 80;
			}
		}
		else if(type == SearchListType.RELEASE) {
			if(remainder <= 270) {
				view.get_column(2).fixed_width = 180;
				view.get_column(3).fixed_width = 90;
				view.get_column(4).fixed_width = 80;
				view.get_column(5).fixed_width = 1;
			}
			else {
				view.get_column(2).fixed_width = (int)(remainder * 0.7f);
				view.get_column(3).fixed_width = (int)(remainder * 0.3f);
				view.get_column(4).fixed_width = 80;
				view.get_column(5).fixed_width = 1;
			}
		}
		else {
			view.get_column(2).fixed_width = remainder;
			view.get_column(3).fixed_width = 50;
		}
	}
	
	public virtual bool listClick(Gdk.EventButton event) {
		if(event.type == Gdk.EventType.BUTTON_PRESS && event.button == 1) {
			stdout.printf("Search list clicked\n");
		}
		
		return false;
	}
	
	public virtual void listDoubleClick(TreePath path, TreeViewColumn column) {
		TreeIter iter;
		
		if(!store.get_iter(out iter, path))
			return;
		
		GLib.Object o;
		store.get(iter, 0, out o);
		
		if(o is Store.Track)
			storeView.lm.playTrackPreview((Store.Track)o, ((Store.Track)o).getPreviewLink());
		else if(o is Store.Release) {
			Release rel = (Store.Release)o;
			var newView = new AlbumView(storeView, storeView.store, rel);
			storeView.setView(newView);
			newView.populate();
		}
		else if(o is Store.Artist) {
			Artist art = (Store.Artist)o;
			var newView = new ArtistView(storeView, storeView.store, art);
			storeView.setView(newView);
			newView.populate();
		}
	}
	
}
