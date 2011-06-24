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
using Gee;

public class Store.AlbumView : ScrolledWindow {
	Store.StoreView parent;
	Store.store store;
	private Store.Release release;
	private LinkedList<Store.Track> tracksListList;
	private LinkedList<Store.Release> similarReleasesList;
	
	private Image albumArt;
	private Gtk.Label albumName;
	private Gtk.Label albumArtist;
	private TagLabel viewArtist;
	private TagLabel purchase;
	private Gtk.Label releaseDate;
	private HBox priceFlags;
	private Store.TrackList trackList;
	private Store.IconView similarReleases;
	
	private Gdk.Pixbuf defaultPix;
	
	public AlbumView(Store.StoreView view, Store.store s, Release r) {
		parent = view;
		store = s;
		release = r;
		tracksListList = new LinkedList<Store.Track>();
		similarReleasesList = new LinkedList<Store.Release>();
		
		defaultPix = new Gdk.Pixbuf.from_file_at_size(GLib.Path.build_filename("/usr", "share", "icons", "hicolor", "128x128", "mimetypes", "media-audio.svg", null), 100, 100);
		
		buildUI();
		
		setAlbum(release);
	}
	
	public void buildUI() {
		VBox allDetails = new VBox(false, 0);
		HBox topRow = new HBox(false, 0);
		VBox topInfo = new VBox(false, 0);
		VBox topFlags = new VBox(false, 0);
		HBox splitter = new HBox(false, 0);
		VBox leftSide = new VBox(false, 0);
		VBox rightSide = new VBox(false, 0);
		
		albumArt = new Image();
		albumName = new Gtk.Label("");
		albumArtist = new Gtk.Label("");
		
		Gdk.Color blue, lightblue, white;
		Gdk.Color.parse("#366C9F", out blue);
		Gdk.Color.parse("#E8EEF5", out lightblue);
		Gdk.Color.parse("#ffffff", out white);
		viewArtist = new TagLabel("View Artist", blue, lightblue, white, release.artist, true);
		purchase = new TagLabel("Purchase Release", blue, lightblue, white, release, true);
		
		releaseDate = new Gtk.Label("");
		priceFlags = new HBox(false, 0);
		trackList = new Store.TrackList(parent, "Album", true);
		similarReleases = new Store.IconView(parent);
		
		topInfo.pack_start(wrap_alignment(albumName, 20, 10, 10, 0), false, true, 0);
		topInfo.pack_start(wrap_alignment(albumArtist, 0, 10, 10, 0), false, true, 0);
		topInfo.pack_start(wrap_alignment(releaseDate, 0, 10, 10, 0), false, true, 0);
		topInfo.pack_start(wrap_alignment(priceFlags, 0, 10, 10, 0), false, true, 0);
		
		topRow.pack_start(wrap_alignment(albumArt, 20, 10, 10, 20), false, true, 0);
		topRow.pack_start(topInfo, true, true, 0);
		
		albumName.xalign = 0.0f;
		albumArtist.xalign = 0.0f;
		releaseDate.xalign = 0.0f;
		
		albumName.ellipsize = Pango.EllipsizeMode.END;
		albumArtist.ellipsize = Pango.EllipsizeMode.END;
		releaseDate.ellipsize = Pango.EllipsizeMode.END;
		
		/* make some 'category' labels */
		var trackListLabel = new Gtk.Label("");
		var similarReleasesLabel = new Gtk.Label("");
		
		trackListLabel.xalign = 0.0f;
		similarReleasesLabel.xalign = 0.0f;
		trackListLabel.set_markup("<span weight=\"bold\" size=\"larger\">Track List</span>");
		similarReleasesLabel.set_markup("<span weight=\"bold\" size=\"larger\">Similar Releases</span>");
		
		// set minimal size for main widgets
		leftSide.set_size_request(200, -1);
		trackList.set_size_request(-1, 250);
		similarReleases.set_size_request(-1, 200);
		
		leftSide.pack_start(wrap_alignment(viewArtist, 0, 0, 10, 0), false, true, 0);
		leftSide.pack_start(wrap_alignment(purchase, 0, 0, 10, 0), false, true, 0);
		stdout.printf("label: %s %s\n", release.label.name, release.label.labelID.to_string());
		leftSide.pack_start(wrap_alignment(new Gtk.Label(release.label.name), 0, 10, 10, 20), false, true, 0);
		
		//rightSide.pack_start(wrap_alignment(trackListLabel, 0, 0, 10, 20), false, true, 0);
		rightSide.pack_start(wrap_alignment(trackList, 0, 20, 40, 20), true, true, 0);
		rightSide.pack_start(wrap_alignment(similarReleasesLabel, 0, 0, 10, 20), false, true, 0);
		rightSide.pack_start(wrap_alignment(similarReleases, 0, 20, 40, 20), true, true, 0);
		
		splitter.pack_start(wrap_alignment(leftSide, 0, 0, 40, 20), false, true, 0);
		splitter.pack_start(rightSide, true, true, 0);
		
		allDetails.pack_start(topRow, true, true, 0);
		allDetails.pack_start(splitter, true, true, 0);
		
		/** now fill in with the artist's data **/
		
		Viewport vp = new Viewport(null, null);
		vp.set_shadow_type(ShadowType.NONE);
		vp.add(allDetails);
		
		add(vp);
		
		show_all();
		
		viewArtist.button_press_event.connect( (event) => {
			var newView = new ArtistView(parent, parent.store, release.artist);
			parent.setView(newView);
			newView.populate();
			
			return false;
		});
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
		try {
			Thread.create<void*>(setalbum_thread_function, false);
			Thread.create<void*>(gettracks_thread_function, false);
			Thread.create<void*>(getsimilarreleases_thread_function, false);
			parent.max = 5;
			parent.index = 0;
			parent.progressNotification();
		}
		catch(GLib.ThreadError err) {
			stdout.printf("ERROR: Could not create thread to get populate ArtistView: %s \n", err.message);
		}
	}
	
	public void* setalbum_thread_function () {
		Store.Release r = store.getRelease(release.releaseID, 200);
		r.image = Store.store.getPixbuf(r.imagePath, 200, 200);
		
		++parent.index;
		
		Idle.add( () => { 
			setAlbum(r); 
			++parent.index;
			
			Thread.create<void*>(gettaglabels_thread_function, false);
			
			return false; 
		});
		
		return null;
	}
	
	public void* gettracks_thread_function () {
		foreach(var track in release.getTracks())
			tracksListList.add(track);
		
		++parent.index;
		
		Idle.add( () => { 
			foreach(var track in tracksListList)
				trackList.addItem(track);
				
			++parent.index;
			return false;
		});
		
		return null;
	}
	
	public void* getsimilarreleases_thread_function () {
		foreach(var rel in release.getSimilar(1)) {
			rel.image = Store.store.getPixbuf(rel.imagePath, 100, 100);
			similarReleasesList.add(rel);
		}
		
		++parent.index;
		
		Idle.add( () => { 
			foreach(var rel in similarReleasesList)
				similarReleases.addItem(rel);
				
			++parent.index;
			return false;
		});
		
		return null;
	}
	
	public void* gettaglabels_thread_function () {
		var labels = new LinkedList<Store.TagLabel>();
		
		Gdk.Color orange;
		Gdk.Color lightorange;
		Gdk.Color white;
		
		Gdk.Color.parse("#F67F0F", out orange);
		Gdk.Color.parse("#FFFF00", out lightorange);
		Gdk.Color.parse("#FFFFFF", out white);
		
		foreach(var format in release.formats) {
			stdout.printf("format: %s %s\n", format.fileFormat, format.bitrate.to_string());
			if(format.fileFormat.down().contains("mp3")) {
				labels.add(new TagLabel("MP3", orange, lightorange, white, format, false));
				labels.add(new TagLabel(format.bitrate.to_string() + "k", orange, lightorange, white, format, false));
				
				if(format.drmFree)
					labels.add(new TagLabel("DRM Free", orange, lightorange, white, format, false));
			}
		}
		
		if(labels.size == 0 && release.formats.size > 0) {
			Format format = release.formats.get(0);
			
			labels.add(new TagLabel(format.fileFormat, orange, lightorange, white, format, false));
			labels.add(new TagLabel(format.bitrate.to_string() + "k", orange, lightorange, white, format, false));
			
			if(format.drmFree)
				labels.add(new TagLabel("DRM Free", orange, lightorange, white, format, false));
		}
		
		if(release.price != null/* && !release.price.formattedPrice.contains("0.00")*/) {
			labels.add(new TagLabel(release.price.formattedPrice, orange, lightorange, white, release.price, false));
		}
		
		++parent.index;
		
		Idle.add( () => { 
			foreach(var lab in labels) {
				stdout.printf("label added: %s\n", lab.label);
				priceFlags.pack_start(lab, false, false, 5);
			}
				
			++parent.index;
			return false;
		});
		
		return null;
	}
	
	public void setAlbum(Store.Release release) {
		this.release = release;
		albumName.set_markup("<span weight=\"bold\" font=\"40\">" + release.title.replace("&", "&amp;") + "</span>");
		albumArtist.set_markup("<span font=\"24\">" + release.artist.name.replace("&", "&amp;") + "</span>");
		releaseDate.set_markup("<span font=\"14\">Released " + release.releaseDate.substring(0, 10).replace("-", "/") + "</span>");
		
		if(release.image == null)
			release.image = Store.store.getPixbuf(release.imagePath, 200, 200);
		
		if(release.image != null) {
			albumArt.set_from_pixbuf(release.image);
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
