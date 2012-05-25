/*-
 * Copyright (c) 2012 Noise Developers
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
using Gee;

namespace BeatBox {
	// Share popover across multiple album views. For speed and memory saving
	public AlbumListView? _shared_album_list_view = null;
}

public class BeatBox.AlbumView : ContentView, ScrolledWindow {

	// The window used to present album contents
	public AlbumListView album_list_view {
		get {
			if (_shared_album_list_view == null) {
				debug ("Creating ALBUM VIEW POPOVER");
				_shared_album_list_view = new AlbumListView (this);
				_shared_album_list_view.focus_out_event.connect ( () => {
					if (album_list_view.visible && lw.has_focus) {
						album_list_view.show_all ();
						album_list_view.present ();
					}
					return false;
				});
			}

			return _shared_album_list_view;
		}
	}

	public ViewWrapper parent_view_wrapper { get; private set; }

	public FastGrid icon_view { get; private set; }

	// album-key / album-media
	Gee.HashMap<string, Gee.HashMap<Media, int>> album_info;

/* Spacing Workarounds */
#if !GTK_ICON_VIEW_BUG_IS_FIXED
	private Gtk.EventBox vpadding_box;
	private Gtk.EventBox hpadding_box;
#endif

	private LibraryManager lm;
	private LibraryWindow lw;

	private Gdk.Pixbuf defaultPix;

	private const int ITEM_PADDING = 0;
	private const int MIN_SPACING = 12;
	private const int ITEM_WIDTH = Icons.ALBUM_VIEW_IMAGE_SIZE;

	/* media should be mutable, as we will be sorting it */
	public AlbumView(ViewWrapper view_wrapper) {
		lm = view_wrapper.lm;
		lw = view_wrapper.lw;
		parent_view_wrapper = view_wrapper;

		defaultPix = lm.get_pixbuf_shadow (Icons.DEFAULT_ALBUM_ART_PIXBUF);
		build_ui();
		
		init ();
	}

	public void build_ui () {
		set_policy(PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);

		icon_view = new FastGrid ();

		icon_view.set_compare_func(compare_func);
		icon_view.set_value_func(val_func);

		icon_view.set_columns(-1);

#if !GTK_ICON_VIEW_BUG_IS_FIXED
		var wrapper_vbox = new Box (Orientation.VERTICAL, 0);
		var wrapper_hbox = new Box (Orientation.HORIZONTAL, 0);

		vpadding_box = new EventBox();
		hpadding_box = new EventBox();

		vpadding_box.get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
		hpadding_box.get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
		this.get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);

		vpadding_box.get_style_context().add_class(Granite.STYLE_CLASS_CONTENT_VIEW);
		hpadding_box.get_style_context().add_class(Granite.STYLE_CLASS_CONTENT_VIEW);
		this.get_style_context().add_class (Granite.STYLE_CLASS_CONTENT_VIEW);

		vpadding_box.set_size_request (-1, MIN_SPACING + ITEM_PADDING);
		hpadding_box.set_size_request (MIN_SPACING + ITEM_PADDING, -1);

		vpadding_box.button_press_event.connect ( () => {
			album_list_view.hide ();
			return false;
		});

		hpadding_box.button_press_event.connect ( () => {
			album_list_view.hide ();
			return false;
		});


		wrapper_vbox.pack_start (vpadding_box, false, false, 0);
		wrapper_vbox.pack_start (wrapper_hbox, true, true, 0);
		wrapper_hbox.pack_start (hpadding_box, false, false, 0);
		wrapper_hbox.pack_start (icon_view, true, true, 0);

		add_with_viewport (wrapper_vbox);

		icon_view.margin = 0;
#else
		add (icon_view);
		icon_view.margin = MIN_SPACING;
#endif

		icon_view.item_width = ITEM_WIDTH;
		icon_view.item_padding = ITEM_PADDING;
		icon_view.spacing = 0;
		icon_view.row_spacing = MIN_SPACING;
		icon_view.column_spacing = MIN_SPACING;

		show_all();

		var focus_blacklist = new Gee.LinkedList<Gtk.Widget> ();
		focus_blacklist.add (lw.viewSelector);
		focus_blacklist.add (lw.searchField);
		focus_blacklist.add (lw.sideTree);
		focus_blacklist.add (lw.statusbar);

		lw.viewSelector.mode_changed.connect ( () => {
			album_list_view.hide ();
		});

		foreach (var w in focus_blacklist) {
			w.add_events (Gdk.EventMask.BUTTON_PRESS_MASK);
			w.button_press_event.connect ( () => {
				album_list_view.hide ();
				return false;
			});
		}

		icon_view.add_events (Gdk.EventMask.POINTER_MOTION_MASK);
		icon_view.motion_notify_event.connect (on_motion_notify);
		icon_view.scroll_event.connect (on_scroll_event);

		//icon_view.button_press_event.connect (on_button_press);
		icon_view.button_release_event.connect (on_button_release);
		icon_view.item_activated.connect (item_activated);

		// for smart spacing stuff
		int MIN_N_ITEMS = 2; // we will allocate horizontal space for at least two items
		int TOTAL_ITEM_WIDTH = ITEM_WIDTH + 2 * ITEM_PADDING;
		int TOTAL_MARGIN = MIN_N_ITEMS * (MIN_SPACING + ITEM_PADDING);
		int MIDDLE_SPACE = MIN_N_ITEMS * MIN_SPACING;

		parent_view_wrapper.set_size_request (MIN_N_ITEMS * TOTAL_ITEM_WIDTH + TOTAL_MARGIN + MIDDLE_SPACE, -1);
		parent_view_wrapper.size_allocate.connect (on_resize);
	}

	public ViewWrapper.Hint get_hint() {
		return parent_view_wrapper.hint;
	}

	public Gee.Collection<Media> get_visible_media () {
		var media_list = new Gee.LinkedList<Media> ();
		foreach (var m in icon_view.get_visible_table ().get_values ())
			media_list.add ((Media)m);

		return media_list;
	}

	public Gee.Collection<Media> get_media () {
		var media_list = new Gee.LinkedList<Media> ();
		foreach (var m in icon_view.get_table ().get_values ())
			media_list.add ((Media)m);

		return media_list;
	}


	private string get_key (Media m) {
		if (m == null)
			return "";
		return m.album_artist + m.album;
	}

	/** Inits data containers **/
	private void init () {
		// reset table
		icon_view.set_table (new HashTable<int, GLib.Object> (null, null));
		album_info = new Gee.HashMap<string, Gee.HashMap<Media, int>> ();
	}

	public void set_media (Gee.Collection<Media> to_add) {
		init ();

		// Add new media
		add_media (to_add);
	}

	// checks for duplicates
	public void add_media (Gee.Collection<Media> media) {
		var to_append = new Gee.HashMap<string, Media> ();
		foreach (var m in media) {
			if (m == null)
				continue;
			
			string key = get_key (m);

			if (!to_append.has_key (key)) {
				if (!album_info.has_key (key)) {
					// Create a new media. We don't want to depend on a song
					// that could be removed for this.
					var album = new Media ("");
					album.album = m.album;
					album.album_artist = m.album_artist;
					to_append.set (key, album);
					
					// set info
					album_info.set (key, new Gee.HashMap<Media, int> ());
				}
			}

			var album_media = album_info.get (key);
			if (!album_media.has_key (m))
				album_media.set (m, 1);
		}

		icon_view.add_objects (to_append.values);
	}

	public void remove_media (Gee.Collection<Media> to_remove) {
		/* There is a special case. Let's say that we're removing
		 * song1, song2 and song5 from Album X, and the album currently
		 * contains song1, song2, song5, and song3. Then we shouldn't remove
		 * the album because it still contains a song (song3).
		 */

		// classify media by album
		var to_remove_album_info = new Gee.HashMap <string, Gee.LinkedList<Media>> ();
		foreach (var m in to_remove) {
			if (m == null)
				continue;
			
			string key = get_key (m);

			if (!to_remove_album_info.has_key (key)) {
				// set info
				to_remove_album_info.set (key, new Gee.LinkedList<Media> ());
			}

			to_remove_album_info.get (key).add (m);
		}

		// table of albums that will be removed
		var albums_to_remove = new Gee.HashMap<string, int> ();

		// Then use the list to verify which albums are in the album view
		foreach (var album_key in to_remove_album_info.keys) {
			if (album_info.has_key (album_key)) {
				// get current media list
				var current_media = album_info.get (album_key);

				// get list of media that should be removed
				var to_remove_media = to_remove_album_info.get (album_key);

				foreach (var m in to_remove_media) {
					current_media.unset (m);
				}
				
				// if the album is left with no songs, it should be removed
				if (current_media.size <= 0) {
					albums_to_remove.set (album_key, 1);
					// unset from album info
					album_info.unset (album_key);
				}
			}
		}

		if (albums_to_remove.size < 1)
			return;		

		// Find media representations in table
		var objects_to_remove = new Gee.HashMap<GLib.Object, int> ();

		foreach (var album_representation in get_visible_media ()) {
			var key = get_key (album_representation);
			if (albums_to_remove.has_key (key))
				objects_to_remove.set (album_representation, 1);
		}

		icon_view.remove_objects (objects_to_remove);
	}

	public int get_relative_id () {
		return -1;
	}

	private bool on_button_release (Gdk.EventButton ev) {
		if (ev.type == Gdk.EventType.BUTTON_RELEASE && ev.button == 1) {
			TreePath path;
			CellRenderer cell;

			icon_view.get_item_at_pos ((int)ev.x, (int)ev.y, out path, out cell);

			if (path == null) { // blank area
				album_list_view.hide ();
				return false;
			}

			item_activated (path);
		}

		return false;
	}

	private inline void set_cursor (int x, int y) {
		TreePath path;
		CellRenderer cell;

		icon_view.get_item_at_pos (x, y, out path, out cell);

		if (path == null) // blank area
			icon_view.get_window ().set_cursor (null);
		else
			icon_view.get_window ().set_cursor (new Gdk.Cursor (Gdk.CursorType.HAND1));

	}

	private bool on_motion_notify (Gdk.EventMotion ev) {
		set_cursor ((int)ev.x, (int)ev.y);
		return false;
	}

	private bool on_scroll_event (Gdk.EventScroll ev) {
		set_cursor ((int)ev.x, (int)ev.y);
		return false;
	}


	private void item_activated (TreePath path) {
		if (!lw.initialization_finished)
			return;

		Media? s = (Media)icon_view.get_object_from_index(int.parse(path.to_string()));

		if (s == null) {
			album_list_view.hide ();
			return;
		}

		album_list_view.set_parent_wrapper (this.parent_view_wrapper);
		album_list_view.set_media (album_info.get (get_key (s)).keys);

		// find window's location
		int x, y;
		Gtk.Allocation alloc;
		lm.lw.get_position (out x, out y);
		get_allocation (out alloc);

		// move down to icon view's allocation
		x += lm.lw.main_hpaned.get_position();
		y += alloc.y;

		// center it on this icon view
		x += (alloc.width - album_list_view.WIDTH) / 2;
		y += (alloc.height - album_list_view.HEIGHT) / 2 + 60;

		bool was_visible = album_list_view.visible;
		album_list_view.show_all ();
		if (!was_visible)
			album_list_view.move (x, y);
		album_list_view.present ();
	}


	public Value val_func (int row, int column, Object o) {
		Media s = o as Media;
		Value? val = null;

		if (column == icon_view.PIXBUF_COLUMN) {
			var cover_art = lm.get_cover_album_art_from_key(s.album_artist, s.album);
			if(cover_art != null) {
				val = cover_art;
			}
			else {
				val = defaultPix;
			}
		}
		else if(column == icon_view.MARKUP_COLUMN) {
			string TEXT_MARKUP = @"%s\n<span foreground=\"#999\">%s</span>";
			
			string album, album_artist;
			if(s.album.length > 25)
				album = s.album.substring (0, 21) + "...";
			else
				album = s.album;

			if(s.album_artist.length > 25)
				album_artist = s.album_artist.substring(0, 21) + "...";
			else
				album_artist = s.album_artist;

			val = TEXT_MARKUP.printf (String.escape (album), String.escape (album_artist));
		}
		else if(column == icon_view.TOOLTIP_COLUMN) {
			string TOOLTIP_MARKUP = @"<span size=\"large\"><b>%s</b></span>\n%s";
			val = TOOLTIP_MARKUP.printf (String.escape (s.album), String.escape (s.album_artist));
		}
		else {
			val = s;
		}
		
		return val;
	}

	private int compare_func (GLib.Object o_a, GLib.Object o_b) {
		Media a_media = o_a as Media;
		Media b_media = o_b as Media;

		int rv = 0;

		if(a_media.album.down() == b_media.album.down()) {
			if(a_media.album_number == b_media.album_number)
				rv = (int)(a_media.track - b_media.track);
			else
				rv = (int)((int)a_media.album_number - (int)b_media.album_number);
		}
		else {
			if(a_media.album == "")
				rv = 1;
			else
				rv = String.compare (a_media.album.down(), b_media.album.down());
		}

		return rv;
	}

	/**
	 * Smart spacing
	 */

	Mutex setting_size;

	int priority_offset = 0;

	private void on_resize (Gtk.Allocation alloc) {
		priority_offset ++;

		Idle.add_full (Priority.HIGH_IDLE - priority_offset, () => {
			compute_spacing (alloc);
			return false;
		});
	}

	private void compute_spacing (Gtk.Allocation alloc) {
		if (alloc.width != parent_view_wrapper.get_allocated_width ())
			return;

		setting_size.lock ();

		if (!visible) {
			setting_size.unlock ();
			return;
		}

		int TOTAL_WIDTH = alloc.width; // width of view wrapper, not scrolled window!
		int TOTAL_ITEM_WIDTH = ITEM_WIDTH + 2 * ITEM_PADDING;

		// Calculate the number of columns
		float n = (float)(TOTAL_WIDTH - MIN_SPACING) / (float)(TOTAL_ITEM_WIDTH + MIN_SPACING);
		int n_columns = Numeric.lowest_int_from_float (n);

		if (n_columns < 1) {
			setting_size.unlock ();
			return;
		}

		icon_view.set_columns (n_columns);

		// We don't want to adjust the spacing if the row is not full
		if (icon_view.get_table ().size () < n_columns) {
			setting_size.unlock ();
			return;
		}

		// You're not supposed to understand this.
		float spacing = (float)(TOTAL_WIDTH - n_columns * (ITEM_WIDTH + 1) - 2 * n_columns * ITEM_PADDING) / (float)(n_columns + 1);
		int new_spacing = Numeric.int_from_float (spacing);

		if (new_spacing < 0) {
			setting_size.unlock ();
			return;
		}

		if (TOTAL_WIDTH < 300)
			-- new_spacing;

		// apply new spacing
		set_spacing (new_spacing);

		priority_offset = 0;

		setting_size.unlock ();
	}

	private void set_spacing (int spacing) {
		if (spacing < 0)
			return;

		int item_offset = ITEM_PADDING / icon_view.columns;
		int item_spacing = spacing - ((item_offset > 0) ? item_offset : 1);

		icon_view.set_column_spacing (item_spacing);
		icon_view.set_row_spacing (item_spacing);

		int margin_width = spacing + ITEM_PADDING;

#if GTK_ICON_VIEW_BUG_IS_FIXED
		icon_view.set_margin (margin_width);
#else
		vpadding_box.set_size_request (-1, margin_width);
		hpadding_box.set_size_request (margin_width, -1);
#endif
	}
}

