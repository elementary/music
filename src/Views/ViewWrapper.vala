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
	HashMap<int, int> medias;
	public HashMap<int, int> showingMedias;
	public int media_count;
	bool needs_update;
	
	public ViewWrapper.Hint hint;
	public int relative_id;
	public ViewType currentView;
	public bool isCurrentView;
	
	LinkedList<string> timeout_search;//stops from doing useless search (timeout)
	string last_search;//stops from searching same thing multiple times
	bool showing_all; // stops from searching unnecesarilly when changing b/w 0 words and search get_hint().
	
	// for Hint.SIMILAR only
	public bool similarsFetched;
	bool in_update;
	
	public enum ViewType {
		LIST,
		FILTER_VIEW
	}
	
	public enum Hint {
		MUSIC,
		PODCAST,
		AUDIOBOOK,
		STATION,
		SIMILAR,
		QUEUE,
		HISTORY,
		PLAYLIST,
		SMART_PLAYLIST,
		CDROM,
		DEVICE_AUDIO,
		DEVICE_PODCAST,
		DEVICE_AUDIOBOOK,
		ALBUM_LIST;
	}
	
	public ViewWrapper(LibraryManager lmm, LibraryWindow lww, Collection<int> the_medias, string sort, Gtk.SortType dir, ViewWrapper.Hint the_hint, int id) {
		lm = lmm;
		lw = lww;
		
		medias = new HashMap<int, int>();
		foreach(int i in the_medias)
			medias.set(i, 1);
		
		media_count = medias.size;
		showingMedias = new HashMap<int, int>();
		timeout_search = new LinkedList<string>();
		
		hint = the_hint;
		
		if(the_hint == ViewWrapper.Hint.SIMILAR) {
			list = new SimilarPane(lm, lw);
			errorBox = new WarningLabel();
			errorBox.show_icon = false;
			errorBox.setWarning ("<span weight=\"bold\" size=\"larger\">Similar Media View</span>\n\nIn this view, BeatBox will automatically find medias similar to the one you are playing.\nYou can then start playing those medias, or save them for later.", null);
		}
		else if(the_hint == ViewWrapper.Hint.PODCAST || the_hint == ViewWrapper.Hint.DEVICE_PODCAST) {
			list = new PodcastListView(lm, lw, sort, dir, the_hint, id);
		}
		else if(the_hint == ViewWrapper.Hint.STATION) {
			list = new RadioListView(lm, lw, sort, dir, the_hint, id);
		}
		else if(the_hint == ViewWrapper.Hint.AUDIOBOOK || the_hint == ViewWrapper.Hint.DEVICE_AUDIOBOOK) {
			list = new MusicTreeView(lm, lw, sort, dir, the_hint, id);
		}
		else {
			list = new MusicTreeView(lm, lw, sort, dir, the_hint, id);
		}
		
		if(the_hint == ViewWrapper.Hint.CDROM) {
			errorBox = new WarningLabel();
			errorBox.show_icon = false;
			errorBox.setWarning ("<span weight=\"bold\" size=\"larger\">Audio CD Invalid</span>\n\nBeatBox could not read the contents of this Audio CD.", null);
		}
		
		//list.populate_view(medias, false);
		albumView = new AlbumView(lm, lw, get_media_ids());
		
		pack_end(list, true, true, 0);
		pack_end(albumView, true, true, 0);
		
		if(hint == ViewWrapper.Hint.SIMILAR || hint == ViewWrapper.Hint.CDROM)
			pack_start(errorBox, true, true, 0);
		
		needs_update = true;
		albumView.set_show_next(get_media_ids());
		list.set_show_next(get_media_ids());
		
		
		//if(the_hint == ViewWrapper.Hint.MUSIC)
		//	doUpdate(ViewType.LIST, get_media_ids(), true, true, false);
		
		if(albumView is AlbumView)
			((AlbumView)albumView).itemClicked.connect(filterViewItemClicked);
		
		no_show_all = true;
		
		lw.viewSelector.mode_changed.connect(selectorViewChanged);
		lm.media_played.connect(mediaPlayed);
		lm.medias_added.connect(medias_added);
		lm.medias_updated.connect(medias_updated);
		lm.medias_removed.connect(medias_removed);
		
		lw.searchField.changed.connect(searchFieldChanged);
		lw.miller.changed.connect(millerChanged);
		
		// initialize in thread
		searchFieldChanged();
	}
	
	public Collection<int> get_media_ids() {
		return medias.keys;
	}
	
	public virtual void selectorViewChanged() {
		if(!lw.initializationFinished || !isCurrentView)
			return;
		
		switch(lw.viewSelector.selected) {
			case 0:
				doUpdate(ViewWrapper.ViewType.FILTER_VIEW, get_media_ids(), false, false, false);
				break;
			case 1:
				doUpdate(ViewWrapper.ViewType.LIST, get_media_ids(), false, false, false);
				break;
			case 2:
				doUpdate(ViewWrapper.ViewType.LIST, get_media_ids(), false, false, false);
				
				if(isCurrentView) {
					stdout.printf("populating millers\n");
					lw.miller.populateColumns("", medias.keys);
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
	
	public void mediaPlayed(int id, int old) {
		if(list.get_hint() != ViewWrapper.Hint.SIMILAR)
			return;
			
		if(!(lm.current_medias().size == list.get_medias().size && lm.current_medias().contains_all(list.get_medias()))) {
			/* a new media is played. don't show list until medias have loaded */
			errorBox.show_icon = false;
			errorBox.setWarning("<span weight=\"bold\" size=\"larger\">Loading similar songs</span>\n\nBeatBox is loading songs similar to <b>" + lm.media_from_id(id).title.replace("&", "&amp;") + "</b> by <b>" + lm.media_from_id(id).artist.replace("&", "&amp;") + "</b> ...", null);
			errorBox.show();
			list.hide();
			albumView.hide();
			similarsFetched = false;
		}
	}
	
	void medias_added(LinkedList<int> ids) {
		add_medias(ids);
	}
	
	// do search to find which ones should be added, removed from this particular view
	// does not re-anaylyze smart playlists or playlists
	public void medias_updated(LinkedList<int> ids) {
		if(in_update)
			return;
		
		in_update = true;
		needs_update = true;
		
		if(isCurrentView) {
			// find which medias belong here
			var shouldShow = new LinkedList<int>();
			var shouldShowAlbum = new LinkedList<int>();
			var shouldBe = new LinkedList<int>();
			var shouldBeAlbum = new LinkedList<int>();
			
			lm.do_search(lw.searchField.get_text(), hint,
					lw.miller.genres.get_selected(), lw.miller.artists.get_selected(), lw.miller.albums.get_selected(),
					ids, ref shouldShow, ref shouldShowAlbum);
			lm.do_search("", hint,
					"All Genres", "All Artists", "All Albums",
					ids, ref shouldBe, ref shouldBeAlbum);
			
			stdout.printf("of %d ids, %d should stay, %d should show\n", ids.size, shouldBe.size, shouldShow.size);
			
			var to_add = new LinkedList<int>();
			var to_remove = new LinkedList<int>();
			var to_remove_show = new LinkedList<int>();
			
			// add elements that should be here
			foreach(int i in shouldBe) {
				medias.set(i, 1);
			}
			
			// add elements that should show
			foreach(int i in shouldShow) {
				if(showingMedias.get(i) == 0)
					to_add.add(i);
				
				showingMedias.set(i, 1);
			}
			
			// remove elements
			foreach(int i in ids) {
				if(!shouldBe.contains(i)) {
					to_remove.add(i);
					medias.unset(i);
				}
			}
			
			foreach(int i in ids) {
				if(!shouldShow.contains(i)) {
					to_remove_show.add(i);
					showingMedias.unset(i);
				}
			}
			
			stdout.printf("removing %d adding %d\n", to_remove_show.size, to_add.size);
			if(isCurrentView) {
				Idle.add( () => {
					list.append_medias(to_add);
					albumView.append_medias(to_add);
					
					list.remove_medias(to_remove_show);
					albumView.remove_medias(to_remove_show);
					set_statusbar_text();
				
					return false;
				});
			}
		}
		else {
			needs_update = true;
		}
		
		in_update = false;
	}
	
	void medias_removed(LinkedList<int> ids) {
		if(in_update)
			return;
		
		in_update = true;
		var to_remove = new LinkedList<int>();
		foreach(int i in ids) {
			medias.unset(i);
			
			if(showingMedias.get(i) != 0)
				to_remove.add(i);
			
			showingMedias.unset(i);
		}
		
		list.remove_medias(to_remove);
		albumView.remove_medias(to_remove);
		
		in_update = false;
		needs_update = true;
	}
	
	public void clear() {
		var empty = new HashMap<int, int>();
		
		this.medias = empty;
		
		list.set_show_next(get_media_ids());
		list.populate_view();
		
		albumView.set_show_next(get_media_ids());
		albumView.populate_view();
	}
	
	public void add_medias(LinkedList<int> new_medias) {
		if(in_update)
			return;
		
		in_update = true;
		if(hint == Hint.MUSIC || hint == Hint.PODCAST || hint == Hint.STATION) {
			// find which medias to add
			LinkedList<int> to_add = new LinkedList<int>();
			foreach(int i in new_medias) {
				if(medias.get(i) == 0) {
					to_add.add(i);
					medias.set(i, 1);
				}
			}
			
			media_count = medias.size;
			
			LinkedList<int> potentialShowing = new LinkedList<int>();
			LinkedList<int> potentialShowingAlbum = new LinkedList<int>();
			lm.do_search(lw.searchField.get_text(), hint,
					lw.miller.genres.get_selected(), lw.miller.artists.get_selected(), lw.miller.albums.get_selected(),
					to_add, ref potentialShowing, ref potentialShowingAlbum);
			
			list.append_medias(potentialShowing);
			albumView.append_medias(potentialShowingAlbum);
			
			showingMedias.clear();
			foreach(int i in potentialShowing)
				showingMedias.set(i, 1);
			
			if(isCurrentView)
				set_statusbar_text();
		}
		
		in_update = false;
		needs_update = true;
	}
	
	/** Updates the displayed view and its content
	 * 
	 * @param view the view to show/update
	 * @param medias If set_medias is true, then set this.medias = medias
	 * @param set_medias whether or not to set the medias
	 * @param do_visual If true, visually populate as well
	*/
	public void doUpdate(ViewType type, Collection<int> up_medias, bool set_medias, bool force, bool in_thread) {
		if(in_update)
			return;
			
		//if(!force && !set_medias && !needs_update && (type == currentView))
		//	return;
		
		in_update = true;
		
		if(set_medias) {
			medias = new HashMap<int, int>();
			foreach(int i in up_medias)
				medias.set(i, 1);
			
			media_count = medias.size;
		}
		
		//stdout.printf("in_thread: %d\n", in_thread ? 1 : 0);
		currentView = type;
		
		if(!in_thread && hint == ViewWrapper.Hint.CDROM && this.visible) {
			stdout.printf("updating cd with %d\n", media_count);
			if(media_count == 0) {
				errorBox.show_icon = true;
				errorBox.show();
				list.hide();
				albumView.hide();
				
				in_update = false;
				return;
			}
			else {
				errorBox.hide();
				list.show();
				albumView.show();
			}
		}
		/* BEGIN special case for similar medias */
		if(!in_thread && list.get_hint() == ViewWrapper.Hint.SIMILAR && this.visible) {
			SimilarPane sp = (SimilarPane)(list);
			
			if(!similarsFetched) { // still fetching similar medias
				errorBox.show();
				list.hide();
				albumView.hide();
				stdout.printf("1\n");
				
				in_update = false;
				return;
			}
			else {
				if(medias.size < 10) { // say we could not find similar medias
					errorBox.show_icon = true;
					errorBox.setWarning("<span weight=\"bold\" size=\"larger\">No similar songs found\n</span>\nBeatBox could not find songs similar to <b>" + lm.media_info.media.title.replace("&", "&amp;") + "</b> by <b>" + lm.media_info.media.artist.replace("&", "&amp;") + "</b>.\nMake sure all song info is correct and you are connected to the Internet.\nSome songs may not have matches.", Justification.LEFT);
					errorBox.show();
					list.hide();
					albumView.hide();
					stdout.printf("2\n");
					
					in_update = false;
					return;
				}
				else {
					stdout.printf("2.5\n");
					errorBox.hide();
					
					sp._base = lm.media_info.media;
				}
			}
			
			/*if(list.get_is_current()) { // don't update, user is playing current list
				stdout.printf("3\n");
				return;
			}*/
		}
		/* END special case */
		
		/* Even if it's a non-visual update, prepare the view's for the visual update */
		if(!this.visible || force || needs_update) {
			//stdout.printf("searching..\n");
			LinkedList<int> potentialShowing = new LinkedList<int>();
			LinkedList<int> potentialShowingAlbum = new LinkedList<int>();
			
			//stdout.printf("seraching to populate with %d medias\n", medias.size);
			lm.do_search(lw.searchField.get_text(), hint,
					lw.miller.genres.get_selected(), lw.miller.artists.get_selected(), lw.miller.albums.get_selected(),
					get_media_ids(), ref potentialShowing, ref potentialShowingAlbum);
			//stdout.printf("seraching done\n");
			list.set_show_next(potentialShowing);
			albumView.set_show_next(potentialShowingAlbum);
			
			showingMedias = new HashMap<int, int>();
			foreach(int i in potentialShowing)
				showingMedias.set(i, 1);
			
			needs_update = false;
			//stdout.printf("searched\n");
		}
		
		//stdout.printf("populating\n");
		if(!in_thread && (this.visible || force)) {
			if(type == ViewType.LIST) {
				list.populate_view();
				list.show_all();
				albumView.hide();
				
				if(!isCurrentView)
					list.set_is_current_view(false);
			}
			else {
				albumView.populate_view();
				list.hide();
				albumView.show_all();
				
				if(!isCurrentView)
					albumView.set_is_current_view(false);
			}
		}
		
		in_update = false;
		//stdout.printf("populated\n");
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
		lw.miller.albums.set_selected(album);
	}
	
	public void millerChanged() {
		if(lw.initializationFinished && isCurrentView) {
			//stdout.printf("miller changed\n");
			doUpdate(this.currentView, medias.keys, false, true, false);
			
			showing_all = (showingMedias.size == medias.size);
			
			list.set_statusbar_text();
		}
	}
	
	public virtual void searchFieldChanged() {
		if(lw.initializationFinished && isCurrentView && lw.searchField.get_text().length != 1 && this.visible) {
			timeout_search.offer_head(lw.searchField.get_text().down());
			Timeout.add(100, () => {
				
				string to_search = timeout_search.poll_tail();
				if(to_search != lw.searchField.get_text() || to_search == last_search)
					return false;
				
				//stdout.printf("search field changed\n");
				doUpdate(this.currentView, medias.keys, false, true, false);
					
				last_search = to_search;
				showing_all = (showingMedias.size == medias.size);
				
				lm.settings.setSearchString(to_search);
				list.set_statusbar_text();
				
				return false;
			});
		}
	}
}
