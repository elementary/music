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

public class Noise.AlbumsView : View {
    private Gtk.Paned hpaned;
    private FastGrid icon_view;

    private AlbumListGrid? _popup = null;
    private AlbumListGrid popup_list_view {
        get {
            if (_popup == null) {
                _popup = new AlbumListGrid ();
                hpaned.pack2 (_popup, false, false);
            }
            return _popup;
        }
        set {
            _popup = value;
        }
    }

    public Gee.Collection<Media> media_coll { get; construct set; }

    public AlbumsView (Gee.Collection<Media> media) {
        Object (media_coll: media);
    }

    construct {
        icon_view = new FastGrid ();
        icon_view.set_compare_func (compare_func);
        icon_view.set_columns (-1);
        icon_view.drag_begin.connect_after (on_drag_begin);
        icon_view.drag_data_get.connect (on_drag_data_get);
        icon_view.item_activated.connect (on_item_activated);

        set_media (media_coll);

        var scroll = new Gtk.ScrolledWindow (null, null);
        scroll.set_policy (Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
        scroll.add (icon_view);

        hpaned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
        hpaned.pack1 (scroll, true, false);

        add (hpaned);
        show_all ();

        clear_objects ();
        reset_pixbufs ();

        notify["scale-factor"].connect (() => {
            reset_pixbufs ();
            queue_resize ();
        });

        setup_focus ();

        Gtk.TargetEntry te = { "text/uri-list", Gtk.TargetFlags.SAME_APP, 0 };
        Gtk.drag_source_set (icon_view, Gdk.ModifierType.BUTTON1_MASK, { te }, Gdk.DragAction.COPY);
    }

    protected void add_objects (Gee.Collection<Object> objects) {
        icon_view.add_objects (objects);
    }

    protected void remove_objects (Gee.Collection<Object> objects) {
        icon_view.remove_objects (objects);
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
        if (path == null)
            item_activated (null);

        var obj = icon_view.get_object_from_index (path.get_indices ()[0]);
        item_activated (obj);
    }

    private void on_drag_begin (Gtk.Widget sender, Gdk.DragContext context) {
        debug ("drag begin");

        var selected_items = icon_view.get_selected_items ();

        if (selected_items.length () > 0)  {
            var path = selected_items.nth_data (0);
            var obj = icon_view.get_object_from_index (path.get_indices ()[0]);
            var drag_icon = get_icon (obj);
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

    public void reset_pixbufs () {
        queue_draw ();
    }

    public void setup_focus () {
        var focus_blacklist = new Gee.LinkedList<Gtk.Widget> ();
        focus_blacklist.add (App.main_window.view_selector);
        focus_blacklist.add (App.main_window.search_entry);
        focus_blacklist.add (App.main_window.source_list_view);
        focus_blacklist.add (App.main_window.statusbar);

        foreach (var w in focus_blacklist) {
            w.add_events (Gdk.EventMask.BUTTON_PRESS_MASK);
        }
    }

    public Gee.Collection<Media> get_visible_media () {
        var all_visible_media = new Gee.TreeSet<Media> ();

        foreach (var album in get_visible_albums ()) {
            var album_media = album.get_media ();
            all_visible_media.add_all (album_media);
        }

        return all_visible_media;
    }

    public Gee.Collection<Media> get_media () {
        var all_media = new Gee.TreeSet<Media> ();

        foreach (var album in get_albums ()) {
            var album_media = album.get_media ();
            all_media.add_all (album_media);
        }

        return all_media;
    }

    public Gee.Collection<Album> get_visible_albums () {
        return (Gee.Collection<Album>)get_visible_objects ();
    }

    public Gee.Collection<Album> get_albums () {
        return (Gee.Collection<Album>)get_objects ();
    }

    public void update_media (Gee.Collection<Media> media) {
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

        remove_objects (albums_to_remove);
        add_media (medias_to_add);
        request_filtering ();
    }

    public void set_media (Gee.Collection<Media> to_add) {
        clear_objects ();
        add_media (to_add);
    }

    // Check for already existing albums, only add the missing ones.
    public void add_media (Gee.Collection<Media> media) {
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
        add_objects (albums_to_append);
        request_filtering ();
    }

    /* There is a special case. Let's say that we're removing
     * song1, song2 and song5 from Album X, and the album currently
     * contains song1, song2, song5, and song3. Then we shouldn't remove
     * the album because it still contains a song (song3).
     */
    public void remove_media (Gee.Collection<Media> to_remove) {
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

        remove_objects (albums_to_remove);
        request_filtering ();
    }

    public int get_relative_id () {
        return -1;
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

        popup_list_view.set_album (album);
        popup_list_view.show_all ();
    }

    protected GLib.Icon? get_icon (Object o) {
        var album = o as Album;
        return_val_if_fail (album != null, null);
        return album.cover_icon;
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

    protected Gee.Collection<Media> get_selected_media (Object obj) {
        var album = obj as Album;
        return_val_if_fail (album != null, null);

        return album.get_media ();
    }

    public override void update_alert (Granite.Widgets.AlertView alert) {
        alert.title = _("No Albums Found.");
    }

    public override bool filter (string search) {
        // TODO: maybe handle search here, not in the library manager?
        App.main_window.library_manager.search_medias (search);
        var result = App.main_window.library_manager.get_search_result ();
        var albums = new Gee.TreeSet<Album> ();
        foreach (var m in result) {
            albums.add (m.album_info);
        }

        var showing = new Gee.HashMap<int, Album> ();
        foreach (var album in albums) {
            showing[showing.size] = album;
        }
        icon_view.set_visible_albums (showing);

        return result.size > 0;
    }
}
