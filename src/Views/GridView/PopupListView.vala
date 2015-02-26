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
 * Authored by: Victor Eduardo <victoreduardm@gmail.com>
 *              Scott Ringwelski <sgringwe@mtu.edu>
 */

public class Noise.PopupListView : Gtk.Dialog {

    public const int MIN_SIZE = 500;

    ViewWrapper view_wrapper;
    Gtk.Image album_cover;
    Gtk.Label album_label;
    Gtk.Label artist_label;
    
    Gtk.Menu cover_action_menu;
    Gtk.MenuItem cover_set_new;
    
    Granite.Widgets.Rating rating;
    GenericList list_view;

    Gee.TreeSet<Media> media_list = new Gee.TreeSet<Media> ();
    
    public PopupListView (GridView grid_view) {
        this.delete_event.connect (hide_on_delete);
        window_position = Gtk.WindowPosition.CENTER_ON_PARENT;

        // window stuff
        has_resize_grip = false;
        resizable = false;

        this.view_wrapper = grid_view.parent_view_wrapper;
        
        set_transient_for (App.main_window);
        App.main_window.close_subwindows.connect (() => { this.hide_on_delete (); });
        destroy_with_parent = true;
        skip_taskbar_hint = true;
        
        // cover        
        album_cover = new Gtk.Image ();
        album_cover.margin_left = album_cover.margin_bottom = 12;
        
        Gtk.EventBox cover_event_box = new Gtk.EventBox ();
        cover_event_box.add (album_cover);
        
        cover_action_menu = new Gtk.Menu ();
      
        cover_set_new = new Gtk.MenuItem.with_label (_("Set new album cover"));
        cover_set_new.activate.connect (() => { this.set_new_cover(); });
        
        cover_action_menu.append (cover_set_new);
        cover_action_menu.show_all ();
        
        cover_event_box.button_press_event.connect (show_cover_context_menu);
        
        // album artist/album labels
        album_label = new Gtk.Label ("");
        artist_label = new Gtk.Label ("");

        album_label.get_style_context ().add_class ("h2"); 

        album_label.ellipsize = Pango.EllipsizeMode.END;
        artist_label.ellipsize = Pango.EllipsizeMode.END;

        album_label.set_line_wrap (false);
        artist_label.set_line_wrap (false);
        
        album_label.set_max_width_chars (30);
        artist_label.set_max_width_chars (30);

        album_label.margin_left = album_label.margin_right = 12;
        artist_label.margin_bottom = 12;

        // Music List
        var tvs = new TreeViewSetup (ListColumn.ARTIST, Gtk.SortType.ASCENDING, ViewWrapper.Hint.ALBUM_LIST);
        list_view = new MusicListView (view_wrapper, tvs);
        list_view.set_search_func (view_search_func);

        list_view.expand = true;
        
        var list_view_scrolled = new Gtk.ScrolledWindow (null, null);
        list_view_scrolled.add (list_view);

        // Rating widget
        rating = new Granite.Widgets.Rating (true, Gtk.IconSize.MENU, true);
        // customize rating
        rating.star_spacing = 16;
        rating.margin_top = rating.margin_bottom = 16;

        // Add everything
        Gtk.Box content = get_content_area () as Gtk.Box;
        Gtk.Box header = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        Gtk.Box artist = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

        artist.pack_start (artist_label, false, true, 0);
        artist.pack_start (album_label, false, true, 0);

        header.pack_start (cover_event_box, false, false);
        header.pack_start (artist, true, false);        

        content.pack_start (header, false, true, 0);
        content.pack_start (list_view_scrolled, true, true, 0);
        content.pack_start (rating, false, true, 0);

        rating.rating_changed.connect (rating_changed);
    }

    /**
     * Resets the window
     */
    public void reset () {
        // clear labels
        set_title ("");
        album_label.set_label ("");
        artist_label.set_label ("");

        // clear treeview and media list
        list_view.get_selection ().unselect_all (); // Unselect rows
        media_list.clear ();
        list_view.set_media (media_list);

        album_cover.set_from_pixbuf (CoverartCache.instance.get_cover (new Media ("")));

        // Reset size request
        set_size (MIN_SIZE);
    }

    public bool show_cover_context_menu (Gtk.Widget sender, Gdk.EventButton evt) {
        if (evt.type == Gdk.EventType.BUTTON_PRESS && evt.button == 3)
            cover_action_menu.popup (null, null, null, evt.button, evt.time);
        
        return true;
    }

    public void set_parent_wrapper (ViewWrapper parent_wrapper) {
        this.view_wrapper = parent_wrapper;
        this.list_view.set_parent_wrapper (parent_wrapper);
    }

    public void set_album (Album album) {
        reset ();
        
        lock (media_list) {

            string name = album.get_display_name ();
            string artist = album.get_display_artist ();

            string title_format = C_("Title format used on Album View Popup: $ALBUM by $ARTIST", "%s by %s");
            set_title (title_format.printf (name, artist));
            
            
            show_album_cover (CoverartCache.instance.get_album_cover (album));
            album_label.set_label (name);
            artist_label.set_label (artist);
            
            // Make a copy. Otherwise the list won't work if some elements are
            // removed from the parent wrapper while the window is showing
            foreach (var m in album.get_media ()) {
                media_list.add (m);
            }

            list_view.set_media (media_list);

            // Search again to match the view wrapper's search
            list_view.do_search (App.main_window.searchField.text);
        }

        if (list_view.get_realized ())
            list_view.columns_autosize ();

        // Set rating
        update_album_rating ();
        view_wrapper.library.media_updated.connect (update_album_rating);
    }

    void show_album_cover (Gdk.Pixbuf pixbuf) {
        var cover_art_with_shadow = PixbufUtils.render_pixbuf_shadow (pixbuf);
        album_cover.set_from_pixbuf (cover_art_with_shadow);
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

    private void view_search_func (string search, Gee.HashMap<int, Media> table, Gee.HashMap<int, Media> showing) {
        int parsed_rating;
        string parsed_search_string;

        String.base_search_method (search, out parsed_rating, out parsed_search_string);

        bool rating_search = parsed_rating > 0;

        // If an external refiltering is going on, we cannot obey the column browser filter
        // because it wil be refreshed after this search based on the new 'showing' table
        // (populated by this method).
        int show_index = 0;
        foreach (var m in table) {
            if (rating_search) {
                if (m.rating == (uint) parsed_rating)
                    showing.set (show_index++, m);
            } else if (Search.match_string_to_media (m, parsed_search_string)) {
                showing.set (show_index++, m);
            }
        }
    }
    
    private void set_new_cover () {
        var file = new Gtk.FileChooserDialog (_("Open"), this, Gtk.FileChooserAction.OPEN,
            _("_Cancel"), Gtk.ResponseType.CANCEL, _("_Open"), Gtk.ResponseType.ACCEPT);

        var image_filter = new Gtk.FileFilter ();
        image_filter.set_filter_name (_("Image files"));
        image_filter.add_mime_type ("image/*");

        file.add_filter (image_filter);

        if (file.run () == Gtk.ResponseType.ACCEPT) {
            Gdk.Pixbuf pix = null;
            try {
                pix = new Gdk.Pixbuf.from_file (file.get_filename ());
            } catch (Error err) {
                debug ("Set new cover failed: %s", err.message); 
            }
            
            if (pix != null) {
                CoverartCache cache =  CoverartCache.instance;
                cache.changed.connect (() => { show_album_cover (cache.get_cover (media_list.to_array () [0])); });
                cache.cache_image_async.begin (media_list.to_array () [0], pix);
            }
        }
        
        file.destroy ();
    }

    /**
     * Force squared layout
     */
    public void set_size (int size) {
        this.set_size_request (size, -1);
        queue_resize ();
    }

    public override Gtk.SizeRequestMode get_request_mode () {
        return Gtk.SizeRequestMode.HEIGHT_FOR_WIDTH;
    }

    public override void get_preferred_height_for_width (int width,
                                                         out int minimum_height,
                                                         out int natural_height)
    {
        minimum_height = natural_height = width;
    }
}
