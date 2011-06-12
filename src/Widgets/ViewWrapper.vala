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

public class BeatBox.ViewWrapper : VBox {
	public LibraryManager lm;
	public LibraryWindow lw;
	public MusicTreeView list;
	public FilterView filterView;
	Collection<int> songs;
	
	ViewType currentView;
	bool isCurrentView;
	
	public enum ViewType {
		LIST,
		FILTER_VIEW
	}
	
	public ViewWrapper(LibraryManager lmm, LibraryWindow lww, Collection<int> songs, string sort, Gtk.SortType dir, MusicTreeView.Hint the_hint, int id) {
		lm = lmm;
		lw = lww;
		this.songs = songs;
		
		list = new MusicTreeView(lm, lw, sort, dir, the_hint, id);
		//list.populateView(songs, false);
		
		/* have to convert to linked list<song> */
		var linkedSongs = new LinkedList<int>();
		foreach(int sid in songs)
			linkedSongs.add(sid);
		
		filterView = new FilterView(lm, lw, linkedSongs);
		
		pack_start(list, true, true, 0);
		pack_start(filterView, true, true, 0);
		
		setView(ViewType.LIST);
		filterView.needsUpdate = true;
		list.needsUpdate = true;
		
		if(the_hint == MusicTreeView.Hint.MUSIC)
			populateViews(songs, true);
		
		filterView.itemClicked.connect(filterViewItemClicked);
		lw.viewSelector.notify["selected"].connect(selectorViewChanged);
	}
	
	public virtual void selectorViewChanged() {
		switch(lw.viewSelector.selected) {
			case 0:
				setView(ViewWrapper.ViewType.FILTER_VIEW);
				break;
			case 1:
			case 2:
				setView(ViewWrapper.ViewType.LIST);
				break;
		}
	}
	
	public void setIsCurrentView(bool isIt) {
		isCurrentView = isIt;
		
		if(!isIt) {
			list.is_current_view = false;
			filterView.isCurrentView = false;
		}
		else {
			setView(currentView);
		}
	}
	
	public void setView(ViewType type) {
		if(type == ViewType.LIST) {
			list.show();
			filterView.hide();
			
			if(isCurrentView) {
				list.is_current_view = true;
				if(list.needsUpdate)
					list.populateView(songs, false);
			}
			else
				list.is_current_view = false;
		}
		else {
			list.hide();
			filterView.show();
			
			if(isCurrentView) {
				filterView.isCurrentView = true;
				if(filterView.needsUpdate) {
					var linkedSongs = new LinkedList<Song>();
					foreach(int id in songs)
						linkedSongs.add(lm.song_from_id(id));
					
					filterView.generateHTML(linkedSongs);
				}
			}
			else
				filterView.isCurrentView = false;
		}
		
		currentView = type;
	}
	
	public ViewType getView() {
		return currentView;
	}
	
	public void populateViews(Collection<int> songs, bool populateBoth) {
		this.songs = songs;
		
		if((currentView == ViewType.LIST || populateBoth))
			list.populateView(songs, false);
		else if((currentView == ViewType.FILTER_VIEW || populateBoth)) {
			var linkedSongs = new LinkedList<Song>();
			foreach(int id in songs)
				linkedSongs.add(lm.song_from_id(id));
			
			filterView.generateHTML(linkedSongs);
		}
	}
	
	public void setStatusBarText() {
		switch(currentView) {
			case ViewType.FILTER_VIEW:
			case ViewType.LIST:
				list.setStatusBarText();
				break;
		}
	}
	
	public virtual void filterViewItemClicked(string album, string artist) {
		stdout.printf("test---------------\n");
		
		if(lw.millerVisible)
			lw.viewSelector.selected = 2;
		else
			lw.viewSelector.selected = 1;
		
		stdout.printf("setting text");
		lw.miller.albums.selected = album;
	}
}
