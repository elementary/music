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

public class Noise.MusicListView : GenericList {

	//for media list right click
	Gtk.Menu mediaActionMenu;
	Gtk.MenuItem mediaEditMedia;
	Gtk.MenuItem mediaFileBrowse;
	Gtk.MenuItem mediaMenuQueue;
	Gtk.MenuItem mediaMenuNewPlaylist;
	Gtk.MenuItem mediaMenuAddToPlaylist; // make menu on fly
	Granite.Widgets.RatingMenuItem mediaRateMedia;
	Gtk.MenuItem mediaRemove;
	Gtk.MenuItem importToLibrary;
	Gtk.MenuItem mediaScrollToCurrent;
	
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
	public MusicListView (ViewWrapper view_wrapper, TreeViewSetup tvs) {
		// FIXME: re-do. Associate a type to each column directly in TreeViewSetup
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

		// This is vital
		set_value_func (view_value_func);
		set_compare_func (view_compare_func);
		
		build_ui();
	}

	public override void update_sensitivities() {
		mediaActionMenu.show_all();

		if(get_hint() == ViewWrapper.Hint.MUSIC) {
			mediaRemove.set_label(_("Remove from Library"));
			importToLibrary.set_visible(false);
		}
		else if(get_hint() == ViewWrapper.Hint.SIMILAR) {
			mediaRemove.set_visible(false);
			importToLibrary.set_visible(false);
		}
		else if(get_hint() == ViewWrapper.Hint.QUEUE) {
			mediaRemove.set_label(_("Remove from Queue"));
			mediaMenuQueue.set_visible(false);
			importToLibrary.set_visible(false);
		}
		else if(get_hint() == ViewWrapper.Hint.HISTORY) {
			mediaRemove.set_visible(false);
			importToLibrary.set_visible(false);
		}
		else if(get_hint() == ViewWrapper.Hint.PLAYLIST) {
			importToLibrary.set_visible(false);
		}
		else if(get_hint() == ViewWrapper.Hint.SMART_PLAYLIST) {
			mediaRemove.set_visible(false);
			importToLibrary.set_visible(false);
		}
		else if(get_hint() == ViewWrapper.Hint.DEVICE_AUDIO) {
			mediaEditMedia.set_visible(false);
			mediaRemove.set_label(_("Remove from Device"));
			mediaMenuQueue.set_visible(false);
			mediaMenuAddToPlaylist.set_visible(false);
			mediaMenuNewPlaylist.set_visible(false);
		}
		else if(get_hint() == ViewWrapper.Hint.CDROM) {
			mediaEditMedia.set_visible(false);
			mediaRateMedia.set_visible(false);
			mediaRemove.set_visible(false);
			mediaMenuAddToPlaylist.set_visible(false);
			mediaMenuNewPlaylist.set_visible(false);
		}
		else {
			mediaRemove.set_visible(false);
			importToLibrary.set_visible(false);
		}
	}

	public void build_ui () {
		add_columns ();

		button_press_event.connect(viewClick);
		button_release_event.connect(viewClickRelease);

		mediaScrollToCurrent = new Gtk.MenuItem.with_label(_("Scroll to Current Song"));
		mediaEditMedia = new Gtk.MenuItem.with_label(_("Edit Song Info"));
		mediaFileBrowse = new Gtk.MenuItem.with_label(_("Show in File Browser"));
		mediaMenuQueue = new Gtk.MenuItem.with_label(_("Queue"));
		mediaMenuNewPlaylist = new Gtk.MenuItem.with_label(_("New Playlist"));
		mediaMenuAddToPlaylist = new Gtk.MenuItem.with_label(_("Add to Playlist"));
		mediaRemove = new Gtk.MenuItem.with_label(_("Remove Song"));
		importToLibrary = new Gtk.MenuItem.with_label(_("Import to Library"));
		mediaRateMedia = new Granite.Widgets.RatingMenuItem ();

		mediaActionMenu = new Gtk.Menu ();

		var hint = tvs.get_hint ();

		if(hint != ViewWrapper.Hint.CDROM && hint != ViewWrapper.Hint.ALBUM_LIST) {
			//mediaActionMenu.append(browseSame);
			mediaActionMenu.append(mediaScrollToCurrent);
		}

		mediaActionMenu.append(mediaEditMedia);
		mediaActionMenu.append(mediaFileBrowse);
		mediaActionMenu.append(mediaRateMedia);
		mediaActionMenu.append(new SeparatorMenuItem());
		mediaActionMenu.append(mediaMenuQueue);
		mediaActionMenu.append(mediaMenuNewPlaylist);
		mediaActionMenu.append(mediaMenuAddToPlaylist);

		if (hint != ViewWrapper.Hint.SMART_PLAYLIST && hint != ViewWrapper.Hint.ALBUM_LIST && hint != hint.HISTORY)
			mediaActionMenu.append (new SeparatorMenuItem());

		mediaActionMenu.append(mediaRemove);
		mediaActionMenu.append(importToLibrary);

		mediaEditMedia.activate.connect(mediaMenuEditClicked);
		mediaFileBrowse.activate.connect(mediaFileBrowseClicked);
		mediaMenuQueue.activate.connect(mediaMenuQueueClicked);
		mediaMenuNewPlaylist.activate.connect(mediaMenuNewPlaylistClicked);
		mediaRemove.activate.connect(mediaRemoveClicked);
		importToLibrary.activate.connect(importToLibraryClicked);
		mediaRateMedia.activate.connect(mediaRateMediaClicked);
		mediaScrollToCurrent.activate.connect(mediaScrollToCurrentRequested);
		
		set_headers_visible (hint != ViewWrapper.Hint.ALBUM_LIST);
		
		update_sensitivities ();		
	}

#if 0
	private void rearrangeColumns(LinkedList<string> correctOrder) {
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
#endif


	/* button_press_event */
	bool viewClick(Gdk.EventButton event) {
		if(event.type == Gdk.EventType.BUTTON_PRESS && event.button == 3) { //right click
			/* create add to playlist menu */
			Gtk.Menu addToPlaylistMenu = new Gtk.Menu();
			foreach(Playlist p in lm.playlists()) {
				Gtk.MenuItem playlist = new Gtk.MenuItem.with_label(p.name);
				addToPlaylistMenu.append(playlist);

				playlist.activate.connect( () => {
					var to_add = new LinkedList<Media>();
					
					foreach(Media m in get_selected_medias()) {
						to_add.add (m);
					}
					p.add_media(to_add);
				});
			}

			addToPlaylistMenu.show_all();
			mediaMenuAddToPlaylist.submenu = addToPlaylistMenu;

			if(lm.playlists().size == 0)
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
					importToLibrary.label = _("Import %i of %i selected songs").printf ((int)temporary_count, (int)total_count);
				else if (temporary_count == 1)
					importToLibrary.label = _("Import this song");
				else
					importToLibrary.label = _("Import %i songs").printf ((int)temporary_count);
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
			mediaActionMenu.popup (null, null, null, 3, get_current_event_time());

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

	protected override void updateTreeViewSetup() {
		if(tvs == null || get_hint() == ViewWrapper.Hint.ALBUM_LIST || get_columns().length() != TreeViewSetup.MUSIC_COLUMN_COUNT)
			return;

		int sort_id = MusicColumn.ARTIST;
		SortType sort_dir = Gtk.SortType.ASCENDING;
		get_sort_column_id(out sort_id, out sort_dir);

		if(sort_id < 0)
			sort_id = MusicColumn.ARTIST;
		
		tvs.set_columns(get_columns());
		tvs.sort_column_id = sort_id;
		tvs.sort_direction = sort_dir;
	}

	/** media menu popup clicks **/
	void mediaMenuEditClicked() {
		var to_edit = new LinkedList<int>();
		var to_edit_med = new LinkedList<Media>();
		
		foreach(Media m in get_selected_medias()) {
			to_edit.add(m.rowid);
			if(to_edit.size == 1)
				to_edit_med.add(m);
		}
		
		if(to_edit.size == 0)
			return;
		
		int id = to_edit.get(0);
		string music_folder_uri = File.new_for_path(Settings.Main.instance.music_folder).get_uri();
		if(to_edit.size == 1 && !GLib.File.new_for_uri(lm.media_from_id(id).uri).query_exists() && lm.media_from_id(id).uri.has_prefix(music_folder_uri)) {
			lm.media_from_id(id).unique_status_image = Icons.PROCESS_ERROR.render(IconSize.MENU, ((ViewWrapper)lw.sideTree.getWidget(lw.sideTree.library_music_iter)).list_view.get_style_context());
			FileNotFoundDialog fnfd = new FileNotFoundDialog(lm, lm.lw, to_edit_med);
			fnfd.present();
		}
		else {
			var list = new LinkedList<int>();
			for(int i = 0; i < get_visible_table().size(); ++i) {
				list.add ((get_object_from_index(i) as Media).rowid);
			}
			MediaEditor se = new MediaEditor(lm, list, to_edit);
			se.medias_saved.connect(mediaEditorSaved);
		}
	}

	protected virtual void mediaEditorSaved(LinkedList<int> medias) {
		LinkedList<Media> toUpdate = new LinkedList<Media>();
		foreach(int i in medias)
			toUpdate.add(lm.media_from_id(i));

		// could have edited rating, so record_time is true
		lm.update_media (toUpdate, true, true);

		if(get_hint() == ViewWrapper.Hint.SMART_PLAYLIST) {
			// make sure these medias still belongs here
		}
	}

	protected void mediaFileBrowseClicked() {
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

	protected virtual void mediaMenuQueueClicked() {
		var to_queue = new Gee.LinkedList<Media> ();

		foreach (Media m in get_selected_medias ()) {
			to_queue.add (m);
		}

		App.player.queue_media (to_queue);
	}

	protected virtual void mediaMenuNewPlaylistClicked() {
		Playlist p = new Playlist();
		
		var to_add = new Gee.LinkedList<Media> ();
		foreach (Media m in get_selected_medias ()) {
			to_add.add (m);
		}
		p.add_media (to_add);

		PlaylistNameWindow pnw = new PlaylistNameWindow (lw, p);
		pnw.playlist_saved.connect( (newP) => {
			lm.add_playlist(p);
			lw.addSideListItem(p);
		});
	}
	
	protected void mediaRateMediaClicked() {
		var los = new LinkedList<Media>();
		int new_rating = mediaRateMedia.rating_value;
		
		foreach(Media m in get_selected_medias()) {
			m.rating = new_rating;
			los.add(m);
		}
		lm.update_media (los, false, true);
	}

	protected virtual void mediaRemoveClicked() {
		var to_remove = new Gee.LinkedList<Media>();
		
		foreach (Media m in get_selected_medias()) {
			to_remove.add (m);
		}

		if (get_hint() == ViewWrapper.Hint.QUEUE) {
			App.player.unqueue_media (to_remove);
		}

		if (get_hint() == ViewWrapper.Hint.MUSIC) {
			var dialog = new RemoveFilesDialog (lm.lw, to_remove, get_hint());
			dialog.remove_media.connect ( (delete_files) => {
				lm.remove_media (to_remove, delete_files);
			});
		}
		else if(get_hint() == ViewWrapper.Hint.DEVICE_AUDIO) {
			DeviceViewWrapper dvw = (DeviceViewWrapper)parent_wrapper;
			dvw.d.remove_medias(to_remove);
		}
		
		if(get_hint() == ViewWrapper.Hint.PLAYLIST) {
			lm.playlist_from_id(relative_id).remove_media (to_remove);
		}
	}

	void importToLibraryClicked() {
		var to_import = new Gee.LinkedList<Media>();
		
		foreach(Media m in get_selected_medias()) {
			to_import.add (m);
		}

		import_requested (to_import);
	}

	protected virtual void onDragDataGet(Gdk.DragContext context, Gtk.SelectionData selection_data, uint info, uint time_) {
		string[] uris = null;

		foreach(Media m in get_selected_medias()) {
			debug("adding %s\n", m.uri);
			uris += (m.uri);
		}

		if (uris != null)
			selection_data.set_uris(uris);
	}

	protected void apply_style_to_view(CssProvider style) {
		get_style_context().add_provider(style, STYLE_PROVIDER_PRIORITY_APPLICATION);
	}
	
	protected int view_compare_func (int col, Gtk.SortType dir, Object a, Object b) {
		int rv = 0;
		
		var a_media = a as Media;
		var b_media = b as Media;
		
		if(col == MusicColumn.NUMBER) {
			rv = 1;//a.get_position() - b.get_position();
		}
		else if(col == MusicColumn.TRACK) {
			rv = (int)(a_media.track - b_media.track);
		}
		else if(col == MusicColumn.TITLE) {
			rv = String.compare (a_media.title.down(), b_media.title.down());
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
					rv = String.compare (a_media.album.down(), b_media.album.down());
			}
			else
				rv = String.compare (a_media.album_artist.down(), b_media.album_artist.down());
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
					rv = String.compare (a_media.album.down(), b_media.album.down());
			}
		}
		else if(col == MusicColumn.GENRE) {
			rv = String.compare (a_media.genre.down(), b_media.genre.down());
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
			rv = String.compare (a_media.uri, b_media.uri);

		if(sort_direction == SortType.DESCENDING)
			rv = (rv > 0) ? -1 : 1;

		return rv;
	}
	
	protected Value view_value_func (int row, int column, Object o) {
		Value val;
		var s = o as Media;
		
		if(column == MusicColumn.ROWID)
			val = s.rowid;
		else if(column == MusicColumn.ICON) {
			if(App.player.media_info.media != null && App.player.media_info.media == s)
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

