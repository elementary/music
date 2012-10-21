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

public class Noise.GridView : ContentView, GridLayout {

    private string TEXT_MARKUP = @"%s\n<span foreground=\"#999\">%s</span>";
    private string TOOLTIP_MARKUP = @"<span size=\"large\"><b>%s</b></span>\n%s";

	// The window used to present album contents
    private static PopupListView? _popup = null;
	public PopupListView popup_list_view {
		get {
			if (_popup == null) {
				_popup = new PopupListView (this);
				_popup.focus_out_event.connect ( () => {
					if (_popup.visible && lw.has_focus) {
						_popup.show_all ();
						_popup.present ();
					}
					return false;
				});
			}

			return _popup;
		}
	}

	// album-key / album-media
	Gee.HashMap<string, Gee.HashMap<Media, int>> album_info;

	private LibraryManager lm;
	private LibraryWindow lw;

	public GridView (ViewWrapper view_wrapper) {
        base (view_wrapper);

		lm = view_wrapper.lm;
		lw = view_wrapper.lw;

		album_info = new Gee.HashMap<string, Gee.HashMap<Media, int>> ();

		build_ui ();

        CoverartCache.instance.changed.connect (queue_draw);
	}

	public void build_ui () {
		var focus_blacklist = new Gee.LinkedList<Gtk.Widget> ();
		focus_blacklist.add (lw.viewSelector);
		focus_blacklist.add (lw.searchField);
		focus_blacklist.add (lw.sideTree);
		focus_blacklist.add (lw.statusbar);

		lw.viewSelector.mode_changed.connect ( () => {
			popup_list_view.hide ();
		});

		foreach (var w in focus_blacklist) {
			w.add_events (Gdk.EventMask.BUTTON_PRESS_MASK);
			w.button_press_event.connect ( () => {
				popup_list_view.hide ();
				return false;
			});
		}

	}

	public ViewWrapper.Hint get_hint() {
		return parent_view_wrapper.hint;
	}

	public Gee.Collection<Media> get_visible_media () {
		var media_list = new Gee.LinkedList<Media> ();
		foreach (var o in get_visible_objects ()) {
            var m = o as Media;
            if (m != null)
    			media_list.add (m);
        }

		return media_list;
	}

	public Gee.Collection<Media> get_media () {
		var media_list = new Gee.LinkedList<Media> ();
		foreach (var o in get_objects ()) {
            var m = o as Media;
            if (m != null)
    			media_list.add (m);
        }

		return media_list;
	}

	private string get_key (Media? m) {
		return (m != null) ? m.album_artist + m.album : "";
	}

	public void set_media (Gee.Collection<Media> to_add, Cancellable? cancellable = null) {
		album_info = new Gee.HashMap<string, Gee.HashMap<Media, int>> ();
        clear_objects ();
		add_media (to_add, cancellable);
	}

	// checks for duplicates
	public void add_media (Gee.Collection<Media> media, Cancellable? cancellable = null) {
		var to_append = new Gee.HashMap<string, Media> ();
		foreach (var m in media) {
            if (Utils.is_cancelled (cancellable))
                return;

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

        if (!Utils.is_cancelled (cancellable))
    		add_objects (to_append.values, cancellable);
	}

	public void remove_media (Gee.Collection<Media> to_remove, Cancellable? cancellable = null) {
		/* There is a special case. Let's say that we're removing
		 * song1, song2 and song5 from Album X, and the album currently
		 * contains song1, song2, song5, and song3. Then we shouldn't remove
		 * the album because it still contains a song (song3).
		 */

		// classify media by album
		var to_remove_album_info = new Gee.HashMap <string, Gee.LinkedList<Media>> ();
		foreach (var m in to_remove) {
            if (Utils.is_cancelled (cancellable))
                return;

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
            if (Utils.is_cancelled (cancellable))
                return;

			if (album_info.has_key (album_key)) {
				// get current media list
				var current_media = album_info.get (album_key);

				// get list of media that should be removed
				var to_remove_media = to_remove_album_info.get (album_key);

				foreach (var m in to_remove_media) {
                    if (Utils.is_cancelled (cancellable))
                        return;
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
            if (Utils.is_cancelled (cancellable))
                return;

			var key = get_key (album_representation);
			if (albums_to_remove.has_key (key))
				objects_to_remove.set (album_representation, 1);
		}

        if (!Utils.is_cancelled (cancellable))
    		remove_objects (objects_to_remove, cancellable);
	}

	public int get_relative_id () {
		return -1;
	}

	protected override void item_activated (Object? object) {
		if (!lw.initialization_finished)
			return;

		if (object == null) {
			popup_list_view.hide ();
			return;
		}

		var s = object as Media;
        return_if_fail (s != null);

		popup_list_view.set_parent_wrapper (this.parent_view_wrapper);
		popup_list_view.set_media (album_info.get (get_key (s)).keys);

		// find window's location
		int x, y;
		Gtk.Allocation alloc;
		lm.lw.get_position (out x, out y);
		get_allocation (out alloc);

		// move down to icon view's allocation
		x += lm.lw.main_hpaned.position;
		y += alloc.y;

		int window_width = 0;
		int window_height = 0;
		
		popup_list_view.get_size (out window_width, out window_height);

		// center it on this icon view
		x += (alloc.width - window_width) / 2;
		y += (alloc.height - window_height) / 2 + 60;

		bool was_visible = popup_list_view.visible;
		popup_list_view.show_all ();
		if (!was_visible)
			popup_list_view.move (x, y);
		popup_list_view.present ();
	}

	protected override Value? val_func (int row, int column, Object o) {
		var s = o as Media;

        return_val_if_fail (s != null, null);

        switch (column) {
            case Column.PIXBUF:
                return CoverartCache.instance.get_cover (s);

            case Column.MARKUP:
			    string album = s.get_display_album ();
			    string artist = s.get_display_album_artist ();

			    if (album.length > 25)
				    album = s.album.substring (0, 21) + "...";
			    if (artist.length > 25)
				    artist = artist.substring (0, 21) + "...";

			    return Markup.printf_escaped (TEXT_MARKUP, album, artist);

		    case Column.TOOLTIP:
			    return Markup.printf_escaped (TOOLTIP_MARKUP, s.get_display_album (), s.get_display_album_artist ());
        }

		assert_not_reached ();
	}

	protected override int compare_func (Object o_a, Object o_b) {
		var media_a = o_a as Media;
		var media_b = o_b as Media;

        return_val_if_fail (media_a != null && media_b != null, 0);

        string album_a = media_a.get_display_album ();
        string album_b = media_b.get_display_album ();

        int order = String.compare (album_a, album_b);

		if (order == 0)
			order = String.compare (media_a.get_display_album_artist (), media_b.get_display_album_artist ());

        return order;
	}
}
