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

public class Noise.Plugins.AndroidDeviceManager : GLib.Object {
    Noise.LibraryManager lm;
    ArrayList<AndroidDevice> devices;
    
    //public signal void device_added(AndroidDevice d);
    //public signal void device_removed(AndroidDevice d);
    
    public AndroidDeviceManager(Noise.LibraryManager lm) {
        this.lm = lm;
        devices = new ArrayList<AndroidDevice>();
        
        lm.device_manager.mount_added.connect (mount_added);
        lm.device_manager.mount_removed.connect (mount_removed);
    }
    
    public void remove_all () {
        foreach(var dev in devices) {
            lm.lw.sideTree.deviceRemoved ((Noise.Device)dev);
        }
        devices = new ArrayList<AndroidDevice>();
    }
    
    void volume_added(Volume volume) {
        if(lm.lw.main_settings.music_mount_name == volume.get_name() && volume.get_mount() == null) {
            stdout.printf("mounting %s because it is believed to be the music folder\n", volume.get_name());
            volume.mount(MountMountFlags.NONE, null, null);
        }
    }
    
    public virtual void mount_added (Mount mount) {
        foreach(var dev in devices) {
            if(dev.get_path() == mount.get_default_location().get_path()) {
                return;
            }
        }
        if(File.new_for_path(mount.get_default_location().get_path() + "/Android").query_exists()) {
            var added = new AndroidDevice(mount);
            added.set_mount(mount);
            devices.add(added);
        
            if(added.start_initialization()) {
                added.finish_initialization();
                added.initialized.connect((d) => {lm.device_manager.deviceInitialized ((Noise.Device)d);});
                lm.lw.sideTree.deviceAdded ((Noise.Device)added);
            }
            else {
                warning ("stop!");
                mount_removed(added.get_mount());
            }
        }
        else {
            warning ("Found device at %s is not an Android Phone. Not using it", mount.get_default_location().get_parse_name());
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
            if(dev.get_path() == mount.get_default_location().get_path()) {
                lm.lw.sideTree.deviceRemoved ((Noise.Device)dev);
                
                // Actually remove it
                devices.remove(dev);
                
                return;
            }
        }
    }

}
