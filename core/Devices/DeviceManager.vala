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

using Gee;

public class Noise.DeviceManager : GLib.Object {
    VolumeMonitor vm;
    
    public Gee.ArrayList<DevicePreferences> device_preferences;
    public Gee.ArrayList<unowned Device> devices;
    
    public signal void device_added(Device d);
    public signal void device_removed(Device d);
    public signal void device_name_changed (Device d);
    public signal void device_asked_sync (Device d);
    public signal void device_asked_transfer (Device d, Collection<Noise.Media> list);
    
    public signal void cancel_device_transfer ();
    
    public signal void mount_added (Mount mount);
    public signal void mount_removed (Mount mount);
    
    public DeviceManager() {
        
        device_preferences = new Gee.ArrayList<DevicePreferences> ();
        devices = new Gee.ArrayList<unowned Device> ();
        
        vm = VolumeMonitor.get();
        
        vm.mount_added.connect((mount) => {mount_added (mount);});
        vm.mount_changed.connect(mount_changed);
        vm.mount_pre_unmount.connect(mount_pre_unmount);
        vm.mount_removed.connect((mount) => {mount_removed (mount);});
        vm.volume_added.connect(volume_added);
    }
    
    public void set_device_preferences (Gee.Collection<DevicePreferences> device_preferences) {
        this.device_preferences.add_all (device_preferences);
    }
    
    public void loadPreExistingMounts() {
        // this can take time if we have to rev up the cd drive
        Threads.add (get_pre_existing_mounts);
    }
    
    public void get_pre_existing_mounts () {
        var mounts = new LinkedList<Mount>();
        var volumes = new LinkedList<Volume>();
        
        foreach(var m in vm.get_mounts()) {
            mounts.add(m);
        }
        
        foreach(var v in vm.get_volumes()) {
            volumes.add(v);
        }
        
        Idle.add( () => {
            
            foreach(var m in mounts) {
                mount_added(m);
            }
            
            foreach(var v in volumes) {
                volume_added(v);
            }
            
            return false;
        });
    }
    
    void volume_added(Volume volume) {
        if(main_settings.music_mount_name == volume.get_name() && volume.get_mount() == null) {
            debug ("mounting %s because it is believed to be the music folder\n", volume.get_name());
            volume.mount.begin (MountMountFlags.NONE, null, null);
        }
    }
    
    public void deviceInitialized (Device d) {
        debug ("adding device\n");
        device_added (d);
        devices.add (d);
    }
    
    public virtual void mount_changed (Mount mount) {
        //message ("mount_changed:%s\n", mount.get_uuid());
    }
    
    public virtual void mount_pre_unmount (Mount mount) {
        //message ("mount_preunmount:%s\n", mount.get_uuid());
    }
    
    public DevicePreferences? get_device_preferences(string id) {
        foreach (var device in device_preferences) {
            if (device.id == id)
                return device;
        }
        return null;
    }
    
    public void add_device_preferences(DevicePreferences dp) {
        
        lock(device_preferences) {
            device_preferences.add(dp);
        }
    }
}
