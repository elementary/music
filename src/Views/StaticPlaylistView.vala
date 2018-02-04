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
}
