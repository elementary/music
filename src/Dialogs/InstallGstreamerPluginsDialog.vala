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

public class Noise.InstallGstreamerPluginsDialog : Gtk.Dialog {
    Gst.Message message;
    string detail;

    public InstallGstreamerPluginsDialog (Gst.Message message) {
        this.message = message;
        this.detail = Gst.PbUtils.missing_plugin_message_get_description (message);

        this.set_modal (true);
        this.set_transient_for (App.main_window);
        this.destroy_with_parent = true;
        this.border_width = 6;
        resizable = false;
        deletable = false;

        var content = get_content_area () as Gtk.Box;

        var question = new Gtk.Image.from_icon_name ("dialog-question", Gtk.IconSize.DIALOG);
        question.yalign = 0;

        var info = new Granite.Widgets.WrapLabel ("<span weight=\"bold\" size=\"larger\">" +
            _("Would you like to install the %s plugin?\n").printf (String.escape (detail)) +
            "</span>" + _("\nThis song cannot be played. The %s plugin is required to play the song.").printf ("<b>" +
            String.escape (detail) + "</b>")
        );

        info.m_wrap_width = 350;
        info.set_selectable (true);
        info.set_use_markup (true);

        var layout = new Gtk.Grid ();
        layout.set_column_spacing (12);
        layout.set_margin_right (6);
        layout.set_margin_bottom (24);
        layout.set_margin_left (6);
        layout.add (question);
        layout.add (info);

        content.add (layout);

        add_button (_("Cancel"), Gtk.ResponseType.CLOSE);
        add_button (_("Install Plugin"), Gtk.ResponseType.APPLY);

        this.response.connect ((response_id) => {
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

    public void install_plugin_clicked () {
        var installer = Gst.PbUtils.missing_plugin_message_get_installer_detail (message);
        var context = new Gst.PbUtils.InstallPluginsContext ();

        Gst.PbUtils.install_plugins_async ({ installer }, context,
                                           (Gst.PbUtils.InstallPluginsResultFunc) install_plugins_finished);

        // This callback was called before APT was done, so let's periodically check
        // whether the plugins have actually been installed. We won't update the
        // registry here.
        Timeout.add_seconds (3, Checker);
        this.hide ();
    }

    public void install_plugins_finished (Gst.PbUtils.InstallPluginsReturn result) {
        GLib.message ("Install of plugins finished.. updating registry");
    }

    private bool installation_done = false;

    private bool Checker () {
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
