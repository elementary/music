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

using Gtk;
using Gee;

public class Noise.BrowserColumn : Gtk.ScrolledWindow {

	public signal void selection_changed (BrowserColumn.Category type, string val);
	public signal void row_activated (string text);
	public signal void reset_requested ();
	public signal void header_clicked (Gdk.EventButton e);
    public signal void visibility_changed (bool visible);

	public enum Category {
        RATING,
        YEAR,
        GENRE,
        ARTIST,
        ALBUM;

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
                default:
                    return "Unknown";
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

	public bool first_item_selected { get { return _selected == null; } }

	public Category category { get; construct set; }
	public CheckMenuItem menu_item { get; construct set;}

	private ColumnBrowser miller_parent;
	private LibraryManager lm;
	private LibraryWindow lw;

	private TreeView view;
	private BrowserColumnModel model;

	// This will be NULL whenever the first element "All" is selected.
	private string? _selected;



	public BrowserColumn (ColumnBrowser miller_parent, Category category) {
		this.miller_parent = miller_parent;
		this.category = category;

		lw = miller_parent.lw;
		lm = miller_parent.lm;

		menu_item = new CheckMenuItem.with_label (category.to_string ());
		this.visible = false;

		view = new TreeView ();
		model = new BrowserColumnModel (category);

		var cell = new CellRendererText ();
		cell.ellipsize = Pango.EllipsizeMode.END;

		view.insert_column_with_attributes (-1, category.to_string (), cell, "text", 0, null);

		add (view);

		view.set_headers_clickable (true);

		view.get_column (0).set_alignment (0.5f);

		menu_item.toggled.connect (on_menu_item_toggled);
		view.get_column (0).get_button ().button_press_event.connect (on_header_clicked);
		view.row_activated.connect (view_double_click);
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
		TreeIter iter;

		model.append (out iter);
		model.set (iter, 0, text);
	}


	// selects "All ..."
	public void select_first_item () {
		if (model == null)
			return;

		if (!first_item_selected)
			set_selected (null, true); // always notify
		else if (model.n_items + 1 >= 1 && this.visible && lw.initialization_finished) // FIXME: Use this.get_realized ()
			//...just scroll to the cell
			view.scroll_to_cell (new TreePath.first(), null, false, 0.0f, 0.0f);
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

	public async void populate (HashMap<string, int> items) {
		view.get_selection ().freeze_notify ();

		items.unset ("");

		view.set_model (null);

		model = new BrowserColumnModel (category);

		model.append_items (items.keys, false);
		model.set_sort_column_id (0, Gtk.SortType.ASCENDING);

		view.set_model (model);

		// set selected item

		// This checks whether we can keep the current selected item selected in the column.
		//if (!items.has_key (this.get_selected ())) {
			select_first_item ();
		//}

		model.foreach (select_proper_string);

		view.get_selection ().thaw_notify ();
	}

	public void set_selected (string? val, bool notify = false) {
		if (model != null && (!lw.initialization_finished || val == _selected))
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

	private bool on_header_clicked (Widget w, Gdk.EventButton e) {
		 // Scroll to top (select 'All') if the primary button is clicked
		if (e.button == Gdk.BUTTON_PRIMARY) {
			select_first_item ();
		}

		// emit signal
		header_clicked (e);

		return true;
	}

	private void selected_item_changed () {
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

	private void view_double_click (TreePath path, TreeViewColumn column) {
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

	private bool select_proper_string (TreeModel tmodel, TreePath path, TreeIter item) {
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
