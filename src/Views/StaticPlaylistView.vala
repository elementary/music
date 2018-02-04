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
