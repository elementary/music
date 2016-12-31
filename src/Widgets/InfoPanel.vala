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
 * Authored by: Scott Ringwelski <sgringwe@mtu.edu>
 */

public class Noise.InfoPanel : Gtk.EventBox {
    public signal void to_update();

    public unowned Media current_media { get { return App.player.current_media; } }
    public bool can_show_up { get { return App.player.current_media != null; } }

    private Gtk.Label title;
    private Gtk.Label artist;
    private Noise.Widgets.AlbumImage coverArt;
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
        coverArt = new Widgets.AlbumImage ();
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
        title.halign = artist.halign = album.halign = year_label.halign = Gtk.Align.CENTER;

        // expand so that the rating can be set within the whole width.
        // The widget centers itself.
        rating.halign = Gtk.Align.FILL;

        content.row_spacing = 6;
        content.margin = 6;
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
        var cover_icon = current_media.album_info.cover_icon;
        if (cover_icon != null) {
            coverArt.gicon = cover_icon;
        } else {
            coverArt.gicon = new ThemedIcon ("albumart");
        }
    }
    
    private void ratingChanged (int new_rating) {
        if (current_media != null) {
            current_media.rating = new_rating;
            libraries_manager.local_library.update_media (current_media, false, true);
        }
    }
}
