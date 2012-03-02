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
 *
 * Authored by: Scott Ringwelski <sgringwe@mtu.edu>
 *              Victor Eduardo <victoreduardm@gmail.com>
 */

using Gdk;
using Gtk;
using Gee;

public class BeatBox.MillerColumns : Box {

	public signal void changed ();
	public signal void position_changed (Position p);

	public enum Position {
		AUTOMATIC = 0,
		LEFT      = 2,
		TOP       = 1
	}

	public Position position {get; private set; default = Position.AUTOMATIC;}

	public LibraryManager lm {get; private set;}
	public LibraryWindow lw {get; private set;}

	public ViewWrapper.Hint view_type {get; private set;}
	public Collection<int> medias {get; private set;}
	public LinkedList<unowned MillerColumn> columns {get; private set;}

	private Gtk.Menu column_chooser_menu;

	public MillerColumns(LibraryWindow lw, ViewWrapper.Hint view_type = ViewWrapper.Hint.MUSIC) {
		this.lm = lw.lm;
		this.lw = lw;
		this.view_type = view_type;

		orientation = Orientation.HORIZONTAL;

		columns = new LinkedList<unowned MillerColumn> ();

		column_chooser_menu = new Gtk.Menu ();

		// Inserting columns
		add_column (MillerColumn.Category.RATING);
		add_column (MillerColumn.Category.YEAR);
		add_column (MillerColumn.Category.GENRE);

		// These columns only make sense for songs
		if (view_type == ViewWrapper.Hint.MUSIC) {
			add_column (MillerColumn.Category.ARTIST);
			add_column (MillerColumn.Category.ALBUM);
		}

		// Read visible columns from settings
		foreach (var col_n in lm.settings.get_miller_visible_columns ()) {
			foreach (var column in columns) {
				if (column.category == int.parse (col_n)) {
					column.visible = true;
					break;
				}
			}
		}

		// Position stuff
		position = (Position) lm.settings.get_miller_columns_position ();

		RadioMenuItem automatic_menu_item;
		RadioMenuItem left_menu_item;
		RadioMenuItem top_menu_item;

		automatic_menu_item = new RadioMenuItem.with_label ((SList<RadioMenuItem>) null, _("Automatic"));
		left_menu_item = new RadioMenuItem.with_label (automatic_menu_item.get_group (), _("Left"));
		top_menu_item = new RadioMenuItem.with_label (left_menu_item.get_group (), _("Top"));

		(automatic_menu_item as CheckMenuItem).toggled.connect ( () => {
			set_columns_position (Position.AUTOMATIC);		
		});

		(left_menu_item as CheckMenuItem).toggled.connect ( () => {
			set_columns_position (Position.LEFT);		
		});

		(top_menu_item as CheckMenuItem).toggled.connect ( () => {
			set_columns_position (Position.TOP);		
		});

		switch (position) {
			case Position.AUTOMATIC:
				automatic_menu_item.set_active (true);
				break;
			case Position.LEFT:
				left_menu_item.set_active (true);
				break;
			case Position.TOP:
				top_menu_item.set_active (true);
				break;
		}

		column_chooser_menu.add (new SeparatorMenuItem ());
		column_chooser_menu.append (automatic_menu_item);
		column_chooser_menu.append (left_menu_item);
		column_chooser_menu.append (top_menu_item);

		column_chooser_menu.show_all ();

		lw.searchField.changed.connect (on_search_field_changed);
	}

	public void set_columns_position (Position pos) {
		position = pos;

		debug ("selected_position = %i", (int) position);

		lm.settings.set_miller_columns_position ((int) position);

		// Emit signal
		position_changed (position);
	}

	public MillerColumn? get_column (MillerColumn.Category type) {
		foreach (var column in columns) {
			if (column.category == type) {
				return column;
			}
		}

		return null;
	}

	private void add_column (MillerColumn.Category type) {
		// Setup column and connect signals
		var column = new MillerColumn (this, type);

		column.selection_changed.connect (column_selection_changed);

		column.reset_requested.connect ( () => {
			column.select_first_item ();
		});

		columns.add (column);
		pack_start (column, true, true, 1);

		column_chooser_menu.append (column.menu_item);

		column.row_activated.connect (column_row_activated);
		column.header_clicked.connect (column_header_clicked);
	}

	private void column_row_activated () {
		// TODO: Start playing the first song in the media treeview
	}

	private void column_selection_changed (MillerColumn.Category category, string val) {

		/* FIXME: remove this code. See explanation below in populate_columns() */
		Widget w = lw.sideTree.getSelectedWidget();
		ViewWrapper.Hint hint = ViewWrapper.Hint.MUSIC;

		if(w is ViewWrapper) {
			hint = ((ViewWrapper)w).hint;
		}
		else {
			return; // no need to populate if not viewing viewwrapper
		}

		/**
		 * Since the columns follow a hierarchical model, we have to re-populate all the columns
		 * that have a lower hierarchical level.
		 */

		var search_rating = -1; // ~ All
		var search_year   = -1; // ~ All
		var search_genre  = ""; // ~ All
		var search_artist = ""; // ~ All
		var search_album  = ""; // ~ All

		foreach (var col in columns) {
			// Higher hierarchical levels (parent columns)
			if (col.category <= category) {
				if (col.category == MillerColumn.Category.GENRE) {
					search_genre = (col.category == category) ? val : col.get_selected ();
				}
				else if (col.category == MillerColumn.Category.ARTIST) {
					search_artist = (col.category == category) ? val : col.get_selected ();
				}
				else if (col.category == MillerColumn.Category.ALBUM) {
					search_album = (col.category == category) ? val : col.get_selected ();
				}
				else if (col.category == MillerColumn.Category.YEAR) {
					var year = (col.category == category) ? val : col.get_selected ();
					search_year = (year == "") ? -1 : int.parse (year);
				}
				else if (col.category == MillerColumn.Category.RATING) {
					var rating = (col.category == category) ? val : col.get_selected ();
					search_rating = (rating == "") ? -1 : int.parse (rating);
				}
			}
		}

		// Perform search
		LinkedList<int> search_results;

		lm.do_search (medias, out search_results, null, null, null, null, hint,
		              lw.searchField.get_text (),
		              search_artist, search_album, search_genre, search_year, search_rating);

		// Now re-populate the child columns
		foreach (var column in columns) {
			// Child columns
			if (column.category > category) {
				var column_set = new HashMap<string, int> ();

				foreach(int id in search_results) {
					var media = lm.media_from_id(id);
					string _val = "";

					if (column.category == MillerColumn.Category.GENRE)
						_val = media.genre;
					else if (column.category == MillerColumn.Category.ARTIST)
						_val = media.album_artist;
					else if (column.category == MillerColumn.Category.ALBUM)
						_val = media.album;
					else if (column.category == MillerColumn.Category.YEAR)
						_val = media.year.to_string ();
					else if (column.category == MillerColumn.Category.RATING)
						_val = media.rating.to_string ();

					column_set.set (_val, 1);
				}

				// The 'populate' method selects 'All # $category' automatically
				column.populate (column_set);
			}
		}

		// Now that we've re-populated the columns, emit the 'changed' signal
		changed ();
	}

	private void column_header_clicked (Gdk.EventButton e) {
		if (e.button == 3) { // secondary button
			column_chooser_menu.popup (null, null, null, 3, get_current_event_time ());
		}
	}

	public virtual void on_search_field_changed () {
		if (visible) {
			populate_columns("", medias);
		}
	}

	public void populate_columns (string s, Collection<int> medias) {
		this.medias = medias;

		// FIXME: remove this code. Each ViewWrapper will have its own MillerColumns object
		// and thus we'll use this.view_type instead (of couse it's something that has to
		// be fixed in ViewWrapper.vala and LibraryWindow.vala). There are serious performance
		// issues with the current method (re-populating the same miller object).

		// <to_remove>
		Widget w = lw.sideTree.getSelectedWidget();
		ViewWrapper.Hint hint = ViewWrapper.Hint.MUSIC;

		if (w is ViewWrapper) {
			hint = ((ViewWrapper)w).hint;
		}
		else {
			return; // no need to populate if not viewing viewwrapper
		}
		// </to_remove>

		LinkedList<int> searched_medias, searched_medias_albums;

		lm.do_search (medias, out searched_medias, out searched_medias_albums, null, null, null,
		              hint, lw.searchField.get_text ());

		foreach (var column in columns) {
			var column_set = new HashMap<string, int>();

			foreach (int id in searched_medias) {
				var media = lm.media_from_id (id);
				string val = "";

				if (column.category == MillerColumn.Category.GENRE)
					val = media.genre;
				else if (column.category == MillerColumn.Category.ARTIST)
					val = media.album_artist;
				else if (column.category == MillerColumn.Category.ALBUM)
					val = media.album;
				else if (column.category == MillerColumn.Category.YEAR)
					val = media.year.to_string ();
				else if (column.category == MillerColumn.Category.RATING)
					val = media.rating.to_string ();

				column_set.set (val, 1);
			}

			column.populate (column_set);
		}
	}
}


public class BeatBox.MillerColumn : ScrolledWindow {

	public signal void selection_changed (MillerColumn.Category type, string val);
	public signal void row_activated (string text);
	public signal void reset_requested ();
	public signal void header_clicked (EventButton e);

	public enum Category {
		RATING = 0,
		YEAR   = 1,
		GENRE  = 2,
		ARTIST = 3,
		ALBUM  = 4
	}

	public new bool visible {
		get {
			return !this.get_no_show_all ();
		}
		set {
			this.menu_item.set_active (value);
			this.set_no_show_all (!value);
			this.set_visible (value);

			if (value)
				show_all ();
			else // if the column is being hidden, make sure we select "All ..."
				select_first_item ();
		}
	}

	public Category category {get; private set;}

	public CheckMenuItem menu_item {get; private set;}

	public bool first_item_selected { get { return _selected == null; } }

	private MillerColumns miller_parent;
	private LibraryManager lm;
	private LibraryWindow lw;

	private TreeView view;
	private MillerModel model;

	// This will be NULL whenever the first element "All" is selected.
	private string? _selected;

	public MillerColumn (MillerColumns parent, Category category) {
		this.miller_parent = parent;
		this.category = category;

		lw = parent.lw;
		lm = parent.lm;

		menu_item = new CheckMenuItem.with_label (get_category_text());
		this.visible = false; // Make the column initially hidden

		view = new TreeView ();
		model = new MillerModel ();

		var cell = new CellRendererText ();
		cell.ellipsize = Pango.EllipsizeMode.END;

		view.insert_column_with_attributes (-1, get_category_text (), cell, "text", 0, null);

		add (view);

		view.set_headers_clickable (true);

		view.get_column (0).set_alignment (0.5f);

		menu_item.toggled.connect (on_menu_item_toggled);
		view.get_column (0).get_button ().button_press_event.connect (on_header_clicked);
		view.get_selection ().changed.connect (selected_item_changed);
		view.row_activated.connect (view_double_click);
		view.key_press_event.connect (key_pressed);
	}

	private void on_menu_item_toggled () {
		if (!menu_item.sensitive || menu_item.active == visible)
			return;

		int visible_columns = 0;

		foreach (var col in miller_parent.columns) {
			if (col.visible)
				visible_columns ++;
		}

		this.visible = menu_item.active;

		if (this.visible)
			visible_columns ++;
		else
			visible_columns --;


		// Save settings
		var visible_columns_list = new LinkedList<string> ();

		foreach (var col in miller_parent.columns) {
			if (col.visible) {
				visible_columns_list.add (((int)col.category).to_string ());
				// don't allow disabling an element if it's the last visible column.
				col.menu_item.set_sensitive (visible_columns > 1);
			}
		}

		lm.settings.set_miller_visible_columns (visible_columns_list);
	}

	public string get_category_text (bool singular = false, bool lower_case = false) {
		string category_text = "";

		switch (category) {
			case Category.GENRE:
				category_text = (singular) ? _("Genre") : _("Genres");
				break;
			case Category.ARTIST:
				category_text = (singular) ? _("Artist") : _("Artists");
				break;
			case Category.ALBUM:
				category_text = (singular) ? _("Album") : _("Albums");
				break;
			case Category.YEAR:
				category_text = (singular) ? _("Year") : _("Years");
				break;
			case Category.RATING:
				category_text = (singular) ? _("Rating") : _("Ratings");
				break;
		}

		if (lower_case)
			category_text = category_text.down ();

		return category_text;
	}

	// selects "All ..."
	public void select_first_item () {
		set_selected (null, get_selected () != "");
		selection_changed (category, get_selected ()); // This will send "" as selected item
	}

	private bool on_header_clicked (Widget w, EventButton e) {
		 // Scroll to top (select 'All') if the primary button is clicked
		if (e.button == 1) {
			select_first_item ();
		}

		// emit signal
		header_clicked (e);

		return true;
	}

	/**
	 * Since this is used to get the selected column item, when _selected is NULL it returns ""
	 * to represent "All" in LibraryManager.do_search()
	 */
	public string get_selected () {
		if (_selected == null || !this.visible || miller_parent.lw.viewSelector.selected != 2)
			return "";

		return _selected;
	}

	public void set_selected (string? val, bool notify = false) {
		if (!lw.initializationFinished || !this.visible || val == _selected)
			return;

		_selected = val;

		if (notify)
			selection_changed (category, get_selected ());

		model.foreach (select_proper_string);
	}

	public bool key_pressed (Gdk.EventKey event) {
		if (Regex.match_simple ("[a-zA-Z0-9]", event.str)) {
			miller_parent.lw.searchField.grab_focus ();
			miller_parent.lw.searchField.insert_at_cursor (event.str);
		}

		return true;
	}

	public virtual void selected_item_changed () {
		TreeModel tempModel;
		TreeIter iter;
		string text;

		if (view.get_selection ().get_selected (out tempModel, out iter)) {
			if (((SequenceIter<string>) iter.user_data).get_position () == 0) {
				// first item selected
				select_first_item ();
			} else {
				tempModel.get (iter, 0, out text);
				set_selected (text, true);
			}
		}
	}

	public virtual void view_double_click (TreePath path, TreeViewColumn column) {
		TreeIter iter;
		model.get_iter (out iter, path);

		if (((SequenceIter<string>) iter.user_data).get_position () == 0) {
			// first item selected
			reset_requested ();
		}
		else {
			Value text;
			model.get_value (iter, 0, out text);
			row_activated ((string) text);
		}
	}

	public void populate (HashMap<string, int> items) {
		if (items.size == model.iter_n_children (null))
			return;

		items.unset ("");

		if (items.get(get_selected()) == 0) {
			select_first_item ();
		}

		model = new MillerModel (get_category_text ());

		model.append_items (items.keys, false);
		model.set_sort_column_id (0, Gtk.SortType.ASCENDING);
		view.set_model (model);

		// select selected item
		view.get_selection ().changed.disconnect (selected_item_changed);
		model.foreach (select_proper_string);
		view.get_selection ().changed.connect (selected_item_changed);
	}

	public void add_item (string text) {
		TreeIter iter;

		model.append (out iter);
		model.set (iter, 0, text);
	}

	public bool select_proper_string (TreeModel tmodel, TreePath path, TreeIter item) {
		string s;
		tmodel.get (item, 0, out s);

		if (first_item_selected) {
			view.get_selection ().select_iter (item);
			view.scroll_to_cell (new TreePath.first(), null, false, 0.0f, 0.0f);

			return true;
		}
		else if (s == get_selected ()) {
			view.get_selection ().select_iter (item);
			view.scroll_to_cell (path, null, false, 0.0f, 0.0f);

			return true;
		}
		else {
			view.get_selection ().unselect_iter (item);
		}

		return false;
	}
}

