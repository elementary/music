/*-
 * Copyright (c) 2011       Scott Ringwelski <sgringwe@mtu.edu>
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

public class Store.ArtistView : ScrolledWindow {
	Store.StoreView storeView;
	Store.store store;
	private Store.Artist artist;
	private LinkedList<Store.Track> topTracksList;
	private LinkedList<Store.Release> releasesList;
	
	private Image artistImage;
	private Gtk.Label artistName;
	private Gtk.Label upDown;
	private Gtk.Label bio;
	private Store.IconView releases;
	private Store.TrackList topTracks;
	
	private Gdk.Pixbuf defaultPix;
	
	public ArtistView(Store.StoreView view, Store.store s, Artist a) {
		storeView = view;
		store = s;
		artist = a;
		topTracksList = new LinkedList<Store.Track>();
		releasesList = new LinkedList<Store.Release>();
		
		defaultPix = new Gdk.Pixbuf.from_file_at_size(GLib.Path.build_filename("/usr", "share", "icons", "hicolor", "128x128", "mimetypes", "media-audio.svg", null), 100, 100);
				
		buildUI();
		
		setArtist(artist);
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
		releases = new Store.IconView(storeView);
		topTracks = new Store.TrackList(storeView, "Album", true);
		
		artistName.xalign = 0.0f;
		
		artistName.ellipsize = Pango.EllipsizeMode.END;
		
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
		Viewport vp = new Viewport(null, null);
		vp.set_shadow_type(ShadowType.NONE);
		vp.add(allDetails);
		
		add(vp);
		
		show_all();
	}
	
	public void populate() {
		try {
			Thread.create<void*>(setartist_thread_function, false);
			Thread.create<void*>(gettracks_thread_function, false);
			Thread.create<void*>(getreleases_thread_function, false);
			storeView.index = 0;
			storeView.max = 5; // must get to 6 for progress bar to turn off
			storeView.progressNotification();
		}
		catch(GLib.ThreadError err) {
			stdout.printf("ERROR: Could not create thread to get populate ArtistView: %s \n", err.message);
		}
	}
	
	public void* setartist_thread_function () {
		Store.Artist a = store.getArtist(artist.artistID);
		++storeView.index;
		Idle.add( () => { 
			setArtist(a); 
			++storeView.index;
			return false; 
		});
		
		return null;
	}
	
	public void* gettracks_thread_function () {
		foreach(var track in artist.getTopTracks(1, 25))
			topTracksList.add(track);
		++storeView.index;
		Idle.add( () => { 
			foreach(var track in topTracksList)
				topTracks.addItem(track);
			
			++storeView.index;
			return false;
		});
		
		return null;
	}
	
	public void* getreleases_thread_function () {
		foreach(var rel in artist.getReleases("album", 1)) {
			rel.image = Store.store.getPixbuf(rel.imagePath, 100, 100);
			releasesList.add(rel);
		}
			
		++storeView.index;
		
		Idle.add( () => { 
			foreach(var rel in releasesList)
				releases.addItem(rel);
			++storeView.index;
			return false;
		});
		
		return null;
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
		
		if(artist.image == null)
			artist.image = Store.store.getPixbuf(artist.imagePath, 200, 200);
			
		if(artist.image != null) {
			artistImage.set_from_pixbuf(artist.image);
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
