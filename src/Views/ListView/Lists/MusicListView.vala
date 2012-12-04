// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012 Noise Developers (http://launchpad.net/noise)
 *
 * This software is licensed under the GNU General Public License
 * (version 2 or later). See the COPYING file in this distribution.
 *
 * The Noise authors hereby grant permission for non-GPL compatible
 * GStreamer plugins to be used and distributed together with GStreamer
 * and Noise. This permission is above and beyond the permissions granted
 * by the GPL license by which Noise is covered. If you modify this code
 * you may extend this exception to your version of the code, but you are not
 * obligated to do so. If you do not wish to do so, delete this exception
 * statement from your version.
 *
 * Authored by: Scott Ringwelski <sgringwe@mtu.edu>,
 *              Victor Eduardo <victoreduardm@gmail.com>,
 *              Corentin Noël <tintou@mailoo.org>
 */

using Gee;
using Gtk;

public class Noise.MusicListView : GenericList {

    //for media list right click
    Gtk.Menu mediaActionMenu;
    Gtk.MenuItem mediaEditMedia;
    Gtk.MenuItem mediaFileBrowse;
    Gtk.MenuItem mediaTopSeparator;
    Gtk.MenuItem mediaMenuQueue;
    Gtk.MenuItem mediaMenuNewPlaylist;
    Gtk.MenuItem mediaMenuAddToPlaylist; // make menu on fly
    Granite.Widgets.RatingMenuItem mediaRateMedia;
    Gtk.MenuItem mediaRemove;
    Gtk.MenuItem importToLibrary;
    Gtk.MenuItem mediaScrollToCurrent;
    bool is_queue = false;

    /**
     * for sort_id use 0+ for normal, -1 for auto, -2 for none
     */
    public MusicListView (ViewWrapper view_wrapper, TreeViewSetup tvs, bool? is_queue = false) {
        base (view_wrapper, tvs);
        this.is_queue = is_queue;

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
        else if(get_hint() == ViewWrapper.Hint.PLAYLIST) {
            importToLibrary.set_visible(false);
        }
        else if(get_hint() == ViewWrapper.Hint.READ_ONLY_PLAYLIST) {
            importToLibrary.set_visible(false);
            if (is_queue == true) {
                mediaRemove.set_label(_("Remove from Queue"));
                mediaMenuQueue.set_visible(false);
            } else {
                mediaRemove.set_visible(false);
            }
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
            mediaTopSeparator.set_visible(false);
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
        mediaMenuQueue = new Gtk.MenuItem.with_label(C_("Action item (verb)", "Queue"));
        mediaMenuNewPlaylist = new Gtk.MenuItem.with_label(_("New Playlist"));
        mediaMenuAddToPlaylist = new Gtk.MenuItem.with_label(_("Add to Playlist"));
        mediaRemove = new Gtk.MenuItem.with_label(_("Remove Song"));
        importToLibrary = new Gtk.MenuItem.with_label(_("Import to Library"));
        mediaRateMedia = new Granite.Widgets.RatingMenuItem ();

        mediaActionMenu = new Gtk.Menu ();
        mediaActionMenu.attach_to_widget (this, null);

        var hint = tvs.get_hint ();

        if(hint != ViewWrapper.Hint.ALBUM_LIST) {
            //mediaActionMenu.append(browseSame);
            mediaActionMenu.append(mediaScrollToCurrent);
        }

        mediaTopSeparator = new SeparatorMenuItem ();

        mediaActionMenu.append(mediaEditMedia);
        mediaActionMenu.append(mediaFileBrowse);
        mediaActionMenu.append(mediaRateMedia);
        mediaActionMenu.append(mediaTopSeparator);
        mediaActionMenu.append(mediaMenuQueue);
        mediaActionMenu.append(mediaMenuNewPlaylist);
        mediaActionMenu.append(mediaMenuAddToPlaylist);

        if (hint != ViewWrapper.Hint.SMART_PLAYLIST && hint != ViewWrapper.Hint.ALBUM_LIST) {
            if (hint == hint.READ_ONLY_PLAYLIST) {
                if (is_queue == true)
                    mediaActionMenu.append (new SeparatorMenuItem());
            } else {
                mediaActionMenu.append (new SeparatorMenuItem());
            }
        }

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
        if (event.window != get_bin_window ())
            return base.button_press_event (event);

        // Check whether we should let the default handler alter the selection or not.
        if (check_selection_event (event))
            base.button_press_event (event);

        if (event.button == Gdk.BUTTON_SECONDARY) {
            // Create add-to-playlist menu
            var addToPlaylistMenu = new Gtk.Menu ();

            foreach (var playlist in lm.playlists ()) {
                // Don't include this playlist in the list of available options
                if (playlist.rowid == this.get_relative_id ())
                    continue;
                    
                if (playlist.read_only == true)
                    continue;

                var playlist_item = new Gtk.MenuItem.with_label (playlist.name);
                addToPlaylistMenu.append (playlist_item);

                playlist_item.activate.connect (() => {
                    var to_add = new Gee.LinkedList<Media> ();
                    foreach (var m in get_selected_medias ())
                        to_add.add (m);
                    playlist.add_media (to_add);
                });
            }

            addToPlaylistMenu.show_all ();
            mediaMenuAddToPlaylist.submenu = addToPlaylistMenu;
            mediaMenuAddToPlaylist.set_sensitive (lm.playlist_count_without_read_only () > 0);

            // if all medias are downloaded already, desensitize.
            // if half and half, change text to 'Download %external of %total'
            int temporary_count = 0;
            int total_count = 0;
            foreach (var m in get_selected_medias ()) {
                if (m.isTemporary)
                    temporary_count++;
                total_count++;
            }

            if (temporary_count < 1) {
                importToLibrary.set_sensitive (false);
            } else {
                importToLibrary.set_sensitive (true);

                if (temporary_count != total_count)
                    importToLibrary.label = _("Import %i of %i selected songs").printf ((int)temporary_count, (int)total_count);
                else
                    importToLibrary.label = ngettext ("Import %i song", "Import %i songs", temporary_count).printf ((int)temporary_count);
            }

            int set_rating = -1;
            foreach (Media m in get_selected_medias ()) {
                if (set_rating == -1) {
                    set_rating = (int) m.rating;
                } else if (set_rating != m.rating) {
                    set_rating = 0;
                    break;
                }
            }

            mediaRateMedia.rating_value = set_rating;

            mediaActionMenu.popup (null, null, null, 3, get_current_event_time());

            return true;
        }

        return false;
    }

    /**
     * Checks whether a Gdk.EventButton resulting in a selection change should be sent
     * to the default handler or not. This is useful to prevent the default handler from
     * destroying the user's previous selection in case there was a multiple selection.
     *
     * @param event the Gdk.EventButton to check
     * @return //true// if the event should be passed to the default handler; false otherwise.
     */
    private bool check_selection_event (Gdk.EventButton event) requires (event.window == get_bin_window ()) {
        if (Utils.flags_set (event.state, Gdk.ModifierType.CONTROL_MASK)
         || Utils.flags_set (event.state, Gdk.ModifierType.SHIFT_MASK))
        {
            return true;
        }

        Gtk.TreePath path;
        Gtk.TreeViewColumn column;
        int cell_x, cell_y;

        if (get_path_at_pos ((int) event.x, (int) event.y, out path, out column, out cell_x, out cell_y)) {
            var selection = get_selection ();

            // If there's multiple selection and the future selected path is part of the
            // already-selected set of rows, return true to prevent the default (base) handler
            // from unselecting everyting.
            if (selection.count_selected_rows () > 1 && selection.path_is_selected (path))
                return false;
        }

        return true;
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
        string music_folder_uri = File.new_for_path(main_settings.music_folder).get_uri();
        if(to_edit.size == 1 && !File.new_for_uri(lm.media_from_id(id).uri).query_exists() && lm.media_from_id(id).uri.has_prefix(music_folder_uri)) {
            lm.media_from_id(id).unique_status_image = Icons.PROCESS_ERROR.render(IconSize.MENU);
            FileNotFoundDialog fnfd = new FileNotFoundDialog(lm, lm.lw, to_edit_med);
            fnfd.present();
        }
        else {
            var list = new LinkedList<int>();
            for(int i = 0; i < get_visible_table().size(); ++i) {
                list.add (get_object_from_index(i).rowid);
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
            lw.addSourceListItem(p);
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
            lm.playlist_from_id(relative_id).remove_medias (to_remove);
        }

        if(get_hint() == ViewWrapper.Hint.READ_ONLY_PLAYLIST && is_queue == true) {
            lm.playlist_from_id(relative_id).remove_medias (to_remove);
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
     */
    protected int view_compare_func (int column, Gtk.SortType dir, Media media_a, Media media_b, int a_pos, int b_pos) {
        int order = 0;
        return_val_if_fail (column >= 0 && column < ListColumn.N_COLUMNS, order);

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

            case ListColumn.ALBUM_ARTIST:
                order = String.compare (media_a.get_display_album_artist (false), media_b.get_display_album_artist (false));
            break;

            case ListColumn.COMPOSER:
                order = String.compare (media_a.get_display_composer (), media_b.get_display_composer ());
            break;

            case ListColumn.GROUPING:
                order = String.compare (media_a.grouping, media_b.grouping);
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

            case ListColumn.FILE_SIZE:
                order = Numeric.compare ((int64) media_a.file_size, (int64) media_b.file_size);
            break;

            case ListColumn.FILE_LOCATION:
                order = String.compare (media_a.get_display_location (), media_b.get_display_location ());
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
        var m = o as Media;
        return_val_if_fail (m != null, null);

        var list_column = (ListColumn) column;
        return list_column.get_value_for_media (m, row);
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
                tvc.set_cell_data_func (spinner_renderer, cell_data_helper.spinner_func);

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

            case ListColumn.NUMBER:
                var text_renderer = new Gtk.CellRendererText ();
                text_renderer.style = Pango.Style.ITALIC;
                renderer = text_renderer;
                tvc.set_cell_data_func (renderer, CellDataFunctionHelper.number_func);
                column_resizable = false;
                test_strings += "00000";
            break;

            case ListColumn.YEAR:
                renderer = new Gtk.CellRendererText ();
                tvc.set_cell_data_func (renderer, CellDataFunctionHelper.intelligent_func);
                column_resizable = false;
                test_strings += "0000";
            break;

            case ListColumn.TRACK:
            case ListColumn.PLAY_COUNT:
            case ListColumn.SKIP_COUNT:
                renderer = new Gtk.CellRendererText ();
                tvc.set_cell_data_func (renderer, CellDataFunctionHelper.intelligent_func);
                column_resizable = false;
                test_strings += "9999";
            break;

#if HAVE_SMART_ALBUM_COLUMN
            case ListColumn.ALBUM:
                renderer = new SmartAlbumRenderer ();
                tvc.set_cell_data_func (renderer, cell_data_helper.album_art_func);
                // XXX set_row_separator_func (cell_data_helper.row_separator_func);
#endif

            case ListColumn.TITLE:
            case ListColumn.ARTIST:
            case ListColumn.ALBUM:
            case ListColumn.ALBUM_ARTIST:
            case ListColumn.COMPOSER:
            case ListColumn.GENRE:
            case ListColumn.GROUPING:
            case ListColumn.FILE_LOCATION:
                renderer = new Gtk.CellRendererText ();
                tvc.set_cell_data_func (renderer, CellDataFunctionHelper.string_func);
                /// Sample string used to measure the ideal size of the Title, Artist,
                /// Album, Album Artist, Composer, Genre, and Grouping columns in the
                /// list view. It's *never* displayed in the user interface. The translated
                /// string should have a reasonable length, similar to the average length
                /// of a song title or artist name in your language. The automatic column
                /// width will depend on the length of this string and the space needed
                /// by the column's title header.
                test_strings += _ ("Sample List String");
            break;

            case ListColumn.BPM:
                renderer = new Gtk.CellRendererText ();
                tvc.set_cell_data_func (renderer, CellDataFunctionHelper.intelligent_func);
                column_resizable = false;
                test_strings += "9999";
            break;

            case ListColumn.FILE_SIZE:
                renderer = new Gtk.CellRendererText ();
                tvc.set_cell_data_func (renderer, CellDataFunctionHelper.file_size_func);
                test_strings += CellDataFunctionHelper.get_file_size_sample ();
            break;

            default:
                // TreeViewSetup might come from a corrupted database, so use relaxed assertion
                return_if_reached ();
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

        // Add menuitem
        add_column_chooser_menu_item (tvc, type);

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

