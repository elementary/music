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

public class BeatBox.ViewWrapper : VBox {
	public LibraryManager lm;
	public LibraryWindow lw;
	public ContentView list;
	public ContentView albumView;
	public WarningLabel errorBox;
	public Collection<int> songs;
	public Collection<int> showingSongs;
	public int song_count;
	
	public ViewWrapper.Hint hint;
	public ViewType currentView;
	public bool isCurrentView;
	
	LinkedList<string> timeout_search;//stops from doing useless search (timeout)
	string last_search;//stops from searching same thing multiple times
	bool showing_all; // stops from searching unnecesarilly when changing b/w 0 words and search get_hint(), etc.
	
	// for Hint.SIMILAR only
	public bool similarsFetched;
	
	public enum ViewType {
		LIST,
		FILTER_VIEW
	}
	
	public enum Hint {
		MUSIC,
		PODCAST,
		AUDIOBOOK,
		SIMILAR,
		QUEUE,
		HISTORY,
		PLAYLIST,
		SMART_PLAYLIST,
		CDROM,
		DEVICE_AUDIO,
		DEVICE_PODCAST,
		DEVICE_AUDIOBOOK;
	}
	
	public ViewWrapper(LibraryManager lmm, LibraryWindow lww, Collection<int> songs, string sort, Gtk.SortType dir, ViewWrapper.Hint the_hint, int id) {
		lm = lmm;
		lw = lww;
		this.songs = songs;
		song_count = songs.size;
		showingSongs = new LinkedList<int>();
		timeout_search = new LinkedList<string>();
		
		hint = the_hint;
		
		if(the_hint == ViewWrapper.Hint.SIMILAR) {
			list = new SimilarPane(lm, lw);
			errorBox = new WarningLabel();
			errorBox.show_icon = false;
			errorBox.setWarning ("<span weight=\"bold\" size=\"larger\">Similar Song View</span>\n\nIn this view, BeatBox will automatically find songs similar to the one you are playing.\nYou can then start playing those songs, or save them for later.");
		}
		else if(the_hint == ViewWrapper.Hint.PODCAST || the_hint == ViewWrapper.Hint.DEVICE_PODCAST) {
			list = new PodcastListView(lm, lw, sort, dir, the_hint, id);
		}
		else if(the_hint == ViewWrapper.Hint.AUDIOBOOK || the_hint == ViewWrapper.Hint.DEVICE_AUDIOBOOK) {
			list = new MusicTreeView(lm, lw, sort, dir, the_hint, id);
		}
		else {
			list = new MusicTreeView(lm, lw, sort, dir, the_hint, id);
		}
		
		//list.populate_view(songs, false);
		albumView = new AlbumView(lm, lw, songs);
		
		pack_end(list, true, true, 0);
		pack_end(albumView, true, true, 0);
		
		if(list.get_hint() == ViewWrapper.Hint.SIMILAR)
			pack_start(errorBox, true, true, 0);
		
		//albumView.needsUpdate = true;
		//list.needsUpdate = true;
		albumView.set_show_next(songs);
		list.set_show_next(songs);
		
		
		if(the_hint == ViewWrapper.Hint.MUSIC)
			doUpdate(ViewType.LIST, songs, true, true);
		
		if(albumView is AlbumView)
			((AlbumView)albumView).itemClicked.connect(filterViewItemClicked);
		
		lw.viewSelector.mode_changed.connect(selectorViewChanged);
		lm.song_played.connect(songPlayed);
		lm.songs_added.connect(songs_added);
		lm.songs_removed.connect(songs_removed);
		
		lw.searchField.changed.connect(searchFieldChanged);
		lw.miller.changed.connect(millerChanged);
		
		// initialize in thread
		searchFieldChanged();
	}
	
	public virtual void selectorViewChanged() {
		switch(lw.viewSelector.selected) {
			case 0:
				doUpdate(ViewWrapper.ViewType.FILTER_VIEW, songs, false, false);
				break;
			case 1:
				doUpdate(ViewWrapper.ViewType.LIST, songs, false, false);
				break;
			case 2:
				doUpdate(ViewWrapper.ViewType.LIST, songs, false, false);
				
				if(isCurrentView) {
					stdout.printf("populating millers\n");
					lw.miller.populateColumns("", songs);
				}
				break;
		}
	}
	
	public void set_is_current_view(bool isIt) {
		isCurrentView = isIt;
		
		if(!isIt) {
			list.set_is_current_view(false);
			albumView.set_is_current_view(false);
		}
	}
	
	public ViewType getView() {
		return currentView;
	}
	
	public void songPlayed(int id, int old) {
		if(list.get_hint() != ViewWrapper.Hint.SIMILAR)
			return;
			
		if(!(lm.current_songs().size == list.get_songs().size && lm.current_songs().contains_all(list.get_songs()))) {
			/* a new song is played. don't show list until songs have loaded */
			errorBox.show_icon = false;
			errorBox.setWarning("<span weight=\"bold\" size=\"larger\">Loading similar songs</span>\n\nBeatBox is loading songs similar to <b>" + lm.song_from_id(id).title.replace("&", "&amp;") + "</b> by <b>" + lm.song_from_id(id).artist.replace("&", "&amp;") + "</b> ...");
			errorBox.show();
			list.hide();
			albumView.hide();
			similarsFetched = false;
		}
	}
	
	void songs_added(LinkedList<int> ids) {
		bool refreshPod = hint == ViewWrapper.Hint.PODCAST;
		bool refreshMusic = hint == ViewWrapper.Hint.MUSIC;
		
		foreach(int i in ids) {
			refreshPod = refreshPod && (lm.song_from_id(i).mediatype == 1);
			refreshMusic = refreshMusic && (lm.song_from_id(i).mediatype == 0);
		}
		
		if(refreshPod)
			doUpdate(currentView, lm.podcast_ids(), true, true);
		/*else if(refreshMusic)
			doUpdate(currentView, lm.song_ids(), true, true);*/
	}
	
	void songs_removed(LinkedList<int> ids) {
		//songs.remove_all(ids);
		showingSongs.remove_all(ids);
	}
	
	public void clear() {
		var empty = new LinkedList<int>();
		
		this.songs = empty;
		
		list.set_show_next(empty);
		list.populate_view();
		
		albumView.set_show_next(empty);
		albumView.populate_view();
	}
	
	/** Updates the displayed view and its content
	 * 
	 * @param view the view to show/update
	 * @param songs If set_songs is true, then set this.songs = songs
	 * @param set_songs whether or not to set the songs
	 * @param do_visual If true, visually populate as well
	*/
	public void doUpdate(ViewType type, Collection<int> songs, bool set_songs, bool force) {
		if(set_songs) {
			this.songs = songs;
			song_count = songs.size;
		}
		
		currentView = type;
		
		/* BEGIN special case for similar songs */
		if(list.get_hint() == ViewWrapper.Hint.SIMILAR && this.visible) {
			SimilarPane sp = (SimilarPane)(list);
			
			if(!similarsFetched) { // still fetching similar songs
				errorBox.show();
				list.hide();
				albumView.hide();
				
				return;
			}
			else if( !(lm.current_songs().size == sp.get_songs().size && lm.current_songs().contains_all(sp.get_songs())) ) { // not currently playing list and have fetched
				if(songs.size < 10) { // say we could not find similar songs
					errorBox.show_icon = true;
					errorBox.setWarning("<span weight=\"bold\" size=\"larger\">No similar songs found\n</span>\nBeatBox could not find songs similar to <b>" + lm.song_info.song.title.replace("&", "&amp;") + "</b> by <b>" + lm.song_info.song.artist.replace("&", "&amp;") + "</b>.\n\nMake sure all song info is correct and you are connected to the Internet.\nSome songs may not have matches.");
					errorBox.show();
					list.hide();
					albumView.hide();
					stdout.printf("2\n");
					return;
				}
				else {
					errorBox.hide();
					
					sp._base = lm.song_info.song;
				}
			}
			/* this stops similar from refreshing when a song from that list is playing. add !set_songs to make sure to update when
			 * the user searches
			 * */
			else if(lm.current_songs().size == sp.get_songs().size && lm.current_songs().contains_all(sp.get_songs()) && similarsFetched && list.get_is_current()) { // needs update, but won't because not worthy
				stdout.printf("3\n");
				return;
			}
		}
		/* END special case */
		
		/* Even if it's a non-visual update, prepare the view's for the visual update */
		if(!this.visible || force) {
			//stdout.printf("searching..\n");
			Collection<int> potentialShowing = new LinkedList<int>();
			Collection<int> potentialShowingAlbum = new LinkedList<int>();
			
			lm.do_search(lw.searchField.get_text(), hint,
					lw.miller.genres.get_selected(), lw.miller.artists.get_selected(), lw.miller.albums.get_selected(),
					songs, ref potentialShowing, ref potentialShowingAlbum);
			
			list.set_show_next(potentialShowing);
			albumView.set_show_next(potentialShowingAlbum);
			showingSongs = potentialShowing;
			//stdout.printf("searched\n");
		}
		
		if(this.visible || force) {
			if(type == ViewType.LIST) {
				//stdout.printf("populating\n");
				list.populate_view();
				//stdout.printf("populated\n");
				list.show();
				albumView.hide();
				
				if(!isCurrentView)
					list.set_is_current_view(false);
			}
			else {
				albumView.populate_view();
				list.hide();
				albumView.show();
				
				if(!isCurrentView)
					albumView.set_is_current_view(false);
			}
		}
	}
	
	public void set_statusbar_text() {
		switch(currentView) {
			case ViewType.FILTER_VIEW:
			case ViewType.LIST:
				list.set_statusbar_text();
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
	
	public void millerChanged() {
		if(lw.initializationFinished && isCurrentView) {
			stdout.printf("miller changed\n");
			doUpdate(this.currentView, songs, false, true);
			
			showing_all = (showingSongs.size == songs.size);
			
			list.set_statusbar_text();
		}
		else if(lw.initializationFinished) {
			// start thread to prepare for when it is current
			try {
				Thread.create<void*>(update_view_thread, false);
			}
			catch(GLib.ThreadError err) {
				
			}
		}
	}
	
	public virtual void searchFieldChanged() {
		if(lw.initializationFinished && isCurrentView && lw.searchField.get_text().length != 1 && this.visible) {
			timeout_search.offer_head(lw.searchField.get_text().down());
			Timeout.add(100, () => {
				
				string to_search = timeout_search.poll_tail();
				if(to_search != lw.searchField.get_text() || to_search == last_search)
					return false;
				
				stdout.printf("search field changed\n");
				doUpdate(this.currentView, songs, false, true);
					
				last_search = to_search;
				showing_all = (showingSongs.size == songs.size);
				
				lm.settings.setSearchString(to_search);
				list.set_statusbar_text();
				
				return false;
			});
		}
		else if(lw.initializationFinished && lw.searchField.get_text().length != 1){
			// start thread to prepare for when it is current
			try {
				Thread.create<void*>(update_view_thread, false);
			}
			catch(GLib.ThreadError err) {
				
			}
		}
	}
	
	public void* update_view_thread () {
		doUpdate(this.currentView, songs, false, false);
		
		return null;	
	}
}
