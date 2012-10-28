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
    public MusicViewWrapper (LibraryWindow lw) {
        base (lw, Hint.MUSIC);
        build_async.begin ();
    }

    private async void build_async () {
        // Add grid view
        grid_view = new GridView (this);

        // Add list view and column browser
        list_view = new ListView (this, lw.library_manager.music_setup, true);

        // Welcome screen
        welcome_screen = new Granite.Widgets.Welcome (_("Get Some Tunes"),
            _("%s can't seem to find your music.").printf (App.instance.get_name ()));

        var music_folder_icon = Icons.MUSIC_FOLDER.render (Gtk.IconSize.DIALOG, null);
        welcome_screen.append_with_pixbuf (music_folder_icon, _("Locate"), _("Change your music folder."));

        welcome_screen.activated.connect (welcome_screen_activated);

        embedded_alert = new Granite.Widgets.EmbeddedAlert ();

        // Refresh view layout
        pack_views ();

        yield set_media_async (lm.media ());
        connect_data_signals ();
    }

    private void connect_data_signals () {
        /** 
         * Listen for library additions, removals and updates. These all are only
         * possible with internal media. This view wrapper is not intended for use
         * with external (i.e. doesn't belong to library) media anyway.
         */
         lm.media_added.connect (on_library_media_added);
         lm.media_removed.connect (on_library_media_removed);
         lm.media_updated.connect (on_library_media_updated);
    }

    private void on_library_media_added (Gee.Collection<int> added_ids) {
        // Convert ids to real media
        var to_add = lm.media_from_ids (added_ids);
        add_media_async (to_add);
    }

    private void on_library_media_removed (Gee.Collection<int> removed_ids) {
        // Convert ids to real media
        var to_remove = lm.media_from_ids (removed_ids);
        remove_media_async (to_remove);    
    }

    private void on_library_media_updated (Gee.Collection<int> updated_ids) {
        // Convert ids to real media
        var to_update = lm.media_from_ids (updated_ids);
        update_media_async (to_update);    
    }
    
    private void welcome_screen_activated (int index) {
        if (index == 0) {
            if (!lm.doing_file_operations ()) {
                var file_chooser = new Gtk.FileChooserDialog (_("Select Music Folder"), lw,
                                                              Gtk.FileChooserAction.SELECT_FOLDER,
                                                              Gtk.Stock.CANCEL,
                                                              Gtk.ResponseType.CANCEL,
                                                              Gtk.Stock.OPEN,
                                                              Gtk.ResponseType.ACCEPT);

                file_chooser.set_local_only (true);
                file_chooser.set_select_multiple (false);
                file_chooser.set_current_folder (Settings.Main.instance.music_folder);

                string? folder = null;

                if (file_chooser.run () == Gtk.ResponseType.ACCEPT)
                    folder = file_chooser.get_filename ();

                file_chooser.destroy ();

                if (!String.is_empty (folder, true))
                    lw.setMusicFolder (folder);
            }
        }
    }
}
