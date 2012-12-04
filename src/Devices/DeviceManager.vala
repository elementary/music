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

using Gee;

public class Noise.DeviceManager : GLib.Object {
    LibraryManager lm;
    VolumeMonitor vm;
    
    GLib.List <DevicePreferences> _device_preferences;
    Gee.LinkedList <unowned Device> _devices;
    
    public signal void device_added(Device d);
    public signal void device_removed(Device d);
    
    public signal void mount_added (Mount mount);
    public signal void mount_removed (Mount mount);
    
    public DeviceManager(LibraryManager lm) {
        this.lm = lm;
        
        _device_preferences = new GLib.List <DevicePreferences> ();
        _devices = new Gee.LinkedList <unowned Device> ();
        
        // pre-load devices and their preferences
        
        lock(_device_preferences) {
            _device_preferences = lm.dbm.load_devices();
        }
        
        vm = VolumeMonitor.get();
        
        vm.mount_added.connect((mount) => {mount_added (mount);});
        vm.mount_changed.connect(mount_changed);
        vm.mount_pre_unmount.connect(mount_pre_unmount);
        vm.mount_removed.connect((mount) => {mount_removed (mount);});
        vm.volume_added.connect(volume_added);
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
            volume.mount(MountMountFlags.NONE, null, null);
        }
    }
    
    public void deviceInitialized (Device d) {
        debug ("adding device\n");
        device_added (d);
        _devices.add (d);
        lm.lw.update_sensitivities();
    }
    
    public virtual void mount_changed (Mount mount) {
        //message ("mount_changed:%s\n", mount.get_uuid());
    }
    
    public virtual void mount_pre_unmount (Mount mount) {
        //message ("mount_preunmount:%s\n", mount.get_uuid());
    }
    
        
    /** Device Preferences **/
    public GLib.List<DevicePreferences> device_preferences() {
        var rv = new GLib.List<Noise.DevicePreferences>();
        
        lock(_device_preferences) {
            foreach(var pref in _device_preferences) {
                rv.append(pref);
            }
        }
        
        return rv;
    }
    
    public Gee.LinkedList<unowned Device> devices () {
        return _devices;
    }
    
    public DevicePreferences? get_device_preferences(string id) {
        foreach (var device in _device_preferences) {
            if (device.id == id)
                return device;
        }
        return null;
    }
    
    public void add_device_preferences(DevicePreferences dp) {
        
        lock(_device_preferences) {
            _device_preferences.append(dp);
        }
    }
}
