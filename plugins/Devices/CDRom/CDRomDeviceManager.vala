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
 * The Music authors hereby grant permission for non-GPL compatible
 * GStreamer plugins to be used and distributed together with GStreamer
 * and Music. This permission is above and beyond the permissions granted
 * by the GPL license by which Music is covered. If you modify this code
 * you may extend this exception to your version of the code, but you are not
 * obligated to do so. If you do not wish to do so, delete this exception
 * statement from your version.
 *
 * Authored by: Corentin Noël <corentin@elementary.io>
 */

public class Music.Plugins.CDRomDeviceManager : GLib.Object {
    Gee.ArrayList<CDRomDevice> devices;

    public CDRomDeviceManager () {
        devices = new Gee.ArrayList<CDRomDevice> ();

        var device_manager = DeviceManager.get_default ();
        device_manager.mount_added.connect (mount_added);
        device_manager.mount_removed.connect (mount_removed);
        foreach (var mount in device_manager.get_available_mounts ()) {
            mount_added (mount);
        }
    }

    public void remove_all () {
        var device_manager = DeviceManager.get_default ();
        foreach (var dev in devices) {
            device_manager.device_removed ((Music.Device)dev);
        }

        devices = new Gee.ArrayList<CDRomDevice> ();
    }

    public virtual void mount_added (Mount mount) {
        foreach (var dev in devices) {
            if (dev.get_uri () == mount.get_default_location ().get_uri ()) {
                return;
            }
        }

        if (
            mount.get_default_location ().get_uri ().has_prefix ("cdda://") &&
            mount.get_volume () != null
        ) {
            debug ("Adding CD to list");
            var added = new CDRomDevice (mount);
            added.set_mount (mount);
            devices.add (added);

            if (added.start_initialization ()) {
                added.finish_initialization ();
                added.initialized.connect ((d) => {
                    DeviceManager.get_default ().device_initialized ((Music.Device) d);
                });
            } else {
                mount_removed (added.get_mount ());
            }
        } else {
            debug (
                "Found device at %s is not an Audio CD. Not using it",
                mount.get_default_location ().get_parse_name ()
            );

            return;
        }
    }

    public virtual void mount_changed (Mount mount) {
        //stdout.printf ("mount_changed:%s\n", mount.get_uuid ());
    }

    public virtual void mount_pre_unmount (Mount mount) {
        //stdout.printf ("mount_preunmount:%s\n", mount.get_uuid ());
    }

    public virtual void mount_removed (Mount mount) {
        var device_manager = DeviceManager.get_default ();
        foreach (var dev in devices) {
            if (dev.get_uri () == mount.get_default_location ().get_uri ()) {
                device_manager.device_removed ((Music.Device) dev);

                // Actually remove it
                devices.remove (dev);

                return;
            }
        }
    }

}
