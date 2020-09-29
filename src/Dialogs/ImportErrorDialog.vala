// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2020 elementary LLC. (https://elementary.io)
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
 * Authored by: Jeremy Wootten <jeremywootten@gmail.com>,
 */


public class Music.ImportErrorDialog : Granite.MessageDialog {
    public Gee.HashMultiMap<Gst.PbUtils.DiscovererResult, string> import_errors { get; construct; }
    public string error_details { get; private set; }
    public ImportErrorDialog (string imported_from,
                              Gee.HashMultiMap<Gst.PbUtils.DiscovererResult, string> import_errors) {

        Object ();
        var n_errors = import_errors.get_values ().size;
        var parts = imported_from.split ("://");
        var dir_path_length = imported_from.length;
        var import_dir_path = Uri.unescape_string (parts[parts.length - 1]);

        primary_text = ngettext (
                        _("There were problems importing %i file from %s"),
                        _("There were problems importing %i files from %s"),
                        n_errors).printf (n_errors, import_dir_path);

        secondary_text = _("These files will not be able to be played and will not appear in the library");

        image_icon = new ThemedIcon ("dialog-error");
        var sb = new StringBuilder ();

        var keys = import_errors.get_keys ();
        foreach (var key in keys) {
            string key_description;
            switch (key) {
                case Gst.PbUtils.DiscovererResult.URI_INVALID:
                    key_description = _("Invalid address");
                    break;

                case Gst.PbUtils.DiscovererResult.BUSY:
                    key_description = _("Busy");
                    break;

                case Gst.PbUtils.DiscovererResult.TIMEOUT:
                    key_description = _("Took too long");
                    break;

                case Gst.PbUtils.DiscovererResult.MISSING_PLUGINS:
                    key_description = _("Codec missing");
                    break;

                case Gst.PbUtils.DiscovererResult.ERROR:
                    key_description = _("Read error");
                    break;

                default:
                    key_description = _("Unknown error");
                    break;
            }

            sb.append (key_description + "\n");
            sb.append (string.nfill (key_description.length, '-') + "\n");

            var uris = import_errors.@get (key);

            foreach (var uri in uris) {
                var rel_uri = uri.slice (dir_path_length + 1, uri.length);
                sb.append (Uri.unescape_string (rel_uri) + "\n");
            }

            sb.append ("\n");
        }

        error_details = sb.str;

        add_button (_("Show details"), Gtk.ResponseType.ACCEPT);
        add_button (_("Close"), Gtk.ResponseType.CLOSE);
        show_all ();
    }
}
