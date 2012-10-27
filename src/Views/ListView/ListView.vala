/*
 * Copyright (c) 2012 Noise Developers
 *
 * This is a free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this program; see the file COPYING.  If not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Victor Eduardo <victoreduardm@gmail.com>
 */

/**
 * Contains the column browser and list view.
 */

using Gee;
using Gtk;

public class Noise.ListView : ContentView, Gtk.Box {

	public signal void reordered ();

	// Wrapper for the list view and miller columns
	private Granite.Widgets.SidebarPaned list_view_hpaned; // for left mode
	private Gtk.Paned list_view_vpaned; // for top mode

	public ColumnBrowser column_browser { get; private set; }
	public GenericList   list_view      { get; private set; }

	private int list_view_hpaned_position = -1;
	private int list_view_vpaned_position = -1;

	private ViewWrapper view_wrapper;
	private LibraryWindow lw;
	private LibraryManager lm;
    private ViewTextOverlay list_text_overlay;

    private bool obey_column_browser = false;

    public uint n_media {
        get { return list_view.get_table ().size (); }
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

	public ListView (ViewWrapper view_wrapper, TreeViewSetup tvs, bool add_browser = false) {
		this.view_wrapper = view_wrapper;
		this.lm = view_wrapper.lm;
		this.lw = view_wrapper.lw;

		list_view = new MusicListView (view_wrapper, tvs);

		var list_scrolled = new Gtk.ScrolledWindow (null, null);
		list_scrolled.set_policy (Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
		list_scrolled.add (list_view);
	    list_scrolled.expand = true;

        list_text_overlay = new ViewTextOverlay ();
        list_text_overlay.add (list_scrolled);
        list_text_overlay.message = String.escape (_("No Songs Found."));

		list_view.rows_reordered.connect ( () => {
			reordered ();
		});

		list_view.import_requested.connect ( (to_import) => {
			import_requested (to_import);
		});

		if (add_browser)
			column_browser = new MusicColumnBrowser (view_wrapper);

        list_view.set_search_func (view_search_func);

		if (has_column_browser) {
			list_view_hpaned = new Granite.Widgets.SidebarPaned ();
			list_view_vpaned = new Paned (Orientation.VERTICAL);

			// Fix theming
			list_view_vpaned.get_style_context().add_class (Gtk.STYLE_CLASS_VERTICAL);

			list_view_hpaned.pack2(list_view_vpaned, true, false);

			// Add hpaned (the most-external wrapper) to the view container
			list_view_hpaned.expand = true;
			this.add (list_view_hpaned);

			// Now pack the list view
			list_view_vpaned.pack2(list_text_overlay, true, false);
			list_view_hpaned.pack1(column_browser, true, false);

			set_column_browser_position (column_browser.position);

			// Connect signals once the widget has been realized to avoid writing to settings
			// on startup
			this.realize.connect (connect_column_browser_ui_signals);

			column_browser_enabled = Settings.SavedState.instance.column_browser_enabled;

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
			if (list_view_hpaned.get_child1() == null && list_view_vpaned.get_child1() == column_browser) {
				list_view_vpaned.remove (column_browser);
				list_view_hpaned.pack1 (column_browser, true, false);

				list_view_hpaned.position = list_view_hpaned_position;
			}
		}
		else if (actual_position == ColumnBrowser.Position.TOP) {
			if (list_view_vpaned.get_child1() == null && list_view_hpaned.get_child1() == column_browser) {
				list_view_hpaned.remove (column_browser);
				list_view_vpaned.pack1 (column_browser, true, false);

				list_view_vpaned.set_position (list_view_vpaned_position);
			}
		}
	}

	private void connect_column_browser_ui_signals () {
		if (!has_column_browser)
			return;

		// For automatic position stuff
		this.size_allocate.connect ( () => {
			if (!lw.initialization_finished)
				return;

			if (column_browser.position == ColumnBrowser.Position.AUTOMATIC)
				set_column_browser_position (ColumnBrowser.Position.AUTOMATIC);
		});

		column_browser.size_allocate.connect ( () => {
			if (!lw.initialization_finished || !column_browser_enabled)
				return;

			if (column_browser.actual_position == ColumnBrowser.Position.LEFT) {
				if (list_view_hpaned.position > 0)
					list_view_hpaned_position = list_view_hpaned.position;
			}
			else if (column_browser.actual_position == ColumnBrowser.Position.TOP) {
				if (list_view_vpaned.position > 0)
					list_view_vpaned_position = list_view_vpaned.position;
			}
		});

        lw.viewSelector.column_browser_toggled.connect (  (enabled) => {
			if (enabled != column_browser_enabled)
				column_browser_enabled = enabled;
		});

		column_browser.position_changed.connect (set_column_browser_position);

		// Read Paned position from settings
		list_view_hpaned_position = Settings.SavedState.instance.column_browser_width;
		list_view_vpaned_position = Settings.SavedState.instance.column_browser_height;

		list_view_hpaned.position = list_view_hpaned_position;
		list_view_vpaned.position = list_view_vpaned_position;

		// We only save the settings when this view wrapper is being destroyed. This avoids unnecessary
		// disk access to write settings.
		destroy.connect (save_column_browser_settings);
	}

	private void save_column_browser_settings () {
		// Need to add a proper fix later ...
		if (has_column_browser) {
			if (column_browser.visible) {
				if (column_browser.actual_position == ColumnBrowser.Position.LEFT)
					Settings.SavedState.instance.column_browser_width = list_view_hpaned_position;
				else if (column_browser.actual_position == ColumnBrowser.Position.TOP)
					Settings.SavedState.instance.column_browser_height = list_view_vpaned_position;
			}

			Settings.SavedState.instance.column_browser_enabled = column_browser_enabled;
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
		var media_list = new Gee.LinkedList<Media> ();
		foreach (var m in list_view.get_table ().get_values ()) {
		    if (m != null)
			    media_list.add ((Media) m);
		}

		return media_list;
	}

	public Gee.Collection<Media> get_visible_media () {
		var media_list = new Gee.LinkedList<Media> ();
		foreach (var m in list_view.get_visible_table ().get_values ()) {
		    if (m != null)
			    media_list.add ((Media) m);
		}

		return media_list;
	}

	private void column_browser_changed () {
		if (lw.initialization_finished) {
            // This is supposed to take the browser's filter into account because obey_column_browser is #false
			list_view.do_search (null);
			view_wrapper.update_statusbar_info ();
		}
	}

	// TODO: Since is_initial is deprecated and not used, update the external code to stop using it
	public void set_as_current_list (int media_id, bool is_initial = false) {
		list_view.set_as_current_list (lm.media_from_id (media_id));
	}

	public bool get_is_current_list ()  {
		return list_view.get_is_current_list ();
	}

	public void add_media (Gee.Collection<Media> to_add) {
    	list_view.add_media (to_add);
		if (has_column_browser)
            column_browser.set_media (get_visible_media ());
	}

	public void remove_media (Gee.Collection<Media> to_remove) {
    	list_view.remove_media (to_remove);
		if (has_column_browser)
            column_browser.set_media (get_visible_media ());
	}

	public void set_media (Gee.Collection<Media> media) {
		if (has_column_browser)
			column_browser.set_media (media);

		list_view.set_media (media);

        obey_column_browser = true;
	}

    public void update_media (Gee.Collection<Media> media) {
        refilter (null);
    }

    public void refilter (string? search) {
        list_text_overlay.message_visible = false;

        // We set 'obey_column_browser' to 'false' because otherwise refilter() would
        // filter the visible media based on the browser's current filter, and then re-populate
        // the browser using that same media. We don't want that to happen, because it would
        // make the browser filter its own media!
        obey_column_browser = false;
        list_view.do_search (search);
        obey_column_browser = true;

        if (has_column_browser)
            column_browser.set_media (get_visible_media ());

        if (list_view.get_visible_table ().size () < 1)
            list_text_overlay.message_visible = true;
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

    private void view_search_func (string search, HashTable<int, Object> table, ref HashTable<int, Object> showing) {
        int parsed_rating;
        string parsed_search_string;

        base_search_method (search, out parsed_rating, out parsed_search_string);

        bool rating_search = parsed_rating > 0;

        // If an external refiltering is going on, we cannot obey the column browser filter
        // because it wil be refreshed after this search based on the new 'showing' table
        // (populated by this method).
        bool obey_column_browser = column_browser_enabled && this.obey_column_browser;
        int show_index = 0;

        for (int i = 0; i < table.size (); ++i) {
            var m = table.get (i) as Media;
            if (m != null) {
                if (obey_column_browser && !column_browser.match_media (m))
                    continue;

                if (rating_search) {
                    if (m.rating == (uint) parsed_rating)
                        showing.set (show_index++, m);
                } else if (Search.match_string_to_media (m, parsed_search_string)) {
                    showing.set (show_index++, m);
                }
            }
        }
    }
}
