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

public class BeatBox.InfoPanel : ScrolledWindow {
	private LibraryManager lm;
	private LibraryWindow lw;
	private int id; // need this for when rating the media
	
	private Label title;
	private Label artist;
	private Button loveMedia;
	private Button banMedia;
	private Gtk.Image coverArt;
	private RatingWidget rating; // need to make custom widget in future
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
		/* put it in event box so we can color background white */
		EventBox eb = new EventBox();
		
		// add View class
		eb.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);

		eb.set_size_request (Icons.ALBUM_VIEW_IMAGE_SIZE + 6, -1);

		title = new Label("Title");
		artist = new Label("Artist");
		loveMedia = new Button();
		banMedia = new Button();
		coverArt = new Gtk.Image();
		coverArt.set_size_request (Icons.ALBUM_VIEW_IMAGE_SIZE, Icons.ALBUM_VIEW_IMAGE_SIZE);
		rating = new RatingWidget(null, true, IconSize.MENU);
		album = new Label("Album");
		year = new Label("Year");
		ssv = new SimilarMediasView(lm, lw);
		
		/* use markup */
		title.set_markup("<span size=\"large\"><b>%s</b></span>".printf(_("Title")));
		year.set_markup("<span size=\"x-small\">%s</span>".printf(_("Year")));
		
		/* ellipsize */
		title.ellipsize = Pango.EllipsizeMode.END;
		artist.ellipsize = Pango.EllipsizeMode.END;
		album.ellipsize = Pango.EllipsizeMode.END;
		year.ellipsize = Pango.EllipsizeMode.END;
		
		loveMedia.relief = ReliefStyle.NONE;
		banMedia.relief = ReliefStyle.NONE;
		
		var lastfm_love_icon = Icons.LASTFM_LOVE.render (IconSize.MENU);
		var lastfm_ban_icon = Icons.LASTFM_BAN.render (IconSize.MENU);
		
		loveMedia.set_image(new Image.from_pixbuf(lastfm_love_icon));
		banMedia.set_image(new Image.from_pixbuf(lastfm_ban_icon));
		
		HBox padding = new HBox(false, 10);
		VBox content = new VBox(false, 0);
		
		HBox buttons = new HBox(false, 0);
		buttons.pack_start(new Label(""), true, true, 0);
		buttons.pack_start(loveMedia, false, false, 0);
		buttons.pack_end(new Label(""), true, true, 0);
		buttons.pack_end(banMedia, false, false, 0);
		
		content.pack_start(wrap_alignment(title, 5, 0, 0, 5), false, true, 0);
		content.pack_start(wrap_alignment(artist, 2, 0, 0, 5), false, true, 0);
		content.pack_start(buttons, false, true, 0);
		content.pack_start(wrap_alignment(coverArt, 5, 5, 0, 5), false, true, 0);
		content.pack_start(wrap_alignment(rating, 5, 0, 0, 5), false, true, 0);
		content.pack_start(wrap_alignment(album, 5, 0, 0, 5), false, true, 0);
		content.pack_start(wrap_alignment(year, 0, 0, 20, 5), false, true, 0);
		content.pack_start(ssv, true, true, 0);
		
		eb.add(content);
		
		padding.pack_start(eb, true, true, 0);
		
		Viewport vp = new Viewport(null, null);
		vp.set_shadow_type(ShadowType.NONE);
		vp.add(padding);
		
		add(vp);
		
		this.set_policy(PolicyType.NEVER, PolicyType.AUTOMATIC);
		this.set_shadow_type(ShadowType.NONE);
		
		// signals here
		rating.rating_changed.connect(ratingChanged);
		title.button_press_event.connect(titleClicked);
		loveMedia.clicked.connect(loveButtonClicked);
		banMedia.clicked.connect(banButtonClicked);
		
		drag_dest_set(this, DestDefaults.ALL, {}, Gdk.DragAction.MOVE);
		Gtk.drag_dest_add_uri_targets(this);
		this.drag_data_received.connect(dragReceived);

		update_visibilities();
	}
	
	Gtk.Alignment wrap_alignment (Gtk.Widget widget, int top, int right, int bottom, int left) {
		var alignment = new Gtk.Alignment(0.0f, 0.0f, 1.0f, 1.0f);
		alignment.top_padding = top;
		alignment.right_padding = right;
		alignment.bottom_padding = bottom;
		alignment.left_padding = left;
		
		alignment.add(widget);
		return alignment;
	}
	
	public void logged_in_to_lastfm() {
		update_visibilities();
	}

	public void update_visibilities() {
		var lastfm_elements_visible = lm.settings.getLastFMSessionKey() != "";

		loveMedia.set_no_show_all (!lastfm_elements_visible);
		banMedia.set_no_show_all (!lastfm_elements_visible);
		ssv.set_no_show_all (!lastfm_elements_visible);
		loveMedia.set_visible(lastfm_elements_visible);
		banMedia.set_visible(lastfm_elements_visible);
		ssv.set_visible(similars_fetched);
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
		
		title.set_markup("<span size=\"large\"><b>" + s.title.replace("&", "&amp;") + "</b></span>");
		artist.set_text(s.artist);
		album.set_text(s.album);
		
		// do rating stuff
		rating.set_rating((int)s.rating);
		
		if(s.year > 1900)
			year.set_markup("<span size=\"x-small\">" + s.year.to_string() + "</span>");
		else
			year.set_markup("");
	}
	
	void update_cover_art() {
		if(lm.media_from_id(id) == null)
			return;

		var coverart_pixbuf = lm.get_cover_album_art(id);

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
			Thread.create<void*>(() => {
				try {
					GLib.AppInfo.launch_default_for_uri (lm.media_info.track.url, null);
				}
				catch(GLib.Error err) {
					message("Could not open url in Last FM: %s\n", err.message);
				}
				
				return null;
			}, false);
		}
		catch(GLib.ThreadError err) {
			message("Could not create thread to open title:%s\n", err.message);
			
		}
		
		return false;
	}
	
	void loveButtonClicked() {
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
				message("Dragged album art is not valid image\n");
			}
			
			Gtk.drag_finish (context, success, false, timestamp);
			return;
		}
    }
}
