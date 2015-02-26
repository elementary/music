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
 
public class Noise.Plugins.AudioPlayerDevice : GLib.Object, Noise.Device {

    Mount mount;
    GLib.Icon icon;
    Noise.DevicePreferences pref;
    bool is_androphone = false;
    Gee.LinkedList<string> music_folders;
    
    private AudioPlayerLibrary library;
    
    
    public AudioPlayerDevice(Mount mount, bool is_androphone) {
        this.mount = mount;
        this.is_androphone = is_androphone;
        music_folders = new Gee.LinkedList<string> ();
        library = new AudioPlayerLibrary (this);
        libraries_manager.add_library (library);
        icon = new Icon (is_androphone ? "phone" : "music-player").gicon;
        var device_manager = DeviceManager.get_default ();
        pref = device_manager.get_device_preferences (get_unique_identifier());
        if(pref == null) {
            pref = new Noise.DevicePreferences (get_unique_identifier());
            device_manager.add_device_preferences (pref);
        }
    }
    
    public Noise.DevicePreferences get_preferences() {
        return pref;
    }
    public void finish_initialization() {
        device_unmounted.connect( () => {
            
        });
        
        finish_initialization_async.begin ();
    }
    public bool start_initialization() {
        return true;
    }
    private async void finish_initialization_async() {
        if (is_androphone) {
            music_folders.add (mount.get_root ().get_uri () + "/Music/");
            
        } else {
            var file = GLib.File.new_for_uri(mount.get_root ().get_uri () + "/.is_audio_player");
            try {
                if(file.query_exists() == true){
                    var dis = new DataInputStream (file.read ());
                    string line;
                    // Read lines until end of file (null) is reached
                    while ((line = dis.read_line (null)) != null) {
                        if (line.contains ("audio_folders=")) {
                            string folders_unparsed = line.split ("audio_folders=", 2)[1];
                            foreach (var folder in folders_unparsed.split (",")) {
                                folder = folder.replace (" ", "");
                                music_folders.add (mount.get_root ().get_uri () + "/" + folder);
                            }
                        }
                    }
                }
            } catch (Error e) {
                stderr.printf ("Error: %s\n", e.message);
            }
        }
        Gee.LinkedList<string> files = new Gee.LinkedList<string> ();
        int items = 0;
        foreach (var folder in music_folders) {
            var music_folder_file = GLib.File.new_for_uri (folder);
            items += FileUtils.count_music_files (music_folder_file, files);
        }

        debug ("found %d items to import\n", items);
        library.tagger.discoverer_import_media (files);
        if (files.size == 0)
            library.queue_finished ();

        Idle.add( () => {
            
            return false;
        });
    }
    
    public Library get_library() {
        return library;
    }
    
    public string getEmptyDeviceTitle() {
        return _("Empty device!");
    }
    
    public string getEmptyDeviceDescription() {
        return _("This device does not contain any music.");
    }
    
    public string getContentType() {
        if (is_androphone) {
            return "android";
        } else {
            return "audioplayer";
        }
    }
    public string getDisplayName() {
        if (is_androphone) {
            return mount.get_name();
        } else {
            var file = GLib.File.new_for_path(mount.get_root ().get_path () + "/.is_audio_player");
            string name = mount.get_name();
            try {
                if(file.query_exists() == true){
                    var dis = new DataInputStream (file.read ());
                    string line;
                    // Read lines until end of file (null) is reached
                    while ((line = dis.read_line (null)) != null) {
                        if (line.contains ("name=")) {
                            string names_unparsed = line.split ("name=", 2)[1];
                            foreach (var names in names_unparsed.split ("\"")) {
                                if (names != null && names != "")
                                    name = names;
                            }
                        }
                    }
                }
            } catch (Error e) {
                stderr.printf ("Error: %s\n", e.message);
            }
            return name;
        }
    }
    
    public void setDisplayName(string name) {
        
    }
    
    public string get_fancy_description() {
        if (is_androphone) {
            return _("Android Phone");
        } else {
            return _("Audio Player");
        }
    }
    
    public void set_mount(Mount mount) {
        this.mount = mount;
    }
    
    public Mount? get_mount() {
        return mount;
    }
    
    public string get_uri() {
        return mount.get_default_location().get_uri();
    }
    
    public void set_icon(GLib.Icon icon) {
        this.icon = icon;
    }
    
    public GLib.Icon get_icon() {
        return icon;
    }
    

    public uint64 get_capacity() {
        uint64 rv = 0;
        
        try {
            var file_info = File.new_for_uri(get_uri()).query_filesystem_info("filesystem::*", null);
            rv = file_info.get_attribute_uint64(GLib.FileAttribute.FILESYSTEM_SIZE);
        } catch(Error err) {
            stdout.printf("Error calculating capacity of iPod: %s\n", err.message);
        }
        
        return (uint64)rv;
    }
    
    public string get_fancy_capacity() {
        return GLib.format_size (get_capacity());
    }
    
    public uint64 get_used_space() {
        return get_capacity() - get_free_space();
    }
    
    public string get_music_folder () {
        return music_folders.get(0);
    }
    
    public uint64 get_free_space() {
        uint64 rv = 0;
        
        try {
            var file_info = File.new_for_uri(get_uri()).query_filesystem_info("filesystem::*", null);
            rv = file_info.get_attribute_uint64(GLib.FileAttribute.FILESYSTEM_FREE);
        } catch(Error err) {
            stdout.printf("Error calculating free space on iPod: %s\n", err.message);
        }
        
        return rv;
    }
    
    public void unmount() {
        mount.unmount_with_operation.begin (GLib.MountUnmountFlags.NONE, null);
    }
    
    public void eject() {
        if (mount.can_eject ()) {
            mount.get_volume ().get_drive ().eject_with_operation.begin (GLib.MountUnmountFlags.NONE, null);
        }
    }
    
    public void synchronize () {
        library.sync_medias ();
    }
    
    public bool only_use_custom_view () {
        return false;
    }
    
    public Gtk.Widget? get_custom_view() {
        return null;
    }
    
    public bool read_only() {
        return false;
    }
}
