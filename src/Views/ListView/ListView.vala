// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012-2018 elementary LLC. (https://elementary.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
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
public class Noise.ListView : Gtk.Box, ViewInterface {
    public signal void reordered ();

    // Wrapper for the list view and miller columns
    private Gtk.Paned browser_hpane; // for left mode
    private Gtk.Paned browser_vpane; // for top mode

    public ColumnBrowser column_browser { get; construct set; }
    public MusicListView list_view { get; construct set; }

    private int browser_hpane_position = -1;
    private int browser_vpane_position = -1;

    public ViewWrapper view_wrapper { get; construct set; }

    private bool obey_column_browser = false;

    public uint n_media {
        get { return list_view.get_table ().size; }
    }

    // UI Properties

    public bool has_column_browser { get { return column_browser != null; } }

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

    public ListView (ViewWrapper view_wrapper, TreeViewSetup tvs, bool add_browser = false) {
        Object (view_wrapper: view_wrapper,
                list_view: new MusicListView (view_wrapper, tvs),
                column_browser: add_browser ? new MusicColumnBrowser (view_wrapper) : null);
    }

    construct {
        var list_scrolled = new Gtk.ScrolledWindow (null, null);
        list_scrolled.add (list_view);
        list_scrolled.expand = true;

        list_view.rows_reordered.connect (() => {
            reordered ();
        });

        list_view.import_requested.connect ((to_import) => {
            import_requested (to_import);
        });

        list_view.set_search_func (view_search_func);
        view_wrapper.library.search_finished.connect (() => { list_view.research_needed = true; });

        if (has_column_browser) {
            browser_vpane = new Gtk.Paned (Gtk.Orientation.VERTICAL);
            browser_vpane.pack2 (list_scrolled, true, false);

            browser_hpane = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
            browser_hpane.expand = true;
            browser_hpane.pack1 (column_browser, false, false);
            browser_hpane.pack2 (browser_vpane, true, false);

            add (browser_hpane);

            set_column_browser_position (column_browser.position);

            // Connect signals once the widget has been realized to avoid writing to settings
            // on startup
            realize.connect (connect_column_browser_ui_signals);

            column_browser_enabled = App.saved_state.get_boolean ("column-browser-enabled");

            // Connect data signals
            column_browser.changed.connect (column_browser_changed);
        } else {
            add (list_scrolled);
        }
    }

    private void set_column_browser_position (ColumnBrowser.Position position) {
        if (!has_column_browser)
            return;

        ColumnBrowser.Position actual_position = position; //position that will be actually applied

        if (actual_position == ColumnBrowser.Position.AUTOMATIC) {
            // Decide what orientation to use based on the view area size

            int view_width = get_allocated_width ();
            const int MIN_RECOMMENDED_COLUMN_WIDTH = 160;

            int visible_columns = 0;
            foreach (var column in column_browser.columns) {
                if (column.visible) {
                    ++ visible_columns;
                }
            }


            // Checks width and number of visible columns
            int required_width = MIN_RECOMMENDED_COLUMN_WIDTH * visible_columns;
            int n_cols = 0;
            foreach (var column in list_view.get_columns ()) {
                if (column.visible) {
                    n_cols ++;
                }
            }

            if (view_width - required_width < list_view.get_allocated_width () && n_cols > 2 && visible_columns > 2) {
                actual_position = ColumnBrowser.Position.TOP;
            } else {
                actual_position = ColumnBrowser.Position.LEFT;
            }
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
        if (!has_column_browser) {
            return;
        }

        // For automatic position stuff
        size_allocate.connect (() => {
            if (!App.main_window.initialization_finished) {
                return;
            }

            if (column_browser.position == ColumnBrowser.Position.AUTOMATIC) {
                set_column_browser_position (ColumnBrowser.Position.AUTOMATIC);
            }
        });

        column_browser.size_allocate.connect (() => {
            if (!App.main_window.initialization_finished || !column_browser_enabled) {
                return;
            }

            if (column_browser.actual_position == ColumnBrowser.Position.LEFT) {
                if (browser_hpane.position > 0) {
                    browser_hpane_position = browser_hpane.position;
                }
            } else if (column_browser.actual_position == ColumnBrowser.Position.TOP) {
                if (browser_vpane.position > 0) {
                    browser_vpane_position = browser_vpane.position;
                }
            }
        });

        App.main_window.view_selector.column_browser_toggled.connect ((enabled) => {
            if (enabled != column_browser_enabled) {
                column_browser_enabled = enabled;
            }
        });

        column_browser.position_changed.connect (set_column_browser_position);

        // Read Paned position from settings
        browser_hpane_position = App.saved_state.get_int ("column-browser-width");
        browser_vpane_position = App.saved_state.get_int ("column-browser-height");

        browser_hpane.position = browser_hpane_position;
        browser_vpane.position = browser_vpane_position;

        // We only save the settings when this view wrapper is being destroyed. This avoids unnecessary
        // disk access to write settings.
        destroy.connect (save_column_browser_settings);
    }

    private void save_column_browser_settings () {
        // Need to add a proper fix later ... Something similar to TreeViewSetup
        if (has_column_browser) {
            if (column_browser.visible) {
                if (column_browser.actual_position == ColumnBrowser.Position.LEFT) {
                    App.saved_state.set_int ("column-browser-width", browser_hpane_position);
                } else if (column_browser.actual_position == ColumnBrowser.Position.TOP) {
                    App.saved_state.set_int ("column-browser-height", browser_vpane_position);
                }
            }
            App.saved_state.set_boolean ("column-browser-enabled", column_browser_enabled);
        }
    }

    /**
     * ContentView interface methods
     */

    public ViewWrapper.Hint get_hint () {
        return list_view.hint;
    }

    public Playlist get_playlist () {
        return list_view.playlist;
    }

    public Gee.Collection<Media> get_media () {
        var media = new Gee.ArrayList<Media> ();
        media.add_all (list_view.get_table ());
        return media;
    }

    public Gee.Collection<Media> get_visible_media () {
        var media = new Gee.ArrayList<Media> ();
        media.add_all (list_view.get_visible_table ());
        return media;
    }

    private void column_browser_changed () {
        if (App.main_window.initialization_finished) {
            // This is supposed to take the browser's filter into account because obey_column_browser is #false
            list_view.do_search (null);
        }
    }

    public void set_as_current_list (int media_id) {
        list_view.set_as_current_list (view_wrapper.library.media_from_id (media_id));
    }

    public bool get_is_current_list () {
        return list_view.get_is_current_list ();
    }

    public void add_media (Gee.Collection<Media> to_add) {
        list_view.add_media (to_add);
        list_view.research_needed = true;
        refilter ();
    }

    public void remove_media (Gee.Collection<Media> to_remove) {
        list_view.remove_media (to_remove);
        list_view.research_needed = true;
        refilter ();
    }

    public void set_media (Gee.Collection<Media> media) {
        obey_column_browser = false;

        list_view.set_media (media);
        list_view.research_needed = true;

        if (has_column_browser) {
            column_browser.set_media (media);
        }

        obey_column_browser = true;
    }

    public void update_media (Gee.Collection<Media> media) {
        refilter ();
    }

    public void refilter () {
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
        list_view.do_search ();
        obey_column_browser = true;

        if (has_column_browser)
            column_browser.set_media (view_wrapper.library.get_search_result ());
    }

    private void view_search_func (string search, Gee.ArrayList<Media> table, Gee.ArrayList<Media> showing) {
        var result = view_wrapper.library.get_search_result ();

        // If an external refiltering is going on, we cannot obey the column browser filter
        // because it wil be refreshed after this search based on the new 'showing' table
        // (populated by this method).
        bool obey_column_browser = column_browser_enabled && this.obey_column_browser;

        if (result.size != view_wrapper.library.get_medias ().size) {
            foreach (var m in table) {
                if (obey_column_browser && !column_browser.match_media (m)) {
                    continue;
                }

                if (m in result) {
                    showing.add (m);
                }
            }
        } else {
            foreach (var m in result) {
                if (obey_column_browser && !column_browser.match_media (m)) {
                    continue;
                }

                showing.add (m);
            }
        }

        // If nothing will be shown, display the "no media found" message.
        if (showing.size < 1 && search != "") {
            App.main_window.view_stack.show_alert ();
        }
    }
}
