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

public class BeatBox.SideTreeView : ElementaryWidgets.SideBar {
	LibraryManager lm;
	LibraryWindow lw;
	
	public TreeIter library_iter;
	public TreeIter library_music_iter;
	public TreeIter library_podcasts_iter;
	public TreeIter library_audiobooks_iter;
	
	public TreeIter devices_iter;
	public TreeIter devices_cdrom_iter;
	
	public TreeIter network_iter;
	public TreeIter network_radio_iter;
	public TreeIter network_store_iter;
	
	public TreeIter playlists_iter;
	public TreeIter playlists_queue_iter;
	public TreeIter playlists_history_iter;
	public TreeIter playlists_similar_iter;
	
	//for podcast right click
	Menu podcastMenu;
	MenuItem podcastAdd;
	MenuItem podcastRefresh;
	
	//for cdrom right click
	Menu CDMenu;
	MenuItem CDimportToLibrary;
	MenuItem CDeject;
	
	//for device right click
	Menu deviceMenu;
	MenuItem deviceImportToLibrary;
	MenuItem deviceSync;
	
	//for playlist right click
	Menu playlistMenu;
	MenuItem playlistNew;
	MenuItem smartPlaylistNew;
	MenuItem playlistEdit;
	MenuItem playlistRemove;
	MenuItem playlistSave;
	MenuItem playlistExport;
	MenuItem playlistImport;
	
	//for radio station right click
	Menu radioMenu;
	MenuItem radioImportStations;
	
	Widget current_widget;
	
	public SideTreeView(LibraryManager lmm, LibraryWindow lww) {
		this.lm = lmm;
		this.lw = lww;
		
		lm.dm.device_added.connect(deviceAdded);
		lm.dm.device_removed.connect(deviceRemoved);
		
		buildUI();
	}
	
	public void buildUI() {
		deviceMenu = new Menu();
		deviceImportToLibrary = new MenuItem.with_label("Import from Device");
		deviceSync = new MenuItem.with_label("Sync");
		deviceMenu.append(deviceImportToLibrary);
		deviceMenu.append(deviceSync);
		deviceImportToLibrary.activate.connect(deviceImportToLibraryClicked);
		deviceSync.activate.connect(deviceSyncClicked);
		deviceMenu.show_all();
		
		podcastMenu = new Menu();
		podcastAdd = new MenuItem.with_label("Add Podcast");
		podcastRefresh = new MenuItem.with_label("Download new Episodes");
		podcastMenu.append(podcastAdd);
		podcastMenu.append(podcastRefresh);
		podcastAdd.activate.connect(podcastAddClicked);
		podcastRefresh.activate.connect(podcastRefreshClicked);
		podcastMenu.show_all();
		
		CDMenu = new Menu();
		CDimportToLibrary = new MenuItem.with_label("Import to Library");
		CDeject = new MenuItem.with_label("Eject");
		CDMenu.append(CDimportToLibrary);
		//CDMenu.append(CDeject);
		CDimportToLibrary.activate.connect(CDimportToLibraryClicked);
		CDeject.activate.connect(CDejectClicked);
		CDMenu.show_all();
		
		radioMenu = new Menu();
		radioImportStations = new MenuItem.with_label("Import Station");
		radioMenu.append(radioImportStations);
		radioImportStations.activate.connect(playlistImportClicked);
		radioMenu.show_all();
		
		//playlist right click menu
		playlistMenu = new Menu();
		playlistNew = new MenuItem.with_label("New Playlist");
		smartPlaylistNew = new MenuItem.with_label("New Smart Playlist");
		playlistEdit = new MenuItem.with_label("Edit");
		playlistRemove = new MenuItem.with_label("Remove");
		playlistSave = new MenuItem.with_label("Save as Playlist");
		playlistExport = new MenuItem.with_label("Export...");
		playlistImport = new MenuItem.with_label("Import Playlist");
		playlistMenu.append(playlistNew);
		playlistMenu.append(smartPlaylistNew);
		playlistMenu.append(playlistEdit);
		playlistMenu.append(playlistRemove);
		playlistMenu.append(playlistSave);
		playlistMenu.append(playlistExport);
		playlistMenu.append(playlistImport);
		playlistNew.activate.connect(playlistMenuNewClicked);
		smartPlaylistNew.activate.connect(smartPlaylistMenuNewClicked);
		playlistEdit.activate.connect(playlistMenuEditClicked);
		playlistRemove.activate.connect(playlistMenuRemoveClicked);
		playlistSave.activate.connect(playlistSaveClicked);
		playlistExport.activate.connect(playlistExportClicked);
		playlistImport.activate.connect(playlistImportClicked);
		playlistMenu.show_all();
		
		this.button_press_event.connect(sideListClick);
		this.row_activated.connect(sideListDoubleClick);
		this.true_selection_change.connect(sideListSelectionChange);
		this.clickable_clicked.connect(clickableClicked);
		this.expand_all();
		
		/* set up drag dest stuff */
		drag_dest_set(this, DestDefaults.ALL, {}, Gdk.DragAction.MOVE);
		Gtk.drag_dest_add_uri_targets(this);
		this.drag_data_received.connect(dragReceived);
		
		this.show_all();
	}
	
	public void addBasicItems() {
		library_iter = addItem(null, null, null, null, "Library", null);
		devices_iter = addItem(null, null, null, null, "Devices", null);
		network_iter = addItem(null, null, null, null, "Network", null);
		playlists_iter = addItem(null, null, null, null, "Playlists", null);
	}
	
	public TreeIter? addSideItem(TreeIter? parent, GLib.Object? o, Widget w, string name) {
		var music_icon = lm.icons.music_icon.render (IconSize.MENU, null);
		var podcast_icon = lm.icons.podcast_icon.render (IconSize.MENU, null);
		var history_icon = lm.icons.history_icon.render (IconSize.MENU, null);
		var smart_playlist_icon = lm.icons.smart_playlist_icon.render (IconSize.MENU, null);
	
		if(name == "Music" && parent == library_iter) {
			library_music_iter = addItem(parent, o, w, music_icon, name, null);
			return library_music_iter;
		}
		else if(name == "Podcasts" && parent == library_iter) {
			library_podcasts_iter = addItem(parent, o, w, podcast_icon, name, null);
			return library_podcasts_iter;
		}
		else if(name == "Audiobooks" && parent == library_iter) {
			// FIXME: add icon
			var audiobook_icon = lm.icons.audiobook_icon.render (IconSize.MENU, null);
			library_audiobooks_iter = addItem(parent, o, w, audiobook_icon, name, null);
			return library_audiobooks_iter;
		}
		else if(o is Device && parent == devices_iter) {
			Device d = (Device)o;
			// TODO: Install and load these icons using the Icons module
			if(d.getContentType() == "cdrom") {
				devices_cdrom_iter = addItem(parent, o, w, render_icon("media-optical-audio", IconSize.MENU, null), name, null);
				return devices_cdrom_iter;
			}
			else if(d.getContentType() == "ipod-new")
				return addItem(parent, o, w, render_icon("phone", IconSize.MENU, null), name, null);
			else if(d.getContentType() == "ipod-old")
				return addItem(parent, o, w, render_icon("multimedia-player", IconSize.MENU, null), name, null);
			else if(d.getContentType() == "android")
				return addItem(parent, o, w, render_icon("phone", IconSize.MENU, null), name, null);
			else
				return addItem(parent, o, w, render_icon("multimedia-player", IconSize.MENU, null), name, null);
		}
		else if(name == "Music Store" && parent == network_iter) {
			network_store_iter = addItem(parent, o, w, music_icon, name, null);
			return network_store_iter;
		}
		else if(name == "Internet Radio" && parent == network_iter) {
			var radio_icon = lm.icons.radio_icon.render (IconSize.MENU, null);
			network_radio_iter = addItem(parent, o, w, radio_icon, name, null);
			return network_radio_iter;
		}
		else if(name == "Similar" && parent == playlists_iter) {
			playlists_similar_iter = addItem(parent, o, w, smart_playlist_icon, name, null);
			return playlists_similar_iter;
		}
		else if(name == "Queue" && parent == playlists_iter) {
			playlists_queue_iter = addItem(parent, o, w, music_icon, name, null);
			return playlists_queue_iter;
		}
		else if(name == "History" && parent == playlists_iter) {
			playlists_history_iter = addItem(parent, o, w, history_icon, name, null);
			return playlists_history_iter;
		}
		else if(o is SmartPlaylist) {
			TreeIter item;
			TreeIter pivot;
			tree.iter_children(out pivot, playlists_iter);
			
			do {
				string tempName;
				GLib.Object tempO;
				tree.get(pivot, 0, out tempO, 4, out tempName);
				
				if(tempO != null && ((tempO is Playlist) || tempName > name)) {
					tree.insert_before(out item, playlists_iter, pivot);
					break;
				}
				else if(!tree.iter_next(ref pivot)) {
					tree.append(out item, parent);
					break;
				}
				
			} while(true);
			
			tree.set(item, 0, o, 1, w, 2, true, 3, smart_playlist_icon, 4, name.replace("&", "&amp;"), 5, null);
			
			if(visible) {
				TreeIter? filterItem = convertToFilter(item);
				if(filterItem != null)
					setSelectedIter(filterItem);
			}
			
			//sideListSelectionChange();
			return item;
		}
		else if(o is Playlist) {
			TreeIter item;
			TreeIter pivot;
			tree.iter_children(out pivot, playlists_iter);
			
			do {
				string tempName;
				GLib.Object tempO;
				tree.get(pivot, 0, out tempO, 4, out tempName);
				
				if(tempO != null && tempO is Playlist && tempName > name) {
					tree.insert_before(out item, playlists_iter, pivot);
					break;
				}
				else if(!tree.iter_next(ref pivot)) {
					tree.append(out item, parent);
					break;
				}
			} while(true);
			
			var playlist_icon = lm.icons.playlist_icon.render (IconSize.MENU, null);
			tree.set(item, 0, o, 1, w, 2, true, 3, playlist_icon, 4, name.replace("&", "&amp;"), 5, null);
			if(visible) {
				TreeIter? filterItem = convertToFilter(item);
				if(filterItem != null)
					setSelectedIter(filterItem);
			}
			
			//sideListSelectionChange();
			return item;
		}
		else {
			sideListSelectionChange();
			return addItem(parent, o, w, null, name, null);
		}
	}
	
	public void updatePlayQueue() {
		Widget w;
		filter.get(convertToFilter(playlists_queue_iter), 1, out w);
		((ViewWrapper)w).doUpdate(((ViewWrapper)w).currentView, lm.queue(), true, true);
	}
	
	public void updateAlreadyPlayed() {
		Widget w;
		filter.get(convertToFilter(playlists_history_iter), 1, out w);
		((ViewWrapper)w).doUpdate(((ViewWrapper)w).currentView, lm.already_played(), true, true);
	}
	
	public virtual void sideListSelectionChange() {
		if(lw.initializationFinished) {
			tree.foreach(updateView);
		}
		
		lw.updateSensitivities();
	}
	
	public virtual bool sideListClick(Gdk.EventButton event) {
		if(event.type == Gdk.EventType.BUTTON_PRESS && event.button == 3) { //right click
			// select one based on mouse position
			TreeIter iter;
			TreePath path;
			TreeViewColumn column;
			int cell_x;
			int cell_y;
			
			this.get_path_at_pos((int)event.x, (int)event.y, out path, out column, out cell_x, out cell_y);
			
			if(!filter.get_iter(out iter, path))
				return false;
			
			GLib.Object o;
			filter.get(iter, 0, out o);
			string name;
			filter.get(iter, 4, out name);
			
			TreeIter parent;
			if(filter.iter_parent(out parent, iter)) {
				
				string parent_name;
				filter.get(parent, 4, out parent_name);
				
				if(iter == convertToFilter(library_podcasts_iter)) {
					podcastMenu.popup (null, null, null, 3, get_current_event_time());
				}
				else if(iter == convertToFilter(network_radio_iter)) {
					radioMenu.popup(null, null, null, 3, get_current_event_time());
				}
				else if(parent == convertToFilter(playlists_iter)) {
					if(iter == convertToFilter(playlists_similar_iter)) {
						playlistSave.visible = true;
						playlistMenu.popup (null, null, null, 3, get_current_event_time());
					}
					else {
						playlistSave.visible = false;
						playlistMenu.popup (null, null, null, 3, get_current_event_time());
					}
					
					if(o is Playlist || o is SmartPlaylist)
						playlistRemove.sensitive = true;
					else
						playlistRemove.sensitive = false;
						
					playlistExport.visible = true;
					playlistImport.visible = false;
				}
				else if(o is Device && ((Device)o).getContentType() == "cdrom") {
					CDMenu.popup(null, null, null, 3, get_current_event_time());
				}
				else if(o is Device) {
					deviceMenu.popup(null, null, null, 3, get_current_event_time());
				}
			}
			else {
				if(iter == convertToFilter(playlists_iter)) {
					playlistRemove.sensitive = false;
					playlistExport.visible = false;
					playlistImport.visible = true;
					playlistMenu.popup (null, null, null, 3, get_current_event_time());
					return true;
				}
			}
			
			return false;
		}
		else if(event.type == Gdk.EventType.BUTTON_PRESS && event.button == 2) {
			TreeIter iter;
			TreeIter iter_f;
			TreePath path;
			TreeViewColumn column;
			int cell_x;
			int cell_y;
			
			this.get_path_at_pos((int)event.x, (int)event.y, out path, out column, out cell_x, out cell_y);
		
			if(!filter.get_iter(out iter_f, path))
				return false;
				
			iter = convertToChild(iter_f);
			
			Widget w = getWidget(iter);
			if(w is ViewWrapper) {
				((ViewWrapper)w).list.set_as_current_list(0, true);
			}
		}
		
		return false;
	}
	
	public virtual void sideListDoubleClick(TreePath path, TreeViewColumn column) {
		TreeIter iter_f;
		TreeIter iter;
		
		if(!filter.get_iter(out iter_f, path))
			return;
			
		iter = convertToChild(iter_f);
			
		Widget w = getWidget(iter);
		if(w is ViewWrapper) {
			((ViewWrapper)w).list.set_as_current_list(1, true);
			
			lm.playMedia(lm.mediaFromCurrentIndex(0));
			lm.player.play();
			
			if(!lm.playing)
				lw.playClicked();
		}
	}
	
	public void resetView() {
		if(lm.media_info.media == null || lm.media_info.media.mediatype == 0)
			setSelectedIter(convertToFilter(library_music_iter));
		else if(lm.media_info.media.mediatype == 1)
			setSelectedIter(convertToFilter(library_podcasts_iter));
		else if(lm.media_info.media.mediatype == 2) {
			setSelectedIter(convertToFilter(library_music_iter));
			stdout.printf("TODO: Set current list to audiobooks when resetting if current media is audiobook\n");
		}
		else if(lm.media_info.media.mediatype == 3)
			setSelectedIter(convertToFilter(network_radio_iter));
		
		tree.foreach(updateView);
	}
	
	// currently not used
	public bool updateAllSmartPlaylists(TreeModel model, TreePath path, TreeIter iter) {
		Widget w;
		GLib.Object o;
		model.get(iter, 0, out o, 1, out w);
		
		if(w == null)
			return false;
		
		if(!w.visible && o is SmartPlaylist) {
			ViewWrapper vw = (ViewWrapper)w;
			
			vw.doUpdate((lw.viewSelector.selected == 0) ? ViewWrapper.ViewType.FILTER_VIEW : ViewWrapper.ViewType.LIST,
						lm.medias_from_smart_playlist(((SmartPlaylist)o).rowid), true, true);
		}
		
		return false;
	}
	
	public bool updateView(TreeModel model, TreePath path, TreeIter iter) {
		Widget w;
		GLib.Object o;
		model.get(iter, 0, out o, 1, out w);
		
		if(w == null)
			return false;
		
		if(w == getSelectedWidget()) {
			bool showing = w.visible;
			w.show();
			
			if(showing)
				return false;
			
			if(w is ViewWrapper) {
				((ViewWrapper)w).set_is_current_view(true);
				
				if(!lw.initializationFinished) {
					return false;
				}
				
				/* update the lists if we need to */
				if(iter == library_music_iter) {
					ViewWrapper vw = (ViewWrapper)w;
					
					vw.doUpdate((lw.viewSelector.selected == 0) ? ViewWrapper.ViewType.FILTER_VIEW : ViewWrapper.ViewType.LIST,
								lm.media_ids(), false, false);
				}
				else if(iter == library_podcasts_iter) {
					ViewWrapper vw = (ViewWrapper)w;
					
					vw.doUpdate((lw.viewSelector.selected == 0) ? ViewWrapper.ViewType.FILTER_VIEW : ViewWrapper.ViewType.LIST,
								lm.podcast_ids(), false, false);
				}
				else if(iter == network_radio_iter) {
					ViewWrapper vw = (ViewWrapper)w;
					
					vw.doUpdate((lw.viewSelector.selected == 0) ? ViewWrapper.ViewType.FILTER_VIEW : ViewWrapper.ViewType.LIST,
								lm.station_ids(), false, false);
				}
				else if(iter == network_store_iter) {
					Store.StoreView sv = (Store.StoreView)w;
					if(!sv.isInitialized) {
						sv.homeView.populate();
						sv.isInitialized = true;
						lw.updateMillerColumns();
					}
				}
				else if(iter == playlists_similar_iter) {
					ViewWrapper vw = (ViewWrapper)w;
					lw.updateMillerColumns(); // don't show millers if showing warning label
					
					vw.doUpdate((lw.viewSelector.selected == 0) ? ViewWrapper.ViewType.FILTER_VIEW : ViewWrapper.ViewType.LIST,
								vw.medias, true, false);
				}
				else if(iter == playlists_queue_iter) {
					ViewWrapper vw = (ViewWrapper)w;
					
					vw.doUpdate((lw.viewSelector.selected == 0) ? ViewWrapper.ViewType.FILTER_VIEW : ViewWrapper.ViewType.LIST,
								lm.queue(), true, false);
				}
				else if(iter == playlists_history_iter) {
					ViewWrapper vw = (ViewWrapper)w;
					
					vw.doUpdate((lw.viewSelector.selected == 0) ? ViewWrapper.ViewType.FILTER_VIEW : ViewWrapper.ViewType.LIST,
								lm.already_played(), true, false);
				}
				else if(o is SmartPlaylist && !((SmartPlaylist)o).viewWrapper_is_up_to_date) {
					ViewWrapper vw = (ViewWrapper)w;
					
					vw.doUpdate((lw.viewSelector.selected == 0) ? ViewWrapper.ViewType.FILTER_VIEW : ViewWrapper.ViewType.LIST,
								lm.medias_from_smart_playlist(((SmartPlaylist)o).rowid), true, false);
				}
				else if(o is Playlist) {
					ViewWrapper vw = (ViewWrapper)w;
					
					vw.doUpdate((lw.viewSelector.selected == 0) ? ViewWrapper.ViewType.FILTER_VIEW : ViewWrapper.ViewType.LIST,
								lm.medias_from_playlist(((Playlist)o).rowid), true, false);
				}
				else if(o is Device && ((Device)o).getContentType() == "cdrom") {
					DeviceViewWrapper vw = (DeviceViewWrapper)w;
					
					vw.doUpdate((lw.viewSelector.selected == 0) ? ViewWrapper.ViewType.FILTER_VIEW : ViewWrapper.ViewType.LIST,
								vw.medias, true, false);
				}
				
				if(lw.initializationFinished && (lw.viewSelector.selected == 2)) {
					stdout.printf("doing miller update\n");
					lw.miller.populateColumns( (o is Device) ? "device" : "", ((ViewWrapper)w).medias);
				}
				
				lw.updateMillerColumns();
				((ViewWrapper)w).set_statusbar_text();
				lm.current_view_size = ((ViewWrapper)w).media_count;
			}
			else if(w is Store.StoreView) {
				((Store.StoreView)w).setIsCurrentView(true);
			}
			else if(w is DeviceView) {
				stdout.printf("o is device\n");
				DeviceView dv = (DeviceView)w;
				
				dv.updateChildren();
				
				if(lw.initializationFinished && (lw.viewSelector.selected == 2)) {
					stdout.printf("doing miller update\n");
					lw.miller.populateColumns( (o is Device) ? "device" : "", ((DeviceView)w).music_list.medias);
				}
				lw.updateMillerColumns();
				((DeviceView)w).music_list.set_statusbar_text();
			}
		}
		else {
			w.hide();
			
			if(w is ViewWrapper) {
				((ViewWrapper)w).set_is_current_view(false);
			}
			else if(w is Store.StoreView) {
				((Store.StoreView)w).setIsCurrentView(false);
			}
			else if(w is DeviceView) {
				((DeviceView)w).set_is_current_view(false);
			}
		}
		return false;
	}
	
	// podcast context menu
	void podcastAddClicked() {
		AddPodcastWindow apw = new AddPodcastWindow(lw);
		apw.lw = lw; // avoid warnings
	}
	
	void podcastRefreshClicked() {
		lm.pm.find_new_podcasts();
	}
	
	// cd rom context menu
	public void CDimportToLibraryClicked() {
		TreeIter iter = getSelectedIter();
		Widget w = getSelectedWidget();
		
		GLib.Object o;
		filter.get(iter, 0, out o);
		
		if(o is Device && ((Device)o).getContentType() == "cdrom") {
			var to_transfer = new LinkedList<int>();
			foreach(int i in ((Device)o).get_medias())
				to_transfer.add(i);
			
			((Device)o).transfer_to_library(to_transfer);
		}
	}
	
	public void CDejectClicked() {
		TreeIter iter = getSelectedIter();
		
		GLib.Object o;
		filter.get(iter, 0, out o);
		
		if(o is Device && ((Device)o).getContentType() == "cdrom") {
			((Device)o).unmount();
		}
	}
	
	// device menu
	void deviceImportToLibraryClicked() {
		TreeIter iter = getSelectedIter();
		Widget w = getSelectedWidget();
		
		GLib.Object o;
		filter.get(iter, 0, out o);
		
		if(o is Device) {
			((DeviceView)w).showImportDialog();
		}
	}
	
	void deviceSyncClicked() {
		TreeIter iter = getSelectedIter();
		Widget w = getSelectedWidget();
		
		GLib.Object o;
		filter.get(iter, 0, out o);
		
		if(o is Device) {
			((DeviceView)w).syncClicked();
		}
	}
	
	//smart playlist context menu
	public virtual void smartPlaylistMenuNewClicked() {
		SmartPlaylistEditor spe = new SmartPlaylistEditor(lw, new SmartPlaylist());
		spe.playlist_saved.connect(smartPlaylistEditorSaved);
	}
	
	public virtual void smartPlaylistEditorSaved(SmartPlaylist sp) {
		sp.is_up_to_date = false;
		
		if(sp.rowid > 0) {
			TreeIter pivot = playlists_history_iter;
				
			do {
				GLib.Object o;
				tree.get(pivot, 0, out o);
				if(o is SmartPlaylist && ((SmartPlaylist)o).rowid == sp.rowid) {
					string name;
					Widget w;
					tree.get(pivot, 1, out w, 4, out name);
					
					removeItem(pivot);
					lw.addSideListItem(sp);
					
					((ViewWrapper)w).doUpdate(((ViewWrapper)w).currentView, lm.medias_from_smart_playlist(sp.rowid), true, false);
					lm.save_smart_playlists();
					
					break;
				}
			} while(tree.iter_next(ref pivot));
		}
		else {
			lm.add_smart_playlist(sp); // this queues save_smart_playlists()
			lw.addSideListItem(sp);
			sideListSelectionChange();
		}
	}
	
	//playlist context menu
	public virtual void playlistMenuNewClicked() {
		PlaylistNameWindow pnw = new PlaylistNameWindow(lw, new Playlist());
		pnw.playlist_saved.connect(playlistNameWindowSaved);
	}
	
	public virtual void playlistNameWindowSaved(Playlist p) {
		if(p.rowid > 0) {
			TreeIter pivot = playlists_history_iter;
			
			do {
				GLib.Object o;
				
				tree.get(pivot, 0, out o);
				if(o is Playlist && ((Playlist)o).rowid == p.rowid) {
					string name;
					Widget w;
					tree.get(pivot, 1, out w, 4, out name);
					
					removeItem(pivot);
					lw.addSideListItem(p);
					
					((ViewWrapper)w).doUpdate(((ViewWrapper)w).currentView, lm.medias_from_playlist(p.rowid), true, false);
					
					break;
				}
			} while(tree.iter_next(ref pivot));
		}
		else {
			lm.add_playlist(p);
			lw.addSideListItem(p);
			sideListSelectionChange();
		}
	}
	
	public virtual void playlistMenuEditClicked() {
		TreeSelection selected = this.get_selection();
		selected.set_mode(SelectionMode.SINGLE);
		TreeModel model;
		TreeIter iter;
		selected.get_selected (out model, out iter);
		
		GLib.Object o;
		filter.get(iter, 0, out o);
		
		if(o is Playlist) {
			PlaylistNameWindow pnw = new PlaylistNameWindow(lw, ((Playlist)o));
			pnw.playlist_saved.connect(playlistNameWindowSaved);
		}
		else if(o is SmartPlaylist) {
			SmartPlaylistEditor spe = new SmartPlaylistEditor(lw, (SmartPlaylist)o);
			spe.playlist_saved.connect(smartPlaylistEditorSaved);
		}
	}
	
	public virtual void playlistMenuRemoveClicked() {
		TreeIter iter, iter_f;
		TreeSelection selected = this.get_selection();
		selected.set_mode(SelectionMode.SINGLE);
		TreeModel model;
		selected.get_selected (out model, out iter_f);
		
		GLib.Object o;
		Widget w;
		filter.get(iter_f, 0, out o, 1, out w);
		
		if(o is Playlist)
			lm.remove_playlist(((Playlist)o).rowid);
		else if(o is SmartPlaylist)
			lm.remove_smart_playlist(((SmartPlaylist)o).rowid);
		
		iter = convertToChild(iter_f);
		
		removeItem(iter);
		resetView();
	}
	
	// removes all normal playlists from the side list, as well as LM
	public void removeAllStaticPlaylists() {
		TreeIter pivot = playlists_history_iter;
		var toRemove = new Gee.LinkedList<int>();
		
		// keep taking from bottom until all playlists are gone
		tree.iter_nth_child(out pivot, playlists_iter, tree.iter_n_children(playlists_iter) - 1);
		
		do {
			GLib.Object o;
			
			tree.get(pivot, 0, out o);
			if(o is Playlist) {
				toRemove.add(((Playlist)o).rowid);
				removeItem(pivot);
			}
			else {
				break;
			}
			
		} while(tree.iter_nth_child(out pivot, playlists_iter, tree.iter_n_children(playlists_iter) - 1));
		
		foreach(int i in toRemove) {
			lm.remove_playlist(i);
		}
	}
	
	// can only be done on similar medias
	public void playlistSaveClicked() {
		TreeSelection selected = this.get_selection();
		selected.set_mode(SelectionMode.SINGLE);
		TreeModel model;
		TreeIter iter;
		selected.get_selected (out model, out iter);
		
		Widget w;
		filter.get(iter, 1, out w);
		
		if(w is ViewWrapper && ((ViewWrapper)w).list is SimilarPane) {
			SimilarPane sp = (SimilarPane)(((ViewWrapper)w).list);
			sp.savePlaylist();
		}
	}
	
	void playlistExportClicked() {
		TreeIter iter, iter_f;
		TreeSelection selected = this.get_selection();
		selected.set_mode(SelectionMode.SINGLE);
		TreeModel model;
		selected.get_selected (out model, out iter_f);
		
		GLib.Object o;
		Widget w;
		filter.get(iter_f, 0, out o, 1, out w);
		
		iter = convertToChild(iter_f);
		
		Playlist p;
		if(o is Playlist) {
			p = (Playlist)o;
		}
		else {
			p = new Playlist();
			
			if(o is SmartPlaylist) {
				foreach(int i in ((SmartPlaylist)o).analyze(lm))
					p.addMedia(i);
					
				p.name = ((SmartPlaylist)o).name;
			}
			else {
				foreach(int i in ((ViewWrapper)w).medias)
					p.addMedia(i);
				
				if(iter == playlists_similar_iter)
					p.name = (lm.media_info.media != null) ? ("Similar to " + lm.media_info.media.title) : "Similar list";
				else if(iter == playlists_queue_iter)
					p.name = Time.local(time_t()).format("%m/%e/%Y %l:%M %p") + " play queue";
				else if(iter == playlists_history_iter)
					p.name = Time.local(time_t()).format("%m/%e/%Y %l:%M %p") + " play history";
				else
					p.name = "Unkown playlist";
			}
		}
		
		if(p == null)
			return;
		
		string file = "";
		string name = "";
		string extension = "";
		var file_chooser = new FileChooserDialog ("Export Playlist", lw,
								  FileChooserAction.SAVE,
								  Gtk.Stock.CANCEL, ResponseType.CANCEL,
								  Gtk.Stock.SAVE, ResponseType.ACCEPT);
		
		// filters for .m3u and .pls
		var m3u_filter = new FileFilter();
		m3u_filter.add_pattern("*.m3u");
		m3u_filter.set_filter_name("MPEG Version 3.0 Extended (*.m3u)");
		file_chooser.add_filter(m3u_filter);
		
		var pls_filter = new FileFilter();
		pls_filter.add_pattern("*.pls");
		pls_filter.set_filter_name("Shoutcast Playlist Version 2.0 (*.pls)");
		file_chooser.add_filter(pls_filter);
		
		file_chooser.do_overwrite_confirmation = true;
		file_chooser.set_current_name(p.name + ".m3u");
		
		// set original folder. if we don't, then file_chooser.get_filename() starts as null, which is bad for signal below.
		if(File.new_for_path(lm.settings.getMusicFolder()).query_exists())
			file_chooser.set_current_folder(lm.settings.getMusicFolder());
		else
			file_chooser.set_current_folder(Environment.get_home_dir());
			
		
		// listen for filter change
		file_chooser.notify["filter"].connect( () => {
			if(file_chooser.get_filename() == null) // happens when no folder is chosen. need way to get textbox text, rather than filename
				return;
			
			if(file_chooser.filter == m3u_filter) {
				stdout.printf("changed to m3u\n");
				var new_file = file_chooser.get_filename().replace(".pls", ".m3u");
				
				if(new_file.slice(new_file.last_index_of(".", 0), new_file.length).length == 0) {
					new_file += ".m3u";
				}
				
				file_chooser.set_current_name(new_file.slice(new_file.last_index_of("/", 0) + 1, new_file.length));
			}
			else {
				stdout.printf("changed to pls\n");
				var new_file = file_chooser.get_filename().replace(".m3u", ".pls");
				
				if(new_file.slice(new_file.last_index_of(".", 0), new_file.length).length == 0) {
					new_file += ".pls";
				}
				
				file_chooser.set_current_name(new_file.slice(new_file.last_index_of("/", 0) + 1, new_file.length));
			}
		});
		
		if (file_chooser.run () == ResponseType.ACCEPT) {
			file = file_chooser.get_filename();
			extension = file.slice(file.last_index_of(".", 0), file.length);
			
			if(extension.length == 0 || extension[0] != '.') {
				extension = (file_chooser.filter == m3u_filter) ? ".m3u" : ".pls";
				file += extension;
			}
			
			name = file.slice(file.last_index_of("/", 0) + 1, file.last_index_of(".", 0));
			stdout.printf("name is %s extension is %s\n", name, extension);
		}
		
		file_chooser.destroy ();
		
		string original_name = p.name;
		if(file != "") {
			var f = File.new_for_path(file);
			
			string folder = f.get_parent().get_path();
			p.name = name; // temporary to save
			
			if(file.has_suffix(".m3u"))
				p.save_playlist_m3u(lm, folder);
			else
				p.save_playlist_pls(lm, folder);
		}
		
		p.name = original_name;
	}
	
	void playlistImportClicked() {
		if(lm.doing_file_operations())
			return;
		
		string file = "";
		string name = "";
		var file_chooser = new FileChooserDialog ("Import Playlist", lw,
								  FileChooserAction.OPEN,
								  Gtk.Stock.CANCEL, ResponseType.CANCEL,
								  Gtk.Stock.OPEN, ResponseType.ACCEPT);
		
		// filters for .m3u and .pls
		var m3u_filter = new FileFilter();
		m3u_filter.add_pattern("*.m3u");
		m3u_filter.set_filter_name("MPEG Version 3.0 Extended (*.m3u)");
		file_chooser.add_filter(m3u_filter);
		
		var pls_filter = new FileFilter();
		pls_filter.add_pattern("*.pls");
		pls_filter.set_filter_name("Shoutcast Playlist Version 2.0 (*.pls)");
		file_chooser.add_filter(pls_filter);
		
		if (file_chooser.run () == ResponseType.ACCEPT) {
			file = file_chooser.get_filename();
			name = file.slice(file.last_index_of("/", 0) + 1, file.last_index_of(".", 0));
		}
		
		file_chooser.destroy ();
		
		var paths = new LinkedList<string>();
		var stations = new LinkedList<Media>();
		bool success = false;
		
		if(file != "") {
			if(file.has_suffix(".m3u")) {
				success = Playlist.parse_paths_from_m3u(lm, file, ref paths, ref stations);
			}
			else if(file.has_suffix(".pls")) {
				success = Playlist.parse_paths_from_pls(lm, file, ref paths, ref stations);
			}
			else {
				success = false;
				lw.doAlert("Invalid Playlist", "Unrecognized playlist file. Import failed.");
				return;
			}
		}
		
		if(success) {
			if(paths.size > 0) {
				try {
					lm.start_file_operations("Importing <b>" + name + "</b> to Library...");
					lm.fo.import_from_playlist_file_info(name, paths);
					lw.updateSensitivities();
				}
				catch(Error err) {
					stdout.printf("Could not create thread to import playlist: %s\n", err.message);
				}
			}
			if(stations.size > 0) {
				lm.add_medias(stations, true);
				
				Widget w = getWidget(network_radio_iter);
				((ViewWrapper)w).doUpdate(((ViewWrapper)w).currentView, lm.station_ids(), true, true);
			}
		}
	}
	
	public virtual void dragReceived(Gdk.DragContext context, int x, int y, Gtk.SelectionData data, uint info, uint timestamp) {
		bool success = false;
		TreeIter iter;
		TreePath path;
		TreeViewColumn column;
		int cell_x;
		int cell_y;
		
		/* get the iter we are on */
		this.get_path_at_pos(x, y, out path, out column, out cell_x, out cell_y);
		if(!filter.get_iter(out iter, path)) {
			Gtk.drag_finish(context, false, false, timestamp);
			return;
		}
		
		GLib.Object o;
		Widget w;
		string name;
		filter.get(iter, 0, out o, 1, out w, 4, out name);
		
		/* make sure it is either queue or normal playlist */
		if(name == "Queue") {
			foreach (string uri in data.get_uris ()) {
				File file = File.new_for_uri (uri);
				if(file.query_file_type(FileQueryInfoFlags.NOFOLLOW_SYMLINKS) == FileType.REGULAR && file.is_native ()) {
					Media add = lm.media_from_file(file.get_path());
					
					if(add != null) {
						lm.queue_media_by_id(add.rowid);
						success = true;
					}
				}
			}
			
			ViewWrapper vw = (ViewWrapper)w;
			vw.millerChanged();
		}
		else if(o is Playlist) {
			Playlist p = (Playlist)o;
			
			foreach (string uri in data.get_uris ()) {
				File file = File.new_for_uri (uri);
				if(file.query_file_type(FileQueryInfoFlags.NOFOLLOW_SYMLINKS) == FileType.REGULAR && file.is_native ()) {
					Media add = lm.media_from_file(file.get_path());
					
					if(add != null) {
						p.addMedia(add.rowid);
						success = true;
					}
				}
			}
			
			ViewWrapper vw = (ViewWrapper)w;
			vw.millerChanged();
			
		}
		
		Gtk.drag_finish (context, success, false, timestamp);
    }
    
    /* device stuff */
    public void deviceAdded(Device d) {
		lw.addSideListItem(d);
		tree.foreach(updateView);
	}
	
	public void deviceRemoved(Device d) {
		TreeIter pivot;
		if(!tree.iter_children(out pivot, devices_iter))
			return;
			
		bool was_selected = false;
		
		do {
			GLib.Object o;
			tree.get(pivot, 0, out o);
			if(o is Device && ((Device)o).get_path() == d.get_path()) {
				if(get_selection().iter_is_selected(convertToFilter(pivot)))
					was_selected = true;
				
				removeItem(pivot);
				
				break;
			}
		} while(tree.iter_next(ref pivot));
		
		if(was_selected)
			resetView();
	}
	
	public void clickableClicked(TreeIter iter) {
		GLib.Object o;
		filter.get(iter, 0, out o);
		
		if(o is Device && ((Device)o).getContentType() == "cdrom") {
			((Device)o).unmount();
		}
	}
}
