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
            grid_view.refilter ();
        });
        grid_view.title = _("View as Albums");
        grid_view.id = "grid";
        grid_view.icon = new ThemedIcon ("view-grid-symbolic");
        add_view (grid_view);

        var list_view = new PlaylistView (App.main_window.library_manager.p_music);
        list_view.title = _("View as List");
        list_view.id = "list";
        list_view.icon = new ThemedIcon ("view-list-symbolic");
        add_view (list_view);

        show_all ();
    }
}
