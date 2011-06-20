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

public class Store.TrackList : Gtk.ScrolledWindow {
	Store.StoreView parent;
	
	private TreeView view;
	private ListStore store; // (-1, Store.Track, title, artist/album, length, price
	string secondaryText; // Either 'Artist' or 'Album'
	
	private bool resizing;
	
	public signal void stream_requested(Store.Track track);
	public signal void purchase_requested(Store.Track track);
	
	public TrackList(Store.StoreView view, string secondary) {
		parent = view;
		secondaryText = secondary;
		resizing = false;
		
		buildUI();
	}
	
	public void buildUI() {
		view = new TreeView();
		store = new ListStore(6, typeof(Store.Track), typeof(string), typeof(string), typeof(string), typeof(string), typeof(string));
		view.set_model(store);
		
		// setup the columns
		TreeViewColumn col = new TreeViewColumn();
		col.title = "track";
		col.visible = false;
		view.insert_column(col, 0);
		
		var cell = new CellRendererText();
		cell.ellipsize = Pango.EllipsizeMode.END;
		view.insert_column_with_attributes(-1, "#", cell, "text", 1, null);
		view.insert_column_with_attributes(-1, "Title", cell, "text", 2, null);
		view.insert_column_with_attributes(-1, secondaryText, cell, "text", 3, null);
		view.insert_column_with_attributes(-1, "Length", cell, "text", 4, null);
		view.insert_column_with_attributes(-1, "Price", cell, "text", 5, null);
		
		view.get_column(1).fixed_width = 30;
		view.get_column(4).fixed_width = 55;
		view.get_column(5).fixed_width = 80;
		
		foreach(var column in view.get_columns()) {
			column.sizing = TreeViewColumnSizing.FIXED;
		}
		
		view.button_press_event.connect(trackListClick);
		view.row_activated.connect(trackListDoubleClick);
		view.size_allocate.connect(resized);
		
		add(view);
		
		show_all();
	}
	
	public void addItem(Store.Track track) {
		TreeIter iter;
		store.append(out iter);
		
		store.set(iter, 0, track, 1, store.iter_n_children(null).to_string(), 2, track.title, 3, ((secondaryText == "Artist") ? track.artist.name : track.release.title), 4, track.prettyDuration(), 5, track.price.formattedPrice);
	}
	
	public virtual void resized(Gdk.Rectangle rectangle) {
		int width = rectangle.width;
		int height = rectangle.height;
		
		int others = 165; // total of other widths combined
		int remainder = width - others;
		
		if(remainder <= 270) {
			view.get_column(2).fixed_width = 180;
			view.get_column(3).fixed_width = 90;
		}
		else if(view.get_column(2).fixed_width != (int)(remainder * 0.7f)) {
			view.get_column(2).fixed_width = (int)(remainder * 0.7f);
			view.get_column(3).fixed_width = (int)(remainder * 0.3f);
		}
	}
	
	public virtual bool trackListClick(Gdk.EventButton event) {
		if(event.type == Gdk.EventType.BUTTON_PRESS && event.button == 1) {
			stdout.printf("Track list clicked\n");
		}
		
		return false;
	}
	
	public virtual void trackListDoubleClick(TreePath path, TreeViewColumn column) {
		TreeIter iter;
		
		if(!store.get_iter(out iter, path))
			return;
		
		GLib.Object o;
		store.get(iter, 0, out o);
		
		if(o is Store.Track) {
			parent.lm.playTrackPreview((Store.Track)o, ((Store.Track)o).getPreviewLink());
		}
	}
	
}
