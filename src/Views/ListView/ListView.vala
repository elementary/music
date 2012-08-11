/*
 * Copyright (c) 2012 Noise Developers
 *
 * This is a free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this program; see the file COPYING.  If not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Victor Eduardo <victoreduardm@gmail.com>
 */

/**
 * Contains the column browser and list view.
 */

using Gee;
using Gtk;

public class Noise.ListView : ContentView, Gtk.Box {
	public signal void reordered ();

	// Wrapper for the list view and miller columns
	private Granite.Widgets.SidebarPaned list_view_hpaned; // for left mode
	private Gtk.Paned list_view_vpaned; // for top mode

	public ColumnBrowser column_browser { get; private set; }
	public GenericList   list_view      { get; private set; }

	private ScrolledWindow list_scrolled;

	private int list_view_hpaned_position = -1;
	private int list_view_vpaned_position = -1;

	private ViewWrapper view_wrapper;
	private LibraryWindow lw;
	private LibraryManager lm;

	// UI Properties

	public bool has_column_browser  { get { return column_browser != null; } }

	public bool column_browser_enabled {
		get {
			return (has_column_browser) ? !column_browser.no_show_all : false;
		}
		private set {
			if (has_column_browser) {
				column_browser.set_no_show_all (!value);
				if (value) {
					// Populate column browser
					column_browser.show_all ();

					if (column_browser.media_results == null)
						column_browser.set_media (get_visible_media ());
				}
				else {
					// Before hiding, reset the filters to "All..."
					// We want all the media to be shown as soon as the user disables
					// the column browser
					column_browser.hide ();
					column_browser.reset_filters ();
				}
			}
		}
	}

	public ListView (ViewWrapper view_wrapper, TreeViewSetup tvs, bool add_browser = false) {

		this.view_wrapper = view_wrapper;
		this.lm = view_wrapper.lm;
		this.lw = view_wrapper.lw;

		this.list_scrolled = new ScrolledWindow (null, null);
		//this.list_scrolled.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);

		/* We'll re-take the hint based approach after 1.0. Right now MusicListView is our
		 * unique widget
		 */
#if 0
		switch (tvs.get_hint()) {
			case ViewWrapper.Hint.MUSIC:
			case ViewWrapper.Hint.HISTORY:
			case ViewWrapper.Hint.QUEUE:
			case ViewWrapper.Hint.PLAYLIST:
			case ViewWrapper.Hint.SMART_PLAYLIST:
			case ViewWrapper.Hint.AUDIOBOOK:
			case ViewWrapper.Hint.SIMILAR:
			case ViewWrapper.Hint.DEVICE_AUDIO:
			case ViewWrapper.Hint.DEVICE_AUDIOBOOK:
			case ViewWrapper.Hint.CDROM:
			//case ViewWrapper.Hint.ALBUM_LIST:
				list_view = new MusicListView (view_wrapper, tvs);
				break;
			default:
				critical ("NO LIST VIEW AVAILABLE FOR HINT -> %s", tvs.get_hint().to_string());
				// don't add anything
				break;
		}
#endif
		list_view = new MusicListView (view_wrapper, tvs);

		list_view.rows_reordered.connect ( () => {
			reordered ();
		});

		list_view.import_requested.connect ( (to_import) => {
			import_requested (to_import);
		});

		// Put the list inside a scrolled window
		list_scrolled.add (list_view);

		if (add_browser)
			column_browser = new MusicColumnBrowser (view_wrapper);

		if (has_column_browser) {
			list_view_hpaned = new Granite.Widgets.SidebarPaned ();
			list_view_vpaned = new Paned (Orientation.VERTICAL);

			// Fix theming
			list_view_vpaned.get_style_context().add_class (Gtk.STYLE_CLASS_VERTICAL);

			list_view_hpaned.pack2(list_view_vpaned, true, false);

			// Add hpaned (the most-external wrapper) to the view container
			this.pack_start (list_view_hpaned, true, true, 0);

			// Now pack the list view
			list_view_vpaned.pack2(list_scrolled, true, true);
			list_view_hpaned.pack1(column_browser, true, false);

			set_column_browser_position (column_browser.position);

			// Connect signals once the widget has been realized to avoid writing to settings
			// on startup
			this.realize.connect (connect_column_browser_ui_signals);

			column_browser_enabled = lw.savedstate_settings.column_browser_enabled;

			// Connect data signals
			column_browser.changed.connect (column_browser_changed);
		}
		else {
			this.pack_start (list_scrolled, true, true, 0);
		}
	}

	private void set_column_browser_position (Noise.BrowserPosition position) {
		if (!has_column_browser)
			return;

		Noise.BrowserPosition actual_position = position; //position that will be actually applied

		if (actual_position == Noise.BrowserPosition.AUTOMATIC) {
			// Decide what orientation to use based on the view area size

			int view_width = this.get_allocated_width ();
			const int MIN_RECOMMENDED_COLUMN_WIDTH = 160;

			int visible_columns = 0;
			foreach (var column in column_browser.columns) {
				if (column.visible)
					++ visible_columns;
			}


			// Checks width and number of visible columns
			int required_width = MIN_RECOMMENDED_COLUMN_WIDTH * visible_columns;
			int n_cols = 0;
			foreach (var column in list_view.get_columns ()) {
				if (column.visible)
					n_cols ++;
			}

			if (view_width - required_width < list_view.get_allocated_width () && n_cols > 2
			    && visible_columns > 2)
				actual_position = Noise.BrowserPosition.TOP;
			else
				actual_position = Noise.BrowserPosition.LEFT;
		}

		column_browser.actual_position = actual_position;

		if (actual_position == Noise.BrowserPosition.LEFT) {
			if (list_view_hpaned.get_child1() == null && list_view_vpaned.get_child1() == column_browser) {
				list_view_vpaned.remove (column_browser);
				list_view_hpaned.pack1 (column_browser, true, false);

				list_view_hpaned.position = list_view_hpaned_position;
			}
		}
		else if (actual_position == Noise.BrowserPosition.TOP) {
			if (list_view_vpaned.get_child1() == null && list_view_hpaned.get_child1() == column_browser) {
				list_view_hpaned.remove (column_browser);
				list_view_vpaned.pack1 (column_browser, true, false);

				list_view_vpaned.set_position (list_view_vpaned_position);
			}
		}
	}

	private void connect_column_browser_ui_signals () {
		if (!has_column_browser)
			return;

		// For automatic position stuff
		this.size_allocate.connect ( () => {
			if (!lw.initialization_finished)
				return;

			if (column_browser.position == Noise.BrowserPosition.AUTOMATIC)
				set_column_browser_position (Noise.BrowserPosition.AUTOMATIC);
		});

		column_browser.size_allocate.connect ( () => {
			if (!lw.initialization_finished || !column_browser_enabled)
				return;

			if (column_browser.actual_position == Noise.BrowserPosition.LEFT) {
				if (list_view_hpaned.position > 0)
					list_view_hpaned_position = list_view_hpaned.position;
			}
			else if (column_browser.actual_position == Noise.BrowserPosition.TOP) {
				if (list_view_vpaned.position > 0)
					list_view_vpaned_position = list_view_vpaned.position;
			}
		});

		lw.column_browser_toggle.toggled.connect ( () => {
			if (view_wrapper.current_view == ViewWrapper.ViewType.LIST && lw.column_browser_toggle.sensitive) {
				bool enabled = lw.column_browser_toggle.get_active();
				if (enabled != column_browser_enabled)
					column_browser_enabled = enabled;
			}
		});

		column_browser.position_changed.connect (set_column_browser_position);

		// Read Paned position from settings
		list_view_hpaned_position = lw.savedstate_settings.column_browser_width;
		list_view_vpaned_position = lw.savedstate_settings.column_browser_height;

		list_view_hpaned.position = list_view_hpaned_position;
		list_view_vpaned.position = list_view_vpaned_position;

		// We only save the settings when this view wrapper is being destroyed. This avoids unnecessary
		// disk access to write settings.
		destroy.connect (save_column_browser_settings);
	}

	private void save_column_browser_settings () {
		// Need to add a proper fix later ...
		if (has_column_browser) {
			if (column_browser.visible) {
				if (column_browser.actual_position == Noise.BrowserPosition.LEFT)
					lw.savedstate_settings.column_browser_width = list_view_hpaned_position;
				else if (column_browser.actual_position == Noise.BrowserPosition.TOP)
					lw.savedstate_settings.column_browser_height = list_view_vpaned_position;
			}

			lw.savedstate_settings.column_browser_enabled = column_browser_enabled;
		}
	}

	/**
	 * ContentView interface methods
	 */

	public ViewWrapper.Hint get_hint () {
		return list_view.get_hint ();
	}

	public int get_relative_id () {
		return list_view.get_relative_id ();
	}

	public Gee.Collection<Media> get_media () {
		var media_list = new Gee.LinkedList<Media> ();
		foreach (var m in list_view.get_table ().get_values ()) {
		    if (m != null)
			    media_list.add ((Media) m);
		}

		return media_list;
	}

	public Gee.Collection<Media> get_visible_media () {
		var media_list = new Gee.LinkedList<Media> ();
		foreach (var m in list_view.get_visible_table ().get_values ()) {
		    if (m != null)
			    media_list.add ((Media) m);
		}

		return media_list;
	}

	private void column_browser_changed () {
		/* This method is only called if the column browser is available.
		 * For performance reasons we won't update visible_media to match
		 * the results of the miller columns.
		 */
		if (lw.initialization_finished) {
			list_view.set_media (column_browser.media_results);
			view_wrapper.update_statusbar_info ();
		}
	}

	// TODO: Since is_initial is deprecated and not used, update the external code to stop using it
	public void set_as_current_list (int media_id, bool is_initial = false) {
		list_view.set_as_current_list (lm.media_from_id (media_id));
	}

	public bool get_is_current_list ()  {
		return list_view.get_is_current_list ();
	}

	public void add_media (Gee.Collection<Media> to_add) {
    	list_view.add_media (to_add);
		if (has_column_browser)
            column_browser.set_media (get_visible_media ());
	}

	public void remove_media (Gee.Collection<Media> to_remove) {
    	list_view.remove_media (to_remove);
		if (has_column_browser)
            column_browser.set_media (get_visible_media ());
	}

	public void set_media (Gee.Collection<Media> media) {
		list_view.set_media (media);
		if (has_column_browser)
			column_browser.set_media (media);
	}
}
