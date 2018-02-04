/**
* A view displaying a static playlist
*/
public class Noise.StaticPlaylistView : PlaylistView {

    public StaticPlaylistView (StaticPlaylist playlist, TreeViewSetup tvs) {
        Object (playlist: playlist, tvs: tvs);
    }

    construct {
        priority = 3;
    }
}
