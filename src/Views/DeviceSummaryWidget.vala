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

public class Noise.DeviceSummaryWidget : Gtk.EventBox {
    Device dev;
    private Gee.LinkedList<unowned Playlist> playlists { get; set; }
    
    Gtk.Grid main_grid;
    
    Gtk.Entry device_name_entry;
    Gtk.Switch auto_sync_switch;
    
    Gtk.CheckButton sync_music_check;
    Gtk.ComboBox sync_music_combobox;
    Gtk.ListStore music_list;
#if HAVE_PODCASTS
    Gtk.CheckButton sync_podcasts_check;
    Gtk.ComboBox sync_podcasts_combobox;
    Gtk.ListStore podcast_list;
#endif
    /*Gtk.CheckButton sync_audiobooks_check;
    Gtk.ComboBox sync_audiobooks_combobox;
    Gtk.ListStore audiobook_list;*/
    
    Gtk.Image device_image;
    SpaceWidget space_widget;
    
    int files_index;
    int music_index;
    int podcast_index;
    //int audiobook_index;
    
    public DeviceSummaryWidget (Device d) {
        this.dev = d;
        
        build_ui ();
    }
    
    public void build_ui () {
        playlists = new Gee.LinkedList<unowned Playlist> ();

        main_grid = new Gtk.Grid ();

        
        /* Content view styling */
        this.get_style_context ().add_class (Granite.StyleClass.CONTENT_VIEW);
        
        /* Create options */
        
        var content_grid = new Gtk.Grid ();
        content_grid.set_hexpand (true);
        content_grid.set_vexpand (true);
        content_grid.set_row_spacing (6);
        content_grid.set_column_spacing (12);
        content_grid.set_margin_top (12);
        
        var device_name_title_label = new Gtk.Label (dev.getDisplayName () ?? "");
        device_name_title_label.set_alignment (1, 0.5f);
        device_name_title_label.margin = 20;
        device_name_title_label.margin_right = 0;
        Granite.Widgets.Utils.apply_text_style_to_label (Granite.TextStyle.H1, device_name_title_label);
        
        var device_name_description_label = new Gtk.Label (dev.get_fancy_description () ?? "");
        device_name_description_label.set_alignment (0, 0.5f);
        Granite.Widgets.Utils.apply_text_style_to_label (Granite.TextStyle.H2, device_name_description_label);
        
        var device_name_label = new Gtk.Label (_("Device Name:"));
        device_name_label.set_alignment (1, 0.5f);
        
        device_name_entry = new Gtk.Entry ();
        device_name_entry.set_placeholder_text (_("Device Name"));
        
        var auto_sync_label = new Gtk.Label (_("Automatically sync when plugged in:"));
        auto_sync_label.set_alignment (1, 0.5f);
        
        auto_sync_switch = new Gtk.Switch ();
        var auto_sync_container = new Gtk.Grid ();
        auto_sync_container.attach (auto_sync_switch, 0, 0, 1, 1);
        
        var sync_options_label = new Gtk.Label (_("Sync:"));
        sync_options_label.set_alignment (1, 0.5f);
        
        sync_music_check = new Gtk.CheckButton ();
        sync_music_combobox = new Gtk.ComboBox ();
        music_list = new Gtk.ListStore (3, typeof(GLib.Object), typeof(string), typeof(Gdk.Pixbuf));
        
        /*sync_audiobooks_check = new Gtk.CheckButton ();
        sync_audiobooks_combobox = new Gtk.ComboBox ();
        audiobook_list = new Gtk.ListStore (3, typeof(GLib.Object), typeof(string), typeof(Gdk.Pixbuf));*/
        
#if HAVE_PODCASTS
        sync_podcasts_check = new Gtk.CheckButton ();
        sync_podcasts_combobox = new Gtk.ComboBox ();
        podcast_list = new Gtk.ListStore (3, typeof(GLib.Object), typeof(string), typeof(Gdk.Pixbuf));
#endif
        
        device_image = new Gtk.Image.from_gicon (dev.get_icon (), Gtk.IconSize.DIALOG);
        space_widget = new SpaceWidget (dev.get_capacity());

        setup_lists ();

        files_index = space_widget.add_item (_("Other Files"), 0, SpaceWidget.ItemColor.GREEN);
        music_index = space_widget.add_item (_("Music"), 0, SpaceWidget.ItemColor.BLUE);
        podcast_index = space_widget.add_item (_("Podcasts"), 0, SpaceWidget.ItemColor.PURPLE);
        //audiobook_index = space_widget.add_item (_("Audiobooks"), 0, SpaceWidget.ItemColor.GREEN);
        
        refresh_space_widget ();
        
        // device name box
        if (device_name_description_label.label == "") {
            content_grid.attach (device_name_title_label,       0, 0, 5, 1);
            device_name_title_label.set_alignment (0.5f, 0.5f);
        } else {
            content_grid.attach (device_name_title_label,       0, 0, 2, 1);
        }
        content_grid.attach (device_name_description_label, 2, 0, 3, 1);
        content_grid.attach (device_name_label,   1, 1, 1, 1);
        content_grid.attach (device_name_entry,   2, 1, 2, 1);
        content_grid.attach (auto_sync_label,     1, 2, 1, 1);
        content_grid.attach (auto_sync_container, 2, 2, 2, 1);
        content_grid.attach (sync_options_label,  1, 3, 1, 1);
        content_grid.attach (sync_music_check,    2, 3, 1, 1);
        content_grid.attach (sync_music_combobox, 3, 3, 1, 1);
        
#if HAVE_PODCASTS
        if(dev.supports_podcasts()) {
            content_grid.attach (sync_podcasts_check,    2, 4, 1, 1);
            content_grid.attach (sync_podcasts_combobox, 3, 4, 1, 1);
        }
#endif
        
        /*if(dev.supports_audiobooks()) {
            audiobookBox.attach(sync_audiobooks, false, false, 0);
            audiobookBox.attach(sync_audiobooks_combobox, false, false, 0);
        }*/
        
        /* Add fake label to be centered */
        
        var fake_label_a = new Gtk.Label ("");
        fake_label_a.set_hexpand (true);
        content_grid.attach (fake_label_a, 0, 0, 1, 1);
        
        var fake_label_b = new Gtk.Label ("");
        fake_label_b.set_hexpand (true);
        content_grid.attach (fake_label_b, 4, 0, 1, 1);

        /* Put it all together */
        
        main_grid.attach (content_grid, 0, 0, 1, 1);
        main_grid.attach (space_widget, 0, 1, 1, 1);
        main_grid.set_hexpand (true);
        main_grid.set_vexpand (true);

        /* Pack everything into the eventbox */
        this.add (main_grid);
        
        if (dev.getDisplayName () != "")
            device_name_entry.text = dev.getDisplayName ();
        
        refresh_lists();
        
        /* set initial values*/
        auto_sync_switch.active = dev.get_preferences ().sync_when_mounted;
        sync_music_check.active = dev.get_preferences ().sync_music;
#if HAVE_PODCASTS
        sync_podcasts_check.active = dev.get_preferences ().sync_podcasts;
#endif
        //syncAudiobooks.active = dev.get_preferences ().sync_audiobooks;
        
        if(dev.get_preferences ().sync_all_music || dev.get_preferences().music_playlist == null)
            sync_music_combobox.set_active (0);
        else {
            bool success = sync_music_combobox.set_active_id (dev.get_preferences().music_playlist.name);
            if (!success) {
                //NotificationManager.get_default ().doAlertNotification ("Missing Sync Playlist", "The playlist named <b>" + dev.get_preferences().music_playlist + "</b> is used to sync device <b>" + dev.getDisplayName() + "</b>, but could not be found.");
                dev.get_preferences ().music_playlist = null;
                dev.get_preferences ().sync_all_music = true;
                sync_music_combobox.set_active (0);
            }
        }

#if HAVE_PODCASTS
        if (dev.get_preferences ().sync_all_podcasts)
            sync_podcasts_combobox.set_active(0);

        else {
            bool success = sync_podcasts_combobox.set_active_id(dev.get_preferences().podcast_playlist);
            if (!success) {
                //NotificationManager.get_default ().doAlertNotification ("Missing Sync Playlist", "The playlist named <b>" + dev.get_preferences().podcast_playlist + "</b> is used to sync device <b>" + dev.getDisplayName() + "</b>, but could not be found.");
                dev.get_preferences ().podcast_playlist = "";
                dev.get_preferences ().sync_all_podcasts = true;
                sync_podcasts_combobox.set_active (0);
            }
        }
#endif

        /*if(dev.get_preferences().sync_all_audiobooks)
            audiobookDropdown.set_active(0);
        else {
            bool success = audiobookDropdown.set_active_id(dev.get_preferences().audiobook_playlist);
            if(!success) {
                //NotificationManager.get_default ().doAlertNotification ("Missing Sync Playlist", "The playlist named <b>" + dev.get_preferences().audiobook_playlist + "</b> is used to sync device <b>" + dev.getDisplayName() + "</b>, but could not be found.");
                dev.get_preferences().audiobook_playlist = "";
                dev.get_preferences().sync_all_audiobooks = true;
                audiobookDropdown.set_active(0);
            }
        }*/
        
        /* hop onto signals to save preferences */
        auto_sync_switch.notify["active"].connect (save_preferences);
        sync_music_check.toggled.connect (save_preferences);
#if HAVE_PODCASTS
        sync_podcasts_check.toggled.connect (save_preferences);
#endif
        //syncAudiobooks.toggled.connect (save_preferences);
        sync_music_combobox.changed.connect (save_preferences);
#if HAVE_PODCASTS
        sync_podcasts_combobox.changed.connect (save_preferences);
#endif
        //audiobookDropdown.changed.connect (save_preferences);
        
        device_name_entry.changed.connect (device_name_changed);
        space_widget.sync_clicked.connect (sync_clicked);
        dev.get_library ().file_operations_done.connect (sync_finished);
        libraries_manager.local_library.playlist_added.connect (() => {refresh_lists ();});
        libraries_manager.local_library.playlist_name_updated.connect (() => {refresh_lists ();});
        libraries_manager.local_library.playlist_removed.connect (() => {refresh_lists ();});
        libraries_manager.local_library.smartplaylist_added.connect (() => {refresh_lists ();});
        libraries_manager.local_library.smartplaylist_name_updated.connect (() => {refresh_lists ();});
        libraries_manager.local_library.smartplaylist_removed.connect (() => {refresh_lists ();});
        
        show_all ();
    }
    
    private void refresh_space_widget () {
        uint64 other_files_size = 0;
        uint64 music_size = 0;
#if HAVE_PODCASTS
        uint64 podcast_size = 0;
#endif
        //double audiobook_size = 0.0;


        foreach (var m in dev.get_library ().get_medias ()) {
            if (m != null)
                music_size += m.file_size;
        }
#if HAVE_PODCASTS
        foreach(int i in dev.get_podcasts ()) {
            podcast_size += lm.media_from_id(i).file_size;
        }
#endif

#if HAVE_PODCASTS
        // Get other used space
        other_files_size = dev.get_used_space () - music_size - podcast_size;
#else
        other_files_size = dev.get_used_space () - music_size;
#endif
        //foreach(int i in dev.get_audiobooks()) {
        //    audiobook_size += (double)(lm.media_from_id(i).file_size);
        //}
        
        space_widget.update_item_size (music_index, music_size);
#if HAVE_PODCASTS
        space_widget.update_item_size (podcast_index, podcast_size);
#endif
        space_widget.update_item_size (files_index, other_files_size);
        //spaceWidget.update_item_size (audiobook_index, audiobook_size);
    }
    
    private void setup_lists() {
        sync_music_combobox.set_model (music_list);
#if HAVE_PODCASTS
        sync_podcasts_combobox.set_model (podcast_list);
#endif
        //audiobookDropdown.set_model (audiobookList);
        
        sync_music_combobox.set_id_column (1);
#if HAVE_PODCASTS
        sync_podcasts_combobox.set_id_column (1);
#endif
        //audiobookDropdown.set_id_column(1);
        
        sync_music_combobox.set_row_separator_func (rowSeparatorFunc);
#if HAVE_PODCASTS
        sync_podcasts_combobox.set_row_separator_func (rowSeparatorFunc);
#endif
        //audiobookDropdown.set_row_separator_func(rowSeparatorFunc);
        
        var music_cell = new Gtk.CellRendererPixbuf ();
        sync_music_combobox.pack_start (music_cell, false);
        sync_music_combobox.add_attribute (music_cell, "pixbuf", 2);
#if HAVE_PODCASTS
        sync_podcasts_combobox.pack_start (music_cell, false);
        sync_podcasts_combobox.add_attribute (music_cell, "pixbuf", 2);
#endif
        //audiobookDropdown.pack_start (music_cell, false);
        //audiobookDropdown.add_attribute (music_cell, "pixbuf", 2);
        
        var cell = new Gtk.CellRendererText ();
        cell.ellipsize = Pango.EllipsizeMode.END;
        sync_music_combobox.pack_start (cell, true);
        sync_music_combobox.add_attribute (cell, "text", 1);
#if HAVE_PODCASTS
        sync_podcasts_combobox.pack_start (cell, true);
        sync_podcasts_combobox.add_attribute (cell, "text", 1);
#endif
        //audiobookDropdown.pack_start (cell, true);
        //audiobookDropdown.add_attribute (cell, "text", 1);
        
        sync_music_combobox.popup.connect (refresh_lists);
#if HAVE_PODCASTS
        sync_podcasts_combobox.popup.connect (refresh_lists);
#endif
        //audiobookDropdown.popup.connect (refreshLists);
        
        sync_music_combobox.set_button_sensitivity (Gtk.SensitivityType.ON);
#if HAVE_PODCASTS
        sync_podcasts_combobox.set_button_sensitivity (Gtk.SensitivityType.ON);
#endif
        //audiobookDropdown.set_button_sensitivity (SensitivityType.ON);
    }
    
    private bool rowSeparatorFunc (Gtk.TreeModel model, Gtk.TreeIter iter) {
        string sep = "";
        model.get (iter, 1, out sep);
        
        return sep == "<separator_item_unique_name>";
    }
    
    private void device_name_changed () {
        dev.setDisplayName (device_name_entry.text);
    }
    
    private void save_preferences () {
        var pref = dev.get_preferences ();
        
        pref.sync_when_mounted = auto_sync_switch.active;
        pref.sync_music = sync_music_check.active;
#if HAVE_PODCASTS
        pref.sync_podcasts = sync_podcasts_check.active;
#endif
        //pref.sync_audiobooks = syncAudiobooks.active;
        
        pref.sync_all_music = sync_music_combobox.get_active () == 0;

#if HAVE_PODCASTS
        pref.sync_all_podcasts = sync_podcasts_combobox.get_active () == 0;
#endif
        //pref.sync_all_audiobooks = audiobookDropdown.get_active () == 0;
        if (sync_music_combobox.get_active ()-2 >= 0)
            pref.music_playlist = playlists.get (sync_music_combobox.get_active ()-2);
        else
            pref.music_playlist = null;
#if HAVE_PODCASTS
        pref.podcast_playlist = libraries_manager.local_library.playlist_from_name (sync_podcasts_combobox.get_active_id ());
#endif
        //pref.audiobook_playlist = audiobookDropdown.get_active_id ();
        
        sync_music_combobox.sensitive = sync_music_check.active;
#if HAVE_PODCASTS
        sync_podcasts_combobox.sensitive = sync_podcasts_check.active;
#endif
        //audiobookDropdown.sensitive = syncAudiobooks.active;
        
        ((LocalLibrary)libraries_manager.local_library).dbu.save_device (pref);
    }
    
    public bool all_medias_selected () {
        return false;
    }
    
    public void refresh_lists () {
        message ("refreshing lists\n");
        
        string musicString = "";
        if (sync_music_combobox.get_active ()-2 >= 0) {
            musicString = playlists.get (sync_music_combobox.get_active ()-2).name;
        }
        
        playlists.clear ();
        
        music_list.clear ();
        
#if HAVE_PODCASTS
        string podcastString = sync_podcasts_combobox.get_active_id ();
        podcast_list.clear ();
#endif
        
        //string audiobookString = audiobookDropdown.get_active_id ();
        //audiobook_list.clear ();
        
        Gtk.TreeIter iter;
        
        /* add entire library options */
        music_list.append (out iter);
        music_list.set (iter, 0, null, 1, _("All Music"), 2, Icons.MUSIC.render(Gtk.IconSize.MENU));
#if HAVE_PODCASTS
        podcast_list.append (out iter);
        podcast_list.set (iter, 0, null, 1, _("All Podcasts"), 2, Icons.PODCAST.render(Gtk.IconSize.MENU));
#endif
        //audiobook_list.append(out iter);
        //audiobook_list.set(iter, 0, null, 1, "All Audiobooks");//, 2, Icons.audiobook_icon.render(IconSize.MENU, audiobookDropdown.get_style_context()));
        
        /* add separator */
        music_list.append (out iter);
        music_list.set (iter, 0, null, 1, "<separator_item_unique_name>");
#if HAVE_PODCASTS
        podcast_list.append (out iter);
        podcast_list.set (iter, 0, null, 1, "<separator_item_unique_name>");
#endif
        //audiobookList.append(out iter);
        //audiobookList.set(iter, 0, null, 1, "<separator_item_unique_name>");
        
        /* add all playlists */
        foreach (var p in libraries_manager.local_library.get_smart_playlists ()) {
            //bool music, podcasts, audiobooks;
            //test_media_types(lm.medias_from_smart_playlist(p.rowid), out music, out podcasts, out audiobooks);
            
            //if(music) {
                music_list.append (out iter);
                music_list.set (iter, 0, p, 1, p.name, 2, Icons.render_icon (p.icon.to_string (), Gtk.IconSize.MENU, null));
                playlists.add (p);
            //}
#if HAVE_PODCASTS
            //if(podcasts) {
                podcast_list.append (out iter);
                podcast_list.set (iter, 0, p, 1, p.name, 2, Icons.render_icon (p.icon.to_string (), Gtk.IconSize.MENU, null));
            //}
#endif
            //if(audiobooks) {
                //audiobook_list.append(out iter);
                //audiobook_list.set(iter, 0, p, 1, p.name, 2, smart_playlist_pix);
            //}
        }
        foreach (var p in libraries_manager.local_library.get_playlists ()) {
            //bool music, podcasts, audiobooks;
            //test_media_types(lm.medias_from_smart_playlist(p.rowid), out music, out podcasts, out audiobooks);
            if (p.read_only == false) {
            
            //if(music) {
                music_list.append(out iter);
                music_list.set(iter, 0, p, 1, p.name, 2, Icons.render_icon (p.icon.to_string (), Gtk.IconSize.MENU, null));
                playlists.add (p);
            //}
#if HAVE_PODCASTS
            //if(podcasts) {
                podcast_list.append(out iter);
                podcast_list.set(iter, 0, p, 1, p.name, 2, Icons.render_icon (p.icon.to_string (), Gtk.IconSize.MENU, null));
            //}
#endif
            //if(audiobooks) {
                //audiobook_list.append(out iter);
                //audiobook_list.set(iter, 0, p, 1, p.name, 2, playlist_pix);
            //}
            }
        }
        
        if (!sync_music_combobox.set_active_id (musicString))
            sync_music_combobox.set_active(0);
#if HAVE_PODCASTS
        if (!sync_podcasts_combobox.set_active_id (podcastString))
            sync_podcasts_combobox.set_active(0);
#endif
        //if(!audiobookDropdown.set_active_id(audiobookString))
        //    audiobookDropdown.set_active(0);
        
        message ("setting sensitivity\n");
        sync_music_combobox.sensitive = dev.get_preferences().sync_music;
#if HAVE_PODCASTS
        sync_podcasts_combobox.sensitive = dev.get_preferences().sync_podcasts;
#endif
        //audiobookDropdown.sensitive = dev.get_preferences().sync_audiobooks;
    }
    
    /*void test_media_types(Gee.Collection<int> items, out bool music, out bool podcasts, out bool audiobooks) {
        music = false;
        podcasts = false;
        audiobooks = false;
        
        if(items.size == 0) {
            music = true; podcasts = true; audiobooks = true;
            return;
        }
        
        foreach(int i in items) {
            if(!music && lm.media_from_id(i).mediatype == 0)
                music = true;
            if(!podcasts && lm.media_from_id(i).mediatype == 1)
                podcasts = true;
            if(!audiobooks && lm.media_from_id(i).mediatype == 2)
                audiobooks = true;
        }
    }*/
    
    private void sync_finished () {
        refresh_space_widget ();
        space_widget.set_sync_button_sensitive (true);
    }
    
    public void sync_clicked () {
        var list = new Gee.LinkedList<Media>();
        var pref = dev.get_preferences ();

        if (pref.sync_music) {
            if (pref.sync_all_music) {
                foreach (var s in libraries_manager.local_library.get_medias ()) {
                    if (s.mediatype == 0 && !s.isTemporary)
                        list.add (s);
                }
            }
            else {
                var p = pref.music_playlist;
                
                if (p != null) {
                    foreach (var m in p.medias) {
                        if (m != null && m.mediatype == 0)
                            list.add (m);
                    }
                }
                else {
                    NotificationManager.get_default ().doAlertNotification (_("Sync Failed"), _("The playlist named %s is used to sync device %s, but could not be found.").printf("<b>" + pref.music_playlist.name + "</b>", "<b>" + dev.getDisplayName() + "</b>"));
                    
                    pref.music_playlist = null;
                    pref.sync_all_music = true;
                    sync_music_combobox.set_active(0);
                    return;
                }
            }
        }

#if HAVE_PODCASTS
        if(pref.sync_podcasts) {
            if(pref.sync_all_podcasts) {
                foreach (var s in App.library_manager.media()) {
                    if (s != null && s.mediatype == 1 && !s.isTemporary)
                        list.add (s);
                }
            }
            else {
                GLib.Object p = pref.podcast_playlist;
                
                if(p != null) {
                    foreach(var s in p.medias ()) {
                        if(s.mediatype == 1 && !s.uri.has_prefix("http:/"))
                            list.add(i);
                    }
                }
                else {
                    NotificationManager.get_default ().doAlertNotification (_("Sync Failed"), _("The playlist named %s is used to sync device %s, but could not be found.").printf("<b>" + pref.podcast_playlist + "</b>", "<b>" + dev.getDisplayName() + "</b>"));
                    pref.podcast_playlist = "";
                    pref.sync_all_podcasts = true;
                    sync_music_combobox.set_active(0);
                    return;
                }
            }
        }
#endif

        /*if(pref.sync_audiobooks) {
            if(pref.sync_all_audiobooks) {
                foreach(var s in lm.media()) {
                    if(s.mediatype == 2 && !s.isTemporary)
                        list.add(s.rowid);
                }
            }
            else {
                GLib.Object p = pref.audiobook_playlist;
                
                if(p != null) {
                    foreach (var s in p.medias()) {
                        if(s.mediatype == 2)
                            list.add(i);
                    }
                }
                else {
                    NotificationManager.get_default ().doAlertNotification ("Sync Failed", "The playlist named <b>" + pref.audiobook_playlist + "</b> is used to sync device <b>" + dev.getDisplayName() + "</b>, but could not be found.");
                    pref.audiobook_playlist = "";
                    pref.sync_all_audiobooks = true;
                    sync_music_combobox.set_active(0);
                    return;
                }
            }
        }*/
        
        bool fits = dev.will_fit (list);
        if(!fits) {
            NotificationManager.get_default ().doAlertNotification (_("Cannot Sync"), _("Cannot sync device with selected sync settings. Not enough space on disk"));
        }
        else if(dev.get_library ().doing_file_operations ()) {
            NotificationManager.get_default ().doAlertNotification (_("Cannot Sync"), _("Device is already doing an operation."));
        }
        else {
            var found = new Gee.LinkedList<int>();
            var not_found = new Gee.LinkedList<Media>();
            libraries_manager.local_library.media_from_name (dev.get_library ().get_medias(), ref found, ref not_found);
            
            if(not_found.size > 0) { // hand control over to SWD
                SyncWarningDialog swd = new SyncWarningDialog(dev, list, not_found);
                swd.show();
            }
            else {
                space_widget.set_sync_button_sensitive(false);
                dev.synchronize ();
            }
        }
    }
}