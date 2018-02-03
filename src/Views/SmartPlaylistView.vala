public class Noise.SmartPlaylistView : PlaylistView {

    public SmartPlaylistView (SmartPlaylist playlist) {
        Object (playlist: playlist);
    }

    construct {
        priority = 2;
    }
}
