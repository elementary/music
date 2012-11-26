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

public class Noise.Plugins.iPodDeviceManager : GLib.Object {
    Noise.LibraryManager lm;
    ArrayList<iPodDevice> devices;
    
    //public signal void device_added(iPodDevice d);
    //public signal void device_removed(iPodDevice d);
    
    public iPodDeviceManager(Noise.LibraryManager lm) {
        this.lm = lm;
        devices = new ArrayList<iPodDevice>();
        
        lm.device_manager.mount_added.connect (mount_added);
        lm.device_manager.mount_removed.connect (mount_removed);
    }
    
    public void remove_all () {
        foreach(var dev in devices) {
            lm.device_removed ((Noise.Device)dev);
        }
        devices = new ArrayList<iPodDevice>();
    }
    
    public virtual void mount_added (Mount mount) {
        foreach(var dev in devices) {
            if(dev.get_uri() == mount.get_default_location().get_uri()) {
                return;
            }
        }
        if(File.new_for_uri(mount.get_default_location().get_uri() + "/iTunes_Control").query_exists() ||
                File.new_for_uri(mount.get_default_location().get_uri() + "/iPod_Control").query_exists() ||
                File.new_for_uri(mount.get_default_location().get_uri() + "/iTunes/iTunes_Control").query_exists() ||
                mount.get_default_location().get_parse_name().has_prefix("afc://")) {
            var added = new iPodDevice(lm, mount);
            added.set_mount(mount);
            devices.add(added);
        
            if(added.start_initialization()) {
                added.finish_initialization();
                added.initialized.connect((d) => {lm.device_manager.deviceInitialized ((Noise.Device)d);});
            }
            else {
                mount_removed(added.get_mount());
            }
        }
        else {
            debug ("Found device at %s is not an iPod. Not using it", mount.get_default_location().get_uri());
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
                lm.device_removed ((Noise.Device)dev);
                
                // Actually remove it
                devices.remove(dev);
                
                return;
            }
        }
    }

}
