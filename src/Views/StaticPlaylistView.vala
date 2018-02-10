/*-
 * Copyright (c) 2012-2017 elementary LLC. (https://elementary.io)
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
 * Authored by: Baptiste Gelez <baptiste@gelez.xyz>
 */

/**
* A view displaying a static playlist
*/
public class Noise.StaticPlaylistView : PlaylistView {

    public StaticPlaylistView (StaticPlaylist playlist, TreeViewSetup tvs) {
        Object (playlist: playlist, tvs: tvs);
    }

    construct {
        id = "local/playlist/static/" + playlist.id;
        if (playlist == App.player.queue_playlist) {
            id = "local/playlist/queue/"; // else queue and history have the same ID
        }
        priority = 3;
        accept_data_drop = true;
        list_view.playlist_id = ((StaticPlaylist)playlist).read_only ? "" : "p%lld".printf (playlist.rowid);

        list_view.headers_clickable = playlist != App.player.queue_playlist; // You can't reorder the queue
    }

    public override Gtk.Menu? get_sidebar_context_menu (Granite.Widgets.SourceList list, Granite.Widgets.SourceList.Item item) {
        var menu = new Gtk.Menu();

        var rename = new Gtk.MenuItem.with_label(_("Rename"));
        rename.activate.connect (() => {
            item.editable = true;
            list.start_editing_item (item);
            item.edited.connect ((new_name) => {
                playlist.name = new_name;
            });
        });

        var remove = new Gtk.MenuItem.with_label(_("Remove"));
        remove.activate.connect (() => {
            App.main_window.library_manager.remove_playlist (playlist.rowid);
        });

        var export = new Gtk.MenuItem.with_label(_("Export…"));
        export.activate.connect (() => {
            PlaylistsUtils.export_playlist (playlist);
        });

        var save = new Gtk.MenuItem.with_label(_("Save as Playlist"));
        save.activate.connect(() => {
            var new_playlist = new StaticPlaylist ();
            new_playlist.name = PlaylistsUtils.get_new_playlist_name (App.main_window.library_manager.get_playlists (), playlist.name);
            new_playlist.add_medias (playlist.medias);
            App.main_window.library_manager.add_playlist (new_playlist);
        });

        if (((StaticPlaylist)playlist).read_only) {
            menu.append (save);
        } else {
            menu.append(rename);
            menu.append(remove);
        }
        menu.append(export);

        menu.show_all ();
        return menu;
    }

    public override void update_alert (Granite.Widgets.AlertView alert) {
        alert.icon_name = "dialog-information";

        if (playlist == App.player.queue_playlist) {
            alert.title = _("No songs in Queue");
            alert.description = _("To add songs to the queue, use the <b>secondary click</b> on an item and choose <b>Queue</b>. When a song finishes, the queued songs will be played first before the next song in the currently playing list.");
        } else if (playlist == App.player.history_playlist) {
            alert.title = _("No songs in History");
            alert.description = _("After a part of a song has been played, it is added to the history list.\nYou can use this list to see all the songs you have played during the current session.");
        } else {
            alert.title = _("No Songs");
            alert.description = _("Updating playlist. Please wait.");
        }
    }

    public override void data_drop (Gtk.SelectionData data) {
        var uri_set = new Gee.HashSet<string> ();
        foreach (string uri in data.get_uris ()) {
            uri_set.add (uri);
        }

        var media_list = App.main_window.library_manager.medias_from_uris (uri_set);
        playlist.add_medias (media_list);
    }
}
