/*-
 * Copyright (c) 2011-2012 Noise Developers
 *
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

namespace Noise {
    public enum BrowserPosition {
        AUTOMATIC,
        LEFT,
        TOP
    }

    public enum WindowState {
        NORMAL,
        MAXIMIZED,
        FULLSCREEN
    }
}

public abstract class Noise.ColumnBrowser : Gtk.Grid {

	public signal void changed ();
	public signal void position_changed (Noise.BrowserPosition p);

    Gtk.RadioMenuItem top_menu_item;
    Gtk.RadioMenuItem left_menu_item;
    Gtk.RadioMenuItem automatic_menu_item;

    Noise.BrowserPosition _position = Noise.BrowserPosition.AUTOMATIC;
	public Noise.BrowserPosition position {
	    get {
            return _position;
	    }
        protected set {
            _position = value;

            position_changed (_position);

		    switch (_position) {
			    case Noise.BrowserPosition.AUTOMATIC:
				    automatic_menu_item.set_active (true);
				    break;
			    case Noise.BrowserPosition.LEFT:
				    left_menu_item.set_active (true);
				    break;
			    case Noise.BrowserPosition.TOP:
				    top_menu_item.set_active (true);
				    break;
		    }
        }
	}

	public Noise.BrowserPosition actual_position { get; set; default = Noise.BrowserPosition.LEFT; }

	public LibraryManager lm { get; private set; }
	public LibraryWindow  lw { get; private set; }
	public ViewWrapper view_wrapper { get; private set; }

	/**
	 * Whether the columns are filtered or not based on the current selection.
	 * Although 'media.size == _media_results.size' would produce a similar result,
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

    public List<BrowserColumn.Category> visible_columns {
        owned get {
            var visible_columns = new List<BrowserColumn.Category> ();
            foreach (var column in columns) {
                if (column.visible)
                    visible_columns.append (column.category);
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
                var col = columns.get (0);
                if (col != null)
                    col.visible = true;
            }
        }
    }


	// All the media
	protected Gee.Collection<Media> media = new Gee.LinkedList<Media> ();

	// Filtered media results. We provide the data. No need to search again outside
	protected Gee.Collection<Media> _media_results;
	public Gee.Collection<Media> media_results { get { return _media_results; } }

	public Gee.LinkedList<unowned BrowserColumn> columns { get; construct set; }
	protected Gtk.Menu column_chooser_menu;

	public ColumnBrowser (ViewWrapper view_wrapper, BrowserColumn.Category[] categories) {
		this.orientation = Gtk.Orientation.HORIZONTAL;

		this.lm = view_wrapper.lm;
		this.lw = view_wrapper.lw;
		this.view_wrapper = view_wrapper;

		columns = new Gee.LinkedList<unowned BrowserColumn> ();

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
    			position = Noise.BrowserPosition.AUTOMATIC;
		});

	    left_menu_item.toggled.connect ( () => {
			if (left_menu_item.active)
    			position = Noise.BrowserPosition.LEFT;
		});

		top_menu_item.toggled.connect ( () => {
			if (top_menu_item.active)
    			position = Noise.BrowserPosition.TOP;
		});

		column_chooser_menu.append (new Gtk.SeparatorMenuItem ());
		column_chooser_menu.append (automatic_menu_item);
		column_chooser_menu.append (top_menu_item);
		column_chooser_menu.append (left_menu_item);
		column_chooser_menu.show_all ();

        position = Noise.BrowserPosition.AUTOMATIC;
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

	public void set_media (Gee.Collection<Media> media, Cancellable? cancellable) {
        if (Utils.is_cancelled (cancellable))
            return;

		this.media = media;
        reset_filters ();
        update_search_results (BrowserColumn.Category.RATING, cancellable);
        populate_columns (BrowserColumn.Category.RATING, true, cancellable);
	}

	private void column_row_activated () {
		view_wrapper.play_first_media ();
	}

	private void column_selection_changed (BrowserColumn.Category category, string val) {
        update_search_results (category, null);
		populate_columns (category, false, null);
		changed ();
	}

    private void update_search_results (BrowserColumn.Category parent_category, Cancellable? cancellable) {
        if (Utils.is_cancelled (cancellable))
            return;

		if (filtered) {
			var search_rating = -1; // ~ All
			var search_year   = -1; // ~ All
			var search_genre  = ""; // ~ All
			var search_artist = ""; // ~ All
			var search_album  = ""; // ~ All

			foreach (var col in columns) {
                if (Utils.is_cancelled (cancellable))
                    break;

				// Higher hierarchical levels (parent columns)
				if (col.category <= parent_category) {
					if (col.category == BrowserColumn.Category.GENRE) {
						search_genre = col.get_selected ();
					}
					else if (col.category == BrowserColumn.Category.ARTIST) {
						search_artist = col.get_selected ();
					}
					else if (col.category == BrowserColumn.Category.ALBUM) {
						search_album = col.get_selected ();
					}
					else if (col.category == BrowserColumn.Category.YEAR) {
						search_year = (col.get_selected () == "") ? -1 : int.parse (col.get_selected ());
					}
					else if (col.category == BrowserColumn.Category.RATING) {
						search_rating = (col.get_selected () == "") ? -1 : int.parse (col.get_selected ());
					}
				}
			}

			// Perform search
			Search.search_in_media_list (media, out _media_results, search_artist, search_album,
			                             search_genre, search_year, search_rating, cancellable);
		}
		else {
			_media_results = media;
		}
    }

    private void populate_columns (BrowserColumn.Category category, bool inclusive, Cancellable? cancellable) {
        if (Utils.is_cancelled (cancellable))
            return;

		// Now re-populate the child columns
		foreach (var column in columns) {
            if (Utils.is_cancelled (cancellable))
                break;

            // Don't consider parent columns
			if (column.category < category)
			    continue;

            if (column.category == category && !inclusive)
                continue;

			var column_set = new Gee.HashSet<string> ();

            switch (column.category) {
                case BrowserColumn.Category.GENRE:
				    foreach (var m in _media_results) {
                        if (Utils.is_cancelled (cancellable))
                            break;

                        string genre = m.get_display_genre ();
                        if (!column_set.contains (genre))
					        column_set.add (genre);
				    }
			    break;

			    case BrowserColumn.Category.ARTIST:
				    foreach (var m in _media_results) {
                        if (Utils.is_cancelled (cancellable))
                            break;

                        string artist = m.get_display_album_artist ();
                        if (!column_set.contains (artist))
					        column_set.add (artist);
				    }
                break;

			    case BrowserColumn.Category.ALBUM:
				    foreach (var m in _media_results) {
                        if (Utils.is_cancelled (cancellable))
                            break;

                        string album = m.get_display_album ();
                        if (!column_set.contains (album))
					        column_set.add (album);
				    }
			    break;

			    case BrowserColumn.Category.YEAR:
				    foreach (var m in _media_results) {
                        if (Utils.is_cancelled (cancellable))
                            break;

                        string year = m.year.to_string ();
                        if (!column_set.contains (year))
					        column_set.add (year);
				    }
			    break;

			    case BrowserColumn.Category.RATING:
				    foreach (var m in _media_results) {
                        if (Utils.is_cancelled (cancellable))
                            break;

                        string rating = m.rating.to_string ();
                        if (!column_set.contains (rating))
					        column_set.add (rating);
				    }
			    break;

                default:
                    assert_not_reached ();
            }

            if (!Utils.is_cancelled (cancellable))
				column.populate (column_set, cancellable);
		}
    }

	private void update_column_separators () {
        uint n_visible_columns = this.visible_columns.length ();

        // Get the last (i.e. right-most) visible column
        BrowserColumn.Category last_col = BrowserColumn.Category.RATING;
        foreach (var col in visible_columns) {
            if (col > last_col)
                last_col = col;
        }

		foreach (var col in columns) {
			// Every column has 0px on the left. The space is always added on the right side.
			col.margin_left = 0;

			// adding right space (separator line)
			col.margin_right = (col.category == last_col || n_visible_columns == 1) ? 0 : 1;
		}
	}

	private void column_header_clicked (Gdk.EventButton e) {
		if (e.button == Gdk.BUTTON_SECONDARY) { // secondary button
			this.column_chooser_menu.popup (null, null, null, 3, Gtk.get_current_event_time ());
		}
	}
}
