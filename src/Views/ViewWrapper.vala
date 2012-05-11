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
	public ListView      list_view      { get; private set; }
	public AlbumView     album_view     { get; private set; }
	public EmbeddedAlert embedded_alert { get; private set; }
	public Welcome       welcome_screen { get; private set; }

	protected Notebook view_container; // Wraps all the internal views for super fast switching

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

	public int index { get { return lw.main_views.page_num(this); } }

	public bool is_current_wrapper {
		get {
			return (lw.initialization_finished ? (index == lw.main_views.get_current_page()) : false);
		}
	}

	protected bool populate_views { get { return is_current_wrapper && lw.get_realized (); } }

	/* UI PROPERTIES */

	public bool has_album_view      { get { return album_view != null;     } }
	public bool has_list_view       { get { return list_view != null;      } }
	public bool has_embedded_alert  { get { return embedded_alert != null; } }
	public bool has_welcome_screen  { get { return welcome_screen != null; } }

	public bool has_media { get { return media_count > 0; } }

	const int SEARCH_TIMEOUT = 200; // ms

	/**
	 * MEDIA DATA
	 *
	 * These data structures hold information about the media shown in the views.
	 **/

	// ALL the media. Data source.
	public HashMap<int, int> medias { get; private set; }
	public HashMap<int, int> showing_medias { get; private set; }

	public int media_count { get { return (medias != null) ? medias.size : 0; } }
	public int showing_media_count { get { return (showing_medias != null) ? showing_medias.size : 0; } }

	// Stops from searching unnecesarilly when changing b/w 0 words and search.
	private bool showing_all { get { return showing_media_count == media_count; } }

	// Holds the last search results (timeout). Helps to prevent useless search.
	protected LinkedList<string> timeout_search;

	// Stops from searching same thing multiple times
	protected string last_search = "";
	protected string actual_search_string = ""; // what the user actually typed in the search box.

	public string get_search_string () {
		return last_search;
	}


	protected Mutex in_update;

	public ViewWrapper (LibraryWindow lw, Collection<int> the_media, TreeViewSetup tvs, int id)
	{
		this.lm = lw.lm;
		this.lw = lw;

		this.relative_id = id;
		this.hint = tvs.get_hint ();

		debug ("BUILDING %s", hint.to_string());

		medias = new HashMap<int, int>();
		showing_medias = new HashMap<int, int>();
		timeout_search = new LinkedList<string>();

		foreach (int i in the_media)
			medias.set (i, 1);

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
				list_view = new ListView (this, tvs);
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
			lm.media_queued.connect (add_media);
			lm.media_unqueued.connect (remove_media);
		}

		// Libraries and smart playlists should listen for additions
		if (hint == Hint.MUSIC || hint == Hint.SMART_PLAYLIST) {
			lm.medias_added.connect (add_media);
		}

		// everyone but devices should listen for removals and updates
		if (hint != Hint.CDROM && hint != Hint.DEVICE_PODCAST && hint != Hint.DEVICE_AUDIO && hint != Hint.DEVICE_AUDIOBOOK) {
			lm.medias_updated.connect (update_media);
			lm.medias_removed.connect (remove_media);
		}

		// Listen for playlist additions/removals
		if (hint == Hint.PLAYLIST) {
			var playlist = lm.playlist_from_id (relative_id);
			playlist.changed.connect ( () => {
				debug ("playlist changed");
				set_media (playlist.medias ());
			});
			playlist.media_added.connect (add_media);
			playlist.media_removed.connect (remove_media);
		}

		lw.viewSelector.mode_changed.connect (view_selector_changed);
		lw.searchField.changed.connect (search_field_changed);
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
			successful = false;
			return;
		}

		// Set view as current
		current_view = type;

		view_container.set_current_page (view_index);

		// Update LibraryWindow toolbar widgets
		update_library_window_widgets ();

		set_statusbar_info ();

		successful = true;
	}


	/**
	 * This method ensures that the view switcher and search box are sensitive/insensitive when they have to.
	 * It also selects the proper view switcher item based on the current view.
	 */
	protected void update_library_window_widgets () {
		if (!is_current_wrapper)
			return;

		// Play, pause, ...
		bool media_active = lm.media_active;
		bool media_visible = (showing_media_count > 0);
		lw.previousButton.set_sensitive (media_active || media_visible);
		lw.playButton.set_sensitive (media_active || media_visible);
		lw.nextButton.set_sensitive (media_active || media_visible);

		// select the right view in the view selector if it's one of the three views
		if (lw.viewSelector.selected != (int)current_view && (int)current_view <= 2)
			lw.viewSelector.set_active ((int)current_view);

		// Restore this view wrapper's search string
		//lw.searchField.changed.disconnect (search_field_changed);
		lw.searchField.set_text (actual_search_string);
		//lw.searchField.changed.connect (search_field_changed);

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

		set_active_view (selected_view);
	}

	// FIXME: this shouldn't depend on the list view
	public void play_first_media () {
		if (!has_list_view)
			return;

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

		update_library_window_widgets ();

#if INCLUDE_DEPRECATED
		// Update the views if needed
		if (needs_update && lw.initialization_finished)
			update_showing_media ();
		else // Update statusbar
			set_statusbar_info ();
#else
		set_statusbar_info ();
#endif
	}

	public void set_statusbar_info (Gee.Collection<int>? visible_media = null) {
		if (!is_current_wrapper)
			return;

		var media_set = visible_media ?? get_showing_media_ids ();

		if (media_set.size < 1) {
			lw.set_statusbar_info (hint, 0, 0, 0);
			return;
		}

		uint count = 0;
		uint total_time = 0;
		uint total_mbs = 0;


		foreach(int id in media_set) {
			var media = lm.media_from_id (id);
			if (media != null) {
				count ++;
				total_time += media.length;
				total_mbs += media.file_size;
			}
		}

		// FIXME: re-do. This works but is UGLY

		bool is_list = !(current_view == ViewType.ALBUM && has_album_view);

		if (!is_list) {
			count = album_view.n_albums;
		}

		lw.set_statusbar_info(hint, count, total_mbs, total_time, is_list);
	}


	public virtual void search_field_changed () {
		if (!is_current_wrapper)
			return;

		actual_search_string = lw.searchField.get_text ();
		var new_search = Search.get_valid_search_string (actual_search_string).down ();
		debug ("Searchbox has '%s'", new_search);

		if (new_search.length != 1) {
			timeout_search.offer_head (new_search.down ());

			Timeout.add (SEARCH_TIMEOUT, () => {
				// Don't search the same stuff every {SEARCH_TIMEOUT}ms
				string to_search = timeout_search.poll_tail();
				if (to_search != new_search || to_search == last_search)
					return false;

				last_search = to_search;
				// Do the actual search and show up results....
				update_showing_media ();

				return false;
			});
		}
	}


#if INCLUDE_DEPRECATED
	/**
	 * Updates the views to use the new data.
	 * For performance reasons, this process should be delayed until the user switches to this view wrapper.
	 * FIXME: @deprecated
	 */
	public void populate_views () {
		if (!lw.initialization_finished)
			return;
		
		// FIXME: redundant.
		if (check_show_embedded_alert ()) {
			needs_update = false;
			return;
		}

		if (has_album_view)
			album_view.populate_view ();

		if (has_list_view)
			list_view.populate_view ();

		// FIXME: column_browser_changed already does this when ListView :: column_browser_enabled is TRUE
		set_statusbar_info ();

		update_library_window_widgets ();

		// Okay, everything is updated now
		needs_update = false;
	}
#endif

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
	public void update_showing_media () {
		in_update.lock ();

		showing_medias = new HashMap<int, int>();

		// Perform search
		LinkedList<int> search_results_ids;
		Search.search_in_media_ids (lm, get_media_ids (), out search_results_ids, get_search_string());

		var search_results = new Gee.LinkedList<Media> ();
		foreach (int i in search_results_ids) {
			showing_medias.set (i, 1);
			search_results.add (lm.media_from_id (i));
		}

		if (has_album_view)
			album_view.set_media (search_results);

		if (has_list_view)
			list_view.set_media (search_results);

#if INCLUDE_DEPRECATED
		// Now update the views to reflect the change
		if (_populate_views)
			populate_views (); // this also updates the statusbar
#endif

		// Check whether we should show the embedded alert in case there's no media
		check_show_embedded_alert ();

		in_update.unlock ();
	}


	public void set_media (Collection<int>? new_media) {
		if (new_media == null)
			return;

		medias = new HashMap <int, int>();

		foreach (int i in new_media)
			medias.set (i, 1);

#if INCLUDE_DEPRECATED
		// update showing media. Don't update the views if inside a thread
		if (!is_current_wrapper || in_thread)
			needs_update = true; //delay the update until the user switches to this view
		else
			update_showing_media ();
#else
		update_showing_media ();
#endif
	}


	protected bool check_show_embedded_alert () {
		if (has_embedded_alert || has_welcome_screen) {
			int size_check = media_count;

			if (size_check < 1) { // no media
				if (has_embedded_alert) {
					set_default_alert ();
					set_active_view (ViewType.ALERT);
				}
				else if (has_welcome_screen) {
					set_active_view (ViewType.WELCOME);
				}

				return true;
			}

			var new_view = (ViewType) lw.viewSelector.selected;
			
			if (current_view != new_view && (new_view == ViewType.LIST && has_list_view) || (new_view == ViewType.ALBUM && has_album_view))
				set_active_view (new_view);
		}

		return false;
	}

	private void set_default_alert () {
		if (!has_embedded_alert)
			return;

		switch (hint) {
			case Hint.MUSIC:
				break;
			case Hint.QUEUE:
				embedded_alert.set_alert (_("No songs in Queue"), _("To add songs to the queue, use the <b>secondary click</b> on an item and choose <b>Queue</b>. When a song finishes, the queued songs will be played first before the next song in the currently playing list."), null, true, Granite.Widgets.EmbeddedAlert.Level.INFO);
				break;
			case Hint.HISTORY:
				embedded_alert.set_alert (_("No songs in History"), _("After a part of a song has been played, it is added to the history list.\nYou can use this list to see all the songs you have played during the current session."), null, true, Granite.Widgets.EmbeddedAlert.Level.INFO);
				break;
			case Hint.CDROM:
				embedded_alert.set_alert (_("Audio CD Invalid"), _("%s could not read the contents of this Audio CD").printf (lw.app.get_name ()), null, true, Granite.Widgets.EmbeddedAlert.Level.WARNING);
				break;
			case Hint.PLAYLIST:
				embedded_alert.set_alert (_("No Songs"), _("To add songs to this playlist, use the <b>secondary click</b> on an item and choose <b>Add to Playlist</b>."), null, true, Granite.Widgets.EmbeddedAlert.Level.INFO);
				break;
			case Hint.SMART_PLAYLIST:
				embedded_alert.set_alert (_("No Songs"), _("This playlist will be automatically populated with songs that match its rules. To modify these rules, use the <b>secondary click</b> on it in the sidebar and click on <b>Edit</b>."), null, true, Granite.Widgets.EmbeddedAlert.Level.INFO);
				break;
			default:
				break;
		}
	}



	/**
	 * Do search to find which ones should be added, removed from this particular view
	 */
	public void update_media (Collection<int> ids) {
		in_update.lock ();

		// find which media belong here
		LinkedList<int> should_be, should_show;

		Collection<int> to_search;

		if(hint == Hint.SMART_PLAYLIST)
			to_search = lm.smart_playlist_from_id(relative_id).analyze(lm, ids);
		else
			to_search = ids;

		lm.do_search (to_search, out should_be, null, null, null, null, hint);
		lm.do_search (to_search, out should_show, null, null, null, null, hint, get_search_string());

		var to_remove = new LinkedList<int>();
		var to_add_show = new LinkedList<Media>();
		var to_remove_show = new LinkedList<Media>();

		// add elements that should be here
		foreach(int i in should_be)
			medias.set(i, 1);

		// add elements that should show
		foreach(int i in should_show) {
			if(!showing_medias.has_key (i))
				to_add_show.add (lm.media_from_id (i));
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
				to_remove_show.add (lm.media_from_id (i));
				showing_medias.unset(i);
			}
		}

		if (populate_views) { // update right away
			/*
			XXX Not doing this for now since it causes problems
			to the column browser. A proper fix has to be added
			to ListView.vala
			if (has_list_view) {
				list_view.append_media(to_add);
				list_view.remove_media(to_remove_show);
			}
			*/

			if (has_album_view) {
				album_view.append_media(to_add_show);
				album_view.remove_media(to_remove_show);
			}

			set_statusbar_info ();
			update_library_window_widgets ();
		}
#if 0
		else {
			Idle.add( () => {
				if (!lw.initialization_finished)
					return true;

				/*
				XXX Not doing this for now since it causes problems
				to the column browser. A proper fix has to be added
				to ListView.vala
				if (has_list_view) {
					list_view.append_media(to_add);
					list_view.remove_media(to_remove_show);
				}
				*/

				if (has_album_view) {
					album_view.append_media(to_add_show);
					album_view.remove_media(to_remove_show);
				}

				return false;
			});
		}
#endif
		in_update.unlock ();
	}


	public void remove_media (Collection<int> ids) {
		in_update.lock ();

		// find which media to remove and remove it from
		// Media and Showing Media
		var to_remove = new LinkedList<Media>();
		foreach(int i in ids) {
			medias.unset(i);

			if(showing_medias.has_key (i))
				to_remove.add (lm.media_from_id (i));

			showing_medias.unset(i);
		}

		if (check_show_embedded_alert()) {
			in_update.unlock ();
			return;
		}	

		// Now update the views to reflect the changes

		if (has_album_view)
			album_view.remove_media (to_remove);

		if (has_list_view)
			list_view.remove_media (to_remove);

		if (is_current_wrapper) {
			update_library_window_widgets ();
			set_statusbar_info ();
		}

		in_update.unlock ();
	}


	public void add_media (Collection<int> new_media) {
		debug ("add_media to %s", hint.to_string ());
		in_update.lock ();

		// find which media to add and update Media
		var to_add = new LinkedList<int>();

		if (hint == Hint.SMART_PLAYLIST) {
			to_add =  lm.smart_playlist_from_id(relative_id).analyze(lm, new_media);
		}
		else {
			foreach(int i in new_media) {
				if (!medias.has_key (i)) {
					medias.set(i, 1);
					to_add.add(i);
				}
			}
		}

		// Do search since Showing Media depends on the search string
		LinkedList<int> to_show_ids;
		lm.do_search (to_add, out to_show_ids, null, null, null, null, hint, get_search_string());

		var to_show = new Gee.LinkedList<Media> ();
		// Update showing media
		foreach (int i in to_show_ids) {
			to_show.add (lm.media_from_id (i));
			showing_medias.set(i, 1);
		}

		if (check_show_embedded_alert()) {
			in_update.unlock ();
			return;
		}

		if (populate_views) {
			if (has_album_view)
				album_view.append_media (to_add);

			if (has_list_view)
				list_view.append_media (to_add);

			set_statusbar_info ();
			update_library_window_widgets ();

		}
#if 0
		else {
			Idle.add ( () => {
				if (!lw.initialization_finished)
					return true;
				
				if (has_album_view)
					album_view.append_media (to_add);

				if (has_list_view)
					list_view.append_media (to_add);
	
				return false;
			});
		}
#endif

		in_update.unlock ();
	}
}

