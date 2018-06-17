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

public class Noise.RemoveFilesDialog : Gtk.Dialog {
    public signal void remove_media (bool response);

    private Gtk.Box content;

    private Gtk.Button remove_button;
    private Gtk.Button trash_button;
    private Gtk.Button cancel_button;

    public RemoveFilesDialog (Gee.Collection<Media> to_remove) {
        this.set_modal (true);
        this.set_transient_for (App.main_window);
        this.destroy_with_parent = true;
        resizable = false;
        deletable = false;

        content = new Gtk.Box (Gtk.Orientation.VERTICAL, 10);

        Gtk.Box padding = get_content_area () as Gtk.Box;
        padding.set_orientation (Gtk.Orientation.HORIZONTAL);

        // initialize controls
        Gtk.Image warning = new Gtk.Image.from_icon_name ("dialog-warning", Gtk.IconSize.DIALOG);
        Gtk.Label title = new Gtk.Label ("");
        Gtk.Label info = new Gtk.Label ("");
        trash_button = new Gtk.Button.with_label (_("Move to Trash"));
        remove_button = new Gtk.Button.with_label (_("Remove from Library"));
        cancel_button = new Gtk.Button.with_label (_("Cancel"));

        bool multiple_media = to_remove.size > 1;

        // set title text
        title.halign = Gtk.Align.START;
        string title_text = "";

        if (multiple_media) {
            title_text = _("Remove %d Songs From Library?").printf (to_remove.size);
        } else {
            Media m = to_remove.to_array ()[0];
            title_text = _("Remove \"%s\" From Library?").printf (m.get_display_title ());
        }

        title.set_markup ("<span weight=\"bold\" size=\"larger\">" + Markup.escape_text (title_text) + "</span>");

        // set info text
        info.halign = Gtk.Align.START;
        info.set_line_wrap (true);
        int n = to_remove.size;
        string info_text = ngettext ("This will remove the song from your library and from any device synced automatically.",
                                     "This will remove the songs from your library and from any device synced automatically.", n);

        info.set_text (info_text);

        // decide if we need the trash button
        bool need_trash = false;
        foreach (var m in to_remove) {
            if (m.uri.has_prefix ("file:/")) {
                if (m.file_exists == true) {
                    need_trash = true;
                    break;
                }
            }
        }

        /* set up controls layout */
        var information = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        var information_text = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        information.pack_start (warning, false, false, 10);
        information_text.pack_start (title, false, true, 10);
        information_text.pack_start (info, false, true, 0);
        information.pack_start (information_text, true, true, 10);

        var bottomButtons = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
        bottomButtons.set_layout (Gtk.ButtonBoxStyle.END);
        if (need_trash) bottomButtons.pack_end (trash_button, false, false, 0);
        bottomButtons.pack_end (cancel_button, false, false, 0);
        bottomButtons.pack_end (remove_button, false, false, 0);
        bottomButtons.set_spacing (10);

        content.pack_start (information, false, true, 0);
        content.pack_start (bottomButtons, false, true, 10);

        padding.pack_start (content, true, true, 0);

        trash_button.clicked.connect (() => {
            remove_media (true);
            destroy ();
        });

        remove_button.clicked.connect (() => {
            remove_media (false);
            destroy ();
        });

        cancel_button.clicked.connect (() => {
            destroy ();
        });

        set_default (cancel_button);
        cancel_button.grab_focus ();

        show_all ();
    }
}
