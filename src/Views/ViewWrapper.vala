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

using Gtk;
using Granite.Widgets;
using Gee;

public class BeatBox.ViewWrapper : Box {

	public LibraryManager lm { get; private set; }
	public LibraryWindow  lw { get; private set; }

	/* MAIN WIDGETS (VIEWS) */
	public ContentView   list_view      { get; private set; }
	public ContentView   album_view     { get; private set; }
	public MillerColumns column_browser { get; private set; }
	public WarningLabel  error_box      { get; private set; }
	public Welcome       welcome_screen { get; private set; }

	// Wrapper for the list view and miller columns
	private Box   list_view_container;
	private Paned list_view_hpaned; // for left mode
	private Paned list_view_vpaned; // for top mode
	private int   list_view_hpaned_position = -1;
	private int   list_view_vpaned_position = -1;

	private Notebook view_container; // Wraps all the internal views for super fast switching

	/**
	 * Type of visual representation of the media.
	 *
	 * IMPORTANT: Values _must_ match the index of the respective view in the view selector.
	 */
	public enum ViewType {
		ALBUM   = 0, // Matches index 0 of the view in lw.viewSelector
		LIST    = 1, // Matches index 1 of the view in lw.viewSelector
		ERROR   = 2, // For error boxes
		WELCOME = 3, // For welcome screens
		NONE    = 4  // Custom views
	}

	public ViewType current_view { get; private set; }

	/**
	 * This is by far the most important property of this object.
	 * It defines how child widgets behave and some other properties.
	 */
	public enum Hint {
		NONE,
		MUSIC,
		PODCAST,
		AUDIOBOOK,
		STATION,
		SIMILAR,
		QUEUE,
		HISTORY,
		PLAYLIST,
		SMART_PLAYLIST,
		CDROM,
		DEVICE_AUDIO,
		DEVICE_PODCAST,
		DEVICE_AUDIOBOOK,
		ALBUM_LIST;
	}

	public Hint hint { get; private set; }
	public int relative_id { get; private set; }


	public int index { get { return lw.mainViews.page_num(this); } }

	public bool is_current_wrapper {
		get {
			return (lw.initializationFinished ? (index == lw.mainViews.get_current_page()) : false);
		}
	}


	/* UI PROPERTIES */

	public bool have_album_view      { get { return album_view != null;     } }
	public bool have_list_view       { get { return list_view != null;      } }
	public bool have_column_browser  { get { return column_browser != null; } }
	public bool have_error_box       { get { return error_box != null;      } }
	public bool have_welcome_screen  { get { return welcome_screen != null; } }

	public bool column_browser_enabled {
		get {
			return (have_column_browser) ? !column_browser.no_show_all : false;
		}
		private set {
			if (have_column_browser) {
				column_browser.set_no_show_all (!value);
				if (value) {
					// Populate column browser
					column_browser.show_all ();

					if (column_browser.medias == null)
						column_browser.populate (get_showing_media_ids());
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

	/**
	 * This boolean is extremely important. It defines whether we show the views or not,
	 * and also other widgets, like the error box or welcome screen.
	 */
	public bool have_media { get { return media_count > 0; } }


	/**
	 * MEDIA DATA
	 *
	 * These data structures hold information about the media shown in the views.
	 **/

	// ALL the media. Data source.
	public HashMap<int, int> medias { get; private set; }

	public int media_count { get { return (medias != null) ? medias.size : 0; } }

	// Media that's currently showed. Only used for search results
	public HashMap<int, int> showing_medias { get; private set; }

	// Holds the last search results (timeout). Helps to prevent useless search.
	private LinkedList<string> timeout_search;

	// Stops from searching same thing multiple times
	private string last_search = "";

	public string get_search_string () {
		return last_search;
	}

	// Stops from searching unnecesarilly when changing b/w 0 words and search.
	private bool showing_all { get { return showing_media_count == media_count; } }

	public int showing_media_count { get { return (showing_medias != null) ? showing_medias.size : 0; } }

	private bool setting_search = false;

	public bool needs_update;

	// for Hint.SIMILAR only
	public bool similarsFetched;
	private bool in_update;
	private bool initialized;


	public ViewWrapper (LibraryWindow lw, Collection<int> the_medias, string sort, Gtk.SortType dir,
	                     Hint the_hint, int id)
	{
		debug ("BUILDING %s", the_hint.to_string());

		orientation = Orientation.VERTICAL;
		initialized = false;

		this.lm = lw.lm;
		this.lw = lw;

		this.relative_id = id;
		this.hint = the_hint;

		medias = new HashMap<int, int>();
		showing_medias = new HashMap<int, int>();
		timeout_search = new LinkedList<string>();

		foreach(int i in the_medias)
			medias.set(i, 1);

		// Setup view container
		view_container = new Notebook ();
		view_container.show_tabs = false;
		view_container.show_border = false;
		this.pack_start (view_container, true, true, 0);

		switch (the_hint) {
			case Hint.MUSIC:
				// list, album and column views
				album_view = new AlbumView (this, get_media_ids());
				list_view = new MusicTreeView (this, sort, dir, the_hint, id);
				column_browser = new MillerColumns (this);
				break;
			case Hint.SIMILAR:
				// list view only
				list_view = new SimilarPane(this);

				error_box = new WarningLabel();
				error_box.show_icon = false;
				error_box.setWarning ("<span weight=\"bold\" size=\"larger\">" + _("Similar Media View") + "</span>\n\n" + _("In this view, BeatBox will automatically find medias similar to the one you are playing.") + "\n" + _("You can then start playing those medias, or save them for later."));
				break;
			case Hint.PODCAST:
				// list, album and column views
				list_view = new PodcastListView (this);
				column_browser = new MillerColumns (this);
				album_view = new AlbumView (this, get_media_ids());

				error_box = new WarningLabel();
				error_box.show_icon = false;
				error_box.setWarning ("<span weight=\"bold\" size=\"larger\">" + _("No Podcasts Found") + "</span>\n\n" + _("To add a podcast, visit a website such as Miro Guide to find RSS Feeds.") + "\n" + _("You can then copy and paste the feed into the \"Add Podcast\" window by right clicking on \"Podcasts\"."));

				break;
			case Hint.DEVICE_PODCAST:
				// list, album and column views
				list_view = new PodcastListView (this);
				column_browser = new MillerColumns (this);
				album_view = new AlbumView (this, get_media_ids());

				error_box = new WarningLabel();
				error_box.show_icon = false;
				error_box.setWarning ("<span weight=\"bold\" size=\"larger\">" + _("No Podcasts Found") + "</span>\n\n" + _("To add a podcast, visit a website such as Miro Guide to find RSS Feeds.") + "\n" + _("You can then copy and paste the feed into the \"Add Podcast\" window by right clicking on \"Podcasts\"."));

				break;
			case Hint.STATION:
				// list and column view
				list_view = new RadioListView(this, sort, dir, the_hint, id);
				column_browser = new MillerColumns (this);

				error_box = new WarningLabel();
				error_box.show_icon = false;
				error_box.setWarning ("<span weight=\"bold\" size=\"larger\">" + _("No Internet Radio Stations Found") + "</span>\n\n" + _("To add a station, visit a website such as SomaFM to find PLS or M3U files.") + "\n" + _("You can then import the file to add the station."));

				break;
			case Hint.AUDIOBOOK:
				// list, album and column views
				list_view = new MusicTreeView(this, sort, dir, the_hint, id);
				column_browser = new MillerColumns (this);
				album_view = new AlbumView (this, get_media_ids());

				break;
			case Hint.DEVICE_AUDIOBOOK:
				// list, album and column views
				list_view = new MusicTreeView(this, sort, dir, the_hint, id);
				column_browser = new MillerColumns (this);
				album_view = new AlbumView (this, get_media_ids());

				break;
			case Hint.CDROM:
				// list view only
				list_view = new MusicTreeView (this, sort, dir, the_hint, id);

				error_box = new WarningLabel();
				error_box.show_icon = true;
				error_box.setWarning ("<span weight=\"bold\" size=\"larger\">" + _("Audio CD Invalid") + "</span>\n\n" + _("BeatBox could not read the contents of this Audio CD."));

				break;
			default:
				// list and album views
				album_view = new AlbumView (this, get_media_ids());
				list_view = new MusicTreeView (this, sort, dir, the_hint, id);

				break;
		}

		// Now setup the view wrapper based on available widgets

		if (have_error_box) {
			view_container.append_page (error_box);
			current_view = ViewType.ERROR;
		}

		if (have_welcome_screen) {
			view_container.append_page (welcome_screen);
			current_view = ViewType.WELCOME;
		}

		if (have_album_view)
			view_container.append_page (album_view);

		if (have_list_view) {
			list_view_container = new Box (Orientation.HORIZONTAL, 0);

			if (have_column_browser) {
				list_view_hpaned = new Paned (Orientation.HORIZONTAL);
				list_view_vpaned = new Paned (Orientation.VERTICAL);

				// Fix theming
				list_view_hpaned.get_style_context().add_class (Gtk.STYLE_CLASS_HORIZONTAL);
				list_view_vpaned.get_style_context().add_class (Gtk.STYLE_CLASS_VERTICAL);

				list_view_hpaned.pack2(list_view_vpaned, true, false);

				// Add hpaned (the most-external wrapper) to the view container
				list_view_container.pack_start (list_view_hpaned, true, true, 0);

				// Now pack the list view
				list_view_vpaned.pack2(list_view, true, true);
				list_view_hpaned.pack1(column_browser, true, true);

				set_column_browser_position (column_browser.position);

				this.realize.connect (connect_column_browser_ui_signals);

				column_browser_enabled = lw.settings.get_miller_columns_enabled();

				// Connect data signals
				column_browser.changed.connect (column_browser_changed);
			}
			else {
				list_view_container.pack_start (list_view, true, true, 0);
			}

			view_container.append_page (list_view_container);
		}

		lm.medias_updated.connect ((list) => { update_media (list); });
		
		if (hint != Hint.CDROM)
			lm.medias_removed.connect ((list) => { remove_media (list); });

		if (hint == Hint.QUEUE)
			lm.media_queued.connect ( (media_id) => {
				var list = new LinkedList<int>();
				list.add (media_id);
				add_media (list);
			});
		else if (hint != Hint.CDROM)
			lm.medias_added.connect ((list) => { add_media (list); });

		lw.searchField.changed.connect (search_field_changed);
		lw.viewSelector.mode_changed.connect (view_selector_changed);

		// Populate views
		needs_update = true; // set_as_current_view() will populate the views later...

		// We only save the settings when this view wrapper is being destroyed. This avoids unnecessary
		// disk access to write settings.
		destroy.connect (on_quit);

		initialized = true;
	}

	public ViewWrapper.with_view (Gtk.Widget view) {
		view_container.append_page (view);
		this.hint = Hint.NONE;
		set_active_view (ViewType.NONE);
		update_library_window_widgets ();
	}


	private void connect_column_browser_ui_signals () {
		if (!have_column_browser)
			return;

		// For automatic position stuff
		this.size_allocate.connect ( () => {
			if (!lw.initializationFinished)
				return;

			if (column_browser.position == MillerColumns.Position.AUTOMATIC)
				set_column_browser_position (MillerColumns.Position.AUTOMATIC);
		});

		column_browser.size_allocate.connect ( () => {
			if (!lw.visible || !column_browser_enabled)
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
			if (current_view == ViewType.LIST && lw.column_browser_toggle.sensitive) {
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
		if (have_column_browser) {
			if (is_current_wrapper) {
				if (column_browser.visible) {
					if (column_browser.actual_position == MillerColumns.Position.LEFT)
						lw.settings.set_miller_columns_width(list_view_hpaned_position);
					else if (column_browser.actual_position == MillerColumns.Position.TOP)
						lw.settings.set_miller_columns_height(list_view_vpaned_position);
				}
				lw.settings.set_miller_columns_enabled (column_browser_enabled);
			}
		}
	}


	// We only check for white space at the moment
	private bool get_is_valid_search_string (string s) {
		if (s.length < 1)
			return true;

		int white_space = 0;
		unichar c;

		for (int i = 0; s.get_next_char (ref i, out c);)
			if (c.isspace())
				++ white_space;

		if (white_space == s.length)
			return false; // white space. Invalid string

		return true; // Passed our tests. Valid string
	}


	private void set_column_browser_position (MillerColumns.Position position) {
		if (!have_column_browser)
			return;

		MillerColumns.Position actual_position = position; //position that will be actually applied

		if (actual_position == MillerColumns.Position.AUTOMATIC) {
			// Decide what orientation to use based on the view area size

			int view_width = this.get_allocated_width ();
			const int MIN_TREEVIEW_WIDTH = 300;

			int visible_columns = 0;
			foreach (var column in column_browser.columns) {
				if (column.visible)
					++ visible_columns;
			}

			int required_width = column_browser.MIN_COLUMN_WIDTH * visible_columns;
			if (view_width - required_width < MIN_TREEVIEW_WIDTH)
				actual_position = MillerColumns.Position.TOP;
			else
				actual_position = MillerColumns.Position.LEFT;
		}

		column_browser.actual_position = actual_position;

		if (actual_position == MillerColumns.Position.LEFT) {
			if (list_view_hpaned.get_child1() == null && list_view_vpaned.get_child1() == column_browser) {
				list_view_vpaned.remove (column_browser);
				list_view_hpaned.pack1 (column_browser, true, true);

				list_view_hpaned.set_position (list_view_hpaned_position);
			}
		}
		else if (actual_position == MillerColumns.Position.TOP) {
			if (list_view_vpaned.get_child1() == null && list_view_hpaned.get_child1() == column_browser) {
				list_view_hpaned.remove (column_browser);
				list_view_vpaned.pack1 (column_browser, true, true);

				list_view_vpaned.set_position (list_view_vpaned_position);
			}
		}
	}


	/**
	 * Convenient visibility method
	 */
	private void set_active_view (ViewType type, out bool successful = null) {
		int view_index = -1;

		// Find position in notebook
		switch (type) {
			case ViewType.LIST:
				if (have_list_view)
					view_index = view_container.page_num (list_view_container);
				break;
			case ViewType.ALBUM:
				if (have_album_view)
					view_index = view_container.page_num (album_view);
				break;
			case ViewType.ERROR:
				if (have_error_box)
					view_index = view_container.page_num (error_box);
				break;
			case ViewType.WELCOME:
				if (have_welcome_screen)
					view_index = view_container.page_num (welcome_screen);
				break;
		}

		// i.e. we're not switching the view if it is not available
		if (view_index < 0) {
			successful = false;
			return;
		}

		// Set view as current
		current_view = type;

		view_container.set_current_page (view_index);

		// Update BeatBox's toolbar widgets
		update_library_window_widgets ();

		successful = true;
	}


	/**
	 * This method ensures that the view switcher and search box are sensitive/insensitive when they have to.
	 * It also selects the proper view switcher item based on the current view.
	 */
	private void update_library_window_widgets () {
		if (!is_current_wrapper)
			return;

		// select the right view in the view selector if it's one of the three views
		if (lw.viewSelector.selected != (int)current_view && (int)current_view <= 2)
			lw.viewSelector.set_active ((int)current_view);

		// Restore this view wrapper's search string
		lw.searchField.set_text (get_search_string());

		// Make the view switcher and search box insensitive if the current item
		// is either the error box or welcome screen
		if (current_view == ViewType.ERROR || current_view == ViewType.WELCOME) {
			lw.viewSelector.set_sensitive (false);
			lw.searchField.set_sensitive (false);

			lw.column_browser_toggle.set_sensitive (false);
			lw.column_browser_toggle.set_active (false);
		}
		else {
			// the view selector will only be sensitive if both views are available
			lw.viewSelector.set_sensitive (have_album_view && have_list_view);

			// Insensitive if there's no media to search
			lw.searchField.set_sensitive (have_media);

			// Sensitive only if the column browser is available and the current view type is LIST
			bool column_browser_available = (have_column_browser && current_view == ViewType.LIST);
			lw.column_browser_toggle.set_sensitive (column_browser_available);
			lw.column_browser_toggle.set_active ((column_browser_available) ? column_browser.visible : false);
		}
	}

	public virtual void view_selector_changed () {
		if (!lw.initializationFinished || (lw.visible && (int)current_view == lw.viewSelector.selected) || current_view == ViewType.ERROR || current_view == ViewType.WELCOME)
			return;

		var selected_view = (ViewType) lw.viewSelector.selected;

		bool successful; // whether the view was available or not
		set_active_view (selected_view, out successful);

		// Hide album list view
		if (successful && have_album_view)
			(album_view as AlbumView).album_list_view.hide ();
	}


	public void play_first_media () {
		if (have_list_view)
			list_view.set_as_current_list(1, true);
		else
			return;

		lm.playMedia (lm.mediaFromCurrentIndex(0), false);
		lm.player.play ();

		if(!lm.playing)
			lw.playClicked();
	}


	public void show_retrieving_similars() {
		if(hint != Hint.SIMILAR || !have_error_box || !lm.media_active)
			return;

		error_box.show_icon = false;
		error_box.setWarning("<span weight=\"bold\" size=\"larger\">" + _("Loading similar songs") + "</span>\n\n" + _("BeatBox is loading songs similar to") + " <b>" + lm.media_info.media.title.replace("&", "&amp;") + "</b> by <b>" + lm.media_info.media.artist.replace("&", "&amp;") + "</b> " + _("..."));

		// Show the error box
		set_active_view (ViewType.ERROR);

		similarsFetched = false;
	}


	/**
	 * This handles updating all the shared stuff outside the view area.
	 *
	 * You should only call this method on the respective ViewWrapper whenever the sidebar's
	 * selected view changes.
	 *
	 * Note: The sidebar-item selection and other stuff is handled automatically by the LibraryWindow
	 *       by request of SideTreeView. See LibraryManager :: set_active_view() for more details.
	 */
	public void set_as_current_view () {
		update_library_window_widgets ();

		// Update List View paned position to use the same position as the miller columns in other view wrappers
		if (have_column_browser) {
			if (column_browser.actual_position == MillerColumns.Position.LEFT && list_view_hpaned_position != -1)
				list_view_hpaned.set_position (list_view_hpaned_position);
			else if (column_browser.actual_position == MillerColumns.Position.TOP && list_view_vpaned_position != -1)
				list_view_vpaned.set_position (list_view_vpaned_position);
		}

		// Update the views if needed
		if (needs_update && lw.initializationFinished)
			update_showing_media ();
			//populate_views ();
		else // Update statusbar
			set_statusbar_info ();
	}


	public void set_statusbar_info() {
		if (!is_current_wrapper)
			return;

		if(showing_media_count < 1) {
			lw.set_statusbar_info (hint, 0, 0, 0);
			return;
		}

		var visible_media = (current_view == ViewType.LIST && column_browser_enabled) ? column_browser.media_results : get_showing_media_ids();

		uint count = 0;
		uint total_time = 0;
		uint total_mbs = 0;

		foreach(int id in visible_media) {
			var media = lm.media_from_id (id);
			if (media != null) {
				count ++;
				total_time += media.length;
				total_mbs += media.file_size;
			}
		}

		lw.set_statusbar_info(hint, count, total_mbs, total_time);
	}


	public virtual void search_field_changed() {
		if (!is_current_wrapper)
			return;

		var new_search = lw.searchField.get_text();

		if (!get_is_valid_search_string (new_search))
			return;

		if(!setting_search && lw.initializationFinished && is_current_wrapper && new_search.length != 1 && this.visible) {
			timeout_search.offer_head(new_search.down());

			Timeout.add(200, () => {

				string to_search = timeout_search.poll_tail();
				if(to_search != new_search || to_search == last_search)
					return false;

				if(!setting_search && is_current_wrapper)
					last_search = to_search;

				// Do the actual search and show results....
				update_showing_media();

				return false;
			});
		}
	}


	/**
	 * Updates the views to use the new data.
	 * For performance reasons, this process should be delayed until the user switches to this view wrapper.
	 */
	public void populate_views () {
		if (check_show_error_box())
			return;

		if (have_album_view)
			album_view.populate_view ();

		if (column_browser_enabled)
			// This will emit the changed() signal and then column_browser_changed will be called.
			// We can't avoid re-populating the entire column browser and then the list view
			// for performance reasons. We don't guarantee persistent selections if the column
			// browser is enabled.
			column_browser.populate (get_showing_media_ids());
		else if (have_list_view)
			list_view.populate_view ();

		// Update statusbar ...
		if (!column_browser_enabled) // column_browser_changed already does this...
			set_statusbar_info ();

		// Okay, everything is updated now
		needs_update = false;
	}

	private void column_browser_changed () {
		// This method is only called if the column browser is available.
		// For performance reasons we won't update showing_medias to match
		// the results of the miller columns.

		if(lw.initializationFinished && have_list_view) {
			list_view.set_show_next (column_browser.media_results);
			list_view.populate_view();
			set_statusbar_info();
		}
	}


	/**
	============================================================================
	                                  DATA STUFF
	============================================================================
	*/


	/**
	 * @return a collection containing ALL the media
	 */
	public Collection<int> get_media_ids () {
		return medias.keys;
	}


	/**
	 * @return a collection containing all the media that should be shown
	 */
	public Collection<int> get_showing_media_ids () {
		return showing_medias.keys;
	}


	/**
	 * Description:
	 * Updates the data in showing_media and re-populates all the views.
	 * Primarily used for searches
	 */
	public void update_showing_media (bool _populate_views = true) {
		if(in_update)
			return;

		in_update = true;

		showing_medias = new HashMap<int, int>();

		// Perform search
		LinkedList<int> search_results;

		lm.do_search (get_media_ids (), out search_results, null, null, null, null, hint, get_search_string());

		foreach (int i in search_results)
			showing_medias.set (i, 1);

		if (have_album_view)
			album_view.set_show_next (search_results);

		if (!column_browser_enabled && have_list_view)
			list_view.set_show_next (search_results);

		// Now update the views to reflect the change
		if (_populate_views)
			populate_views (); // this also updates the statusbar

		in_update = false;
	}


	public void set_media (Collection<int>? new_media, bool in_thread = false) {
		if (new_media == null)
			return;

		medias = new HashMap <int, int>();

		foreach (int i in new_media)
			medias.set (i, 1);

		// BEGIN special case for similar media
		if(!in_thread && have_list_view && hint == Hint.SIMILAR && is_current_wrapper) {
			SimilarPane sp = (SimilarPane)(list_view);

			if (check_show_error_box())
				return;

			if(!similarsFetched) { // still fetching similar media
				// Show the error box
				set_active_view (ViewType.ERROR);

				in_update = false;
				return;
			}
			else {
				if(media_count < 10) { // say we could not find similar media
					if (have_error_box) {
						error_box.show_icon = true;
						error_box.setWarning("<span weight=\"bold\" size=\"larger\">" + _("No similar songs found") + "\n</span>\n" + _("BeatBox could not find songs similar to" + " <b>" + lm.media_info.media.title.replace("&", "&amp;") + "</b> by <b>" + lm.media_info.media.artist.replace("&", "&amp;") + "</b>.\n") + _("Make sure all song info is correct and you are connected to the Internet.\nSome songs may not have matches."));
						// Show the error box
						set_active_view (ViewType.ERROR);
					}

					in_update = false;
					return;
				}
				else {
					sp._base = lm.media_info.media;
					set_active_view (ViewType.LIST);
				}
			}
		}
		// END special case

		// update showing media. Don't update the views if inside a thread
		if (!is_current_wrapper || in_thread)
			needs_update = true; //delay the update until the user switches to this view
		else
			update_showing_media ();
	}


	private bool check_show_error_box () {
		// Check if we should show the error box or welcome screen here
		// FIXME: we could do better here. We should be able to set what kind of view we
		//         want to handle the no-media case and maybe just emit a signal here.
		if (have_error_box || have_welcome_screen) {
			int size_check;

			if (hint == Hint.PODCAST) {
				size_check = 0;
				foreach (int i in lm.podcast_ids()) {
					if (!lm.media_from_id(i).isTemporary)
						++size_check;
				}
			}
			else if (hint == Hint.STATION) {
				size_check = 0;
				foreach (int i in lm.station_ids()) {
					if (lm.media_from_id(i) != null)
						++size_check;
				}
			} else {
				size_check = media_count;
			}

			if (size_check < 1) { // no media
				if (have_error_box)
					set_active_view (ViewType.ERROR);
				else if (have_welcome_screen)
					set_active_view (ViewType.WELCOME);

				return true;
			}

			var new_view = (ViewType) lw.viewSelector.selected;
			
			if (current_view != new_view && (new_view == ViewType.LIST && have_list_view) || (new_view == ViewType.ALBUM && have_album_view))
				set_active_view (new_view);
		}

		return false;
	}


	/**
	 * Do search to find which ones should be added, removed from this particular view
	 * does not re-anaylyze smart playlist_views or playlist_views.
	 */
	public void update_media (Collection<int> ids) {
		if (in_update)
			return;

		in_update = true;

		if (is_current_wrapper) {
			// find which media belong here
			LinkedList<int> should_be, should_show;

			Collection<int> to_search;

			if(hint == Hint.SMART_PLAYLIST)
				to_search = lm.smart_playlist_from_id(relative_id).analyze(lm, ids);
			else
				to_search = ids;

			lm.do_search (to_search, out should_be, null, null, null, null, hint);
			lm.do_search (to_search, out should_show, null, null, null, null, hint, get_search_string());

			var to_add = new LinkedList<int>();
			var to_remove = new LinkedList<int>();
			var to_remove_show = new LinkedList<int>();

			// add elements that should be here
			foreach(int i in should_be)
				medias.set(i, 1);

			// add elements that should show
			foreach(int i in should_show) {
				if(showing_medias.get(i) == 0)
					to_add.add(i);

				showing_medias.set(i, 1);
			}

			// remove elements
			foreach(int i in ids) {
				if(!should_be.contains(i)) {
					to_remove.add(i);
					medias.unset(i);
				}
			}

			foreach(int i in ids) {
				if(!should_show.contains(i)) {
					to_remove_show.add(i);
					showing_medias.unset(i);
				}
			}

			Idle.add( () => {
				if (check_show_error_box())
					return false;
			
				if (column_browser_enabled) {
					// FIXME: not doing anything for now. Things that should be done
					// 1) update the column browser without repopulating the list-view
					//    after every change. Duration is missing from songs very often and
					//    when BeatBox fixes them, medias_updated() is emmited, calling this
					//    method. Enabling the following lines would make BeatBox re-populate
					//    the list view and column browser almost everytime a media with missing
					//    duration is played!
					//
					// This will emit the changed() signal and then column_browser_changed will be called.
					// We can't avoid re-populating the entire column browser and then the list view
					// for performance reasons. We don't guarantee persistent selections if the column
					// browser is enabled.
					//column_browser.populate (get_showing_media_ids());
				}
				else if (have_list_view) {
					list_view.append_medias(to_add);
					list_view.remove_medias(to_remove_show);
				}

				if (have_album_view) {
					album_view.append_medias(to_add);
					album_view.remove_medias(to_remove_show);
				}

				set_statusbar_info ();

				return false;
			});
		}
		else {
			needs_update = true;
		}

		in_update = false;
	}


	public void remove_media (Collection<int> ids) {
		if(in_update)
			return;

		in_update = true;

		// find which media to remove and remove it from
		// Media and Showing Media
		var to_remove = new LinkedList<int>();
		foreach(int i in ids) {
			medias.unset(i);

			if(showing_medias.get(i) != 0)
				to_remove.add(i);

			showing_medias.unset(i);
		}

		if (check_show_error_box())
			return;

		// Now update the views to reflect the changes

		if (have_album_view)
			album_view.remove_medias (to_remove);

		if (column_browser_enabled)
			// This will emit the changed() signal and then column_browser_changed will be called.
			// We can't avoid re-populating the entire column browser and then the list view
			// for performance reasons. We don't guarantee persistent selections if the column
			// browser is enabled.
			column_browser.populate (get_showing_media_ids());
		else if (have_list_view)
			list_view.remove_medias (to_remove);

		set_statusbar_info ();

		in_update = false;
	}


	public void add_media (Collection<int> new_media) {
		if(in_update)
			return;

		in_update = true;

		if(hint == Hint.MUSIC || hint == Hint.PODCAST || hint == Hint.STATION) { //FIXME DEVICE_?
			// find which media to add and update Media
			var to_add = new LinkedList<int>();
			foreach(int i in new_media) {
				if(medias.get(i) == 0) {
					medias.set(i, 1);
					to_add.add(i);
				}
			}

			// Do search since Showing Media depends on the search string
			LinkedList<int> to_show;
			lm.do_search (to_add, out to_show, null, null, null, null, hint, get_search_string());

			// Update Showing Media
			foreach(int i in to_show)
				showing_medias.set(i, 1);

			if (check_show_error_box())
				return;

			if (have_album_view)
				album_view.append_medias (to_add);

			if (column_browser_enabled) {
				// This will emit the changed() signal and then column_browser_changed will be called.
				// We can't avoid re-populating the entire column browser and then the list view
				// for performance reasons. We don't guarantee persistent selections if the column
				// browser is enabled.
				column_browser.populate (get_showing_media_ids());
			}
			else if (have_list_view) {
				list_view.append_medias (to_add);
			}
		}
		else {
			needs_update = true; //not sure about this
		}

		in_update = false;
	}
}

