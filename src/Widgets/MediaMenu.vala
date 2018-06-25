/*
 * Copyright (c) 2018 elementary LLC. (https://elementary.io)
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
 */

public class Noise.MediaMenu : Gtk.Menu {
    public ViewWrapper.Hint hint { get; construct ;}
    public GenericList generic_list { get; construct; }

    private Gtk.MenuItem add_to_playlist;
    private Gtk.MenuItem contractor_entry;
    private Gtk.MenuItem edit_media;
    private Gtk.MenuItem import_to_library;
    private Gtk.MenuItem queue_media;
    private Music.RatingMenuItem rate_media;
    private Gtk.MenuItem remove_media;

    public MediaMenu (GenericList generic_list) {
        Object (
            generic_list: generic_list,
            hint: generic_list.hint
        );
    }

    construct {
        var scroll_to_current = new Gtk.MenuItem.with_label (_("Scroll to Current Song"));
        scroll_to_current.sensitive = false;

        var file_browse = new Gtk.MenuItem.with_label (_("Show in File Browser…"));
        edit_media = new Gtk.MenuItem.with_label (_("Edit Song Info…"));
        contractor_entry = new Gtk.MenuItem.with_label (_("Other Actions"));
        rate_media = new Music.RatingMenuItem ();
        queue_media = new Gtk.MenuItem.with_label (C_("Action item (verb)", "Queue"));
        add_to_playlist = new Gtk.MenuItem.with_label (_("Add to Playlist"));
        remove_media = new Gtk.MenuItem.with_label (_("Remove Song…"));
        import_to_library = new Gtk.MenuItem.with_label (_("Import to Library"));

        switch (hint) {
            case ViewWrapper.Hint.ALBUM_LIST:
                append (edit_media);
                append (file_browse);
                append (contractor_entry);
                append (rate_media);
                append (new Gtk.SeparatorMenuItem ());
                append (queue_media);
                append (add_to_playlist);
                append (new Gtk.SeparatorMenuItem ());
                append (remove_media);
                remove_media.label = _("Remove from Library…");
                break;
            case ViewWrapper.Hint.MUSIC:
            case ViewWrapper.Hint.PLAYLIST:
                append (scroll_to_current);
                append (new Gtk.SeparatorMenuItem ());
                append (edit_media);
                append (file_browse);
                append (contractor_entry);
                append (rate_media);
                append (new Gtk.SeparatorMenuItem ());
                append (queue_media);
                append (add_to_playlist);
                append (new Gtk.SeparatorMenuItem ());
                append (remove_media);
                if (hint == ViewWrapper.Hint.MUSIC) {
                    remove_media.label = _("Remove from Library…");
                }
                break;
            case ViewWrapper.Hint.DEVICE_AUDIO:
                append (scroll_to_current);
                append (new Gtk.SeparatorMenuItem ());
                append (file_browse);
                append (contractor_entry);
                append (rate_media);
                append (new Gtk.SeparatorMenuItem ());
                append (queue_media);
                append (new Gtk.SeparatorMenuItem ());
                append (remove_media);
                append (import_to_library);
                remove_media.label = _("Remove from Device");
                break;
            case ViewWrapper.Hint.SMART_PLAYLIST:
                append (scroll_to_current);
                append (new Gtk.SeparatorMenuItem ());
                append (edit_media);
                append (file_browse);
                append (contractor_entry);
                append (rate_media);
                append (new Gtk.SeparatorMenuItem ());
                append (queue_media);
                append (add_to_playlist);
                break;
            case ViewWrapper.Hint.READ_ONLY_PLAYLIST:
            default:
                append (scroll_to_current);
                append (new Gtk.SeparatorMenuItem ());
                append (file_browse);
                append (contractor_entry);
                if (generic_list.playlist == App.player.queue_playlist) {
                    append (new Gtk.SeparatorMenuItem ());
                    append (remove_media);
                    remove_media.label = _("Remove from Queue");
                }
                break;
        }

        show_all ();

        scroll_to_current.activate.connect (() => {
            generic_list.scroll_to_current_media (true);
        });

        App.player.playback_stopped.connect (() => {
            scroll_to_current.sensitive = false;
        });

        App.player.playback_started.connect (() => {
            scroll_to_current.sensitive = true;
        });

        edit_media.activate.connect (edit_media_clicked);
        file_browse.activate.connect (file_browse_clicked);
        import_to_library.activate.connect (import_to_library_clicked);
        queue_media.activate.connect (queue_clicked);
        rate_media.activate.connect (rate_media_clicked);
        remove_media.activate.connect (remove_media_clicked);
    }

    public void popup_media_menu (Gee.Collection<Media> selection) {
        var media_menu_new_playlist = new Gtk.MenuItem.with_label (_("New Playlist…"));
        media_menu_new_playlist.activate.connect (media_menu_new_playlist_clicked);

        var add_to_playlist_menu = new Gtk.Menu ();
        add_to_playlist_menu.append (media_menu_new_playlist);

        media_menu_new_playlist.visible = generic_list.parent_wrapper.library.support_playlists ();

        foreach (var playlist in generic_list.parent_wrapper.library.get_playlists ()) {
            // Don't include this playlist in the list of available options
            if (playlist == generic_list.playlist || playlist.read_only == true) {
                continue;
            }

            var playlist_item = new Gtk.MenuItem.with_label (playlist.name);
            add_to_playlist_menu.append (playlist_item);

            playlist_item.activate.connect (() => {
                playlist.add_medias (selection.read_only_view);
            });
        }
        add_to_playlist_menu.show_all ();
        add_to_playlist.submenu = add_to_playlist_menu;

        // if all medias are downloaded already, desensitize.
        // if half and half, change text to 'Download %external of %total'
        int temporary_count = 0;
        int total_count = 0;
        foreach (var m in selection) {
            if (m.isTemporary) {
                temporary_count++;
            }
            total_count++;
        }

        if (temporary_count < 1) {
            import_to_library.sensitive = false;
        } else {
            import_to_library.sensitive = true;
            if (temporary_count != total_count) {
                import_to_library.label = _("Import %i of %i selected songs").printf ((int)temporary_count, (int)total_count);
            } else {
                import_to_library.label = ngettext ("Import %i song", "Import %i songs", temporary_count).printf ((int)temporary_count);
            }
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

        rate_media.rating_value = set_rating;

        //remove the previous "Other Actions" submenu and create a new one
        var contractor_sub_menu = new Gtk.Menu ();
        contractor_entry.submenu = contractor_sub_menu;

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
                contractor_sub_menu.append (menu_item);
            }

            contractor_entry.sensitive = contractor_sub_menu.get_children ().length () > 0;
            contractor_sub_menu.show_all ();
        } catch (Error err) {
            warning ("Failed to obtain Contractor actions: %s", err.message);
            contractor_entry.sensitive = false;
        }

        popup (null, null, null, 3, Gtk.get_current_event_time ());
    }

    private void edit_media_clicked () {
        var to_edit_med = new Gee.TreeSet<Media> ();
        to_edit_med.add_all (generic_list.get_selected_medias ());

        if (to_edit_med.is_empty) {
            return;
        }

        var first_media = to_edit_med.first ();
        string music_folder_uri = File.new_for_path (Settings.Main.get_default ().music_folder).get_uri ();
        if (to_edit_med.size == 1 && !first_media.file.query_exists () && first_media.uri.has_prefix (music_folder_uri)) {
            first_media.unique_status_image = new ThemedIcon ("process-error-symbolic");
            var fnfd = new FileNotFoundDialog (to_edit_med);
            fnfd.present ();
        } else {
            var media_editor = new MediaEditor (to_edit_med);
            media_editor.show_all ();
        }
    }

    private void file_browse_clicked () {
        foreach (Media media in generic_list.get_selected_medias ()) {
            try {
                Gtk.show_uri (null, media.file.get_parent ().get_uri (), Gdk.CURRENT_TIME);
            } catch (Error err) {
                debug ("Could not browse media %s: %s\n", media.uri, err.message);
            }

            return;
        }
    }

    private void import_to_library_clicked () {
        generic_list.import_requested (generic_list.get_selected_medias ().read_only_view);
    }

    private void media_menu_new_playlist_clicked () {
        var p = new StaticPlaylist ();
        p.add_medias (generic_list.get_selected_medias ().read_only_view);
        p.name = PlaylistsUtils.get_new_playlist_name (generic_list.parent_wrapper.library.get_playlists ());
        generic_list.parent_wrapper.library.add_playlist (p);
    }

    private void queue_clicked () {
        App.player.queue_medias (generic_list.get_selected_medias ().read_only_view);
    }

    private void rate_media_clicked () {
        int new_rating = rate_media.rating_value;
        var selected = generic_list.get_selected_medias ().read_only_view;
        foreach (Media media in selected) {
            media.rating = new_rating;
        }
        generic_list.parent_wrapper.library.update_medias (selected, false, true);
    }

    private void remove_media_clicked () {
        var selected_media = generic_list.get_selected_medias ().read_only_view;

        switch (hint) {
            case ViewWrapper.Hint.ALBUM_LIST:
            case ViewWrapper.Hint.MUSIC:
                var dialog = new RemoveFilesDialog (selected_media);
                dialog.remove_media.connect ((delete_files) => {
                    generic_list.parent_wrapper.library.remove_medias (selected_media, delete_files);
                });
                break;
            case ViewWrapper.Hint.DEVICE_AUDIO:
                var dvw = (DeviceViewWrapper) generic_list.parent_wrapper;
                dvw.library.remove_medias (selected_media, true);
                break;
            case ViewWrapper.Hint.PLAYLIST:
                generic_list.playlist.remove_medias (selected_media);
                break;
            case ViewWrapper.Hint.READ_ONLY_PLAYLIST:
                if (generic_list.playlist == App.player.queue_playlist) {
                    generic_list.playlist.remove_medias (selected_media);
                }
                break;
          }
    }
}
