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
using Granite;

public class BeatBox.StationEditor : Window {
	LibraryManager _lm;
	
	LinkedList<int> _allstations;
	LinkedList<int> _stations;
	
	//for padding around notebook mostly
	private VBox content;
	private HBox padding;
	
	private VBox vert; // separates editors with buttons and other stuff
	private HBox horiz; // separates text with numerical editors
	private VBox textVert; // separates text editors
	private VBox numerVert; // separates numerical editors
	
	private HashMap<string, FieldEditor> fields;// a hashmap with each property and corresponding editor
	
	private Button _previous;
	private Button _next;
	private Button _save;
	
	public signal void stations_saved(LinkedList<int> stations);
	
	public StationEditor(LibraryManager lm, LinkedList<int> allstations, LinkedList<int> stations) {
		this.window_position = WindowPosition.CENTER;
		this.type_hint = Gdk.WindowTypeHint.DIALOG;
		this.set_modal(true);
		this.set_transient_for(lm.lw);
		this.destroy_with_parent = true;
		content = new VBox(false, 10);
		
		set_size_request (520, -1);
		resizable = false;
		
		_lm = lm;
		
		_allstations = allstations;
		_stations = stations;
		
		HButtonBox buttonSep = new HButtonBox();
		buttonSep.set_layout(ButtonBoxStyle.END);
		_previous = new Button.with_label("Previous");
		_next = new Button.with_label("Next");
		_save = new Button.with_label("Done");
		
		buttonSep.pack_start(_previous, false, false, 0);
		buttonSep.pack_start(_next, false, false, 0);
		buttonSep.pack_end(_save, false, false, 0);
		
		content.pack_start(wrap_alignment(createBasicViewport(), 10, 0, 0, 0), true, true, 0);
		content.pack_start(wrap_alignment(buttonSep, 0, 0, 10, 0), false, true, 0);
		
		(buttonSep as Gtk.ButtonBox).set_child_secondary(_next, true);
		(buttonSep as Gtk.ButtonBox).set_child_secondary(_previous, true);
		
		padding.pack_start(content, true, true, 10);
		add(padding);
		
		show_all();
		
		_next.sensitive = allstations.size > 1;
		_previous.sensitive = allstations.size > 1;
		
		if(_stations.size == 1) {
			foreach(FieldEditor fe in fields.values)
				fe.set_check_visible(false);
		}
		
		_previous.clicked.connect(previousClicked);
		_next.clicked.connect(nextClicked);
		_save.clicked.connect(saveClicked);
	}
	
	public Viewport createBasicViewport() {
		Viewport rv = new Viewport(null, null);
		fields = new HashMap<string, FieldEditor>();
		Media sum = _lm.media_from_id(_stations.get(0)).copy();
		
		/** find what these stations have what common, and keep those values **/
		foreach(int i in _stations) {
			Media s = _lm.media_from_id(i);
			
			if(s.album_artist != sum.album_artist) // station name
				sum.album_artist = "";
			if(s.genre != sum.genre) // category
				sum.genre = "";
			if(s.rating != sum.rating)
				sum.rating = 0;
		}
		
		if(_stations.size == 1) {
			title = "Editing " + sum.title;
		}
		else {
			title = "Editing " + _stations.size.to_string() + " stations";
		}
		
		if(sum.year == -1)
			sum.year = Time().year;
		
		fields.set("Station", new FieldEditor("Station", sum.album_artist, new Entry()));
		fields.set("Genre", new FieldEditor("Genre", sum.genre, new Entry()));
		fields.set("Rating", new FieldEditor("Rating", sum.rating.to_string(), new RatingWidget(null, false, IconSize.MENU)));
		
		padding = new HBox(false, 10);
		vert = new VBox(false, 0);
		horiz = new HBox(false, 0);
		textVert = new VBox(false, 0);
		numerVert = new VBox(false, 0);
		
		textVert.pack_start(fields.get("Station"), false, true, 0);
		textVert.pack_start(fields.get("Genre"), false, true, 5);
		numerVert.pack_start(fields.get("Rating"), false, true, 5);
		
		horiz.pack_start(wrap_alignment(textVert, 0, 30, 0, 0), false, true, 0);
		horiz.pack_end(numerVert, false, true, 0);
		vert.pack_start(horiz, true, true, 0);
		
		rv.add(vert);
		
		return rv;
	}
	
	public static Gtk.Alignment wrap_alignment (Gtk.Widget widget, int top, int right, int bottom, int left) {
		var alignment = new Gtk.Alignment(0.0f, 0.0f, 1.0f, 1.0f);
		alignment.top_padding = top;
		alignment.right_padding = right;
		alignment.bottom_padding = bottom;
		alignment.left_padding = left;
		
		alignment.add(widget);
		return alignment;
	}
	
	public void previousClicked() {
		save_stations();
		
		// now fetch the next media on current_view
		int i = 0; // will hold next media to edit
		int indexOfCurrentFirst = _allstations.index_of(_stations.get(0));
		
		if(indexOfCurrentFirst == 0)
			i = _allstations.get(_allstations.size - 1);
		else
			i = _allstations.get(indexOfCurrentFirst - 1);
		
		// now fetch the previous media on current_view
		var newstations = new LinkedList<int>();
		newstations.add(i);
		
		change_media(newstations);
	}
	
	public void nextClicked() {
		save_stations();
		
		// now fetch the next media on current_view
		int i = 0; // will hold next media to edit
		int indexOfCurrentLast = _allstations.index_of(_stations.get(_stations.size - 1));
		
		if(indexOfCurrentLast == _allstations.size - 1)
			i = _allstations.get(0);
		else
			i = _allstations.get(indexOfCurrentLast + 1);
		
		var newstations = new LinkedList<int>();
		newstations.add(i);
		
		change_media(newstations);
	}
	
	public void change_media(LinkedList<int> newstations) {
		_stations = newstations;
		
		Media sum = _lm.media_from_id(newstations.get(0));
		
		title = "Editing " + sum.title;
		
		/* do not show check boxes for 1 media */
		foreach(FieldEditor fe in fields.values)
			fe.set_check_visible(false);
		
		fields.get("Station").set_value(sum.album_artist);
		fields.get("Genre").set_value(sum.genre);
		fields.get("Rating").set_value(sum.rating.to_string());
	}
	
	public void save_stations() {
		foreach(int i in _stations) {
			Media s = _lm.media_from_id(i);
			
			if(fields.get("Station").checked())
				s.album_artist = fields.get("Station").get_value();
			if(fields.get("Genre").checked())
				s.genre = fields.get("Genre").get_value();
			if(fields.get("Rating").checked())
				s.rating = int.parse(fields.get("Rating").get_value());
		}
		
		stations_saved(_stations);
	}
	
	public virtual void saveClicked() {
		save_stations();
		
		this.destroy();
	}
}
