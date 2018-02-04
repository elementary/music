/**
* A view displaying a smart playlist.
*/
public class Noise.SmartPlaylistView : PlaylistView {

    public SmartPlaylistView (SmartPlaylist playlist, TreeViewSetup tvs) {
        Object (playlist: playlist, tvs: tvs);
    }

    construct {
        id = "local/playlist/smart/" + playlist.id;
        priority = 2;
    }

    public override Gtk.Menu? get_sidebar_context_menu (Granite.Widgets.SourceList list, Granite.Widgets.SourceList.Item item) {
        var rename = new Gtk.MenuItem.with_label(_("Rename"));
        rename.activate.connect (() => {
            item.editable = true;
            list.start_editing_item (item);
            item.edited.connect ((new_name) => {
                playlist.name = new_name;
            });
        });

        var edit = new Gtk.MenuItem.with_label(_("Edit…"));
        edit.activate.connect (() => {
            show_edit_dialog ();
        });

        var remove = new Gtk.MenuItem.with_label(_("Remove"));
        remove.activate.connect (() => {
            App.main_window.library_manager.remove_smart_playlist (playlist.rowid);
        });

        var export = new Gtk.MenuItem.with_label(_("Export…"));
        export.activate.connect (() => {
            PlaylistsUtils.export_playlist (playlist);
        });

        var menu = new Gtk.Menu();
        menu.append(rename);
        menu.append(edit);
        menu.append(remove);
        menu.append(export);

        menu.show_all ();
        return menu;
    }

    public override void update_alert (Granite.Widgets.AlertView alert) {
        alert.icon_name = "dialog-information";
        alert.title = _("No Songs");
        alert.description = _("This playlist will be automatically populated with songs that match its rules. To modify these rules, use the <b>secondary click</b> on it in the sidebar and click on <b>Edit</b>. Optionally, you can click on the button below.");
        alert.show_action (_("Edit Smart Playlist"));
        alert.action_activated.connect (show_edit_dialog);
    }

    public void show_edit_dialog () {
        var spe = new SmartPlaylistEditor ((SmartPlaylist)playlist, App.main_window.library_manager);
        spe.show ();
    }
}
