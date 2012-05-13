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

	protected Notebook view_container; // Wraps all the internal views for super fast switching

	/* MAIN WIDGETS (VIEWS) */
	public ListView      list_view      { get; private set; }
	public AlbumView     album_view     { get; private set; }
	public EmbeddedAlert embedded_alert { get; private set; }
	public Welcome       welcome_screen { get; private set; }

	/* UI PROPERTIES */
	public bool has_album_view      { get { return album_view != null;     } }
	public bool has_list_view       { get { return list_view != null;      } }
	public bool has_embedded_alert  { get { return embedded_alert != null; } }
	public bool has_welcome_screen  { get { return welcome_screen != null; } }

	/**
	 * Type of visual representation of the media.
	 *
	 * IMPORTANT: Values _must_ match the index of the respective view in the view selector.
	 */
	public enum ViewType {
		ALBUM   = 0, // Matches index 0 of the view in lw.viewSelector
		LIST    = 1, // Matches index 1 of the view in lw.viewSelector
		ALERT   = 2, // For embedded alertes
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

	public int index { get { return lw.view_container.get_view_index (this); } }

	public bool is_current_wrapper {
		get {
			return (lw.initialization_finished ? (index == lw.view_container.get_current_index ()) : false);
		}
	}


	/**
	 * MEDIA DATA
	 *
	 * These data structures hold information about the media shown in the views.
	 **/

	// ALL the media. Data source.
	protected HashMap<Media, int> media_table;
	protected HashMap<Media, int> visible_media_table;

	public int media_count { get { return (media_table != null) ? media_table.size : 0; } }


	public ViewWrapper (LibraryWindow lw, TreeViewSetup tvs, int id)
	{
		this.lm = lw.lm;
		this.lw = lw;

		this.relative_id = id;
		this.hint = tvs.get_hint ();

		debug ("BUILDING %s", hint.to_string());

		// Setup view container
		view_container = new Notebook ();
		view_container.show_tabs = false;
		view_container.show_border = false;
		this.pack_start (view_container, true, true, 0);

		switch (hint) {
			case Hint.MUSIC:
				// list and album view
				album_view = new AlbumView (this);
				
				// Currently only the music-library view should have a column browser
				list_view = new ListView (this, tvs, true);
				// Welcome screen
				welcome_screen = new Granite.Widgets.Welcome(_("Get Some Tunes"), _("%s can't seem to find your music.").printf (lw.app.get_name ()));
				break;
			case Hint.DEVICE_AUDIO:
				// list and album view
				album_view = new AlbumView (this);
				list_view = new ListView (this, tvs);

				embedded_alert = new Granite.Widgets.EmbeddedAlert ();
				break;
			case Hint.HISTORY:
			case Hint.QUEUE:
				//list view only				
				list_view = new ListView (this, tvs);

				embedded_alert = new Granite.Widgets.EmbeddedAlert();
				break;
			case Hint.PLAYLIST:
			case Hint.SMART_PLAYLIST:
				// list and album view
				album_view = new AlbumView (this);
				list_view = new ListView (this, tvs);

				embedded_alert = new Granite.Widgets.EmbeddedAlert();
				break;
			case Hint.SIMILAR:
				// list view only
				list_view = new ListView (this, tvs);

				embedded_alert = new Granite.Widgets.EmbeddedAlert();
				break;
			case Hint.CDROM:
				// list view only
				list_view = new ListView (this, tvs);

				embedded_alert = new Granite.Widgets.EmbeddedAlert();
				break;
			default:
				// nothing but an embedded alert
				embedded_alert = new Granite.Widgets.EmbeddedAlert ();
				break;
		}

		// Now setup the view wrapper based on available widgets

		if (has_embedded_alert) {
			view_container.append_page (embedded_alert);
		}

		if (has_welcome_screen) {
			view_container.append_page (welcome_screen);
		}

		if (has_album_view)
			view_container.append_page (album_view);
		else
			debug ("NO ALBUM VIEW (%s)", hint.to_string());

		if (has_list_view)
			view_container.append_page (list_view);

		// Connect data signals

		if (hint == Hint.QUEUE) {
			lm.media_queued.connect ( (ids) => {
				add_media (lm.media_from_ids (ids));
			});
			lm.media_unqueued.connect ( (ids) => {
				remove_media (lm.media_from_ids (ids));
			});
		}
		else if (hint == Hint.HISTORY) {
			lm.history_changed.connect ( () => {
				set_media (lm.media_from_ids (lm.already_played ()));
			});
		}
		// Libraries and smart playlists should listen for additions
		else if (hint == Hint.MUSIC || hint == Hint.SMART_PLAYLIST) {
			lm.media_added.connect ( (ids) => {
				add_media (lm.media_from_ids (ids));
			});
		}

		// everyone but devices should listen for removals and updates
		if (hint != Hint.CDROM && hint != Hint.DEVICE_PODCAST && hint != Hint.DEVICE_AUDIO && hint != Hint.DEVICE_AUDIOBOOK) {
			// if it's a smart playlist, re-analyze
			lm.media_updated.connect ( (ids) => {
				var to_update = ids;
				if (hint == Hint.SMART_PLAYLIST)
					to_update = lm.smart_playlist_from_id (relative_id).analyze (lm, ids);
				update_media (lm.media_from_ids (to_update));
			});
			lm.media_removed.connect ( (ids) => {
				remove_media (lm.media_from_ids (ids));
			});
		}

		// Listen for playlist additions/removals
		if (hint == Hint.PLAYLIST) {
			var playlist = lm.playlist_from_id (relative_id);

			playlist.cleared.connect ( () => {
				debug ("playlist changed");
				set_media (new LinkedList<Media> ());
			});

			playlist.media_added.connect ( (ids) => {
				add_media (lm.media_from_ids (ids));
			});
			playlist.media_removed.connect ( (ids) => {
				remove_media (lm.media_from_ids (ids));
			});
		}

		lw.viewSelector.mode_changed.connect (view_selector_changed);
		lw.searchField.changed.connect (search_field_changed);

		debug ("FINISHED BUILDING %s\n\n\n", hint.to_string());
	}

	public ViewWrapper.with_view (Gtk.Widget view) {
		view_container.append_page (view);
		this.hint = Hint.NONE;
		set_active_view (ViewType.NONE);
		update_library_window_widgets ();
	}



	/**
	 * Convenient visibility method
	 */
	protected void set_active_view (ViewType type, out bool successful = null) {
		int view_index = -1;

		// Find position in notebook
		switch (type) {
			case ViewType.LIST:
				if (has_list_view)
					view_index = view_container.page_num (list_view);
				break;
			case ViewType.ALBUM:
				if (has_album_view)
					view_index = view_container.page_num (album_view);
				break;
			case ViewType.ALERT:
				if (has_embedded_alert)
					view_index = view_container.page_num (embedded_alert);
				break;
			case ViewType.WELCOME:
				if (has_welcome_screen)
					view_index = view_container.page_num (welcome_screen);
				break;
		}

		// i.e. we're not switching the view if it is not available
		if (view_index < 0) {
			debug ("%s : VIEW %s was not available", hint.to_string(), type.to_string ());
			successful = false;
			return;
		}

		// Set view as current
		current_view = type;

		view_container.set_current_page (view_index);

		debug ("%s : switching to %s", hint.to_string(), type.to_string ());

		// Update LibraryWindow toolbar widgets
		update_library_window_widgets ();

		update_statusbar_info ();

		successful = true;
	}


	/**
	 * This method ensures that the view switcher and search box are sensitive/insensitive when they have to.
	 * It also selects the proper view switcher item based on the current view.
	 */
	protected void update_library_window_widgets () {
		if (!is_current_wrapper)
			return;

		debug ("%s : update_library_window_widgets", hint.to_string());

		// Play, pause, ...
		bool media_active = lm.media_active;
		bool media_visible = (visible_media_table.size > 0);
		lw.previousButton.set_sensitive (media_active || media_visible);
		lw.playButton.set_sensitive (media_active || media_visible);
		lw.nextButton.set_sensitive (media_active || media_visible);

		// select the right view in the view selector if it's one of the three views
		if (lw.viewSelector.selected != (int)current_view && (int)current_view <= 2)
			lw.viewSelector.set_active ((int)current_view);

		// Restore this view wrapper's search string
		lw.searchField.set_text (actual_search_string);

		// Make the view switcher and search box insensitive if the current item
		// is either the embedded alert or welcome screen
		if (current_view == ViewType.ALERT || current_view == ViewType.WELCOME) {
			lw.viewSelector.set_sensitive (false);
			lw.searchField.set_sensitive (false);

			lw.column_browser_toggle.set_sensitive (false);
			lw.column_browser_toggle.set_active (false);
		}
		else {
			// the view selector will only be sensitive if both views are available
			lw.viewSelector.set_sensitive (has_album_view && has_list_view);

			bool has_media = media_table.size > 0;
			// Insensitive if there's no media to search
			lw.searchField.set_sensitive (has_media);

			bool column_browser_available = false;
			bool column_browser_visible = false;

			// Sensitive only if the column browser is available and the current view type is LIST
			if (has_list_view) {
				var lv = list_view as ListView;
			
				column_browser_available = (lv.has_column_browser && current_view == ViewType.LIST);

				if (column_browser_available)
					column_browser_visible = lv.column_browser.visible;
			}

			lw.column_browser_toggle.set_sensitive (column_browser_available);
			lw.column_browser_toggle.set_active (column_browser_visible);
		}
		
		/* XXX
		   /!\ WARNING: NOT ENTERELY NECESSARY.
		   It's here to avoid potential issues. Should be removed
		   if it impacts performance.
		*/
		//lw.update_sensitivities();
	}

	public virtual void view_selector_changed () {
		if (!lw.initialization_finished || (lw.initialization_finished && (int)current_view == lw.viewSelector.selected) || current_view == ViewType.ALERT || current_view == ViewType.WELCOME)
			return;

		var selected_view = (ViewType) lw.viewSelector.selected;
		debug ("%s : view_selector_changed : applying actions", hint.to_string());

		set_active_view (selected_view);
	}

	// FIXME: this shouldn't depend on the list view
	public void play_first_media () {
		if (!has_list_view)
			return;

		debug ("%s : play_first_media", hint.to_string());

		(list_view as ListView).set_as_current_list(1, true);

		lm.playMedia (lm.mediaFromCurrentIndex(0), false);
		lm.player.play ();

		if(!lm.playing)
			lw.playClicked();
	}


	/**
	 * This handles updating all the shared stuff outside the view area.
	 *
	 * You should only call this method on the respective ViewWrapper whenever the sidebar's
	 * selected view changes.
	 *
	 * Note: The sidebar-item selection and other stuff is handled automatically by the LibraryWindow
	 *       by request of SideTreeView. See LibraryWindow :: set_active_view() for more details.
	 */
	public void set_as_current_view () {
		if (!lw.initialization_finished)
			return;
		debug ("%s : SETTING AS CURRENT VIEW -> set_as_current_view", hint.to_string());
		check_have_media ();
		update_library_window_widgets ();
		update_statusbar_info ();
	}


	public async void update_statusbar_info () {
		if (!is_current_wrapper)
			return;

		debug ("%s : updating statusbar info", hint.to_string ());

		if (current_view == ViewType.ALERT || current_view == ViewType.WELCOME) {
			lw.set_statusbar_info ("");
			return;
		}

		bool is_list = false;

		Gee.Collection<Media>? media_set = null;
		// Get data based on the current view
		if (current_view == ViewType.LIST) {
			is_list = true;
			media_set = list_view.get_visible_media ();
		}
		else {
			// Let's use the local data since it has no internal filter
			media_set = new Gee.LinkedList<Media> ();
			foreach (var m in get_visible_media_list ()) {
				if (m != null)
					media_set.add (m);
			}
		}

		uint total_items = 0, total_size = 0, total_time = 0;

		foreach (var media in media_set) {
			if (media != null) {
				total_items ++;
				total_time += media.length;
				total_size += media.file_size;
			}
		}

		if (total_items == 0) {
			lw.set_statusbar_info ("");
		}

		string media_description = "";

		if (is_list) {
			if (hint == Hint.MUSIC)
				media_description = total_items > 1 ? _("%i songs") : _("1 song");
			else
				media_description = total_items > 1 ? _("%i items") : _("1 item");	
		}
		else {
			media_description = total_items > 1 ? _("%i albums") : _("1 album");
		}

		// FIXME: bad workaround
		if (current_view == ViewType.ALBUM && has_album_view) {
			total_items = album_view.get_visible_media ().size;
		}

		string media_text = media_description.printf ((int)total_items);
		string time_text = TimeUtils.time_string_from_seconds (total_time);
		string size_text = format_size ((uint64)(total_size * 1000000));

		lw.set_statusbar_info ("%s, %s, %s".printf (media_text, time_text, size_text));
	}


	// Holds the last search results (timeout). Helps to prevent useless search.
	protected LinkedList<string> timeout_search = new LinkedList<string>();
	private int search_timeout = 100; // ms

	// Stops from searching same thing multiple times
	protected string last_search = "";
	protected string actual_search_string = ""; // what the user actually typed in the search box.

	private void search_field_changed () {
		if (!is_current_wrapper)
			return;

		actual_search_string = lw.searchField.get_text ();
		var new_search = Search.get_valid_search_string (actual_search_string).down ();
		debug ("Search changed : searchbox has '%s'", new_search);

		if (new_search.length != 1) {
			timeout_search.offer_head (new_search.down ());

			Timeout.add (search_timeout, () => {
				// Don't search the same stuff every {search_timeout}ms
				string to_search = timeout_search.poll_tail();
				if (to_search != new_search || to_search == last_search)
					return false;

				last_search = to_search;
				// Do the actual search and show up results....
				update_visible_media ();

				return false;
			});
		}
	}


	protected bool check_have_media () {
		debug ("%s : check_have_media", hint.to_string());

		if (has_embedded_alert || has_welcome_screen) {
			int size_check = media_count;

			if (size_check < 1) { // no media

				if (has_embedded_alert) {
					debug ("%s : showing ALERT BOX", hint.to_string());
					set_default_alert ();
					set_active_view (ViewType.ALERT);
				}
				else if (has_welcome_screen) {
					debug ("%s : showing WELCOME SCREEN", hint.to_string());
					set_active_view (ViewType.WELCOME);
				}

				return true;
			}

			if (current_view == ViewType.ALERT || current_view == ViewType.WELCOME) {
				var new_view = (ViewType) lw.viewSelector.selected;
				debug ("%s : showing %s", hint.to_string(), new_view.to_string ());
				if (current_view != new_view && ((new_view == ViewType.LIST && has_list_view) || (new_view == ViewType.ALBUM && has_album_view)))
					set_active_view (new_view);
			}
		}

		debug ("%s : not showing any error/welcome widget", hint.to_string());
		return false;
	}


	private void set_default_alert () {
		if (!has_embedded_alert)
			return;

		debug ("%s : set_default_alert", hint.to_string());

		switch (hint) {
			case Hint.MUSIC:
				break;
			case Hint.QUEUE:
				embedded_alert.set_alert (_("No songs in Queue"), _("To add songs to the queue, use the <b>secondary click</b> on an item and choose <b>Queue</b>. When a song finishes, the queued songs will be played first before the next song in the currently playing list."), null, true, Granite.AlertLevel.INFO);
				break;
			case Hint.HISTORY:
				embedded_alert.set_alert (_("No songs in History"), _("After a part of a song has been played, it is added to the history list.\nYou can use this list to see all the songs you have played during the current session."), null, true, Granite.AlertLevel.INFO);
				break;
			case Hint.CDROM:
				embedded_alert.set_alert (_("Audio CD Invalid"), _("%s could not read the contents of this Audio CD").printf (lw.app.get_name ()), null, true, Granite.AlertLevel.WARNING);
				break;
			case Hint.PLAYLIST:
				embedded_alert.set_alert (_("No Songs"), _("To add songs to this playlist, use the <b>secondary click</b> on an item and choose <b>Add to Playlist</b>."), null, true, Granite.AlertLevel.INFO);
				break;
			case Hint.SMART_PLAYLIST:
				var action = new Gtk.Action ("smart-playlist-rules-edit",
				                              _("Edit Smart Playlist"),
				                              _("Click on the button to edit playlist rules"),
				                              Gtk.Stock.EDIT
				                              );
				// Connect to the 'activate' signal
				action.activate.connect ( () => {
					// Show this playlist's edit dialog
					lw.sideTree.playlistMenuEditClicked ();
				});
				var actions = new Gtk.Action[1];
				actions[0] = action;
				embedded_alert.set_alert (_("No Songs"), _("This playlist will be automatically populated with songs that match its rules. To modify these rules, use the <b>secondary click</b> on it in the sidebar and click on <b>Edit</b>. Optionally, you can click on the button below."), actions, true, Granite.AlertLevel.INFO);
				break;
			default:
				break;
		}
	}


	/**
	============================================================================
	                                  DATA STUFF
	============================================================================
	*/


	protected Mutex in_update;

	/* Whether to populate this view wrapper's views immediately or delay the process */
	protected bool populate_views { get { return is_current_wrapper && lw.get_realized (); } }

	public string get_search_string () {
		return last_search;
	}


	/**
	 * @return a collection containing ALL the media
	 */
	public Collection<Media> get_media_list () {
		return media_table.keys;
	}


	/**
	 * @return a collection containing all the media that should be shown
	 */
	public Collection<Media> get_visible_media_list () {
		return visible_media_table.keys;
	}


	/**
	 * Description:
	 * Updates the data in visible_media and re-populates all the views.
	 * Primarily used for searches
	 */
	public async void update_visible_media () {
		in_update.lock ();

		debug ("%s : UPDATING SHOWING MEDIA", hint.to_string ());

		visible_media_table = new HashMap<Media, int> ();
		var to_search = get_search_string ();

		var search_results = new Gee.LinkedList<Media> ();

		if (to_search != "") {
			// Perform search
			LinkedList<Media> search_results_ids;
			Search.search_in_media_list (get_media_list (), out search_results, to_search);

			foreach (var m in search_results) {
				visible_media_table.set (m, 1);
			}
		}
		else {
			// No need to search. Same data as media
			foreach (var m in get_media_list ()) {
				search_results.add (m);
				visible_media_table.set (m, 1);
			}
		}

		in_update.unlock ();

		if (populate_views) { // update right away
			if (has_list_view) {
				list_view.set_media (search_results);
				list_view.set_media (search_results);
			}

			if (has_album_view) {
				album_view.set_media (search_results);
				album_view.set_media (search_results);
			}

			update_statusbar_info ();
			update_library_window_widgets ();
		}
		else {
			Idle.add( () => {
				if (!lw.initialization_finished)
					return true;

				debug ("%s : populating views on idle", hint.to_string());

				if (has_list_view) {
					list_view.set_media (search_results);
					list_view.set_media (search_results);
				}

				if (has_album_view) {
					album_view.set_media (search_results);
					album_view.set_media (search_results);
				}

				return false;
			});
		}

		// Check whether we should show the embedded alert in case there's no media
		check_have_media ();
	}

	public async void set_media_from_ids (Gee.Collection<int> new_media) {
		var to_set = new Gee.LinkedList<Media> ();
		foreach (var id in new_media)
			to_set.add (lm.media_from_id (id));
		set_media (to_set);
	}

	public async void set_media (Collection<Media> new_media) {
		if (new_media == null) {
			warning ("set_media: attempt to set NULL media failed");
			return;
		}

		debug ("%s : SETTING MEDIA -> set_media", hint.to_string());

		media_table = new HashMap <Media, int>();

		int media_count = 0;
		foreach (var m in new_media) {
			if (m != null) {
				media_table.set (m, 1);
				media_count ++;
			}
		}

		// optimize searches based on the amount of media. Time in ms
		if (media_count < 100) 
			search_timeout = 40;
		if (media_count < 250)
			search_timeout = 100;
		if (media_count < 100)
			search_timeout = 140;
		else if (media_count < 5000)
			search_timeout = 200;
		else if (media_count < 10000)
			search_timeout = 240;
		else if (media_count < 25000)
			search_timeout = 300;
		else
			search_timeout = 500;

		update_visible_media ();
	}


	/**
	 * Do search to find which ones should be added, removed from this particular view
	 */
	public async void update_media (Gee.Collection<Media> media) {
		in_update.lock ();

		debug ("%s : UPDATING media", hint.to_string());

		// find which media belong here
		Gee.LinkedList<Media> should_be, should_show;

		Search.full_search_in_media_list (media, out should_be, null, null, null, null, hint);
		Search.full_search_in_media_list (media, out should_show, null, null, null, null, hint, get_search_string ());

		var to_remove = new LinkedList<Media>();
		var to_add_show = new LinkedList<Media>();
		var to_remove_show = new LinkedList<Media>();

		// add elements that should be here
		foreach (var m in should_be)
			if (!media_table.has_key (m))
				media_table.set (m, 1);

		// add elements that should show
		foreach (var m in should_show) {
			if (!visible_media_table.has_key (m)) {
				to_add_show.add (m);
				visible_media_table.set (m, 1);
			}
		}

		// remove elements
		foreach (var m in media) {
			if (!should_be.contains (m)) {
				to_remove.add (m);
				media_table.unset (m);
			}

			if (!should_show.contains (m)) {
				to_remove_show.add (m);
				visible_media_table.unset (m);
			}
		}

		in_update.unlock ();

		if (populate_views) { // update right away
			if (has_list_view) {
				list_view.add_media (to_add_show);
				list_view.remove_media (to_remove_show);
			}

			if (has_album_view) {
				album_view.add_media (to_add_show);
				album_view.remove_media (to_remove_show);
			}

			update_statusbar_info ();
			update_library_window_widgets ();
		}
		else {
			Idle.add( () => {
				if (!lw.initialization_finished)
					return true;

				debug ("%s : populating views on idle", hint.to_string());

				if (has_list_view) {
					list_view.add_media (to_add_show);
					list_view.remove_media (to_remove_show);
				}

				if (has_album_view) {
					album_view.add_media (to_add_show);
					album_view.remove_media (to_remove_show);
				}

				return false;
			});
		}
	}


	public async void remove_media (Collection<Media> media) {
		in_update.lock ();

		debug ("%s : REMOVING media", hint.to_string ());

		// find which media to remove and remove it from Media and Showing Media
		var to_remove = new LinkedList<Media>();
		foreach (var m in media) {
			media_table.unset (m);

			if (visible_media_table.has_key (m)) {
				to_remove.add (m);
				visible_media_table.unset (m);
			}
		}

		if (check_have_media ()) {
			in_update.unlock ();
			return;
		}	

		in_update.unlock ();

		// Now update the views to reflect the changes

		if (has_album_view)
			album_view.remove_media (to_remove);

		if (has_list_view)
			list_view.remove_media (to_remove);

		if (is_current_wrapper) {
			update_library_window_widgets ();
			update_statusbar_info ();
		}

	}


	public async void add_media (Collection<Media> new_media) {
		in_update.lock ();

		debug ("%s : ADDING media", hint.to_string());

		// find which media to add and update Media
		var to_add = new LinkedList<Media> ();

		foreach (var m in new_media) {
			if (!media_table.has_key (m)) {
				media_table.set (m, 1);
				to_add.add (m);
			}
		}

		// Do search since Showing Media depends on the search string
		LinkedList<Media> media_to_show;
		Search.search_in_media_list (to_add, out media_to_show, get_search_string ());

		// Update showing media
		foreach (var m in media_to_show) {
			if (!visible_media_table.has_key (m))
				visible_media_table.set (m, 1);
		}

		if (check_have_media ()) {
			in_update.unlock ();
			return;
		}

		in_update.unlock ();

		if (populate_views) {
			if (has_album_view)
				album_view.add_media (media_to_show);

			if (has_list_view)
				list_view.add_media (media_to_show);

			update_statusbar_info ();
			update_library_window_widgets ();

		}
		else {
			Idle.add ( () => {
				if (!lw.initialization_finished)
					return true;

				debug ("%s : populating views on idle", hint.to_string());
				
				if (has_album_view)
					album_view.add_media (media_to_show);

				if (has_list_view)
					list_view.add_media (media_to_show);
	
				return false;
			});
		}
	}
}

