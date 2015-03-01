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

public class Noise.InfoPanel : Gtk.EventBox {
    public signal void to_update();

    public unowned Media current_media { get { return App.player.current_media; } }
    public bool can_show_up { get { return App.player.current_media != null; } }

    private Gtk.Label title;
    private Gtk.Label artist;
    private Gtk.Image coverArt;
    private Granite.Widgets.Rating rating;
    private Gtk.Label album;
    private Gtk.Label year_label;
    private int place = 1;
    private Gtk.Grid container;
    
    private const string TITLE_MARKUP = "<span size=\"large\"><b>%s</b></span>";


    public InfoPanel () {

        buildUI();

        App.player.media_played.connect_after (on_media_updated);
        libraries_manager.local_library.media_updated.connect_after (on_media_updated);
        NotificationManager.get_default ().update_track.connect (on_media_updated);
        CoverartCache.instance.changed.connect_after (update_cover_art);
    }
    
    public int add_view (Gtk.Widget view) {
        container.attach (view, 0, place, 1, 1);
        place++;
        return place-1;
    }
    
    private void buildUI () {
        // add View class
        this.get_style_context ().add_class (Granite.StyleClass.CONTENT_VIEW);
        
        container = new Gtk.Grid ();

        title = new Gtk.Label("");
        artist = new Gtk.Label("");
        coverArt = new Gtk.Image();
        rating = new Granite.Widgets.Rating (true, Gtk.IconSize.MENU, true); // centered = true
        album = new Gtk.Label("");
        year_label = new Gtk.Label("");

        /* ellipsize */
        title.set_hexpand (true);
        title.ellipsize = Pango.EllipsizeMode.END;
        artist.ellipsize = Pango.EllipsizeMode.END;
        album.ellipsize = Pango.EllipsizeMode.END;
        year_label.ellipsize = Pango.EllipsizeMode.END;

        var content = new Gtk.Grid ();
        content.get_style_context ().add_class (Granite.StyleClass.CONTENT_VIEW);

        // margins
        coverArt.halign = title.halign = artist.halign = album.halign = year_label.halign = Gtk.Align.CENTER;

        // expand so that the rating can be set within the whole width.
        // The widget centers itself.
        rating.halign = Gtk.Align.FILL;

        content.set_row_spacing (6);
        content.margin = 12;
        content.attach (coverArt, 0, 0, 1, 1);
        content.attach (title, 0, 1, 1, 1);
        content.attach (rating, 0, 2, 1, 1);
        content.attach (artist, 0, 3, 1, 1);
        content.attach (album, 0, 4, 1, 1);
        content.attach (year_label, 0, 5, 1, 1);

        container.attach (content, 0, 0, 1, 1);

        this.add (container);

        // signals here
        rating.rating_changed.connect (ratingChanged);

        update_visibilities();
    }

    private void update_visibilities () {
        // Don't show rating for external media
        bool hide_rating = true;

        if (current_media != null)
            hide_rating = current_media.isTemporary;

        rating.set_no_show_all (hide_rating);
        rating.set_visible (!hide_rating);

        to_update ();
    }

    private void on_media_updated () {
        update_visibilities ();
        update_metadata ();
        update_cover_art ();
    }

    private void update_metadata () {
        bool none = current_media == null;
        title.set_markup (none ? "" : Markup.printf_escaped (TITLE_MARKUP, current_media.get_display_title ()));
        artist.set_text (none ? "" : current_media.get_display_artist ());
        album.set_text (none ? "" : current_media.get_display_album ());

        // do rating stuff
        rating.rating = none ? 0 : (int)current_media.rating;

        var year = none ? 0 : current_media.year;
        var year_str = year > 0 ? "<span size=\"x-small\">" + year.to_string () + "</span>" : "";
        year_label.set_markup (year_str);
    }
    
    private void update_cover_art () {
        if (current_media != null) {
            var cover_art = CoverartCache.instance.get_cover (current_media);
            var cover_art_with_shadow = PixbufUtils.render_pixbuf_shadow (cover_art); 
            coverArt.set_from_pixbuf (cover_art_with_shadow);
        }
    }
    
    private void ratingChanged (int new_rating) {
        if (current_media != null) {
            current_media.rating = new_rating;
            libraries_manager.local_library.update_media (current_media, false, true);
        }
    }
}
