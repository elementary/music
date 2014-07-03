/*-
 * Copyright (c) 2011-2012 Noise Developers
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

public class Noise.BrowserColumn : Gtk.Grid {
	public signal void selection_changed (BrowserColumn.Category type, string val);
	public signal void row_activated (string text);
	public signal void reset_requested ();
	public signal void header_clicked (Gdk.EventButton e);
    public signal void visibility_changed (bool visible);

	public enum Category {
        RATING,
        GROUPING,
        YEAR,
        GENRE,
        COMPOSER,
        ARTIST,
        ALBUM,
        N_CATEGORIES;

        public static Category first () {
            return (Category) 0;
        }

        public static Category last () {
            return (Category) (N_CATEGORIES - 1);
        }

        public string to_string () {
		    switch (this) {
			    case Category.GENRE:
				    return _("Genres");
			    case Category.ARTIST:
				    return _("Artists");
			    case Category.ALBUM:
				    return _("Albums");
			    case Category.YEAR:
				    return _("Years");
			    case Category.RATING:
				    return _("Ratings");
			    case Category.COMPOSER:
				    return _("Composers");
			    case Category.GROUPING:
				    return _("Groupings");
                default:
                    assert_not_reached ();
		    }
        }
	}

	public new bool visible {
		get {
			return !this.no_show_all;
		}
		set {
			bool show_column = value;

			this.menu_item.active = show_column;
			this.no_show_all = !show_column;

			if (show_column) {
				show_all ();
			}
			else { // if the column is being hidden, make sure we select "All ..."
			   	select_first_item ();
                hide ();
            }

            this.visibility_changed (!no_show_all);
		}
	}

	private Gtk.Separator separator;
	public bool show_separator {
		set {
			if (separator != null && separator.parent == this) {
				remove (separator);
				separator = null;
			}

			if (value) {
				separator = new Gtk.Separator (Gtk.Orientation.VERTICAL);
				separator.hexpand = false;
				separator.vexpand = true;
				separator.show ();
				add (separator);
			}
		}
	}

	public bool first_item_selected { get { return _selected == null; } }

	public Category category { get; construct set; }
	public Gtk.CheckMenuItem menu_item { get; construct set;}

	private ColumnBrowser miller_parent;

	private Gtk.TreeView view;
	private BrowserColumnModel model;

	// This will be NULL whenever the first element "All" is selected.
	private string? _selected;

	public BrowserColumn (ColumnBrowser miller_parent, Category category) {
		this.miller_parent = miller_parent;
		this.category = category;
		orientation = Gtk.Orientation.HORIZONTAL;

		menu_item = new Gtk.CheckMenuItem.with_label (category.to_string ());
		this.visible = false;

		view = new Gtk.TreeView ();
		model = new BrowserColumnModel (category);

		var cell = new Gtk.CellRendererText ();
		cell.ellipsize = Pango.EllipsizeMode.END;

		view.insert_column_with_attributes (-1, category.to_string (), cell, "text", 0, null);

		var scrolled = new Gtk.ScrolledWindow (null, null);
		scrolled.expand = true;
		scrolled.add (view);
		add (scrolled);

		view.set_headers_clickable (true);

		menu_item.toggled.connect (on_menu_item_toggled);
		view.row_activated.connect (view_double_click);

        var column = view.get_column (0);
		column.set_alignment (0.5f);
		column.get_button ().button_press_event.connect (on_header_clicked);
        view.get_selection ().mode = Gtk.SelectionMode.BROWSE;
	}

	private void on_menu_item_toggled () {
		if (!this.menu_item.sensitive || this.menu_item.active == visible)
			return;

		this.menu_item.toggled.disconnect (on_menu_item_toggled);

		int visible_columns = 0;

		foreach (var col in miller_parent.columns) {
			if (col.visible)
				visible_columns ++;
		}

		if (menu_item.active)
			visible_columns ++;
		else
			visible_columns --;

		this.visible = this.menu_item.active;

		foreach (var col in miller_parent.columns) {
			if (col.visible) {
				// don't allow disabling an element if it's the last visible column.
				col.menu_item.set_sensitive (visible_columns > 1);
			}
		}

		this.menu_item.toggled.connect (on_menu_item_toggled);

        view.get_selection ().changed.connect_after (selected_item_changed);
	}


	public void add_item (string text) {
		Gtk.TreeIter iter;

		model.append (out iter);
		model.set (iter, 0, text);
	}


	// selects "All ..."
	public void select_first_item () {
		if (model == null)
			return;

		if (!first_item_selected)
			set_selected (null, true); // always notify
		else if (model.n_items + 1 >= 1 && this.visible && App.main_window.initialization_finished) // FIXME: Use this.get_realized ()
			//...just scroll to the cell
			view.scroll_to_cell (new Gtk.TreePath.first(), null, false, 0.0f, 0.0f);
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

	public void populate (Gee.HashSet<string> items) {
		items.remove ("");

		view.get_selection ().freeze_notify ();
		model = new BrowserColumnModel (category);
		view.set_model (null);

		model.append_items (items, false);
		model.set_sort_column_id (0, Gtk.SortType.ASCENDING);

		view.set_model (model);

		// Set selected item
        //
		// This checks whether we can keep the current selected item selected in the column.
		// If we cannot, we select "All ..." (first item). Please notice that we don't
		// select_first_item() because model.foreach() will be called next. It will handle
		// the selection update.
		if (!items.contains (this.get_selected ()))
            _selected = null; // i.e. first_item_selected

		model.foreach (select_proper_string);

		view.get_selection ().thaw_notify ();
	}

	public void set_selected (string? val, bool notify = false) {
		if (model != null && (!App.main_window.initialization_finished || val == _selected))
			return;

		_selected = val;

		model.foreach (select_proper_string);

		if (notify) {
			Idle.add_full (Priority.DEFAULT_IDLE - 10, () => {
				selection_changed (category, get_selected ());
				return false;
			});
		}
	}

	private bool on_header_clicked (Gtk.Widget w, Gdk.EventButton e) {
		 // Scroll to top (select 'All') if the primary button is clicked
		if (e.button == Gdk.BUTTON_PRIMARY) {
			select_first_item ();
		}

		// emit signal
		header_clicked (e);

		return true;
	}

	private void selected_item_changed () {
		Gtk.TreeModel tempModel;
		Gtk.TreeIter iter;
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

	private void view_double_click (Gtk.TreePath path, Gtk.TreeViewColumn column) {
		Gtk.TreeIter iter;
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

	private bool select_proper_string (Gtk.TreeModel tmodel, Gtk.TreePath path, Gtk.TreeIter item) {
		if (first_item_selected) {
		    var first_path = new Gtk.TreePath.first ();
			view.get_selection ().select_path (first_path);
			view.scroll_to_cell (first_path, null, true, 0.0f, 0.0f);
			return true;
		}

		string s;
		tmodel.get (item, 0, out s);

		if (s == get_selected ()) {
			view.get_selection ().select_iter (item);

            // If the cell is not within the visible range, scroll to center
            // rather than top (improves usability)
            bool scroll_to_center = false;
            Gtk.TreePath start, end;

            if (view.get_visible_range (out start, out end)) {
                int start_index = start.get_indices ()[0];
                int end_index = end.get_indices ()[0];
                int current_index = path.get_indices ()[0];

                if (current_index < start_index || current_index > end_index)
                    scroll_to_center = true;
            }

			view.scroll_to_cell (path, null, scroll_to_center, 0.5f, 0.0f);

			return true;
		}

		view.get_selection ().unselect_iter (item);

		return false;
	}
}