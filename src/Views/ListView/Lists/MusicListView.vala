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
	
	/**
	 * for sort_id use 0+ for normal, -1 for auto, -2 for none
	 */
	public MusicListView (ViewWrapper view_wrapper, TreeViewSetup tvs) {
		base (view_wrapper, tvs);

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
        mediaActionMenu.attach_to_widget (this, null);

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


	public override bool button_press_event (Gdk.EventButton event) {
        base.button_press_event (event);

        if (event.window != get_bin_window ())
            return false;

		if(event.button == 3) { //right click
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

			return false;
		}

		if(event.button == 1) {
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
		if (tvs == null || get_hint () == ViewWrapper.Hint.ALBUM_LIST)
			return;

		int sort_id;
		SortType sort_dir;
		get_sort_column_id(out sort_id, out sort_dir);

		if (sort_id < 0)
			sort_id = ListColumn.ARTIST;

		tvs.set_columns (get_columns ());
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
		if(to_edit.size == 1 && !File.new_for_uri(lm.media_from_id(id).uri).query_exists() && lm.media_from_id(id).uri.has_prefix(music_folder_uri)) {
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
			catch(Error err) {
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

	protected override void mediaRemoveClicked() {
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

    /**
     * Compares the two given objects based on the sort column.
     *
     * Objects are assumed to represent Media.
     */
	protected int view_compare_func (int column, Gtk.SortType dir, Object a, Object b, int a_pos, int b_pos) {
        int order = 0;

        return_val_if_fail (column >= 0 && column < ListColumn.N_COLUMNS, order);

		var media_a = a as Media;
		var media_b = b as Media;

        return_val_if_fail (media_a != null && media_b != null, order);

        switch (column) {
            case ListColumn.NUMBER: // We assume there are no two indentical numbers for this case
                order = a_pos - b_pos;
            break;

            case ListColumn.TITLE:
                order = compare_titles (media_a, media_b);
            break;

            case ListColumn.LENGTH:
                order = Numeric.compare (media_a.length, media_b.length);
                if (order == 0)
                    compare_titles (media_a, media_b);
            break;

            case ListColumn.ARTIST:
                order = compare_artists (media_a, media_b);
            break;

            case ListColumn.ALBUM:
                order = compare_albums (media_a, media_b);
            break;

            // Typically, when users choose to sort their media collection by track numbers,
            // what they actually want is ordering their albums, which means that this is
            // equivalent to sorting by genre.
            case ListColumn.TRACK:
            case ListColumn.GENRE:
                order = compare_genres (media_a, media_b);
            break;

            case ListColumn.YEAR:
                order = Numeric.compare (media_a.year, media_b.year);
            break;

            case ListColumn.BITRATE:
                order = Numeric.compare (media_a.bitrate, media_b.bitrate);
            break;

            case ListColumn.RATING:
                order = Numeric.compare (media_a.rating, media_b.rating);
            break;

		    case ListColumn.PLAY_COUNT:
                order = Numeric.compare (media_a.play_count, media_b.play_count);
            break;

		    case ListColumn.SKIP_COUNT:
                order = Numeric.compare (media_a.skip_count, media_b.skip_count);
            break;

		    case ListColumn.DATE_ADDED:
                order = Numeric.compare (media_a.date_added, media_b.date_added);
            break;

		    case ListColumn.LAST_PLAYED:
                order = Numeric.compare (media_a.last_played, media_b.last_played);
            break;

		    case ListColumn.BPM:
                order = Numeric.compare (media_a.bpm, media_b.bpm);
            break;
        }

        // When order is zero, we'd like to jump into sorting by genre, but that'd
        // be a performance killer. Let's compare titles and that's it.
        if (order == 0 && column != ListColumn.GENRE && column != ListColumn.ARTIST)
            order = compare_titles (media_a, media_b);

        // If still 0, fall back to comparing URIS
		if (order == 0)
			order = String.compare (media_a.uri, media_b.uri);

        // Invert order if ordering is descending
		if (dir == SortType.DESCENDING && order != 0)
			order = (order > 0) ? -1 : 1;

		return order;

	}

    private inline int compare_titles (Media a, Media b) {
        return String.compare (a.get_display_title (), b.get_display_title ());
    }

    private inline int compare_genres (Media a, Media b) {
        int order = String.compare (a.get_display_genre (), b.get_display_genre ());
        if (order == 0)
            order = compare_artists (a, b);
        return order;
    }

    private inline int compare_artists (Media a, Media b) {
        int order = String.compare (a.get_display_artist (), b.get_display_artist ());
        if (order == 0)
            order = compare_albums (a, b);
        return order;
    }

    private inline int compare_albums (Media a, Media b) {
        int order = String.compare (a.get_display_album (), b.get_display_album ());
        if (order == 0)
            order = Numeric.compare (a.album_number, b.album_number);
        if (order == 0)
            order = compare_track_numbers (a, b);
        return order;
    }

    private inline int compare_track_numbers (Media a, Media b) {
        return Numeric.compare (a.track, b.track);
    }

	protected Value? view_value_func (int row, int column, Object o) {
		var s = o as Media;
        return_val_if_fail (s != null, null);

        switch (column) {
		    case ListColumn.ICON:
                GLib.Icon? icon;
                var currently_playing = App.player.media_info.media;

			    if (s == currently_playing && currently_playing != null)
				    icon = Icons.NOW_PLAYING_SYMBOLIC.gicon;
			    else if (tvs.get_hint () == ViewWrapper.Hint.CDROM && !s.isTemporary)
				    icon = Icons.PROCESS_COMPLETED.gicon;
                else
				    icon = s.unique_status_image;

                return icon;

		    case ListColumn.NUMBER:
			    return (uint) row + 1;

		    case ListColumn.TRACK:
			    return s.track;

		    case ListColumn.TITLE:
			    return s.get_display_title ();

		    case ListColumn.LENGTH:
			    return s.length;

		    case ListColumn.ARTIST:
			    return s.get_display_artist ();

		    case ListColumn.ALBUM:
			    return s.get_display_album ();

		    case ListColumn.GENRE:
			    return s.get_display_genre ();

		    case ListColumn.YEAR:
			    return s.year;

		    case ListColumn.BITRATE:
			    return s.bitrate;

		    case ListColumn.RATING:
			    return s.rating;

		    case ListColumn.PLAY_COUNT:
			    return s.play_count;

		    case ListColumn.SKIP_COUNT:
			    return s.skip_count;

		    case ListColumn.DATE_ADDED:
			    return s.date_added;

		    case ListColumn.LAST_PLAYED:
			    return s.last_played;

		    case ListColumn.BPM:
			    return s.bpm;
        }

		assert_not_reached ();
	}

    protected override void add_column (Gtk.TreeViewColumn tvc, ListColumn type) {
        tvc.sizing = Gtk.TreeViewColumnSizing.FIXED;

        bool column_resizable = true;
        bool column_reorderable = true;
        int column_width = -1;
        int insert_index = -1; // leave at -1 for appending
        var test_strings = new string[0];

        Gtk.CellRenderer? renderer = null;

        switch (type) {
            case ListColumn.ICON:
                // Force the column to stay at initial position instead of simply appending it
                insert_index = type;

                column_reorderable = false;
                column_resizable = false;

                var icon_renderer = new Gtk.CellRendererPixbuf ();
                icon_renderer.follow_state = true;

                var spinner_renderer = new Gtk.CellRendererSpinner ();

                icon_renderer.stock_size = spinner_renderer.size = Gtk.IconSize.MENU;

                int width, height;
                Gtk.icon_size_lookup ((Gtk.IconSize) icon_renderer.stock_size, out width, out height);
                column_width = int.max (width, height) + 7;

                tvc.set_cell_data_func (icon_renderer, cell_data_helper.icon_func);
                tvc.set_cell_data_func (spinner_renderer, cell_data_helper.icon_func);

                // Pack spinner cell because only @renderer will be packed automatically
                tvc.pack_start (spinner_renderer, true);

                // We only consider icon renderer for sizing purposes
                renderer = icon_renderer;
            break;

            case ListColumn.BITRATE:
                renderer = new Gtk.CellRendererText ();
                tvc.set_cell_data_func (renderer, CellDataFunctionHelper.bitrate_func);
                column_resizable = false;
                test_strings += _ ("1234 kbps");
            break;

            case ListColumn.LENGTH:
                renderer = new Gtk.CellRendererText ();
                tvc.set_cell_data_func (renderer, CellDataFunctionHelper.length_func);
                column_resizable = false;
                test_strings += "0000:00";
            break;

            case ListColumn.DATE_ADDED:
                renderer = new Gtk.CellRendererText ();
                tvc.set_cell_data_func (renderer, CellDataFunctionHelper.date_func);
                test_strings += CellDataFunctionHelper.get_date_func_sample_string ();
                test_strings += _ ("Never");
            break;

            case ListColumn.LAST_PLAYED:
                renderer = new Gtk.CellRendererText ();
                tvc.set_cell_data_func (renderer, CellDataFunctionHelper.date_func);
                test_strings += CellDataFunctionHelper.get_date_func_sample_string ();
                test_strings += _ ("Never");
            break;

            case ListColumn.RATING:
                var rating_renderer = new Granite.Widgets.CellRendererRating ();
                rating_renderer.rating_changed.connect (on_rating_cell_changed);

                renderer = rating_renderer;
                tvc.set_cell_data_func (rating_renderer, CellDataFunctionHelper.rating_func);

                column_resizable = false;
                column_width = rating_renderer.width + 5;
            break;

            case ListColumn.YEAR:
                renderer = new Gtk.CellRendererText ();
                tvc.set_cell_data_func (renderer, CellDataFunctionHelper.intelligent_func);
                column_resizable = false;
                test_strings += "0000";
            break;

            case ListColumn.NUMBER:
                var text_renderer = new Gtk.CellRendererText ();
                text_renderer.style = Pango.Style.ITALIC;
                renderer = text_renderer;
                tvc.set_cell_data_func (renderer, CellDataFunctionHelper.number_func);
                column_resizable = false;
                test_strings += "00000";
            break;

            case ListColumn.TRACK:
                renderer = new Gtk.CellRendererText ();
                tvc.set_cell_data_func (renderer, CellDataFunctionHelper.intelligent_func);
                column_resizable = false;
                test_strings += "000";
            break;

            case ListColumn.PLAY_COUNT:
                renderer = new Gtk.CellRendererText ();
                tvc.set_cell_data_func (renderer, CellDataFunctionHelper.intelligent_func);
                column_resizable = false;
                test_strings += "9999";
            break;

            case ListColumn.SKIP_COUNT:
                renderer = new Gtk.CellRendererText ();
                tvc.set_cell_data_func (renderer, CellDataFunctionHelper.intelligent_func);
                column_resizable = false;
                test_strings += "9999";
            break;

            case ListColumn.TITLE:
                renderer = new Gtk.CellRendererText ();
                tvc.set_cell_data_func (renderer, CellDataFunctionHelper.string_func);

                /// Sample string used to measure the desired size of the Title column in the list view.
                /// Should be as long as a common song title in your language.
                test_strings += _ ("Sample Title");
            break;

            case ListColumn.ARTIST:
                renderer = new Gtk.CellRendererText ();
                tvc.set_cell_data_func (renderer, CellDataFunctionHelper.string_func);

                /// Sample string used to measure the desired size of the Artist column in the list view.
                /// Should be as long as a common artist name in your language.
                test_strings += _ ("Sample Artist");
            break;

            case ListColumn.ALBUM:
                /// Sample string used to measure the desired size of the Album column in the list view.
                /// Should be as long as a common album name in your language.
                test_strings += _ ("Sample Album");
#if HAVE_SMART_ALBUM_COLUMN
                renderer = new SmartAlbumRenderer ();
                tvc.set_cell_data_func (renderer, cell_data_helper.album_art_func);
                // XXX set_row_separator_func (cell_data_helper.row_separator_func);
#else
                renderer = new Gtk.CellRendererText ();
                tvc.set_cell_data_func (renderer, CellDataFunctionHelper.string_func);
#endif
            break;

            case ListColumn.GENRE:
                renderer = new Gtk.CellRendererText ();
                tvc.set_cell_data_func (renderer, CellDataFunctionHelper.string_func);

                /// Sample string used to measure the desired size of the Genre column in the list view.
                /// Should be as long as a common genre name in your language.
                test_strings += _ ("Sample Genre");
            break;

            case ListColumn.BPM:
                renderer = new Gtk.CellRendererText ();
                tvc.set_cell_data_func (renderer, CellDataFunctionHelper.intelligent_func);
                column_resizable = false;
                test_strings += "9999";
            break;

            default:
                assert_not_reached ();
        }

        tvc.pack_start (renderer, true);

        // Now insert the column
        insert_column (tvc, insert_index);

        if (column_width > 0) {
            tvc.fixed_width = column_width;
        } else if (renderer != null) {
            var text_renderer = renderer as Gtk.CellRendererText;
            if (text_renderer != null)
                set_fixed_column_width (this, tvc, text_renderer, test_strings, 5);
        }

        tvc.reorderable = false;
        tvc.clickable = true;

        tvc.resizable = column_resizable;
        tvc.expand = column_resizable;

        bool sortable = type != ListColumn.NUMBER && type != ListColumn.ICON;

        // This is vital. All the methods in CellDataFunctionHelper rely
        // on this for retrieving the right column values from the cell-data
        // functions. For that reason, it **must** use the same index as
        // the column it corresponds to, unless it's not sortable.
        tvc.sort_column_id = sortable ? (int) type : -1;
        tvc.sort_indicator = sortable;

        var header_button = tvc.get_button ();

        // Make sure the title text is always fully displayed when the headers are visible
        if (headers_visible) {
            Gtk.Requisition natural_size;
            header_button.get_preferred_size (null, out natural_size);

            if (natural_size.width > tvc.fixed_width)
                tvc.fixed_width = natural_size.width;

            // Add extra width for the order indicator arrows
            if (tvc.sort_indicator)
                tvc.fixed_width += 5; // roughly estimated arrow width
        }

        tvc.min_width = tvc.fixed_width;

        // This is probably the best place to disable the columns we don't want
        // for especific views, like the CD view. FIXME: we need to properly abstract this
        // and keep this class GENERIC rather than SHARED. This should be done in a subclass,
        // like CDRomList
        if (get_hint () == ViewWrapper.Hint.CDROM) {
            if (type != ListColumn.ICON &&
                type != ListColumn.NUMBER &&
                type != ListColumn.TRACK &&
                type != ListColumn.TITLE &&
                type != ListColumn.LENGTH &&
                type != ListColumn.ALBUM &&
                type != ListColumn.ARTIST)
            {
                // hide the column and don't add a menuitem
                tvc.visible = false;
            }
            else {
                tvc.visible = type != ListColumn.NUMBER;
                // Add menuitem
                add_column_chooser_menu_item (tvc, type);
            }
        }
        else {
            // Add menuitem
            add_column_chooser_menu_item (tvc, type);
        }

        if (type == ListColumn.ICON) {
            header_button.button_press_event.connect ((e) => {
                return view_header_click (e, true);
            });
        } else {
            header_button.button_press_event.connect ((e) => {
                return view_header_click (e, false);
            });
        }
    }
}

