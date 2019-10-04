// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012-2018 elementary LLC. (https://elementary.io)
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
 * The Music authors hereby grant permission for non-GPL compatible
 * GStreamer plugins to be used and distributed together with GStreamer
 * and Music. This permission is above and beyond the permissions granted
 * by the GPL license by which Music is covered. If you modify this code
 * you may extend this exception to your version of the code, but you are not
 * obligated to do so. If you do not wish to do so, delete this exception
 * statement from your version.
 *
 * Authored by: Scott Ringwelski <sgringwe@mtu.edu>
 */

public class Music.SetMusicFolderConfirmation : Granite.MessageDialog {
    public signal void finished (bool response);

    private Gtk.Image is_finished;
    private Gtk.Spinner is_working;

    public SetMusicFolderConfirmation (string path) {
        Object (
            image_icon: new ThemedIcon ("dialog-warning"),
            primary_text: _("Set Music Folder?"),
            secondary_text: _("Are you sure you want to set the music folder to %s? This will reset your library and remove your playlists.").printf ("<b>" + Markup.escape_text (path) + "</b>")
        );
    }

    construct {
        modal = true;
        transient_for = App.main_window;

        var save_playlists = new Gtk.Button.with_label (_("Export Playlists"));
        is_finished = new Gtk.Image ();
        is_working = new Gtk.Spinner ();

        // save playlist hbox
        var playlist_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        playlist_box.pack_start (save_playlists, true, true, 0);
        playlist_box.pack_end (is_finished, false, false, 0);
        playlist_box.pack_end (is_working, false, false, 0);

        var action_area = (Gtk.ButtonBox) get_action_area ();
        action_area.margin = 5;
        action_area.margin_top = 14;
        action_area.add (playlist_box);
        action_area.set_child_secondary (playlist_box, true);

        var cancel = (Gtk.Button) add_button (_("Cancel"), Gtk.ResponseType.CLOSE);

        var ok = (Gtk.Button) add_button (_("Set Music Folder"), Gtk.ResponseType.ACCEPT);
        ok.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);

        var local_library = libraries_manager.local_library;
        save_playlists.set_sensitive (!local_library.get_medias ().is_empty && local_library.playlist_count_without_read_only () > 0);

        save_playlists.clicked.connect (save_playlists_clicked);
        cancel.clicked.connect (cancel_clicked);
        ok.clicked.connect (ok_clicked);

        show_all ();

        is_working.hide ();
    }

    public void save_playlists_clicked () {
        var file_chooser = new Gtk.FileChooserNative (
            _("Choose Music Folder"),
            this,
            Gtk.FileChooserAction.SELECT_FOLDER,
            _("Open"),
            _("Cancel")
        );

        string folder = "";
        if (file_chooser.run () == Gtk.ResponseType.ACCEPT) {
            folder = file_chooser.get_uri ();
        }

        file_chooser.destroy ();

        if (folder != "") {
            is_working.show ();
            is_finished.hide ();

            // foreach playlist in lm.playlists(), save to (p.name).m3u
            var success = true;
            foreach (var p in libraries_manager.local_library.get_playlists ()) {
                if (!Music.PlaylistsUtils.save_playlist_m3u (p, folder, "")) {
                    success = false;
                }
            }

            is_working.hide ();
            is_finished.show ();
            is_finished.set_from_icon_name (success ? "process-completed-symbolic" : "process-error-symbolic", Gtk.IconSize.MENU);
        }
    }

    public void cancel_clicked () {
        finished (false);
        this.destroy ();
    }

    public void ok_clicked () {
        finished (true);
        this.destroy ();
    }
}
