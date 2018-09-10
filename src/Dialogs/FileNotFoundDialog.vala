// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012-2018 elementary, Inc. (https://elementary.io)
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
 *              Corentin Noël <corentin@elementary.io>
 */

public class Noise.FileNotFoundDialog : Granite.MessageDialog {
    private Gee.LinkedList<Media> media_list;

    public FileNotFoundDialog (Gee.Collection<Media> _media_list) {
        Object (
            destroy_with_parent: true,
            image_icon: new ThemedIcon ("dialog-warning"),
            primary_text: _("File not found"),
            transient_for: App.main_window
        );

        media_list = new Gee.LinkedList<Media> ();
        media_list.add_all (_media_list);

        if (media_list.size == 1) {
            var s = media_list.get (0);

            secondary_text = (_("The music file for <b>%s</b> by <b>%s</b> could not be found.").printf
                           (Markup.escape_text (s.title), Markup.escape_text (s.artist)));
        } else {
            secondary_text = (_("%i music files could not be found?").printf (media_list.size));
        }

        var rescan_library = (Gtk.Button) add_button (_("Rescan Library"), 1);
        add_button (_("Remove Song"), 2);
        add_button (_("Cancel"), Gtk.ResponseType.CLOSE);
        add_button (_("Find Song"), 3);

        rescan_library.sensitive = !libraries_manager.local_library.doing_file_operations ();

        response.connect ((response_id) => {
            switch (response_id) {
                case 1:
                    rescan_library_clicked ();
                    break;
                case 2:
                    remove_media_clicked ();
                    break;
                case 3:
                    locate_media_clicked ();
                    break;
                case Gtk.ResponseType.CLOSE:
                    destroy ();
                    break;
            }
        });

        libraries_manager.local_library.file_operations_started.connect (() => {
            rescan_library.sensitive = false;
        });

        libraries_manager.local_library.file_operations_done.connect (() => {
            rescan_library.sensitive = true;
        });

        show_all ();
    }

    private void remove_media_clicked () {
        libraries_manager.local_library.remove_medias (media_list, false);

        this.destroy ();
    }

    private void locate_media_clicked () {
        Media m = media_list.get (0);
        int64 media_id = m.rowid;

        string file = "";
        var file_chooser = new Gtk.FileChooserDialog (_("Choose Music Folder"), this,
                                                      Gtk.FileChooserAction.OPEN,
                                                      _("Cancel"), Gtk.ResponseType.CANCEL,
                                                      _("Open"), Gtk.ResponseType.ACCEPT);

        // try and help user by setting a sane default folder
        var invalid_file = File.new_for_uri (libraries_manager.local_library.media_from_id (media_id).uri);
        var music_folder = Settings.Main.get_default ().music_folder;

        if (invalid_file.get_parent ().query_exists ()) {
            file_chooser.set_current_folder (invalid_file.get_parent ().get_path ());
        } else if (invalid_file.get_parent ().get_parent ().query_exists () &&
                   invalid_file.get_parent ().get_parent ().get_path ().contains (music_folder)) {

            file_chooser.set_current_folder (invalid_file.get_parent ().get_parent ().get_path ());
        } else if (File.new_for_path (music_folder).query_exists ()) {
            file_chooser.set_current_folder (music_folder);
        } else {
            file_chooser.set_current_folder (Environment.get_home_dir ());
        }

        if (file_chooser.run () == Gtk.ResponseType.ACCEPT) {
            file = file_chooser.get_filename ();
        }

        file_chooser.destroy ();

         if (file != "" && File.new_for_path (file).query_exists ()) {
            m.uri = File.new_for_path (file).get_uri ();
            m.location_unknown = false;
            m.unique_status_image = null;

            // TODO: lm.lw.media_found(m.rowid);
            libraries_manager.local_library.update_media (m, false, false);

            this.destroy ();
        }
    }

    private void rescan_library_clicked () {
        ((LocalLibrary) libraries_manager.local_library).rescan_music_folder ();

        this.destroy ();
    }
}
