/*
 * Copyright (c) 2012 BeatBox Developers
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
 * Contains the miller columns and list view.
 */

using Gee;
using Gtk;

public class BeatBox.ListView : ContentView, Gtk.Box {

	// Wrapper for the list view and miller columns
	private Gtk.Paned list_view_hpaned; // for left mode
	private Gtk.Paned list_view_vpaned; // for top mode

	public MillerColumns column_browser { get; private set; }
	public GenericList   list_view { get; private set; }

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

					if (column_browser.medias == null)
						column_browser.populate (view_wrapper.get_showing_media_ids());
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

	public ListView (ViewWrapper view_wrapper, TreeViewSetup tvs) {

		this.view_wrapper = view_wrapper;
		this.lm = view_wrapper.lm;
		this.lw = view_wrapper.lw;

		this.list_scrolled = new ScrolledWindow (null, null);
		//this.list_scrolled.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);

		switch (tvs.get_hint()) {

			case ViewWrapper.Hint.MUSIC:
			case ViewWrapper.Hint.HISTORY:
			case ViewWrapper.Hint.QUEUE:
			case ViewWrapper.Hint.PLAYLIST:
			case ViewWrapper.Hint.SMART_PLAYLIST:
			case ViewWrapper.Hint.AUDIOBOOK:
			case ViewWrapper.Hint.DEVICE_AUDIOBOOK:
			case ViewWrapper.Hint.CDROM:
			case ViewWrapper.Hint.SIMILAR:
			//case ViewWrapper.Hint.ALBUM_LIST:
				list_view = new MusicTreeView (view_wrapper, tvs);
				break;
#if HAVE_PODCASTS
			case ViewWrapper.Hint.PODCAST:
			case ViewWrapper.Hint.DEVICE_PODCAST:
				list_view = new PodcastListView (view_wrapper, tvs);
				break;
#endif
#if HAVE_INTERNET_RADIO
			case ViewWrapper.Hint.STATION:
				list_view = new RadioListView(view_wrapper, tvs);
				break;
#endif
			default:
				critical ("NO LIST VIEW AVAILABLE FOR HINT -> %s", tvs.get_hint().to_string());
				// don't add anything
				break;
		}


		// Currently only the music-library view should have a column browser
		if (view_wrapper.hint == ViewWrapper.Hint.MUSIC)
			column_browser = new MillerColumns (view_wrapper);

		// Put the list inside a scrolled window
		list_scrolled.add (list_view);

		if (has_column_browser) {
			list_view_hpaned = new Paned (Orientation.HORIZONTAL);
			list_view_vpaned = new Paned (Orientation.VERTICAL);

			// Fix theming
			list_view_hpaned.get_style_context().add_class (Gtk.STYLE_CLASS_HORIZONTAL);
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

			column_browser_enabled = lw.settings.get_miller_columns_enabled();

			// Connect data signals
			column_browser.changed.connect (column_browser_changed);
		}
		else {
			this.pack_start (list_scrolled, true, true, 0);
		}

		// Set sort data from saved session
		list_view.set_sort_column_id(tvs.sort_column_id, tvs.sort_direction);

		// We only save the settings when this view wrapper is being destroyed. This avoids unnecessary
		// disk access to write settings.
		destroy.connect (on_quit);
	}

	private void set_column_browser_position (MillerColumns.Position position) {
		if (!has_column_browser)
			return;

		MillerColumns.Position actual_position = position; //position that will be actually applied

		if (actual_position == MillerColumns.Position.AUTOMATIC) {
			// Decide what orientation to use based on the view area size

			int view_width = this.get_allocated_width ();
			const int MIN_RECOMMENDED_TREEVIEW_WIDTH = 300;
			const int MIN_RECOMMENDED_COLUMN_WIDTH = 160;

			int visible_columns = 0;
			foreach (var column in column_browser.columns) {
				if (column.visible)
					++ visible_columns;
			}

			int required_width = MIN_RECOMMENDED_COLUMN_WIDTH * visible_columns;
			if (view_width - required_width < MIN_RECOMMENDED_TREEVIEW_WIDTH)
				actual_position = MillerColumns.Position.TOP;
			else
				actual_position = MillerColumns.Position.LEFT;
		}

		column_browser.actual_position = actual_position;

		if (actual_position == MillerColumns.Position.LEFT) {
			if (list_view_hpaned.get_child1() == null && list_view_vpaned.get_child1() == column_browser) {
				list_view_vpaned.remove (column_browser);
				list_view_hpaned.pack1 (column_browser, true, false);

				list_view_hpaned.set_position (list_view_hpaned_position);
			}
		}
		else if (actual_position == MillerColumns.Position.TOP) {
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

			if (column_browser.position == MillerColumns.Position.AUTOMATIC)
				set_column_browser_position (MillerColumns.Position.AUTOMATIC);
		});

		column_browser.size_allocate.connect ( () => {
			if (!lw.initialization_finished || !column_browser_enabled)
				return;

			if (column_browser.actual_position == MillerColumns.Position.LEFT) {
				if (list_view_hpaned.position > 0)
					list_view_hpaned_position = list_view_hpaned.position;
			}
			else if (column_browser.actual_position == MillerColumns.Position.TOP) {
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
		list_view_hpaned_position = lw.settings.get_miller_columns_width ();
		list_view_vpaned_position = lw.settings.get_miller_columns_height ();

		list_view_hpaned.position = list_view_hpaned_position;
		list_view_vpaned.position = list_view_vpaned_position;
	}

	private void on_quit () {
		// Need to add a proper fix later ...
		if (has_column_browser) {
			if (column_browser.visible) {
				if (column_browser.actual_position == MillerColumns.Position.LEFT)
					lw.settings.set_miller_columns_width(list_view_hpaned_position);
				else if (column_browser.actual_position == MillerColumns.Position.TOP)
					lw.settings.set_miller_columns_height(list_view_vpaned_position);
			}

			lw.settings.set_miller_columns_enabled (column_browser_enabled);
		}
	}

	/**
	 * Data and ContentView interface stuff ...
	 */

	public ViewWrapper.Hint get_hint () {
		return list_view.get_hint ();
	}

	public int get_relative_id () {
		return list_view.get_relative_id ();
	}


	public GLib.List<Media> get_media () {
		return list_view.get_table().get_values ();
	}

	public GLib.List<Media> get_showing_media () {
		return list_view.get_visible_table().get_values ();
	}


	public Gee.Collection<int> get_media_ids () {
		var rv = new Gee.LinkedList<int> ();
		foreach (var val in list_view.get_table().get_values ()) {
			rv.add (val.rowid);
		}
		return rv;
	}

	public Gee.Collection<int> get_showing_media_ids () {
		var rv = new Gee.LinkedList<int> ();
		foreach (var val in list_view.get_visible_table().get_values ()) {
			rv.add (val.rowid);
		}
		return rv;
	}
	
	// XXX: fix column browser stuff!
	// THIS IS CRITICAL!

	public async void populate_view () {
		if (column_browser_enabled)
			// This will emit the changed() signal and then column_browser_changed will be called.
			// We can't avoid re-populating the entire column browser and then the list view
			// for performance reasons. We don't guarantee persistent selections if the column
			// browser is enabled.
			
			// TODO: Try to avoid requesting information from the view wrapper in the future.
			column_browser.populate (view_wrapper.get_showing_media_ids());
		/*else
			list_view.populate_view ();*/
	}

	private async void column_browser_changed () {
		// This method is only called if the column browser is available.
		// For performance reasons we won't update showing_medias to match
		// the results of the miller columns.

		if(lw.initialization_finished) {
			set_show_next (column_browser.media_results);
			view_wrapper.set_statusbar_info (column_browser.media_results);
		}
	}

	/* ---------- NEW API --------- */
	// remember to include column-browser stuff

	public void set_as_current_list (int media_id, bool is_initial = false) {
		list_view.set_as_current_list (media_id, is_initial);
	}


	public bool get_is_current_list ()  {
		return list_view.get_is_current_list ();
	}

	public async void set_show_next (Gee.Collection<int> to_show) {
		int index = 0;
		var media = new HashTable<int, Media> (null, null);
		foreach (int id in to_show) {
			media.set (index++, lm.media_from_id (id));
		}

		// Populate column browser
		// column_browser.populate (to_show);
		
		list_view.set_table (media);
	}

	public async void append_media (Gee.Collection<int> media) {
		if (column_browser_enabled)
			column_browser.populate (view_wrapper.get_showing_media_ids());
		else {
			var to_add = new GLib.List<Media> ();
			foreach (int id in media) {
				var m = lm.media_from_id (id);
				if (m != null)
					to_add.append (m);
			}
		
			list_view.add_media (to_add);
		}
	}

	public async void remove_media (Gee.Collection<int> media) {
		if (column_browser_enabled)
			column_browser.populate (view_wrapper.get_showing_media_ids());
		else {
			var to_remove = new HashTable<Media, int> (null, null);
			int index = 0;
			foreach (int id in media) {
				to_remove.set (lm.media_from_id (id), index++);
			}
	
			list_view.remove_media (to_remove);
		}
	}

	/* EXTRA METHODS.
	 * TODO: This shouldn't be here. Just added since there's no time to standarize this stuff
	 *        right now.
	 */

	public async void set_table (HashTable<int, Media> table) {
		list_view.set_table (table);
	}
}

