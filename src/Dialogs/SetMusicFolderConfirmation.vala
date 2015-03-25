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

public class Noise.SetMusicFolderConfirmation : Gtk.Dialog {
    public signal void finished (bool response);

    string folder_path;

    Gtk.Grid content;

    Gtk.Button savePlaylists;
    Gtk.Button ok;
    Gtk.Button cancel;

    Gtk.Image is_finished;
    Gtk.Spinner is_working;

    public SetMusicFolderConfirmation (string path) {
        folder_path = path;

        // set the size based on saved gconf settings
        this.window_position = Gtk.WindowPosition.CENTER;
        this.set_modal (true);
        this.set_transient_for (App.main_window);
        this.destroy_with_parent = true;
        this.deletable = false;

        resizable = false;

        content = new Gtk.Grid ();
        content.margin = 12;
        content.margin_bottom = 0;
        content.column_spacing = 12;
        content.row_spacing = 6;

        // initialize controls
        Gtk.Image warning = new Gtk.Image.from_icon_name ("dialog-warning", Gtk.IconSize.DIALOG);
        Gtk.Label title = new Gtk.Label("");
        Gtk.Label info = new Gtk.Label("");
        savePlaylists = new Gtk.Button.with_label(_("Export Playlists"));
        ok = new Gtk.Button.with_label(_("Set Music Folder"));
        cancel = new Gtk.Button.with_label (_(STRING_CANCEL));
        is_finished = new Gtk.Image();
        is_working = new Gtk.Spinner();

        // pretty up labels
        title.halign = Gtk.Align.START;
        title.set_markup("<span weight=\"bold\" size=\"larger\">%s</span>".printf(String.escape (_("Set Music Folder?"))));
        info.halign = Gtk.Align.START;
        info.set_line_wrap (true);
        info.set_markup (_("Are you sure you want to set the music folder to %s? This will reset your library and remove your playlists.").printf ("<b>" + String.escape (path) + "</b>"));

        // save playlist hbox
        var playlistBox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        playlistBox.pack_start (savePlaylists, true, true, 0);
        playlistBox.pack_end (is_finished, false, false, 0);
        playlistBox.pack_end (is_working, false, false, 0);

        var bottomButtons = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
        bottomButtons.layout_style = Gtk.ButtonBoxStyle.END;
        bottomButtons.spacing = 12;
        bottomButtons.pack_start (playlistBox, false, false, 0);
        bottomButtons.pack_end (cancel, false, false, 0);
        bottomButtons.pack_end (ok, false, false, 0);

        ((Gtk.ButtonBox)bottomButtons).set_child_secondary (playlistBox, true);

        content.attach (warning, 0, 0, 1, 2);
        content.attach (title, 1, 0, 1, 1);
        content.attach (info, 1, 1, 1, 1);
        content.attach (bottomButtons, 0, 2, 2, 1);

        var local_library = libraries_manager.local_library;
        savePlaylists.set_sensitive (!local_library.get_medias ().is_empty && local_library.playlist_count_without_read_only () > 0);

        savePlaylists.clicked.connect (savePlaylistsClicked);
        cancel.clicked.connect (cancel_clicked);
        ok.clicked.connect (ok_clicked);

        get_content_area ().add (content);
        show_all ();

        is_working.hide ();
    }

    public void savePlaylistsClicked () {
        string folder = "";
        var file_chooser = new Gtk.FileChooserDialog (_("Choose Music Folder"), this,
                                  Gtk.FileChooserAction.SELECT_FOLDER,
                                  _(STRING_CANCEL), Gtk.ResponseType.CANCEL,
                                  _(STRING_OPEN), Gtk.ResponseType.ACCEPT);
        if (file_chooser.run () == Gtk.ResponseType.ACCEPT) {
            folder = file_chooser.get_filename ();
        }

        file_chooser.destroy ();

        if (folder != "") {
            is_working.show ();
            is_finished.hide ();

            // foreach playlist in lm.playlists(), save to (p.name).m3u
            var success = true;
            foreach (var p in libraries_manager.local_library.get_playlists ()) {
                if (!Noise.PlaylistsUtils.save_playlist_m3u(p, folder, ""))
                    success = false;
            }

            is_working.hide ();
            is_finished.show ();
            var process_completed_icon = Icons.PROCESS_COMPLETED.render (Gtk.IconSize.MENU);
            var process_error_icon = Icons.PROCESS_ERROR.render (Gtk.IconSize.MENU);
            is_finished.set_from_pixbuf (success ? process_completed_icon : process_error_icon);
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
