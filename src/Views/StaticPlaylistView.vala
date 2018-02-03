public class Noise.StaticPlaylistView : PlaylistView {

    public StaticPlaylistView (StaticPlaylist playlist) {
        Object (playlist: playlist);
    }

    construct {
        priority = 3;
    }
}
