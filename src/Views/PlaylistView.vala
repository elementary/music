public class Noise.PlaylistView : View {
    public Playlist playlist { get; construct; }
    private MusicListView list_view { get; set; }

    public PlaylistView (Playlist playlist) {
        Object (playlist: playlist);
    }

    construct {
        list_view = new MusicListView ();
        list_view.set_compare_func (compare_func);
        list_view.set_media (playlist.medias);
        add (list_view);
        // VIEW-TODO: connect_data_signals ();
    }

    private void connect_data_signals () {
        // switch (hint) {
        //     case Hint.READ_ONLY_PLAYLIST:
        //     case Hint.PLAYLIST:
        //     case Hint.SMART_PLAYLIST:
        //         var p = (Playlist) playlist;

        //         // Connect to playlist signals
        //         if (p != null) {
        //             p.media_added.connect (on_playlist_media_added);
        //             p.media_removed.connect (on_playlist_media_removed);
        //             p.cleared.connect (on_playlist_cleared);
        //             p.request_play.connect (() => {
        //                 App.player.clear_queue ();
        //                 play_first_media (true);
        //                 App.player.get_next(true);
        //             });
        //         }
        //         break;
        //     default:
        //         assert_not_reached ();
        // }
    }

    private async void on_playlist_media_added (Gee.Collection<Media> to_add) {
        // yield list_view.add_media_async (to_add);
    }

    private async void on_playlist_media_removed (Gee.Collection<Media> to_remove) {
        // yield list_view.remove_media_async (to_remove);
    }

    private async void on_playlist_cleared () {
        // yield list_view.set_media_async (new Gee.ArrayQueue<Media> ());
    }

    protected int compare_func (int column, Gtk.SortType dir, Media media_a, Media media_b, int a_pos, int b_pos) {
        if (playlist == App.player.queue_playlist) {
            return 0; // Display the queue in the order it actually is
        }

        return list_view.view_compare_func (column, dir, media_a, media_b, a_pos, b_pos);
    }

    public override bool filter (string search) {
        return true;
    }
}
