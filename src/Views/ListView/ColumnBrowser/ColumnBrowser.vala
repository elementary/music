// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012 Noise Developers (http://launchpad.net/noise)
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
 * Authored by: Scott Ringwelski <sgringwe@mtu.edu>
 *              Victor Eduardo <victoreduardm@gmail.com>
 */

public abstract class Noise.ColumnBrowser : Gtk.Grid {

    public signal void changed ();
    public signal void position_changed (Position p);

    public enum Position {
        AUTOMATIC,
        LEFT,
        TOP
    }

    private Position _position = Position.AUTOMATIC;
    public Position position {
        get {
            return _position;
        }
        protected set {
            _position = value;

            position_changed (_position);

            switch (_position) {
                case Position.AUTOMATIC:
                    automatic_menu_item.set_active (true);
                    break;
                case Position.LEFT:
                    left_menu_item.set_active (true);
                    break;
                case Position.TOP:
                    top_menu_item.set_active (true);
                    break;
                default:
                    assert_not_reached ();
            }
        }
    }

    public Position actual_position { get; set; default = Position.LEFT; }

    public ViewWrapper view_wrapper { get; private set; }

    /**
     * Whether the columns are filtered or not based on the current selection.
     * Although 'media.size == search_results.size' would produce a similar result,
     * here we want to know if the "All ..." filter is selected in every column.
     */
    public bool filtered {
        get {
            foreach (var col in columns) {
                if (!col.first_item_selected)
                    return true;
            }
            return false;
        }
    }

    public Gee.TreeSet<BrowserColumn.Category> visible_columns {
        owned get {
            var visible_columns = new Gee.TreeSet<BrowserColumn.Category> ();
            foreach (var column in columns) {
                if (column.visible)
                    visible_columns.add (column.category);
            }
            return visible_columns;
        }
        protected set {
            // Asserting value.size == 0 woudn't work since the list
            // could be full of categories that don't apply to this browser.
            bool no_column_enabled = true;

            foreach (var column in columns) {
                bool column_visible = false;

                foreach (var category in value) {
                    if (column.category == category) {
                        column_visible = true;
                        break;
                    }
                }

                column.visible = column_visible;

                if (column_visible)
                    no_column_enabled = false;
            }

            // In case no column is visible 
            if (no_column_enabled) {
                var col = columns.first ();
                if (col != null)
                    col.visible = true;
            }
        }
    }

    public bool initialized { get { return media == null || search_results == null; } }

    public Gee.TreeSet<BrowserColumn> columns { get; private set; }

    // All the media. We search within this media collection
    private Gee.LinkedList<Media> media = new Gee.LinkedList<Media> ();

    // Filtered media results (media that matches the current set of filters).
    // We provide the data. No need to search again outside
    private Gee.Collection<Media> search_results = new Gee.LinkedList<Media> ();

    private Gtk.Menu column_chooser_menu;
    private Gtk.RadioMenuItem top_menu_item;
    private Gtk.RadioMenuItem left_menu_item;
    private Gtk.RadioMenuItem automatic_menu_item;

    public ColumnBrowser (ViewWrapper view_wrapper, BrowserColumn.Category[] categories) {
        this.orientation = Gtk.Orientation.HORIZONTAL;
        this.view_wrapper = view_wrapper;
        columns = new Gee.TreeSet<BrowserColumn> ();
        column_chooser_menu = new Gtk.Menu ();

        // Inserting columns
        foreach (var category in categories) {
            add_column (category);
        }

        create_column_selector_menu ();
    }

    private void create_column_selector_menu () {
        automatic_menu_item =
            new Gtk.RadioMenuItem.with_label (new SList<Gtk.RadioMenuItem> (), _("Automatic"));
        left_menu_item =
            new Gtk.RadioMenuItem.with_label (automatic_menu_item.get_group (), _("On Left"));
        top_menu_item =
            new Gtk.RadioMenuItem.with_label (left_menu_item.get_group (), _("On Top"));

        automatic_menu_item.toggled.connect ( () => {
            if (automatic_menu_item.active)
                position = Position.AUTOMATIC;
        });

        left_menu_item.toggled.connect ( () => {
            if (left_menu_item.active)
                position = Position.LEFT;
        });

        top_menu_item.toggled.connect ( () => {
            if (top_menu_item.active)
                position = Position.TOP;
        });

        column_chooser_menu.append (new Gtk.SeparatorMenuItem ());
        column_chooser_menu.append (automatic_menu_item);
        column_chooser_menu.append (top_menu_item);
        column_chooser_menu.append (left_menu_item);
        column_chooser_menu.show_all ();

        position = Position.AUTOMATIC;
    }

    public void reset_filters () {
        foreach (var col in columns)
            col.select_first_item ();
    }

    protected BrowserColumn add_column (BrowserColumn.Category type) {
        // Setup column and connect signals
        var column = new BrowserColumn (this, type);

        column.selection_changed.connect_after (column_selection_changed);

        // Set minimum size
        column.set_size_request (60, 100);

        column.reset_requested.connect ( () => {
            column.select_first_item ();
        });

        columns.add (column);

        column.hexpand = column.vexpand = true;
        attach (column, (int)type, 0, 1, 1);

        column_chooser_menu.append (column.menu_item);

        column.row_activated.connect (column_row_activated);
        column.header_clicked.connect (column_header_clicked);
        column.visibility_changed.connect (update_column_separators);

        return column;
    }

    public void set_media (Gee.Collection<Media> media) {
        this.media.clear ();
        this.media.add_all (media);
        //reset_filters ();
        search_results.clear ();
        search_results.add_all (media); // equivalent to resetting filters without losing column selections
        
        var highest_category = BrowserColumn.Category.first ();
        //update_search_results (highest_category);
        populate_columns (highest_category, true);
        
        changed ();
    }

    private void column_row_activated () {
        view_wrapper.play_first_media ();
    }

    private void column_selection_changed (BrowserColumn.Category category, string val) {
        update_search_results (category);
        view_wrapper.list_view.list_view.research_needed = true;
        populate_columns (category, false);
        changed ();
    }

    private void update_search_results (BrowserColumn.Category parent_category) {
        int rating, year;
        string genre, album_artist, album, grouping, composer;
        get_filters (parent_category, out rating, out year, out genre, out album_artist, out album,
                     out grouping, out composer);

        // Perform search
        Search.search_in_media_list (media, out search_results, album_artist, album,
                                     genre, grouping, composer, year, rating, null);
    }

    private void get_filters (BrowserColumn.Category parent_category,
                              out int rating,
                              out int year,
                              out string genre,
                              out string album_artist,
                              out string album,
                              out string grouping,
                              out string composer)
    {
        rating = -1; // ~ All
        year   = -1; // ~ All
        genre  = ""; // ~ All
        album_artist  = ""; // ~ All
        album = ""; // ~ All
        grouping = ""; // ~ All
        composer = ""; // ~ All

        foreach (var col in columns) {
            // Higher hierarchical levels (parent columns)
            if (col.category <= parent_category) {
                var selected = col.get_selected ();

                switch (col.category) {
                    case BrowserColumn.Category.GENRE:
                        genre = selected;
                    break;

                    case BrowserColumn.Category.ARTIST:
                        album_artist = selected;
                    break;

                    case BrowserColumn.Category.ALBUM:
                        album = selected;
                    break;

                    case BrowserColumn.Category.GROUPING:
                        grouping = selected;
                    break;

                    case BrowserColumn.Category.COMPOSER:
                        composer = selected;
                    break;

                    case BrowserColumn.Category.YEAR:
                        // the year column contains only numbers, or "" in case the first
                        // item is selected, so its parsing will be OK all the time.
                        year = String.is_empty (selected, false) ? -1 : (int) Numeric.uint_from_string (selected);
                    break;

                    case BrowserColumn.Category.RATING:
                        // We have to be careful here. selected can contain values such as:
                        // ""  (i.e. ALL)
                        // "1 star"
                        // "2 stars"
                        // ...
                        // "Unrated"
                        //
                        // For "1 star" and "2 stars", uint_from_string() has absolutely no problem extracting
                        // their values. This is also true for unrated, because uint_from_string() returns 0
                        // (i.e. unrated) when no digit is found in a string.
                        //
                        // Please note that these strings are usually localized.
                        // Avoid changing uint_from_string()'s behavior at all cost.
                        rating = String.is_empty (selected, false) ? -1 : (int) Numeric.uint_from_string (selected);
                    break;
                    
                    default:
                        assert_not_reached ();
                }
            }
        }
    }

    private void populate_columns (BrowserColumn.Category category, bool inclusive) {
        // Now re-populate the child columns
        foreach (var column in columns) {
            // Don't consider parent columns
            if (column.category < category)
                continue;

            if (column.category == category && !inclusive)
                continue;

            fill_column (column);
        }
    }

    public void fill_column (BrowserColumn column) {
        var column_set = new Gee.HashSet<string> ();

        switch (column.category) {
            case BrowserColumn.Category.GENRE:
                foreach (var m in search_results) {
                    string genre = m.get_display_genre ();
                    if (!column_set.contains (genre))
                        column_set.add (genre);
                }
            break;

            case BrowserColumn.Category.ARTIST:
                foreach (var m in search_results) {
                    string artist = m.get_display_album_artist ();
                    if (!column_set.contains (artist))
                        column_set.add (artist);
                }
            break;

            case BrowserColumn.Category.GROUPING:
                foreach (var m in search_results) {
                    string grouping = m.grouping;
                    
                    // TODO XXX If grouping is an empty string, append "Ungrouped" instead
                    if (!String.is_empty (grouping, false) && !column_set.contains (grouping))
                        column_set.add (grouping);
                }
            break;

            case BrowserColumn.Category.COMPOSER:
                foreach (var m in search_results) {
                    string composer = m.get_display_composer ();
                    if (!column_set.contains (composer))
                        column_set.add (composer);
                }
            break;

            case BrowserColumn.Category.ALBUM:
                foreach (var m in search_results) {
                    string album = m.get_display_album ();
                    if (!column_set.contains (album))
                        column_set.add (album);
                }
            break;

            case BrowserColumn.Category.YEAR:
                // filter duplicate years
                var numeric_set = new Gee.HashSet<uint> ();
                foreach (var m in search_results) {
                    uint year = m.year;
                    if (year > 0 && !numeric_set.contains (year)) { // Don't add 0
                        numeric_set.add (year);
                        column_set.add (year.to_string ());
                    }
                }
            break;

            case BrowserColumn.Category.RATING:
                // filter duplicate years
                var numeric_set = new Gee.HashSet<uint> ();
                foreach (var m in search_results) {
                    uint rating = m.rating;
                    if (!numeric_set.contains (rating)) { // Don't add 0
                        numeric_set.add (rating);

                        string rating_str;
                        if (rating < 1)
                            rating_str = _("Unrated");
                        else
                            rating_str = ngettext ("%i Star", "%i Stars", rating).printf (rating);

                        column_set.add (rating_str);
                    }
                }
            break;

            default:
                assert_not_reached ();
        }

        column.populate (column_set);

        // Update search results so that the next column is populated taking this column's
        // (new) selected item into account (new value of column.get_selected)
        //
        // Be careful though, as this only works if columns are being populated hierarchically;
        // that is, starting at the higher-level column (0 : RATING).
        update_search_results (column.category);
    }

    public bool match_media (Media m) {
#if 0
        // No need to search again. Querying the hash set is efficient too
        return search_results.contains (m);
#else
        // Slightly slower than the code above, but more reliable.
        int rating, year;
        string genre, album_artist, album, grouping, composer;
        get_filters (BrowserColumn.Category.last (), out rating, out year, out genre,
                     out album_artist, out album, out grouping, out composer);

        // Perform search
        return Search.match_fields_to_media (m, album_artist, album, genre, grouping, composer, year, rating);
#endif
    }

    private void update_column_separators () {
        uint n_visible_columns = this.visible_columns.size;

        // Get the last (i.e. right-most) visible column
        var first_col = BrowserColumn.Category.first ();
        foreach (var col in visible_columns) {
            if (col > first_col)
                first_col = col;
        }

        foreach (var col in columns)
            col.show_separator = (col.category != first_col) && (n_visible_columns > 1);
    }

    private void column_header_clicked (Gdk.EventButton e) {
        if (e.button == Gdk.BUTTON_SECONDARY) { // secondary button
            this.column_chooser_menu.popup (null, null, null, 3, Gtk.get_current_event_time ());
        }
    }
}
