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
	public AlbumView albumView;
	private WarningLabel errorBox;
	public Collection<int> songs;
	public Collection<int> showingSongs;
	
	public MusicTreeView.Hint hint;
	public ViewType currentView;
	public bool isCurrentView;
	
	LinkedList<string> timeout_search;//stops from doing useless search (timeout)
	string last_search;//stops from searching same thing multiple times
	bool showing_all; // stops from searching unnecesarilly when changing b/w 0 words and search hint, etc.
	
	// for Hint.SIMILAR only
	public bool similarsFetched;
	
	public enum ViewType {
		LIST,
		FILTER_VIEW
	}
	
	public ViewWrapper(LibraryManager lmm, LibraryWindow lww, Collection<int> songs, string sort, Gtk.SortType dir, MusicTreeView.Hint the_hint, int id) {
		lm = lmm;
		lw = lww;
		this.songs = songs;
		showingSongs = new LinkedList<int>();
		timeout_search = new LinkedList<string>();
		
		hint = the_hint;
		
		if(the_hint != MusicTreeView.Hint.SIMILAR)
			list = new MusicTreeView(lm, lw, sort, dir, the_hint, id);
		else {
			list = new SimilarPane(lm, lw);
			errorBox = new WarningLabel();
		}
		
		//list.populateView(songs, false);
		albumView = new AlbumView(lm, lw, songs);
		
		pack_start(list, true, true, 0);
		pack_start(albumView, true, true, 0);
		
		if(list.hint == MusicTreeView.Hint.SIMILAR)
			pack_start(errorBox, true, true, 0);
		
		albumView.needsUpdate = true;
		list.needsUpdate = true;
		
		if(the_hint == MusicTreeView.Hint.MUSIC)
			doUpdate(ViewType.LIST, songs, true, true);
		
		albumView.itemClicked.connect(filterViewItemClicked);
		lw.viewSelector.notify["selected"].connect(selectorViewChanged);
		lm.song_played.connect(songPlayed);
		
		lw.searchField.changed.connect(searchFieldChanged);
		lw.miller.changed.connect(searchFieldChanged);
	}
	
	public virtual void selectorViewChanged() {
		switch(lw.viewSelector.selected) {
			case 0:
				doUpdate(ViewWrapper.ViewType.FILTER_VIEW, songs, false, false);
				break;
			case 1:
			case 2:
				doUpdate(ViewWrapper.ViewType.LIST, songs, false, false);
				break;
		}
	}
	
	public void setIsCurrentView(bool isIt) {
		isCurrentView = isIt;
		
		if(!isIt) {
			list.is_current_view = false;
			albumView.isCurrentView = false;
		}
	}
	
	public ViewType getView() {
		return currentView;
	}
	
	public void songPlayed(int id, int old) {
		if(list.hint != MusicTreeView.Hint.SIMILAR)
			return;
			
		if(!(lm.current_songs().size == list.get_songs().size && lm.current_songs().contains_all(list.get_songs()))) {
			/* a new song is played. don't show list until songs have loaded */
			
			errorBox.setWarning("<span weight=\"bold\" size=\"larger\">Loading similar songs</span>\nBeatBox is loading songs similar to " + lm.song_from_id(id).title.replace("&", "&amp;") + " by " + lm.song_from_id(id).artist.replace("&", "&amp;") + "...");
			errorBox.show();
			list.hide();
			albumView.hide();
			similarsFetched = false;
		}
	}
	
	public void clear() {
		var empty = new LinkedList<int>();
		
		this.songs = empty;
		
		list.set_songs(empty);
		list.populateView(empty, false, false);
		
		albumView.set_songs(empty);
		albumView.populateView(empty, false);
	}
	
	public void doUpdate(ViewType type, Collection<int> songs, bool set_songs, bool force) {
		if(set_songs) {
			this.songs = songs;
		}
		
		currentView = type;
		
		/* BEGIN special case for similar songs */
		if(list.hint == MusicTreeView.Hint.SIMILAR) {
			SimilarPane sp = (SimilarPane)(list);
			
			if(!similarsFetched) { // still fetching similar songs
				errorBox.show();
				list.hide();
				albumView.hide();
				
				return;
			}
			else if( !(lm.current_songs().size == sp.get_songs().size && lm.current_songs().contains_all(sp.get_songs())) ) { // not currently playing list and have fetched
				if(songs.size < 10) { // say we could not find similar songs
					errorBox.setWarning("<span weight=\"bold\" size=\"larger\">No Similar Songs</span>\nBeatBox could not find songs similar to " + lm.song_info.song.title.replace("&", "&amp;") + " by " + lm.song_info.song.artist.replace("&", "&amp;") + ".\nYou could have incorrect data, no internet connection, or non-mainstream music.");
					errorBox.show();
					list.hide();
					albumView.hide();
					
					return;
				}
				else {
					errorBox.hide();
					
					sp._base = lm.song_info.song;
				}
			}
			else if(lm.current_songs().size == sp.get_songs().size && lm.current_songs().contains_all(sp.get_songs()) && similarsFetched) { // needs update, but won't because not worthy
				
				return;
			}
		}
		/* END special case */
		
		var potentialShowing = new LinkedList<int>();
		bool doPopulate = true;
		
		if(hint != MusicTreeView.Hint.CDROM) {
			if(currentView != ViewWrapper.ViewType.FILTER_VIEW) {
				potentialShowing.add_all(lm.songs_from_search(lw.searchField.get_text(), 
													lw.miller.genres.get_selected(), 
													lw.miller.artists.get_selected(),
													lw.miller.albums.get_selected(),
													songs));
			
			}
			else {
				potentialShowing.add_all(lm.songs_from_search(lw.searchField.get_text(), 
													"All Genres", 
													"All Artists",
													"All Albums",
													songs));
			}
		}
		else {
			if(currentView != ViewWrapper.ViewType.FILTER_VIEW) {
				potentialShowing.add_all(lm.temps_from_search(lw.searchField.get_text(), 
													lw.miller.genres.get_selected(), 
													lw.miller.artists.get_selected(),
													lw.miller.albums.get_selected(),
													songs));
			
			}
			else {
				potentialShowing.add_all(lm.temps_from_search(lw.searchField.get_text(), 
													"All Genres", 
													"All Artists",
													"All Albums",
													songs));
			}
		}
		
		if(showingSongs.size == potentialShowing.size && potentialShowing.size > 500 && hint != MusicTreeView.Hint.HISTORY && hint != MusicTreeView.Hint.QUEUE && !force)
			doPopulate = false;
		
		showingSongs = potentialShowing;
		
		if(type == ViewType.LIST) {
			list.show();
			albumView.hide();
			
			if(isCurrentView || force) {
				list.is_current_view = isCurrentView;
				
				if(doPopulate || list.needsUpdate) {
					list.populateView(showingSongs, !set_songs, force);
				}
			}
			else
				list.is_current_view = false;
		}
		else {
			list.hide();
			albumView.show();
			
			if(isCurrentView || force) {
				albumView.isCurrentView = isCurrentView;
				
				if(doPopulate || albumView.needsUpdate)
					albumView.populateView(showingSongs, force);
			}
			else
				albumView.isCurrentView = false;
				
			stdout.printf("setting focus\n");
			albumView.icons.has_focus = true;
			/*Gdk.EventButton ev = new Gdk.EventButton();
			ev.type = Gdk.EventType.BUTTON_PRESS;
			ev.x = 1;
			ev.y = 1;
			ev.button = 1;
			albumView.icons.button_press_event(ev);*/
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
		if(lw.millerVisible)
			lw.viewSelector.selected = 2;
		else
			lw.viewSelector.selected = 1;
		
		lw.miller.albums.set_selected(album);
	}
	
	
	public virtual void searchFieldChanged() {
		if(lw.initializationFinished && isCurrentView && lw.searchField.get_text().length != 1) {
			timeout_search.offer_head(lw.searchField.get_text().down());
			Timeout.add(100, () => {
				
				string to_search = timeout_search.poll_tail();
				//stdout.printf("search filed changed\n");
				doUpdate(this.currentView, songs, false, false);
					
				last_search = to_search;
				showing_all = (showingSongs.size == songs.size);
				
				lm.settings.setSearchString(to_search);
				list.setStatusBarText();
				
				return false;
			});
		}
	}
}
