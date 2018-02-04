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

    public override void update_alert (Granite.Widgets.AlertView alert) {
        alert.icon_name = "dialog-information";
        alert.title = _("No Songs");
        alert.description = _("This playlist will be automatically populated with songs that match its rules. To modify these rules, use the <b>secondary click</b> on it in the sidebar and click on <b>Edit</b>. Optionally, you can click on the button below.");
        alert.show_action (_("Edit Smart Playlist"));
        alert.action_activated.connect (alert_action_clicked);
    }

    public void alert_action_clicked () {
        var spe = new SmartPlaylistEditor ((SmartPlaylist)playlist, App.main_window.library_manager);
        spe.show ();
    }
}
