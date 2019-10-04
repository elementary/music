/*-
 * Copyright (c) 2012-2019 elementary, Inc. (https://elementary.io)
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

public class Music.InstallGstreamerPluginsDialog : Granite.MessageDialog {
    private Gst.Message message;
    private bool installation_done = false;

    public InstallGstreamerPluginsDialog (Gst.Message message) {
        Object ();

        this.message = message;
    }

    construct {
        var detail = Gst.PbUtils.missing_plugin_message_get_description (message);

        primary_text = _("Would you like to install the %s plugin?").printf (Markup.escape_text (detail));
        secondary_text = _("This song cannot be played. The %s plugin is required to play the song.").printf ("<b>" + Markup.escape_text (detail) + "</b>");

        destroy_with_parent = true;
        image_icon = new GLib.ThemedIcon ("dialog-question");
        modal = true;
        transient_for = App.main_window;

        add_button (_("Cancel"), Gtk.ResponseType.CLOSE);

        var install_button = add_button (_("Install Plugin"), Gtk.ResponseType.APPLY);
        install_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        response.connect ((response_id) => {
            switch (response_id) {
                case Gtk.ResponseType.APPLY:
                    install_plugin_clicked ();
                    break;
                case Gtk.ResponseType.CLOSE:
                    destroy ();
                    break;
            }
        });

        show_all ();
    }

    private void install_plugin_clicked () {
        var installer = Gst.PbUtils.missing_plugin_message_get_installer_detail (message);
        var context = new Gst.PbUtils.InstallPluginsContext ();

        Gst.PbUtils.install_plugins_async ({ installer }, context,
                                           (Gst.PbUtils.InstallPluginsResultFunc) install_plugins_finished);

        // This callback was called before APT was done, so let's periodically check
        // whether the plugins have actually been installed. We won't update the
        // registry here.
        Timeout.add_seconds (3, checker);
        this.hide ();
    }

    private void install_plugins_finished (Gst.PbUtils.InstallPluginsReturn result) {
        GLib.message ("Install of plugins finished.. updating registry");
    }

    private bool checker () {
        if (installation_done)
            return false;   // this ends the checking method

        var search = new Granite.Services.SimpleCommand ("/home", "/usr/bin/dpkg -l");
        search.run ();      // this is asynchronous. It will tell us when its done

        search.done.connect ((exit) => {
            if (search.output_str.contains ("fluendo")) {   // if plugins installed
                Gst.update_registry ();
                installation_done = true;
            }
        });

        // this will mean that it will be checked again
        return true;
    }
}
