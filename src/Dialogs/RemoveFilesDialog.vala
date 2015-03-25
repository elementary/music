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

public class Noise.RemoveFilesDialog : Gtk.Dialog {
    public signal void remove_media(bool response);

    private Gtk.Box content;

    private Gtk.Button remove_button;
    private Gtk.Button trash_button;
    private Gtk.Button cancel_button;

    public RemoveFilesDialog (Gee.Collection<Media> to_remove, ViewWrapper.Hint media_type) {
        var app_name = ((Noise.App) GLib.Application.get_default ()).get_name ();

        this.set_modal(true);
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
        remove_button = new Gtk.Button.with_label (_("Remove from %s").printf (app_name));
        cancel_button = new Gtk.Button.with_label (_(STRING_CANCEL));

        bool multiple_media = to_remove.size > 1;

        // set title text
        title.halign = Gtk.Align.START;
        string title_text = "";

        if (multiple_media) {
            title_text = _("Remove %d Songs From %s?").printf (to_remove.size, app_name);
        } else {
            Media m = to_remove.to_array ()[0];
            title_text = _("Remove \"%s\" From %s?").printf (m.get_display_title (), app_name);
        }

        title.set_markup("<span weight=\"bold\" size=\"larger\">" + String.escape (title_text) + "</span>");

        // set info text
        info.halign = Gtk.Align.START;
        info.set_line_wrap (true);
        int n = to_remove.size;
        string info_text = ngettext ("This will remove the song from your library and from any device that automatically syncs with %s.",
                                     "This will remove the songs from your library and from any device that automatically syncs with %s.", n).printf (app_name);

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

        show_all();
    }
}
