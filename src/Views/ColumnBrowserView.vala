/**
* View that displays media in a list, filtered with a {@link Noise.MusicColumnBrowser}
*/
public class Noise.ColumnBrowserView : View {
    public Playlist playlist { get; construct set; }
    public Gee.ArrayList<Media> media { get; set; }

    private int visible_count = 0;

    public MusicColumnBrowser column_browser { get; construct; }
    public MusicListView list_view { get; construct; }

    public ColumnBrowserView (Playlist playlist) {
        Object (playlist: playlist);
    }

    construct {
        media = new Gee.ArrayList<Media> ();
        media.add_all (playlist.medias);

        column_browser = new MusicColumnBrowser ();
        column_browser.set_media (playlist.medias);
        column_browser.changed.connect (filter_changed);

        list_view = new MusicListView ();
        list_view.set_media (playlist.medias);
        var scroll = new Gtk.ScrolledWindow (null, null);
        scroll.add (list_view);

        var vpaned = new Gtk.Paned (Gtk.Orientation.VERTICAL);
        vpaned.pack1 (column_browser, false, false);
        vpaned.pack2 (scroll, true, false);

        add (vpaned);
    }

    public void filter_changed () {
        var showing = new Gee.ArrayList<Media> ();
        foreach (var m in media) {
            if (column_browser.match_media (m)) {
                showing.add (m);
            }
        }

        list_view.set_visible_media (showing);
        visible_count = showing.size;
    }

    public override bool filter (string search) {
        App.main_window.library_manager.search_medias (search);
        var result = App.main_window.library_manager.get_search_result ();

        media.clear ();
        foreach (var m in playlist.medias) {
            if (m in result) {
                media.add (m);
            }
        }

        filter_changed (); // will filter according to the columns, and set the final list

        return visible_count > 0;
    }
}
