// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012-2013 Noise Developers (http://launchpad.net/noise)
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
 *              Corentin Noël <tintou@mailoo.org>
 */

public class Noise.FileNotFoundDialog : Gtk.Dialog {
    Gee.LinkedList<Media> media_list = new Gee.LinkedList<Media> ();

    Gtk.Button rescanLibrary;

    public FileNotFoundDialog (Gee.Collection<Media> _media_list) {
        this.media_list.add_all (_media_list);

        this.set_modal (true);
        this.set_transient_for (App.main_window);
        this.destroy_with_parent = true;
        this.border_width = 6;
        resizable = false;
        deletable = false;

        var content = get_content_area () as Gtk.Box;

        // initialize controls
        Gtk.Image warning = new Gtk.Image.from_icon_name ("dialog-warning", Gtk.IconSize.DIALOG);
        warning.yalign = 0;

        var title_string = _("File not found");
        var body_string = "";

        if (media_list.size == 1) {
            var s = media_list.get (0);

            body_string = (_("The music file for <b>%s</b> by <b>%s</b> could not be found.").printf
                           (s.title.escape (""), s.artist.escape ("")));
        } else {
             body_string = (_("%i music files could not be found?").printf (media_list.size));
        }

        var info = new Granite.Widgets.WrapLabel (("<span weight=\"bold\" size=\"larger\">%s</span>").printf
            (String.escape (title_string)) + "\n\n" + ("%s").printf (body_string)
        );

        info.m_wrap_width = 350;
        info.set_selectable (true);
        info.set_use_markup (true);

        rescanLibrary.set_sensitive (!libraries_manager.local_library.doing_file_operations ());

        var layout = new Gtk.Grid ();
        layout.set_column_spacing (12);
        layout.set_margin_right (6);
        layout.set_margin_bottom (24);
        layout.set_margin_left (6);
        layout.add (warning);
        layout.add (info);

        content.add (layout);

        add_button (_("Rescan Library"), 1);
        add_button (_("Remove Song"), 2);
        add_button (_("Cancel"), Gtk.ResponseType.CLOSE);
        add_button (_("Find Song"), 3);

        this.response.connect ((response_id) => {
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

        libraries_manager.local_library.file_operations_started.connect (file_operations_started);
        libraries_manager.local_library.file_operations_done.connect (file_operations_done);

        show_all ();
    }

    void remove_media_clicked () {
        libraries_manager.local_library.remove_medias (media_list, false);

        this.destroy ();
    }

    void locate_media_clicked () {
        Media m = media_list.get (0);
        int media_id = m.rowid;

        string file = "";
        var file_chooser = new Gtk.FileChooserDialog (_("Choose Music Folder"), this,
                                                      Gtk.FileChooserAction.OPEN,
                                                      _(STRING_CANCEL), Gtk.ResponseType.CANCEL,
                                                      _(STRING_OPEN), Gtk.ResponseType.ACCEPT);

        // try and help user by setting a sane default folder
        var invalid_file = File.new_for_uri (libraries_manager.local_library.media_from_id (media_id).uri);
        var music_folder = Settings.Main.get_default ().music_folder;

        if (invalid_file.get_parent ().query_exists ()) {
            file_chooser.set_current_folder (invalid_file.get_parent().get_path ());
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

    void rescan_library_clicked () {
        ((LocalLibrary) libraries_manager.local_library).rescan_music_folder ();

        this.destroy ();
    }

    void file_operations_done () {
        rescanLibrary.set_sensitive (true);
    }

    void file_operations_started () {
        rescanLibrary.set_sensitive (false);
    }
}
