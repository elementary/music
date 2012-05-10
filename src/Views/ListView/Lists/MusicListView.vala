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

using Gee;
using Gtk;

public class BeatBox.MusicTreeView : GenericList {

	//for header column chooser
	Gee.HashMap<string, Gtk.CheckMenuItem> column_chooser_menu_items;
	Gtk.Menu column_chooser_menu;

	//for media list right click
	Gtk.Menu mediaMenuActionMenu;
	Gtk.MenuItem mediaEditMedia;
	Gtk.MenuItem mediaFileBrowse;
	Gtk.MenuItem mediaMenuQueue;
	Gtk.MenuItem mediaMenuNewPlaylist;
	Gtk.MenuItem mediaMenuAddToPlaylist; // make menu on fly
	Granite.Widgets.RatingMenuItem mediaRateMedia;
	Gtk.MenuItem mediaRemove;
	Gtk.MenuItem importToLibrary;

	// for editing cells in-treeview
	CellRendererText cellTrack;
	CellRendererText cellTitle;
	CellRendererText cellLength;
	CellRendererText cellArtist;
#if HAVE_SMART_ALBUM_COLUMN
	SmartAlbumRenderer cellAlbum;
#else
	CellRendererText cellAlbum;
#endif
	CellRendererText cellGenre;
	CellRendererText cellYear;
	CellRendererText cellSkips;
	CellRendererText cellPlays;
	CellRendererText cellBitrate;
	
	Granite.Widgets.CellRendererRating cellRating;

	public enum MusicColumn {
		ROWID,
		ICON,
		NUMBER,
		TRACK,
		TITLE,
		LENGTH,
		ARTIST,
		ALBUM,
		GENRE,
		YEAR,
		BITRATE,
		RATING,
		PLAY_COUNT,
		SKIP_COUNT,
		DATE_ADDED,
		LAST_PLAYED,
		BPM,
		PULSER
	}

	/**
	 * for sort_id use 0+ for normal, -1 for auto, -2 for none
	 */
	public MusicTreeView(ViewWrapper view_wrapper, TreeViewSetup tvs) {
		var types = new GLib.List<Type>();
		types.append(typeof(int)); // id
		types.append(typeof(GLib.Icon)); // icon
		types.append(typeof(int)); // #
		types.append(typeof(int)); // track
		types.append(typeof(string)); // title
		types.append(typeof(int)); // length
		types.append(typeof(string)); // artist
		types.append(typeof(string)); // album
		types.append(typeof(string)); // genre
		types.append(typeof(int)); // year
		types.append(typeof(int)); // bitrate
		types.append(typeof(int)); // rating
		types.append(typeof(int)); // plays
		types.append(typeof(int)); // skips
		types.append(typeof(int)); // date added
		types.append(typeof(int)); // last played
		types.append(typeof(int)); // bpm
		types.append(typeof(int)); // pulser};

		base(view_wrapper, types, tvs);

		buildUI();
	}

	private void add_column_chooser_menu_item (TreeViewColumn tvc) {
		var column_id = tvc.title;

		if (column_chooser_menu == null)
			column_chooser_menu = new Gtk.Menu ();
		if (column_chooser_menu_items == null)
			column_chooser_menu_items = new Gee.HashMap<string, Gtk.CheckMenuItem> ();

		var menu_item = new Gtk.CheckMenuItem.with_label (column_id);
		menu_item.active = tvc.visible;

		column_chooser_menu.append (menu_item);
		column_chooser_menu_items.set (column_id, menu_item);

		column_chooser_menu.show_all ();

		menu_item.toggled.connect (column_menu_item_toggled);
	}

	public override void update_sensitivities() {
		mediaMenuActionMenu.show_all();

		if(get_hint() == ViewWrapper.Hint.MUSIC) {
			mediaRemove.set_sensitive(true);
			mediaRemove.set_label(_("Remove from Library"));
			var columnNumber = column_chooser_menu_items.get (TreeViewSetup.COLUMN_NUM);
			columnNumber.set_active(false);
			columnNumber.set_visible(false);
			importToLibrary.set_visible(false);
		}
		else if(get_hint() == ViewWrapper.Hint.SIMILAR) {
			mediaRemove.set_sensitive(false);
			importToLibrary.set_visible(false);
		}
		else if(get_hint() == ViewWrapper.Hint.QUEUE) {
			mediaRemove.set_sensitive(true);
			mediaRemove.set_label(_("Remove from Queue"));
			mediaMenuQueue.set_sensitive(false);
			importToLibrary.set_visible(false);
		}
		else if(get_hint() == ViewWrapper.Hint.HISTORY) {
			mediaRemove.set_sensitive(false);
			importToLibrary.set_visible(false);
		}
		else if(get_hint() == ViewWrapper.Hint.PLAYLIST) {
			mediaRemove.set_sensitive(true);
			importToLibrary.set_visible(false);
		}
		else if(get_hint() == ViewWrapper.Hint.SMART_PLAYLIST) {
			mediaRemove.set_sensitive(false);
			importToLibrary.set_visible(false);
		}
		else if(get_hint() == ViewWrapper.Hint.DEVICE_AUDIO) {
			mediaRemove.set_visible(false);
			mediaRemove.set_label("TODO: Remove from device");
			importToLibrary.set_visible(true);
			//mediaMenuAddToPlaylist.set_visible(false);
			//mediaMenuNewPlaylist.set_visible(false);
		}
		else if(get_hint() == ViewWrapper.Hint.CDROM) {
			mediaRemove.set_visible(false);
			importToLibrary.set_visible(true);
			mediaMenuAddToPlaylist.set_visible(false);
			mediaMenuNewPlaylist.set_visible(false);
		}
		else {
			mediaRemove.set_sensitive(false);
		}
	}

	public void buildUI() {
		cellTrack = new CellRendererText();
		cellTitle = new CellRendererText();
		cellLength = new CellRendererText();
		cellArtist = new CellRendererText();
#if HAVE_SMART_ALBUM_COLUMN
		cellAlbum = new SmartAlbumRenderer();
#else
		cellAlbum = new CellRendererText();
#endif
		cellGenre = new CellRendererText();
		cellYear = new CellRendererText();
		cellRating = new Granite.Widgets.CellRendererRating();
		cellSkips = new CellRendererText();
		cellPlays = new CellRendererText();
		cellBitrate = new CellRendererText();

		cellRating.rating_changed.connect (on_rating_cell_changed);

		//cellTitle.editable = false;
		//cellTitle.edited.connect(cellTitleEdited);

		var to_use = new GLib.List<TreeViewColumn>();
		var originalOrder = new GLib.List<TreeViewColumn>();
		var correctStringOrder = new GLib.List<string>();
		to_use = tvs.get_columns();

		foreach(var tvc in to_use) {
			originalOrder.append(tvc);
			correctStringOrder.append(tvc.title);
		}

		int index = 0;
		foreach(TreeViewColumn tvc in originalOrder) {
			if(!(tvc.title == TreeViewSetup.COLUMN_BLANK || tvc.title == TreeViewSetup.COLUMN_ID)) {
				if (tvc.title == TreeViewSetup.COLUMN_BITRATE) {
					insert_column_with_data_func(-1, tvc.title, cellBitrate, cellHelper.bitrateTreeViewFiller);
				}
				else if (tvc.title == TreeViewSetup.COLUMN_LENGTH)
					insert_column_with_data_func(-1, tvc.title, cellLength, cellHelper.lengthTreeViewFiller);
				else if(tvc.title == TreeViewSetup.COLUMN_DATE_ADDED)
					insert_column_with_data_func(-1, tvc.title, new CellRendererText(), cellHelper.dateTreeViewFiller);
				else if(tvc.title == TreeViewSetup.COLUMN_LAST_PLAYED)
					insert_column_with_data_func(-1, tvc.title, new CellRendererText(), cellHelper.dateTreeViewFiller);
				else if(tvc.title == TreeViewSetup.COLUMN_RATING)
					insert_column_with_data_func(-1, tvc.title, cellRating, cellHelper.ratingTreeViewFiller);
				else if(tvc.title == TreeViewSetup.COLUMN_YEAR)
					insert_column_with_data_func(-1, tvc.title, cellYear, cellHelper.intelligentTreeViewFiller);
				else if(tvc.title == TreeViewSetup.COLUMN_NUM)
					insert_column_with_data_func(-1, tvc.title, new CellRendererText(), cellHelper.intelligentTreeViewFiller);
				else if(tvc.title == TreeViewSetup.COLUMN_TRACK)
					insert_column_with_data_func(-1, tvc.title, cellTrack, cellHelper.intelligentTreeViewFiller);
				else if(tvc.title == TreeViewSetup.COLUMN_PLAYS)
					insert_column_with_data_func(-1, tvc.title, cellPlays, cellHelper.intelligentTreeViewFiller);
				else if(tvc.title == TreeViewSetup.COLUMN_SKIPS)
					insert_column_with_data_func(-1, tvc.title, cellSkips, cellHelper.intelligentTreeViewFiller);
				else if(tvc.title == TreeViewSetup.COLUMN_TITLE)
					insert_column_with_data_func(-1, tvc.title, cellTitle, cellHelper.stringTreeViewFiller);
				else if(tvc.title == TreeViewSetup.COLUMN_ARTIST)
					insert_column_with_data_func(-1, tvc.title, cellArtist, cellHelper.stringTreeViewFiller);
				else if(tvc.title == TreeViewSetup.COLUMN_ALBUM)
#if HAVE_SMART_ALBUM_COLUMN
					insert_column_with_data_func(-1, tvc.title, cellAlbum, cellHelper.smartAlbumFiller);
#else
					insert_column_with_data_func(-1, tvc.title, cellAlbum, cellHelper.stringTreeViewFiller);
#endif
				else if(tvc.title == TreeViewSetup.COLUMN_GENRE)
					insert_column_with_data_func(-1, tvc.title, cellGenre, cellHelper.stringTreeViewFiller);
				else if(tvc.title == TreeViewSetup.COLUMN_BPM)
					insert_column_with_data_func(-1, tvc.title, new CellRendererText(), cellHelper.intelligentTreeViewFiller);
				else
					insert_column(tvc, index);


				get_column(index).resizable = true;
				get_column(index).reorderable = false;
				get_column(index).clickable = true;
				get_column(index).sort_column_id = index;
				get_column(index).set_sort_indicator(false);
				get_column(index).visible = tvc.visible;
				get_column(index).sizing = Gtk.TreeViewColumnSizing.FIXED;
				get_column(index).fixed_width = tvc.fixed_width;

				// Add menuitem
				add_column_chooser_menu_item (tvc);
			}
			else if(tvc.title == TreeViewSetup.COLUMN_BLANK) {
				// Icon column
				
				insert_column(tvc, index);

				tvc.fixed_width = 24;
				tvc.clickable = false;
				tvc.sort_column_id = -1;
				tvc.resizable = false;
				tvc.reorderable = false;

				tvc.clear_attributes (tvc.get_cells().nth_data(0));
				tvc.clear_attributes (tvc.get_cells().nth_data(1));

				tvc.set_cell_data_func(tvc.get_cells().nth_data(0), iconDataFunc);
				tvc.set_cell_data_func(tvc.get_cells().nth_data(1), iconDataFunc);
			}
			else if(tvc.title == TreeViewSetup.COLUMN_ID) {
				insert_column(tvc, index);
			}
			else {
				insert_column(tvc, index);
			}

			get_column(index).get_button().button_press_event.connect(viewHeaderClick);
			get_column(index).notify["width"].connect(viewHeadersResized);

			++index;
		}
		
		set_compare_func(view_compare_func);

		//set_search_func(view_search_func);
		set_value_func(view_value_func);
        
		//rearrangeColumns(correctStringOrder);
		//viewColumnsChanged();

		//enable_grid_lines = TreeViewGridLines.VERTICAL; // will require special theming to work properly

		button_press_event.connect(on_button_press);

		//cursor_changed.connect_after(() => { update_rating_menu(); });
		button_release_event.connect(on_button_pressRelease);
		//columns_changed.connect(viewColumnsChanged);

		//media list right click menu
		mediaMenuActionMenu = new Gtk.Menu();
		mediaEditMedia = new Gtk.MenuItem.with_label (_("Edit Song Info"));
		mediaFileBrowse = new Gtk.MenuItem.with_label (_("Show in File Browser"));
		mediaMenuQueue = new Gtk.MenuItem.with_label (_("Queue"));
		mediaMenuNewPlaylist = new Gtk.MenuItem.with_label (_("New Playlist"));
		mediaMenuAddToPlaylist = new Gtk.MenuItem.with_label (_("Add to Playlist"));
		mediaRemove = new Gtk.MenuItem.with_label (_("Remove Song"));
		importToLibrary = new Gtk.MenuItem.with_label (_("Import to Library"));
		mediaRateMedia = new Granite.Widgets.RatingMenuItem ();
		mediaMenuActionMenu.append(mediaEditMedia);
		mediaMenuActionMenu.append(mediaFileBrowse);

		mediaMenuActionMenu.append(mediaRateMedia);

		mediaMenuActionMenu.append(new SeparatorMenuItem());
		mediaMenuActionMenu.append(mediaMenuQueue);
		mediaMenuActionMenu.append(mediaMenuNewPlaylist);
		mediaMenuActionMenu.append(mediaMenuAddToPlaylist);
		mediaMenuActionMenu.append(new SeparatorMenuItem());
		mediaMenuActionMenu.append(mediaRemove);
		mediaMenuActionMenu.append(importToLibrary);
		mediaEditMedia.activate.connect(mediaMenuEditClicked);
		mediaFileBrowse.activate.connect(mediaFileBrowseClicked);
		mediaMenuQueue.activate.connect(mediaMenuQueueClicked);
		mediaMenuNewPlaylist.activate.connect(mediaMenuNewPlaylistClicked);
		mediaRemove.activate.connect(mediaRemoveClicked);
		importToLibrary.activate.connect(importToLibraryClicked);
		mediaRateMedia.activate.connect(mediaRateMediaClicked);

		//update_column_header_items  ();
		update_sensitivities ();

		//this.list_model.rows_reordered.connect(modelRowsReordered);
		//this.list_model.sort_column_changed.connect(sortColumnChanged);
		
	}

	public void rearrangeColumns(LinkedList<string> correctOrder) {
		move_column_after(get_column(6), get_column(7));
		//debug("correctOrder.length = %d, get_columns.length() = %d\n", correctOrder.size, (int)get_columns().length());
		/* iterate through get_columns and if a column is not in the
		 * same location as correctOrder, move it there.
		*/
		for(int index = 0; index < get_columns().length(); ++index) {
			//debug("on index %d column %s originally moving to %d\n", index, get_column(index).title, correctOrder.index_of(get_column(index).title));
			if(get_column(index).title != correctOrder.get(index)) {
				move_column_after(get_column(index), get_column(correctOrder.index_of(get_column(index).title)));
			}
		}
	}

	// When the user clicks over a cell in the rating column, that cell renderer
	// emits the rating_changed signal. We need to update that rating...
	private void on_rating_cell_changed (int new_rating, Gtk.Widget widget, string path, Gtk.CellRendererState flags) {
		var m = get_media_from_index (int.parse (path));

		if (m == null)
			return;

		m.rating = new_rating;

		var to_update = new LinkedList<Media> ();
		to_update.add (m);
		lm.update_medias (to_update, true, true);
	}

	public void cellTitleEdited(string path, string new_text) {
		/*int rowid;
		debug("done!\n");
		if((rowid = list_model.getRowidFromPath(path)) != 0) {
			lm.media_from_id(rowid).title = new_text;

			lm.update_media(lm.media_from_id(rowid), true);
		}
		cellTitle.editable = false; */
	}

	public virtual void sortColumnChanged() {
		updateTreeViewSetup();
	}

	public virtual void modelRowsReordered(TreePath path, TreeIter? iter, void* new_order) {
		/*if(ViewWrapper.Hint == "queue") {
			lm.clear_queue();

			TreeIter item;
			for(int i = 0; list_model.get_iter_from_string(out item, i.to_string()); ++i) {
				int id;
				list_model.get(item, 0, out id);

				lm.queue_media_by_id(id);
			}
		}*/
		
		// TODO: FIXME
		//if(is_current_view) {
		//	set_as_current_list(0, false);
		//}

		if(!scrolled_recently) {
			scroll_to_current_media();
		}
	}

	public virtual void viewColumnsChanged() {
		updateTreeViewSetup();
	}

	public void update_column_header_items () {
		int index = 0;
		foreach(TreeViewColumn tvc in get_columns()) {
#if 0
			if(tvc.title == TreeViewSetup.COLUMN_NUM)
				columnNumber.active = get_column(index).visible;
			else if(tvc.title == TreeViewSetup.COLUMN_TRACK)
				columnTrack.active = get_column(index).visible;
			else if(tvc.title == TreeViewSetup.COLUMN_TITLE)
				columnTitle.active = get_column(index).visible;
			else if(tvc.title == TreeViewSetup.COLUMN_LENGTH)
				columnLength.active = get_column(index).visible;
			else if(tvc.title == TreeViewSetup.COLUMN_ARTIST)
				columnArtist.active = get_column(index).visible;
			else if(tvc.title == TreeViewSetup.COLUMN_ALBUM)
				columnAlbum.active = get_column(index).visible;
			else if(tvc.title == TreeViewSetup.COLUMN_GENRE)
				columnGenre.active = get_column(index).visible;
			else if(tvc.title == TreeViewSetup.COLUMN_YEAR)
				columnYear.active = get_column(index).visible;
			else if(tvc.title == TreeViewSetup.COLUMN_BITRATE)
				columnBitRate.active = get_column(index).visible;
			else if(tvc.title == TreeViewSetup.COLUMN_RATING)
				columnRating.active = get_column(index).visible;
			else if(tvc.title == TreeViewSetup.COLUMN_PLAYS)
				columnPlayCount.active = get_column(index).visible;
			else if(tvc.title == TreeViewSetup.COLUMN_SKIPS)
				columnSkipCount.active = get_column(index).visible;
			else if(tvc.title == TreeViewSetup.COLUMN_DATE_ADDED)
				columnDateAdded.active = get_column(index).visible;
			else if(tvc.title == TreeViewSetup.COLUMN_LAST_PLAYED)
				columnLastPlayed.active = get_column(index).visible;
			else if(tvc.title == TreeViewSetup.COLUMN_BPM)
				columnBPM.active = get_column(index).visible;
#endif

			// this is equivalent
			var column_item = column_chooser_menu_items.get (tvc.title);
			if (column_item != null)
				column_item.active = get_column (index).visible;
			else
				debug ("column item '%s' is null", tvc.title);

			++index;
		}
	}

	/* button_press_event */
	bool on_button_press (Gdk.EventButton event) {
		if(event.type == Gdk.EventType.BUTTON_PRESS && event.button == 3) { //right click
			/* create add to playlist menu */
			Gtk.Menu addToPlaylistMenu = new Gtk.Menu();
			foreach(Playlist p in lm.playlists()) {
				/* Verify that it's not this list's playlist! */
				if (get_hint () == ViewWrapper.Hint.PLAYLIST && p.rowid == get_relative_id ())
					continue;
			
				Gtk.MenuItem playlist = new Gtk.MenuItem.with_label(p.name);
				addToPlaylistMenu.append(playlist);

				playlist.activate.connect( () => {
					var to_add = new LinkedList<int>();
					
					foreach(Media m in get_selected_medias()) {
						to_add.add(m.rowid);
					}
					p.add_media(to_add);
				});
			}

			addToPlaylistMenu.show_all();
			mediaMenuAddToPlaylist.submenu = addToPlaylistMenu;

			if(lm.playlists().size == 0 || addToPlaylistMenu.get_children ().length () < 1)
				mediaMenuAddToPlaylist.set_sensitive(false);
			else
				mediaMenuAddToPlaylist.set_sensitive(true);

			// if all medias are downloaded already, desensitize.
			// if half and half, change text to 'Download %external of %total'
			int temporary_count = 0;
			int total_count = 0;
			foreach(Media m in get_selected_medias()) {
				if(m.isTemporary)
					++temporary_count;

				++total_count;
			}

			if(temporary_count == 0)
				importToLibrary.set_sensitive(false);
			else {
				importToLibrary.set_sensitive(true);
				if(temporary_count != total_count)
					importToLibrary.label = _("Import %d of %d selected songs").printf (temporary_count, total_count);
				else if (temporary_count > 1)
					importToLibrary.label = _("Import %d songs").printf (temporary_count);
				else // 1 song
					importToLibrary.label = _("Import");
			}

			int set_rating = -1;
			foreach(Media m in get_selected_medias()) {
				if(set_rating == -1)
					set_rating = (int)m.rating;
				else if(set_rating != m.rating) {
					set_rating = 0;
					break;
				}
			}

			mediaRateMedia.rating_value = set_rating;
			mediaMenuActionMenu.popup (null, null, null, 3, get_current_event_time());

			TreeSelection selected = get_selection();
			selected.set_mode(SelectionMode.MULTIPLE);
			if(selected.count_selected_rows() > 1)
				return true;
			else
				return false;
		}
		else if(event.type == Gdk.EventType.BUTTON_PRESS && event.button == 1) {
			//TreeIter iter;
			TreePath path;
			TreeViewColumn column;
			int cell_x;
			int cell_y;

			get_path_at_pos((int)event.x, (int)event.y, out path, out column, out cell_x, out cell_y);

			//if(!list_model.get_iter(out iter, path))
			//	return false;

			/* don't unselect everything if multiple selected until button release
			 * for drag and drop reasons */
			if(get_selection().count_selected_rows() > 1) {
				if(get_selection().path_is_selected(path)) {
					if(((event.state & Gdk.ModifierType.SHIFT_MASK) == Gdk.ModifierType.SHIFT_MASK)|
						((event.state & Gdk.ModifierType.CONTROL_MASK) == Gdk.ModifierType.CONTROL_MASK)) {
							get_selection().unselect_path(path);
					}
					return true;
				}
				else if(!(((event.state & Gdk.ModifierType.SHIFT_MASK) == Gdk.ModifierType.SHIFT_MASK)|
				((event.state & Gdk.ModifierType.CONTROL_MASK) == Gdk.ModifierType.CONTROL_MASK))) {
					return true;
				}

				return false;
			}
		}

		return false;
	}

	/* button_release_event */
	private bool on_button_pressRelease(Gtk.Widget sender, Gdk.EventButton event) {
		/* if we were dragging, then set dragging to false */
		if(dragging && event.button == 1) {
			dragging = false;
			return true;
		}
		else if(((event.state & Gdk.ModifierType.SHIFT_MASK) == Gdk.ModifierType.SHIFT_MASK) | ((event.state & Gdk.ModifierType.CONTROL_MASK) == Gdk.ModifierType.CONTROL_MASK)) {
			return true;
		}
		else {
			TreePath path;
			TreeViewColumn tvc;
			int cell_x;
			int cell_y;
			int x = (int)event.x;
			int y = (int)event.y;

			if(!(get_path_at_pos(x, y, out path, out tvc, out cell_x, out cell_y))) return false;
			get_selection().unselect_all();
			get_selection().select_path(path);
			return false;
		}
	}

	private bool viewHeaderClick(Gtk.Widget w, Gdk.EventButton e) {
		if(e.button == 3) {
			column_chooser_menu.popup (null, null, null, 3, get_current_event_time());
			return true;
		}
/* XXX: delete. We don't want ot represent shuffle visually
		else if(e.button == 1) {
			// If the user tries to sort, then make sure that all other views
			// become sorted (unshuffled) if they are shuffled
			lw.shuffleChooser.setOption(0);
			
			updateTreeViewSetup();
			
			return false;
		}
*/
		return false;
	}

	void viewHeadersResized() {
		updateTreeViewSetup();
	}

	void updateTreeViewSetup() {
		if(tvs == null || !visible || get_hint() == ViewWrapper.Hint.ALBUM_LIST || get_columns().length() != TreeViewSetup.MUSIC_COLUMN_COUNT)
			return;

		int sort_id = MusicColumn.ARTIST;
		SortType sort_dir = Gtk.SortType.ASCENDING;
		get_sort_column_id(out sort_id, out sort_dir);

		if(sort_id <= 0)
			sort_id = MusicColumn.ARTIST;
		
		tvs.set_columns(get_columns());
		tvs.sort_column_id = sort_id;
		tvs.sort_direction = sort_dir;
	}

	/** When the column chooser popup menu has a change/toggle
	 * FIXME: This relies extremely in the order of the 'else if' control lines.
	 *         Fetch columns by col_id<string>
	 **/
	public virtual void column_menu_item_toggled () {
		int index = 0;
		
		foreach(TreeViewColumn tvc in get_columns()) {
#if 0
			if(tvc.title == TreeViewSetup.COLUMN_TRACK)
				get_column(index).visible = column_chooser_menu_items.get (TreeViewSetup.COLUMN_TRACK).active;
			else if(tvc.title == TreeViewSetup.COLUMN_NUM)
				get_column(index).visible = column_chooser_menu_items.get (TreeViewSetup.COLUMN_NUM).active;
			else if(tvc.title == TreeViewSetup.COLUMN_TITLE)
				get_column(index).visible = column_chooser_menu_items.get (TreeViewSetup.COLUMN_TITLE).active;
			else if(tvc.title == TreeViewSetup.COLUMN_LENGTH)
				get_column(index).visible = column_chooser_menu_items.get (TreeViewSetup.COLUMN_LENGTH).active;
			else if(tvc.title == TreeViewSetup.COLUMN_ARTIST)
				get_column(index).visible = column_chooser_menu_items.get (TreeViewSetup.COLUMN_ARTIST).active;
			else if(tvc.title == TreeViewSetup.COLUMN_ALBUM)
				get_column(index).visible = column_chooser_menu_items.get (TreeViewSetup.COLUMN_ALBUM).active;
			else if(tvc.title == TreeViewSetup.COLUMN_GENRE)
				get_column(index).visible = column_chooser_menu_items.get (TreeViewSetup.COLUMN_GENRE).active;
			else if(tvc.title == TreeViewSetup.COLUMN_YEAR)
				get_column(index).visible = column_chooser_menu_items.get (TreeViewSetup.COLUMN_YEAR).active;
			else if(tvc.title == TreeViewSetup.COLUMN_BITRATE)
				get_column(index).visible = column_chooser_menu_items.get (TreeViewSetup.COLUMN_BITRATE).active;
			else if(tvc.title == TreeViewSetup.COLUMN_RATING)
				get_column(index).visible = column_chooser_menu_items.get (TreeViewSetup.COLUMN_RATING).active;
			else if(tvc.title == TreeViewSetup.COLUMN_PLAYS)
				get_column(index).visible = column_chooser_menu_items.get (TreeViewSetup.COLUMN_PLAYS).active;
			else if(tvc.title == TreeViewSetup.COLUMN_SKIPS)
				get_column(index).visible = column_chooser_menu_items.get (TreeViewSetup.COLUMN_SKIPS).active;
			else if(tvc.title == TreeViewSetup.COLUMN_DATE_ADDED)
				get_column(index).visible = column_chooser_menu_items.get (TreeViewSetup.COLUMN_DATE_ADDED).active;
			else if(tvc.title == TreeViewSetup.COLUMN_LAST_PLAYED)
				get_column(index).visible = column_chooser_menu_items.get (TreeViewSetup.COLUMN_LAST_PLAYED).active;//add bpm, file size, file path
			else if(tvc.title == TreeViewSetup.COLUMN_BPM)
				get_column(index).visible = column_chooser_menu_items.get (TreeViewSetup.COLUMN_BPM).active;
#endif

			// this is equivalent
			var column_item = column_chooser_menu_items.get (tvc.title);
			if (column_item != null)
				get_column (index).visible = column_item.active;

			++index;
		}

		tvs.set_columns(get_columns());
	}

	/** media menu popup clicks **/
	public virtual void mediaMenuEditClicked() {
		var to_edit = new LinkedList<int>();
		
		foreach(Media m in get_selected_medias()) {
			to_edit.add(m.rowid);
		}

		/*if(!GLib.File.new_for_path(media_from_id(id).file).query_exists() && media_from_id(id).file.contains(settings.getMusicFolder())) {
			media_from_id(id).unique_status_image = lw.render_icon("process-error-symbolic", Gtk.IconSize.MENU, null);
			lw.media_not_found(id);
		}
		else {*/
			var list = new LinkedList<int>();
			for(int i = 0; i < get_visible_table().size(); ++i) {
				list.add(get_media_from_index(i).rowid);
			}
			MediaEditor se = new MediaEditor(lm, list, to_edit);
			se.medias_saved.connect(mediaEditorSaved);
		//}
	}

	public virtual void mediaEditorSaved(LinkedList<int> medias) {
		LinkedList<Media> toUpdate = new LinkedList<Media>();
		foreach(int i in medias)
			toUpdate.add(lm.media_from_id(i));

		// could have edited rating, so record_time is true
		lm.update_medias(toUpdate, true, true);

		if(get_hint() == ViewWrapper.Hint.SMART_PLAYLIST) {
			// make sure these medias still belongs here
		}
	}

	void mediaFileBrowseClicked() {
		foreach(Media m in get_selected_medias()) {
			try {
				var file = File.new_for_uri(m.uri);
				Gtk.show_uri(null, file.get_parent().get_uri(), 0);
			}
			catch(GLib.Error err) {
				debug("Could not browse media %s: %s\n", m.uri, err.message);
			}

			return;
		}
	}

	public virtual void mediaMenuQueueClicked() {
		var to_queue = new LinkedList<int>();

		foreach(Media m in get_selected_medias()) {
			to_queue.add (m.rowid);
		}

		lm.queue_media_by_id (to_queue);
	}

	public virtual void mediaMenuNewPlaylistClicked() {
		Playlist p = new Playlist();
		
		var to_add = new LinkedList<int>();
		foreach(Media m in get_selected_medias()) {
			to_add.add(m.rowid);
		}
		p.add_media (to_add);

		PlaylistNameWindow pnw = new PlaylistNameWindow(lw, p);
		pnw.playlist_saved.connect( (newP) => {
			lm.add_playlist(p);
			lw.addSideListItem(p);
		});
	}
	
	void mediaRateMediaClicked() {
		var los = new LinkedList<Media>();
		int new_rating = mediaRateMedia.rating_value;

		foreach(Media m in get_selected_medias()) {
			m.rating = new_rating;
			los.add(m);
		}

		lm.update_medias(los, false, true);
	}

	public virtual void mediaRemoveClicked() {
		LinkedList<Media> to_remove = new LinkedList<Media>();
		LinkedList<int> to_remove_ids = new LinkedList<int>();
		
		foreach (var m in get_selected_medias()) {
			to_remove_ids.add (m.rowid);

			if (get_hint() == ViewWrapper.Hint.MUSIC ||  get_hint() == ViewWrapper.Hint.DEVICE_AUDIO) {
				to_remove.add(m);
			}
		}

		if (get_hint() == ViewWrapper.Hint.MUSIC) {
			var dialog = new RemoveFilesDialog (lm.lw, to_remove, get_hint());
			dialog.remove_media.connect ( (delete_files) => {
				lm.remove_medias (to_remove, delete_files);
			});
		}
		/*
		else if (get_hint() == ViewWrapper.Hint.DEVICE_AUDIO) {
			var dvw = (DeviceViewWrapper)parent_wrapper;
			dvw.d.remove_medias(to_remove);
		}*/
		else if (get_hint() == ViewWrapper.Hint.QUEUE) {
			lm.unqueue_media_by_id (to_remove_ids);
		}
		else if(get_hint() == ViewWrapper.Hint.PLAYLIST) {
			lm.playlist_from_id(relative_id).remove_media (to_remove_ids);
		}
	}

	void importToLibraryClicked() {
		var to_import = new LinkedList<int>();
		
		foreach(Media m in get_selected_medias()) {
			to_import.add(m.rowid);
		}

		import_requested(to_import);
	}

	public virtual void onDragDataGet(Gdk.DragContext context, Gtk.SelectionData selection_data, uint info, uint time_) {
		string[] uris = null;

		foreach(Media m in get_selected_medias()) {
			debug("adding %s\n", m.uri);
			uris += (m.uri);
		}

		if (uris != null)
			selection_data.set_uris(uris);
	}

	public void apply_style_to_view(CssProvider style) {
		get_style_context().add_provider(style, STYLE_PROVIDER_PRIORITY_APPLICATION);
	}
	
	int view_compare_func (int col, Gtk.SortType dir, Media a_media, Media b_media) {
		int rv = 0;
		
		if(col == MusicColumn.NUMBER) {
			rv = 1;//a.get_position() - b.get_position();
		}
		else if(col == MusicColumn.TRACK) {
			rv = (int)(a_media.track - b_media.track);
		}
		else if(col == MusicColumn.TITLE) {
			rv = advanced_string_compare(a_media.title.down(), b_media.title.down());
		}
		else if(col == MusicColumn.LENGTH) {
			rv = (int)(a_media.length - b_media.length);
		}
		else if(col == MusicColumn.ARTIST) {
			if(a_media.album_artist.down() == b_media.album_artist.down()) {
				if(a_media.album.down() == b_media.album.down()) {
					if(a_media.album_number == b_media.album_number) {
						//if(a_media.track == b_media.track)
						//	rv = advanced_string_compare(a_media.uri, b_media.uri);
						//else
							rv = (int)((sort_direction == SortType.ASCENDING) ? (int)(a_media.track - b_media.track) : (int)(b_media.track - a_media.track));
					}
					else
						rv = (int)((int)a_media.album_number - (int)b_media.album_number);
				}
				else
					rv = advanced_string_compare(a_media.album.down(), b_media.album.down());
			}
			else
				rv = advanced_string_compare(a_media.album_artist.down(), b_media.album_artist.down());
		}
		else if(col == MusicColumn.ALBUM) {
			if(a_media.album.down() == b_media.album.down()) {
				if(a_media.album_number == b_media.album_number)
					rv = (int)((sort_direction == SortType.ASCENDING) ? (int)(a_media.track - b_media.track) : (int)(b_media.track - a_media.track));
				else
					rv = (int)((int)a_media.album_number - (int)b_media.album_number);

			}
			else {
				if(a_media.album == "")
					rv = 1;
				else
					rv = advanced_string_compare(a_media.album.down(), b_media.album.down());
			}
		}
		else if(col == MusicColumn.GENRE) {
			rv = advanced_string_compare(a_media.genre.down(), b_media.genre.down());
		}
		else if(col == MusicColumn.YEAR) {
			rv = (int)(a_media.year - b_media.year);
		}
		else if(col == MusicColumn.BITRATE) {
			rv = (int)(a_media.bitrate - b_media.bitrate);
		}
		else if(col == MusicColumn.RATING) {
			rv = (int)(a_media.rating - b_media.rating);
		}
		else if(col == MusicColumn.LAST_PLAYED) {
			rv = (int)(a_media.last_played - b_media.last_played);
		}
		else if(col == MusicColumn.DATE_ADDED) {
			rv = (int)(a_media.date_added - b_media.date_added);
		}
		else if(col == MusicColumn.PLAY_COUNT) {
			rv = (int)(a_media.play_count - b_media.play_count);
		}
		else if(col == MusicColumn.SKIP_COUNT) {
			rv = (int)(a_media.skip_count - b_media.skip_count);
		}
		else if(col == MusicColumn.BPM) {
			rv = (int)(a_media.bpm - b_media.bpm);
		}
		else {
			rv = 0;
		}
		
		if(rv == 0 && col != MusicColumn.ARTIST && col != MusicColumn.ALBUM)
			rv = advanced_string_compare(a_media.uri, b_media.uri);

		if(sort_direction == SortType.DESCENDING)
			rv = (rv > 0) ? -1 : 1;

		return rv;
	}
	
	Value view_value_func (int row, int column, Media s) {
		Value val;
		
		if(column == MusicColumn.ROWID)
			val = s.rowid;
		else if(column == MusicColumn.ICON) {
			if(lm.media_info.media != null && lm.media_info.media.rowid == s.rowid)
				val = playing_icon;
			else if(tvs.get_hint() == ViewWrapper.Hint.CDROM && !s.isTemporary)
				val = completed_icon;
			else if(s.unique_status_image != null)
				val = s.unique_status_image;
			else
				val = Value(typeof(GLib.Icon));
		}
		else if(column == MusicColumn.NUMBER)
			val = (int)(row + 1);
		else if(column == MusicColumn.TRACK)
			val = (int)s.track;
		else if(column == MusicColumn.TITLE)
			val = s.title;
		else if(column == MusicColumn.LENGTH)
			val = (int)s.length;
		else if(column == MusicColumn.ARTIST)
			val = s.artist;
		else if(column == MusicColumn.ALBUM)
			val = s.album;
		else if(column == MusicColumn.GENRE)
			val = s.genre;
		else if(column == MusicColumn.YEAR)
			val = (int)s.year;
		else if(column == MusicColumn.BITRATE)
			val = (int)s.bitrate;
		else if(column == MusicColumn.RATING)
			val = (int)s.rating;
		else if(column == MusicColumn.PLAY_COUNT)
			val = (int)s.play_count;
		else if(column == MusicColumn.SKIP_COUNT)
			val = (int)s.skip_count;
		else if(column == MusicColumn.DATE_ADDED)
			val = (int)s.date_added;
		else if(column == MusicColumn.LAST_PLAYED)
			val = (int)s.last_played;
		else if(column == MusicColumn.BPM)
			val = (int)s.bpm;
		else// if(column == 17)
			val = (int)s.pulseProgress;
		
		return val;
	}
}

