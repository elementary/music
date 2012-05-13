/*-
 * Copyright (c) 2011-2012 Scott Ringwelski <sgringwe@mtu.edu>
 * Copyright (c) 2012 Noise Developers
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
				debug ("----> CREATING ALBUM VIEW POPOVER <----");
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

	public FastGrid icons { get; private set; }

/* Spacing Workarounds */
#if !GTK_ICON_VIEW_BUG_IS_FIXED
	private EventBox vpadding_box;
	private EventBox hpadding_box;
#endif

	private LibraryManager lm;
	private LibraryWindow lw;

	private Gdk.Pixbuf defaultPix;

	private const int ITEM_PADDING = 0;
	private const int ITEM_WIDTH = Icons.ALBUM_VIEW_IMAGE_SIZE;

	private const int MIN_SPACING = 12;

	/* media should be mutable, as we will be sorting it */
	public AlbumView(ViewWrapper view_wrapper) {
		lm = view_wrapper.lm;
		lw = view_wrapper.lw;
		parent_view_wrapper = view_wrapper;

		defaultPix = lm.get_pixbuf_shadow (Icons.DEFAULT_ALBUM_ART_PIXBUF);
		build_ui();
	}

	public void build_ui () {
		set_policy(PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);

		icons = new FastGrid ();

		icons.set_compare_func(compare_func);
		icons.set_value_func(val_func);

		icons.set_columns(-1);

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
		wrapper_hbox.pack_start (icons, true, true, 0);

		add_with_viewport (wrapper_vbox);

		icons.margin = 0;
#else
		add (icons);
		icons.margin = MIN_SPACING;
#endif

		icons.item_width = ITEM_WIDTH;
		icons.item_padding = ITEM_PADDING;
		icons.spacing = 0;
		icons.row_spacing = MIN_SPACING;
		icons.column_spacing = MIN_SPACING;

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

		icons.add_events (Gdk.EventMask.POINTER_MOTION_MASK);
		icons.motion_notify_event.connect (on_motion_notify);

		//icons.button_press_event.connect (on_button_press);
		icons.button_release_event.connect (on_button_release);
		icons.item_activated.connect (item_activated);

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

	public Gee.Collection<Media> get_media () {
		var media_list = new Gee.LinkedList<Media> ();
		foreach (var m in icons.get_visible_table ().get_values ())
			media_list.add ((Media)m);

		return media_list;
	}

	public Gee.Collection<Media> get_visible_media () {
		var media_list = new Gee.LinkedList<Media> ();
		foreach (var m in icons.get_table ().get_values ())
			media_list.add ((Media)m);

		return media_list;
	}


	private string get_key (Media m) {
		if (m == null)
			return "";
		return m.album_artist + m.album;
	}

	public async void set_media (Gee.Collection<Media> to_add) {
		var new_table = new HashTable<int, Media> (null, null);
		// just here to check for duplicates
		var to_add_ind = new Gee.HashMap<string, int> ();

		foreach (var m in to_add) {
			if (m == null)
				continue;
			
			string key = get_key (m);

			if (!to_add_ind.has_key (key)) {
				to_add_ind.set (key, 1);
				new_table.set ((int)new_table.size(), m);
			}
		}

		// set table and resort
		icons.set_table (new_table, true);
	}

	public async void add_media (Gee.Collection<Media> media) {
		var to_append = new Gee.HashMap<string, Media> ();
		foreach (var m in media) {
			if (m == null)
				continue;
			
			string key = get_key (m);

			if (!to_append.has_key (key)) {
				to_append.set (key, m);
			}		
		}

		icons.add_objects (to_append.values);
	}

	public async void remove_media (Gee.Collection<Media> to_remove) {
		var to_remove_ind = new Gee.HashMap<string, int> ();
		var to_remove_table = new HashMap<Object, int> ();

		foreach (var m in to_remove) {
			if (m == null)
				continue;

			string key = get_key (m);

			if (!to_remove_ind.has_key (key)) {
				to_remove_ind.set (key, 1);
				to_remove_table.set (m, 1);
			}
		}

		icons.remove_objects (to_remove_table);	
	}

	public int get_relative_id () {
		return 0;
	}


	private bool on_button_release (Gdk.EventButton ev) {
		if (ev.type == Gdk.EventType.BUTTON_RELEASE && ev.button == 1) {
			TreePath path;
			CellRenderer cell;

			icons.get_item_at_pos ((int)ev.x, (int)ev.y, out path, out cell);

			if (path == null) { // blank area
				album_list_view.hide ();
				return false;
			}

			item_activated (path);
		}

		return false;
	}

	private bool on_motion_notify (Gdk.EventMotion ev) {
		TreePath path;
		CellRenderer cell;

		icons.get_item_at_pos ((int)ev.x, (int)ev.y, out path, out cell);

		if (path == null) // blank area
			icons.get_window ().set_cursor (null);
		else
			icons.get_window ().set_cursor (new Gdk.Cursor (Gdk.CursorType.HAND1));

		return false;
	}


	private void item_activated (TreePath path) {
		if (!lw.initialization_finished)
			return;

		Media? s = (Media)icons.get_object_from_index(int.parse(path.to_string()));

		if (s == null) {
			album_list_view.hide ();
			return;
		}

		album_list_view.set_parent_wrapper (this.parent_view_wrapper);
		album_list_view.set_songs_from_media (s);

		// find window's location
		int x, y;
		Gtk.Allocation alloc;
		lm.lw.get_position (out x, out y);
		get_allocation (out alloc);

		// move down to icon view's allocation
		x += lm.lw.sourcesToMedias.get_position();
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





	const int FONT_SIZE = 10300;
	const int MAX_ALBUM_NAME_LENGTH = (int) (20.0 * ((double)FONT_SIZE/10500.0) * ((double) Icons.ALBUM_VIEW_IMAGE_SIZE) / 138.0);

	string TEXT_MARKUP = @"<span weight='medium' size='$FONT_SIZE'>%s\n</span><span foreground=\"#999\">%s</span>";
	string TOOLTIP_MARKUP = @"<span weight='bold' size='$FONT_SIZE'>%s</span>\n%s";

	public Value val_func (int row, int column, Object o) {
		Media s = o as Media;
		Value? val = null;

		if (column == icons.PIXBUF_COLUMN) {
			var cover_art = lm.get_cover_album_art_from_key(s.album_artist, s.album);
			if(cover_art != null) {
				val = cover_art;
			}
			else {
				val = defaultPix;
			}
		}
		else if(column == icons.MARKUP_COLUMN) {
			string album, album_artist;
			if(s.album.length > MAX_ALBUM_NAME_LENGTH)
				album = s.album.substring(0, MAX_ALBUM_NAME_LENGTH - 3) + "...";
			else
				album = s.album;

			if(s.album_artist.length > 25)
				album_artist = s.album_artist.substring(0, 22) + "...";
			else
				album_artist = s.album_artist;
				val = TEXT_MARKUP.printf (String.escape (album), String.escape (album_artist));
		}
		else if(column == icons.TOOLTIP_COLUMN) {
			val = TOOLTIP_MARKUP.printf (String.escape (s.album), String.escape (s.album_artist));
		}
		else {
			val = s;
		}
		
		return val;
	}

	private int compare_func (GLib.Object o_a, GLib.Object o_b) {
		Media a = o_a as Media;
		Media b = o_b as Media;
		
		if (a.album_artist == b.album_artist) {
#if 0
			if (a.album == b.album) {
				return a.count() - b.count();
			}
			else {
				return advanced_string_compare (a.album, b.album);
			}
#else
			return advanced_string_compare (a.album, b.album);
#endif
		}
		else {
			return advanced_string_compare (a.album_artist, b.album_artist);
		}
	}

	private inline int advanced_string_compare (string a, string b) {
		if (a == "" && b != "")
			return 1;
		else if (a != "" && b == "")
			return -1;
		
		return (a > b) ? 1 : -1;
	}


/*
 * This is the ideal implementation of the smart spacing mechanism. Currently
 * it's being stopped by a bug in GTK+ 3 that inserts the row-spacing and column-spacing
 * properties after the last row and column respectively, instead of just in-between
 * them. This causes the album view to have 'margin + column-spacing' on the right
 * and 'margin + row-spacing' on the bottom, when they should be 'margin' and 'margin'.
 *
 * /!\ Still present in GTK+ 3.4.1 -- Apr. 21, 2012
 */
#if GTK_ICON_VIEW_BUG_IS_FIXED
	private void on_resize (Allocation alloc) {

		if (!visible) {
			return;
		}

		int n_columns = 1;
		int new_spacing = 0;

		int TOTAL_WIDTH = alloc.width;
		int TOTAL_ITEM_WIDTH = ITEM_WIDTH + 2 * ITEM_PADDING;

		// Calculate the number of columns
		n_columns = (TOTAL_WIDTH - MIN_SPACING) / (TOTAL_ITEM_WIDTH + MIN_SPACING);

		if (n_columns < 1)
			return;

		set_columns (n_columns);

		// We don't want to adjust the spacing if the row is not full
		if (icons.get_table ().size () < n_columns)
			new_spacing = MIN_SPACING;
		else
			new_spacing = (TOTAL_WIDTH - n_columns * (ITEM_WIDTH + 1) - 2 * n_columns * ITEM_PADDING) / (n_columns + 1);

		set_spacing (new_spacing);
	}
#else
	/* Use workarounds */
	Mutex setting_size;

	private void on_resize (Allocation alloc) {
		setting_size.lock ();

		if (!visible) {
			setting_size.unlock ();
			return;
		}

		int n_columns = 1;
		int new_spacing = 0;

		int TOTAL_WIDTH = alloc.width;
		int TOTAL_ITEM_WIDTH = ITEM_WIDTH + 2 * ITEM_PADDING;

		// Calculate the number of columns
		n_columns = (TOTAL_WIDTH - MIN_SPACING) / (TOTAL_ITEM_WIDTH + MIN_SPACING);

		if (n_columns < 1) {
			setting_size.unlock ();
			return;
		}

		icons.set_columns (n_columns);

		// We don't want to adjust the spacing if the row is not full
		if (icons.get_table ().size () < n_columns) {
			setting_size.unlock ();
			return;
		}

		new_spacing = (TOTAL_WIDTH - n_columns * (ITEM_WIDTH + 1) - 2 * n_columns * ITEM_PADDING) / (n_columns + 1);

		if (new_spacing < 0) {
			setting_size.unlock ();
			return;
		}

		vpadding_box.set_size_request (-1, new_spacing);
		hpadding_box.set_size_request (new_spacing - n_columns / 2, -1);

		icons.set_column_spacing (new_spacing);
		icons.set_row_spacing (new_spacing);
		
		setting_size.unlock ();
	}
#endif
}


