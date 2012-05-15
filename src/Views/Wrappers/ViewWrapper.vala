// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012 Noise Developers (http://launchpad.net/noise)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Victor Eduardo <victoreduardm@gmail.com>,
 *              Scott Ringwelski <sgringwe@mtu.edu>
 */

using Gtk;
using Granite.Widgets;
using Gee;

public abstract class BeatBox.ViewWrapper : Gtk.Box {

    public LibraryManager lm { get; protected set; }
    public LibraryWindow  lw { get; protected set; }

    protected ViewContainer view_container; // Wraps all the internal views for super fast switching

    /* MAIN WIDGETS (VIEWS) */
    public ListView      list_view      { get; protected set; }
    public AlbumView     album_view     { get; protected set; }

    public EmbeddedAlert embedded_alert { get; protected set; }
    public Welcome       welcome_screen { get; protected set; }

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

    public ViewType current_view { get; protected set; }

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

    public Hint hint { get; protected set; }

    public int relative_id { get; protected set; }

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
    protected Gee.HashMap<Media, int> media_table = new Gee.HashMap<Media, int> ();
    protected Gee.HashMap<Media, int> visible_media_table = new Gee.HashMap<Media, int> ();

    public int media_count { get { return (media_table != null) ? media_table.size : 0; } }


    public ViewWrapper (LibraryWindow lw, TreeViewSetup tvs, int id)
    {
        this.lm = lw.lm;
        this.lw = lw;

        this.relative_id = id;
        this.hint = tvs.get_hint ();

        debug ("BUILDING %s", hint.to_string());

        // Setup view container
        view_container = new ViewContainer ();
        this.pack_start (view_container, true, true, 0);

        // Now setup the view wrapper based on available widgets

        lw.viewSelector.mode_changed.connect (view_selector_changed);
        lw.searchField.changed.connect (search_field_changed);

        debug ("FINISHED BUILDING %s\n\n\n", hint.to_string());
    }

#if 0
    public ViewWrapper.with_view (Gtk.Widget view) {
        view_container.add_view (view);
        this.hint = Hint.NONE;
        set_active_view (ViewType.NONE);
        update_library_window_widgets ();
    }
#endif

    /* Re-checks which views are available and packs them in */
    protected void pack_views () {
        if (has_album_view && view_container.get_view_index (album_view) < 0) {
            view_container.add_view (album_view);
        }

        if (has_list_view && view_container.get_view_index (list_view) < 0) {
            view_container.add_view (list_view);
        }

        if (has_welcome_screen && view_container.get_view_index (welcome_screen) < 0) {
            view_container.add_view (welcome_screen);
        }

        if (has_embedded_alert && view_container.get_view_index (embedded_alert) < 0) {
            view_container.add_view (embedded_alert);
        }
    }

    /**
     * Convenient visibility method
     */
    protected void set_active_view (ViewType type, out bool successful = false) {
        // Find position in notebook
        switch (type) {
            case ViewType.LIST:
                successful = view_container.set_current_view (list_view);
                break;
            case ViewType.ALBUM:
                successful = view_container.set_current_view (album_view);
                break;
            case ViewType.ALERT:
                successful = view_container.set_current_view (embedded_alert);
                break;
            case ViewType.WELCOME:
                successful = view_container.set_current_view (welcome_screen);
                break;
        }

        // i.e. we're not switching (officially) to that view if it's not available
        if (!successful) {
            debug ("%s : VIEW %s was not available", hint.to_string(), type.to_string ());
            return;
        }

        // Set view as current
        current_view = type;

        debug ("%s : switching to %s", hint.to_string(), type.to_string ());

        // Update LibraryWindow toolbar widgets
        update_library_window_widgets ();

        update_statusbar_info ();
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
        // FIXME also check for lw.viewSelector.sensitive before proceeding
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

    /**
     * ---------------------------------------------------------------------------------
     *      ALL THE VIEW WRAPPERS MUST IMPLEMENT THIS.
     * ---------------------------------------------------------------------------------
     *
     * It tells the parent class whether the search field, media control buttons, and
     * other external widgets should be sensitive or not (among other things), so that
     * the parent abstract class can take care of all these automated/repetitive tasks for you.
     *
     * In case your view wrapper doesn't have an alert box or welcome screen, and it
     * doesn't need any kind of complex size-based behavior, you should check the value of
     * media_count and return <true> or <false> based on that.
     *
     * For most cases, "return media_count > 0;" is enough.
     *
     * In case the view contains an alert box and/or welcome screen, it is recommended
     * to set either view as current from your implementation before returning anything.
     * (Using set_active_view.)
     *
     * The child ViewWrappers are also responsible for setting the proper view back after
     * the alert/welcome screens are no longer needed (i.e. when the method would return 'true'.)
     * select_proper_content_view() selects the best suited view for you in case you don't want
     * to handle that. You still need to call it from the implementation though.
     *
     * EXAMPLE:
     *
     *    // Taken from MusicViewWrapper.vala
     *    protected bool check_have_media () {
     *        bool have_media = media_count > 0;
     *
     *        // show welcome screen if there's no media
     *        if (have_media)
     *            select_proper_content_view ();
     *        else if (has_welcome_screen)
     *            set_active_view (ViewType.WELCOME);
     *
     *        return have_media;
     *    }
     *
     *
     * WARNING: Don't ever attempt calling the set_media(), update_media(), add_media() or remove_media()
     *          methods (including async variations) from your implementation, unless you want the method
     *          to fall into an infinite loop, potentially freezing the entire application.
     *
     * @return true if the ViewWrapper has media. false otherwise.
     */
    protected abstract bool check_have_media ();

    protected virtual void select_proper_content_view () {
            debug ("Selecting proper content view automatically");
            // FIXME: I can't believe I wrote this. WE CAN DO BETTER HERE (Victor).
            if (current_view == ViewType.ALERT || current_view == ViewType.WELCOME) {
                var new_view = (ViewType) lw.viewSelector.selected;
                debug ("%s : showing %s", hint.to_string(), new_view.to_string ());
                
                if (current_view != new_view) {
                    if (new_view == ViewType.LIST && has_list_view)
                        set_active_view (ViewType.LIST);
                    else if (new_view == ViewType.ALBUM && has_album_view)
                        set_active_view (ViewType.ALBUM);
                }
            }        
    }


    /**
    ============================================================================
                                      DATA STUFF
    ============================================================================
    */

    /*
     * The clients shouldn't be able to lock this mutex (hence it's private).
     * It could have terrible results it a child view wrapper locks it before
     * calling set_media().
     */
    private Mutex in_update;

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
    private void update_visible_media () {
        in_update.lock ();

        debug ("%s : UPDATING SHOWING MEDIA", hint.to_string ());

        visible_media_table = new HashMap<Media, int> ();
        var to_search = get_search_string ();

        var search_results = new Gee.LinkedList<Media> ();

        if (to_search != "") {
            // Perform search
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

    /**
     * /!\ Async variants. Don't use them if you depend on the results to proceed in your method
     */
    public async void set_media_async (Gee.Collection<Media> new_media) {
        set_media (new_media);
    }

    public async void set_media_from_ids_async (Gee.Collection<int> new_media) {
        set_media_from_ids (new_media);
    }

    public async void add_media_async (Gee.Collection<Media> to_add) {
        add_media (to_add);
    }

    public async void remove_media_async (Gee.Collection<Media> to_remove) {
        remove_media (to_remove);
    }

    public async void update_media_async (Gee.Collection<Media> to_update) {
        update_media (to_update);
    }


    /**
     * Normal variants
     */

    public void clear_filters () {
        /**
         * /!\ Currently setting the search to "" is enough. Remember to update it
         *     if the internal views try to restore their previous state after changes.
         */
        lw.searchField.set_text ("");
    }

    public void set_media_from_ids (Gee.Collection<int> new_media) {
        var to_set = new Gee.LinkedList<Media> ();
        foreach (var id in new_media)
            to_set.add (lm.media_from_id (id));
        set_media (to_set);
    }

    public void set_media (Collection<Media> new_media) {
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
    public void update_media (Gee.Collection<Media> media) {
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


    public void remove_media (Collection<Media> media) {
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


    public void add_media (Collection<Media> new_media) {
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

