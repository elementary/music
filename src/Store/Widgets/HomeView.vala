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

public class Store.HomeView : ScrolledWindow {
	Store.store store;
	Store.StoreView storeView;
	
	HBox allItems;
	Store.ObjectList tagList;
	Store.ObjectList artistList;
	Store.TrackList trackList;
	Store.ReleaseRotator releaseRotator;
	Store.IconView topRock;
	
	public HomeView(StoreView storeView, Store.store store) {
		this.storeView = storeView;
		this.store = store;
		
		buildUI();
	}
	
	public void buildUI() {
		allItems = new HBox(false, 0);
		VBox leftItems = new VBox(false, 0);
		VBox centerItems = new VBox(false, 0);
		
		tagList = new ObjectList(storeView, "Popular Genres");
		artistList = new ObjectList(storeView, "Top Artists");
		trackList = new TrackList(storeView, "Artist", false);
		releaseRotator = new ReleaseRotator(storeView);
		topRock = new IconView(storeView);
		
		/* category labels */
		var genresLabel = new Gtk.Label("");
		var artistsLabel = new Gtk.Label("");
		var tracksLabel = new Gtk.Label("");
		var rockLabel = new Gtk.Label("");
		
		genresLabel.xalign = 0.0f;
		artistsLabel.xalign = 0.0f;
		tracksLabel.xalign = 0.0f;
		rockLabel.xalign = 0.0f;
		
		genresLabel.set_markup("<span weight=\"bold\" size=\"larger\">Popular Genres</span>");
		artistsLabel.set_markup("<span weight=\"bold\" size=\"larger\">Top Artists</span>");
		tracksLabel.set_markup("<span weight=\"bold\" size=\"larger\">Top Tracks</span>");
		rockLabel.set_markup("<span weight=\"bold\" size=\"larger\">New Rock Releases</span>");
		
		leftItems.pack_start(wrap_alignment(genresLabel, 20, 0, 0, 20), false, true, 0);
		leftItems.pack_start(wrap_alignment(tagList, 10, 10, 30, 20), false, true, 0);
		leftItems.pack_start(wrap_alignment(artistsLabel, 10, 0, 0, 20), false, true, 0);
		leftItems.pack_start(wrap_alignment(artistList, 10, 10, 10, 20), false, true, 0);
		
		centerItems.pack_start(wrap_alignment(releaseRotator, 0, 0, 40, 0), false, true, 0);
		centerItems.pack_start(wrap_alignment(tracksLabel, 0, 0, 0, 0), false, true, 0);
		centerItems.pack_start(wrap_alignment(trackList, 10, 0, 0, 0), false, true, 0);
		centerItems.pack_start(wrap_alignment(rockLabel, 40, 0, 0, 0), false, true, 0);
		centerItems.pack_start(wrap_alignment(topRock, 10, 0, 0, 0), false, true, 0);
		
		allItems.pack_start(leftItems, false, true, 0);
		allItems.pack_start(wrap_alignment(centerItems, 20, 20, 10, 10), true, true, 0);
		
		releaseRotator.set_size_request(-1, 200);
		tagList.set_size_request(200, 250);
		artistList.set_size_request(200, 450);
		trackList.set_size_request(-1, 300);
		topRock.set_size_request(-1, 200);
		
		Viewport vp = new Viewport(null, null);
		vp.set_shadow_type(ShadowType.NONE);
		vp.add(allItems);
		
		add(vp);
		
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
		try {
			Thread.create<void*>(getartists_thread_function, false);
			Thread.create<void*>(getreleases_thread_function, false);
			Thread.create<void*>(gettracks_thread_function, false);
			Thread.create<void*>(gettoprock_thread_function, false);
			Thread.create<void*>(getgenres_thread_function, false);
			storeView.max = 6;
			storeView.index = 0;
			storeView.progressNotification();
		}
		catch(GLib.ThreadError err) {
			stdout.printf("ERROR: Could not create thread to get populate ArtistView: %s \n", err.message);
		}
	}
	
	public void* getartists_thread_function () {
		var tops = new LinkedList<Artist>();
		
		foreach(var art in store.topArtists("week", null, null, 1))
			tops.add(art);
		
		++storeView.index;
		
		Idle.add( () => { 
			foreach(var art in tops)
				artistList.addItem(art);
				
			++storeView.index;
			return false;
		});
		
		return null;
	}
	
	public void* getreleases_thread_function () {
		var tops = new LinkedList<Release>();
		
		foreach(var rel in store.topReleases("week", null, null, 1)) {
			rel.image = Store.store.getPixbuf(rel.imagePath, 200, 200);
			tops.add(rel);
			
			// get off to a start
			if(tops.size == 1)
				releaseRotator.setReleases(tops);
		}
		
		++storeView.index;
		
		releaseRotator.setReleases(tops);
		
		return null;
	}
	
	public void* gettracks_thread_function () {
		var tops = new LinkedList<Track>();
		
		foreach(var track in store.topTracks("week", null, 1))
			tops.add(track);
		
		++storeView.index;
		
		Idle.add( () => { 
			foreach(var track in tops)
				trackList.addItem(track);
				
			++storeView.index;
			return false;
		});
		
		return null;
	}
	
	public void* gettoprock_thread_function () {
		var rock = new LinkedList<Release>();
		
		foreach(var rel in store.topReleases("week", null, "rock", 1)) {
			rel.image = Store.store.getPixbuf(rel.imagePath, 100, 100);
			rock.add(rel);
		}
		
		++storeView.index;
		
		Idle.add( () => { 
			foreach(var rel in rock)
				topRock.addItem(rel);
				
			++storeView.index;
			return false;
		});
		
		return null;
	}
	
	public void* getgenres_thread_function () {
		var gens = new LinkedList<Tag>();
		
		gens.add( new Tag.with_values("pop", "Pop", "") );
		gens.add( new Tag.with_values("rock", "Rock", "") );
		gens.add( new Tag.with_values("electronic", "Electronic", "") );
		gens.add( new Tag.with_values("jazz", "Jazz", "") );
		gens.add( new Tag.with_values("alternative-indie", "Alternative/Indie", "") );
		gens.add( new Tag.with_values("country", "Country", "") );
		gens.add( new Tag.with_values("grunge", "Grunge", "") );
		gens.add( new Tag.with_values("2000s", "2000's", "") );
		gens.add( new Tag.with_values("reggae", "Reggae", "") );
		gens.add( new Tag.with_values("new-age", "New Age", "") );
		gens.add( new Tag.with_values("instrumental", "Instrumental", "") );
		gens.add( new Tag.with_values("soundtrack", "Soundtrack", "") );
		
		++storeView.index;
		
		Idle.add( () => { 
			foreach(var tag in gens)
				tagList.addItem(tag);
				
			++storeView.index;
			return false;
		});
		
		return null;
	}
	
}
