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
	// XXX change this back to ContentView later on!
	public ListView      list_view      { get; private set; }
	public AlbumView     album_view     { get; private set; }
	public WarningLabel  error_box      { get; private set; }
	public Welcome       welcome_screen { get; private set; }

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

	public int index { get { return lw.main_views.page_num(this); } }

	public bool is_current_wrapper {
		get {
			return (lw.initialization_finished ? (index == lw.main_views.get_current_page()) : false);
		}
	}

	/* UI PROPERTIES */

	public bool has_album_view      { get { return album_view != null;     } }
	public bool has_list_view       { get { return list_view != null;      } }
	public bool has_error_box       { get { return error_box != null;      } }
	public bool has_welcome_screen  { get { return welcome_screen != null; } }

	public bool has_media { get { return media_count > 0; } }


	const int SEARCH_TIMEOUT = 340; // ms

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
	protected LinkedList<string> timeout_search;

	// Stops from searching same thing multiple times
	protected string last_search = "";
	protected string actual_search_string = ""; // what the user actually typed in the search box.

	public string get_search_string () {
		return last_search;
	}

	// Stops from searching unnecesarilly when changing b/w 0 words and search.
	private bool showing_all { get { return showing_media_count == media_count; } }

	public int showing_media_count { get { return (showing_medias != null) ? showing_medias.size : 0; } }

	private bool setting_search = false;

	public bool needs_update;
	protected Mutex in_update = new Mutex ();

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

		foreach(int i in the_media)
			medias.set(i, 1);

		// Setup view container
		view_container = new Notebook ();
		view_container.show_tabs = false;
		view_container.show_border = false;
		this.pack_start (view_container, true, true, 0);

		// FIXME: Get error boxes' text out of here. It must be set within
		//         a different method, so that we can use them to handle different
		//         cases, like "No media", "No media found. Did you mean '...' ", etc.

		switch (hint) {
			case Hint.MUSIC:
				// list and album view
				album_view = new AlbumView (this);
				list_view = new ListView (this, tvs);

				// Welcome screen
				welcome_screen = new Granite.Widgets.Welcome(_("Get Some Tunes"), _("Noise can't seem to find your music."));
				
				break;
			case Hint.HISTORY:
			case Hint.QUEUE:
				//list view only				
				list_view = new ListView (this, tvs);

				error_box = new WarningLabel();
				error_box.show_icon = false;
				
				error_box.setWarning ("<span weight=\"bold\" size=\"larger\">" + _("Empty Playlist") + "</span>\n\n" + _("..."));
				break;
			case Hint.PLAYLIST:
			case Hint.SMART_PLAYLIST:
				// list and album view
				album_view = new AlbumView (this);
				list_view = new ListView (this, tvs);

				error_box = new WarningLabel();
				error_box.show_icon = false;
				
				if (hint == Hint.PLAYLIST)
					error_box.setWarning ("<span weight=\"bold\" size=\"larger\">" + _("Empty Playlist") + "</span>\n\n" + _("..."));
				else
					error_box.setWarning ("<span weight=\"bold\" size=\"larger\">" + _("Empty Playlist") + "</span>\n\n" + _("..."));

				
				break;
			case Hint.SIMILAR:
				// list view only
				list_view = new ListView (this, tvs);

				error_box = new WarningLabel();
				error_box.show_icon = false;
				error_box.setWarning ("<span weight=\"bold\" size=\"larger\">" + _("Similar Media View") + "</span>\n\n" + _("In this view, BeatBox will automatically find medias similar to the one you are playing.") + "\n" + _("You can then start playing those medias, or save them for later."));
				break;
#if HAVE_PODCASTS
			case Hint.PODCAST:
				// list and album view
				album_view = new AlbumView (this);
				list_view = new ListView (this, tvs);

				error_box = new WarningLabel();
				error_box.show_icon = false;
				error_box.setWarning ("<span weight=\"bold\" size=\"larger\">" + _("No Podcasts Found") + "</span>\n\n" + _("To add a podcast, visit a website such as Miro Guide to find RSS Feeds.") + "\n" + _("You can then copy and paste the feed into the \"Add Podcast\" window by right clicking on \"Podcasts\"."));

				break;
			case Hint.DEVICE_PODCAST:
				// list and album view
				album_view = new AlbumView (this);
				list_view = new ListView (this, tvs);

				error_box = new WarningLabel();
				error_box.show_icon = false;
				error_box.setWarning ("<span weight=\"bold\" size=\"larger\">" + _("No Podcasts Found") + "</span>\n\n" + _("To add a podcast, visit a website such as Miro Guide to find RSS Feeds.") + "\n" + _("You can then copy and paste the feed into the \"Add Podcast\" window by right clicking on \"Podcasts\"."));

				break;
#endif
#if HAVE_INTERNET_RADIO
			case Hint.STATION:
				// list view
				list_view = new ListView (this, tvs);

				error_box = new WarningLabel();
				error_box.show_icon = false;
				error_box.setWarning ("<span weight=\"bold\" size=\"larger\">" + _("No Internet Radio Stations Found") + "</span>\n\n" + _("To add a station, visit a website such as SomaFM to find PLS or M3U files.") + "\n" + _("You can then import the file to add the station."));

				break;
#endif
			case Hint.AUDIOBOOK:
				// list and album view
				album_view = new AlbumView (this);
				list_view = new ListView (this, tvs);

				break;
			case Hint.DEVICE_AUDIOBOOK:
				// list and album views
				album_view = new AlbumView (this);
				list_view = new ListView(this, tvs);

				break;
			case Hint.CDROM:
				// list view only
				list_view = new ListView (this, tvs);

				error_box = new WarningLabel();
				error_box.show_icon = true;
				error_box.setWarning ("<span weight=\"bold\" size=\"larger\">" + _("Audio CD Invalid") + "</span>\n\n" + _("BeatBox could not read the contents of this Audio CD."));

				break;
			default:
				// nothing but an error box
				error_box = new WarningLabel ();
				error_box.show_icon = true;
				error_box.setWarning ("<span weight=\"bold\" size=\"larger\">" + _("WARNING: Default View Wrapper!"));
				break;
		}

		// Now setup the view wrapper based on available widgets

		if (has_error_box) {
			view_container.append_page (error_box);
		}

		if (has_welcome_screen) {
			view_container.append_page (welcome_screen);
		}

		if (has_album_view)
			view_container.append_page (album_view);

		if (has_list_view)
			view_container.append_page (list_view);



		// Connect data signals

		if (hint == Hint.QUEUE) {
			lm.media_queued.connect ( (media_ids) => {
				add_media (media_ids);
			});
		}

		if (hint != Hint.CDROM && hint != Hint.DEVICE_PODCAST && hint != Hint.DEVICE_AUDIO && hint != Hint.DEVICE_AUDIOBOOK) {
			lm.medias_updated.connect (update_media);
			lm.medias_removed.connect (remove_media);

			if (hint == Hint.PLAYLIST) {
				// Listen for playlist additions/removals
				lm.playlist_from_id (relative_id).changed.connect (playlist_changed);
			}
			else if (hint != Hint.SIMILAR && hint != Hint.QUEUE) {
				// if hint != Hint.SMART_PLAYLIST add_media() will re-analyze everything
				lm.medias_added.connect (add_media);
			}
		}

		lw.searchField.changed.connect (search_field_changed);
		lw.viewSelector.mode_changed.connect (view_selector_changed);

		// Populate views
		needs_update = true; // set_as_current_view() will populate the views later...

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
			case ViewType.ERROR:
				if (has_error_box)
					view_index = view_container.page_num (error_box);
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

		// Update BeatBox's toolbar widgets
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
		lw.previousButton.set_sensitive(media_active || media_visible);
		lw.playButton.set_sensitive(media_active || media_visible);
		lw.nextButton.set_sensitive(media_active || media_visible);

		// select the right view in the view selector if it's one of the three views
		if (lw.viewSelector.selected != (int)current_view && (int)current_view <= 2)
			lw.viewSelector.set_active ((int)current_view);

		setting_search = true;
		// Restore this view wrapper's search string
		lw.searchField.set_text (actual_search_string);
		setting_search = false;

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
		if (!lw.initialization_finished || (lw.initialization_finished && (int)current_view == lw.viewSelector.selected) || current_view == ViewType.ERROR || current_view == ViewType.WELCOME)
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

		// Update the views if needed
		if (needs_update && lw.initialization_finished)
			update_showing_media ();
		else // Update statusbar
			set_statusbar_info ();
	}


	public void set_statusbar_info (Gee.Collection<int>? visible_media = null) {
		if (!is_current_wrapper || !lw.initialization_finished)
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

		bool is_list = !(current_view == ViewType.ALBUM && has_album_view);

		if (!is_list) {
			count = album_view.n_albums;
		}

		lw.set_statusbar_info(hint, count, total_mbs, total_time, is_list);
	}


	public virtual void search_field_changed() {
		if (!is_current_wrapper || !lw.initialization_finished)
			return;

		actual_search_string = lw.searchField.get_text();
		var new_search = Utils.get_valid_search_string (actual_search_string);
		debug ("Searchbox has '%s'", new_search);

		if(!setting_search && lw.initialization_finished && is_current_wrapper && new_search.length != 1 && this.visible) {
			timeout_search.offer_head (new_search.down());

			Timeout.add (SEARCH_TIMEOUT, () => {
				// Don't search the same stuff every {SEARCH_TIMEOUT}ms
				string to_search = timeout_search.poll_tail();
				if (to_search != new_search || to_search == last_search)
					return false;

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
	 * FIXME: @deprecated
	 */
	public void populate_views () {
		if (!lw.initialization_finished)
			return;
		
		if (check_show_error_box()) {
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

	/**
	============================================================================
	                                  DATA STUFF
	============================================================================
	*/

	// For playlists
	void playlist_changed () {
		Playlist p = lm.playlist_from_id(relative_id);
		
		set_media (p.medias ());
	}

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

		in_update.lock ();

		showing_medias = new HashMap<int, int>();

		// Perform search
		LinkedList<int> search_results;

		Utils.search_in_media_ids (lm, get_media_ids (), out search_results, get_search_string());

		foreach (int i in search_results)
			showing_medias.set (i, 1);

		// FIXME: Use new api
		if (has_album_view)
			album_view.set_show_next (search_results);

		if (has_list_view)
			list_view.set_show_next (search_results);

		// Now update the views to reflect the change
		if (_populate_views)
			populate_views (); // this also updates the statusbar

		// Check whether we should show the error box in case there's no media
		check_show_error_box ();

		in_update.unlock ();
	}


	public void set_media (Collection<int>? new_media, bool in_thread = false) {
		if (new_media == null)
			return;

		medias = new HashMap <int, int>();

		foreach (int i in new_media)
			medias.set (i, 1);

		// update showing media. Don't update the views if inside a thread
		if (!is_current_wrapper || in_thread)
			needs_update = true; //delay the update until the user switches to this view
		else
			update_showing_media ();
	}


	protected bool check_show_error_box () {
		// Check if we should show the error box or welcome screen here
		// FIXME: we could do better here. We should be able to set what kind of view we
		//         want to handle the no-media case and maybe just emit a signal here.
		if (has_error_box || has_welcome_screen) {
			int size_check;

#if HAVE_PODCASTS
			if (hint == Hint.PODCAST) {
				size_check = 0;
				foreach (int i in lm.podcast_ids()) {
					if (!lm.media_from_id(i).isTemporary)
						++size_check;
				}
			}
			else
#endif

#if HAVE_INTERNET_RADIO
			if (hint == Hint.STATION) {
				size_check = 0;
				foreach (int i in lm.station_ids()) {
					if (lm.media_from_id(i) != null)
						++size_check;
				}
			}
			else {
#endif

				size_check = media_count;
#if HAVE_INTERNET_RADIO
			}
#endif

			if (size_check < 1) { // no media
				if (has_error_box)
					set_active_view (ViewType.ERROR);
				else if (has_welcome_screen)
					set_active_view (ViewType.WELCOME);

				return true;
			}

			var new_view = (ViewType) lw.viewSelector.selected;
			
			if (current_view != new_view && (new_view == ViewType.LIST && has_list_view) || (new_view == ViewType.ALBUM && has_album_view))
				set_active_view (new_view);
		}

		return false;
	}


	/**
	 * Do search to find which ones should be added, removed from this particular view
	 * does not re-anaylyze smart playlist_views or playlist_views.
	 */
	public void update_media (Collection<int> ids) {
		in_update.lock ();

		if (is_current_wrapper || hint == Hint.QUEUE || hint == Hint.SMART_PLAYLIST) {
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

			// FIXME: use hashtables. mandatory in new API

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
					album_view.append_media(to_add);
					album_view.remove_media(to_remove_show);
				}

				set_statusbar_info ();
				update_library_window_widgets ();

				return false;
			});
		}
		else {
			needs_update = true;
		}


		in_update.unlock ();
	}


	public void remove_media (Collection<int> ids) {
		in_update.lock ();

		// find which media to remove and remove it from
		// Media and Showing Media
		var to_remove = new LinkedList<int>();
		foreach(int i in ids) {
			medias.unset(i);

			if(showing_medias.get(i) != 0)
				to_remove.add(i);

			showing_medias.unset(i);
		}

		if (check_show_error_box()) {
			in_update.unlock ();
			return;
		}	

		// Now update the views to reflect the changes

		if (has_album_view)
			album_view.remove_media (to_remove);

		if (has_list_view)
			list_view.remove_media (to_remove);

		update_library_window_widgets ();
		set_statusbar_info ();

		in_update.unlock ();
	}


	public void add_media (Collection<int> new_media) {
		in_update.lock ();

		//if(hint == Hint.MUSIC || hint == Hint.PODCAST || hint == Hint.STATION) { //FIXME DEVICE_?
		if (is_current_wrapper || hint == Hint.QUEUE || hint == Hint.SMART_PLAYLIST) {
			// find which media to add and update Media
			var to_add = new LinkedList<int>();

			if (hint == Hint.SMART_PLAYLIST) {
				to_add =  lm.smart_playlist_from_id(relative_id).analyze(lm, new_media);
			}
			else {
				foreach(int i in new_media) {
					if(medias.get(i) == 0) {
						medias.set(i, 1);
						to_add.add(i);
					}
				}
			}

			// Do search since Showing Media depends on the search string
			LinkedList<int> to_show;
			lm.do_search (to_add, out to_show, null, null, null, null, hint, get_search_string());

			// Update Showing Media
			foreach(int i in to_show)
				showing_medias.set(i, 1);

			if (check_show_error_box()) {
				in_update.unlock ();
				return;
			}

			if (has_album_view)
				album_view.append_media (to_add);

			if (has_list_view)
				list_view.append_media (to_add);

			set_statusbar_info ();
			update_library_window_widgets ();
		}
		else {
			needs_update = true;
		}

		in_update.unlock ();
	}
}

