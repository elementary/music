/*-
 * Copyright (c) 2011-2012       Scott Ringwelski <sgringwe@mtu.edu>
 *
 * Originally Written by Scott Ringwelski for BeatBox Music Player
 * BeatBox Music Player: http://www.launchpad.net/beat-box
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

public class Noise.Plugins.CDView : Gtk.Grid {
    CDRomDevice dev;
    
    Gtk.EventBox main_event_box;
    Gtk.Grid main_grid;
    
    Gtk.Image album_image;
    
    Gtk.Label title;
    Gtk.Label author;
    
    Noise.StaticPlaylist cd_playlist;
    public CDViewWrapper cd_viewwrapper;
    
    public CDView (CDRomDevice d) {
        this.dev = d;
        cd_playlist = new Noise.StaticPlaylist ();
        cd_viewwrapper = new CDViewWrapper (cd_playlist);
        
        build_ui ();
        
        dev.initialized.connect (cd_initialised);
        
    }
    
    public void build_ui () {
        
        main_event_box = new Gtk.EventBox ();
        main_grid = new Gtk.Grid ();
        
        /* Content view styling */
        main_event_box.get_style_context ().add_class (Granite.StyleClass.CONTENT_VIEW);
        
        if ( cd_playlist.is_empty () == false) {
        }
        
        var default_pix = Icons.DEFAULT_ALBUM_ART.render_at_size (Icons.DEFAULT_ALBUM_ART_SIZE);
        default_pix = PixbufUtils.render_pixbuf_shadow (default_pix);
        
        album_image = new Gtk.Image.from_pixbuf (default_pix);
        album_image.halign = Gtk.Align.CENTER;
        album_image.valign = Gtk.Align.CENTER;
        album_image.set_alignment(0.5f, 1);
        
        title = new Gtk.Label ("");
        title.set_alignment(0.5f, 1);
        title.set_justify(Gtk.Justification.CENTER);
        Granite.Widgets.Utils.apply_text_style_to_label (Granite.TextStyle.H2, title);
        
        author = new Gtk.Label ("");
        author.set_alignment(0.5f, 1);
        author.set_justify(Gtk.Justification.CENTER);
        author.sensitive = false;
        Granite.Widgets.Utils.apply_text_style_to_label (Granite.TextStyle.H2, author);
        
        var fake_label_1 = new Gtk.Label ("");
        fake_label_1.set_hexpand (true);
        fake_label_1.set_vexpand (true);
        
        var fake_label_2 = new Gtk.Label ("");
        fake_label_2.set_hexpand (true);
        fake_label_2.set_vexpand (true);
        
        var fake_label_3 = new Gtk.Label ("");
        fake_label_3.set_hexpand (true);
        
        var import_grid = new Gtk.Grid ();
        var import_button = new Gtk.Button.with_label (_("Import"));
        import_button.set_alignment(1, 0);
        import_grid.attach (fake_label_3,  0, 0, 1, 1);
        import_grid.attach (import_button, 1, 0, 1, 1);
        
        main_grid.attach (fake_label_1,   0, 0, 1, 7);
        main_grid.attach (album_image,    1, 3, 1, 1);
        main_grid.attach (title,          2, 2, 1, 1);
        main_grid.attach (author,         3, 2, 1, 1);
        main_grid.attach (cd_viewwrapper, 2, 3, 2, 1);
        main_grid.attach (import_grid,    3, 4, 1, 1);
        main_grid.attach (fake_label_2,   4, 0, 1, 7);
        
        main_event_box.add (main_grid);
        this.attach (main_event_box,0,0,1,1);
        
        /* Create options */
        
        main_grid.set_hexpand (true);
        main_grid.set_row_spacing (6);
        main_grid.set_column_spacing (12);
        main_grid.set_margin_top (12);
        
        import_button.clicked.connect ( () => {dev.transfer_to_library (cd_playlist.medias);});
        
        show_all ();
    }
    
    public void cd_initialised () {
        cd_playlist.add_medias (dev.get_medias ());
        if ( cd_playlist.is_empty () == false) {
            var m = cd_playlist.medias.peek ();
            author.set_markup (m.get_display_album_artist (true));
            title.set_markup (m.get_display_album ());
            CoverartCache.instance.changed.connect (load_cover);
            load_cover ();
            if ((!String.is_empty (m.artist, true) || !String.is_empty (m.album_artist, true)) && !String.is_empty (m.album, true))
            NotificationManager.get_default ().search_cover (m);
        }
        show_all ();
    }
    
    private void load_cover () {
        var cover_pixbuf = CoverartCache.instance.get_cover (cd_playlist.medias.peek ());
        if (cover_pixbuf != null) {
            album_image.set_from_pixbuf (cover_pixbuf);
        }
    }
    
    public Granite.Widgets.WrapLabel create_title_label (string title) {
        var label = new Granite.Widgets.WrapLabel (title);
        label.set_justify(Gtk.Justification.LEFT);
        label.set_alignment(0, 0);
        label.set_hexpand (true);
        return label;
    }
    
    public Gtk.Label create_length_label (uint length) {
        var label = new Gtk.Label (TimeUtils.pretty_length_from_ms (length));
        label.set_justify(Gtk.Justification.RIGHT);
        return label;
    }
}
