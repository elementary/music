// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012 Noise Developers (http://launchpad.net/noise)
 *
 * This software is licensed under the GNU General Public License
 * (version 2 or later). See the COPYING file in this distribution.
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

public class Noise.GridView : ContentView, GridLayout {
    // The window used to present album contents
    private static PopupListView? _popup = null;
    public PopupListView popup_list_view {
        get {
            if (_popup == null) {
                _popup = new PopupListView (this);
                _popup.focus_out_event.connect ( () => {
                    if (_popup.visible && App.main_window.has_focus) {
                        _popup.show_all ();
                        _popup.present ();
                    }
                    return false;
                });
            }

            return _popup;
        }
    }

    /**
     * Hash map containing a set of albums identified by their album key.
     */
    private Gee.HashMap<string, Album> album_info;

    public GridView (ViewWrapper view_wrapper) {
        base (view_wrapper);

        album_info = new Gee.HashMap<string, Album> ();

        setup_focus ();

        CoverartCache.instance.changed.connect (queue_draw);

        message = String.escape (_("No Albums Found."));
    }

    public void setup_focus () {
        var focus_blacklist = new Gee.LinkedList<Gtk.Widget> ();
        focus_blacklist.add (App.main_window.viewSelector);
        focus_blacklist.add (App.main_window.searchField);
        focus_blacklist.add (App.main_window.source_list_view);
        focus_blacklist.add (App.main_window.statusbar);

        App.main_window.viewSelector.mode_changed.connect ( () => {
            popup_list_view.hide ();
        });

        foreach (var w in focus_blacklist) {
            w.add_events (Gdk.EventMask.BUTTON_PRESS_MASK);
            w.button_press_event.connect ( () => {
                popup_list_view.hide ();
                return false;
            });
        }
    }

    public ViewWrapper.Hint get_hint() {
        return parent_view_wrapper.hint;
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

    public void refilter (string? search) {
        do_search (search);
    }

    public string get_statusbar_text () {
        uint total_items = get_visible_objects ().size;

        if (total_items < 1)
            return "";

        var all_visible_media = get_visible_media ();

        uint64 total_size = 0, total_time = 0;

        foreach (var media in all_visible_media) {
            if (media != null) {
                total_time += media.length;
                total_size += media.file_size;
            }
        }

        string media_description = ngettext ("%u album", "%u albums", total_items).printf (total_items);
        string time_text = TimeUtils.time_string_from_miliseconds (total_time);
        string size_text = format_size (total_size);

        var statusbar_format = _(FULL_STATUSBAR_FORMAT);
        return statusbar_format.printf (media_description, time_text, size_text);
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
                album_info.unset (album.get_hashkey ());
                album.remove_media (m);
                if (album.is_empty == true) {
                    albums_to_remove.add (album);
                }

            }
        }

        remove_objects (albums_to_remove);
        add_media (medias_to_add);
        set_research_needed (true);
    }

    public void set_media (Gee.Collection<Media> to_add) {
        album_info.clear ();
        clear_objects ();
        add_media (to_add);
    }

    // Check for already existing albums, only add the missing ones.
    public void add_media (Gee.Collection<Media> media) {
        var medias_to_add = new Gee.TreeSet<Media> ();
        medias_to_add.add_all (media);
        var albums_to_append = new Gee.TreeSet<Album> ();
        lock (album_info) {
            foreach (var m in medias_to_add) {
                if (m == null)
                    continue;

                if (m.album_info != null)
                    continue;

                // Check if the song might go into an album.
                if (m.get_album_hashkey () in album_info.keys) {
                    var album = album_info.get (m.get_album_hashkey ());
                    album.add_media (m);
                }

                if (m.album_info == null) {
                    var album = new Album.from_media (m);
                    album.add_media (m);
                    album_info.set (album.get_hashkey (), album);
                    albums_to_append.add (album);
                }
            }
        }

        if (albums_to_append.size <= 0)
            return;

        // Add new albums
        add_objects (albums_to_append);
        set_research_needed (true);
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
            if (album.is_empty == true)
                albums_to_remove.add (album);

            album_info.unset (album.get_hashkey ());
        }

        if (albums_to_remove.size <= 0)
            return;

        remove_objects (albums_to_remove);
        set_research_needed (true);
    }

    public int get_relative_id () {
        return -1;
    }

    protected override void item_activated (Object? object) {
        if (!App.main_window.initialization_finished)
            return;

        if (object == null) {
            popup_list_view.hide ();
            return;
        }

        var album = object as Album;
        return_if_fail (album != null);

        popup_list_view.set_parent_wrapper (this.parent_view_wrapper);
        popup_list_view.set_album (album);

        // find window's location
        int x, y;
        Gtk.Allocation alloc;
        App.main_window.get_position (out x, out y);
        get_allocation (out alloc);

        // move down to icon view's allocation
        x += App.main_window.main_hpaned.position;
        y += alloc.y;

        int window_width = 0;
        int window_height = 0;
        
        popup_list_view.get_size (out window_width, out window_height);

        // center it on this icon view
        x += (alloc.width - window_width) / 2;
        y += (alloc.height - window_height) / 2 + 60;

        bool was_visible = popup_list_view.visible;
        if (!was_visible)
            popup_list_view.move (x, y);
        popup_list_view.show_all ();
        popup_list_view.present ();
    }

    protected override Value? val_func (int row, int column, Object o) {
        var album = o as Album;
        return_val_if_fail (album != null, null);

        switch (column) {
            case FastGrid.Column.PIXBUF:
                return get_pixbuf (o);

            case FastGrid.Column.TITLE:
                return album.get_display_name ();

            case FastGrid.Column.SUBTITLE:
                return album.get_display_artist ();

            case FastGrid.Column.TOOLTIP:
                string name = album.get_display_name ();
                string artist = album.get_display_artist ();
                return "<span size=\"large\"><b>%s</b></span>\n%s".printf (String.escape (name), String.escape (artist));
        }

        assert_not_reached ();
    }

    protected override Gdk.Pixbuf? get_pixbuf (Object o) {
        var album = o as Album;
        return_val_if_fail (album != null, null);

        // XXX: this is dangerous. Remember to update CoverartCache.get_album_key
        // to always match the key for the respective media. As explained in
        // Noise.Album and Noise.CoveartCache, these classes are supposed to
        // replace the current album-related media fields.
        return CoverartCache.instance.get_album_cover (album);
    }

    protected override int compare_func (Object o_a, Object o_b) {
        var album_a = o_a as Album;
        var album_b = o_b as Album;

        // Check for null and keep being reflexive
        if (album_a == null)
            return album_b != null ? -1 : 0;

        if (album_b == null)
            return 1;
        
        int order = String.compare (album_a.get_display_artist (), album_b.get_display_artist ());

        if (order == 0)
            order = Numeric.compare (album_a.year, album_b.year);

        if (order == 0)
            order = String.compare (album_a.get_display_name (), album_b.get_display_name ());

        return order;
    }


    protected override void search_func (string search, Gee.HashMap<int, Object> table, Gee.HashMap<int, Object> showing) {
        message_visible = false;
        var result = parent_view_wrapper.library.get_search_result ();
        int show_index = 0;

        if (result.size != parent_view_wrapper.library.get_medias ().size) {
            foreach (var o in table) {
                var album = o as Album;

                // Search in the album's media. After the first match found, we break
                // the loop because we know the album has (at least) one of the items
                // we want. Real search is done later by the popup list after an album
                // is selected.
                foreach (var m in album.get_media ()) {
                    if (m != null) {
                        if (result.contains (m)) {
                            showing.set (show_index++, album);
                            break;
                        }
                    }
                }
            }
        } else {
            foreach (var o in table) {
                var album = o as Album;
                // Search in the album's media. After the first match found, we break
                // the loop because we know the album has (at least) one of the items
                // we want. Real search is done later by the popup list after an album
                // is selected.
                foreach (var m in album.get_media ()) {
                    if (m != null) {
                        showing.set (show_index++, album);
                        break;
                    }
                }
            }
        }

        // If nothing will be shown, display the "no albums found" message.
        if (showing.size < 1) {
            message_visible = true;
        }
    }

    protected override Gee.Collection<Media> get_selected_media (Object obj) {
        var album = obj as Album;
        return_val_if_fail (album != null, null);

        return album.get_media ();
    }
}
