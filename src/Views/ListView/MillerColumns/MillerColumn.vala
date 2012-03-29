/*-
 * Copyright (c) 2011-2012 BeatBox Developers
 *
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

// FIXME: We've picked the wrong data structure here.
// TODO: Switch to HashMaps.
// TODO: Improve translations here and in the view model because the current system is too English-specific.

public class BeatBox.MillerColumns : Box {

	public signal void changed ();
	public signal void position_changed (Position p);

	public enum Position {
		AUTOMATIC = 0,
		LEFT      = 2,
		TOP       = 1
	}

	public LibraryManager lm { get; private set; }
	public LibraryWindow  lw { get; private set; }
	public ViewWrapper view_wrapper { get; private set; }


	public const int MIN_COLUMN_WIDTH = 100;
	public const int MIN_COLUMN_HEIGHT = 70;

	public bool is_music_miller {
		get {
			return view_wrapper.hint == ViewWrapper.Hint.MUSIC || view_wrapper.hint == ViewWrapper.Hint.DEVICE_AUDIO ||
			        view_wrapper.hint == ViewWrapper.Hint.CDROM;
		}
	}

	// All the media
	public Collection<int> medias {get; private set;}

	// Search results
	private LinkedList<int> _media_results;

	// Filtered media results. We provide the data. No need to search again outside
	public LinkedList<int> media_results { get {return _media_results;} }

	public Position position { get; private set; default = Position.AUTOMATIC; }
	public Position actual_position { get; set; default = Position.LEFT; }

	public LinkedList<unowned MillerColumn> columns {get; private set;}

	private Gtk.Menu column_chooser_menu;

	public MillerColumns(ViewWrapper view_wrapper) {
		this.lm = view_wrapper.lm;
		this.lw = view_wrapper.lw;
		this.view_wrapper = view_wrapper;

		orientation = Orientation.HORIZONTAL;

		_media_results = new LinkedList<int> ();

		columns = new LinkedList<unowned MillerColumn> ();

		column_chooser_menu = new Gtk.Menu ();

		// Inserting columns
		add_column (MillerColumn.Category.RATING);
		add_column (MillerColumn.Category.YEAR);
		add_column (MillerColumn.Category.GENRE);

		// These columns only make sense for songs.
		if (is_music_miller)
		{
			add_column (MillerColumn.Category.ARTIST);
			add_column (MillerColumn.Category.ALBUM);

			// Read visible columns from settings
			foreach (var col_n in lw.settings.get_music_miller_visible_columns ()) {
				foreach (var column in columns) {
					if (column.category == int.parse (col_n)) {
						column.visible = true;
						break;
					}
				}
			}
		}
		else {
			// Read visible columns from settings
			foreach (var col_n in lw.settings.get_generic_miller_visible_columns ()) {
				foreach (var column in columns) {
					if (column.category == int.parse (col_n)) {
						column.visible = true;
						break;
					}
				}
			}
		}

		// Position stuff
		position = (Position) lw.settings.get_miller_columns_position ();

		RadioMenuItem automatic_menu_item;
		RadioMenuItem left_menu_item;
		RadioMenuItem top_menu_item;

		automatic_menu_item = new RadioMenuItem.with_label ((SList<RadioMenuItem>) null, _("Automatic"));
		left_menu_item = new RadioMenuItem.with_label (automatic_menu_item.get_group (), _("On Left"));
		top_menu_item = new RadioMenuItem.with_label (left_menu_item.get_group (), _("On Top"));

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
		column_chooser_menu.append (top_menu_item);
		column_chooser_menu.append (left_menu_item);

		column_chooser_menu.show_all ();
	}

	/**
	 * Sets all the filters to "All ..."
	 */
	public void reset_filters () {
		foreach (var col in columns)
			col.select_first_item();	
	}

	public void set_columns_position (Position pos) {
		position = pos;

		lw.settings.set_miller_columns_position ((int) position);

		// Emit signal
		position_changed (position);
	}

	public MillerColumn? get_column (MillerColumn.Category type) {
		foreach (var column in columns) {
			if (column.category == type) {
				return column;
			}
		}

		critical ("Couldn't find column %s", type.to_string ());
		return null;
	}

	private MillerColumn add_column (MillerColumn.Category type) {
		// Setup column and connect signals
		var column = new MillerColumn (this, type);

		column.selection_changed.connect (column_selection_changed);

		// Set minimun size
		//column.set_size_request (MIN_COLUMN_WIDTH, MIN_COLUMN_HEIGHT);

		column.reset_requested.connect ( () => {
			column.select_first_item ();
		});

		columns.add (column);
		pack_start (column, true, true, 1);

		column_chooser_menu.append (column.menu_item);

		column.row_activated.connect (column_row_activated);
		column.header_clicked.connect (column_header_clicked);
				
		return column;
	}

	private void column_row_activated () {
		// Start playing the first media
		view_wrapper.play_first_media ();
	}

	private void column_selection_changed (MillerColumn.Category category, string val) {
		/**
		 * Since the columns follow a tree model, we have to re-populate all the columns
		 * that have a lower hierarchical level.
		 */

		var search_rating = -1; // ~ All
		var search_year   = -1; // ~ All
		var search_genre  = ""; // ~ All
		var search_artist = ""; // ~ All
		var search_album  = ""; // ~ All

		foreach (var col in columns) {
			// Higher hierarchical levels (parent columns)
			if (col.category < category) {
				if (col.category == MillerColumn.Category.GENRE) {
					search_genre = col.get_selected ();
				}
				else if (col.category == MillerColumn.Category.ARTIST) {
					search_artist = col.get_selected ();
				}
				else if (col.category == MillerColumn.Category.ALBUM) {
					search_album = col.get_selected ();
				}
				else if (col.category == MillerColumn.Category.YEAR) {
					search_year = (col.get_selected () == "") ? -1 : int.parse (col.get_selected ());
				}
				else if (col.category == MillerColumn.Category.RATING) {
					search_rating = (col.get_selected () == "") ? -1 : int.parse (col.get_selected ());
				}
			}
			else if (col.category == category) {
				if (col.category == MillerColumn.Category.GENRE) {
					search_genre = val;
				}
				else if (col.category == MillerColumn.Category.ARTIST) {
					search_artist = val;
				}
				else if (col.category == MillerColumn.Category.ALBUM) {
					search_album = val;
				}
				else if (col.category == MillerColumn.Category.YEAR) {
					search_year = (val == "") ? -1 : int.parse (val);
				}
				else if (col.category == MillerColumn.Category.RATING) {
					search_rating = (val == "") ? -1 : int.parse (val);
				}
			}
		}

		// Perform search
		lm.do_search (medias, out _media_results, null, null, null, null, view_wrapper.hint,
		              "", search_artist, search_album, search_genre, search_year, search_rating);

		// Now re-populate the child columns

		foreach (var column in columns) {
			// Child columns
			if (column.category > category) {
				var column_set = new HashMap<string, int> ();

				foreach(int id in _media_results) {
					var _media = lm.media_from_id(id);
					string _val = "";

					if (column.category == MillerColumn.Category.GENRE)
						_val = _media.genre;
					else if (column.category == MillerColumn.Category.ARTIST)
						_val = _media.album_artist;
					else if (column.category == MillerColumn.Category.ALBUM)
						_val = _media.album;
					else if (column.category == MillerColumn.Category.YEAR)
						_val = _media.year.to_string ();
					else if (column.category == MillerColumn.Category.RATING)
						_val = _media.rating.to_string ();

					column_set.set (_val, 1);
				}

				// The 'populate' method selects 'All # $category' automatically
				column.populate (column_set);
			}
		}

		// Notify others about the change
		changed ();
	}

	private void column_header_clicked (Gdk.EventButton e) {
		if (e.button == 3) { // secondary button
			column_chooser_menu.popup (null, null, null, 3, get_current_event_time ());
		}
	}

	public void populate(Collection<int> media, string? search = null) {
		this.medias = media;

		lm.do_search (media, out _media_results, /*out _album_results*/ null, null, null, null,
		              view_wrapper.hint, search ?? "");

		foreach (var column in columns) {
			var column_set = new HashMap<string, int>();

			foreach (int id in _media_results) {
				var _media = lm.media_from_id (id);
				string val = "";

				if (column.category == MillerColumn.Category.GENRE)
					val = _media.genre;
				else if (column.category == MillerColumn.Category.ARTIST)
					val = _media.album_artist;
				else if (column.category == MillerColumn.Category.ALBUM)
					val = _media.album;
				else if (column.category == MillerColumn.Category.YEAR)
					val = _media.year.to_string ();
				else if (column.category == MillerColumn.Category.RATING)
					val = _media.rating.to_string ();

				column_set.set (val, 1);
			}

			column.populate (column_set);
		}
		
		// FIXME: notify about the change here?
		changed();
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

		if (miller_parent.is_music_miller) 
			lw.settings.set_music_miller_visible_columns (visible_columns_list);
		else
			lw.settings.set_generic_miller_visible_columns (visible_columns_list);
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
	public void select_first_item (bool? notify = null) {
		set_selected (null, true);
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
		if (_selected == null || !this.visible)
			return "";

		return _selected;
	}

	public void set_selected (string? val, bool notify = false) {
		if (!lw.initializationFinished || val == _selected)
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

		view.get_selection ().changed.disconnect (selected_item_changed);

		items.unset ("");

		if (items.get(get_selected()) == 0) {
			select_first_item (false); // Don't notify
		}

		model = new MillerModel (get_category_text ());

		model.append_items (items.keys, false);
		model.set_sort_column_id (0, Gtk.SortType.ASCENDING);
		view.set_model (model);

		// select selected item
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

