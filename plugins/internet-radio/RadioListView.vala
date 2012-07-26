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

public class Noise.RadioListView : GenericView {

	//for header column chooser
	Gtk.Menu columnChooserMenu;
	CheckMenuItem columnRating;
	CheckMenuItem columnStation;
	CheckMenuItem columnGenre;

	//for media list right click
	Gtk.Menu mediaMenuActionMenu;
	Gtk.MenuItem mediaEditMedia;
	Gtk.MenuItem mediaRemove;
	RatingWidgetMenu mediaRateMedia;

	// for editing cells in-treeview
	CellRendererPixbuf cellRating;
	
	public enum RadioColumn {
		ROWID = 0,
		ICON = 1,
		STATION = 2,
		GENRE = 3,
		RATING = 4,
		PULSER = 5
	}

	/**
	 * for sort_id use 0+ for normal, -1 for auto, -2 for none
	 */
	// FIXME: Wrapper.Hint the_hint is no longer necessary
	public RadioListView(LibraryManager lm, TreeViewSetup tvs, int rel_id) {
		var types = new GLib.List<Type>();
		types.append(typeof(int)); // id
		types.append(typeof(GLib.Icon)); // icon
		types.append(typeof(string)); // station
		types.append(typeof(string)); // genre
		types.append(typeof(int)); // rating
		types.append(typeof(int)); // pulser
		base(lm, types, tvs, rel_id);
		
		//last_search = "";
		//timeout_search = new LinkedList<string>();
		//showing_all = true;
		//removing_medias = false;

		buildUI();
	}

	public override void update_sensitivities() {
		mediaRemove.set_sensitive(true);
		mediaRemove.set_label(_("Remove Station"));
	}

	public void buildUI() {
		cellRating = new CellRendererPixbuf();

		cellRating.xalign = 0.0f;
		
		/* id is always first and is stored as an int. Then the rest are (1)
		 * strings (for simplicity), and include:
		 * #, track, title, artist, album, genre, comment, year, rating, (9)
		 * bitrate, play count, last played, date added, file name, (5)
		 * bpm, length, file size, (3) */
		var to_use = new GLib.List<TreeViewColumn>();
		var originalOrder = new GLib.List<TreeViewColumn>();
		var correctStringOrder = new GLib.List<string>();
		to_use = tvs.get_columns();

		/* put them in the order for treemodel */
		foreach(var tvc in to_use) {
			originalOrder.append(tvc);
			correctStringOrder.append(tvc.title);
		}

		int index = 0;
		foreach(TreeViewColumn tvc in originalOrder) {
			if(!(tvc.title == " " || tvc.title == "id")) {
				if(tvc.title == "Rating")
					insert_column_with_data_func(-1, tvc.title, cellRating, cellHelper.ratingTreeViewFiller);
				else if(tvc.title == "Station")
					insert_column_with_data_func(-1, tvc.title, new CellRendererText(), cellHelper.stringTreeViewFiller);
				else if(tvc.title == "Genre")
					insert_column_with_data_func(-1, tvc.title, new CellRendererText(), cellHelper.stringTreeViewFiller);
				else {
					insert_column(tvc, index);
				}


				get_column(index).resizable = true;
				get_column(index).reorderable = false;
				get_column(index).clickable = true;
				get_column(index).sort_column_id = index;
				get_column(index).set_sort_indicator(false);
				get_column(index).visible = tvc.visible;
				get_column(index).sizing = Gtk.TreeViewColumnSizing.FIXED;
				get_column(index).fixed_width = tvc.fixed_width;
			}
			else if(tvc.title == " ") {
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
			else if(tvc.title == "id") {
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
        set_search_func(view_search_func);
        set_value_func(view_value_func);

		//rearrangeColumns(correctStringOrder);
		//viewColumnsChanged();
		
		button_press_event.connect(viewClick);

		//cursor_changed.connect_after(() => { update_rating_menu(); });
		button_release_event.connect(viewClickRelease);
		//columns_changed.connect(viewColumnsChanged);

		// column chooser menu
		columnChooserMenu = new Gtk.Menu();
		columnStation = new CheckMenuItem.with_label("Station");
		columnGenre = new CheckMenuItem.with_label("Genre");
		columnRating = new CheckMenuItem.with_label("Rating");
		updateColumnVisibilities();
		columnChooserMenu.append(columnStation);
		columnChooserMenu.append(columnGenre);
		columnChooserMenu.append(columnRating);
		columnStation.toggled.connect(columnMenuToggled);
		columnGenre.toggled.connect(columnMenuToggled);
		columnRating.toggled.connect(columnMenuToggled);
		columnChooserMenu.show_all();


		//media list right click menu
		mediaMenuActionMenu = new Gtk.Menu();
		mediaEditMedia = new Gtk.MenuItem.with_label("Edit Station");
		mediaRemove = new Gtk.MenuItem.with_label("Remove Station");
		mediaRateMedia = new RatingWidgetMenu();
		mediaMenuActionMenu.append(mediaEditMedia);
		mediaMenuActionMenu.append(mediaRateMedia);
		mediaMenuActionMenu.append(new SeparatorMenuItem());
		mediaMenuActionMenu.append(mediaRemove);
		mediaEditMedia.activate.connect(mediaMenuEditClicked);
		mediaRemove.activate.connect(mediaRemoveClicked);
		mediaRateMedia.activate.connect(mediaRateMediaClicked);

		update_sensitivities();
		
		// TODO: FIXME
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

	public void updateColumnVisibilities() {
		int index = 0;
		foreach(TreeViewColumn tvc in get_columns()) {
			if(tvc.title == "Station")
				columnStation.active = get_column(index).visible;
			else if(tvc.title == "Genre")
				columnGenre.active = get_column(index).visible;
			else if(tvc.title == "Rating")
				columnRating.active = get_column(index).visible;

			++index;
		}
	}
	
	/* button_press_event */
	bool viewClick(Gdk.EventButton event) {
		if(event.type == Gdk.EventType.BUTTON_PRESS && event.button == 3) { //right click
			mediaMenuActionMenu.show_all();

			int set_rating = -1;
			TreeModel temp;
			foreach(TreePath path in get_selection().get_selected_rows(out temp)) {
				TreeIter item;
				temp.get_iter(out item, path);

				int id;
				temp.get(item, 0, out id);

				if(set_rating == -1)
					set_rating = (int)lm.media_from_id(id).rating;
				else if(set_rating != lm.media_from_id(id).rating) {
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
	private bool viewClickRelease(Gtk.Widget sender, Gdk.EventButton event) {
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
			columnChooserMenu.popup (null, null, null, 3, get_current_event_time());
			return true;
		}
		else if(e.button == 1) {
			updateTreeViewSetup();

			return false;
		}

		return false;
	}

	void viewHeadersResized() {
		updateTreeViewSetup();
	}

	void updateTreeViewSetup() {
		if(tvs == null || !visible || get_columns().length() != TreeViewSetup.RADIO_COLUMN_COUNT)
			return;

		int sort_id = RadioColumn.STATION;
		SortType sort_dir = Gtk.SortType.ASCENDING;
		get_sort_column_id(out sort_id, out sort_dir);

		if(sort_id <= 0)
			sort_id = RadioColumn.STATION;
		
		tvs.set_columns(get_columns());
		tvs.sort_column_id = sort_id;
		tvs.sort_direction = sort_dir;
	}

	/** When the column chooser popup menu has a change/toggle **/
	public virtual void columnMenuToggled() {
		int index = 0;
		foreach(TreeViewColumn tvc in get_columns()) {
			if(tvc.title == "Station")
				get_column(index).visible = columnStation.active;
			else if(tvc.title == "Genre")
				get_column(index).visible = columnGenre.active;
			else if(tvc.title == "Rating")
				get_column(index).visible = columnRating.active;

			++index;
		}

		lm.station_setup.set_columns(get_columns());
	}

	/** media menu popup clicks **/
	public virtual void mediaMenuEditClicked() {
		var to_edit = new LinkedList<int>();
		
		foreach(Media m in get_selected_medias()) {
			to_edit.add(m.rowid);
		}

		/*if(!GLib.File.new_for_path(media_from_id(id).file).query_exists() && media_from_id(id).file.contains(settings.getMusicFolder())) {
			media_from_id(id).unique_status_image = Icons.process_error_icon;
			lw.media_not_found(id);
		}
		else {*/
			var list = new LinkedList<int>();
			for(int i = 0; i < get_visible_table().size(); ++i) {
				list.add(get_media_from_index(i).rowid);
			}
			StationEditor se = new StationEditor(lm, list, to_edit);
			se.stations_saved.connect(stationEditorSaved);
		//}
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

	public virtual void stationEditorSaved(LinkedList<int> medias) {
		LinkedList<Media> toUpdate = new LinkedList<Media>();
		foreach(int i in medias)
			toUpdate.add(lm.media_from_id(i));

		// user could have edited rating, so record time
		lm.update_medias(toUpdate, true, true);
	}

	public virtual void mediaRemoveClicked() {
		LinkedList<Media> toRemove = new LinkedList<Media>();
		LinkedList<int> toRemoveIDs = new LinkedList<int>();

		foreach(Media m in get_selected_medias()) {
			toRemoveIDs.add(m.rowid);

			if(get_hint() == ViewWrapper.Hint.STATION) {
				toRemove.add(m);
			}
		}

		if(get_hint() == ViewWrapper.Hint.STATION) {
			var dialog = new RemoveFilesDialog (lm.lw, toRemove, get_hint());
			dialog.remove_media.connect ( (delete_files) => {
				lm.remove_medias (toRemove, delete_files);
			});
		}
	}
	
	int view_compare_func (int col, Gtk.SortType dir, Media a_media, Media b_media) {
		int rv = 0;
		
		if(sort_column_id == RadioColumn.STATION) { // station
			if(a_media.album_artist.down() == b_media.album_artist.down()) {
				rv = advanced_string_compare(b_media.uri, a_media.uri);
			}
			else
				rv = advanced_string_compare(a_media.album_artist.down(), b_media.album_artist.down());
		}
		else if(sort_column_id == RadioColumn.GENRE) { // genre
			if(a_media.genre.down() == b_media.genre.down()) {
				if(a_media.album_artist.down() == b_media.album_artist.down()) {
					rv = advanced_string_compare(b_media.uri, a_media.uri);
				}
				else {
					rv = advanced_string_compare(a_media.album_artist.down(), b_media.album_artist.down());
				}
			}
			else
				rv = advanced_string_compare(a_media.genre.down(), b_media.genre.down());
		}
		
		else if(sort_column_id == RadioColumn.RATING) { // rating
			rv = (int)(a_media.rating - b_media.rating);
		}
		else {
			rv = 0;
		}
		
		if(rv == 0 && col != RadioColumn.STATION && col != RadioColumn.GENRE)
			rv = advanced_string_compare(a_media.uri, b_media.uri);
		
		if(sort_direction == SortType.DESCENDING)
			rv = (rv > 0) ? -1 : 1;
		
		return rv;
	}
	
	Value view_value_func (int row, int column, Media s) {
		Value val;
		
		if(column == 0)
			val = (int)s.rowid;
		else if(column == 1) {
			if(lm.media_info.media != null && lm.media_info.media.rowid == s.rowid)
				val = playing_icon;
			else if(s.unique_status_image != null)
				val = s.unique_status_image;
			else
				val = Value(typeof(GLib.Icon));
		}
		else if(column == 2)
			val = s.album_artist;
		else if(column == 3)
			val = s.genre;
		else if(column == 4)
			val = (int)s.rating;
		else// if(column == 5)
			val = (int)s.pulseProgress;
		
		return val;
	}
}

