/*-
 * Copyright (c) 2019 elementary Inc. (https://elementary.io)
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
 * The Music authors hereby grant permission for non-GPL compatible
 * GStreamer plugins to be used and distributed together with GStreamer
 * and Music. This permission is above and beyond the permissions granted
 * by the GPL license by which Music is covered. If you modify this code
 * you may extend this exception to your version of the code, but you are not
 * obligated to do so. If you do not wish to do so, delete this exception
 * statement from your version.
 */

public class Music.TrackMenu : Gtk.Menu {
    public Gee.Collection<Media> selection { get; construct; }

    private Music.RatingMenuItem rating_menuitem;

    public TrackMenu (Gee.Collection<Media> selection) {
        Object (selection: selection);
    }

    construct {
        var edit_menuitem = new Gtk.MenuItem.with_label (_("Edit Song Info…"));

        var files_menuitem = new Gtk.MenuItem.with_label (_("Show in File Browser…"));

        var contractor_sub_menu = new Gtk.Menu ();

        var contractor_entry = new Gtk.MenuItem.with_label (_("Other Actions"));
        contractor_entry.submenu = contractor_sub_menu;

        rating_menuitem = new Music.RatingMenuItem ();

        var queue_menuitem = new Gtk.MenuItem.with_label (C_("Action item (verb)", "Queue"));

        var new_playlist_menuitem = new Gtk.MenuItem.with_label (_("New Playlist…"));

        var add_to_playlist_menu = new Gtk.Menu ();
        add_to_playlist_menu.append (new_playlist_menuitem);

        var add_to_playlist = new Gtk.MenuItem.with_label (_("Add to Playlist"));
        add_to_playlist.submenu = add_to_playlist_menu;

        var remove_menuitem = new Gtk.MenuItem.with_label (_("Remove from Library…"));

        append (edit_menuitem);
        append (files_menuitem);
        append (contractor_entry);
        append (rating_menuitem);
        append (new Gtk.SeparatorMenuItem ());
        append (queue_menuitem);
        append (add_to_playlist);
        append (new Gtk.SeparatorMenuItem ());
        append (remove_menuitem);

        try {
            var files = new Gee.HashSet<File> (); //for automatic deduplication
            foreach (var media in selection) {
                if (media.file.query_exists ()) {
                    files.add (media.file);
                    //if the file was marked nonexistent, update its status
                    if (media.location_unknown && media.unique_status_image != null) {
                        media.unique_status_image = null;
                        media.location_unknown = false;
                    }
                } else {
                    critical ("File %s does not exist, ignoring it", media.uri);
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
        } catch (Error err) {
            critical ("Failed to obtain Contractor actions: %s", err.message);
            contractor_entry.sensitive = false;
        }

        foreach (var playlist in libraries_manager.local_library.get_playlists ()) {
            // Don't include this playlist in the list of available options
            if (playlist.read_only == true) {
                continue;
            }

            var playlist_item = new Gtk.MenuItem.with_label (playlist.name);
            add_to_playlist_menu.append (playlist_item);

            playlist_item.activate.connect (() => {
                playlist.add_medias (selection.read_only_view);
            });
        }

        show_all ();

        edit_menuitem.activate.connect (edit_media);
        files_menuitem.activate.connect (show_in_files);
        rating_menuitem.activate.connect (rate_media);
        remove_menuitem.activate.connect (remove_media);
        new_playlist_menuitem.activate.connect (create_new_playlist);

        queue_menuitem.activate.connect (() => {
            App.player.queue_media (selection.read_only_view);
        });
    }

    private void create_new_playlist () {
        var local_library = libraries_manager.local_library;

        var playlist = new StaticPlaylist ();
        playlist.add_medias (selection.read_only_view);
        playlist.name = PlaylistsUtils.get_new_playlist_name (local_library.get_playlists ());

        local_library.add_playlist (playlist);
    }

    private void edit_media () {
        var media_treeset = new Gee.TreeSet<Media> ();
        media_treeset.add_all (selection);

        var media_editor = new MediaEditor (media_treeset);
        media_editor.show_all ();
    }

    private void rate_media () {
        int new_rating = rating_menuitem.rating_value;
        foreach (var media in selection) {
            media.rating = new_rating;
        }
    }

    private void remove_media () {
        var dialog = new RemoveFilesDialog (selection.read_only_view);
        dialog.remove_media.connect ((delete_files) => {
            libraries_manager.local_library.remove_medias (selection, delete_files);
        });
    }

    private void show_in_files () {
        foreach (var media in selection) {
            try {
                Gtk.show_uri (null, media.file.get_parent ().get_uri (), Gdk.CURRENT_TIME);
            } catch (Error err) {
                debug ("Could not browse media %s: %s\n", media.uri, err.message);
            }
        }
    }
}
