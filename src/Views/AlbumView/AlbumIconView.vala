/*-
 * Copyright (c) 2011-2012       Scott Ringwelski <sgringwe@mtu.edu>
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
 */

using Gtk;
using Gee;

public class BeatBox.AlbumView : ContentView, ScrolledWindow {

	public signal void itemClicked(string artist, string album);

	// The window used to present album contents
	public AlbumListView album_list_view {get; private set;}

	public ViewWrapper parent_view_wrapper {get; private set;}

	public IconView icons;

	private LibraryManager lm;
	private LibraryWindow lw;
	private HashMap<string, LinkedList<int>> medias; // album+album_artist, list of related songs

	private Collection<int> _show_next; // these are populated if necessary when user opens this view.
	private HashMap<string, LinkedList<int>> _showing_medias;
	private string last_search;
	private LinkedList<string> timeout_search;

	private AlbumViewModel model;

	public bool is_current_view { get { return parent_view_wrapper.current_view == ViewWrapper.ViewType.ALBUM; } }

	private Gdk.Pixbuf defaultPix;

	private bool needsUpdate;

	private const int ITEM_PADDING = 3;
	private const int ITEM_WIDTH = Icons.ALBUM_VIEW_IMAGE_SIZE;
	private const int SPACING = 12;

	private const string ALBUM_VIEW_STYLESHEET = """
		GtkIconView.view.cell:selected,
		GtkIconView.view.cell:selected:focused {

		background-color: alpha (#000, 0.05);
    		background-image: none;

			color: @text_color;

			border-radius: 4px;
			border-style: solid;
			border-width: 1px;

			-unico-border-gradient: -gtk-gradient (linear,
			                 left top, left bottom,
			                 from (shade (@base_color, 0.74)),
			                 to (shade (@base_color, 0.74)));

			-unico-inner-stroke-gradient: -gtk-gradient (linear,
			                left top, left bottom,
			                from (alpha (#000, 0.07)),
			                to (alpha (#000, 0.03)));
		}
	""";

	/* medias should be mutable, as we will be sorting it */
	public AlbumView(ViewWrapper view_wrapper, Collection<int> smedias) {
		lm = view_wrapper.lm;
		lw = view_wrapper.lw;

		parent_view_wrapper = view_wrapper;
		album_list_view = new AlbumListView(this);

		medias = new HashMap<string, LinkedList<int>>();
		_show_next = new LinkedList<int>();
		foreach(int i in smedias) {
			Media s = lm.media_from_id(i);
			string key = s.album_artist + s.album;

			if(medias.get(key) == null)
				medias.set(key, new LinkedList<int>());

			medias.get(key).add(i);
		}

		_showing_medias = new HashMap<string, LinkedList<int>>();
		last_search = "";
		timeout_search = new LinkedList<string>();

		defaultPix = Icons.DEFAULT_ALBUM_ART_PIXBUF;

		buildUI();

		lm.medias_removed.connect(medias_removed);
		
		//parent_view_wrapper.size_allocate.connect (resized);
	}

	/*
	public void resized (Allocation alloc) {
		
		if (!visible)
			return;

		int n, total_width = lw.mediasToInfo.position; //alloc.width;
		int total_item_width = ITEM_WIDTH + 2 * ITEM_PADDING;

		// Calculate the number of columns
		n = (total_width - SPACING) / (total_item_width + SPACING);

		debug("ALBUM_VIEW_N_COLS = %i", n);

		if (n > 0)
			icons.set_columns (n);
	}
	*/

	public void buildUI() {
		set_policy(PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);

		icons = new IconView();
		model = new AlbumViewModel(lm, defaultPix);

		// apply css styling
		var style_provider = new CssProvider();

		try  {
			style_provider.load_from_data (ALBUM_VIEW_STYLESHEET, -1);
		} catch (Error e) {
			warning (e.message);
		}

		icons.get_style_context().add_provider(style_provider, STYLE_PROVIDER_PRIORITY_APPLICATION);

		icons.set_columns(-1);

		icons.set_pixbuf_column(0);
		icons.set_markup_column(1);
		icons.set_tooltip_column(3);

		icons.item_width = ITEM_WIDTH;
		icons.item_padding = ITEM_PADDING;
		icons.spacing = 2;
		icons.margin = SPACING + ITEM_PADDING;
		icons.row_spacing = SPACING;
		icons.column_spacing = SPACING;

		add(icons);

		show_all();

		icons.button_release_event.connect(buttonReleaseEvent);
		icons.button_press_event.connect(buttonReleaseEvent);
		icons.item_activated.connect(itemActivated);
	}

	public void set_hint(ViewWrapper.Hint hint) {
		// nothing
	}

	public ViewWrapper.Hint get_hint() {
		return parent_view_wrapper.hint;
	}

	public void set_show_next(Collection<int> medias) {
		_show_next = medias;
	}

	public void set_relative_id(int id) {
		// do nothing
	}

	public int get_relative_id() {
		return 0;
	}

	public Collection<int> get_medias() {
		return medias.keys;
	}

	public Collection<int> get_showing_medias() {
		return _showing_medias.keys;
	}

	// Unused. Doesn't apply
	public void set_as_current_list(int media_id, bool is_initial = false) {
		//nothing to do
	}

	public void set_statusbar_info() {
		parent_view_wrapper.set_statusbar_info ();
	}

	public void append_medias(Collection<int> new_medias) {
		var to_append = new LinkedList<Media>();

		foreach(int i in new_medias) {
			Media s = lm.media_from_id(i);
			string key = s.album_artist + s.album;

			if(medias.get(key) == null)
				medias.set(key, new LinkedList<int>());
			if(_showing_medias.get(key) == null) {
				_showing_medias.set(key, new LinkedList<int>());

				Media alb = new Media("");
				alb.album_artist = s.album_artist;
				alb.album = s.album;
				to_append.add(alb);
			}

			_showing_medias.get(key).add(i);
			medias.get(key).add(i);
		}

		model.appendMedias(to_append, true);
		model.resort();
		queue_draw();
	}

	public void remove_medias(Collection<int> to_remove) {
		var medias_remove = new LinkedList<Media>();

		foreach(int i in to_remove) {
			Media s = lm.media_from_id(i);
			if(s == null)
				continue;

			string key = s.album_artist + s.album;
			if(key == null)
				continue;

			if(medias.get(key) != null) {
				medias.get(key).remove(i);
				if(medias.get(key).size == 0)
					medias.unset(key);
			}
			if(_showing_medias.get(key) != null) {
				_showing_medias.get(key).remove(i);
				if(_showing_medias.get(key).size == 0) {
					medias.unset(key);

					Media alb = new Media("");
					alb.album_artist = s.album_artist;
					alb.album = s.album;
					medias_remove.add(alb);
				}
			}
		}

		model.removeMedias(medias_remove, true);
		queue_draw();
	}

	/**
	 * Goes through the hashmap and generates html. If artist,album, or genre
	 * is set, makes sure that only items that fit those filters are
	 * shown
	 **/
	public void populate_view() {
		icons.freeze_child_notify();
		icons.set_model(null);

		_showing_medias.clear();
		var to_append = new LinkedList<Media>();
		foreach(int i in _show_next) {
			Media s = lm.media_from_id(i);
			string key = s.album_artist + s.album;

			if(medias.get(key) == null)
				medias.set(key, new LinkedList<int>());
			if(_showing_medias.get(key) == null) {
				_showing_medias.set(key, new LinkedList<int>());

				Media alb = new Media("");
				alb.album_artist = s.album_artist;
				alb.album = s.album;
				to_append.add(alb);
			}

			_showing_medias.get(key).add(i);
			medias.get(key).add(i);
		}

		model = new AlbumViewModel(lm, defaultPix);
		model.appendMedias(to_append, false);
		model.set_sort_column_id(0, SortType.ASCENDING);
		icons.set_model(model);
		icons.thaw_child_notify();

		if(visible && lm.media_info.media != null)
			scrollToCurrent();

		needsUpdate = false;
	}

	public void update_medias(Collection<int> medias) {
		// nothing to do
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

		album_list_view.move(x, y);

		album_list_view.show_all();
		album_list_view.present();
	}

	public new void hide () {
		// make sure that the album list view is hidden as well
		album_list_view.hide ();
		
		base.hide ();
	}

	void medias_removed(LinkedList<int> ids) {
		// TODO:
		//model.removeMedias(ids, false);
		//_showing_medias.remove_all(ids);
		//_show_next.remove_all(ids);
	}

	public void scrollToCurrent() {
		if(!visible || lm.media_info.media == null)
			return;

		debug ("scrolling to current\n");

		TreeIter iter;
		model.iter_nth_child(out iter, null, 0);
		while(model.iter_next(ref iter)) {
			Value vs;
			model.get_value(iter, 2, out vs);

			if(icons is IconView && ((Media)vs).album == lm.media_info.media.album) {
				icons.scroll_to_path(model.get_path(iter), false, 0.0f, 0.0f);

				return;
			}
		}
	}
}

