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
    
    Gtk.Grid main_grid;
    
    Gtk.Entry device_name_entry;
    Gtk.Switch auto_sync_switch;
    
    Gtk.CheckButton sync_music_check;
    Gtk.ComboBox sync_music_combobox;
    Gtk.ListStore music_list;
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
        device_name_entry.placeholder_text = _("Device Name");

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
        //syncAudiobooks.active = dev.get_preferences ().sync_audiobooks;

        if(dev.get_preferences ().sync_all_music || dev.get_preferences().music_playlist == null)
            sync_music_combobox.set_active (0);
        else {
            bool success = sync_music_combobox.set_active_id (dev.get_preferences().music_playlist.name);
            if (!success) {
                //NotificationManager.get_default ().show_alert ("Missing Sync Playlist", "The playlist named <b>" + dev.get_preferences().music_playlist + "</b> is used to sync device <b>" + dev.getDisplayName() + "</b>, but could not be found.");
                dev.get_preferences ().music_playlist = null;
                dev.get_preferences ().sync_all_music = true;
                sync_music_combobox.set_active (0);
            }
        }

        /* hop onto signals to save preferences */
        auto_sync_switch.notify["active"].connect (save_preferences);
        sync_music_check.toggled.connect (save_preferences);
        sync_music_combobox.changed.connect (save_preferences);

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
        foreach (var m in dev.get_library ().get_medias ()) {
            if (m != null)
                music_size += m.file_size;
        }
        other_files_size = dev.get_used_space () - music_size;

        space_widget.update_item_size (music_index, music_size);
        space_widget.update_item_size (files_index, other_files_size);
        //spaceWidget.update_item_size (audiobook_index, audiobook_size);
    }

    private void setup_lists() {
        sync_music_combobox.set_model (music_list);
        sync_music_combobox.set_id_column (1);
        sync_music_combobox.set_row_separator_func (rowSeparatorFunc);

        var music_cell = new Gtk.CellRendererPixbuf ();
        sync_music_combobox.pack_start (music_cell, false);
        sync_music_combobox.add_attribute (music_cell, "pixbuf", 2);

        var cell = new Gtk.CellRendererText ();
        cell.ellipsize = Pango.EllipsizeMode.END;
        sync_music_combobox.pack_start (cell, true);
        sync_music_combobox.add_attribute (cell, "text", 1);
        sync_music_combobox.popup.connect (refresh_lists);
        sync_music_combobox.set_button_sensitivity (Gtk.SensitivityType.ON);
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
        pref.sync_all_music = sync_music_combobox.get_active () == 0;
        Gtk.TreeIter iter;
        if (sync_music_combobox.get_active ()-2 >= 0) {
            sync_music_combobox.get_active_iter (out iter);
            GLib.Value value;
            music_list.get_value (iter, 0, out value);
            pref.music_playlist = (Noise.Playlist)value.dup_object ();
        }

        sync_music_combobox.sensitive = sync_music_check.active;

        ((LocalLibrary)libraries_manager.local_library).dbu.save_device (pref);
    }

    public bool all_medias_selected () {
        return false;
    }

    public void refresh_lists () {
        message ("refreshing lists\n");

        Gtk.TreeIter iter;
        Playlist selected_playlist = null;
        if (sync_music_combobox.get_active ()-2 >= 0) {
            sync_music_combobox.get_active_iter (out iter);
            GLib.Value value;
            music_list.get_value (iter, 0, out value);
            selected_playlist = (Noise.Playlist)value.dup_object ();
        }

        music_list.clear ();

        /* add entire library options */
        music_list.append (out iter);
        music_list.set (iter, 0, null, 1, _("All Music"), 2, Icons.MUSIC.render(Gtk.IconSize.MENU));

        /* add separator */
        music_list.append (out iter);
        music_list.set (iter, 0, null, 1, "<separator_item_unique_name>");

        /* add all playlists */
        foreach (var p in libraries_manager.local_library.get_smart_playlists ()) {
            music_list.append (out iter);
            music_list.set (iter, 0, p, 1, p.name, 2, Icons.render_icon (p.icon.to_string (), Gtk.IconSize.MENU, null));
            if (selected_playlist == p) {
                sync_music_combobox.set_active_iter (iter);
            }
        }

        foreach (var p in libraries_manager.local_library.get_playlists ()) {
            if (p.read_only == false) {
                music_list.append (out iter);
                music_list.set (iter, 0, p, 1, p.name, 2, Icons.render_icon (p.icon.to_string (), Gtk.IconSize.MENU, null));
                if (selected_playlist == p) {
                    sync_music_combobox.set_active_iter (iter);
                }
            }
        }

        if (selected_playlist == null)
            sync_music_combobox.set_active(0);

        message ("setting sensitivity\n");
        sync_music_combobox.sensitive = dev.get_preferences().sync_music;
    }

    private void sync_finished () {
        refresh_space_widget ();
        space_widget.set_sync_button_sensitive (true);
    }
    
    public void sync_clicked () {
        var list = new Gee.TreeSet<Media>();
        var pref = dev.get_preferences ();

        if (pref.sync_music) {
            if (pref.sync_all_music) {
                foreach (var s in libraries_manager.local_library.get_medias ()) {
                    if (s.isTemporary == false)
                        list.add (s);
                }
            } else {
                var p = pref.music_playlist;
                
                if (p != null) {
                    foreach (var m in p.medias) {
                        if (m != null)
                            list.add (m);
                    }
                } else {
                    NotificationManager.get_default ().show_alert (_("Sync Failed"), _("The playlist named %s is used to sync device %s, but could not be found.").printf("<b>" + pref.music_playlist.name + "</b>", "<b>" + dev.getDisplayName() + "</b>"));
                    
                    pref.music_playlist = null;
                    pref.sync_all_music = true;
                    sync_music_combobox.set_active(0);
                    return;
                }
            }
        }
        
        bool fits = dev.will_fit (list);
        if (!fits) {
            NotificationManager.get_default ().show_alert (_("Cannot Sync"), _("Cannot sync device with selected sync settings. Not enough space on disk"));
        } else if(dev.get_library ().doing_file_operations ()) {
            NotificationManager.get_default ().show_alert (_("Cannot Sync"), _("Device is already doing an operation."));
        } else {
            var found = new Gee.TreeSet<int>();
            var not_found = new Gee.TreeSet<Media>();
            libraries_manager.local_library.media_from_name (dev.get_library ().get_medias(), found, not_found);
            
            if(not_found.size > 0) { // hand control over to SWD
                SyncWarningDialog swd = new SyncWarningDialog(dev, list, not_found);
                swd.show();
            } else {
                space_widget.set_sync_button_sensitive(false);
                dev.synchronize ();
            }
        }
    }
}
