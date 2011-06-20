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

public class Store.StoreView : VBox {
	public Store.store store;
	
	public BeatBox.LibraryManager lm;
	public BeatBox.LibraryWindow lw;
	bool isCurrentView;
	
	Store.HomeView homeView;
	Widget currentView;
	
	Toolbar topPanel;
	ToolButton homeButton;
	HBox container;
	
	public StoreView(BeatBox.LibraryManager lm, BeatBox.LibraryWindow lw) {
		this.lm = lm;
		this.lw = lw;
		store = new Store.store();
		
		buildUI();
	}
	
	public void buildUI() {
		topPanel = new Toolbar();
		homeButton = new ToolButton(null, "Home");
		container = new HBox(false, 0);
		
		topPanel.insert(homeButton, 0);
		
		pack_start(topPanel, false, true, 0);
		pack_start(container, true, true, 0);
		
		homeView = new HomeView(this, store);
		setView(homeView);
		
		show_all();
		
		homeButton.clicked.connect(homeButtonClicked);
		lw.searchField.activate.connect(searchFieldActivated);
	}
	
	public void setIsCurrentView(bool isit) {
		isCurrentView = isit;
	}
	
	public void homeButtonClicked() {
		homeView = new HomeView(this, store);
		setView(homeView);
	}
	
	public void searchFieldActivated() {
		if(!isCurrentView)
			return;
		
		var searchPage = new SearchResultsView(this, store);
		foreach(var track in store.searchTracks(lw.searchField.get_text(), 1))
			searchPage.addTrack(track);
		foreach(var artist in store.searchArtists(lw.searchField.get_text(), null, 1))
			searchPage.addArtist(artist);
		foreach(var rel in store.searchReleases(lw.searchField.get_text(), 1))
			searchPage.addRelease(rel);
		
		setView(searchPage);
		
	}
	
	public void setView(Widget w) {
		stdout.printf("setView()\n");
		currentView.hide();
		stdout.printf("1\n");
		currentView = w;
		stdout.printf("2\n");
		container.add(currentView);
		stdout.printf("3\n");
	}
	
	
}
