// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012-2013 Noise Developers (http://launchpad.net/noise)
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
 *              Corentin Noël <tintou@mailoo.org>
 */

public class Noise.DeviceManager : GLib.Object {
    VolumeMonitor vm;

    public signal void device_added (Device d);
    public signal void device_removed (Device d);
    public signal void device_name_changed (Device d);

    public signal void mount_added (Mount mount);
    public signal void mount_removed (Mount mount);

    private Gee.TreeSet<DevicePreferences> device_preferences;
    private Gee.TreeSet<unowned Device> initialized_devices;
    private Gee.TreeSet<unowned Mount> mounts_availables;
    private Gee.TreeSet<Playlist> local_playlists;

    private static DeviceManager? device_manager = null;

    public static DeviceManager get_default () {
        if (device_manager == null)
            device_manager = new DeviceManager ();
        return device_manager;
    }

    private DeviceManager () {
        device_preferences = new Gee.TreeSet<DevicePreferences> ();
        initialized_devices = new Gee.TreeSet<unowned Device> ();
        mounts_availables = new Gee.TreeSet<unowned Mount> ();
        local_playlists = new Gee.TreeSet<Playlist> ();

        vm = VolumeMonitor.get ();
        vm.mount_added.connect ((mount) => {mounts_availables.add (mount); mount_added (mount);});
        vm.mount_changed.connect (mount_changed);
        vm.mount_pre_unmount.connect (mount_pre_unmount);
        vm.mount_removed.connect ((mount) => {mounts_availables.remove (mount); mount_removed (mount);});
        vm.volume_added.connect (volume_added);
        get_pre_existing_mounts.begin ();
    }

    public void set_device_preferences (Gee.Collection<DevicePreferences> device_preferences) {
        this.device_preferences.add_all (device_preferences);
    }

    public async void get_pre_existing_mounts () {
        var mounts = new Gee.TreeSet<Mount> ();
        var volumes = new Gee.TreeSet<Volume> ();

        foreach (var m in vm.get_mounts ()) {
            mounts.add (m);
        }

        foreach (var v in vm.get_volumes ()) {
            volumes.add (v);
        }

        Idle.add(() => {
            foreach (var m in mounts) {
                mounts_availables.add (m); 
                mount_added (m);
            }

            foreach (var v in volumes) {
                volume_added (v);
            }

            return false;
        });
    }

    void volume_added(Volume volume) {
        if(Settings.Main.get_default ().music_mount_name == volume.get_name () && volume.get_mount () == null) {
            debug ("mounting %s because it is believed to be the music folder\n", volume.get_name ());
            volume.mount.begin (MountMountFlags.NONE, null, null);
        }
    }

    public void device_initialized (Device d) {
        debug ("adding device\n");
        device_added (d);
        initialized_devices.add (d);
    }

    public virtual void mount_changed (Mount mount) {
        //message ("mount_changed:%s\n", mount.get_uuid());
    }

    public virtual void mount_pre_unmount (Mount mount) {
        //message ("mount_preunmount:%s\n", mount.get_uuid());
    }

    public DevicePreferences? get_device_preferences (string id) {
        foreach (var device in device_preferences) {
            if (device.id == id)
                return device;
        }

        return null;
    }

    public Gee.Collection<unowned Device> get_initialized_devices () {
        return initialized_devices;
    }

    public Gee.Collection<unowned Mount> get_available_mounts () {
        return mounts_availables;
    }

    public void add_device_preferences (DevicePreferences dp) {
        lock (device_preferences) {
            device_preferences.add (dp);
        }
    }
}
