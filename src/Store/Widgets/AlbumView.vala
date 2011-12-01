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

public class Store.AlbumView : ScrolledWindow {
	Store.StoreView storeView;
	Store.store store;
	private Store.Release release;
	private LinkedList<Store.Track> tracksListList;
	private LinkedList<Store.Release> similarReleasesList;
	
	private Image albumArt;
	private Gtk.Label albumName;
	private Gtk.Label albumArtist;
	//private TagLabel purchase;
	private Gtk.Label releaseDate;
	private Gtk.Label producer;
	private HBox priceFlags;
	private VBox rightButtons;
	private VBox middleLeft;
	private Gtk.Label description;
	private HBox tags; 
	private Store.TrackList trackList;
	private Store.IconView similarReleases;
	
	private Gdk.Pixbuf defaultPix;
	
	public AlbumView(Store.StoreView view, Store.store s, Release r) {
		storeView = view;
		store = s;
		release = r;
		tracksListList = new LinkedList<Store.Track>();
		similarReleasesList = new LinkedList<Store.Release>();
		
		defaultPix = new Gdk.Pixbuf.from_file_at_size(GLib.Path.build_filename("/usr", "share", "icons", "hicolor", "128x128", "mimetypes", "media-audio.svg", null), 100, 100);
		
		buildUI();
		
		setAlbum(release);
	}
	
	public void buildUI() {
		/* put it in event box so we can color background white */
		EventBox eb = new EventBox();
		
		// make the background white
		Gdk.Color c = Gdk.Color();
		Gdk.Color.parse("#FFFFFF", out c);
		eb.modify_bg(StateType.NORMAL, c);
		
		VBox allDetails = new VBox(false, 0);
		HBox topRow = new HBox(false, 0);
		VBox topInfo = new VBox(false, 0);
		VBox topFlags = new VBox(false, 0);
		
		albumArt = new Image();
		albumName = new Gtk.Label("");
		albumArtist = new Gtk.Label("");
		releaseDate = new Gtk.Label("");
		producer = new Gtk.Label("");
		priceFlags = new HBox(false, 5);
		rightButtons = new VBox(false, 0);
		description = new Gtk.Label("");
		tags = new HBox(false, 5);
		trackList = new Store.TrackList(storeView, "Album", false);
		similarReleases = new Store.IconView(storeView);
		
		HBox topInfoSplit = new HBox(false, 0);
		topInfo.pack_start(wrap_alignment(albumName, 20, 10, 10, 0), false, true, 0);
		topInfo.pack_start(wrap_alignment(albumArtist, 0, 10, 10, 0), false, true, 0);
		topInfo.pack_start(wrap_alignment(releaseDate, 0, 10, 10, 0), false, true, 0);
		topInfo.pack_start(wrap_alignment(producer, 0, 10, 10, 0), false, true, 0);
		topInfo.pack_start(wrap_alignment(priceFlags, 0, 10, 10, 0), false, true, 0);
		
		topInfoSplit.pack_start(topInfo, true, true, 0);
		topInfoSplit.pack_start(rightButtons, false, true, 0);
		
		topRow.pack_start(wrap_alignment(albumArt, 20, 10, 20, 20), false, true, 0);
		topRow.pack_start(topInfoSplit, true, true, 0);
		
		albumName.xalign = 0.0f;
		albumArtist.xalign = 0.0f;
		releaseDate.xalign = 0.0f;
		producer.xalign = 0.0f;
		
		albumName.ellipsize = Pango.EllipsizeMode.END;
		albumArtist.ellipsize = Pango.EllipsizeMode.END;
		releaseDate.ellipsize = Pango.EllipsizeMode.END;
		producer.ellipsize = Pango.EllipsizeMode.END;
		
		/* make some 'category' labels */
		var similarReleasesLabel = new Gtk.Label("");
		similarReleasesLabel.xalign = 0.0f;
		similarReleasesLabel.set_markup("<span weight=\"bold\" size=\"larger\">Similar Releases</span>");
		
		// set minimal size for main widgets
		//description.set_size_request(100, 600);
		trackList.set_size_request(-1, 250);
		similarReleases.set_size_request(-1, 180);
		
		allDetails.pack_start(topRow, true, true, 0);
		allDetails.pack_start(wrap_alignment(description, 0, 20, 20, 20), true, true, 0);
		allDetails.pack_start(wrap_alignment(trackList, 0, 20, 6, 20), true, true, 0);
		allDetails.pack_start(wrap_alignment(tags, 0, 20, 6, 20), false, true, 0);
		allDetails.pack_start(wrap_alignment(similarReleasesLabel, 34, 0, 6, 20), false, true, 0);
		allDetails.pack_start(wrap_alignment(similarReleases, 0, 20, 40, 20), true, true, 0);
		
		/** now fill in with the artist's data **/
		//description.ellipsize = Pango.EllipsizeMode.END;
		description.set_line_wrap(true);
		//description.set_line_wrap_mode(Pango.WrapMode.WORD);
		description.yalign = 0.0f;
		description.xalign = 0.0f;
		
		eb.add(allDetails);
		
		Viewport vp = new Viewport(null, null);
		vp.set_shadow_type(ShadowType.NONE);
		vp.add(eb);
		
		add(vp);
		
		show_all();
		
		/*viewArtist.button_press_event.connect( (event) => {
			var newView = new ArtistView(storeView, storeView.store, release.artist);
			storeView.setView(newView);
			newView.populate();
			
			return false;
		});*/
		
		this.size_allocate.connect(resized);
	}
	
	public virtual void resized(Allocation rec) {
		description.set_size_request(rec.width - 40, -1);
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
			Thread.create<void*>(getalbuminfo_thread_function, false);
			storeView.max = 5;
			storeView.index = 0;
			storeView.progressNotification();
		}
		catch(GLib.ThreadError err) {
			stdout.printf("ERROR: Could not create thread to get populate ArtistView: %s \n", err.message);
		}
	}
	
	public void* setalbum_thread_function () {
		Store.Release r = store.getRelease(release.releaseID, 200);
		r.image = Store.store.getPixbuf(r.imagePath, 200, 200);
		
		++storeView.index;
		
		Idle.add( () => { 
			setAlbum(r); 
			++storeView.index;
			
			Thread.create<void*>(gettaglabels_thread_function, false);
			
			return false; 
		});
		
		return null;
	}
	
	public void* gettracks_thread_function () {
		foreach(var track in release.getTracks())
			tracksListList.add(track);
		
		++storeView.index;
		
		Idle.add( () => { 
			foreach(var track in tracksListList)
				trackList.addItem(track);
				
			++storeView.index;
			return false;
		});
		
		return null;
	}
	
	public void* getsimilarreleases_thread_function () {
		foreach(var rel in release.getSimilar(1)) {
			rel.image = Store.store.getPixbuf(rel.imagePath, 100, 100);
			similarReleasesList.add(rel);
		}
		
		++storeView.index;
		
		Idle.add( () => { 
			foreach(var rel in similarReleasesList)
				similarReleases.addItem(rel);
				
			++storeView.index;
			return false;
		});
		
		return null;
	}
	
	public void* gettaglabels_thread_function () {
		/*var labels = new LinkedList<Store.TagLabel>();
		
		foreach(var format in release.formats) {
			stdout.printf("format: %s %s\n", format.fileFormat, format.bitrate.to_string());
			if(format.fileFormat.down().contains("mp3")) {
				labels.add(new TagLabel("MP3", "orange", format, false));
				labels.add(new TagLabel(format.bitrate.to_string() + "k", "orange", format, false));
				
				if(format.drmFree)
					labels.add(new TagLabel("DRM Free", "orange", format, false));
			}
		}
		
		if(labels.size == 0 && release.formats.size > 0) {
			Format format = release.formats.get(0);
			
			labels.add(new TagLabel(format.fileFormat, "orange", format, false));
			labels.add(new TagLabel(format.bitrate.to_string() + "k", "orange", format, false));
			
			if(format.drmFree)
				labels.add(new TagLabel("DRM Free", "orange", format, false));
		}
		
		if(release.price != null/* && !release.price.formattedPrice.contains("0.00")*) {
			labels.add(new TagLabel(release.price.formattedPrice, "orange", release.price, false));
		}
		
		++storeView.index;
		
		Idle.add( () => { 
			foreach(var lab in labels) {
				stdout.printf("label added: %s\n", lab.label);
				priceFlags.pack_start(lab, false, false, 0);
			}
				
			++storeView.index;
			return false;
		});*/
		
		return null;
	}
	
	public void* getalbuminfo_thread_function () {
		/* first get album description */
		LastFM.AlbumInfo album = new LastFM.AlbumInfo.basic();
		
		string artist_s = release.artist.name;
		string album_s = release.title;
		
		/* fetch album info now. only save if still on current song */
		//if(!storeView.lm.album_info_exists(album_s + " by " + artist_s)) {
			
			album = new LastFM.AlbumInfo.with_info(artist_s, album_s);
			stdout.printf("fetched album\n");
			if(album != null) {
				//storeView.lm.save_album(album);
				stdout.printf("saved album\n");
			}
			
		//}
		//else {
		//	album = storeView.lm.get_album(album_s + " by " + artist_s);
		//}
		
		/* now get the 7digital tags */
		var tags = new LinkedList<Store.Tag>();
		foreach(var tag in release.getTags(1))
			tags.add(tag);
		
		Idle.add( () => {
			if(album != null && album.summary != null && album.summary.length > 200) { 
				setDescription(album.summary);
				//description.set_size_request(-1, 100);
			}
			
			foreach(var tag in tags) {
				stdout.printf("tag added: %s\n", tag.text);
				//this.tags.pack_start(new TagLabel(tag.text, "blue", tag, true), false, false, 0);
			}
			
			return false;
		});
		
		return null;
	}
	
	public void setAlbum(Store.Release release) {
		this.release = release;
		albumName.set_markup("<span weight=\"bold\" font=\"34\">" + release.title.replace("&", "&amp;") + "</span>");
		albumArtist.set_markup("<span font=\"22\">" + release.artist.name.replace("&", "&amp;") + "</span>");
		releaseDate.set_markup("<span font=\"11\">Released " + release.releaseDate.substring(0, 10).replace("-", "/") + "</span>");
		
		if(release.label.name != null && release.label.name != "")
			producer.set_markup("<span font=\"11\">" + release.label.name.substring(0, 10).replace("-", "/") + "</span>");
		
		if(release.image == null)
			release.image = Store.store.getPixbuf(release.imagePath, 200, 200);
		
		if(release.image != null) {
			albumArt.set_from_pixbuf(release.image);
		}
		else
			albumArt.set_from_pixbuf(defaultPix);
	}
	
	public void setDescription(string desc) {
		description.set_markup(desc);
	}
	
	public void addTrack(Store.Track track) {
		trackList.addItem(track);
	}
	
	public void addSimilarRelease(Store.Release release) {
		similarReleases.addItem(release);
	}
}
