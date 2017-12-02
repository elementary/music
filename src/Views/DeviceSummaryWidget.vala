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

public class Noise.DeviceSummaryWidget : Gtk.EventBox {
    Device dev;
    DevicePreferences preferences;

    Gtk.Grid main_grid;

    Gtk.Entry device_name_entry;
    Gtk.Switch auto_sync_switch;

    Gtk.CheckButton sync_music_check;
    Gtk.ComboBox sync_music_combobox;
    Gtk.ListStore music_list;

    Gtk.Image device_image;
    SpaceWidget space_widget;

    public DeviceSummaryWidget (Device d, DevicePreferences preferences) {
        this.dev = d;
        this.preferences = preferences;
        build_ui ();
    }

    public void build_ui () {
        main_grid = new Gtk.Grid ();

        /* Content view styling */
        this.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);

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
        device_name_title_label.get_style_context ().add_class (Granite.STYLE_CLASS_H1_LABEL);

        var device_name_description_label = new Gtk.Label (dev.get_fancy_description () ?? "");
        device_name_description_label.set_alignment (0, 0.5f);
        device_name_description_label.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
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
        music_list = new Gtk.ListStore (3, typeof (GLib.Object), typeof (string), typeof (GLib.Icon));

        device_image = new Gtk.Image.from_gicon (dev.get_icon (), Gtk.IconSize.DIALOG);

        space_widget = new SpaceWidget (dev.get_capacity());
        space_widget.valign = Gtk.Align.END;

        setup_lists ();

        space_widget.storagebar.update_block_size (Granite.Widgets.StorageBar.ItemDescription.OTHER, 0);
        space_widget.storagebar.update_block_size (Granite.Widgets.StorageBar.ItemDescription.AUDIO, 0);

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

        /* Pack everything into the eventbox */
        this.add (main_grid);

        if (dev.getDisplayName () != "")
            device_name_entry.text = dev.getDisplayName ();

        refresh_lists();

        /* set initial values*/
        auto_sync_switch.active = preferences.sync_when_mounted;
        sync_music_check.active = preferences.sync_music;

        if(preferences.sync_all_music || preferences.music_playlist == null)
            sync_music_combobox.set_active (0);
        else {
            bool success = sync_music_combobox.set_active_id (preferences.music_playlist.name);
            if (!success) {
                //NotificationManager.get_default ().show_alert ("Missing Sync Playlist", "The playlist named <b>" + preferences.music_playlist + "</b> is used to sync device <b>" + dev.getDisplayName() + "</b>, but could not be found.");
                preferences.music_playlist = null;
                preferences.sync_all_music = true;
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

        space_widget.storagebar.update_block_size (Granite.Widgets.StorageBar.ItemDescription.OTHER, other_files_size);
        space_widget.storagebar.update_block_size (Granite.Widgets.StorageBar.ItemDescription.AUDIO, music_size);
    }

    private void setup_lists() {
        sync_music_combobox.set_model (music_list);
        sync_music_combobox.set_id_column (1);
        sync_music_combobox.set_row_separator_func (rowSeparatorFunc);

        var music_cell = new Gtk.CellRendererPixbuf ();
        music_cell.stock_size = Gtk.IconSize.MENU;
        sync_music_combobox.pack_start (music_cell, false);
        sync_music_combobox.add_attribute (music_cell, "gicon", 2);


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
        preferences.sync_when_mounted = auto_sync_switch.active;
        preferences.sync_music = sync_music_check.active;
        preferences.sync_all_music = sync_music_combobox.get_active () == 0;
        Gtk.TreeIter iter;
        if (sync_music_combobox.get_active ()-2 >= 0) {
            sync_music_combobox.get_active_iter (out iter);
            GLib.Value value;
            music_list.get_value (iter, 0, out value);
            preferences.music_playlist = (Noise.Playlist)value.dup_object ();
        }

        sync_music_combobox.sensitive = sync_music_check.active;
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
        music_list.set (iter, 0, null, 1, _("All Music"), 2, new ThemedIcon ("library-music"));

        /* add separator */
        music_list.append (out iter);
        music_list.set (iter, 0, null, 1, "<separator_item_unique_name>");

        /* add all playlists */
        foreach (var p in libraries_manager.local_library.get_smart_playlists ()) {
            music_list.append (out iter);
            music_list.set (iter, 0, p, 1, p.name, 2, p.icon);
            if (selected_playlist == p) {
                sync_music_combobox.set_active_iter (iter);
            }
        }

        foreach (var p in libraries_manager.local_library.get_playlists ()) {
            if (p.read_only == false) {
                music_list.append (out iter);
                music_list.set (iter, 0, p, 1, p.name, 2, p.icon);
                if (selected_playlist == p) {
                    sync_music_combobox.set_active_iter (iter);
                }
            }
        }

        if (selected_playlist == null)
            sync_music_combobox.set_active(0);

        message ("setting sensitivity\n");
        sync_music_combobox.sensitive = preferences.sync_music;
    }

    private void sync_finished () {
        refresh_space_widget ();
        space_widget.set_sync_button_sensitive (true);
    }

    public void sync_clicked () {
        var list = new Gee.TreeSet<Media>();

        if (preferences.sync_music) {
            if (preferences.sync_all_music) {
                foreach (var s in libraries_manager.local_library.get_medias ()) {
                    if (s.isTemporary == false)
                        list.add (s);
                }
            } else {
                var p = preferences.music_playlist;

                if (p != null) {
                    foreach (var m in p) {
                        if (m != null)
                            list.add (m);
                    }
                } else {
                    NotificationManager.get_default ().show_alert (_("Sync Failed"), _("The playlist named %s is used to sync device %s, but could not be found.").printf("<b>" + preferences.music_playlist.name + "</b>", "<b>" + dev.getDisplayName() + "</b>"));

                    preferences.music_playlist = null;
                    preferences.sync_all_music = true;
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
                swd.response.connect ((src, id) => {
                    switch (id) {
                        case SyncWarningDialog.ResponseId.IMPORT_MEDIA:
                            libraries_manager.transfer_to_local_library (not_found);
                            // TODO: After transfer, do sync

                            swd.destroy ();
                            break;
                        case SyncWarningDialog.ResponseId.CONTINUE:
                            dev.synchronize ();
                            swd.destroy ();
                            break;
                        case SyncWarningDialog.ResponseId.STOP:
                            swd.destroy ();
                            break;
                    }
                });
                swd.show();
            } else {
                space_widget.set_sync_button_sensitive(false);
                dev.synchronize ();
            }
        }
    }
}
