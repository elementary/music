// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012 Noise Developers (http://launchpad.net/noise)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Scott Ringwelski <sgringwe@mtu.edu>
 *              Victor Eduardo <victoreduardm@gmail.com>
 */

public class Noise.MusicViewWrapper : ViewWrapper {
    
    public MusicViewWrapper (TreeViewSetup? tvs = null, Library library, TopDisplay topDisplay) {
        base (Hint.MUSIC, library);
        build_async.begin (tvs, topDisplay);
    }

    private Gee.HashMap<unowned Device, int> _devices;

    private async void build_async (TreeViewSetup? tvs = null, TopDisplay topDisplay) {
        Idle.add_full (VIEW_CONSTRUCT_PRIORITY, build_async.callback);
        yield;
        // Add grid view
        grid_view = new GridView (this);

        // Add list view and column browser
        TreeViewSetup music_setup;
        if (tvs == null)
            music_setup = new TreeViewSetup (ListColumn.ARTIST,
                                             Gtk.SortType.ASCENDING,
                                             ViewWrapper.Hint.MUSIC);
        else
            music_setup = tvs;
        list_view = new ListView (this, music_setup, true);
        topDisplay.set_list_view(list_view.list_view);

        // Welcome screen
        welcome_screen = new Granite.Widgets.Welcome (_("Get Some Tunes"),
            _("Add music to your library."/*" with one of the methods below."*/));

        var import_music_icon = Icons.IMPORT.render (Gtk.IconSize.DIALOG, null);
        welcome_screen.append_with_pixbuf (import_music_icon, _("Import Music"),
            _("Import music from a source into your library."));

        var music_folder_icon = Icons.MUSIC_FOLDER.render (Gtk.IconSize.DIALOG, null);
        welcome_screen.append_with_pixbuf (music_folder_icon, _("Change Music Folder"),
            _("Load music from a folder, a network or an external disk."));

        welcome_screen.activated.connect (welcome_screen_activated);
        _devices = new Gee.HashMap<Device, int> ();

        embedded_alert = new Granite.Widgets.EmbeddedAlert ();
        
        // Drag n drop in welcome widget
        Gtk.TargetEntry uris = {"text/uri-list", 0, 0};
        Gtk.drag_dest_set (welcome_screen, Gtk.DestDefaults.ALL, {uris}, Gdk.DragAction.COPY);
        welcome_screen.drag_data_received.connect ( (ctx, x, y, sel, info, time) => {
            var files = new Gee.TreeSet<string> ();
            for (var i=0; i < sel.get_uris ().length; i++) {
                File f = File.new_for_uri (sel.get_uris()[i]);
                string path = f.get_uri ();
                files.add (path);
            }
            App.main_window.library_manager.add_files_to_library (files);
        });
        
        // Refresh view layout
        pack_views ();

        connect_data_signals ();
        yield set_media_async (library.get_medias ());
    }

    private void connect_data_signals () {
        /** 
         * Listen for library additions, removals and updates. These all are only
         * possible with internal media. This view wrapper is not intended for use
         * with external (i.e. doesn't belong to library) media anyway.
         */
        if (library == libraries_manager.local_library) {
            var device_manager = DeviceManager.get_default ();
            device_manager.device_added.connect (on_device_added);
            device_manager.device_removed.connect (on_device_removed);
            device_manager.device_name_changed.connect (on_device_name_changed);
        }
        library.media_added.connect (add_media_async);
        library.media_removed.connect (remove_media_async);
        library.media_updated.connect (update_media_async);
    }

    private void on_device_added (Device d) {
        int id = welcome_screen.append (d.get_icon().to_string (), _("Import your Music"), _("Import all your Music from %s into your library.").printf(d.getDisplayName()));
        _devices.set (d, id);
        welcome_screen.show_all ();
    }

    private void on_device_removed (Device d) {
        int id = _devices.get (d);
        if (id > 0) {
            welcome_screen.remove_item (_devices.get (d));
        }
        _devices.unset (d, null);
    }

    private void on_device_name_changed (Device d) {
        welcome_screen.remove_item (_devices.get (d));
        _devices.unset (d, null);
        int id = welcome_screen.append (d.get_icon().to_string (), _("Import your Music"), _("Import all your Music from %s into your library.").printf(d.getDisplayName()));
        _devices.set (d, id);
        welcome_screen.show_all ();
    }

    private void welcome_screen_activated (int index) {
        if (index == 0) {
            App.main_window.fileImportMusicClick ();
        } else if (index == 1) {
            if (!library.doing_file_operations ()) {
                var file_chooser = new Gtk.FileChooserDialog (_("Select Music Folder"), App.main_window,
                                                              Gtk.FileChooserAction.SELECT_FOLDER,
                                                              _(STRING_CANCEL),
                                                              Gtk.ResponseType.CANCEL,
                                                              _(STRING_OPEN),
                                                              Gtk.ResponseType.ACCEPT);

                file_chooser.set_local_only (true);
                file_chooser.set_select_multiple (false);
                file_chooser.set_current_folder (Settings.Main.get_default ().music_folder);

                string? folder = null;

                if (file_chooser.run () == Gtk.ResponseType.ACCEPT)
                    folder = file_chooser.get_filename ();

                file_chooser.destroy ();

                if (!String.is_empty (folder, true))
                    App.main_window.setMusicFolder (folder);
            }
        } else {
            foreach (var device_entry in _devices.entries) {
                if (device_entry.value == index) {
                    libraries_manager.transfer_to_local_library (((Device)device_entry.key).get_library ().get_medias ());
                }
            }
        }
    }
}
