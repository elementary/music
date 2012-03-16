/*-
 * Copyright (c) 2012 Lucas Baudin <xapantu@gmail.com>
 *
 * Originally Written by Lucas Baudin for BeatBox Music Player
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

/* This file contains the default music list view */

public abstract class BeatBox.BaseListView : ContentView, ScrolledWindow {
	public BeatBox.LibraryManager lm;
	public BeatBox.LibraryWindow lw;

	public ViewWrapper view_wrapper;

	public bool has_grid_lines {
		get {
			return view.enable_grid_lines == TreeViewGridLines.HORIZONTAL;
		}
		set {
			view.set_grid_lines (value? TreeViewGridLines.HORIZONTAL : TreeViewGridLines.NONE);
		}
	}
	
	protected TreeView view;
	protected BaseTreeModel list_model;

	protected Collection<int> _show_next; // these are populated if necessary when user opens this view.
	//private Collection<int> _medias;
	protected Collection<int> _showing_medias;
	protected LinkedList<string> _columns;

	public bool is_current_view { get { return this.visible; } }



	/**
	 * @deprecated
	 **/
	protected int relative_id;// if playlist, smart playlist, etc.
	protected ViewWrapper.Hint hint; // playlist, queue, smart_playlist, etc. changes how it behaves.
	protected string sort_column;
	protected SortType sort_direction;
	protected bool removing_medias;

	protected bool dragging;

	protected LinkedList<string> timeout_search;//stops from doing useless search (timeout)
	protected string last_search;//stops from searching same thing multiple times
	protected bool showing_all; // stops from searching unnecesarilly when changing b/w 0 words and search ViewWrapper.Hint, etc.

	protected bool scrolled_recently;

	protected CellDataFunctionHelper cellHelper;
	protected RatingWidgetMenu rating_item;
	
	public BaseListView (ViewWrapper view_wrapper) {
		this.lm = view_wrapper.lm;
		this.lw = view_wrapper.lw;

		this.view_wrapper = view_wrapper;

		_showing_medias = new LinkedList<int>();
		_columns = new LinkedList<string>();
		cellHelper = new CellDataFunctionHelper((BeatBox.LibraryManager)lm);

		lm.medias_updated.connect(medias_updated);
		lm.media_played.connect(media_played);
		lm.playback_stopped.connect(playback_stopped);
		lm.current_cleared.connect(current_cleared);
	}

	public void set_id(int id) {
		relative_id = id;
	}
	
	public virtual void buildUI() {

		list_model.set_sort_column_id(_columns.index_of(sort_column), sort_direction);

		view.set_model(list_model);
		view.set_headers_clickable(true);
		view.set_headers_visible(get_hint() != ViewWrapper.Hint.ALBUM_LIST);
		view.set_fixed_height_mode(true);
		view.rules_hint = true;
		view.set_reorderable(false);

		view.row_activated.connect(viewDoubleClick);
	}
	

	void viewDoubleClick(TreePath path, TreeViewColumn column) {
		TreeIter item;

		// get db's rowid of row clicked
		list_model.get_iter(out item, path);
		Value id;
		list_model.get_value(item, 0, out id);

		set_as_current_list(id.get_int(), !is_current_view);

		// play the media
		lm.playMedia(id.get_int(), false);

		if(!lm.playing) {
			lw.playClicked();
		}
	}
	
	public virtual void current_cleared() {
		if(lm.media_info.media != null)
			list_model.updateMedia(lm.media_info.media.rowid, is_current_view);
	}

	public virtual void media_played(int id, int old) {
		if(old != -1) {
			list_model.updateMedia(old, is_current_view);
			list_model.turnOffPixbuf(old);
		}

		if(!scrolled_recently) {
			scrollToCurrent();
		}

		list_model.updateMedia(id, is_current_view);

		if(get_hint() == ViewWrapper.Hint.QUEUE) {
			_show_next = lm.queue();
			populate_view();
		}
	}

	void playback_stopped(int was_playing) {
		if(was_playing >= 1) {
			list_model.turnOffPixbuf(was_playing);
		}
	}

	public virtual void mediaRateMediaClicked() {
		TreeSelection selected = view.get_selection();
		selected.set_mode(SelectionMode.MULTIPLE);
		TreeModel l_model;

		var los = new LinkedList<Media>();
		int new_rating = rating_item.rating_value;
		foreach(TreePath path in selected.get_selected_rows(out l_model)) {
			TreeIter item;
			l_model.get_iter(out item, path);

			int id;
			l_model.get(item, 0, out id);
			Media s = lm.media_from_id(id);

			s.rating = new_rating;
			los.add(s);
		}

		lm.update_medias(los, false, true);
	}

	public void update_medias(Collection<int> medias) {
		medias_updated(medias);
	}
	
	protected void medias_updated(Collection<int> ids) {
		list_model.updateMedias(ids, is_current_view);
		//list_model.resort();

		//since a media may have changed location, reset current
		if(is_current_view && !lm.playing_queued_song()) {
			set_as_current_list(0, false);
		}
	}

	protected abstract void updateSensitivities ();

	/* interface functions */

	public void set_hint(ViewWrapper.Hint the_hint) {
		hint = the_hint;
		updateSensitivities();
	}

	public ViewWrapper.Hint get_hint() {
		return hint;
	}

	public void set_relative_id(int id) {
		relative_id = id;
	}

	public int get_relative_id() {
		return relative_id;
	}

	public void set_show_next(Collection<int> medias) {
		_show_next = medias;
	}

	public Collection<int> get_medias() {
		return list_model.getOrderedMedias();
	}
	
	public void set_as_current_list(int media_id, bool is_initial = false) {
		var ordered_songs = list_model.getOrderedMedias();
		debug("there are %d ordered songs\n", ordered_songs.size);

		bool shuffle = (lm.shuffle == LibraryManager.Shuffle.ALL);

		lm.clearCurrent();
		int i = 0;
		lm.current_index = 0;
		foreach(int id in ordered_songs) {
			lm.addToCurrent(id);

			if(!shuffle && lm.media_info.media != null && lm.media_info.media.rowid == id && media_id == 0)
				lm.current_index = i;
			else if(!shuffle && lm.media_info.media != null && media_id == id)
				lm.current_index = i;

			++i;
		}

		if(lm.media_info.media != null)
			list_model.updateMedia(lm.media_info.media.rowid, is_current_view);
		debug("current list is %d and index %d\n", lm.current_medias().size, lm.current_index);
		lm.setShuffleMode(lm.shuffle, shuffle && is_initial);
	}

	public void append_medias(Collection<int> new_medias) {
		var all_medias = new LinkedList<int>();
		all_medias.add_all(_showing_medias);
		all_medias.add_all(new_medias);
		_showing_medias = all_medias;

		list_model.append_medias(new_medias, true);
		list_model.resort();
		if(visible)	queue_draw();
	}

	public void remove_medias(Collection<int> to_remove) {
		var all_medias = new LinkedList<int>();
		all_medias.add_all(_showing_medias);
		all_medias.remove_all(to_remove);
		_showing_medias = all_medias;

		list_model.removeMedias(to_remove);
		if(visible)	queue_draw();
	}

	public void set_statusbar_info() {
		view_wrapper.set_statusbar_info ();
	}

	public LinkedList<TreeViewColumn> get_columns() {
		var rv = new LinkedList<TreeViewColumn>();

		foreach(TreeViewColumn tvc in view.get_columns())
			rv.add(tvc);

		return rv;
	}

	public LinkedList<string> get_column_strings() {
		var rv = new LinkedList<string>();

		foreach(TreeViewColumn tvc in view.get_columns())
			rv.add(tvc.title);

		return rv;
	}

	/* music tree view specific functions */
	public Collection<int> get_showing_medias() {
		return list_model.getOrderedMedias();
	}

	public void populate_view() {
		/** NOTE: This could have a bad effect if user coincidentally
		 * searches for something that has same number of results as
		 * a different search. However, this cuts lots of unecessary
		 * loading of lists/icon lists */
		/*if(lw.searchField.get_text() == "" && _showing_medias.size == medias.size && ViewWrapper.Hint != ViewWrapper.Hint.HISTORY && ViewWrapper.Hint != ViewWrapper.Hint.QUEUE && !force) {
			return;
		}*/
		if(_show_next == _showing_medias)
			return;

		_showing_medias = _show_next;

		view.freeze_child_notify();
		view.set_model(null);

		int sort_col;
		SortType sort_dir;
		list_model.get_sort_column_id(out sort_col, out sort_dir);

		if (this is RadioListView)
			list_model = new RadioTreeModel(this, get_column_strings());
		else if (this is PodcastListView)
			list_model = new PodcastTreeModel(this, get_column_strings(), view);
		else if (this is MusicTreeView)
			list_model = new MusicTreeModel(this, get_column_strings(), get_hint ());

		list_model.append_medias(_showing_medias, false);

		list_model.set_sort_column_id(sort_col, sort_dir);

		if(lm.media_info.media != null)
			list_model.updateMedia(lm.media_info.media.rowid, is_current_view);
		view.set_model(list_model);
		view.thaw_child_notify();

		if(is_current_view && lm.media_info.media != null)
			scrollToCurrent();
	}

	public virtual void viewScroll() {
		if(!scrolled_recently && is_current_view) {
			Timeout.add(30000, () => {
				scrolled_recently = false;

				return false;
			});

			scrolled_recently = true;
		}
	}

	public void scrollToCurrent() {
		if(!is_current_view || lm.media_info.media == null)
			return;

		TreeIter iter;
		for(int i = 0; list_model.get_iter_from_string(out iter, i.to_string()); ++i) {
			Value id;
			list_model.get_value(iter, 0, out id);

			if(view is TreeView && id.get_int() == lm.media_info.media.rowid) {
				view.scroll_to_cell(new TreePath.from_string(i.to_string()), null, false, 0.0f, 0.0f);
				scrolled_recently = false;

				return;
			}
		}

		scrolled_recently = false;
	}

	public virtual void onDragBegin(Gtk.Widget sender, Gdk.DragContext context) {
		dragging = true;
		lw.dragging_from_music = true;
		debug("drag begin\n");

		Gdk.drag_abort(context, Gtk.get_current_event_time());

		if(view.get_selection().count_selected_rows() == 1) {
			drag_source_set_icon_stock(this, Gtk.Stock.DND);
		}
		else if(view.get_selection().count_selected_rows() > 1) {
			drag_source_set_icon_stock(this, Gtk.Stock.DND_MULTIPLE);
		}
		else {
			return;
		}
	}
	
	public virtual void onDragEnd(Gtk.Widget sender, Gdk.DragContext context) {
		dragging = false;
		lw.dragging_from_music = false;

		debug("drag end\n");

		//unset_rows_drag_dest();
		Gtk.drag_dest_set(this,
						  Gtk.DestDefaults.ALL,
						  {},
						  Gdk.DragAction.COPY|
						  Gdk.DragAction.MOVE
						  );
	}
}
