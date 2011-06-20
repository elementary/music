/*-
 * Copyright (c) 2011       Scott Ringwelski <sgringwe@mtu.edu>
 *
 * Originaly Written by Scott Ringwelski for BeatBox Music Player
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

public class Store.ArtistView : ScrolledWindow {
	Store.StoreView parent;
	Store.store store;
	private Store.Artist artist;
	
	private Image artistImage;
	private Gtk.Label artistName;
	private Gtk.Label upDown;
	private Gtk.Label bio;
	private Store.IconView releases;
	private Store.TrackList topTracks;
	
	private Gdk.Pixbuf defaultPix;
	
	public ArtistView(Store.StoreView view, Store.store s, Artist a) {
		parent = view;
		store = s;
		artist = a;
		defaultPix = new Gdk.Pixbuf.from_file_at_size(GLib.Path.build_filename("/usr", "share", "icons", "hicolor", "128x128", "mimetypes", "media-audio.svg", null), 128, 128);
				
		buildUI();
	}
	
	public void buildUI() {
		VBox allDetails = new VBox(false, 0);
		HBox topRow = new HBox(false, 0);
		VBox topInfo = new VBox(false, 0);
		VBox topFlags = new VBox(false, 0);
		artistImage = new Image();
		artistName = new Gtk.Label("");
		upDown = new Gtk.Label("");
		bio = new Gtk.Label("");
		releases = new Store.IconView(parent);
		topTracks = new Store.TrackList(parent, "Album");
		
		artistName.xalign = 0.0f;
		
		topInfo.pack_start(wrap_alignment(artistName, 20, 10, 10, 0), false, true, 0);
		topInfo.pack_start(bio, true, true, 0);
		
		topRow.pack_start(wrap_alignment(artistImage, 20, 10, 40, 20), false, true, 0);
		topRow.pack_start(topInfo, true, true, 0);
		
		/* make some 'category' labels */
		var releasesLabel = new Gtk.Label("");
		var topTracksLabel = new Gtk.Label("");
		
		releasesLabel.xalign = 0.0f;
		topTracksLabel.xalign = 0.0f;
		releasesLabel.set_markup("<span weight=\"bold\" size=\"larger\">Releases</span>");
		topTracksLabel.set_markup("<span weight=\"bold\" size=\"larger\">Top Tracks</span>");
		
		// set minimal size for main widgets
		releases.set_size_request(-1, 200);
		topTracks.set_size_request(-1, 250);
		
		allDetails.pack_start(topRow, true, true, 0);
		allDetails.pack_start(wrap_alignment(topTracksLabel, 0, 0, 10, 20), false, true, 0);
		allDetails.pack_start(wrap_alignment(topTracks, 0, 20, 40, 20), true, true, 0);
		allDetails.pack_start(wrap_alignment(releasesLabel, 0, 0, 10, 20), false, true, 0);
		allDetails.pack_start(wrap_alignment(releases, 0, 20, 40, 20), true, true, 0);
		
		/** now fill in with the artist's data **/
		
		
		add_with_viewport(allDetails);
		
		show_all();
	}
	
	public void populate() {
		setArtist(store.getArtist(artist.artistID));
		
		foreach(var track in artist.getTopTracks(1))
			topTracks.addItem(track);
		foreach(var rel in artist.getReleases(null, 1))
			releases.addItem(rel);
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
	
	public void setArtist(Store.Artist artist) {
		this.artist = artist;
		artistName.set_markup("<span weight=\"bold\" font=\"40\">" + artist.name.replace("&", "&amp;") + "</span>");
		
		Gdk.Pixbuf artistImg = Store.store.getPixbuf(artist.imagePath, 200, 200);
		if(artistImg != null) {
			stdout.printf("booya\n");
			artistImage.set_from_pixbuf(artistImg);
		}
		else
			artistImage.set_from_pixbuf(defaultPix);
		
	}
	
	public void addTopTrack(Store.Track track) {
		topTracks.addItem(track);
	}
	
	public void addRelease(Store.Release release) {
		releases.addItem(release);
	}
	
	public void addSimilarArtist(Store.Artist artist) {
		
	}
	
	public void addTag(Store.Tag tag) {
		
	}
}
