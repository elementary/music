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

public class Noise.RemoveFilesDialog : Granite.MessageDialog {
    public signal void remove_media (bool response);

    public RemoveFilesDialog (Gee.Collection<Media> to_remove) {
        Object (
            destroy_with_parent: true,
            image_icon: new ThemedIcon ("dialog-warning"),
            modal: true,
            primary_text: "",
            secondary_text: "",
            transient_for: App.main_window
        );

        primary_label.max_width_chars = 65;
        secondary_label.max_width_chars = 65;

        var to_remove_size = to_remove.size;

        if (to_remove_size > 1) {
            primary_text = ngettext (
                "Remove %d Songs From Library?",
                "Remove %d Songs From Library?",
                to_remove_size
            ).printf (to_remove_size);
        } else {
            var media = to_remove.to_array ()[0];
            primary_text = _("Remove \"%s\" From Library?").printf (media.get_display_title ());
        }

        secondary_text = ngettext (
            "This will remove the song from your library and from any device synced automatically.",
            "This will remove the songs from your library and from any device synced automatically.",
            to_remove_size
        );

        bool need_trash = false;
        foreach (var m in to_remove) {
            if (m.uri.has_prefix ("file:/") && m.file_exists == true) {
                need_trash = true;
                break;
            }
        }

        if (need_trash) {
            var trash_button = (Gtk.Button) add_button (_("Move to Trash"), 0);
            trash_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);

            trash_button.clicked.connect (() => {
                remove_media (true);
                destroy ();
            });
        }

        var cancel_button = (Gtk.Button) add_button (_("Cancel"), Gtk.ResponseType.CANCEL);
        var remove_button = (Gtk.Button) add_button (_("Remove from Library"), Gtk.ResponseType.APPLY);

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
