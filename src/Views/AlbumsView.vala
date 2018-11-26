// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012-2018 elementary LLC. (https://elementary.io)
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
 * Authored by: Scott Ringwelski <sgringwe@mtu.edu>
 *              Victor Eduardo <victoreduardm@gmail.com>
 */

public class Noise.AlbumsView : Gtk.Paned, ViewInterface {
    private FastGrid icon_view;

    private static AlbumListGrid? _popup = null;
    private AlbumListGrid popup_list_view {
        get {
            if (_popup == null) {
                _popup = new AlbumListGrid (parent_view_wrapper);
                pack2 (_popup, false, false);
            }

            return _popup;
        }
    }

    public ViewWrapper parent_view_wrapper { get; construct; }

    public AlbumsView (ViewWrapper view_wrapper) {
        Object (parent_view_wrapper: view_wrapper);
    }

    construct {
        icon_view = new FastGrid ();
        icon_view.compare_func = compare_func;
        icon_view.search_func = search_func;
        icon_view.set_columns (-1);
        icon_view.drag_begin.connect_after (on_drag_begin);
        icon_view.drag_data_get.connect (on_drag_data_get);
        icon_view.item_activated.connect (on_item_activated);

        var scroll = new Gtk.ScrolledWindow (null, null);
        scroll.set_policy (Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
        scroll.add (icon_view);

        orientation = Gtk.Orientation.HORIZONTAL;
        pack1 (scroll, true, false);

        show_all ();

        clear_objects ();
        queue_draw ();

        notify["scale-factor"].connect (() => {
            queue_draw ();
            queue_resize ();
        });

        parent_view_wrapper.library.search_finished.connect (() => {
            icon_view.research_needed = true;
        });

        Gtk.TargetEntry te = { "text/uri-list", Gtk.TargetFlags.SAME_APP, 0 };
        Gtk.drag_source_set (icon_view, Gdk.ModifierType.BUTTON1_MASK, { te }, Gdk.DragAction.COPY);
    }

    protected void clear_objects () {
        icon_view.set_table (new Gee.HashMap<int, Album> (), true);
    }

    protected Gee.Collection<Object> get_objects () {
        return icon_view.get_table ().values;
    }

    protected Gee.Collection<Object> get_visible_objects () {
        return icon_view.get_visible_table ().values;
    }

    private void on_item_activated (Gtk.TreePath? path) {
        if (path == null) {
            item_activated (null);
        }

        var obj = icon_view.get_object_from_index (path.get_indices ()[0]);
        item_activated (obj);
    }

    private void on_drag_begin (Gtk.Widget sender, Gdk.DragContext context) {
        debug ("drag begin");

        var selected_items = icon_view.get_selected_items ();

        if (selected_items.length () > 0) {
            var path = selected_items.nth_data (0);
            var obj = icon_view.get_object_from_index (path.get_indices ()[0]);
            var drag_icon = ((Album) obj).cover_icon;

            Gtk.drag_set_icon_gicon (context, drag_icon, 0, 0);
        }
    }

    private void on_drag_data_get (Gdk.DragContext context, Gtk.SelectionData selection_data, uint info, uint time_) {
        string[] uris = null;

        var selected_items = icon_view.get_selected_items ();

        if (selected_items.length () <= 0)
            return;

        // this code assumes only 1 item can be selected at a time
        var path = selected_items.nth_data (0);
        var obj = icon_view.get_object_from_index (path.get_indices ()[0]);

        if (obj == null)
            return;

        foreach (var m in get_selected_media (obj))
            uris += m.uri;

        if (uris != null)
            selection_data.set_uris (uris);
    }

    private ViewWrapper.Hint get_hint () {
        return parent_view_wrapper.hint;
    }

    private Gee.Collection<Media> get_visible_media () {
        var all_visible_media = new Gee.TreeSet<Media> ();

        foreach (var album in get_visible_albums ()) {
            var album_media = album.get_media ();
            all_visible_media.add_all (album_media);
        }

        return all_visible_media;
    }

    private Gee.Collection<Media> get_media () {
        var all_media = new Gee.TreeSet<Media> ();

        foreach (var album in get_albums ()) {
            var album_media = album.get_media ();
            all_media.add_all (album_media);
        }

        return all_media;
    }

    private Gee.Collection<Album> get_visible_albums () {
        return (Gee.Collection<Album>)get_visible_objects ();
    }

    private Gee.Collection<Album> get_albums () {
        return (Gee.Collection<Album>)get_objects ();
    }

    private void refilter () {
        icon_view.do_search ();
    }

    private void update_media (Gee.Collection<Media> media) {
        var medias_to_update = new Gee.TreeSet<Media> ();
        medias_to_update.add_all (media);
        var medias_to_add = new Gee.TreeSet<Media> ();
        var albums_to_remove = new Gee.TreeSet<Album> ();
        foreach (var m in medias_to_update) {
            if (m == null)
                continue;

            var album = m.album_info;
            if (album == null)
                continue;

            if (!album.is_compatible (m)) {
                medias_to_add.add (m);
                album.remove_media (m);
                if (album.is_empty == true) {
                    album.cover_rendered.disconnect (queue_draw);
                    album.notify["cover-icon"].disconnect (queue_draw);
                    albums_to_remove.add (album);
                }

            }
        }

        icon_view.remove_objects (albums_to_remove);
        add_media (medias_to_add);
        icon_view.research_needed = true;
    }

    private void set_media (Gee.Collection<Media> to_add) {
        clear_objects ();
        add_media (to_add);
    }

    // Check for already existing albums, only add the missing ones.
    private void add_media (Gee.Collection<Media> media) {
        var medias_to_add = new Gee.TreeSet<Media> ();
        medias_to_add.add_all (media);
        var albums_to_append = new Gee.TreeSet<Album> ();
        var albums = get_albums ();
        foreach (var m in medias_to_add) {
            var album = m.album_info;
            if (!(album in albums)) {
                albums_to_append.add (album);
                album.cover_rendered.connect (queue_draw);
                album.notify["cover-icon"].connect (queue_draw);
            }
        }

        if (albums_to_append.size <= 0)
            return;

        // Add new albums
        icon_view.add_objects (albums_to_append);
        icon_view.research_needed = true;
    }

    /* There is a special case. Let's say that we're removing
     * song1, song2 and song5 from Album X, and the album currently
     * contains song1, song2, song5, and song3. Then we shouldn't remove
     * the album because it still contains a song (song3).
     */
    private void remove_media (Gee.Collection<Media> to_remove) {
        var albums_to_remove = new Gee.TreeSet<Album> ();
        foreach (var m in to_remove) {
            if (m == null)
                continue;

            var album = m.album_info;
            if (album == null)
                continue;

            album.remove_media (m);
            if (album.is_empty == true) {
                album.cover_rendered.disconnect (queue_draw);
                album.notify["cover-icon"].disconnect (queue_draw);
                albums_to_remove.add (album);
            }
        }

        if (albums_to_remove.size <= 0)
            return;

        icon_view.remove_objects (albums_to_remove);
        icon_view.research_needed = true;
    }

    protected void item_activated (Object? object) {
        if (!App.main_window.initialization_finished)
            return;

        if (object == null) {
            popup_list_view.hide ();
            return;
        }

        var album = object as Album;
        return_if_fail (album != null);

        popup_list_view.view_wrapper = parent_view_wrapper;
        popup_list_view.set_album (album);
        popup_list_view.show_all ();
    }

    protected int compare_func (Object o_a, Object o_b) {
        var album_a = o_a as Album;
        var album_b = o_b as Album;

        // Check for null and keep being reflexive
        if (album_a == null)
            return album_b != null ? -1 : 0;

        if (album_b == null)
            return 1;

        int order = String.compare (album_a.get_display_artist (), album_b.get_display_artist ());

        if (order == 0)
            order = Compare.standard_unsigned (album_a.year, album_b.year);

        if (order == 0)
            order = String.compare (album_a.get_display_name (), album_b.get_display_name ());

        return order;
    }

    protected void search_func (Gee.HashMap<int, Object> showing) {
        var result = parent_view_wrapper.library.get_search_result ();
        var albums = new Gee.TreeSet<Album> ((a,b) => {
            int order = String.compare (a.get_display_name (), b.get_display_name ());
            if (order != 0) {
                return order;
            }

            order = String.compare (a.get_display_artist (), b.get_display_artist ());
            if (order != 0) {
                return order;
            }

            return (int) a.year - (int) b.year;
        });
        foreach (var m in result) {
            albums.add (m.album_info);
        }

        foreach (var album in albums) {
            showing.set (showing.size, album);
        }

        // If nothing will be shown, display the "no albums found" message.
        if (showing.size < 1) {
            App.main_window.view_stack.show_alert ();
        }
    }

    protected Gee.Collection<Media> get_selected_media (Object obj) {
        var album = obj as Album;
        return_val_if_fail (album != null, null);

        return album.get_media ();
    }
}
