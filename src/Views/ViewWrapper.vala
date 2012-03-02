/*-
 * Copyright (c) 2011-2012	   Scott Ringwelski <sgringwe@mtu.edu>
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
	public bool needs_update;
	
	public ViewWrapper.Hint hint;
	public int relative_id;
	public ViewType currentView;
	public bool isCurrentView;
	
	LinkedList<string> timeout_search;//stops from doing useless search (timeout)
	string last_search;//stops from searching same thing multiple times
	bool showing_all; // stops from searching unnecesarilly when changing b/w 0 words and search get_hint().
	bool setting_search;
	
	// for Hint.SIMILAR only
	public bool similarsFetched;
	bool in_update;
	
	public enum ViewType {
		LIST,
		FILTER_VIEW
	}
	
	public enum Hint {
		NONE,
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
		last_search = "";
		timeout_search = new LinkedList<string>();
		setting_search = false;
		
		relative_id = id;
		hint = the_hint;
		
		errorBox = new WarningLabel();
		if(the_hint == ViewWrapper.Hint.SIMILAR) {
			list = new SimilarPane(lm, lw);
			errorBox.show_icon = false;
			errorBox.setWarning ("<span weight=\"bold\" size=\"larger\">" + _("Similar Media View") + "</span>\n\n" + _("In this view, BeatBox will automatically find medias similar to the one you are playing.") + "\n" + _("You can then start playing those medias, or save them for later."), null);
		}
		else if(the_hint == ViewWrapper.Hint.PODCAST || the_hint == ViewWrapper.Hint.DEVICE_PODCAST) {
			list = new PodcastListView(lm, lw);
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
			errorBox.show_icon = false;
			errorBox.setWarning ("<span weight=\"bold\" size=\"larger\">" + _("Audio CD Invalid") + "</span>\n\n" + _("BeatBox could not read the contents of this Audio CD."), null);
		}
		
		if(the_hint == ViewWrapper.Hint.PODCAST) {
			errorBox.show_icon = false;
			errorBox.setWarning ("<span weight=\"bold\" size=\"larger\">" + _("No Podcasts Found") + "</span>\n\n" + _("To add a podcast, visit a website such as Miro Guide to find RSS Feeds.") + "\n" + _("You can then copy and paste the feed into the \"Add Podcast\" window by right clicking on \"Podcasts\"."), null);
		}
		
		if(the_hint == ViewWrapper.Hint.STATION) {
			errorBox.show_icon = false;
			errorBox.setWarning ("<span weight=\"bold\" size=\"larger\">" + _("No Internet Radio Stations Found") + "</span>\n\n" + _("To add a station, visit a website such as SomaFM to find PLS or M3U files.") + "\n" + _("You can then import the file to add the station."), null);
		}
		
		//list.populate_view(medias, false);
		albumView = new AlbumView(lm, lw, get_media_ids());
		
		pack_end(list, true, true, 0);
		pack_end(albumView, true, true, 0);
		
		if(hint == ViewWrapper.Hint.SIMILAR || hint == ViewWrapper.Hint.CDROM ||
		hint == ViewWrapper.Hint.PODCAST || hint == ViewWrapper.Hint.STATION)
			pack_start(errorBox, true, true, 0);
		
		//doUpdate(currentView, get_media_ids(), false, false, false);
		needs_update = true;
		no_show_all = true;
		
		lw.viewSelector.mode_changed.connect(selectorViewChanged);
		//lm.media_played.connect(mediaPlayed);
		lm.medias_added.connect(medias_added);
		lm.medias_updated.connect(medias_updated);
		lm.medias_removed.connect(medias_removed);
		
		lw.searchField.changed.connect(searchFieldChanged);
		lw.miller.changed.connect(millerChanged);
	}
	
	public ViewWrapper.with_view (LibraryManager lmm, LibraryWindow lww, Collection<int> the_medias, string sort, Gtk.SortType dir, ViewWrapper.Hint the_hint, int id, BaseListView view) {
		lm = lmm;
		lw = lww;
		
		medias = new HashMap<int, int>();
		foreach(int i in the_medias)
			medias.set(i, 1);
		
		media_count = medias.size;
		showingMedias = new HashMap<int, int>();
		last_search = "";
		timeout_search = new LinkedList<string>();
		setting_search = false;
		
		relative_id = id;
		hint = the_hint;
		
		errorBox = new WarningLabel();
		list = view;
		
		if(the_hint == ViewWrapper.Hint.CDROM) {
			errorBox.show_icon = false;
			errorBox.setWarning ("<span weight=\"bold\" size=\"larger\">" + _("Audio CD Invalid") + "</span>\n\n" + _("BeatBox could not read the contents of this Audio CD."), null);
		}
		
		if(the_hint == ViewWrapper.Hint.PODCAST) {
			errorBox.show_icon = false;
			errorBox.setWarning ("<span weight=\"bold\" size=\"larger\">" + _("No Podcasts Found") + "</span>\n\n" + _("To add a podcast, visit a website such as Miro Guide to find RSS Feeds.") + "\n" + _("You can then copy and paste the feed into the \"Add Podcast\" window by right clicking on \"Podcasts\"."), null);
		}
		
		if(the_hint == ViewWrapper.Hint.STATION) {
			errorBox.show_icon = false;
			errorBox.setWarning ("<span weight=\"bold\" size=\"larger\">" + _("No Internet Radio Stations Found") + "</span>\n\n" + _("To add a station, visit a website such as SomaFM to find PLS or M3U files.") + "\n" + _("You can then import the file to add the station."), null);
		}
		
		//list.populate_view(medias, false);
		albumView = new AlbumView(lm, lw, get_media_ids());
		
		pack_end(list, true, true, 0);
		pack_end(albumView, true, true, 0);
		
		if(hint == ViewWrapper.Hint.SIMILAR || hint == ViewWrapper.Hint.CDROM ||
		hint == ViewWrapper.Hint.PODCAST || hint == ViewWrapper.Hint.STATION)
			pack_start(errorBox, true, true, 0);
		
		//doUpdate(currentView, get_media_ids(), false, false, false);
		needs_update = true;
		no_show_all = true;
		
		lw.viewSelector.mode_changed.connect(selectorViewChanged);
		//lm.media_played.connect(mediaPlayed);
		lm.medias_added.connect(medias_added);
		lm.medias_updated.connect(medias_updated);
		lm.medias_removed.connect(medias_removed);
		
		lw.searchField.changed.connect(searchFieldChanged);
		lw.miller.changed.connect(millerChanged);
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
					debug("populating millers\n");
					lw.miller.populate_columns("", medias.keys);
				}
				break;
		}
	}
	
	public void set_is_current_view(bool isIt) {
		isCurrentView = isIt;
		
		setting_search = true;
		if(!isIt) {
			list.set_is_current_view(false);
			albumView.set_is_current_view(false);
		}
		else {
			lw.searchField.set_text(last_search);
		}
		setting_search = false;
	}
	
	public ViewType getView() {
		return currentView;
	}
	
	public void show_retrieving_similars() {
		if(hint != ViewWrapper.Hint.SIMILAR || lm.media_info.media == null)
			return;
			
		errorBox.show_icon = false;
		errorBox.setWarning("<span weight=\"bold\" size=\"larger\">" + _("Loading similar songs") + "</span>\n\n" + _("BeatBox is loading songs similar to") + " <b>" + lm.media_info.media.title.replace("&", "&amp;") + "</b> by <b>" + lm.media_info.media.artist.replace("&", "&amp;") + "</b> " + _("..."), null);
		errorBox.show();
		list.hide();
		albumView.hide();
		lw.alv.hide ();
		similarsFetched = false;
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
		
		if(isCurrentView) {
			// find which medias belong here
			LinkedList<int> shouldShow, shouldShowAlbum, shouldBe, shouldBeAlbum;
			
			LinkedList<int> to_search = new LinkedList<int>();

			if(hint == ViewWrapper.Hint.SMART_PLAYLIST)
				to_search = lm.smart_playlist_from_id(relative_id).analyze(lm, ids);
			else
				to_search = ids;
			
			var selected_miller_artist = lw.miller.get_column (MillerColumn.Category.ARTIST).get_selected ();
			
			lm.do_search (to_search, out shouldShow, out shouldShowAlbum, null, null, null,
			              hint, lw.searchField.get_text (), selected_miller_artist);

			lm.do_search (to_search, out shouldBe, out shouldBeAlbum, null, null, null, hint);

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
			// TODO: contains is slow
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
			
			if(isCurrentView) {
				Idle.add( () => {
					list.append_medias(to_add);
					albumView.append_medias(to_add);
					
					list.remove_medias(to_remove_show);
					albumView.remove_medias(to_remove_show);
					
					set_statusbar_info();
					check_show_error_box();
					
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
		
		check_show_error_box();
		
		needs_update = true;
		in_update = false;
	}
	
	public void clear() {
		var empty = new HashMap<int, int>();
		
		this.medias = empty;
		showingMedias = empty;
		
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

			
			var selected_miller_artist = lw.miller.get_column (MillerColumn.Category.ARTIST).get_selected ();

			lm.do_search(to_add, out potentialShowing, out potentialShowingAlbum, null, null, null,
			             hint, lw.searchField.get_text(), selected_miller_artist);
			
			list.append_medias(potentialShowing);
			albumView.append_medias(potentialShowingAlbum);
			
			foreach(int i in potentialShowing)
				showingMedias.set(i, 1);
			
			if(isCurrentView) {
				set_statusbar_info();
				check_show_error_box();
			}
		}
		
		needs_update = true;
		in_update = false;
	}
	
	bool check_show_error_box() {
		if((hint == ViewWrapper.Hint.CDROM || hint == ViewWrapper.Hint.PODCAST ||
		hint == ViewWrapper.Hint.STATION) && this.visible) {
			int size_check = media_count;
			if(hint == ViewWrapper.Hint.PODCAST) {
				size_check = 0;
				foreach(int i in lm.podcast_ids()) {
					if(!lm.media_from_id(i).isTemporary)
						++size_check;
				}
			}
			if(hint == ViewWrapper.Hint.STATION) {
				size_check = 0;
				foreach(int i in lm.station_ids()) {
					if(lm.media_from_id(i) != null)
						++size_check;
				}
			}
			
			if(size_check == 0) {
				errorBox.show_icon = (hint == ViewWrapper.Hint.CDROM);
				errorBox.show_all();
				list.hide();
				albumView.hide();
				lw.alv.hide ();
				
				return true;
			}
			else {
				errorBox.hide();
				
				if(currentView == ViewType.LIST) {
					list.show_all();
					albumView.hide();
					lw.alv.hide ();
				}
				else {
					list.hide();
					albumView.show_all();
				}
			}
		}
		
		return false;
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
		
		currentView = type;
		
		if(!in_thread && check_show_error_box()) {
			in_update = false;
			return;
		}
		
		/* BEGIN special case for similar medias */
		if(!in_thread && list.get_hint() == ViewWrapper.Hint.SIMILAR && this.visible) {
			SimilarPane sp = (SimilarPane)(list);
			
			if(!similarsFetched) { // still fetching similar medias
				errorBox.show_all();
				list.hide();
				albumView.hide();
				lw.alv.hide ();
				debug("1\n");
				
				in_update = false;
				return;
			}
			else {
				if(medias.size < 10) { // say we could not find similar medias
					errorBox.show_icon = true;
					errorBox.setWarning("<span weight=\"bold\" size=\"larger\">" + _("No similar songs found") + "\n</span>\n" + _("BeatBox could not find songs similar to" + " <b>" + lm.media_info.media.title.replace("&", "&amp;") + "</b> by <b>" + lm.media_info.media.artist.replace("&", "&amp;") + "</b>.\n") + _("Make sure all song info is correct and you are connected to the Internet.\nSome songs may not have matches."), Justification.LEFT);
					errorBox.show_all();
					list.hide();
					albumView.hide();
					lw.alv.hide ();
					debug("2\n");
					
					in_update = false;
					return;
				}
				else {
					debug("2.5\n");
					errorBox.hide();
					
					sp._base = lm.media_info.media;
				}
			}
			
			/*if(lm.current_medias().size == list.get_medias().size && lm.current_medias().contains_all(list.get_medias())) { // don't update, user is playing current list
				debug("3\n");
				return;
			}*/
		}
		/* END special case */
		
		/* Even if it's a non-visual update, prepare the view's for the visual update */
		if(!this.visible || force || needs_update) {
			//debug("searching..\n");
			LinkedList<int> potentialShowing = new LinkedList<int>();
			LinkedList<int> potentialShowingAlbum = new LinkedList<int>();
			
			debug("searching to populate with %d medias\n", medias.size);

			
			var selected_miller_artist = lw.miller.get_column (MillerColumn.Category.ARTIST).get_selected ();

			lm.do_search(get_media_ids(), out potentialShowing, out potentialShowingAlbum, null, null, null,
			             hint, last_search, selected_miller_artist);
			
			//debug("searching done\n");
			list.set_show_next(potentialShowing);
			albumView.set_show_next(potentialShowingAlbum);
			
			showingMedias = new HashMap<int, int>();
			foreach(int i in potentialShowing)
				showingMedias.set(i, 1);
			
			needs_update = false;
			//debug("searched\n");
		}
		
		//debug("populating\n");
		if(!in_thread && (this.visible || force)) {
			errorBox.hide();
			
			if(type == ViewType.LIST) {
				list.populate_view();
				list.show_all();
				albumView.hide();
				lw.alv.hide ();
				
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
		//debug("populated\n");
	}
	
	public void set_statusbar_info() {
		switch(currentView) {
			case ViewType.FILTER_VIEW:
			case ViewType.LIST:
				list.set_statusbar_info();
				break;
		}
	}
	
	public void millerChanged() {
		if(lw.initializationFinished && isCurrentView) {
			//debug("miller changed\n");
			doUpdate(this.currentView, medias.keys, false, true, false);
			
			showing_all = (showingMedias.size == medias.size);
			
			list.set_statusbar_info();
		}
	}
	
	public virtual void searchFieldChanged() {
		if(!setting_search && lw.initializationFinished && isCurrentView && lw.searchField.get_text().length != 1 && this.visible) {
			timeout_search.offer_head(lw.searchField.get_text().down());
			Timeout.add(200, () => {
				
				string to_search = timeout_search.poll_tail();
				if(to_search != lw.searchField.get_text() || to_search == last_search)
					return false;
				
				if(!setting_search && isCurrentView)
					last_search = to_search;
				
				doUpdate(this.currentView, medias.keys, false, true, false);
				
				showing_all = (showingMedias.size == medias.size);
				
				lm.settings.setSearchString(to_search);
				list.set_statusbar_info();
				
				return false;
			});
		}
	}
}
