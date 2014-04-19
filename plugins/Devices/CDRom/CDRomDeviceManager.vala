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

public class Noise.Plugins.CDRomDeviceManager : GLib.Object {
    Gee.ArrayList<CDRomDevice> devices;

    public CDRomDeviceManager() {
        devices = new Gee.ArrayList<CDRomDevice>();

        var device_manager = DeviceManager.get_default ();
        device_manager.mount_added.connect (mount_added);
        device_manager.mount_removed.connect (mount_removed);
        foreach (var mount in device_manager.get_available_mounts ()) {
            mount_added (mount);
        }
    }

    public void remove_all () {
        var device_manager = DeviceManager.get_default ();
        foreach(var dev in devices) {
            device_manager.device_removed ((Noise.Device)dev);
        }

        devices = new Gee.ArrayList<CDRomDevice>();
    }

    public virtual void mount_added (Mount mount) {
        foreach(var dev in devices) {
            if(dev.get_uri() == mount.get_default_location().get_uri()) {
                return;
            }
        }
        if(mount.get_default_location().get_uri().has_prefix("cdda://") && mount.get_volume() != null) {
            var added = new CDRomDevice(mount);
            added.set_mount(mount);
            devices.add(added);

            if(added.start_initialization()) {
                added.finish_initialization();
                added.initialized.connect((d) => {DeviceManager.get_default ().device_initialized ((Noise.Device)d);});
            }
            else {
                mount_removed(added.get_mount());
            }
        }
        else {
            debug ("Found device at %s is not an Audio CD. Not using it", mount.get_default_location().get_parse_name());
            return;
        }
    }

    public virtual void mount_changed (Mount mount) {
        //stdout.printf("mount_changed:%s\n", mount.get_uuid());
    }

    public virtual void mount_pre_unmount (Mount mount) {
        //stdout.printf("mount_preunmount:%s\n", mount.get_uuid());
    }

    public virtual void mount_removed (Mount mount) {
        var device_manager = DeviceManager.get_default ();
        foreach(var dev in devices) {
            if(dev.get_uri() == mount.get_default_location().get_uri()) {
                device_manager.device_removed ((Noise.Device)dev);

                // Actually remove it
                devices.remove(dev);

                return;
            }
        }
    }

}