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

public abstract class Noise.ViewWrapper : Gtk.Box {

    public LibraryManager lm { get; protected set; }
    public LibraryWindow  lw { get; protected set; }

    private Gtk.Box layout_box;
    private ViewContainer view_container;

    // FIXME: should be protected instead of public
    public ContentView list_view { get; protected set; }
    public ContentView grid_view { get; protected set; }

    protected Granite.Widgets.EmbeddedAlert embedded_alert { get; protected set; }
    protected Granite.Widgets.Welcome welcome_screen { get; protected set; }

    /* UI PROPERTIES */
    public bool has_grid_view { get { return grid_view != null; } }
    public bool has_list_view { get { return list_view != null;  } }
    public bool has_embedded_alert  { get { return embedded_alert != null; } }
    public bool has_welcome_screen  { get { return welcome_screen != null; } }

    protected bool widgets_ready = false;

    // Contruction must always happen before population
    protected const int VIEW_CONSTRUCT_PRIORITY = Priority.DEFAULT_IDLE - 10;

    /**
     * Type of visual representation of the media.
     *
     * Values *must* match the index of the respective view in the view selector.
     */
    public enum ViewType {
        GRID    = 0, // Matches index 0 of the view in lw.viewSelector
        LIST    = 1, // Matches index 1 of the view in lw.viewSelector
        ALERT   = 2, // For embedded alerts
        WELCOME = 3, // For welcome screens
        NONE    = 4  // Nothing showing
    }

    public ViewType current_view { get; private set; default = ViewType.NONE; }


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
        NETWORK_DEVICE,
        ALBUM_LIST;
    }

    /**
     * This is by far the most important property of this object.
     * It defines how child widgets behave and some other properties.
     */
    public Hint hint { get; protected set; }

    public int index { get { return lw.view_container.get_view_index (this); } }

    public bool is_current_wrapper {
        get {
            return (lw.initialization_finished ? (index == lw.view_container.get_current_index ()) : false);
        }
    }

    /**
     * TODO: deprecate. it's only useful for PlaylistViewWrapper
     */
    public int relative_id { get; protected set; default = -1; }


    public int media_count { get { return (media_table != null) ? media_table.size : 0; } }

    public ViewWrapper (LibraryWindow lw, Hint hint)
    {
        this.lm = lw.library_manager;
        this.lw = lw;
        this.hint = hint;

        // Allows inserting widgets on top of the view
        layout_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        view_container = new ViewContainer ();

        layout_box.pack_end (view_container, true, true, 0);
        this.pack_start (layout_box, true, true, 0);

        lw.viewSelector.mode_changed.connect (view_selector_changed);
        lw.searchField.text_changed_pause.connect (search_field_changed);
    }

    protected void insert_widget (Gtk.Widget widget, bool on_top = true) {
        if (view_container == null) {
            critical ("insert_widget() failed. Param 'widget' is NULL");
            return;
        }

        if (on_top)
            layout_box.pack_start (widget, false, false, 0);
        else
            layout_box.pack_end (widget, false, false, 0);
    }

    /* Checks which views are available and packs them in (if they are not yet packed) */
    protected void pack_views () {
        if (view_container == null) {
            critical ("pack_views() failed. Container is NULL");
            return;
        }

        if (has_grid_view && !view_container.has_view (grid_view)) {
            view_container.add_view (grid_view);
        }

        if (has_list_view && !view_container.has_view (list_view)) {
            view_container.add_view (list_view);
        }

        if (has_welcome_screen && !view_container.has_view (welcome_screen)) {
            view_container.add_view (welcome_screen);
        }

        if (has_embedded_alert && !view_container.has_view (embedded_alert)) {
            view_container.add_view (embedded_alert);
        }

        widgets_ready = true;
        show_all ();
    }

    /**
     * Convenient visibility method
     */
    protected void set_active_view (ViewType type, out bool successful = null) {
        successful = false;

        switch (type) {
            case ViewType.LIST:
                successful = view_container.set_current_view (list_view);
                ((ListView)list_view).list_view.scroll_to_current_media(true);
                break;
            case ViewType.GRID:
                successful = view_container.set_current_view (grid_view);
                break;
            case ViewType.ALERT:
                successful = view_container.set_current_view (embedded_alert);
                break;
            case ViewType.WELCOME:
                successful = view_container.set_current_view (welcome_screen);
                break;
        }

        // We're not switching (officially) to that view if it's not available
        if (!successful) {
            debug ("%s : VIEW %s was not available", hint.to_string(), type.to_string ());
            return;
        }

        // Set view as current
        current_view = type;

        debug ("%s : switching to %s", hint.to_string(), type.to_string ());

        // Update LibraryWindow widgets
        update_library_window_widgets ();
    }


    /**
     * This method ensures that the view switcher and search box are sensitive/insensitive
     * when they have to. It also selects the proper view switcher item based on the
     * current view.
     */
    protected void update_library_window_widgets () {
        if (!is_current_wrapper)
            return;

        debug ("%s : update_library_window_widgets", hint.to_string());

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
            lw.viewSelector.set_sensitive (has_grid_view && has_list_view);

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

        // select the right view in the view selector if it's one of the three views.
        // The order is important here. The sensitivity set above must be set before this,
        // as view_selector_changed() depends on that.
        if (lw.viewSelector.selected != (int)current_view && (int)current_view <= 2)
            lw.viewSelector.set_active ((int)current_view);

        // The statusbar is also a library window widget
        update_statusbar_info ();

        /* XXX
           /!\ WARNING: NOT ENTERELY NECESSARY.
           It's here to avoid potential issues. Should be removed
           if it impacts performance.
        */
        //lw.update_sensitivities();
    }

    public virtual void view_selector_changed () {
        if (!lw.initialization_finished || (lw.initialization_finished && (int)current_view == lw.viewSelector.selected) || current_view == ViewType.ALERT || current_view == ViewType.WELCOME || !lw.viewSelector.sensitive)
            return;

        debug ("%s : view_selector_changed : applying actions", hint.to_string());

        var selected_view = (ViewType) lw.viewSelector.selected;

        if (is_current_wrapper) { // apply changes right away
            set_active_view (selected_view);
        }
        else { // only set current_view and let set_as_current_view() do the actual job
            current_view = selected_view;
        }
    }

    // FIXME: this shouldn't depend on the list view
    public void play_first_media () {
        if (!has_list_view)
            return;

        debug ("%s : play_first_media", hint.to_string());

        (list_view as ListView).set_as_current_list(1, true);
        var m = lm.mediaFromCurrentIndex (0);

        if (m == null)
           return;

        lm.playMedia (m, false);
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
    }

    /**
     * XXX, FIXME: Although this is working perfectly, it's embarrassing. This should
     *             be implemented by client code, and while it's overridable, we shouldn't
     *             have any kind of specific implementation-code hanging around here, since it simply
     *             breaks the entire abstraction.
     */
    protected virtual string get_statusbar_text () {
        if (current_view == ViewType.ALERT || current_view == ViewType.WELCOME)
            return "";

        bool is_album = false;

        Gee.Collection<Media>? media_set = null;

        // Get data based on the current view
        if (current_view == ViewType.GRID) {
            is_album = true;

            // Let's use the local data since it has no internal filter
            media_set = new Gee.LinkedList<Media> ();
            foreach (var m in get_visible_media_list ()) {
                if (m != null)
                    media_set.add (m);
            }
        }
        else if (current_view == ViewType.LIST) {
            media_set = list_view.get_visible_media ();
        }

        uint total_items = 0;
        uint64 total_size = 0, total_time = 0;

        foreach (var media in media_set) {
            if (media != null) {
                total_items ++;
                total_time += media.length;
                total_size += media.file_size;
            }
        }

        if (total_items < 1) {
            return "";
        }

        // FIXME: bad workaround
        if (current_view == ViewType.GRID && has_grid_view) {
            total_items = grid_view.get_visible_media ().size;
        }

        string media_description = "";

        if (is_album)
            media_description = ngettext ("%u album", "%u albums", total_items).printf (total_items);
        else
            media_description = ngettext ("%u song", "%u songs", total_items).printf (total_items);
 
        string media_text = media_description.printf (total_items);
        string time_text = TimeUtils.time_string_from_miliseconds (total_time);
        string size_text = format_size (total_size);

        return "%s, %s, %s".printf (media_text, time_text, size_text);
    }

    public async void update_statusbar_info () {
        if (!is_current_wrapper)
            return;

        debug ("%s : updating statusbar info", hint.to_string ());

        lw.statusbar.set_info (get_statusbar_text ());
    }


    // Current search filter
    protected string last_search = "";
    
    // what the user actually typed in the search box.
    private string actual_search_string = "";

    private void search_field_changed (string search_field_text) {
        if (!is_current_wrapper)
            return;

        actual_search_string = search_field_text;
        var new_search = Search.get_valid_search_string (actual_search_string);
        debug ("Search changed : searchbox has '%s'", new_search);

        if (new_search.length != 1) {
            last_search = new_search;

            // Do the actual search and show up results....
            update_visible_media ();

            return;
        }
    }

    /**
     * It tells the parent class whether the search field, media control buttons, and
     * other external widgets should be sensitive or not (among other things), so that
     * the abstract parent class can take care of all these automated/repetitive tasks.
     *
     * /!\ THE DEFAULT IMPLEMENTATION IS VERY LIMITED, SO IT'S RECOMMENDED TO OVERRIDE
     *     THIS METHOD FROM THE SUBCLASS.
     *
     * OVERRIDING THE METHOD:
     *
     * In case the view contains an alert box and/or welcome screen, it is recommended
     * to set either view as current from your implementation before returning anything.
     * (Using set_active_view.)
     *
     * The child ViewWrappers are also responsible for setting the proper view back after
     * the alert/welcome screens are no longer needed (i.e. when the method would return
     * 'true'.)
     * select_proper_content_view() selects the best suited view for you in case you
     * don't want to handle that. You still need to call it from the implementation though.
     *
     * WARNING: Don't ever attempt calling the set_media(), update_media(), add_media() or
     *          remove_media() methods (including async variations) from your implementation,
     *          unless you want the method to fall into an infinite loop, potentially
     *          freezing the entire application.
     *
     * @return true if the ViewWrapper has media. false otherwise.
     */
    protected virtual bool check_have_media () {
        bool have_media = media_count > 0;

        // show alert or welcome screen if there's no media
        if (have_media)
            select_proper_content_view ();
        else if (has_welcome_screen)
            set_active_view (ViewType.WELCOME);
        else if (has_embedded_alert)
            set_active_view (ViewType.ALERT);

        return have_media;   
    }

    protected virtual void select_proper_content_view () {
        debug ("Selecting proper content view automatically");

        var new_view = (ViewType) lw.viewSelector.selected;
        debug ("%s : showing %s", hint.to_string(), new_view.to_string ());

        const int N_VIEWS = 2; // list view and album view
        if (new_view < 0 || new_view > N_VIEWS)
            new_view = ViewType.LIST;

        if (new_view == ViewType.LIST && has_list_view)
            set_active_view (ViewType.LIST);
        else if (new_view == ViewType.GRID && has_grid_view)
            set_active_view (ViewType.GRID);
    }


    /**
     *  DATA METHODS
     */

    // MEDIA DATA: These hashmaps hold information about the media shown in the views.
    protected Gee.HashMap<Media, int> media_table = new Gee.HashMap<Media, int> ();
    protected Gee.HashMap<Media, int> visible_media_table = new Gee.HashMap<Media, int> ();

    public string get_search_string () {
        return last_search;
    }

    /**
     * @return a collection containing ALL the media
     */
    public Gee.Collection<Media> get_media_list () {
        return media_table.keys;
    }

    /**
     * @return a collection containing all the media that should be shown
     */
    public Gee.Collection<Media> get_visible_media_list () {
        return visible_media_table.keys;
    }


    private Mutex updating_media_data;

    public void clear_filters () {
        /**
         * /!\ Currently setting the search to "" is enough. Remember to update it
         *     if the internal views try to restore their previous state after changes.
         */
        lw.searchField.set_text ("");
    }

    /**
     * Description:
     * Updates the data in visible_media and re-populates all the views.
     * Primarily used for searches
     */
    protected virtual void update_visible_media () {
        debug ("%s : UPDATING VISIBLE MEDIA", hint.to_string ());

        // LOCK
        updating_media_data.lock ();

        visible_media_table = new Gee.HashMap<Media, int> ();
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

        // UNLOCK
        updating_media_data.unlock ();

        set_content_views_media (search_results);

        if (is_current_wrapper) {
            update_library_window_widgets ();
            // Check whether we should show the embedded alert in case there's no media
            check_have_media ();
        }
    }


    private int compute_populate_priority () {
        int priority = 0;

        priority = (is_current_wrapper) ? Priority.HIGH_IDLE : Priority.DEFAULT_IDLE;

        // Populate playlists in order
        priority += relative_id;

        // lower priority
        if (hint == Hint.SMART_PLAYLIST || hint == Hint.PLAYLIST)
            priority += 10;

        if (priority > VIEW_CONSTRUCT_PRIORITY)
            priority = VIEW_CONSTRUCT_PRIORITY + 1;    

        return priority;
    }


    public async void set_media_async (Gee.Collection<Media> new_media) {
        Idle.add_full (compute_populate_priority (), () => {
            if (!widgets_ready)
                return true;
            set_media (new_media);
            return false;
        });
    }

    public async void add_media_async (Gee.Collection<Media> to_add) {
        Idle.add_full (compute_populate_priority (), () => {
            if (!widgets_ready)
                return true;
            add_media (to_add);
            return false;
        });
    }

    public async void remove_media_async (Gee.Collection<Media> to_remove) {
        Idle.add_full (compute_populate_priority (), () => {
            if (!widgets_ready)
                return true;
            remove_media (to_remove);
            return false;
        });
    }

    public async void update_media_async (Gee.Collection<Media> to_update) {
        Idle.add_full (compute_populate_priority (), () => {
            if (!widgets_ready)
                return true;
            update_media (to_update);
            return false;
        });
    }


    private void set_media (Gee.Collection<Media> new_media) {
        // LOCK
        updating_media_data.lock ();

        if (new_media == null) {
            warning ("set_media: attempt to set NULL media failed");
            updating_media_data.unlock ();
            return;
        }

        debug ("%s : SETTING MEDIA -> set_media", hint.to_string());

        media_table = new Gee.HashMap<Media, int> ();

        foreach (var m in new_media) {
            if (m != null) {
                media_table.set (m, 1);
            }
        }

        if (!check_have_media ()) {
            media_table = new Gee.HashMap<Media, int> ();
            visible_media_table = new Gee.HashMap<Media, int> ();
        }

        // UNLOCK
        updating_media_data.unlock ();

        update_visible_media ();
    }


    /**
     * Do search to find which ones should be added, removed from this particular view
     */
    private void update_media (Gee.Collection<Media> media) {
        if (media.size < 1)
            return;

        // LOCK
        updating_media_data.lock ();

        debug ("%s : UPDATING media", hint.to_string ());

        // find which media belong here
        Gee.LinkedList<Media> should_be, should_show;

        Search.full_search_in_media_list (media, out should_be, null, null, null, null, hint);
        Search.full_search_in_media_list (media, out should_show, null, null, null, null, hint,
                                          get_search_string ());

        var to_add_show = new Gee.LinkedList<Media> ();
        var to_remove_show = new Gee.LinkedList<Media> ();

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
                media_table.unset (m);
            }

            if (!should_show.contains (m)) {
                to_remove_show.add (m);
                visible_media_table.unset (m);
            }
        }

        add_media_to_content_views (to_add_show);
        remove_media_from_content_views (to_remove_show);

        if (!check_have_media ()) {
            media_table = new Gee.HashMap<Media, int> ();
            visible_media_table = new Gee.HashMap<Media, int> ();
            // UNLOCK
            updating_media_data.unlock ();
            update_visible_media ();
        }

        // UNLOCK
        updating_media_data.unlock ();

        if (is_current_wrapper) {
            // Update view wrapper state
            update_library_window_widgets ();
        }
    }


    private void add_media (Gee.Collection<Media> new_media) {
        if (new_media.size < 1)
            return;

        // LOCK
        updating_media_data.lock ();

        debug ("%s : ADDING media", hint.to_string());

        // find which media to add and update Media
        var to_add = new Gee.LinkedList<Media> ();

        foreach (var m in new_media) {
            if (!media_table.has_key (m)) {
                media_table.set (m, 1);
                to_add.add (m);
            }
        }

        // Do search since Showing Media depends on the search string
        Gee.LinkedList<Media> media_to_show;
        Search.search_in_media_list (to_add, out media_to_show, get_search_string ());

        // Update showing media
        foreach (var m in media_to_show) {
            if (!visible_media_table.has_key (m))
                visible_media_table.set (m, 1);
        }

        add_media_to_content_views (media_to_show);

        if (!check_have_media ()) {
            media_table = new Gee.HashMap<Media, int> ();
            visible_media_table = new Gee.HashMap<Media, int> ();
            // UNLOCK
            updating_media_data.unlock ();
            update_visible_media ();
        }

        // UNLOCK
        updating_media_data.unlock ();

        if (is_current_wrapper) {
            // Update view wrapper state
            update_library_window_widgets ();
        }

    }


    private void remove_media (Gee.Collection<Media> media) {
        if (media.size < 1)
            return;

        // LOCK
        updating_media_data.lock ();

        debug ("%s : REMOVING media", hint.to_string ());

        // find which media to remove and remove it from Media and Showing Media
        var to_remove = new Gee.LinkedList<Media>();
        foreach (var m in media) {
            media_table.unset (m);

            if (visible_media_table.has_key (m)) {
                to_remove.add (m);
                visible_media_table.unset (m);
            }
        }

        // Now update the views to reflect the changes
        remove_media_from_content_views (to_remove);

        if (!check_have_media ()) {
            media_table = new Gee.HashMap<Media, int> ();
            visible_media_table = new Gee.HashMap<Media, int> ();
            // UNLOCK
            updating_media_data.unlock ();
            update_visible_media ();
        }

        // UNLOCK
        updating_media_data.unlock ();

        if (is_current_wrapper) {
            // Update view wrapper state
            update_library_window_widgets ();
        }
    }


    /* Content view stuff */

    private void add_media_to_content_views (Gee.Collection<Media> to_add) {
        // The order matters here. Make sure we apply the action to the current view first
        if (current_view == ViewType.LIST) {
            if (has_list_view)
                list_view.add_media (to_add);
            if (has_grid_view)
                    grid_view.add_media (to_add);
        }
        else {
            if (has_grid_view)
                grid_view.add_media (to_add);
            if (has_list_view)
                list_view.add_media (to_add);
        }
    }

    private void remove_media_from_content_views (Gee.Collection<Media> to_remove) {
        if (has_list_view)
            list_view.remove_media (to_remove);
        if (has_grid_view)
            grid_view.remove_media (to_remove);
    }

    private void set_content_views_media (Gee.Collection<Media> new_media) {
        // The order matters here. Make sure we apply the action to the current view first
        if (current_view == ViewType.LIST) {
            if (has_list_view)
                list_view.set_media (new_media);
            if (has_grid_view)
                grid_view.set_media (new_media);
        }
        else {
            if (has_grid_view)
                grid_view.set_media (new_media);
            if (has_list_view)
                list_view.set_media (new_media);
        }
    }
}
