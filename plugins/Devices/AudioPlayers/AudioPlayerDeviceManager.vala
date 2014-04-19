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

public class Noise.Plugins.AudioPlayerDeviceManager : GLib.Object {
    Gee.ArrayList<AudioPlayerDevice> devices;

    public AudioPlayerDeviceManager() {
        devices = new Gee.ArrayList<AudioPlayerDevice>();

        var device_manager = DeviceManager.get_default ();
        device_manager.mount_added.connect (mount_added);
        device_manager.mount_removed.connect (mount_removed);
        foreach (var mount in device_manager.get_available_mounts ()) {
            mount_added (mount);
        }
    }

    public void remove_all () {
        foreach(var dev in devices) {
            DeviceManager.get_default ().device_removed ((Noise.Device)dev);
        }

        devices = new Gee.ArrayList<AudioPlayerDevice>();
    }

    public virtual void mount_added (Mount mount) {
        foreach(var dev in devices) {
            if(dev.get_uri() == mount.get_default_location().get_uri()) {
                return;
            }
        }
        if(File.new_for_uri(mount.get_default_location().get_uri() + "/Android").query_exists() | File.new_for_uri(mount.get_default_location().get_uri() + "/.is_audio_player").query_exists()) {
            var added = new AudioPlayerDevice(mount, File.new_for_uri(mount.get_default_location().get_uri() + "/Android").query_exists());
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
            debug ("Found device at %s is not an Audio Player or Android Phone. Not using it", mount.get_default_location().get_parse_name());
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
        foreach(var dev in devices) {
            if(dev.get_uri() == mount.get_default_location().get_uri()) {
                DeviceManager.get_default ().device_removed ((Noise.Device)dev);

                // Actually remove it
                devices.remove(dev);

                return;
            }
        }
    }

}