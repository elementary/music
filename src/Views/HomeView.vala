/**
* The default view, showing all your local library
*/
public class Noise.HomeView : SwitchableView {
    construct {
        title = _("Music");
        icon = new ThemedIcon ("library-music");
        category = "library";
        id = "local/music";

        var media = App.main_window.library_manager.get_medias ();
        var grid_view = new AlbumsView (media);
        App.main_window.library_manager.media_added.connect ((media) => {
            grid_view.set_media (App.main_window.library_manager.get_medias ());
            // TODO: refilter
        });
        grid_view.title = _("View as Albums");
        grid_view.id = "grid";
        grid_view.icon = new ThemedIcon ("view-grid-symbolic");
        add_view (grid_view);

        var list_tvs = new TreeViewSetup (false, "library:main", App.main_window.library_manager.connection);
        var list_view = new PlaylistView (App.main_window.library_manager.p_music, list_tvs);
        list_view.title = _("View as List");
        list_view.id = "list";
        list_view.icon = new ThemedIcon ("view-list-symbolic");
        add_view (list_view);

        var col_tvs = new TreeViewSetup (false, "library:main", App.main_window.library_manager.connection);
        var column_browser = new ColumnBrowserView (App.main_window.library_manager.p_music, col_tvs);
        column_browser.title = _("View in Columns");
        column_browser.id = "column";
        column_browser.icon = new ThemedIcon ("view-column-symbolic");
        add_view (column_browser);

        show_all ();
    }
}
