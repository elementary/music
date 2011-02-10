using Gtk;

public class BeatBox.SideTreeView : TreeView {
	LibraryManager lm;
	LibraryWindow lw;
	TreeStore sideTreeModel;
	
	TreeIter library_iter;
	TreeIter play_queue_iter;
	TreeIter already_played_iter;
	
	TreeIter info_iter;
	TreeIter internet_iter;
	TreeIter playlist_iter;
	TreeIter smart_playlist_iter;
	
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
		
		//set as multiple
		TreeSelection selected = this.get_selection();
		selected.set_mode(SelectionMode.MULTIPLE);
	}
	
	public void buildUI() {
		/* 0: playlist, smart playlist, etc.
		 * 1: the widget to show in relation
		 * 2: name to display
		 */
		sideTreeModel = new TreeStore(3, typeof(GLib.Object), typeof(Widget), typeof(string));
		this.set_model(sideTreeModel);
		this.set_headers_visible(false);
		this.set_level_indentation(30);
		this.show_expanders = false;
		
		TreeViewColumn col = new TreeViewColumn();
		col.title = "object";
		this.insert_column(col, 0);
		
		col = new TreeViewColumn();
		col.title = "widget";
		this.insert_column(col, 1);
		
		this.insert_column_with_data_func(-1, "title", new CellRendererPixbuf(), smartPixTextColumnData);
		var cell_renderer_text = new Gtk.CellRendererText();
		this.get_column(2).pack_end(cell_renderer_text, true);
		this.get_column(2).set_attributes(cell_renderer_text, "text", 2, null);
		
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
		
		this.show_all();
	}
	
	public void smartPixTextColumnData(TreeViewColumn tree_column, CellRenderer cell, TreeModel tree_model, TreeIter iter) {
		GLib.Object o = null;
		string title = "";
		tree_model.get(iter, 0, out o, 2, out title);
		
		if(cell is CellRendererText) {
			string text;
			tree_model.get(iter, 2, out text);
			((CellRendererText)cell).text = text;
		}
		else if(cell is CellRendererPixbuf && title == "Song Info") {
			((CellRendererPixbuf)cell).pixbuf = get_pixbuf_from_stock(Gtk.Stock.INFO, IconSize.MENU);
		}
		else if(cell is CellRendererPixbuf && title == "Library") {
			((CellRendererPixbuf)cell).pixbuf = get_pixbuf_from_stock("folder-music", IconSize.MENU);
		}
		else if(cell is CellRendererPixbuf && title == "Queue") {
			((CellRendererPixbuf)cell).pixbuf = get_pixbuf_from_stock("media-audio", IconSize.MENU);
		}
		else if(cell is CellRendererPixbuf && title == "Already Played") {
			((CellRendererPixbuf)cell).pixbuf = get_pixbuf_from_stock("emblem-urgent", IconSize.MENU);
		}
		else if(cell is CellRendererPixbuf && o is SmartPlaylist) {
			((CellRendererPixbuf)cell).pixbuf = get_pixbuf_from_stock("playlist-automatic", IconSize.MENU);
		}
		else if(cell is CellRendererPixbuf && o is Playlist) {
			((CellRendererPixbuf)cell).pixbuf = get_pixbuf_from_stock("playlist", IconSize.MENU);
		}
	}
	
	Gdk.Pixbuf get_pixbuf_from_stock (string stock_id, Gtk.IconSize size)
	{
	  Gdk.Pixbuf pixbuf;
	 
	  pixbuf = this.render_icon(stock_id, size, null);
	  
	  if(pixbuf == null)
		stdout.printf("null\n");
	  
	  return pixbuf;
	}
	
	public void addBasicItems() {
		stdout.printf("basic\n");
		//sideTreeModel.append(out info_iter, null);
		//sideTreeModel.set(info_iter, 0, null, 1, null, 2, "Information");
		
		//sideTreeModel.append(out internet_iter, null);
		//sideTreeModel.set(internet_iter, 0, null, 1, null, 2, "Internet");
		
		//sideTreeModel.append(out smart_playlist_iter, null);
		//sideTreeModel.set(smart_playlist_iter, 0, null, 1, null, 2, "Smart Playlists");
		
		//sideTreeModel.append(out playlist_iter, null);
		//sideTreeModel.set(playlist_iter, 0, null, 1, null, 2, "Playlists");
		//sideTreeModel.set(playlist_iter, 0, null, 1, null, 2, "Playlists");
	}
	
	public TreeIter addItem(TreeIter? parent, GLib.Object? o, Widget w, string name) {
		if(name == "Library") {
			sideTreeModel.append(out library_iter, parent);
			sideTreeModel.set(library_iter, 0, o, 1, w, 2, name);
			return library_iter;
		}
		else if(name == "Queue") {
			sideTreeModel.append(out play_queue_iter, parent);
			sideTreeModel.set(play_queue_iter, 0, o, 1, w, 2, name);
			return play_queue_iter;
		}
		else if(name == "Already Played") {
			sideTreeModel.append(out already_played_iter, parent);
			sideTreeModel.set(already_played_iter, 0, o, 1, w, 2, name);
			return already_played_iter;
		}
		else {
			TreeIter item;
			sideTreeModel.append(out item, parent);
			sideTreeModel.set(item, 0, o, 1, w, 2, name);
			
			this.expand_to_path(sideTreeModel.get_path(item));
			
			return item;
		}
	}
	
	public Widget getSelectedWidget() {
		TreeSelection selected = this.get_selection();
		selected.set_mode(SelectionMode.SINGLE);
		TreeModel model;
		TreeIter iter;
		selected.get_selected (out model, out iter);
		selected.set_mode(SelectionMode.MULTIPLE);
		
		Widget w;
		sideTreeModel.get(iter, 1, out w);
		return w;
	}
	
	public Widget getWidget(TreeIter iter) {
		Widget w;
		sideTreeModel.get(iter, 1, out w);
		return w;
	}
	
	public TreeIter get_library_iter() {
		return library_iter;
	}
	
	public TreeIter get_play_queue_iter() {
		return play_queue_iter;
	}
	
	public TreeIter get_already_played_iter() {
		return already_played_iter;
	}
	
	/*public TreeIter get_playlist_iter() {
		return playlist_iter;
	}
	
	public TreeIter get_smart_playlist_iter() {
		return smart_playlist_iter;
	}
	
	public TreeIter get_internet_iter() {
		return internet_iter;
	}
	
	public TreeIter get_info_iter() {
		return info_iter;
	}*/
	
	public Widget get_current_widget() {
		return current_widget;
	}
	
	public void updatePlayQueue() {
		Widget w;
		sideTreeModel.get(play_queue_iter, 1, out w);
		((MusicTreeView)w).populateView(lm.queue(), false);
	}
	
	public void updateAlreadyPlayed() {
		Widget w;
		sideTreeModel.get(already_played_iter, 1, out w);
		((MusicTreeView)w).populateView(lm.already_played(), false);
	}
	
	public virtual void sideListSelectionChange() {
		sideTreeModel.foreach(updateView);
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
			
			int id;
			sideTreeModel.get(iter, 0, out id);
			string name;
			sideTreeModel.get(iter, 2, out name);
			
			TreeIter parent;
			sideTreeModel.iter_parent(out parent, iter);
			if(sideTreeModel.iter_is_valid(parent)) {
				string parent_name;
				sideTreeModel.get(parent, 2, out parent_name);
				
				if(parent_name == "Library") {
					playlistMenu.popup (null, null, null, 3, get_current_event_time());
					return false;
				}
			}
			else {
				if(name == "Library") {
					playlistMenu.popup (null, null, null, 2, get_current_event_time());
				}
				else if(name == "Play Queue") {
					//show play queue right click menu
				}
			}
			
			return false;
		}
		else if(event.type == Gdk.EventType.BUTTON_PRESS && event.button == 1) {
			/* All of this happens before selection_changed event, so do
			 * pre-requisites here. Examples are refreshing smart playlist,
			 * opening pandora if it isn't yet, etc.
			 */
			TreeIter item;
			TreePath path;
			TreeViewColumn column;
			int cell_x;
			int cell_y;
			
			this.get_path_at_pos((int)event.x, (int)event.y, out path, out column, out cell_x, out cell_y);
			
			if(!sideTreeModel.get_iter(out item, path))
				return false;
			
			GLib.Object o;
			sideTreeModel.get(item, 0, out o);
			Widget w;
			sideTreeModel.get(item, 1, out w);
			string name;
			sideTreeModel.get(item, 2, out name);
			
			//searchField.text = (search != null) ? search : "";
			
			TreeIter parent;
			sideTreeModel.iter_parent(out parent, item);
			
			if(sideTreeModel.iter_is_valid(parent)) {
				string parent_name;
				sideTreeModel.get(parent, 2, out parent_name);
				
				if(parent_name == "Information") {
					
				}
				else if(parent_name == "Internet") {
					
				}
				else if(parent_name == "Smart Playlists") {
					MusicTreeView mtv = (MusicTreeView)w;
					mtv.populateView(lm.songs_from_smart_playlist(mtv.relative_id), false);
				}
				else if(parent_name == "Playlists") {
					
				}
			}
			else {
				if(name == "Library") {
					
				}
				else if(name == "Queue") {
					MusicTreeView mtv = (MusicTreeView)w;
					mtv.populateView(lm.queue(), false);
				}
				else if(name == "Already Played") {
					MusicTreeView mtv = (MusicTreeView)w;
					mtv.populateView(lm.already_played(), false);
				}
			}
			
			return false;
		}
		
		return false;
	}
	
	public void resetView() {
		this.get_selection().unselect_all();
		this.get_selection().select_iter(library_iter);
		sideTreeModel.foreach(updateView);
	}
	
	public bool updateView(TreeModel model, TreePath path, TreeIter item) {
		Widget w;
		model.get(item, 1, out w);
		
		if(w != null) {
			if(this.get_selection().iter_is_selected(item)) {
				w.show();
				this.current_widget = w;
			}
			else
				w.hide();
		}
			
		return false;
	}
	
	
	
	//smart playlist context menu
	public virtual void smartPlaylistMenuNewClicked() {
		SmartPlaylistEditor spe = new SmartPlaylistEditor(new SmartPlaylist());
		spe.playlist_saved.connect(smartPlaylistEditorSaved);
	}
	
	public virtual void smartPlaylistEditorSaved(SmartPlaylist sp) {
		if(sp.rowid > 0) {
			//edit name
			TreeIter edit;
			// TODO: loop through children to find where id = old
			sideTreeModel.get_iter_from_string(out edit, "4:" + (sp.rowid - 1).to_string());
			sideTreeModel.set(edit, 0, sp, 2, sp.name);
		}
		else {
			//add playlist to list
			lm.add_smart_playlist(sp);
			lw.addSideListItem(sp);
		}
	}
	
	//playlist context menu
	public virtual void playlistMenuNewClicked() {
		PlaylistNameWindow pnw = new PlaylistNameWindow(new Playlist());
		pnw.playlist_saved.connect(playlistNameWindowSaved);
	}
	
	public virtual void playlistNameWindowSaved(Playlist p) {
		if(p.rowid > 0) {
			//edit name
			TreeIter edit;
			
			// TODO: loop through children to find where id = old
			sideTreeModel.get_iter_from_string(out edit, "4:" + (p.rowid - 1).to_string());
			sideTreeModel.set(edit, 0, p, 2, p.name);
		}
		else {
			//add playlist to list
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
		selected.set_mode(SelectionMode.MULTIPLE);
		
		GLib.Object o;
		sideTreeModel.get(iter, 0, out o);
		
		if(o is Playlist) {
			PlaylistNameWindow pnw = new PlaylistNameWindow(((Playlist)o));
			pnw.playlist_saved.connect(playlistNameWindowSaved);
		}
		else if(o is SmartPlaylist) {
			SmartPlaylistEditor spe = new SmartPlaylistEditor((SmartPlaylist)o);
			spe.playlist_saved.connect(smartPlaylistEditorSaved);
		}
	}
	
	public virtual void playlistMenuRemoveClicked() {
		TreeSelection selected = this.get_selection();
		selected.set_mode(SelectionMode.SINGLE);
		TreeModel model;
		TreeIter iter;
		selected.get_selected (out model, out iter);
		selected.set_mode(SelectionMode.MULTIPLE);
		
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
		sideTreeModel.foreach(updateView);
	}
}
