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

public class BeatBox.AlbumListView : Window {

	public const int WIDTH = 350;
	public const int HEIGHT = 400; 

	LibraryManager lm;

	Label album_label;
	Label artist_label;
	RatingWidget rating;
	MusicTreeView mtv;
	bool setting_songs;

	private const string WIDGET_STYLESHEET = """
		.BeatBoxAlbumList {
			background-image: -gtk-gradient (radial, center center, 0,
                                             center center, 1,
			                                 from (#404040),
			                                 color-stop (0.9, alpha (shade (#454545, 1.1), 0.9)),
			                                 to (#404040));
			border-width: 0;
			border-style: none;
			border-radius: 0;
			padding: 0;
		}

		* {
			color: @selected_fg_color;
		}

		GtkTreeView {
			background-color: shade (#414141, 1.01);
		}

		GtkTreeView row {
			border-width: 0;
			border-radius: 0;
			padding: 0;
		}

		GtkTreeView row:nth-child(even) {
			background-color: shade (#3b3b3b, 0.97);
		}

		GtkTreeView row:selected {
			background-image: -gtk-gradient (linear,
			                                 left top,
			                                 left bottom,
			                                 from (shade (@selected_bg_color, 1.30)),
			                                 to (shade (@selected_bg_color, 0.98)));
		}

		.button:hover {
			background-image: -gtk-gradient (linear,
			                                 left top,
			                                 left bottom,
			                                 from (shade (#454545, 1.15)),
			                                 to (shade (#454545, 1.03)));

			-unico-border-gradient: -gtk-gradient (linear,
			                                       left top, left bottom,
			                                       from (shade (#454545, 0.78)),
			                                       to (shade (#454545, 0.60)));
		}

		.button:active,
		.button:active:hover {
			background-image: -gtk-gradient (linear,
			                                 left top,
			                                 left bottom,
			                                 from (shade (#404040, 0.95)),
			                                 to (shade (#404040, 1.13)));

			-unico-border-gradient: -gtk-gradient (linear,
			                                       left top, left bottom,
			                                       from (shade (#404040, 0.78)),
			                                       to (shade (#454545, 0.60)));
		}
	""";

	public AlbumListView(LibraryManager lm) {
		this.lm = lm;

		set_transient_for(lm.lw);
		window_position = Gtk.WindowPosition.CENTER_ON_PARENT;
		set_decorated(false);
		set_has_resize_grip(false);
		set_resizable(false);
		set_skip_taskbar_hint(true);
		this.destroy_with_parent = true;
		set_title("Album List");
		set_size_request(WIDTH, HEIGHT);
		set_default_size(WIDTH, HEIGHT);

		// apply css styling
		var style_provider = new CssProvider();

		try  {
			style_provider.load_from_data (WIDGET_STYLESHEET, -1);
		} catch (Error e) {
			warning ("AlbumListView: %s", e.message);
		}

		get_style_context().add_class("BeatBoxAlbumList");
		get_style_context().add_provider(style_provider, STYLE_PROVIDER_PRIORITY_THEME);

		// add close button
		var close = new Gtk.Button ();
		close.set_image (Icons.render_image ("gtk-close", Gtk.IconSize.MENU));
		close.hexpand = close.vexpand = false;
		close.halign = Gtk.Align.START;
		close.set_relief(Gtk.ReliefStyle.NONE);
		close.clicked.connect( () =>  { this.hide(); });

		// add album artist/album labels
		album_label = new Label("Album");
		artist_label = new Label("Artist");
		album_label.ellipsize = Pango.EllipsizeMode.END;
		artist_label.ellipsize = Pango.EllipsizeMode.END;
		album_label.set_max_width_chars(35);
		artist_label.set_max_width_chars(35);

		// add actual list
		mtv = new MusicTreeView(lm, lm.lw, "Artist", SortType.ASCENDING, ViewWrapper.Hint.ALBUM_LIST, -1);
		mtv.apply_style_to_view(style_provider);
		//mtv.get_style_context().add_class("ListView");
		mtv.vexpand = true;

		// add rating
		rating = new RatingWidget(get_style_context(), true, IconSize.BUTTON, true);
		rating.set_transparent (true);

		var all_area = new Box(Orientation.VERTICAL, 0);
		all_area.pack_start(close, false, false, 0);
		all_area.pack_start(album_label, false, true, 0);
		all_area.pack_start(artist_label, false, true, 3);
		all_area.pack_start(mtv, true, true, 6);
		all_area.pack_start(rating, false, true, 12);

		add(all_area);

		rating.rating_changed.connect(rating_changed);
		this.focus_out_event.connect(focus_out);
	}

	public void set_songs_from_media(Media m) {
		setting_songs = true;
		album_label.set_markup("<span size=\"large\" color=\"#ffffff\"><b>" + m.album.replace("&", "&amp;") + "</b></span>");
		artist_label.set_markup("<span color=\"#ffffff\"><b>" + m.album_artist.replace("&", "&amp;") + "</b></span>");

		var songs = new LinkedList<int>();
		var albums = new LinkedList<int>();
		lm.do_search("", ((ViewWrapper)lm.lw.sideTree.getSelectedWidget()).hint, m.album_artist, m.album,
		((ViewWrapper)lm.lw.sideTree.getSelectedWidget()).get_media_ids(), ref songs, ref albums);

		// decide rating. unless all are equal, show 0.
		int overall_rating = -1;
		foreach(int i in songs) {
			if(overall_rating == -1)
				overall_rating = (int)lm.media_from_id(i).rating;
			else if(lm.media_from_id(i).rating != overall_rating) {
				overall_rating = 0;
				break;
			}
		}
		rating.set_rating(overall_rating);

		mtv.set_show_next(songs);
		mtv.populate_view();
		setting_songs = false;
	}

	void rating_changed(int new_rating) {
		if(setting_songs)
			return;

		var updated = new LinkedList<Media>();
		foreach(int i in mtv.get_medias()) {
			lm.media_from_id(i).rating = new_rating;
			updated.add(lm.media_from_id(i));
		}

		lm.update_medias(updated, false, true);
	}

	bool focus_out(Gdk.EventFocus event) {
		//this.hide();

		return false;
	}
}

