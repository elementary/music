// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
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
 * Authored by: Corentin Noël <corentin@elementary.io>
 */

public class Noise.MediaEditor : Gtk.Dialog {
    public const int MIN_WIDTH = 600;
    public const int MIN_HEIGHT = 400;
    
    private Gtk.Entry title_entry;
    private Gtk.Entry artist_entry;
    private Gtk.Entry album_artist_entry;
    private Gtk.Entry album_entry;
    private Gtk.Entry genre_entry;
    private Gtk.Entry composer_entry;
    private Gtk.Entry grouping_entry;
    private Gtk.TextView comment_textview;
    private Gtk.ScrolledWindow comment_scrolledwindow;
    private Gtk.SpinButton track_spinbutton;
    private Gtk.SpinButton disk_spinbutton;
    private Gtk.SpinButton year_spinbutton;
    private Granite.Widgets.Rating rating_widget;

    private Gtk.Button previous_button;
    private Gtk.Button next_button;
    private Gtk.Button save_button;
    private Gtk.Button close_button;

    private Gee.TreeSet<Media> media_list;
    private Gee.HashMap<int64?, Media> temp_list;
    private Media current_media;

    public MediaEditor (Gee.TreeSet<Media> given_media) {
        Object (
            deletable: false,
            destroy_with_parent: true,
            height_request: MIN_HEIGHT,
            resizable: true,
            transient_for: App.main_window,
            width_request: MIN_WIDTH,
            window_position: Gtk.WindowPosition.CENTER_ON_PARENT
        );
        media_list.add_all (given_media);
        set_media (media_list.first ());
    }

    construct {
        media_list = new Gee.TreeSet<Media> ();
        temp_list = new Gee.HashMap<int64?, Media> ((Gee.HashDataFunc<int64?>)GLib.int64_hash, (Gee.EqualDataFunc<int64?>)GLib.int64_equal, null);

        var grid = new Gtk.Grid ();
        grid.expand = true;
        grid.margin_start = 12;
        grid.margin_end = 12;
        grid.column_spacing = 12;

        title_entry = new Gtk.Entry ();
        artist_entry = new Gtk.Entry ();
        album_artist_entry = new Gtk.Entry ();
        album_entry = new Gtk.Entry ();
        genre_entry = new Gtk.Entry ();
        composer_entry = new Gtk.Entry ();
        grouping_entry = new Gtk.Entry ();
        comment_textview = new Gtk.TextView ();
        comment_textview.set_wrap_mode (Gtk.WrapMode.WORD_CHAR);
        comment_scrolledwindow = new Gtk.ScrolledWindow (null, null);
        comment_scrolledwindow.set_policy (Gtk.PolicyType.EXTERNAL, Gtk.PolicyType.AUTOMATIC);
        comment_scrolledwindow.add (comment_textview);
        track_spinbutton = new Gtk.SpinButton.with_range (0, 500, 1);
        disk_spinbutton = new Gtk.SpinButton.with_range (0, 500, 1);
        var local_time = new DateTime.now_local ();
        year_spinbutton = new Gtk.SpinButton.with_range (0, local_time.get_year (), 1);
        rating_widget = new Granite.Widgets.Rating (false, Gtk.IconSize.MENU);
        rating_widget.hexpand = true;

        var comment_frame = new Gtk.Frame (null);
        comment_frame.expand = true;
        comment_frame.add (comment_scrolledwindow);

        grid.attach (new Granite.HeaderLabel (_("Title:")), 0, 0, 1, 1);
        grid.attach (title_entry, 0, 1, 1, 1);
        grid.attach (new Granite.HeaderLabel (_("Artist:")), 1, 0, 1, 1);
        grid.attach (artist_entry, 1, 1, 1, 1);
        grid.attach (new Granite.HeaderLabel (_("Album:")), 0, 2, 1, 1);
        grid.attach (album_entry, 0, 3, 1, 1);
        grid.attach (new Granite.HeaderLabel (_("Album Artist:")), 1, 2, 1, 1);
        grid.attach (album_artist_entry, 1, 3, 1, 1);
        grid.attach (new Granite.HeaderLabel (_("Composer:")), 0, 4, 1, 1);
        grid.attach (composer_entry, 0, 5, 1, 1);
        grid.attach (new Granite.HeaderLabel (_("Grouping:")), 1, 4, 1, 1);
        grid.attach (grouping_entry, 1, 5, 1, 1);
        grid.attach (new Granite.HeaderLabel (_("Genre:")), 0, 6, 1, 1);
        grid.attach (genre_entry, 0, 7, 1, 1);
        grid.attach (new Granite.HeaderLabel (_("Year:")), 1, 6, 1, 1);
        grid.attach (year_spinbutton, 1, 7, 1, 1);
        grid.attach (new Granite.HeaderLabel (_("Track:")), 1, 8, 1, 1);
        grid.attach (track_spinbutton, 1, 9, 1, 1);
        grid.attach (new Granite.HeaderLabel (_("Disk:")), 1, 10, 1, 1);
        grid.attach (disk_spinbutton, 1, 11, 1, 1);
        grid.attach (new Granite.HeaderLabel (_("Rating:")), 1, 12, 1, 1);
        grid.attach (rating_widget, 1, 13, 1, 1);
        grid.attach (new Granite.HeaderLabel (_("Comment:")), 0, 8, 1, 1);
        grid.attach (comment_frame, 0, 9, 1, 5);

        previous_button = new Gtk.Button.from_icon_name ("go-previous-symbolic");
        next_button = new Gtk.Button.from_icon_name ("go-next-symbolic");

        var arrows_grid = new Gtk.Grid ();
        arrows_grid.orientation = Gtk.Orientation.HORIZONTAL;
        arrows_grid.column_homogeneous = true;
        arrows_grid.get_style_context ().add_class (Gtk.STYLE_CLASS_LINKED);
        arrows_grid.add (previous_button);
        arrows_grid.add (next_button);

        save_button = new Gtk.Button.with_label (_("Save"));
        save_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        close_button  = new Gtk.Button.with_label (_("Close"));

        var buttons = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
        buttons.layout_style = Gtk.ButtonBoxStyle.END;
        buttons.spacing = 6;
        buttons.margin_top = 6;

        buttons.pack_start (arrows_grid, false, false, 0);
        buttons.pack_end (close_button, false, false, 0);
        buttons.pack_end (save_button, false, false, 0);
        buttons.set_child_secondary (arrows_grid, true);
        buttons.set_child_non_homogeneous (arrows_grid, true);
        grid.attach (buttons, 0, 14, 2, 1);

        var content = get_content_area () as Gtk.Container;
        content.add (grid);

        previous_button.clicked.connect (previous_track);
        next_button.clicked.connect (next_track);
        close_button.clicked.connect (() => destroy ());
        save_button.clicked.connect (save_and_exit);
    }

    private void previous_track () {
        var iterator = (Gee.BidirIterator<Media>) media_list.iterator_at (current_media);
        if (iterator.has_previous ()) {
            save_track ();
            iterator.previous ();
            set_media (iterator.get ());
        } else {
            previous_button.sensitive = false;
        }
    }

    private void next_track () {
        var iterator = media_list.iterator_at (current_media);
        if (iterator.has_next ()) {
            save_track ();
            iterator.next ();
            set_media (iterator.get ());
        } else {
            next_button.sensitive = false;
        }
    }

    private void save_track () {
        var m = current_media.copy ();
        m.title = title_entry.text;
        m.artist = artist_entry.text;
        m.album_artist = album_artist_entry.text;
        m.album = album_entry.text;
        m.genre = genre_entry.text;
        m.composer = composer_entry.text;
        m.grouping = grouping_entry.text;
        m.comment = comment_textview.buffer.text;
        m.track = (int) track_spinbutton.value;
        m.album_number = (int) disk_spinbutton.value;
        m.year = (int) year_spinbutton.value;
        m.rating = (uint) rating_widget.rating;
        temp_list.set (current_media.rowid, m);
    }

    // We create temporary media that will be saved once the save button is clicked.
    private void save_and_exit () {
        save_track ();
        foreach (var m in media_list) {
            if (temp_list.has_key (m.rowid)) {
                var copy = temp_list.get (m.rowid);
                m.title = copy.title;
                m.artist = copy.artist;
                m.album_artist = copy.album_artist;
                m.album = copy.album;
                m.genre = copy.genre;
                m.composer = copy.composer;
                m.grouping = copy.grouping;
                m.comment = copy.comment;
                m.track = copy.track;
                m.album_number = copy.album_number;
                m.year = copy.year;
                m.rating = copy.rating;
            }
        }

        media_list.clear ();
        current_media = null;
        temp_list.clear ();
        destroy ();
    }

    private void set_media (Media m) {
        current_media = m;
        var considered_media = current_media;
        if (temp_list.has_key (current_media.rowid)) {
            considered_media = temp_list.get (current_media.rowid);
        }

        title_entry.text = considered_media.title;
        artist_entry.text = considered_media.artist;
        album_artist_entry.text = considered_media.album_artist;
        album_entry.text = considered_media.album;
        genre_entry.text = considered_media.genre;
        composer_entry.text = considered_media.composer;
        grouping_entry.text = considered_media.grouping;
        comment_textview.buffer.text = considered_media.comment;
        track_spinbutton.value = considered_media.track;
        disk_spinbutton.value = considered_media.album_number;
        year_spinbutton.value = considered_media.year;
        rating_widget.rating = (int) considered_media.rating;
        var iterator = (Gee.BidirIterator<Media>) media_list.iterator_at (current_media);
        previous_button.sensitive = iterator.has_previous ();
        next_button.sensitive = iterator.has_next ();
    }
}
