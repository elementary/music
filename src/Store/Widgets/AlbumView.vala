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

public class Store.AlbumView : ScrolledWindow {
	Store.StoreView parent;
	Store.store store;
	private Store.Release release;
	
	private Image albumArt;
	private Gtk.Label albumName;
	private Gtk.Label albumArtist;
	private Gtk.Label releaseDate;
	private VBox priceFlags;
	private Store.TrackList trackList;
	private Store.IconView similarReleases;
	
	private Gdk.Pixbuf defaultPix;
	
	public AlbumView(Store.StoreView view, Store.store s, Release r) {
		parent = view;
		store = s;
		release = r;
		defaultPix = new Gdk.Pixbuf.from_file_at_size(GLib.Path.build_filename("/usr", "share", "icons", "hicolor", "128x128", "mimetypes", "media-audio.svg", null), 128, 128);
		
		buildUI();
	}
	
	public void buildUI() {
		VBox allDetails = new VBox(false, 0);
		HBox topRow = new HBox(false, 0);
		VBox topInfo = new VBox(false, 0);
		VBox topFlags = new VBox(false, 0);
		albumArt = new Image();
		albumName = new Gtk.Label("");
		albumArtist = new Gtk.Label("");
		releaseDate = new Gtk.Label("");
		priceFlags = new VBox(false, 0);
		trackList = new Store.TrackList(parent, "Album");
		similarReleases = new Store.IconView(parent);
		
		topInfo.pack_start(wrap_alignment(albumName, 20, 10, 10, 0), false, true, 0);
		topInfo.pack_start(wrap_alignment(albumArtist, 0, 10, 10, 0), false, true, 0);
		topInfo.pack_start(wrap_alignment(releaseDate, 0, 10, 10, 0), false, true, 0);
		
		topRow.pack_start(wrap_alignment(albumArt, 20, 10, 40, 20), false, true, 0);
		topRow.pack_start(topInfo, true, true, 0);
		topRow.pack_start(priceFlags, false, true, 0);
		
		albumName.xalign = 0.0f;
		albumArtist.xalign = 0.0f;
		releaseDate.xalign = 0.0f;
		
		/* make some 'category' labels */
		var trackListLabel = new Gtk.Label("");
		var similarReleasesLabel = new Gtk.Label("");
		
		trackListLabel.xalign = 0.0f;
		similarReleasesLabel.xalign = 0.0f;
		trackListLabel.set_markup("<span weight=\"bold\" size=\"larger\">Track List</span>");
		similarReleasesLabel.set_markup("<span weight=\"bold\" size=\"larger\">Similar Releases</span>");
		
		// set minimal size for main widgets
		trackList.set_size_request(-1, 250);
		similarReleases.set_size_request(-1, 200);
		
		allDetails.pack_start(topRow, true, true, 0);
		allDetails.pack_start(wrap_alignment(trackListLabel, 0, 00, 10, 20), false, true, 0);
		allDetails.pack_start(wrap_alignment(trackList, 0, 20, 40, 20), true, true, 0);
		allDetails.pack_start(wrap_alignment(similarReleasesLabel, 0, 0, 10, 20), false, true, 0);
		allDetails.pack_start(wrap_alignment(similarReleases, 0, 20, 40, 20), true, true, 0);
		
		/** now fill in with the artist's data **/
		
		add_with_viewport(allDetails);
		
		show_all();
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
	
	public void populate() {
		setAlbum(store.getRelease(release.releaseID));
		
		foreach(var track in release.getTracks()) {
			addTrack(track);
		}
		foreach(var rel in release.getSimilar(1))
			addSimilarRelease(rel);
	}
	
	public void setAlbum(Store.Release release) {
		this.release = release;
		albumName.set_markup("<span weight=\"bold\" font=\"40\">" + release.title.replace("&", "&amp;") + "</span>");
		albumArtist.set_markup("<span font=\"24\">" + release.artist.name.replace("&", "&amp;") + "</span>");
		releaseDate.set_markup("<span font=\"14\">Released " + release.releaseDate.substring(0, 10).replace("-", "/") + "</span>");
		
		Gdk.Pixbuf relImg = Store.store.getPixbuf(release.imagePath, 200, 200);
		if(relImg != null) {
			albumArt.set_from_pixbuf(relImg);
		}
		else
			albumArt.set_from_pixbuf(defaultPix);
	}
	
	public void addTrack(Store.Track track) {
		trackList.addItem(track);
	}
	
	public void addSimilarRelease(Store.Release release) {
		similarReleases.addItem(release);
	}
}
