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

public class Noise.SyncWarningDialog : Granite.MessageDialog {
    public enum ResponseId {
        IMPORT_MEDIA = 1,
        CONTINUE,
        STOP
    }

    public Device device { get; construct; }
    public Gee.TreeSet<Media> to_sync { get; construct; }
    public Gee.TreeSet<Media> to_remove { get; construct; }

    private Gtk.Widget import_media_button;
    private Gtk.Widget continue_button;

    construct {
        deletable = false;
        destroy_with_parent = true;
        modal = true;
        transient_for = App.main_window;

        image_icon = new GLib.ThemedIcon ("dialog-warning");

        // be a bit explicit to make translations better
        primary_text = ngettext ("Sync will remove %i item from %s", "Sync will remove %i items from %s", to_remove.size)
                                .printf (to_remove.size, device.get_display_name ());

        secondary_text = _("If you continue to sync, media will be removed from %s since they are not on the sync list. Would you like to import them to your library first?").printf ("<b>" + Markup.escape_text (device.get_display_name ()) + "</b>");

        continue_button = add_button (_("Continue Syncing"), ResponseId.CONTINUE);
        continue_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);

        var stop_button = add_button (_("Cancel"), ResponseId.STOP);

        import_media_button = add_button (_("Import"), ResponseId.IMPORT_MEDIA);
        import_media_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        import_media_button.sensitive = !libraries_manager.local_library.doing_file_operations ();
        continue_button.sensitive = !libraries_manager.local_library.doing_file_operations ();

        show_all ();
    }

    public SyncWarningDialog (Device d, Gee.TreeSet<Media> to_sync, Gee.TreeSet<Media> removed) {
        Object (device: d, to_sync: to_sync, to_remove: removed);
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
