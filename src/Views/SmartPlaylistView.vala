/**
* A view displaying a smart playlist.
*/
public class Noise.SmartPlaylistView : PlaylistView {

    public SmartPlaylistView (SmartPlaylist playlist, TreeViewSetup tvs) {
        Object (playlist: playlist, tvs: tvs);
    }

    construct {
        priority = 2;
    }
}
