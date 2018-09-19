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
 * Authored by: Victor Eduardo <victoreduardm@gmail.com>
 *              Scott Ringwelski <sgringwe@mtu.edu>
 */

public class Noise.AlbumListGrid : Gtk.Grid {
    public ViewWrapper view_wrapper { get; construct set; }

    private Album album;
    private Widgets.AlbumImage album_cover;
    private Gee.TreeSet<Media> media_list = new Gee.TreeSet<Media> ();
    private Gtk.Label album_label;
    private Gtk.Label artist_label;
    private Gtk.FlowBox album_list_box;
    private Gtk.Menu cover_action_menu;
    private Music.RatingWidget rating;

    public AlbumListGrid (ViewWrapper view_wrapper) {
        Object (view_wrapper: view_wrapper);
    }

    construct {
        album_cover = new Widgets.AlbumImage ();
        album_cover.width_request = 184;
        album_cover.margin_top = 31;

        var cover_event_box = new Gtk.EventBox ();
        cover_event_box.add (album_cover);

        var cover_box_child = new Gtk.FlowBoxChild ();
        cover_box_child.can_focus = false;
        cover_box_child.add (cover_event_box);

        var cover_set_new = new Gtk.MenuItem.with_label (_("Set new album cover"));

        cover_action_menu = new Gtk.Menu ();
        cover_action_menu.append (cover_set_new);
        cover_action_menu.show_all ();

        album_label = new Gtk.Label ("");
        album_label.halign = Gtk.Align.START;
        album_label.margin_start = album_label.margin_end = 12;
        album_label.max_width_chars = 30;
        album_label.wrap = true;
        album_label.xalign = 0;
        album_label.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);

        artist_label = new Gtk.Label ("");
        artist_label.halign = Gtk.Align.START;
        artist_label.margin_start = artist_label.margin_end = 12;
        artist_label.max_width_chars = 30;
        artist_label.wrap = true;
        artist_label.xalign = 0;
        artist_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        var title_grid = new Gtk.Grid ();
        title_grid.halign = Gtk.Align.CENTER;
        title_grid.valign = Gtk.Align.CENTER;
        title_grid.attach (album_label, 0, 0);
        title_grid.attach (artist_label, 0, 1);

        var title_grid_child = new Gtk.FlowBoxChild ();
        title_grid_child.can_focus = false;
        title_grid_child.add (title_grid);

        var title_flow_box = new Gtk.FlowBox ();
        title_flow_box.margin_start = title_flow_box.margin_end = 19;
        title_flow_box.max_children_per_line = 2;
        title_flow_box.row_spacing = 12;
        title_flow_box.add (cover_box_child);
        title_flow_box.add (title_grid_child);

        var title_size_group = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);
        title_size_group.add_widget (cover_event_box);
        title_size_group.add_widget (title_grid);

        album_list_box = new Gtk.FlowBox ();
        album_list_box.homogeneous = true;
        album_list_box.valign = Gtk.Align.START;
        album_list_box.expand = true;
        album_list_box.get_style_context ().add_class (Gtk.STYLE_CLASS_BACKGROUND);
        album_list_box.set_sort_func ((Gtk.FlowBoxSortFunc) compare_rows);

        var list_view_scrolled = new Gtk.ScrolledWindow (null, null);
        list_view_scrolled.margin_top = 18;
        list_view_scrolled.add (album_list_box);

        rating = new Music.RatingWidget (true, Gtk.IconSize.MENU, true);
        rating.star_spacing = 12;
        rating.margin_bottom = rating.margin_top = 12;

        attach (title_flow_box, 0, 0);
        attach (list_view_scrolled, 0, 1);
        attach (rating, 0, 2);

        // FIXME: media menu currently needs a generic list
        //var media_menu = new Noise.MediaMenu ();

        cover_event_box.button_press_event.connect (show_cover_context_menu);
        cover_set_new.activate.connect (set_new_cover);
        rating.rating_changed.connect (rating_changed);

        album_list_box.child_activated.connect ((row) => {
            App.player.clear_queue ();
            App.player.queue_medias (media_list);
            App.player.play_media (((AlbumListRow) row).media);
            App.player.start_playback ();
        });

        album_list_box.button_release_event.connect ((event) => {
            if (event.button == Gdk.BUTTON_SECONDARY) {
                //media_menu.popup_media_menu (media_list);
                return true;
            }
            return false;
        });
    }

    /**
     * Resets the window
     */
    public void reset () {
        album_label.set_label ("");
        artist_label.set_label ("");
        media_list.clear ();

        foreach (Gtk.Widget child in album_list_box.get_children ()) {
            child.destroy ();
        }

        if (album != null) {
            album.notify["cover-icon"].disconnect (update_album_cover);
        }
    }

    public bool show_cover_context_menu (Gtk.Widget sender, Gdk.EventButton evt) {
        if (evt.type == Gdk.EventType.BUTTON_PRESS) {
            cover_action_menu.popup_at_pointer (evt);
        }
        return true;
    }

    public void set_album (Album album) {
        reset ();
        this.album = album;
        lock (media_list) {
            string name = album.get_display_name ();
            string artist = album.get_display_artist ();

            album_label.set_label (name);
            artist_label.set_label (artist);
            update_album_cover ();
            album.notify["cover-icon"].connect (update_album_cover);

            // Make a copy. Otherwise the list won't work if some elements are
            // removed from the parent wrapper while the window is showing
            foreach (var media in album.get_media ()) {
                media_list.add (media);
                album_list_box.add (new AlbumListRow (media));
            }

            // Search again to match the view wrapper's search
            //list_view.do_search (App.main_window.search_entry.text);
        }

        // Set rating
        update_album_rating ();
        view_wrapper.library.media_updated.connect (update_album_rating);
    }

    void update_album_cover () {
        if (album.cover_icon != null) {
            album_cover.image.gicon = album.cover_icon;
        } else {
            album_cover.image.gicon = null;
        }
    }

    void update_album_rating () {
        // We don't want to set the overall_rating as each media's rating.
        // See rating_changed() in case you want to figure out what would happen.
        rating.rating_changed.disconnect (rating_changed);

        // Use average rating for the album
        int total_rating = 0, n_media = 0;
        foreach (var media in media_list) {
            if (media == null)
                continue;
            n_media ++;
            total_rating += (int)media.rating;
        }

        float average_rating = (float)total_rating / (float)n_media;

        // fix approximation and set new rating
        rating.rating = (int) GLib.Math.roundf (average_rating);

        // connect again ...
        rating.rating_changed.connect (rating_changed);
    }

    void rating_changed (int new_rating) {
        var updated = new Gee.LinkedList<Media> ();
        lock (media_list) {

            foreach (var media in media_list) {
                if (media == null)
                    continue;

                media.rating = (uint)new_rating;
                updated.add (media);
            }

        }

        view_wrapper.library.update_medias (updated, false, true);
    }

    private void view_search_func (string search, Gee.ArrayList<Media> table, Gee.ArrayList<Media> showing) {
        uint parsed_rating;
        string parsed_search_string;

        String.base_search_method (search, out parsed_rating, out parsed_search_string);

        bool rating_search = parsed_rating != 0;

        // If an external refiltering is going on, we cannot obey the column browser filter
        // because it wil be refreshed after this search based on the new 'showing' table
        // (populated by this method).
        foreach (var m in table) {
            if (rating_search) {
                if (m.rating == (uint) parsed_rating) {
                    showing.add (m);
                }
            } else if (Search.match_string_to_media (m, parsed_search_string)) {
                showing.add (m);
            }
        }
    }

    private void set_new_cover () {
        var image_filter = new Gtk.FileFilter ();
        image_filter.set_filter_name (_("Image files"));
        image_filter.add_mime_type ("image/*");

        var file = new Gtk.FileChooserDialog (
            _("Open"), App.main_window, Gtk.FileChooserAction.OPEN,
            _("_Cancel"), Gtk.ResponseType.CANCEL,
            _("_Open"), Gtk.ResponseType.ACCEPT
        );
        file.add_filter (image_filter);

        if (file.run () == Gtk.ResponseType.ACCEPT) {
            album.save_cover_file (file.get_file ());
        }

        file.destroy ();
    }

    private static int compare_rows (Gtk.FlowBoxChild a, Gtk.FlowBoxChild b) {
        var tracka = (((AlbumListRow)a).media.track);
        var trackb = (((AlbumListRow)b).media.track);

        if (tracka > trackb) {
            return 1;
        } else {
            return -1;
        }
    }
}
