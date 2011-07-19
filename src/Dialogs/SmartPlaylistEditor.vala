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

/* Merely a place holder for multiple pieces of information regarding
 * the current song playing. Mostly here because of dependence. */

using Gtk;
using Gee;

public class BeatBox.SmartPlaylistEditor : Window {
	SmartPlaylist _sp;
	
	VBox content;
	HBox padding;
	
	private  Label nameLabel;
	private Label rulesLabel;
	private Label optionsLabel;
	
	ElementaryWidgets.ElementaryEntry _name;
	ComboBoxText comboMatch;
	VBox vertQueries;
	Gee.ArrayList<SmartPlaylistEditorQuery> spQueries;
	Button addButton;
	CheckButton limitSongs;
	SpinButton songLimit;
	Button save;
	
	public signal void playlist_saved(SmartPlaylist sp);
	
	public SmartPlaylistEditor(LibraryWindow lw, SmartPlaylist sp) {
		this.title = "Smart Playlist Editor";
		
		this.window_position = WindowPosition.CENTER;
		this.type_hint = Gdk.WindowTypeHint.DIALOG;
		this.set_modal(true);
		this.set_transient_for(lw);
		this.destroy_with_parent = true;
		
		_sp = sp;
		
		content = new VBox(false, 10);
		padding = new HBox(false, 10);
		
		/* start out by creating all category labels */
		nameLabel = new Label("Name of Playlist");
		rulesLabel = new Label("Rules");
		optionsLabel = new Label("Options");
		
		/* make them look good */
		nameLabel.xalign = 0.0f;
		rulesLabel.xalign = 0.0f;
		optionsLabel.xalign = 0.0f;
		nameLabel.set_markup("<b>Name of Playlist</b>");
		rulesLabel.set_markup("<b>Rules</b>");
		optionsLabel.set_markup("<b>Options</b>");
		
		/* add the name entry */
		_name = new ElementaryWidgets.ElementaryEntry("Playlist Title");
		if(_sp.name != "")
			_name.set_text(_sp.name);
		
		/* create match checkbox/combo combination */
		HBox matchBox = new HBox(false, 2);
		Label tMatch = new Label("Match");
		comboMatch = new ComboBoxText();
		comboMatch.insert_text(0, "any");
		comboMatch.insert_text(1, "all");
		Label tOfTheFollowing = new Label("of the following:");
		
		matchBox.pack_start(tMatch, false, false, 0);
		matchBox.pack_start(comboMatch, false, false, 0);
		matchBox.pack_start(tOfTheFollowing, false, false, 0);
		
		if(_sp.conditional == "any")
			comboMatch.set_active(0);
		else
			comboMatch.set_active(1);
		
		/* create rule list */
		spQueries = new Gee.ArrayList<SmartPlaylistEditorQuery>();
		vertQueries = new VBox(true, 2);
		foreach(SmartQuery q in _sp.queries()) {
			SmartPlaylistEditorQuery speq = new SmartPlaylistEditorQuery(q);
			
			vertQueries.pack_start(speq._box, false, true, 1);
			spQueries.add(speq);
		}
		
		if(_sp.queries().size == 0) {
			addRow();
		}
		
		addButton = new Button.with_label("Add");
		vertQueries.pack_end(addButton, false, true, 1);
		addButton.clicked.connect(addButtonClick);
		
		/* create extra option: limiter */
		limitSongs = new CheckButton.with_label("Limit to");
		songLimit = new SpinButton.with_range(0, 500, 10);
		Label limiterLabel = new Label("songs");
		
		limitSongs.set_active(_sp.limit);
		songLimit.set_value((double)_sp.limit_amount);
		
		HBox limiterBox = new HBox(false, 2);
		limiterBox.pack_start(limitSongs, false, false, 0);
		limiterBox.pack_start(songLimit, false, false, 0);
		limiterBox.pack_start(limiterLabel, false, false, 0);
		
		/* add the Done button on bottom */
		HButtonBox bottomButtons = new HButtonBox();
		save = new Button.with_label("Done");
		bottomButtons.set_layout(ButtonBoxStyle.END);
		bottomButtons.pack_end(save, false, false, 0);
		
		/* put it all together */
		content.pack_start(wrap_alignment(nameLabel, 10, 0, 0, 0), false, true, 0);
		content.pack_start(wrap_alignment(_name, 0, 10, 0, 10), false, true, 0);
		content.pack_start(rulesLabel, false, true, 0);
		content.pack_start(wrap_alignment(matchBox, 0, 10, 0, 10) , false, true, 0);
		content.pack_start(wrap_alignment(vertQueries, 0, 10, 0, 10), false, true, 0);
		content.pack_start(optionsLabel, false, true, 0);
		content.pack_start(wrap_alignment(limiterBox, 0, 10, 0, 10), false, true, 0);
		content.pack_start(bottomButtons, false, false, 10);
		
		padding.pack_start(content, true, true, 10);
		
		add(padding);
		show_all();
		
		foreach(SmartPlaylistEditorQuery speq in spQueries) {
			speq.fieldChanged();
		}
		
		save.clicked.connect(saveClick);
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
	
	public void addRow() {
		SmartPlaylistEditorQuery speq = new SmartPlaylistEditorQuery(new SmartQuery());
		
		vertQueries.pack_start(speq._box, false, true, 1);
		spQueries.add(speq);
		
	}
	
	public virtual void addButtonClick() {
		addRow();
	}
	
	public virtual void saveClick() {
		_sp.clearQueries();
		foreach(SmartPlaylistEditorQuery speq in spQueries) {
			if(speq._box.visible)
				_sp.addQuery(speq.getQuery());
		}
		
		_sp.name = _name.text;
		_sp.conditional = comboMatch.get_active_text();
		_sp.limit = limitSongs.get_active();
		_sp.limit_amount = (int)songLimit.get_value();
		
		playlist_saved(_sp);
		
		this.destroy();
	}
}

public class BeatBox.SmartPlaylistEditorQuery : GLib.Object {
	private SmartQuery _q;
	
	public HBox _box;
	private ComboBoxText _field;
	private ComboBoxText _comparator;
	private Entry _value;
	private SpinButton _valueNumerical;
	private Label _units;
	private Button _remove;
	
	public HashMap<string, int> fields;
	public HashMap<string, int> comparators;
	
	public signal void removed();
	
	public SmartPlaylistEditorQuery(SmartQuery q) {
		_q = q;
		fields = new HashMap<string, int>();
		comparators = new HashMap<string, int>();
		
		fields.set("Album", 0);
		fields.set("Artist", 1);
		fields.set("Bitrate", 2);
		fields.set("Comment", 3);
		fields.set("Date Added", 4);
		fields.set("Genre", 5);
		fields.set("Last Played", 6);
		fields.set("Length", 7);
		fields.set("Playcount", 8);
		fields.set("Rating", 9);
		fields.set("Skipcount", 10);
		fields.set("Title", 11);
		fields.set("Year", 12);
		
		_box = new HBox(false, 2);
		_field = new ComboBoxText();
		_comparator = new ComboBoxText();
		_value = new Entry();
		_valueNumerical = new SpinButton.with_range(0, 1000, 1);
		_remove = new Button.with_label("Remove");
		
		_field.append_text("Album");
		_field.append_text("Artist");
		_field.append_text("Bitrate");
		_field.append_text("Comment");
		_field.append_text("Date Added");
		_field.append_text("Genre");
		_field.append_text("Last Played");
		_field.append_text("Length");
		_field.append_text("Playcount");
		_field.append_text("Rating");
		_field.append_text("Skipcount");
		_field.append_text("Title");
		_field.append_text("Year");
		
		_field.set_active(fields.get(q.field));
		_comparator.set_active(comparators.get(q.comparator));
		
		if(q.field == "Album" || q.field == "Artist" || q.field == "Comment" || q.field == "Genre" || q.field == "Title") {
			_value.text = q.value;
		}
		else {
			_valueNumerical.set_value(int.parse(q.value));
		}
			
		_units = new Label("");
		
		_box.pack_start(_field, false, true, 0);
		_box.pack_start(_comparator, false ,true, 1);
		_box.pack_start(_value, true, true, 1);
		_box.pack_start(_valueNumerical, true, true, 1);
		_box.pack_start(_units, false, true, 1);
		_box.pack_start(_remove, false, true, 0);
		
		_box.show_all();
		
		fieldChanged();
		_remove.clicked.connect(removeClicked);
		_field.changed.connect(fieldChanged);
	}
	
	public SmartQuery getQuery() {
		SmartQuery rv = new SmartQuery();
		
		rv.field = _field.get_active_text();
		rv.comparator = _comparator.get_active_text();
		
		if(_field.get_active_text() == "Album" || _field.get_active_text() == "Artist" || _field.get_active_text() == "Comment" || _field.get_active_text() == "Genre" || _field.get_active_text() == "Title")
			rv.value = _value.text;
		else
			rv.value = _valueNumerical.value.to_string();
		
		return rv;
	}
	
	public virtual void fieldChanged() {
		if(_field.get_active_text() == "Album" || _field.get_active_text() == "Artist" || _field.get_active_text() == "Comment" || _field.get_active_text() == "Genre" || _field.get_active_text() == "Title") {
			_value.show();
			_valueNumerical.hide();
			
			for(int i = 0;i < 3; ++i) _comparator.remove(0);
			_comparator.append_text("is");
			_comparator.append_text("contains");
			_comparator.append_text("does not contain");
			comparators.set("is", 0);
			comparators.set("contains", 1);
			comparators.set("does not contain", 2);
			
			_comparator.set_active( (comparators.has_key(_q.comparator)) ? comparators.get(_q.comparator) : 0);
		}
		else {
			_valueNumerical.show();
			_value.hide();
			
			if(_field.get_active_text() == "Bitrate" || _field.get_active_text() == "Year" || _field.get_active_text() == "Rating" || _field.get_active_text() == "Playcount" || _field.get_active_text() == "Skipcount" || _field.get_active_text() == "Length") {
				for(int i = 0;i < 3; ++i) _comparator.remove(0);
				_comparator.append_text("is exactly");
				_comparator.append_text("is at most");
				_comparator.append_text("is at least");
				comparators.set("is exactly", 0);
				comparators.set("is at most", 1);
				comparators.set("is at least", 2);
				
				_comparator.set_active( (comparators.has_key(_q.comparator)) ? comparators.get(_q.comparator) : 0);
			}
			else if(_field.get_active_text() == "Date Added" || _field.get_active_text() == "Last Played") {
				for(int i = 0;i < 3; ++i) _comparator.remove(0);
				_comparator.append_text("is exactly");
				_comparator.append_text("is within");
				_comparator.append_text("is before");
				comparators.set("is exactly", 0);
				comparators.set("is within", 1);
				comparators.set("is before", 2);
				
				_comparator.set_active( (comparators.has_key(_q.comparator)) ? comparators.get(_q.comparator) : 0);
			}
		}
		
		_comparator.show();
		
		//helper for units
		if(_field.get_active_text() == "Length") {
			_units.set_text("seconds");
			_units.show();
		}
		else if(_field.get_active_text() == "Last Played" || _field.get_active_text() == "Date Added") {
			_units.set_text("days ago");
			_units.show();
		}
		else if(_field.get_active_text() == "Bitrate") {
			_units.set_text("kbps");
			_units.show();
		}
		else
			_units.hide();
	}
	
	public virtual void removeClicked() {
		removed();
		this._box.hide();
	}
}
