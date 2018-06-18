// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012-2018 elementary LLC. (https://elementary.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
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
 *              Corentin Noël <corentin@elementary.io>,
 *              Lucas Baudin <xapantu@gmail.com>,
 *              ammonkey <am.monkeyd@gmail.com>,
 *              Victor Martinez <victoreduardm@gmail.com>,
 *              Sergey Davidoff <shnatsel@gmail.com>
 */

public class Noise.MusicListView : GenericList {
    public bool can_scroll_to_current { get; construct; }

    //for media list right click
    Gtk.Menu media_action_menu;
    Gtk.MenuItem media_edit_media;
    Gtk.MenuItem media_file_browse;
    Gtk.MenuItem media_menu_contractor_entry; // make menu on fly
    Gtk.MenuItem media_menu_queue;
    Gtk.MenuItem media_menu_add_to_playlist; // make menu on fly
    Granite.Widgets.RatingMenuItem media_rate_media;
    Gtk.MenuItem media_remove;
    Gtk.MenuItem import_to_library;
    Gtk.MenuItem media_scroll_to_current;

    public MusicListView (ViewWrapper view_wrapper, TreeViewSetup tvs, bool can_scroll_to_current = true) {
        Object (
            can_scroll_to_current: can_scroll_to_current,
            parent_wrapper: view_wrapper,
            tvs: tvs
        );
    }

    construct {
        // This is vital
        set_value_func (view_value_func);
        set_compare_func (view_compare_func);

        button_release_event.connect (view_click_release);

        media_scroll_to_current = new Gtk.MenuItem.with_label (_("Scroll to Current Song"));
        media_scroll_to_current.activate.connect (media_scroll_to_current_requested);
        media_scroll_to_current.sensitive = false;

        media_edit_media = new Gtk.MenuItem.with_label (_("Edit Song Info"));
        media_edit_media.activate.connect (media_edit_media_clicked);

        media_file_browse = new Gtk.MenuItem.with_label (_("Show in File Browser"));
        media_file_browse.activate.connect (media_file_browse_clicked);

        media_menu_contractor_entry = new Gtk.MenuItem.with_label (_("Other actions"));

        media_menu_queue = new Gtk.MenuItem.with_label (C_("Action item (verb)", "Queue"));
        media_menu_queue.activate.connect (media_menu_queue_clicked);

        media_menu_add_to_playlist = new Gtk.MenuItem.with_label (_("Add to Playlist"));

        media_remove = new Gtk.MenuItem.with_label (_("Remove Song"));
        media_remove.activate.connect (mediaRemoveClicked);

        import_to_library = new Gtk.MenuItem.with_label (_("Import to Library"));
        import_to_library.activate.connect (import_to_library_clicked);

        media_rate_media = new Granite.Widgets.RatingMenuItem ();
        media_rate_media.activate.connect (media_rate_media_clicked);

        media_action_menu = new Gtk.Menu ();
        media_action_menu.attach_to_widget (this, null);

        if (can_scroll_to_current) {
            media_action_menu.append (media_scroll_to_current);
            media_action_menu.append (new Gtk.SeparatorMenuItem ());
        }

        var read_only = hint == ViewWrapper.Hint.READ_ONLY_PLAYLIST;
        if (read_only == false) {
            media_action_menu.append (media_edit_media);
        }
        media_action_menu.append (media_file_browse);
        media_action_menu.append (media_menu_contractor_entry);
        if (read_only == false) {
            media_action_menu.append (media_rate_media);
        }
        media_action_menu.append (new Gtk.SeparatorMenuItem ());
        media_action_menu.append (media_menu_queue);
        if (read_only == false) {
            media_action_menu.append (media_menu_add_to_playlist);
        }
        if (hint != ViewWrapper.Hint.SMART_PLAYLIST &&
            hint != ViewWrapper.Hint.READ_ONLY_PLAYLIST) {
                media_action_menu.append (new Gtk.SeparatorMenuItem ());
        }
        media_action_menu.append (media_remove);
        media_action_menu.append (import_to_library);

        App.player.playback_stopped.connect (() => {
            media_scroll_to_current.sensitive = false;
        });

        App.player.playback_started.connect (() => {
            media_scroll_to_current.sensitive = true;
        });

        headers_clickable = playlist != App.player.queue_playlist; // You can't reorder the queue

        update_sensitivities ();
    }

    public override void update_sensitivities () {
        media_action_menu.show_all ();

        switch (hint) {
            case ViewWrapper.Hint.ALBUM_LIST:
            case ViewWrapper.Hint.MUSIC:
                media_remove.label = _("Remove from Library");
                import_to_library.visible = false;
                break;
            case ViewWrapper.Hint.PLAYLIST:
                import_to_library.visible = false;
                break;
            case ViewWrapper.Hint.READ_ONLY_PLAYLIST:
                import_to_library.visible = false;
                if (playlist == App.player.queue_playlist) {
                    media_remove.label = _("Remove from Queue");
                    media_menu_queue.visible = false;
                } else {
                    media_remove.visible = false;
                }
                break;
            case ViewWrapper.Hint.DEVICE_AUDIO:
                media_edit_media.visible = false;
                media_remove.label = _("Remove from Device");
                if (parent_wrapper.library.support_playlists () == false) {
                    media_menu_add_to_playlist.visible = false;
                }
                break;
            default:
                media_remove.visible = false;
                import_to_library.visible = false;
                break;
        }
    }

    public void popup_media_menu (Gee.Collection<Media> selection) {
        var media_menu_new_playlist = new Gtk.MenuItem.with_label (_("New Playlist…"));
        media_menu_new_playlist.activate.connect (media_menu_new_playlist_clicked);

        var add_to_playlist_menu = new Gtk.Menu ();
        add_to_playlist_menu.append (media_menu_new_playlist);
        if (parent_wrapper.library.support_playlists () == false) {
            media_menu_new_playlist.visible = false;
        }
        foreach (var playlist in parent_wrapper.library.get_playlists ()) {
            // Don't include this playlist in the list of available options
            if (playlist == this.playlist)
                continue;

            if (playlist.read_only == true)
                continue;

            var playlist_item = new Gtk.MenuItem.with_label (playlist.name);
            add_to_playlist_menu.append (playlist_item);

            playlist_item.activate.connect (() => {
                playlist.add_medias (selection.read_only_view);
            });
        }
        add_to_playlist_menu.show_all ();
        media_menu_add_to_playlist.submenu = add_to_playlist_menu;

        // if all medias are downloaded already, desensitize.
        // if half and half, change text to 'Download %external of %total'
        int temporary_count = 0;
        int total_count = 0;
        foreach (var m in selection) {
            if (m.isTemporary)
                temporary_count++;
            total_count++;
        }

        if (temporary_count < 1) {
            import_to_library.sensitive = false;
        } else {
            import_to_library.sensitive = true;
            if (temporary_count != total_count)
                import_to_library.label = _("Import %i of %i selected songs").printf ((int)temporary_count, (int)total_count);
            else
                import_to_library.label = ngettext ("Import %i song", "Import %i songs", temporary_count).printf ((int)temporary_count);
        }

        int set_rating = -1;
        foreach (Media m in selection) {
            if (set_rating == -1) {
                set_rating = (int) m.rating;
            } else if (set_rating != m.rating) {
                set_rating = 0;
                break;
            }
        }

        media_rate_media.rating_value = set_rating;

        //remove the previous "Other Actions" submenu and create a new one
        var contractorSubMenu = new Gtk.Menu ();
        media_menu_contractor_entry.submenu = contractorSubMenu;

        try {
            var files = new Gee.HashSet<File> (); //for automatic deduplication
            debug ("Number of selected medias obtained by MusicListView class: %u\n", selection.size);
            foreach (var media in selection) {
                if (media.file.query_exists ()) {
                    files.add (media.file);
                    //if the file was marked nonexistent, update its status
                    if (media.location_unknown && media.unique_status_image != null) {
                        media.unique_status_image = null;
                        media.location_unknown = false;
                    }
                } else {
                    warning ("File %s does not exist, ignoring it", media.uri);
                    //indicate that the file doesn't exist in the UI
                    media.unique_status_image = new ThemedIcon ("process-error-symbolic");
                    media.location_unknown = true;
                }
            }

            var contracts = Granite.Services.ContractorProxy.get_contracts_for_files (files.to_array ());
            foreach (var contract in contracts) {
                var menu_item = new ContractMenuItem (contract, selection);
                contractorSubMenu.append (menu_item);
            }

            media_menu_contractor_entry.sensitive = contractorSubMenu.get_children ().length () > 0;
            contractorSubMenu.show_all ();
        } catch (Error err) {
            warning ("Failed to obtain Contractor actions: %s", err.message);
            media_menu_contractor_entry.sensitive = false;
        }

        media_action_menu.popup (null, null, null, 3, Gtk.get_current_event_time ());
    }

    public override bool button_press_event (Gdk.EventButton event) {
        if (event.window != get_bin_window ())
            return base.button_press_event (event);

        // Check whether we should let the default handler alter the selection or not.
        if (check_selection_event (event))
            base.button_press_event (event);

        if (event.button == Gdk.BUTTON_SECONDARY) {
            popup_media_menu (get_selected_medias ());
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
        if ((event.state & Gdk.ModifierType.CONTROL_MASK) == event.state || (event.state & Gdk.ModifierType.SHIFT_MASK) == event.state) {
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
    private bool view_click_release (Gtk.Widget sender, Gdk.EventButton event) {
        /* if we were dragging, then set dragging to false */
        if (dragging && event.button == 1) {
            dragging = false;
            return true;
        } else if (((event.state & Gdk.ModifierType.SHIFT_MASK) == Gdk.ModifierType.SHIFT_MASK) | ((event.state & Gdk.ModifierType.CONTROL_MASK) == Gdk.ModifierType.CONTROL_MASK)) {
            return true;
        } else {
            Gtk.TreePath path;
            Gtk.TreeViewColumn tvc;
            int cell_x;
            int cell_y;
            int x = (int)event.x;
            int y = (int)event.y;

            if (!(get_path_at_pos (x, y, out path, out tvc, out cell_x, out cell_y)))
                return false;
            get_selection ().unselect_all ();
            get_selection ().select_path (path);
            return false;
        }
    }

    /** media menu popup clicks **/
    void media_edit_media_clicked () {
        var to_edit_med = new Gee.TreeSet<Media> ();
        to_edit_med.add_all (get_selected_medias ());

        if (to_edit_med.is_empty)
            return;

        Media first_media = to_edit_med.first ();
        string music_folder_uri = File.new_for_path (Settings.Main.get_default ().music_folder).get_uri ();
        if (to_edit_med.size == 1 && !first_media.file.query_exists () && first_media.uri.has_prefix (music_folder_uri)) {
            first_media.unique_status_image = new ThemedIcon ("process-error-symbolic");
            var fnfd = new FileNotFoundDialog (to_edit_med);
            fnfd.present ();
        } else {
            var se = new MediaEditor (to_edit_med);
            se.show_all ();
        }
    }

    protected void media_file_browse_clicked () {
        foreach (Media m in get_selected_medias ()) {
            try {
                Gtk.show_uri (null, m.file.get_parent ().get_uri (), Gdk.CURRENT_TIME);
            } catch (Error err) {
                debug ("Could not browse media %s: %s\n", m.uri, err.message);
            }

            return;
        }
    }

    protected virtual void media_menu_queue_clicked () {
        App.player.queue_medias (get_selected_medias ().read_only_view);
    }

    protected virtual void media_menu_new_playlist_clicked () {
        var p = new StaticPlaylist ();
        p.add_medias (get_selected_medias ().read_only_view);
        p.name = PlaylistsUtils.get_new_playlist_name (parent_wrapper.library.get_playlists ());
        parent_wrapper.library.add_playlist (p);
    }

    protected void media_rate_media_clicked () {
        int new_rating = media_rate_media.rating_value;
        var selected = get_selected_medias ().read_only_view;
        foreach (Media m in selected) {
            m.rating = new_rating;
        }
        parent_wrapper.library.update_medias (selected, false, true);
    }

    protected override void mediaRemoveClicked () {
        var selected_media = get_selected_medias ().read_only_view;

        switch (hint) {
            case ViewWrapper.Hint.ALBUM_LIST:
            case ViewWrapper.Hint.MUSIC:
                var dialog = new RemoveFilesDialog (selected_media);
                dialog.remove_media.connect ((delete_files) => {
                    parent_wrapper.library.remove_medias (selected_media, delete_files);
                });
                break;
            case ViewWrapper.Hint.DEVICE_AUDIO:
                var dvw = (DeviceViewWrapper) parent_wrapper;
                dvw.library.remove_medias (selected_media, true);
                break;
            case ViewWrapper.Hint.PLAYLIST:
                playlist.remove_medias (selected_media);
                break;
            case ViewWrapper.Hint.READ_ONLY_PLAYLIST:
                if (playlist == App.player.queue_playlist) {
                    playlist.remove_medias (selected_media);
                }
                break;
          }
    }

    void import_to_library_clicked () {
        import_requested (get_selected_medias ().read_only_view);
    }

    protected virtual void onDragDataGet (Gdk.DragContext context, Gtk.SelectionData selection_data, uint info, uint time_) {
        string[] uris = null;

        foreach (Media m in get_selected_medias ()) {
            debug ("adding %s", m.uri);
            uris += (m.uri);
        }

        if (uris != null)
            selection_data.set_uris (uris);
    }

    /**
     * Compares the two given objects based on the sort column.
     */
    protected int view_compare_func (int column, Gtk.SortType dir, Media media_a, Media media_b, int a_pos, int b_pos) {
        if (playlist == App.player.queue_playlist) {
            return 0; // Display the queue in the order it actually is
        }

        int order = 0;
        return_val_if_fail (column >= 0 && column < ListColumn.N_COLUMNS, order);

        switch (column) {
            case ListColumn.NUMBER: // We assume there are no two indentical numbers for this case
                order = Compare.standard (a_pos, b_pos);
            break;

            case ListColumn.TITLE:
                order = Compare.titles (media_a, media_b);
            break;

            case ListColumn.LENGTH:
                order = Compare.standard_unsigned (media_a.length, media_b.length);
                if (order == 0) {
                    Compare.titles (media_a, media_b);
                }
            break;

            case ListColumn.ARTIST:
                order = Compare.artists (media_a, media_b);
            break;

            case ListColumn.ALBUM:
                order = Compare.albums (media_a, media_b);
            break;


            // Typically, when users choose to sort their media collection by track numbers,
            // what they actually want is ordering their albums, which means that this is
            // equivalent to sorting by album_artists.
            case ListColumn.TRACK:
            case ListColumn.ALBUM_ARTIST:
                order = Compare.album_artists (media_a, media_b);
            break;

            case ListColumn.COMPOSER:
                order = String.compare (media_a.get_display_composer (), media_b.get_display_composer ());
            break;

            case ListColumn.GROUPING:
                order = String.compare (media_a.grouping, media_b.grouping);
            break;
            case ListColumn.GENRE:
                order = Compare.genres (media_a, media_b);
            break;

            case ListColumn.YEAR:
                order = Compare.standard_unsigned (media_a.year, media_b.year);
            break;

            case ListColumn.BITRATE:
                order = Compare.standard_unsigned (media_a.bitrate, media_b.bitrate);
            break;

            case ListColumn.RATING:
                order = Compare.standard_unsigned (media_a.rating, media_b.rating);
            break;

            case ListColumn.PLAY_COUNT:
                order = Compare.standard_unsigned (media_a.play_count, media_b.play_count);
            break;

            case ListColumn.SKIP_COUNT:
                order = Compare.standard_unsigned (media_a.skip_count, media_b.skip_count);
            break;

            case ListColumn.DATE_ADDED:
                order = Compare.standard_unsigned (media_a.date_added, media_b.date_added);
            break;

            case ListColumn.LAST_PLAYED:
                order = Compare.standard_unsigned (media_a.last_played, media_b.last_played);
            break;

            case ListColumn.BPM:
                order = Compare.standard_unsigned (media_a.bpm, media_b.bpm);
            break;

            case ListColumn.FILE_SIZE:
                order = Compare.standard_64 ((int64) media_a.file_size, (int64) media_b.file_size);
            break;

            case ListColumn.FILE_LOCATION:
                order = String.compare (media_a.get_display_location (), media_b.get_display_location ());
            break;
        }

        // When order is zero, we'd like to jump into sorting by genre, but that'd
        // be a performance killer. Let's compare titles and that's it.
        if (order == 0 && column != ListColumn.GENRE && column != ListColumn.ARTIST)
            order = Noise.Compare.titles (media_a, media_b);

        // If still 0, fall back to comparing URIS
        if (order == 0)
            order = String.compare (media_a.uri, media_b.uri);

        // Invert order if ordering is descending
        if (dir == Gtk.SortType.DESCENDING && order != 0)
            order = (order > 0) ? -1 : 1;

        return order;
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

            case ListColumn.ALBUM:
            case ListColumn.TITLE:
            case ListColumn.ARTIST:
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
