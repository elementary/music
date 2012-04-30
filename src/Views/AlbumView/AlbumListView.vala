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

using Gee;
using Gtk;

#if ENABLE_LIGHT_WINDOW
public class BeatBox.AlbumListView : Granite.Widgets.DecoratedWindow {
#else
public class BeatBox.AlbumListView : Window {
#endif

	public const int WIDTH = 400;
	public const int HEIGHT = 400; 

	LibraryManager lm;
	ViewWrapper view_wrapper;

	Label album_label;
	Label artist_label;
	Granite.Widgets.Rating rating;
	MusicTreeView mtv;

	Gee.LinkedList<Media> media_list;

	Mutex setting_media = new Mutex ();

	public AlbumListView(AlbumView album_view) {
		this.view_wrapper = album_view.parent_view_wrapper;
		this.lm = view_wrapper.lm;

		set_size_request (WIDTH, HEIGHT);
		set_default_size (WIDTH, HEIGHT);

		set_transient_for (lm.lw);
		window_position = Gtk.WindowPosition.CENTER_ON_PARENT;
		this.destroy_with_parent = true;
		set_skip_taskbar_hint (true);
#if !ENABLE_LIGHT_WINDOW
		// window stuff

		set_decorated(false);
		set_has_resize_grip(false);
		set_resizable(false);

		// close button
		var close = new Gtk.Button ();
		close.get_style_context().add_class("close-button");
		close.set_image (Icons.render_image ("window-close-symbolic", Gtk.IconSize.MENU));
		close.hexpand = close.vexpand = false;
		close.halign = Gtk.Align.START;
		close.set_relief(Gtk.ReliefStyle.NONE);
		close.clicked.connect( () =>  { this.hide(); });
#else
		base.get_style_context ().remove_class (Granite.STYLE_CLASS_CONTENT_VIEW);
		base.get_style_context ().remove_class ("content-view-window");
#endif
		// album artist/album labels
		album_label = new Label("Album");
		artist_label = new Label("Artist");

		// Apply special style: Level-2 header
		UI.apply_style_to_label (album_label, UI.TextStyle.H2);

		album_label.ellipsize = Pango.EllipsizeMode.END;
		artist_label.ellipsize = Pango.EllipsizeMode.END;

		album_label.set_line_wrap (false);
		artist_label.set_line_wrap (false);
		
		album_label.set_max_width_chars (30);
		artist_label.set_max_width_chars (30);

		album_label.margin_left = album_label.margin_right = 12;
		artist_label.margin_bottom = 12;

		// Music List
		var tvs = new TreeViewSetup(MusicTreeView.MusicColumn.TRACK, Gtk.SortType.ASCENDING, ViewWrapper.Hint.ALBUM_LIST);
		mtv = new MusicTreeView(view_wrapper, tvs);
		mtv.has_grid_lines = true;

		var mtv_scrolled = new ScrolledWindow (null, null);
		mtv_scrolled.add (mtv);

		// Rating widget
		rating = new Granite.Widgets.Rating (get_style_context(), true, IconSize.MENU, true);
		// customize rating
		rating.set_star_spacing (16);
		rating.margin_top = rating.margin_bottom = 16;

		// Add everything
		var vbox = new Box(Orientation.VERTICAL, 0);
#if !ENABLE_LIGHT_WINDOW
		vbox.pack_start (close, false, false, 0);
#endif
		vbox.pack_start (album_label, false, true, 0);
		vbox.pack_start (artist_label, false, true, 0);
		vbox.pack_start (mtv_scrolled, true, true, 0);
		vbox.pack_start(rating, false, true, 0);

		add(vbox);

		rating.rating_changed.connect(rating_changed);

#if !ENABLE_LIGHT_WINDOW
		this.add_events (Gdk.EventMask.BUTTON_PRESS_MASK | Gdk.EventMask.POINTER_MOTION_MASK);

		lm.lw.viewSelector.mode_changed.connect ( () => {
			this.hide ();
		});

		lm.lw.sideTree.true_selection_change.connect ( () => {
			this.hide ();
		});

		this.button_press_event.connect ( (event) => {
			this.begin_move_drag ((int)event.button, (int)event.x_root,
			                       (int)event.y_root, event.time);
			return true;
		});
#endif
	}

	public void set_songs_from_media(Media m) {
		setting_media.lock ();

		set_title (m.album + " by " + m.album_artist);

		album_label.set_label (m.album);
		artist_label.set_label (m.album_artist);

		var to_search = new LinkedList<Media> ();

		// only search media that match the search filter
		foreach (int id in view_wrapper.get_showing_media_ids ()) {
			to_search.add (lm.media_from_id(id));
		}

		Search.fast_album_search_in_media_list (to_search, out media_list, "", m.album_artist, m.album);

		var media_table = new HashTable<int, Media>(null, null);

		int index = 0;
		// FIXME: this is ugly and can potentially disorder the songs.
		//         This kind of implementation detail should not be relevant here!
		foreach (var _media in media_list) {
			media_table.set (index++, _media);
		}

		mtv.set_table (media_table);

		setting_media.unlock ();

		// Set rating
		update_album_rating ();
		lm.medias_updated.connect (update_album_rating);
	}


	void update_album_rating () {
		// We don't want to set the overall_rating as each media's rating.
		// See rating_changed() in case you want to figure out what would happen.
		rating.rating_changed.disconnect(rating_changed);

		// Use average rating for the album
		int overall_rating = 0, total_rating = 0, n_media = 0;
		foreach(var media in media_list) {
			if (media == null)
				continue;
			n_media ++;
			total_rating += (int)media.rating;
		}

		overall_rating = total_rating / n_media;

		rating.set_rating(overall_rating);

		// connect again ...
		rating.rating_changed.connect(rating_changed);
	}

	void rating_changed(int new_rating) {
		setting_media.lock ();

		var updated = new LinkedList<Media>();
		foreach(var media in media_list) {
			if (media == null)
				continue;

			media.rating = (uint)new_rating;
			updated.add(media);
		}

		setting_media.unlock ();

		lm.update_medias(updated, false, true);
	}
}

