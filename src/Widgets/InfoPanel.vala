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

public class BeatBox.InfoPanel : Gtk.EventBox {
	private LibraryManager lm;
	private LibraryWindow lw;

	private Gtk.ScrolledWindow scroll;
	
	private Label title;
	private Label artist;
	private Button love_button;
	private Button ban_button;
	private Gtk.Image coverArt;
	private Granite.Widgets.Rating rating;
	private Label album;
	private Label year;
	
	bool similars_fetched;
	private SimilarMediasView ssv;

	public InfoPanel(LibraryManager lmm, LibraryWindow lww) {
		lm = lmm;
		lw = lww;

		buildUI();

		similars_fetched = false;

		lm.media_updated.connect (on_media_updated);
		lm.media_played.connect (on_media_played);

		// Last.fm
		lm.lfm.logged_in.connect (logged_in_to_lastfm);
		lm.lfm.similar_retrieved.connect (similar_retrieved);
	}
	
	private void buildUI() {

		// add View class
		this.get_style_context ().add_class (Granite.STYLE_CLASS_CONTENT_VIEW);

		title = new Label("");
		artist = new Label("");
		love_button = new Button();
		ban_button = new Button();
		coverArt = new Gtk.Image();
		coverArt.set_size_request (Icons.ALBUM_VIEW_IMAGE_SIZE, Icons.ALBUM_VIEW_IMAGE_SIZE);
		rating = new Granite.Widgets.Rating (true, IconSize.MENU); // centered = true
		album = new Label("");
		year = new Label("");
		ssv = new SimilarMediasView(lm, lw);

		/* ellipsize */
		title.ellipsize = Pango.EllipsizeMode.END;
		artist.ellipsize = Pango.EllipsizeMode.END;
		album.ellipsize = Pango.EllipsizeMode.END;
		year.ellipsize = Pango.EllipsizeMode.END;
		
		love_button.set_image (Icons.LASTFM_LOVE.render_image (IconSize.MENU));
		ban_button.set_image (Icons.LASTFM_BAN.render_image (IconSize.MENU));

		love_button.halign = ban_button.halign = Gtk.Align.CENTER;

		var content = new Box (Orientation.VERTICAL, 0);

		// margins
		content.margin = 12;

		var buttons = new ButtonBox (Orientation.HORIZONTAL);
		buttons.pack_start (love_button, false, false, 0);
		buttons.pack_end (ban_button, false, false, 0);

		// put treeview inside scrolled window		
		scroll = new ScrolledWindow (null, null);
		scroll.set_policy (PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
		scroll.add (ssv);

		buttons.halign = coverArt.halign = Gtk.Align.CENTER;
		title.halign = artist.halign = album.halign = year.halign = Gtk.Align.CENTER;

		// expand so that the rating can be set within the whole width.
		// The widget centers itself.
		rating.halign = Gtk.Align.FILL;

		title.margin_top = 6;
		rating.margin_top = 6;
		artist.margin_top = 6;
		album.margin_top = 0;
		year.margin_top = 3;

		content.pack_start (buttons, false, true, 0);
		content.pack_start (coverArt, false, true, 0);
		content.pack_start (title, false, true, 0);
		content.pack_start (rating, false, true, 0);
		content.pack_start (artist, false, true, 0);
		content.pack_start (album, false, true, 0);
		content.pack_start (year, false, true, 0);

		var outer_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
		outer_box.pack_start (content, false, false, 0);
		outer_box.pack_end (scroll, true, true, 0);

		this.add (outer_box);

		// signals here
		rating.rating_changed.connect (ratingChanged);
		title.button_press_event.connect (titleClicked);
		love_button.clicked.connect (love_button_clicked);
		ban_button.clicked.connect (ban_button_clicked);

		drag_dest_set(this, DestDefaults.ALL, {}, Gdk.DragAction.MOVE);
		Gtk.drag_dest_add_uri_targets(this);
		this.drag_data_received.connect(dragReceived);

		update_visibilities();
	}
	
	private void logged_in_to_lastfm() {
		update_visibilities();
	}

	private void update_visibilities() {
	    var lastfm_settings = new LastFM.Settings ();
		var lastfm_elements_visible = lastfm_settings.session_key != "";

		love_button.set_no_show_all (!lastfm_elements_visible);
		ban_button.set_no_show_all (!lastfm_elements_visible);

		love_button.set_visible (lastfm_elements_visible);
		ban_button.set_visible (lastfm_elements_visible);

		scroll.set_no_show_all (!similars_fetched);
		if (similars_fetched)
			scroll.show_all ();
		else
			scroll.hide ();

		// Don't show rating for external media
		bool hide_rating = lm.media_info.media.isTemporary;
		rating.set_no_show_all (hide_rating);
		rating.set_visible (!hide_rating);
	}

	private void on_media_played () {
		update_metadata ();
		update_cover_art ();
		similars_fetched = false;
		update_visibilities ();
	}
	
	private void on_media_updated () {
		update_metadata ();
		update_cover_art ();
		update_visibilities ();
	}
	
	private void update_metadata() {
		if (lm.media_info == null || lm.media_info.media == null)
			return;

		title.set_markup("<span size=\"large\"><b>" + String.escape (lm.media_info.media.title) + "</b></span>");
		artist.set_text(lm.media_info.media.artist);
		album.set_text(lm.media_info.media.album);

		// do rating stuff
		rating.set_rating((int)lm.media_info.media.rating);

		if(lm.media_info.media.year > 1900)
			year.set_markup("<span size=\"x-small\">" + String.escape ("(%d)".printf ((int)lm.media_info.media.year)) + "</span>");
		else
			year.set_markup("");
	}
	
	private void update_cover_art() {
		if (lm.media_info == null || lm.media_info.media == null)
			return;

		var coverart_pixbuf = lm.get_cover_album_art (lm.media_info.media.rowid);

		if (coverart_pixbuf == null)
			coverart_pixbuf = lm.get_pixbuf_shadow (Icons.DEFAULT_ALBUM_ART_PIXBUF);

		// This is not dumb. We're just checking for nullity again
		if(coverart_pixbuf != null) {
			coverArt.show();
			coverArt.set_from_pixbuf(coverart_pixbuf);
		}
		else {
			coverArt.hide();
		}
	}
	
	private void similar_retrieved (LinkedList<int> similar_internal, LinkedList<Media> similar_external) {
		update_similar_list(similar_external);
	}

	public void update_similar_list (Collection<Media> media) {
		if (media.size > 8) {
			similars_fetched = true;
			ssv.populateView (media);
		}
		
		update_visibilities ();
	}
	
	private void ratingChanged(int new_rating) {
		if (lm.media_info == null || lm.media_info.media == null)
			return;

		lm.media_info.media.rating = new_rating;
		lm.update_media_item (lm.media_info.media, false, true);
	}
	
	private bool titleClicked(Gdk.EventButton event) {
		if (lm.media_info == null || lm.media_info.media == null)
			return false;

		try {
			new Thread<void*>.try (null, () => {
				try {
					GLib.AppInfo.launch_default_for_uri (lm.media_info.track.url, null);
				}
				catch(GLib.Error err) {
					warning ("Could not open url in Last FM: %s\n", err.message);
				}
				
				return null;
			});
		}
		catch(GLib.Error err) {
			warning ("Could not create thread to open title:%s\n", err.message);
			
		}
		
		return false;
	}
	
	private void love_button_clicked() {
		if (lm.media_info == null || lm.media_info.media == null)
			return;

		lm.lfm.loveTrack(lm.media_info.media.title, lm.media_info.media.artist);
	}

	private void ban_button_clicked() {
		if (lm.media_info == null || lm.media_info.media == null)
			return;

		lm.lfm.banTrack(lm.media_info.media.title, lm.media_info.media.artist);
	}
	
	// FIXME: MOVE TO UTILS!
	private bool is_valid_image_type(string type) {
		var typeDown = type.down();
		
		return (typeDown.has_suffix(".jpg") || typeDown.has_suffix(".jpeg") ||
				typeDown.has_suffix(".png"));
	}
	
	private void dragReceived(Gdk.DragContext context, int x, int y, Gtk.SelectionData data, uint info, uint timestamp) {
		if (lm.media_info == null || lm.media_info.media == null)
			return;

		bool success = true;
		
		foreach(string uri in data.get_uris()) {
			
			if(is_valid_image_type(uri)) {
				message("Saving dragged album art as image\n");
				lm.save_album_locally(lm.media_info.media.rowid, uri);
			}
			else {
				warning ("Dragged album art is not valid image\n");
			}
			
			Gtk.drag_finish (context, success, false, timestamp);
			return;
		}
    }
}
