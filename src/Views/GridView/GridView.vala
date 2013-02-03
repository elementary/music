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

    private string TEXT_MARKUP = "%s\n<span foreground=\"#999\">%s</span>";
    private string TOOLTIP_MARKUP = "<span size=\"large\"><b>%s</b></span>\n%s";

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
        var all_visible_media = new Gee.LinkedList<Media> ();

        foreach (var album in get_visible_albums ()) {
            var album_media = album.get_media ();
            all_visible_media.add_all (album_media);
        }

        return all_visible_media;
    }

    public Gee.Collection<Media> get_media () {
        var all_media = new Gee.LinkedList<Media> ();

        foreach (var album in get_albums ()) {
            var album_media = album.get_media ();
            all_media.add_all (album_media);
        }

        return all_media;
    }

    public Gee.Collection<Album> get_visible_albums () {
        var album_list = new Gee.LinkedList<Album> ();
        foreach (var o in get_visible_objects ()) {
            var album = o as Album;
            if (album != null)
                album_list.add (album);
        }

        return album_list;
    }

    public Gee.Collection<Album> get_albums () {
        var album_list = new Gee.LinkedList<Album> ();
        foreach (var o in get_objects ()) {
            var album = o as Album;
            if (album != null)
                album_list.add (album);
        }

        return album_list;
    }

    private string get_key (Album? album) {
        return album != null ? album.to_string () : "";
    }

    public void refilter (string? search) {
        do_search (search);
    }

    public string get_statusbar_text () {
        uint total_items = get_visible_objects ().length ();

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
        refilter (null);
    }

    public void set_media (Gee.Collection<Media> to_add) {
        album_info = new Gee.HashMap<string, Album> ();
        clear_objects ();
        add_media (to_add);
    }

    // checks for duplicates
    public void add_media (Gee.Collection<Media> media) {
        // Albums to append. We use this to check for duplicates. In the end,
        // the map is supposed to only contain new albums.
        var albums_to_append = new Gee.HashMap<string, Album> ();

        foreach (var m in media) {
            if (m == null)
                continue;

            var album = new Album.from_media (m);
            string key = get_key (album);

            if (!albums_to_append.has_key (key) && !album_info.has_key (key)) {
                albums_to_append.set (key, album);

                // Add album to internal media info
                album_info.set (key, album);
            }

            // Now let's get the album again. We don't use the reference above because
            // we don't know if that is the actual instance which was added.
            var actual_album = album_info.get (key);
            if (!actual_album.contains (m))
                actual_album.add_media (m);
        }

        // Add new albums
        add_objects (albums_to_append.values);
    }

    public void remove_media (Gee.Collection<Media> to_remove) {
        /* There is a special case. Let's say that we're removing
         * song1, song2 and song5 from Album X, and the album currently
         * contains song1, song2, song5, and song3. Then we shouldn't remove
         * the album because it still contains a song (song3).
         */

        // classify media by album.
        var to_remove_album_info = new Gee.HashMap <string, Album> ();

        foreach (var m in to_remove) {
            if (m == null)
                continue;

            var album = new Album.from_media (m);            
            string key = get_key (album);

            if (!to_remove_album_info.has_key (key))
                to_remove_album_info.set (key, album);

            to_remove_album_info.get (key).add_media (m);
        }

        // table of albums that will be removed
        var albums_to_remove = new Gee.HashSet<string> ();

        // Then use the list to verify which albums are in the album view and try to remove
        // the songs which are part of to_remove_album_info from them. Eventually, if it
        // is found that the album is left empty, it is completely removed.
        foreach (var album_entry in to_remove_album_info.entries) {
            if (album_info.has_key (album_entry.key)) {
                // get current album. It contains all the media
                var current_album = album_info.get (album_entry.key);

                // Album containing the media that should be removed
                var to_remove_album = album_entry.value;
                var to_remove_album_media = to_remove_album.get_media ();

                // Now we will remove the media in to_remove_album from the actual album
                // contained by album_info.
                foreach (var m in to_remove_album_media)
                    current_album.remove_media (m);

                // if the album is left with no songs, it should be removed (we don't remove albums
                // that still contain media!)
                if (current_album.is_empty) {
                    albums_to_remove.add (album_entry.key);

                    // unset from album info
                    album_info.unset (album_entry.key);
                }
            }
        }

        if (albums_to_remove.size < 1)
            return;        

        // Find media representations in table
        var objects_to_remove = new Gee.HashSet<Object> ();

        foreach (var album in get_visible_albums ()) {
            var key = get_key (album);
            if (albums_to_remove.contains (key))
                objects_to_remove.add (album);
        }

        remove_objects (objects_to_remove);
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
        popup_list_view.show_all ();
        if (!was_visible)
            popup_list_view.move (x, y);
        popup_list_view.present ();
    }

    protected override Value? val_func (int row, int column, Object o) {
        var album = o as Album;
        return_val_if_fail (album != null, null);

        switch (column) {
            case FastGrid.Column.PIXBUF:
                // XXX: this is dangerous. Remember to update CoverartCache.get_album_key
                // to always match the key for the respective media. As explained in
                // Noise.Album and Noise.CoveartCache, these classes are supposed to
                // replace the current album-related media fields.
                return CoverartCache.instance.get_album_cover (album);

            case FastGrid.Column.MARKUP:
                string name = album.get_display_name ();
                string artist = album.get_display_artist ();

                if (name.length > 25)
                    name = name.substring (0, 21) + "…";
                if (artist.length > 25)
                    artist = artist.substring (0, 21) + "…";

                return Markup.printf_escaped (TEXT_MARKUP, name, artist);

            case FastGrid.Column.TOOLTIP:
                string name = album.get_display_name ();
                string artist = album.get_display_artist ();

                return Markup.printf_escaped (TOOLTIP_MARKUP, name, artist);
        }

        assert_not_reached ();
    }

    protected override int compare_func (Object o_a, Object o_b) {
        var album_a = o_a as Album;
        var album_b = o_b as Album;

        // Check for null and keep being reflexive
        if (album_a == null)
            return album_b != null ? -1 : 0;

        if (album_b == null)
            return 1;

        int order = String.compare (album_a.get_display_name (), album_b.get_display_name ());

        if (order == 0)
            order = String.compare (album_a.get_display_artist (), album_b.get_display_artist ());

        return order;
    }

    protected override void search_func (string search, HashTable<int, Object> table, ref HashTable<int, Object> showing) {
        message_visible = false;

        int parsed_rating;
        string parsed_search_string;

        base_search_method (search, out parsed_rating, out parsed_search_string);

        bool rating_search = parsed_rating > 0;

        int show_index = 0;
        for (int i = 0; i < table.size (); i++) {
            var album = table.get (i) as Album;
            if (album == null)
                continue;

            // Search in the album's media. After the first match found, we break
            // the loop because we know the album has (at least) one of the items
            // we want. Real search is done later by the popup list after an album
            // is selected.
            foreach (var m in album.get_media ()) {
                if (rating_search) {
                    if (m.rating == (uint) parsed_rating) {
                        showing.set (show_index++, album);
                        break; // we only need to add the album once.
                    }
                } else if (Search.match_string_to_media (m, parsed_search_string)) {
                    showing.set (show_index++, album);
                    break; // we only need to add the album once.
                }
            }
        }

        // If nothing will be shown, display the "no albums found" message.
        if (showing.size () < 1)
            message_visible = true;
    }
}
