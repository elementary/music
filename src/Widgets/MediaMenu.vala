/*-
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
    private Gee.TreeSet<Media> media { get; set; }
    private Granite.Widgets.RatingMenuItem rate_media;
    private Gtk.MenuItem add_to_playlist;
    private Gtk.MenuItem contractor_entry;

    construct {
        var edit_media = new Gtk.MenuItem.with_label (_("Edit Song Info"));
        edit_media.activate.connect (edit_clicked);

        var file_browse = new Gtk.MenuItem.with_label (_("Show in File Browser"));
        file_browse.activate.connect (file_browse_clicked);

        contractor_entry = new Gtk.MenuItem.with_label (_("Other Actions"));

        var queue = new Gtk.MenuItem.with_label (C_("Action item (verb)", "Queue"));
        queue.activate.connect (queue_clicked);

        add_to_playlist = new Gtk.MenuItem.with_label (_("Add to Playlist"));

        var remove = new Gtk.MenuItem.with_label (_("Remove Song"));
        remove.activate.connect (remove_clicked);

        rate_media = new Granite.Widgets.RatingMenuItem ();
        rate_media.activate.connect (rate_clicked);

        append (edit_media);
        append (file_browse);
        append (contractor_entry);
        append (rate_media);
        append (new Gtk.SeparatorMenuItem ());
        append (queue);
        append (add_to_playlist);
        append (new Gtk.SeparatorMenuItem ());
        append (remove);
    }

    public void popup_media_menu (Gee.Collection<Media> selection) {
        var media_menu_new_playlist = new Gtk.MenuItem.with_label (_("New Playlist…"));
        media_menu_new_playlist.activate.connect (new_playlist_clicked);

        var add_to_playlist_menu = new Gtk.Menu ();
        add_to_playlist_menu.append (media_menu_new_playlist);

        foreach (var playlist in App.main_window.library_manager.get_playlists ()) {
            if (playlist.read_only == true)
                continue;

            var playlist_item = new Gtk.MenuItem.with_label (playlist.name);
            add_to_playlist_menu.append (playlist_item);

            playlist_item.activate.connect (() => {
                playlist.add_medias (selection.read_only_view);
            });
        }
        add_to_playlist_menu.show_all ();
        add_to_playlist.submenu = add_to_playlist_menu;

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
        var contractorSubMenu = new Gtk.Menu ();
        contractor_entry.submenu = contractorSubMenu;

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

            contractor_entry.sensitive = contractorSubMenu.get_children ().length () > 0;
            contractorSubMenu.show_all ();
        } catch (Error err) {
            warning ("Failed to obtain Contractor actions: %s", err.message);
            contractor_entry.sensitive = false;
        }

        show_all ();
        popup (null, null, null, 3, Gtk.get_current_event_time ());
    }

    private void edit_clicked () {
        if (media.is_empty) {
            return;
        }

        var first_media = media.first ();
        string music_folder_uri = File.new_for_path (Settings.Main.get_default ().music_folder).get_uri ();
        if (media.size == 1 && !first_media.file.query_exists () && first_media.uri.has_prefix (music_folder_uri)) {
            first_media.unique_status_image = new ThemedIcon ("process-error-symbolic");
            var fnfd = new FileNotFoundDialog (media);
            fnfd.present ();
        } else {
            var se = new MediaEditor (media);
            se.show_all ();
        }
    }

    private void file_browse_clicked () {
        foreach (Media m in media) {
            try {
                Gtk.show_uri (null, m.file.get_parent ().get_uri (), Gdk.CURRENT_TIME);
            } catch (Error err) {
                debug ("Could not browse media %s: %s\n", m.uri, err.message);
            }

            return;
        }
    }

    private void queue_clicked () {
        App.player.queue_medias (media);
    }

    private void new_playlist_clicked () {
        var p = new StaticPlaylist ();
        p.add_medias (media);
        p.name = PlaylistsUtils.get_new_playlist_name (App.main_window.library_manager.get_playlists ());
        App.main_window.library_manager.add_playlist (p);
    }

    private void rate_clicked () {
        int new_rating = rate_media.rating_value;
        foreach (Media m in media) {
            m.rating = new_rating;
        }
    }

    private void remove_clicked () {
        var dialog = new RemoveFilesDialog (media);
        dialog.remove_media.connect ((delete_files) => {
            App.main_window.library_manager.remove_medias (media, delete_files);
        });
    }
}
