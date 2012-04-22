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

public class BeatBox.AlbumView : ContentView, ScrolledWindow {

	public signal void itemClicked(string artist, string album);

	private const int MEDIA_SET_VAL = 1;

	// The window used to present album contents
	public AlbumListView album_list_view { get; private set; }

	public ViewWrapper parent_view_wrapper { get; private set; }

	public int n_albums { get { return model.iter_n_children(null); } }

	public IconView icons { get; private set; }

/* Spacing Workarounds */
#if !GTK_ICON_VIEW_BUG_IS_FIXED
	private EventBox vpadding_box;
	private EventBox hpadding_box;
#endif

	private LibraryManager lm;
	private LibraryWindow lw;

	private Collection<int> _show_next; // these are populated if necessary when user opens this view.
	private HashMap<string, int> _showing_media;

	private AlbumViewModel model;

	private Gdk.Pixbuf defaultPix;

	private const int ITEM_PADDING = 0;
	private const int ITEM_WIDTH = Icons.ALBUM_VIEW_IMAGE_SIZE;

#if GTK_ICON_VIEW_BUG_IS_FIXED
	private const int MIN_SPACING = 12;
#else
	// it would be 12, but we can subtract 6 px since there's a lot of extra space in-between
	private const int MIN_SPACING = 6;
#endif

	/* media should be mutable, as we will be sorting it */
	public AlbumView(ViewWrapper view_wrapper) {
		lm = view_wrapper.lm;
		lw = view_wrapper.lw;

		parent_view_wrapper = view_wrapper;
		album_list_view = new AlbumListView(this);

		_show_next = new LinkedList<int>();
		_showing_media = new HashMap<string, int>();

		defaultPix = Icons.DEFAULT_ALBUM_ART_PIXBUF;

		buildUI();
	}

	public void buildUI() {
		set_policy(PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);

		icons = new IconView();
		model = new AlbumViewModel(lm, defaultPix);

		icons.set_columns(-1);

		icons.set_pixbuf_column(model.PIXBUF_COLUMN);
		icons.set_markup_column(model.MARKUP_COLUMN);
		icons.set_tooltip_column(model.TOOLTIP_COLUMN);

		icons.set_model (model);

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

		icons.button_release_event.connect(buttonReleaseEvent);
		icons.button_press_event.connect(buttonReleaseEvent);
		icons.item_activated.connect(itemActivated);

		// hide floating window when switching to another view
		lw.viewSelector.mode_changed.connect ( () => {
			album_list_view.hide ();
		});

		// for smart spacing stuff
		int MIN_N_ITEMS = 2; // we will allocate horizontal space for at least two items
		int TOTAL_ITEM_WIDTH = ITEM_WIDTH + 2 * ITEM_PADDING;
		int TOTAL_MARGIN = MIN_N_ITEMS * (MIN_SPACING + ITEM_PADDING);
		int MIDDLE_SPACE = MIN_N_ITEMS * MIN_SPACING;

		parent_view_wrapper.set_size_request (MIN_N_ITEMS * TOTAL_ITEM_WIDTH + TOTAL_MARGIN + MIDDLE_SPACE, -1);
		parent_view_wrapper.size_allocate.connect (on_resize);
	}


	// Smart Spacing !

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

		// We don't want to adjust the spacing if the row is not full
		if (_showing_media.size < n_columns || n_columns < 1) {
			return;
		}

		new_spacing = (TOTAL_WIDTH - n_columns * (ITEM_WIDTH + 1) - 2 * n_columns * ITEM_PADDING) / (n_columns + 1);
		set_policy(PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);

		icons.set_columns (n_columns);

		icons.set_margin (new_spacing);
		icons.set_column_spacing (new_spacing);
		icons.set_row_spacing (new_spacing);

		set_policy(PolicyType.NEVER, PolicyType.AUTOMATIC);
	}
#else
	/* Use workarounds */
	Mutex setting_size = new Mutex ();
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

		// We don't want to adjust the spacing if the row is not full
		// This also means that the layout won't change while searching
		if (_showing_media.size < n_columns || n_columns < 1) {
			setting_size.unlock ();
			return;
		}

		new_spacing = (TOTAL_WIDTH - n_columns * (ITEM_WIDTH + 1) - 2 * n_columns * ITEM_PADDING) / (n_columns + 1);

		vpadding_box.set_size_request (-1, new_spacing);
		hpadding_box.set_size_request (new_spacing - n_columns / 2, -1);

		icons.set_columns (n_columns);
		icons.set_column_spacing (new_spacing);
		icons.set_row_spacing (new_spacing);

		setting_size.unlock ();
	}
#endif

	public ViewWrapper.Hint get_hint() {
		return parent_view_wrapper.hint;
	}

	public void set_show_next(Collection<int> media) {
		_show_next = media;
	}

	public int get_relative_id() {
		return 0;
	}

	public Collection<int> get_showing_media_ids () {
		return _showing_media.keys;
	}

	public void append_media(Collection<int> new_media) {
		var to_append = new LinkedList<Media>();

		foreach(int i in new_media) {
			Media s = lm.media_from_id(i);
			if (s == null)
				continue;
			
			string key = get_key (s);

			if(!_showing_media.has_key(key)) {
				_showing_media.set(key, MEDIA_SET_VAL);

				Media alb = new Media("");
				alb.album_artist = s.album_artist;
				alb.album = s.album;
				to_append.add (alb);
			}
		}

		model.append_media (to_append, true);
		model.resort();
		queue_draw();
	}

	public void remove_media(Collection<int> to_remove) {
		var media_remove = new LinkedList<Media>();

		foreach(int i in to_remove) {
			Media s = lm.media_from_id(i);
			if (s == null)
				continue;
			
			string key = get_key (s);

			if(_showing_media.has_key (key)) {
				_showing_media.unset (key);

				Media alb = new Media("");
				alb.album_artist = s.album_artist;
				alb.album = s.album;

				media_remove.add(alb);
			}
		}

		model.remove_media (media_remove, true);
		queue_draw();
	}

	public void populate_view() {
		icons.freeze_child_notify();
		icons.set_model(null);

		_showing_media.clear();
		var to_append = new LinkedList<Media>();
		foreach(int i in _show_next) {
			Media s = lm.media_from_id(i);
			if (s == null)
				continue;
			
			string key = get_key (s);

			if(!_showing_media.has_key (key)) {
				_showing_media.set(key, MEDIA_SET_VAL);

				Media alb = new Media("");
				alb.album_artist = s.album_artist;
				alb.album = s.album;
				to_append.add(alb);
			}
		}

		model = new AlbumViewModel(lm, defaultPix);
		model.append_media (to_append, false);
		model.set_sort_column_id(0, SortType.ASCENDING);
		icons.set_model(model);
		icons.thaw_child_notify();

		if(visible && lm.media_info.media != null)
			scrollToCurrent();
	}

	private string get_key (Media m) {
		if (m == null)
			return "";
		return m.album_artist + m.album;
	}


	public static int mediaCompareFunc(Media a, Media b) {
		if(a.album_artist.down() == b.album_artist.down())
			return (a.album > b.album) ? 1 : -1;

		return a.album_artist.down() > b.album_artist.down() ? 1 : -1;
	}

	public bool buttonReleaseEvent(Gdk.EventButton ev) {
		if(ev.type == Gdk.EventType.BUTTON_RELEASE && ev.button == 1) {
			TreePath path;
			CellRenderer cell;

			icons.get_item_at_pos((int)ev.x, (int)ev.y, out path, out cell);

			if(path == null)
				return false;

			itemActivated(path);
		}

		return false;
	}

	void itemActivated(TreePath path) {
		TreeIter iter;

		if(!model.get_iter(out iter, path)) {
			album_list_view.hide();

			return;
		}

		Media s = ((AlbumViewModel)model).get_media_representation(iter);

		album_list_view.set_songs_from_media(s);

		// find window's location
		int x, y;
		Gtk.Allocation alloc;
		lm.lw.get_position(out x, out y);
		get_allocation(out alloc);

		// move down to icon view's allocation
		x += lm.lw.sourcesToMedias.get_position();
		y += alloc.y;

		// center it on this icon view
		x += (alloc.width - album_list_view.WIDTH) / 2;
		y += (alloc.height - album_list_view.HEIGHT) / 2 + 60;

		album_list_view.show_all();
		album_list_view.move(x, y);
	}

	public void scrollToCurrent() {
		if(!visible || lm.media_info == null || lm.media_info.media == null)
			return;

		debug ("scrolling to current\n");

		TreeIter iter;
		model.iter_nth_child(out iter, null, 0);
		while(model.iter_next(ref iter)) {
			Value vs;
			model.get_value(iter, model.MEDIA_COLUMN, out vs);

			if(icons is IconView && ((Media)vs).album == lm.media_info.media.album) {
				icons.scroll_to_path(model.get_path(iter), false, 0.0f, 0.0f);

				return;
			}
		}
	}
}

