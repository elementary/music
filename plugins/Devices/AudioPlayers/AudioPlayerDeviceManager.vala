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
 * Authored by: Corentin Noël <corentin@elementary.io>
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
                App.main_window.view_manager.remove_view (dev.music_view);
                App.main_window.view_manager.remove_view (dev.summary_view);
                // App.main_window.view_manager.remove_category (dev.view_category);

                // Actually remove it
                devices.remove(dev);

                return;
            }
        }
    }

}
