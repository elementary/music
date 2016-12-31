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

public class Noise.DeviceView : Gtk.Grid {
    public Device d;
    DeviceSummaryWidget summary;
    
    Gtk.InfoBar infobar;
    Gtk.Label infobar_label;
    
    public DeviceView (Noise.Device device, DevicePreferences preferences) {
        this.orientation = Gtk.Orientation.VERTICAL;
        this.d = device;

        buildUI (preferences);

        ulong connector = NotificationManager.get_default ().progress_canceled.connect ( () => {
            if (d.get_library ().doing_file_operations ()) {
                NotificationManager.get_default ().show_alert (_("Cancelling…"), _("Device operation has been cancelled and will stop after this media."));
            }
        });
        d.device_unmounted.connect ( () => {
            message ("device unmounted\n");
            d.disconnect (connector);
        });
        
        if (preferences.sync_when_mounted)
            syncClicked ();
    }

    void buildUI (DevicePreferences preferences) {
        
        /* create infobar */
        
        infobar = new Gtk.InfoBar();
        infobar.get_style_context ().add_class (Gtk.STYLE_CLASS_INFO);
        infobar.set_hexpand (true);
        infobar_label = new Gtk.Label ("");
        (infobar.get_content_area () as Gtk.Container).add (infobar_label);
        infobar.add_button (_("OK"), 0);
        infobar.response.connect ( (self, response) => {
            infobar.hide ();
        });
        summary = new DeviceSummaryWidget (d, preferences);
        
        attach (infobar, 0, 0, 1, 1);
        if (d.get_custom_view () != null) {
            attach (d.get_custom_view (), 0, 1, 1, 1);
        } else {
            attach (summary, 0, 1, 1, 1);
        }
        
        show_all ();
        infobar.hide ();
        d.infobar_message.connect (infobar_message_sended);
    }
    
    
    public void set_as_current_view () {
        summary.refresh_lists ();
    }
    
    void infobar_message_sended (string message, Gtk.MessageType type) {
        infobar_label.set_label (message);
        infobar.set_message_type (type);
        infobar.show_all ();
    }
    
    public void showImportDialog () {
        // ask the user if they want to import medias from device that they don't have in their library (if any)
        // this should be same as MusicViewWrapper
        if (!libraries_manager.local_library.doing_file_operations () && Settings.Main.get_default ().music_folder != "") {
            var found = new Gee.TreeSet<int> ();
            var not_found = new Gee.TreeSet<Media> ();
            libraries_manager.local_library.media_from_name (d.get_library ().get_medias (), found, not_found);
            
            if (not_found.size > 0) {
                TransferFromDeviceDialog tfdd = new TransferFromDeviceDialog (d, not_found);
                tfdd.show ();
            } else {
                NotificationManager.get_default ().show_alert (_("No External Songs"), _("There were no songs found on this device that are not in your library."));
            }
        }
    }
    
    public void syncClicked () {
        summary.sync_clicked ();
    }
}
