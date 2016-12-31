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
 * Authored by: Victor Eduardo <victoreduardm@gmail.com>
 */

int main (string[] args) {
    Gtk.init (ref args);
    Gda.init ();

    try {
        Gst.init_check (ref args);
    } catch (Error err) {
        error ("Could not init GStreamer: %s", err.message);
    }

    // Init internationalization support before anything else
    string package_name = Build.GETTEXT_PACKAGE;
    string langpack_dir = Path.build_filename (Build.DATADIR, "locale");
    Intl.setlocale (LocaleCategory.ALL, "");
    Intl.bindtextdomain (package_name, langpack_dir);
    Intl.bind_textdomain_codeset (package_name, "UTF-8");
    Intl.textdomain (package_name);
    GLib.Environ.set_variable ({"PULSE_PROP_media.role"}, "audio", "true");
    var app = new Noise.App ();

    return app.run (args);
}
