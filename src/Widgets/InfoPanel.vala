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
	private int id; // need this for when rating the media

	private ScrolledWindow scroll;
	
	private Label title;
	private Label artist;
	private Button loveMedia;
	private Button banMedia;
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
		lm.medias_updated.connect(medias_updated);
		lm.media_played.connect(media_played);
		lm.lfm.logged_in.connect(logged_in_to_lastfm);
		lm.lfm.similar_retrieved.connect(similar_retrieved);
	}
	
	private void buildUI() {

		// add View class
		this.get_style_context ().add_class (Granite.STYLE_CLASS_CONTENT_VIEW);

		title = new Label("");
		artist = new Label("");
		loveMedia = new Button();
		banMedia = new Button();
		coverArt = new Gtk.Image();
		coverArt.set_size_request (Icons.ALBUM_VIEW_IMAGE_SIZE, Icons.ALBUM_VIEW_IMAGE_SIZE);
		rating = new Granite.Widgets.Rating (null, true, IconSize.MENU); // centered = true
		album = new Label("");
		year = new Label("");
		ssv = new SimilarMediasView(lm, lw);

		/* ellipsize */
		title.ellipsize = Pango.EllipsizeMode.END;
		artist.ellipsize = Pango.EllipsizeMode.END;
		album.ellipsize = Pango.EllipsizeMode.END;
		year.ellipsize = Pango.EllipsizeMode.END;
		
		loveMedia.set_image (Icons.LASTFM_LOVE.render_image (IconSize.MENU));
		banMedia.set_image (Icons.LASTFM_BAN.render_image (IconSize.MENU));
		
		var content = new Box (Orientation.VERTICAL, 0);

		// margins
		content.margin_left = content.margin_right = 6;

		var buttons = new ButtonBox (Orientation.HORIZONTAL);
		buttons.pack_start (loveMedia, false, false, 0);
		buttons.pack_end (banMedia, false, false, 0);

		// put treeview inside scrolled window		
		scroll = new ScrolledWindow (null, null);
		scroll.set_policy (PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
		scroll.add (ssv);

		buttons.halign = coverArt.halign = Gtk.Align.CENTER;
		title.halign = artist.halign = album.halign = year.halign = Gtk.Align.CENTER;

		// expand so that the rating can be set within the whole width.
		// The widget centers itself.
		rating.halign = Gtk.Align.FILL;

		coverArt.margin_top = 6;
		buttons.margin_top = 0;
		title.margin_top = 6;
		rating.margin_top = 6;
		artist.margin_top = 6;
		album.margin_top = 0;
		year.margin_top = 3;

		scroll.margin_top = 12;

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
		loveMedia.clicked.connect (lovthisuttonClicked);
		banMedia.clicked.connect (banButtonClicked);

		drag_dest_set(this, DestDefaults.ALL, {}, Gdk.DragAction.MOVE);
		Gtk.drag_dest_add_uri_targets(this);
		this.drag_data_received.connect(dragReceived);

		update_visibilities();
	}
	
	public void logged_in_to_lastfm() {
		update_visibilities();
	}

	public void update_visibilities() {
		var lastfm_elements_visible = lm.settings.getLastFMSessionKey() != "";

		loveMedia.set_no_show_all (!lastfm_elements_visible);
		banMedia.set_no_show_all (!lastfm_elements_visible);
		ssv.set_no_show_all (!lastfm_elements_visible);
		loveMedia.set_visible (lastfm_elements_visible);
		banMedia.set_visible (lastfm_elements_visible);
		ssv.set_visible (similars_fetched);
	}

	void media_played(int id, int old) {
		if(lm.media_info.media.isPreview)
			return;
		
		this.id = id;
		
		update_metadata ();
		update_cover_art ();
		update_visibilities ();
		
		similars_fetched = false;
	}
	
	void medias_updated(Collection<int> ids) {
		if(ids.contains(id)) {
			update_metadata ();
			update_cover_art ();
			update_visibilities ();
		}
	}
	
	void update_metadata() {
		Media s = lm.media_from_id(id);
		
		title.set_markup("<span size=\"large\"><b>" + Markup.escape_text (s.title, -1) + "</b></span>");
		artist.set_text(s.artist);
		album.set_text(s.album);

		// do rating stuff
		rating.set_rating((int)s.rating);

		if(s.year > 1900)
			year.set_markup("<span size=\"x-small\">" + Markup.escape_text ("(%d)".printf ((int)s.year), -1) + "</span>");
		else
			year.set_markup("");
	}
	
	void update_cover_art() {
		if(lm.media_from_id(id) == null)
			return;

		var coverart_pixbuf = lm.get_cover_album_art(id);

		if (coverart_pixbuf == null)
			coverart_pixbuf = lm.get_pixbuf_shadow (Icons.DEFAULT_ALBUM_ART_PIXBUF);

		if(coverart_pixbuf != null) {
			coverArt.show();
			coverArt.set_from_pixbuf(coverart_pixbuf);
		}
		else {
			coverArt.hide();
		}
	}
	
	void similar_retrieved(LinkedList<int> similar_internal, LinkedList<Media> similar_external) {
		update_similar_list(similar_external);
	}
	
	public void update_similar_list(Collection<Media> medias) {
		if(medias.size > 8) {
			similars_fetched = true;
			ssv.populateView(medias);
		}
		
		update_visibilities ();
	}
	
	void ratingChanged(int new_rating) {
		lm.media_from_id(id).rating = new_rating;
		lm.update_media(lm.media_from_id(id), false, true);
	}
	
	bool titleClicked(Gdk.EventButton event) {
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
	
	void lovthisuttonClicked() {
		lm.lfm.loveTrack(lm.media_info.media.title, lm.media_info.media.artist);
	}
	
	void banButtonClicked() {
		lm.lfm.banTrack(lm.media_info.media.title, lm.media_info.media.artist);
	}
	
	bool is_valid_image_type(string type) {
		var typeDown = type.down();
		
		return (typeDown.has_suffix(".jpg") || typeDown.has_suffix(".jpeg") ||
				typeDown.has_suffix(".png"));
	}
	
	void dragReceived(Gdk.DragContext context, int x, int y, Gtk.SelectionData data, uint info, uint timestamp) {
		bool success = true;
		
		foreach(string uri in data.get_uris()) {
			
			if(is_valid_image_type(uri) && lm.media_info.media != null) {
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
