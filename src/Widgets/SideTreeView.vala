using Gtk;

public class BeatBox.SideTreeView : TreeView {
	LibraryManager lm;
	LibraryWindow lw;
	TreeStore sideTreeModel;
	
	public TreeIter library_iter;
	public TreeIter library_music_iter;
	public TreeIter library_podcasts_iter;
	public TreeIter library_audiobooks_iter;
	
	public TreeIter devices_iter;
	
	public TreeIter network_iter;
	
	public TreeIter playlists_iter;
	public TreeIter playlists_queue_iter;
	public TreeIter playlists_history_iter;
	public TreeIter playlists_similar_iter;
	
	//for playlist right click
	Menu playlistMenu;
	MenuItem playlistNew;
	MenuItem smartPlaylistNew;
	MenuItem playlistEdit;
	MenuItem playlistRemove;
	
	Widget current_widget;
	
	public SideTreeView(LibraryManager lmm, LibraryWindow lww) {
		this.lm = lmm;
		this.lw = lww;
		
		buildUI();
	}
	
	public void buildUI() {
		/* 0: playlist, smart playlist, etc.
		 * 1: the widget to show in relation
		 * 2: name to display
		 */
		sideTreeModel = new TreeStore(4, typeof(GLib.Object), typeof(Widget), typeof(string), typeof(string));
		this.set_model(sideTreeModel);
		this.set_headers_visible(false);
		//this.set_grid_lines(TreeViewGridLines.NONE);
		//this.show_expanders = false;
		
		TreeViewColumn col = new TreeViewColumn();
		col.title = "object";
		this.insert_column(col, 0);
		
		col = new TreeViewColumn();
		col.title = "widget";
		this.insert_column(col, 1);
		
		var cell_renderer_text = new Gtk.CellRendererText();
		var cell_renderer_pixbuf = new Gtk.CellRendererPixbuf();
		this.insert_column_with_data_func(-1, "title", cell_renderer_pixbuf, smartPixTextColumnData);
		this.get_column(2).pack_end(cell_renderer_text, true);
		this.get_column(2).set_attributes(cell_renderer_text, "markup", 2, null);
		this.get_column(2).alignment = 0.0f;
		//this.get_column(2).max_width = 150;
		//this.get_column(2).fixed_width = 150;
		cell_renderer_text.xalign = 0.0f;
		//this.get_column(2).expand = false;
		
		col = new TreeViewColumn();
		col.title = "expander";
		col.expand = true;
		this.insert_column(col, 3);
		//this.set_expander_column(get_column(2));
		this.set_show_expanders(false);
		
		int index = 0;
		foreach(TreeViewColumn tvc in this.get_columns()) {
			if(index == 0 || index == 1)
				tvc.visible = false;
			
			++index;
		}
		
		this.button_press_event.connect(sideListClick);
		this.get_selection().changed.connect(sideListSelectionChange);
		this.expand_all();
		
		//playlist right click menu
		playlistMenu = new Menu();
		playlistNew = new MenuItem.with_label("New Playlist");
		smartPlaylistNew = new MenuItem.with_label("New Smart Playlist");
		playlistEdit = new MenuItem.with_label("Edit");
		playlistRemove = new MenuItem.with_label("Remove");
		playlistMenu.append(playlistNew);
		playlistMenu.append(smartPlaylistNew);
		playlistMenu.append(playlistEdit);
		playlistMenu.append(playlistRemove);
		playlistNew.activate.connect(playlistMenuNewClicked);
		smartPlaylistNew.activate.connect(smartPlaylistMenuNewClicked);
		playlistEdit.activate.connect(playlistMenuEditClicked);
		playlistRemove.activate.connect(playlistMenuRemoveClicked);
		playlistMenu.show_all();
		
		/* set up drag dest stuff */
		drag_dest_set(this, DestDefaults.ALL, {}, Gdk.DragAction.MOVE);
		Gtk.drag_dest_add_uri_targets(this);
		this.drag_data_received.connect(dragReceived);
		
		this.show_all();
	}
	
	public void smartPixTextColumnData(TreeViewColumn tree_column, CellRenderer cell, TreeModel tree_model, TreeIter iter) {
		GLib.Object o = null;
		string title = "";
		tree_model.get(iter, 0, out o, 2, out title);
		
		TreeIter parent;
		//if(sideTreeModel.iter_is_valid(parent))
		//	sideTreeModel.get(parent, out parent_string);
		
		/* NOTE: This is only called for the pixbuf cellrenderer!!!!!!! */
		if(cell is CellRendererPixbuf && iter == library_music_iter) {
			((CellRendererPixbuf)cell).pixbuf = get_pixbuf_from_stock("folder-music", IconSize.MENU);
		}
		else if(cell is CellRendererPixbuf && iter == playlists_similar_iter) {
			((CellRendererPixbuf)cell).pixbuf = get_pixbuf_from_stock("playlist-automatic", IconSize.MENU);
			
			//make it insensitive if no similar songs/not enough
		}
		else if(cell is CellRendererPixbuf && iter == playlists_queue_iter) {
			((CellRendererPixbuf)cell).pixbuf = get_pixbuf_from_stock("media-audio", IconSize.MENU);
		}
		else if(cell is CellRendererPixbuf && iter == playlists_history_iter) {
			((CellRendererPixbuf)cell).pixbuf = get_pixbuf_from_stock("emblem-urgent", IconSize.MENU);
		}
		else if(cell is CellRendererPixbuf && o is SmartPlaylist) {
			((CellRendererPixbuf)cell).pixbuf = get_pixbuf_from_stock("playlist-automatic", IconSize.MENU);
		}
		else if(cell is CellRendererPixbuf && o is Playlist) {
			((CellRendererPixbuf)cell).pixbuf = get_pixbuf_from_stock("playlist", IconSize.MENU);
		}
		else
			((CellRendererPixbuf)cell).pixbuf = null;
		
		//align pixbuf to right, text to left
		if(cell is CellRendererPixbuf) {
			cell.set_fixed_size(40, 0);
			cell.set_alignment((float)1.0, (float)1.0);
			//((CellRendererPixbuf)cell).alignment = Alignment.RIGHT;
			((CellRendererPixbuf)cell).stock_size = 16;
		}
			
		if(!sideTreeModel.iter_parent(out parent, iter)) {
			cell.visible = false;
		}
		else {
			cell.visible = true;
		}
	}
	
	private Gdk.Pixbuf get_pixbuf_from_stock (string stock_id, Gtk.IconSize size) {
		Gdk.Pixbuf pixbuf;
		
		pixbuf = this.render_icon(stock_id, size, null);
		
		if(pixbuf == null)
		stdout.printf("Could not render icon %s\n", stock_id);
		
		return pixbuf;
	}
	
	public void addBasicItems() {
		sideTreeModel.append(out library_iter, null);
		sideTreeModel.set(library_iter, 0, null, 1, null, 2, "<b>Library</b>");
		
		sideTreeModel.append(out devices_iter, null);
		sideTreeModel.set(devices_iter, 0, null, 1, null, 2, "<b>Devices</b>");
		
		sideTreeModel.append(out network_iter, null);
		sideTreeModel.set(network_iter, 0, null, 1, null, 2, "<b>Network</b>");
		
		sideTreeModel.append(out playlists_iter, null);
		sideTreeModel.set(playlists_iter, 0, null, 1, null, 2, "<b>Playlists</b>");
	}
	
	public TreeIter? addItem(TreeIter? parent, GLib.Object? o, Widget w, string name) {
		if(name == "Music" && parent == library_iter) {
			sideTreeModel.append(out library_music_iter, parent);
			sideTreeModel.set(library_music_iter, 0, o, 1, w, 2, name);
			return library_music_iter;
		}
		else if(name == "Podcasts" && parent == library_iter) {
			sideTreeModel.append(out library_podcasts_iter, parent);
			sideTreeModel.set(library_podcasts_iter, 0, o, 1, w, 2, name);
			return library_podcasts_iter;
		}
		else if(name == "Audiobooks" && parent == library_iter) {
			sideTreeModel.append(out library_audiobooks_iter, parent);
			sideTreeModel.set(library_audiobooks_iter, 0, o, 1, w, 2, name);
			return library_audiobooks_iter;
		}
		else if(name == "Similar" && parent == playlists_iter) {
			sideTreeModel.append(out playlists_similar_iter, parent);
			sideTreeModel.set(playlists_similar_iter, 0, o, 1, w, 2, name);
			return playlists_similar_iter;
		}
		else if(name == "Queue" && parent == playlists_iter) {
			sideTreeModel.append(out playlists_queue_iter, parent);
			sideTreeModel.set(playlists_queue_iter, 0, o, 1, w, 2, name);
			return playlists_queue_iter;
		}
		else if(name == "History" && parent == playlists_iter) {
			sideTreeModel.append(out playlists_history_iter, parent);
			sideTreeModel.set(playlists_history_iter, 0, o, 1, w, 2, name);
			return playlists_history_iter;
		}
		else if(o is SmartPlaylist) {
			TreeIter item;
			TreeIter pivot;
			sideTreeModel.iter_children(out pivot, playlists_iter);
			
			do {
				string tempName;
				GLib.Object tempO;
				sideTreeModel.get(pivot, 0, out tempO, 2, out tempName);
				
				if(tempO != null && ((tempO is Playlist) || tempName > name)) {
					sideTreeModel.insert_before(out item, playlists_iter, pivot);
					break;
				}
				else if(!sideTreeModel.iter_next(ref pivot)) {
					sideTreeModel.append(out item, parent);
					break;
				}
			} while(true);
			
			sideTreeModel.set(item, 0, o, 1, w, 2, name);
			this.expand_to_path(sideTreeModel.get_path(item));
			this.get_selection().select_iter(item);
			
			return item;
		}
		else if(o is Playlist) {
			TreeIter item;
			TreeIter pivot;
			sideTreeModel.iter_children(out pivot, playlists_iter);
			
			do {
				string tempName;
				GLib.Object tempO;
				sideTreeModel.get(pivot, 0, out tempO, 2, out tempName);
				
				if(tempO != null && tempO is Playlist && tempName > name) {
					sideTreeModel.insert_before(out item, playlists_iter, pivot);
					break;
				}
				else if(!sideTreeModel.iter_next(ref pivot)) {
					sideTreeModel.append(out item, parent);
					break;
				}
			} while(true);
			
			sideTreeModel.set(item, 0, o, 1, w, 2, name);
			this.expand_to_path(sideTreeModel.get_path(item));
			this.get_selection().select_iter(item);
			
			return item;
		}
		else {
			TreeIter iter;
			sideTreeModel.append(out iter, parent);
			sideTreeModel.set(iter, 0, o, 1, w, 2, name);
			return iter;
		}
	}
	
	public Widget getSelectedWidget() {
		TreeSelection selected = this.get_selection();
		selected.set_mode(SelectionMode.SINGLE);
		TreeModel model;
		TreeIter iter;
		selected.get_selected (out model, out iter);
		
		Widget w;
		sideTreeModel.get(iter, 1, out w);
		return w;
	}
	
	public Widget getWidget(TreeIter iter) {
		Widget w;
		sideTreeModel.get(iter, 1, out w);
		return w;
	}
	
	public Widget get_current_widget() {
		return current_widget;
	}
	
	public void updatePlayQueue() {
		Widget w;
		sideTreeModel.get(playlists_queue_iter, 1, out w);
		((MusicTreeView)w).populateView(lm.queue(), false);
	}
	
	public void updateAlreadyPlayed() {
		Widget w;
		sideTreeModel.get(playlists_history_iter, 1, out w);
		((MusicTreeView)w).populateView(lm.already_played(), false);
	}
	
	public virtual void sideListSelectionChange() {
		sideTreeModel.foreach(updateView);
		
		if(current_widget is MusicTreeView) {
			int count = 0;
			int total_time = 0;
			int total_mbs = 0;
			
			foreach(int id in ((MusicTreeView)current_widget).get_songs()) {
				++count;
				total_time += lm.song_from_id(id).length;
				total_mbs += lm.song_from_id(id).file_size;
			}
			
			string fancy = "";
			if(total_time < 3600) { // less than 1 hour show in minute units
				fancy = (total_time/60).to_string() + " minutes";
			}
			else if(total_time < (24 * 3600)) { // less than 1 day show in hour units
				fancy = (total_time/3600).to_string() + " hours";
			}
			else { // units in days
				fancy = (total_time/(24 * 3600)).to_string() + " days";
			}
			
			string fancy_size = "";
			if(total_mbs < 1000)
				fancy_size = ((float)(total_mbs)).to_string() + " MB's";
			else 
				fancy_size = ((float)(total_mbs/1000.0f)).to_string() + " GB's";
			
			lw.setStatusBarText(count.to_string() + " items, " + fancy + ", " + fancy_size);
		}
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
			
			if(!sideTreeModel.get_iter(out iter, path))
				return false;
			
			GLib.Object o;
			sideTreeModel.get(iter, 0, out o);
			string name;
			sideTreeModel.get(iter, 2, out name);
			
			TreeIter parent;
			sideTreeModel.iter_parent(out parent, iter);
			if(sideTreeModel.iter_is_valid(parent)) {
				
				string parent_name;
				sideTreeModel.get(parent, 2, out parent_name);
				if(iter == library_music_iter) {
					
				}
				else if(iter == library_podcasts_iter) {
					
				}
				else if(iter == library_audiobooks_iter) {
					
				}
				else if(parent == playlists_iter) {
					if(iter == playlists_queue_iter) {
						
					}
					else if(iter == playlists_history_iter) {
						
					}
					else {
						playlistMenu.popup (null, null, null, 3, get_current_event_time());
					}
				}
			}
			else {
				if(iter == library_iter) {
					return true;
				}
				else if(iter == devices_iter) {
					return true;
				}
				else if(iter == network_iter) {
					return true;
				}
				else if(iter == playlists_iter) {
					playlistMenu.popup (null, null, null, 3, get_current_event_time());
					return true;
				}
			}
			
			return false;
		}
		else if(event.type == Gdk.EventType.BUTTON_PRESS && event.button == 1) {
			TreeIter iter;
			TreePath path;
			TreeViewColumn column;
			int cell_x;
			int cell_y;
			
			this.get_path_at_pos((int)event.x, (int)event.y, out path, out column, out cell_x, out cell_y);
			
			if(!sideTreeModel.get_iter(out iter, path))
				return false;
			
			GLib.Object o;
			sideTreeModel.get(iter, 0, out o);
			Widget w;
			sideTreeModel.get(iter, 1, out w);
			string name;
			sideTreeModel.get(iter, 2, out name);
			
			TreeIter parent;
			sideTreeModel.iter_parent(out parent, iter);
			if(sideTreeModel.iter_is_valid(parent)) {
				this.get_selection().select_iter(iter);
				
				string parent_name;
				sideTreeModel.get(parent, 2, out parent_name);
				
				if(iter == playlists_similar_iter) {
					if(((SimilarPane)w)._base == null || ((SimilarPane)w)._have.size == 0)
						return true;
				}
				else if(iter == playlists_queue_iter) {
					MusicTreeView mtv = (MusicTreeView)w;
					mtv.populateView(lm.queue(), false);
				}
				else if(iter == playlists_history_iter) {
					MusicTreeView mtv = (MusicTreeView)w;
					mtv.populateView(lm.already_played(), false);
				}
				else if(parent == playlists_iter && o is SmartPlaylist) {
					MusicTreeView mtv = (MusicTreeView)w;
					mtv.populateView(lm.songs_from_smart_playlist(((SmartPlaylist)o).rowid), false);
				}
				else if(parent == playlists_iter && o is Playlist) {
					MusicTreeView mtv = (MusicTreeView)w;
					mtv.populateView(lm.songs_from_playlist(((Playlist)o).rowid), false);
				}
				
				return false;
			}
			else {
				
				return true;
			}
		}
		
		return false;
	}
	
	public bool updateView(TreeModel model, TreePath path, TreeIter item) {
		Widget w;
		model.get(item, 1, out w);
		
		if(w != null) {
			if(this.get_selection().iter_is_selected(item)) {
				w.show();
				this.current_widget = w;
				if(w is MusicTreeView) {
					((MusicTreeView)w).is_current_view = true;
				}
			}
			else {
				w.hide();
				if(w is MusicTreeView)
					((MusicTreeView)w).is_current_view = false;
			}
		}
		
		return false;
	}
	
	public void resetView() {
		this.get_selection().unselect_all();
		this.get_selection().select_iter(library_music_iter);
		model.foreach(updateView);
	}
	
	//smart playlist context menu
	public virtual void smartPlaylistMenuNewClicked() {
		SmartPlaylistEditor spe = new SmartPlaylistEditor(lw, new SmartPlaylist());
		spe.playlist_saved.connect(smartPlaylistEditorSaved);
	}
	
	public virtual void smartPlaylistEditorSaved(SmartPlaylist sp) {
		if(sp.rowid > 0) {
			TreeIter pivot = playlists_history_iter;
				
			do {
				GLib.Object o;
				sideTreeModel.get(pivot, 0, out o);
				if(o is SmartPlaylist && ((SmartPlaylist)o).rowid == sp.rowid) {
					string name;
					Widget w;
					sideTreeModel.get(pivot, 1, out w, 2, out name);
					
					sideTreeModel.remove(pivot);
					addItem(playlists_iter, sp, w, sp.name);
					
					((MusicTreeView)w).populateView(lm.songs_from_smart_playlist(sp.rowid), false);
					
					break;
				}
			} while(sideTreeModel.iter_next(ref pivot));
		}
		else {
			lm.add_smart_playlist(sp);
			lw.addSideListItem(sp);
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
				sideTreeModel.get(pivot, 0, out o);
				if(o is Playlist && ((Playlist)o).rowid == p.rowid) {
					string name;
					Widget w;
					sideTreeModel.get(pivot, 1, out w, 2, out name);
					
					sideTreeModel.remove(pivot);
					addItem(playlists_iter, p, w, p.name);
					((MusicTreeView)w).populateView(lm.songs_from_playlist(p.rowid), false);
					
					break;
				}
			} while(sideTreeModel.iter_next(ref pivot));
		}
		else {
			lm.add_playlist(p);
			lw.addSideListItem(p);
		}
	}
	
	public virtual void playlistMenuEditClicked() {
		TreeSelection selected = this.get_selection();
		selected.set_mode(SelectionMode.SINGLE);
		TreeModel model;
		TreeIter iter;
		selected.get_selected (out model, out iter);
		
		GLib.Object o;
		sideTreeModel.get(iter, 0, out o);
		
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
		TreeSelection selected = this.get_selection();
		selected.set_mode(SelectionMode.SINGLE);
		TreeModel model;
		TreeIter iter;
		selected.get_selected (out model, out iter);
		
		GLib.Object o;
		sideTreeModel.get(iter, 0, out o);
		Widget w;
		sideTreeModel.get(iter, 1, out w);
		
		if(o is Playlist)
			lm.remove_playlist(((Playlist)o).rowid);
		else if(o is SmartPlaylist)
			lm.remove_smart_playlist(((SmartPlaylist)o).rowid);
		
		w.destroy();
		sideTreeModel.remove(iter);
		resetView();
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
		if(!sideTreeModel.get_iter(out iter, path)) {
			Gtk.drag_finish(context, false, false, timestamp);
			return;
		}
		
		GLib.Object o;
		sideTreeModel.get(iter, 0, out o);
		string name;
		sideTreeModel.get(iter, 2, out name);
		
		/* make sure it is either queue or normal playlist */
		if(name == "Queue") {
			foreach (string uri in data.get_uris ()) {
				File file = File.new_for_uri (uri);
				if(file.query_file_type(FileQueryInfoFlags.NOFOLLOW_SYMLINKS) == FileType.REGULAR && file.is_native ()) {
					Song add = lm.song_from_file(file.get_path());
					
					if(add != null) {
						lm.queue_song_by_id(add.rowid);
						success = true;
					}
				}
			}
		}
		else if(o is Playlist) {
			Playlist p = (Playlist)o;
			
			foreach (string uri in data.get_uris ()) {
				File file = File.new_for_uri (uri);
				if(file.query_file_type(FileQueryInfoFlags.NOFOLLOW_SYMLINKS) == FileType.REGULAR && file.is_native ()) {
					Song add = lm.song_from_file(file.get_path());
					
					if(add != null) {
						p.addSong(add);
						success = true;
					}
				}
			}
		}
		
		Gtk.drag_finish (context, success, false, timestamp);
    }
}
