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
 
using GPod;
using Gee;

public class Noise.Plugins.AndroidDevice : GLib.Object, Noise.Device {
    Mount mount;
    Gdk.Pixbuf icon;
    
    public AndroidDevice(Mount mount) {
        this.mount = mount;
        icon = Icons.render_icon("phone", Gtk.IconSize.MENU);
    }
    
    public Noise.DevicePreferences get_preferences() {
        return new Noise.DevicePreferences(get_unique_identifier());
    }
    
    public bool start_initialization() {
        return false;
    }
    
    public void finish_initialization() {
        
        //initialized(this);
    }
    
    public string getContentType() {
        return "android";
    }
    public string getDisplayName() {
        return mount.get_name();
    }
    
    public void setDisplayName(string name) {
        
    }
    
    public string get_fancy_description() {
        return "No Description";
    }
    
    public void set_mount(Mount mount) {
        this.mount = mount;
    }
    
    public Mount get_mount() {
        return mount;
    }
    
    public string get_path() {
        return mount.get_default_location().get_path();
    }
    
    public void set_icon(Gdk.Pixbuf icon) {
        this.icon = icon;
    }
    
    public Gdk.Pixbuf get_icon() {
        return icon;
    }
    
    public uint64 get_capacity() {
        return (uint64)0;
    }
    
    public string get_fancy_capacity() {
        return "Unknown capacity";
    }
    
    public uint64 get_used_space() {
        return (uint64)0;
    }
    
    public uint64 get_free_space() {
        return (uint64)0;
    }
    
    public void unmount() {
        mount.unmount_with_operation (GLib.MountUnmountFlags.NONE, null);
    }
    
    public void eject() {
        mount.eject_with_operation (GLib.MountUnmountFlags.NONE, null);
    }
    
    public void get_device_type() {
        
    }
    
    public bool supports_podcasts() {
        return false;
    }
    
    public bool supports_audiobooks() {
        return false;
    }
    
    public Collection<int> get_medias() {
        return new LinkedList<int>();
    }
    
    public Collection<int> get_songs() {
        return new LinkedList<int>();
    }
    
    public Collection<int> get_podcasts() {
        return new LinkedList<int>();
    }
    
    public Collection<int> get_audiobooks() {
        return new LinkedList<int>();
    }
    
    public Collection<int> get_playlists() {
        return new LinkedList<int>();
    }
    
    public Collection<int> get_smart_playlists() {
        return new LinkedList<int>();
    }
    
    public bool sync_medias(LinkedList<Noise.Media> list) {
        return false;
    }
    
    public bool add_medias(LinkedList<Noise.Media> list) {
        return false;
    }
    
    public bool remove_medias(LinkedList<Noise.Media> list) {
        return false;
    }
    
    public bool sync_playlists(LinkedList<int> list) {
        return false;
    }
    
    public bool will_fit(LinkedList<Noise.Media> list) {
        return false;
    }
    
    public bool transfer_to_library(LinkedList<Noise.Media> list) {
        return false;
    }
    
    public bool is_syncing() {
        return false;
    }
    
    public bool is_transferring() {
        return false;
    }
    
    public void cancel_sync() {
        
    }
    
    public void cancel_transfer() {
        
    }
}
