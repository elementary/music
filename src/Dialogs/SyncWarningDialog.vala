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

public class Noise.SyncWarningDialog : Gtk.Dialog {
    private enum ResponseId {
        IMPORT_MEDIA = 1,
        CONTINUE,
        STOP
    }

    Device d;
    Gee.TreeSet<Media> to_sync = new Gee.TreeSet<Media> ();
    Gee.TreeSet<Media> to_remove = new Gee.TreeSet<Media> ();

    Gtk.Widget import_media_button;
    Gtk.Widget continue_button;
    Gtk.Widget stop_button;

    public SyncWarningDialog (Device d, Gee.Collection<Media> to_sync, Gee.Collection<Media> removed) {
        this.d = d;
        this.to_sync.add_all (to_sync);
        this.to_remove.add_all (removed);

        // set the size based on saved gconf settings
        //this.window_position = WindowPosition.CENTER;
        this.type_hint = Gdk.WindowTypeHint.DIALOG;
        this.modal = true;
        this.transient_for = App.main_window;
        this.destroy_with_parent = true;

        set_default_size (475, -1);
        resizable = false;
        border_width = 20;

        Gtk.Box content = get_content_area ();
        content.spacing = 10;

        // initialize controls
        Gtk.Image warning = new Gtk.Image.from_icon_name ("dialog-error", Gtk.IconSize.DIALOG);
        Gtk.Label title = new Gtk.Label ("");
        Gtk.Label info = new Gtk.Label ("");

        import_media_button = add_button (_("Import media to Library"), ResponseId.IMPORT_MEDIA);
        continue_button = add_button (_("Continue Syncing"), ResponseId.CONTINUE);
        stop_button = add_button (_("Stop Syncing"), ResponseId.STOP);
        response.connect (on_response);

        // pretty up labels
        title.halign = Gtk.Align.START;
        info.halign = Gtk.Align.START;

        info.set_line_wrap (true);
        var info_text = _("If you continue to sync, media will be removed from %s since they are not on the sync list. Would you like to import them to your library first?").printf ("<b>" + Markup.escape_text (d.getDisplayName ()) + "</b>");
        info.set_markup (info_text);

        // be a bit explicit to make translations better
        string title_text = to_remove.size > 1
            ? _("Sync will remove %i items from %s").printf (to_remove.size, d.getDisplayName ())
            : _("Sync will remove 1 item from %s").printf (d.getDisplayName ());

        string MARKUP_TEMPLATE = "<span weight=\"bold\" size=\"larger\">%s</span>";
        var title_string = MARKUP_TEMPLATE.printf (Markup.escape_text (title_text, -1));
        title.set_markup (title_string);

        import_media_button.sensitive = !libraries_manager.local_library.doing_file_operations ();
        continue_button.sensitive = !libraries_manager.local_library.doing_file_operations ();

        /* set up controls layout */
        var information = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        var information_text = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        information.pack_start (warning, false, false, 10);
        information_text.pack_start (title, false, true, 10);
        information_text.pack_start (info, false, true, 0);
        information.pack_start (information_text, true, true, 10);

        content.pack_start (information, false, true, 0);

        libraries_manager.local_library.file_operations_started.connect (file_operations_started);
        libraries_manager.local_library.file_operations_done.connect (file_operations_done);

        show_all ();
    }

    public void on_response (Gtk.Dialog src, int id) {
        switch (id) {
            case ResponseId.IMPORT_MEDIA:
                libraries_manager.transfer_to_local_library (to_remove);
                // TODO: After transfer, do sync

                this.destroy ();
                break;
            case ResponseId.CONTINUE:
                d.synchronize ();
                this.destroy ();
                break;
            case ResponseId.STOP:
                this.destroy ();
                break;
        }
    }

    public void file_operations_done () {
        import_media_button.sensitive = true;
        continue_button.sensitive = true;
    }

    public void file_operations_started () {
        import_media_button.sensitive = false;
        continue_button.sensitive = false;
    }
}
