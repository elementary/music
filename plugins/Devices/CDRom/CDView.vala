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
 * Authored by: Corentin Noël <corentin@elementary.io>
 */

public class Noise.Plugins.CDView : View {
    public MusicListView list_view;
    public TreeViewSetup tvs;

    public CDRomDevice dev { get; construct set; }

    private Gtk.EventBox main_event_box;
    private Gtk.Grid main_grid;
    private Gtk.Label title_label;
    private Gtk.Label author_label;
    private Noise.StaticPlaylist cd_playlist;
    private Widgets.AlbumImage album_image;

    public CDView (CDRomDevice device) {
        Object (dev: device);
    }

    construct {
        title = _("Audio CD");
        id = dev.get_unique_identifier ();
        category = dev.get_unique_identifier ();
        icon = new ThemedIcon ("media-optical");

        album_image = new Widgets.AlbumImage ();
        album_image.image.gicon = new ThemedIcon ("albumart");
        album_image.halign = Gtk.Align.CENTER;
        album_image.valign = Gtk.Align.CENTER;

        title_label = new Gtk.Label ("");
        title_label.justify = Gtk.Justification.CENTER;
        title_label.valign = Gtk.Align.END;
        title_label.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);

        author_label = new Gtk.Label ("");
        author_label.justify = Gtk.Justification.CENTER;
        author_label.sensitive = false;
        author_label.valign = Gtk.Align.END;
        author_label.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);

        var fake_label_1 = new Gtk.Label ("");
        fake_label_1.set_hexpand (true);
        fake_label_1.set_vexpand (true);

        var fake_label_2 = new Gtk.Label ("");
        fake_label_2.set_hexpand (true);
        fake_label_2.set_vexpand (true);

        var fake_label_3 = new Gtk.Label ("");
        fake_label_3.set_hexpand (true);

        cd_playlist = new Noise.StaticPlaylist ();
        tvs = new TreeViewSetup.for_cdrom ();
        list_view = new MusicListView (tvs, true, false);

        // Do initial population. Further additions and removals will be handled
        // by the handlers connected below through connect_data_signals()
        list_view.set_media (cd_playlist.medias);

        cd_playlist.media_added.connect (on_playlist_media_added);
        cd_playlist.media_removed.connect (on_playlist_media_removed);
        cd_playlist.cleared.connect (on_playlist_cleared);

        var import_button = new Gtk.Button.with_label (_("Import"));
        import_button.halign = Gtk.Align.END;

        var import_grid = new Gtk.Grid ();
        import_grid.attach (fake_label_3,  0, 0, 1, 1);
        import_grid.attach (import_button, 1, 0, 1, 1);

        main_grid = new Gtk.Grid ();
        main_grid.hexpand = true;
        main_grid.column_spacing = 12;
        main_grid.row_spacing = 6;
        main_grid.margin_top = 12;
        main_grid.attach (fake_label_1, 0, 0, 1, 7);
        main_grid.attach (album_image, 1, 3, 1, 1);
        main_grid.attach (title_label, 2, 2, 1, 1);
        main_grid.attach (author_label, 3, 2, 1, 1);
        main_grid.attach (list_view, 2, 3, 2, 1);
        main_grid.attach (import_grid, 3, 4, 1, 1);
        main_grid.attach (fake_label_2, 4, 0, 1, 7);

        main_event_box = new Gtk.EventBox ();
        main_event_box.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        main_event_box.add (main_grid);

        add (main_event_box);

        import_button.clicked.connect (() => {
            dev.transfer_to_library (cd_playlist.medias);
        });

        show_all ();

        dev.initialized.connect (cd_initialised);
    }

    protected override void update_alert (Granite.Widgets.AlertView alert) {
        alert.icon_name = "dialog-error";
        alert.title = _("An Error Occured");
        alert.description = _("There was an error while loading this Audio CD.");
    }

    private void on_playlist_media_added (Gee.Collection<Media> to_add) {
        list_view.add_media (to_add);
    }

    private void on_playlist_media_removed (Gee.Collection<Media> to_remove) {
        list_view.remove_media (to_remove);
    }

    private void on_playlist_cleared () {
        list_view.set_media (new Gee.LinkedList<Media> ());
    }

    public void cd_initialised () {
        cd_playlist.add_medias (dev.get_medias ());
        if (cd_playlist.is_empty () == false) {
            var m = cd_playlist[0];
            author_label.set_markup (m.get_display_album_artist (true));
            title_label.set_markup (m.get_display_album ());
            load_cover ();
        }

        show_all ();
    }

    private void load_cover () {
        var cover_icon = cd_playlist[0].album_info.cover_icon;
        if (cover_icon != null) {
            album_image.image.gicon = cover_icon;
        }
    }

    public override bool filter (string search) {
        return !cd_playlist.is_empty ();
    }
}
