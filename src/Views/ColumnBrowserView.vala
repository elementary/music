/**
* View that displays media in a list, filtered with a {@link Noise.MusicColumnBrowser}
*/
public class Noise.ColumnBrowserView : View {
    public Playlist playlist { get; construct set; }
    public Gee.ArrayList<Media> media { get; set; }

    private int visible_count = 0;

    public MusicColumnBrowser column_browser { get; construct; }
    public MusicListView list_view { get; construct; }

    public TreeViewSetup tvs { get; construct; }

    public ColumnBrowserView (Playlist playlist, TreeViewSetup tvs) {
        Object (playlist: playlist, tvs: tvs);
    }

    construct {
        var saved_state_settings = new GLib.Settings ("io.elementary.music.saved-state");

        media = new Gee.ArrayList<Media> ();
        media.add_all (playlist.medias);

        column_browser = new MusicColumnBrowser ();
        column_browser.set_media (playlist.medias);
        column_browser.changed.connect (filter_changed);

        list_view = new MusicListView (tvs);
        list_view.set_media (playlist.medias);
        var scroll = new Gtk.ScrolledWindow (null, null);
        scroll.add (list_view);

        var vpane = new Gtk.Paned (Gtk.Orientation.VERTICAL);
        vpane.position = saved_state_settings.get_int ("column-browser-height");
        vpane.pack1 (column_browser, false, false);
        vpane.pack2 (scroll, true, false);

        add (vpane);

        destroy.connect (() => {
            saved_state_settings.set_int ("column-browser-height", vpane.position);
        });
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
