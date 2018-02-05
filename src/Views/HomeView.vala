/*-
 * Copyright (c) 2012-2017 elementary LLC. (https://elementary.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * The Noise authors hereby grant permission for non-GPL compatible
 * GStreamer plugins to be used and distributed together with GStreamer
 * and Noise. This permission is above and beyond the permissions granted
 * by the GPL license by which Noise is covered. If you modify this code
 * you may extend this exception to your version of the code, but you are not
 * obligated to do so. If you do not wish to do so, delete this exception
 * statement from your version.
 *
 * Authored by: Baptiste Gelez <baptiste@gelez.xyz>
 */
 
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
