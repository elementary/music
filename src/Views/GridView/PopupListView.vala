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
 * Authored by: Victor Eduardo <victoreduardm@gmail.com>
 *              Scott Ringwelski <sgringwe@mtu.edu>
 */

using Gee;
using Gtk;

#if USE_GRANITE_DECORATED_WINDOW
public class Noise.PopupListView : Granite.Widgets.DecoratedWindow {
#else
public class Noise.PopupListView : Window {
#endif

	public const int MIN_SIZE = 400;

	LibraryManager lm;
	ViewWrapper view_wrapper;

	Gtk.Label album_label;
	Gtk.Label artist_label;
	Granite.Widgets.Rating rating;

	GenericList list_view;

	Gee.Collection<Media> media_list;

	public PopupListView (GridView grid_view) {
#if USE_GRANITE_DECORATED_WINDOW
        base ("", "album-list-view", "album-list-view");

        // Don't destroy the window
		this.delete_event.connect (hide_on_delete);

        // Hide titlebar (we want to set a title, but not showing it!)
        this.show_title = false;
#else
		window_position = Gtk.WindowPosition.CENTER_ON_PARENT;

		// window stuff
		decorated = false;
		has_resize_grip = false;
		resizable = false;

		// close button
		var close = new Gtk.Button ();
        get_style_context ().add_class ("album-list-view");
		close.get_style_context().add_class("close-button");
		close.set_image (Icons.render_image ("window-close-symbolic", Gtk.IconSize.MENU));
		close.hexpand = close.vexpand = false;
		close.halign = Gtk.Align.START;
		close.set_relief(Gtk.ReliefStyle.NONE);
		close.clicked.connect( () =>  { this.hide(); });

		/* Make window draggable */
		UI.make_window_draggable (this);
#endif

		this.view_wrapper = grid_view.parent_view_wrapper;
		this.lm = view_wrapper.lm;

		transient_for = lm.lw;
		destroy_with_parent = true;
		skip_taskbar_hint = true;

		// album artist/album labels
		album_label = new Label ("");
		artist_label = new Label ("");

		// Apply special style: Level-2 header
		Granite.Widgets.Utils.apply_text_style_to_label (Granite.TextStyle.H2, album_label);

		album_label.ellipsize = Pango.EllipsizeMode.END;
		artist_label.ellipsize = Pango.EllipsizeMode.END;

		album_label.set_line_wrap (false);
		artist_label.set_line_wrap (false);
		
		album_label.set_max_width_chars (30);
		artist_label.set_max_width_chars (30);

		album_label.margin_left = album_label.margin_right = 12;
		artist_label.margin_bottom = 12;

		// Music List
		var tvs = new TreeViewSetup (ListColumn.ARTIST, Gtk.SortType.ASCENDING, ViewWrapper.Hint.ALBUM_LIST);
		list_view = new MusicListView (view_wrapper, tvs);
        list_view.set_search_func (view_search_func);

        list_view.expand = true;
		
		var list_view_scrolled = new ScrolledWindow (null, null);
		list_view_scrolled.add (list_view);

		// Rating widget
		rating = new Granite.Widgets.Rating (true, IconSize.MENU, true);
		// customize rating
		rating.star_spacing = 16;
		rating.margin_top = rating.margin_bottom = 16;

		// Add everything
		var vbox = new Box(Orientation.VERTICAL, 0);
#if !USE_GRANITE_DECORATED_WINDOW
		vbox.pack_start (close, false, false, 0);
#endif
		vbox.pack_start (album_label, false, true, 0);
		vbox.pack_start (artist_label, false, true, 0);
		vbox.pack_start (list_view_scrolled, true, true, 0);
		vbox.pack_start(rating, false, true, 0);

		add(vbox);

		rating.rating_changed.connect(rating_changed);
	}

	/**
	 * Resets the window
	 */
	public void reset () {
		// clear labels
		set_title ("");
		album_label.set_label ("");
		artist_label.set_label ("");

		// clear treeview and media list
        list_view.get_selection ().unselect_all (); // Unselect rows
        media_list = new Gee.LinkedList<Media> ();
        list_view.set_media (media_list);

		// Reset size request
		set_size (MIN_SIZE);
	}

	public void set_parent_wrapper (ViewWrapper parent_wrapper) {
		this.view_wrapper = parent_wrapper;
		this.list_view.set_parent_wrapper (parent_wrapper);
	}

	Mutex setting_media;

	public void set_album (Album album) {
		reset ();

		setting_media.lock ();

        string name = album.get_display_name ();
        string artist = album.get_display_artist ();

        string title_format = C_("Title format used on Album View Popup: $ALBUM by $ARTIST", "%s by %s");
        set_title (title_format.printf (name, artist));
        
        album_label.set_label (name);
        artist_label.set_label (artist);
        
        // Make a copy. Otherwise the list won't work if some elements are
        // removed from the parent wrapper while the window is showing
        media_list = Utils.copy_collection<Media> (album.get_media ());

		list_view.set_media (media_list);

        // Search again to match the view wrapper's search
        list_view.do_search (view_wrapper.get_search_string ());

		setting_media.unlock ();

        if (list_view.get_realized ())
            list_view.columns_autosize ();

		// Set rating
		update_album_rating ();
		lm.media_updated.connect (update_album_rating);
	}

	void update_album_rating () {
		// We don't want to set the overall_rating as each media's rating.
		// See rating_changed() in case you want to figure out what would happen.
		rating.rating_changed.disconnect(rating_changed);

		// Use average rating for the album
		int total_rating = 0, n_media = 0;
		foreach (var media in media_list) {
			if (media == null)
				continue;
			n_media ++;
			total_rating += (int)media.rating;
		}

		float average_rating = (float)total_rating / (float)n_media;

		// fix approximation and set new rating
		rating.rating = Numeric.int_from_float (average_rating);

		// connect again ...
		rating.rating_changed.connect (rating_changed);
	}

	void rating_changed (int new_rating) {
		setting_media.lock ();

		var updated = new LinkedList<Media> ();
		foreach (var media in media_list) {
			if (media == null)
				continue;

			media.rating = (uint)new_rating;
			updated.add (media);
		}

		setting_media.unlock ();

		lm.update_media (updated, false, true);
	}

    private void view_search_func (string search, HashTable<int, Object> table, ref HashTable<int, Object> showing) {
        int parsed_rating;
        string parsed_search_string;

        ContentView.base_search_method (search, out parsed_rating, out parsed_search_string);

        bool rating_search = parsed_rating > 0;

        // If an external refiltering is going on, we cannot obey the column browser filter
        // because it wil be refreshed after this search based on the new 'showing' table
        // (populated by this method).
        int show_index = 0;
        for (int i = 0; i < table.size (); ++i) {
            var m = table.get (i) as Media;
            if (m != null) {
                if (rating_search) {
                    if (m.rating == (uint) parsed_rating)
                        showing.set (show_index++, m);
                } else if (Search.match_string_to_media (m, parsed_search_string)) {
                    showing.set (show_index++, m);
                }
            }
        }
    }

    /**
     * Force squared layout
     */
    public void set_size (int size) {
        this.set_size_request (size, -1);
        queue_resize ();
    }

    public override Gtk.SizeRequestMode get_request_mode () {
        return Gtk.SizeRequestMode.HEIGHT_FOR_WIDTH;
    }

    public override void get_preferred_height_for_width (int width,
                                                         out int minimum_height,
                                                         out int natural_height)
    {
        minimum_height = natural_height = width;
    }
}

