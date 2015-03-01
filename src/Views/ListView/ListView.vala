// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012- Noise Developers (http://launchpad.net/noise)
 *
 * This software is licensed under the GNU General Public License
 * (version 2 or later). See the COPYING file in this distribution.
 *
 * The Noise authors hereby grant permission for non-GPL compatible
 * GStreamer plugins to be used and distributed together with GStreamer
 * and Noise. This permission is above and beyond the permissions granted
 * by the GPL license by which Noise is covered. If you modify this code
 * you may extend this exception to your version of the code, but you are not
 * obligated to do so. If you do not wish to do so, delete this exception
 * statement from your version.
 *
 * Authored by: Victor Eduardo <victoreduardm@gmail.com>
 */

/**
 * Contains the column browser and list view.
 */
public class Noise.ListView : ContentView, Gtk.Box {

    public signal void reordered ();

    // Wrapper for the list view and miller columns
    private Gtk.Paned browser_hpane; // for left mode
    private Gtk.Paned browser_vpane; // for top mode

    public ColumnBrowser column_browser { get; private set; }
    public MusicListView   list_view    { get; private set; }

    private int browser_hpane_position = -1;
    private int browser_vpane_position = -1;

    private ViewWrapper view_wrapper;
    private ViewTextOverlay list_text_overlay;

    private bool obey_column_browser = false;

    public uint n_media {
        get { return list_view.get_table ().size; }
    }

    // UI Properties

    public bool has_column_browser  { get { return column_browser != null; } }

    public bool column_browser_enabled {
        get {
            return has_column_browser && !column_browser.no_show_all;
        }
        private set {
            if (has_column_browser) {
                column_browser.set_no_show_all (!value);
                if (value) {
                    // Populate column browser
                    column_browser.show_all ();

                    if (!column_browser.initialized)
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

    public ListView (ViewWrapper view_wrapper, TreeViewSetup tvs, bool add_browser = false, bool? is_queue = false, bool? read_only = false) {
        this.view_wrapper = view_wrapper;

        list_view = new MusicListView (view_wrapper, tvs, is_queue, read_only);

        var list_scrolled = new Gtk.ScrolledWindow (null, null);
        list_scrolled.set_policy (Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
        list_scrolled.add (list_view);
        list_scrolled.expand = true;

        list_text_overlay = new ViewTextOverlay ();
        list_text_overlay.add (list_scrolled);
        list_text_overlay.message = String.escape (_("No Songs Found."));

        list_view.rows_reordered.connect (() => {
            reordered ();
        });

        list_view.import_requested.connect ((to_import) => {
            import_requested (to_import);
        });

        if (add_browser)
            column_browser = new MusicColumnBrowser (view_wrapper);

        list_view.set_search_func (view_search_func);
        view_wrapper.library.search_finished.connect (() => {this.list_view.research_needed = true;});

        if (has_column_browser) {
            browser_hpane = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
            browser_vpane = new Gtk.Paned (Gtk.Orientation.VERTICAL);

            // Fix theming
            browser_vpane.get_style_context ().add_class (Gtk.STYLE_CLASS_VERTICAL);

            browser_hpane.pack2 (browser_vpane, true, false);

            // Add hpaned (the most-external wrapper) to the view container
            browser_hpane.expand = true;
            this.add (browser_hpane);

            // Now pack the list view
            browser_vpane.pack2 (list_text_overlay, true, false);
            browser_hpane.pack1 (column_browser, false, false);

            set_column_browser_position (column_browser.position);

            // Connect signals once the widget has been realized to avoid writing to settings
            // on startup
            this.realize.connect (connect_column_browser_ui_signals);

            column_browser_enabled = Settings.SavedState.get_default ().column_browser_enabled;

            // Connect data signals
            column_browser.changed.connect (column_browser_changed);
        }
        else {
            this.add (list_text_overlay);
        }
    }

    private void set_column_browser_position (ColumnBrowser.Position position) {
        if (!has_column_browser)
            return;

        ColumnBrowser.Position actual_position = position; //position that will be actually applied

        if (actual_position == ColumnBrowser.Position.AUTOMATIC) {
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
                actual_position = ColumnBrowser.Position.TOP;
            else
                actual_position = ColumnBrowser.Position.LEFT;
        }

        column_browser.actual_position = actual_position;

        if (actual_position == ColumnBrowser.Position.LEFT) {
            if (browser_hpane.get_child1 () == null && browser_vpane.get_child1 () == column_browser) {
                browser_vpane.remove (column_browser);
                browser_hpane.pack1 (column_browser, false, false);

                browser_hpane.position = browser_hpane_position;
            }
        } else if (actual_position == ColumnBrowser.Position.TOP) {
            if (browser_vpane.get_child1 () == null && browser_hpane.get_child1 () == column_browser) {
                browser_hpane.remove (column_browser);
                browser_vpane.pack1 (column_browser, false, false);

                browser_vpane.set_position (browser_vpane_position);
            }
        }
    }

    private void connect_column_browser_ui_signals () {
        if (!has_column_browser)
            return;

        // For automatic position stuff
        this.size_allocate.connect (() => {
            if (!App.main_window.initialization_finished)
                return;

            if (column_browser.position == ColumnBrowser.Position.AUTOMATIC)
                set_column_browser_position (ColumnBrowser.Position.AUTOMATIC);
        });

        column_browser.size_allocate.connect (() => {
            if (!App.main_window.initialization_finished || !column_browser_enabled)
                return;

            if (column_browser.actual_position == ColumnBrowser.Position.LEFT) {
                if (browser_hpane.position > 0)
                    browser_hpane_position = browser_hpane.position;
            } else if (column_browser.actual_position == ColumnBrowser.Position.TOP) {
                if (browser_vpane.position > 0)
                    browser_vpane_position = browser_vpane.position;
            }
        });

        App.main_window.viewSelector.column_browser_toggled.connect (  (enabled) => {
            if (enabled != column_browser_enabled)
                column_browser_enabled = enabled;
        });

        column_browser.position_changed.connect (set_column_browser_position);

        // Read Paned position from settings
        var saved_state = Settings.SavedState.get_default ();
        browser_hpane_position = saved_state.column_browser_width;
        browser_vpane_position = saved_state.column_browser_height;

        browser_hpane.position = browser_hpane_position;
        browser_vpane.position = browser_vpane_position;

        // We only save the settings when this view wrapper is being destroyed. This avoids unnecessary
        // disk access to write settings.
        destroy.connect (save_column_browser_settings);
    }

    private void save_column_browser_settings () {
        // Need to add a proper fix later ... Something similar to TreeViewSetup
        if (has_column_browser) {
            var saved_state = Settings.SavedState.get_default ();
            if (column_browser.visible) {
                if (column_browser.actual_position == ColumnBrowser.Position.LEFT)
                    saved_state.column_browser_width = browser_hpane_position;
                else if (column_browser.actual_position == ColumnBrowser.Position.TOP)
                    saved_state.column_browser_height = browser_vpane_position;
            }

            saved_state.column_browser_enabled = column_browser_enabled;
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
        var media_list = new Gee.ArrayQueue<Media> ();
        media_list.add_all (list_view.get_table ().values);
        return media_list;
    }

    public Gee.Collection<Media> get_visible_media () {
        var media_list = new Gee.ArrayQueue<Media> ();
        media_list.add_all (list_view.get_visible_table ().values);
        return media_list;
    }

    private void column_browser_changed () {
        if (App.main_window.initialization_finished) {
            // This is supposed to take the browser's filter into account because obey_column_browser is #false
            list_view.do_search (null);
            view_wrapper.update_statusbar_info ();
        }
    }

    // TODO: Since is_initial is deprecated and not used, update the external code to stop using it
    public void set_as_current_list (int media_id, bool is_initial = false) {
        list_view.set_as_current_list (view_wrapper.library.media_from_id (media_id));
    }

    public bool get_is_current_list ()  {
        return list_view.get_is_current_list ();
    }

    public void add_media (Gee.Collection<Media> to_add) {
        list_view.add_media (to_add);
        this.list_view.research_needed = true;
        refilter (null);
    }

    public void remove_media (Gee.Collection<Media> to_remove) {
        list_view.remove_media (to_remove);
        this.list_view.research_needed = true;
        refilter (null);
    }

    public void set_media (Gee.Collection<Media> media) {
        obey_column_browser = false;

        list_view.set_media (media);
        this.list_view.research_needed = true;

        if (has_column_browser)
            column_browser.set_media (media);

        obey_column_browser = true;
    }

    public void update_media (Gee.Collection<Media> media) {
        refilter (null);
    }

    public void refilter (string? search) {
        // We set 'obey_column_browser' to 'false' because otherwise refilter () would
        // filter the visible media based on the browser's current filter, and then re-populate
        // the browser using that same media. We don't want that to happen, because it would
        // make the browser filter its own media!
        // Basically, what 'obey_column_browser = false' does is forcing the view to traverse
        // the entire item table again to decide what elements are visible without taking into
        // account the column browser filter - just the search string.
        //
        // We can safely do this because the browser is smart enough to keep its current
        // selection/filter as long as the new media contains properties matching the criteria.
        obey_column_browser = false;
        list_view.do_search (search);
        obey_column_browser = true;

        if (has_column_browser)
            column_browser.set_media (view_wrapper.library.get_search_result ());
    }

    public string get_statusbar_text () {
        var all_visible_media = get_visible_media ();

        bool is_cd = view_wrapper.hint == ViewWrapper.Hint.CDROM;
        uint total_items = 0;
        uint64 total_size = 0, total_time = 0;

        foreach (var media in all_visible_media) {
            if (media != null) {
                total_items ++;
                total_time += media.length;
                total_size += media.file_size;
            }
        }

        if (total_items < 1)
            return "";

        string media_description;

        if (is_cd)
            media_description = ngettext ("%i track", "%i tracks", total_items).printf ((int) total_items);
        else
            media_description = ngettext ("%u song", "%u songs", total_items).printf (total_items);

        string time_text = TimeUtils.time_string_from_miliseconds (total_time);

        string status_text;

        // ignore file size field for audio CDs
        if (is_cd) {
            var statusbar_format = C_("Format used on statusbar: $description, $total_duration", "%s, %s");
            status_text = statusbar_format.printf (media_description, time_text);
        } else {
            string size_text = format_size (total_size);
            var statusbar_format = _(FULL_STATUSBAR_FORMAT);
            status_text = statusbar_format.printf (media_description, time_text, size_text);
        }

        return status_text;
    }

    private void view_search_func (string search, Gee.HashMap<int, Media> table, Gee.HashMap<int, Media> showing) {
        list_text_overlay.message_visible = false;
        var result = view_wrapper.library.get_search_result ();

        // If an external refiltering is going on, we cannot obey the column browser filter
        // because it wil be refreshed after this search based on the new 'showing' table
        // (populated by this method).
        bool obey_column_browser = column_browser_enabled && this.obey_column_browser;
        int show_index = 0;
        
        if (result.size != view_wrapper.library.get_medias ().size) {
            /* 
             * Please don't change back to a foreach implementation
             * until you fully understand the proper behavior
             * since this change produces the bug 1346678
             * Leave this "for loop" for now.                   */
            foreach (var m in table) {
                if (obey_column_browser && !column_browser.match_media (m))
                    continue;

                if (result.contains (m)) {
                    showing.set (show_index++, m);
                }
            }
        } else {
            /* 
             * Please don't change back to a foreach implementation
             * until you fully understand the proper behavior
             * since this change produces the bug 1346678
             * Leave this "for loop" for now.                   */
            foreach (var m in table) {
                if (obey_column_browser && !column_browser.match_media (m))
                    continue;

                showing.set (show_index++, m);
            }
        }

        // If nothing will be shown, display the "no media found" message.
        if (showing.size < 1) {
            list_text_overlay.message_visible = true;
        }
    }
}
