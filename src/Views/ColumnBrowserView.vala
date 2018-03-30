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
* View that displays media in a list, filtered with a {@link Noise.MusicColumnBrowser}
*/
public class Noise.ColumnBrowserView : View {
    public Playlist playlist { get; construct set; }
    public Gee.ArrayList<Media> media { get; set; }

    private int visible_count = 0;

    public MusicColumnBrowser column_browser { get; construct; }
    public MusicListView list_view { get; construct; }

    public TreeViewSetup tvs { get; construct; }

    public Library library { get; construct; default = App.main_window.library_manager; }

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
        column_browser.row_activated.connect (() => {
            App.player.clear_queue ();
            var media = list_view.get_visible_table ();
            App.player.queue_medias (media);
            App.player.play_media (media.first ());
            App.player.start_playback ();
        });

        list_view = new MusicListView (tvs);
        list_view.set_media (playlist.medias);
        list_view.remove_request.connect ((media) => {
            var dialog = new RemoveFilesDialog (media);
            dialog.remove_media.connect ((delete_files) => {
                library.remove_medias (media, delete_files);
            });
        });
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
        library.search_medias (search);
        var result = library.get_search_result ();

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
