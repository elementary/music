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
	private SimilarMediasView ssv;
	
	public InfoPanel(LibraryManager lmm, LibraryWindow lww) {
		lm = lmm;
		lw = lww;
		
		buildUI();
		
		lm.medias_updated.connect(medias_updated);
		lm.lfm.logged_in.connect(logged_in_to_lastfm);
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
		this.size_allocate.connect(resized);
		//title.button_press_event.connect(titleClicked);
		loveMedia.clicked.connect(loveButtonClicked);
		banMedia.clicked.connect(banButtonClicked);
		
		drag_dest_set(this, DestDefaults.ALL, {}, Gdk.DragAction.MOVE);
		Gtk.drag_dest_add_uri_targets(this);
		this.drag_data_received.connect(dragReceived);

		setVisibilities();
	}
	
	public static Gtk.Alignment wrap_alignment (Gtk.Widget widget, int top, int right, int bottom, int left) {
		var alignment = new Gtk.Alignment(0.0f, 0.0f, 1.0f, 1.0f);
		alignment.top_padding = top;
		alignment.right_padding = right;
		alignment.bottom_padding = bottom;
		alignment.left_padding = left;
		
		alignment.add(widget);
		return alignment;
	}
	
	public void logged_in_to_lastfm() {
		setVisibilities();
	}

	public void setVisibilities() {
		var lastfm_elements_visible = lm.settings.getLastFMSessionKey() != "";

		loveMedia.set_no_show_all (!lastfm_elements_visible);
		banMedia.set_no_show_all (!lastfm_elements_visible);
		ssv.set_no_show_all (!lastfm_elements_visible);
		loveMedia.set_visible(lastfm_elements_visible);
		banMedia.set_visible(lastfm_elements_visible);
		ssv.set_visible(lastfm_elements_visible);
	}
	
	public void updateMedia(int new_id) {
		id = new_id;
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
		
		updateCoverArt(false);
		ssv.hide();
		
		setVisibilities();
	}
	
	public void updateCoverArt(bool is_initial) {
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
	
	public void updateMediaList(Collection<Media> medias) {
		if(medias.size > 8) {
			ssv.show();
			ssv.populateView(medias);
		}
		else {
			ssv.hide();
		}
	}
	
	public virtual void ratingChanged(int new_rating) {
		lm.media_from_id(id).rating = new_rating;
		lm.update_media(lm.media_from_id(id), false, true);
	}
	
	public virtual void medias_updated(Collection<int> ids) {
		if(ids.contains(lm.media_info.media.rowid))
			rating.set_rating((int)lm.media_info.media.rating);
	}
	
	public virtual void resized(Allocation rectangle) {
		// resize the image to fit
		//coverArt.icon_size = rectangle.width - 10;
		updateCoverArt(false);
	}
	
	/* FIXME: unused code
	public virtual bool titleClicked(Gdk.EventButton event) {
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
	*/
	public virtual void loveButtonClicked() {
		lm.lfm.loveTrack(lm.media_info.media.title, lm.media_info.media.artist);
	}
	
	public virtual void banButtonClicked() {
		lm.lfm.banTrack(lm.media_info.media.title, lm.media_info.media.artist);
	}
	
	private bool is_valid_image_type(string type) {
		var typeDown = type.down();
		
		return (typeDown.has_suffix(".jpg") || typeDown.has_suffix(".jpeg") ||
				typeDown.has_suffix(".png"));
	}
	
	void dragReceived(Gdk.DragContext context, int x, int y, Gtk.SelectionData data, uint info, uint timestamp) {
		message("drag received\n");
		bool success = true;
		
		foreach(string singleUri in data.get_uris()) {
			
			if(is_valid_image_type(singleUri) && lm.media_info.media != null) {
				var original = File.new_for_uri(singleUri);
				var playingPath = File.new_for_uri(lm.media_info.media.uri); // used to get dest
				var dest = File.new_for_path(Path.build_path("/", playingPath.get_parent().get_path(), "Album.jpg"));
				
				// test successful, no block on copy
				if(dest.query_exists()) {
					try {
						dest.delete();
					}
					catch(Error err) {
						message("Could not delete previous file\n");
					}
				}
				
				try {
					original.copy(dest, FileCopyFlags.NONE, null, null);
				}
				catch(Error err) {
					success = false;
					message("Could not copy album art to destination\n");
				}
				
				if(success) {
					// save new pixbuf in memory
					Gdk.Pixbuf? pix = null;
					try {
						pix = new Gdk.Pixbuf.from_file(dest.get_path());
					}
					catch(GLib.Error err) {}
					lm.set_album_art(lm.media_info.media.rowid, pix);
					
					Gee.LinkedList<Media> updated_medias = new Gee.LinkedList<Media>();
					foreach(int id in lm.media_ids()) {
						if(lm.media_from_id(id).artist == lm.media_info.media.artist && lm.media_from_id(id).album == lm.media_info.media.album) {
							lm.media_from_id(id).setAlbumArtPath(dest.get_path());
							updated_medias.add(lm.media_from_id(id));
						}
					}
					
					// wait for everything to finish up and then update the medias
					Timeout.add(2000, () => {
						
						try {
							Thread.create<void*>(lm.fetch_all_cover_art, false);
						}
						catch(GLib.ThreadError err) {
							message("Could not create thread to load media pixbuf's: %s \n", err.message);
						}
						
						lm.update_medias(updated_medias, false, false);
						
						// for sound menu (dbus doesn't like linked lists)
						if(updated_medias.contains(lm.media_info.media))
							lm.update_media(lm.media_info.media, false, false);
						
						return false;
					});
				}
			}
			
			updateCoverArt(true);
			Gtk.drag_finish (context, success, false, timestamp);
			return;
		}
    }
}
