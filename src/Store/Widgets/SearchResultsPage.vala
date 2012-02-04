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

public class Store.SearchResultsView : ScrolledWindow {
	Store.StoreView storeView;
	Store.store store;
	
	public Store.SearchList tracks;
	public Store.SearchList artists;
	public Store.SearchList releases;
	
	public SearchResultsView(Store.StoreView view, Store.store store) {
		this.storeView = view;
		this.store = store;
		
		buildUI();
	}
	
	public void buildUI() {
		VBox allLists = new VBox(false, 0);
		HBox bottomLists = new HBox(false, 0);
		VBox leftList = new VBox(false, 0);
		VBox rightList = new VBox(false, 0);
		
		tracks = new SearchList(storeView, SearchList.SearchListType.TRACK);
		artists = new SearchList(storeView, SearchList.SearchListType.ARTIST);
		releases = new SearchList(storeView, SearchList.SearchListType.RELEASE);
		
		/* make some 'category' labels */
		var tracksLabel = new Gtk.Label("");
		var artistsLabel = new Gtk.Label("");
		var releasesLabel = new Gtk.Label("");
		
		tracksLabel.xalign = 0.0f;
		artistsLabel.xalign = 0.0f;
		releasesLabel.xalign = 0.0f;
		tracksLabel.set_markup("<span weight=\"bold\" size=\"larger\">Tracks</span>");
		artistsLabel.set_markup("<span weight=\"bold\" size=\"larger\">Artists</span>");
		releasesLabel.set_markup("<span weight=\"bold\" size=\"larger\">Releases</span>");
		
		// set minimal size for main widgets
		tracks.set_size_request(-1, 250);
		artists.set_size_request(-1, 250);
		releases.set_size_request(-1, 250);
		
		allLists.pack_start(wrap_alignment(tracksLabel, 10, 20, 10, 20), false, true, 0);
		allLists.pack_start(wrap_alignment(tracks, 0, 20, 40, 20), true, true, 0);
		
		leftList.pack_start(wrap_alignment(artistsLabel, 10, 20, 10, 20), false, true, 0);
		leftList.pack_start(wrap_alignment(artists, 0, 20, 40, 20), true, true, 0);
		
		rightList.pack_start(wrap_alignment(releasesLabel, 10, 20, 10, 20), false, true, 0);
		rightList.pack_start(wrap_alignment(releases, 0, 20, 40, 20), true, true, 0);
		
		bottomLists.pack_start(leftList, true, true, 0);
		bottomLists.pack_start(rightList, true, true, 0);
		
		allLists.pack_start(bottomLists);
		
		Viewport vp = new Viewport(null, null);
		vp.set_shadow_type(ShadowType.NONE);
		vp.add(allLists);
		
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
	
	public void addTrack(Store.Track track) {
		tracks.addItem(track);
	}
	
	public void addArtist(Store.Artist artist) {
		artists.addItem(artist);
	}
	
	public void addRelease(Store.Release release) {
		releases.addItem(release);
	}
	
}
