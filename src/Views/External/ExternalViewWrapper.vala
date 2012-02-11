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

public class BeatBox.ExternalViewWrapper : VBox {
	public LibraryManager lm;
	public LibraryWindow lw;
	public ExternalExternalMusicTreeView list;
	public ExternalAlbumView albumView;
	private WarningLabel errorBox;
	public Collection<Media> medias;
	
	public ViewType currentView;
	public bool isCurrentView;
	
	// for Hint.SIMILAR only
	public bool similarsFetched;
	
	public enum ViewType {
		LIST,
		FILTER_VIEW
	}
	
	public ViewWrapper(LibraryManager lmm, LibraryWindow lww, Collection<Media> medias, string sort, Gtk.SortType dir, ExternalMusicTreeView.Hint the_hint, int id) {
		lm = lmm;
		lw = lww;
		this.medias = medias;
		
		if(the_hint != ExternalMusicTreeView.Hint.SIMILAR)
			list = new ExternalMusicTreeView(lm, lw, sort, dir, the_hint, id);
		else {
			list = new SimilarPane(lm, lw);
			errorBox = new WarningLabel();
		}
		
		//list.populateView(medias, false);
		albumView = new ExternalAlbumView(lm, lw, medias);
		
		pack_start(list, true, true, 0);
		pack_start(albumView, true, true, 0);
		
		if(list.hint == ExternalMusicTreeView.Hint.SIMILAR)
			pack_start(errorBox, true, true, 0);
		
		albumView.needsUpdate = true;
		list.needsUpdate = true;
		
		if(the_hint == ExternalMusicTreeView.Hint.MUSIC)
			doUpdate(ViewType.LIST, medias, true);
		
		albumView.itemClicked.connect(filterViewItemClicked);
		lw.viewSelector.notify["selected"].connect(selectorViewChanged);
		lm.media_played.connect(mediaPlayed);
	}
	
	public virtual void selectorViewChanged() {
		switch(lw.viewSelector.selected) {
			case 0:
				doUpdate(ViewWrapper.ViewType.FILTER_VIEW, medias, false);
				break;
			case 1:
			case 2:
				doUpdate(ViewWrapper.ViewType.LIST, medias, false);
				break;
		}
	}
	
	public void setIsCurrentView(bool isIt) {
		isCurrentView = isIt;
		
		if(!isIt) {
			list.is_current_view = false;
			albumView.isCurrentView = false;
		}
		else {
			doUpdate(currentView, medias, false);
		}
	}
	
	public ViewType getView() {
		return currentView;
	}
	
	public void mediaPlayed(int id, int old) {
		if(list.hint != ExternalMusicTreeView.Hint.SIMILAR)
			return;
			
		if(!(lm.current_medias().size == list.get_medias().size && lm.current_medias().contains_all(list.get_medias()))) {
			/* a new media is played. don't show list until medias have loaded */
			
			errorBox.setWarning("<span weight=\"bold\" size=\"larger\">Loading similar medias</span>\nBeatBox is loading medias similar to " + lm.media_from_id(id).title.replace("&", "&amp;") + " by " + lm.media_from_id(id).artist.replace("&", "&amp;") + "...");
			errorBox.show();
			list.hide();
			albumView.hide();
			similarsFetched = false;
		}
	}
	
	public void clear() {
		var empty = new LinkedList<Media>();
		
		this.medias = empty;
		
		list.set_medias(empty);
		list.populateView(empty, false, false);
		
		albumView.set_medias(empty);
		albumView.generateHTML(empty, false);
	}
	
	public void doUpdate(ViewType type, Collection<Media> medias, bool force) {
		this.medias = medias;
		currentView = type;
		
		if(type == ViewType.LIST) {
			list.show();
			albumView.hide();
			
			if(isCurrentView) {
				list.is_current_view = true;
				list.populateView(medias, false, force);
			}
			else
				list.is_current_view = false;
		}
		else {
			list.hide();
			albumView.show();
			
			if(isCurrentView) {
				albumView.isCurrentView = true;
				albumView.generateHTML(medias, force);
			}
			else
				albumView.isCurrentView = false;
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
		
		lw.miller.albums.selected = album;
	}
}
