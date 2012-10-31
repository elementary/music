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

public class Noise.Plugins.AudioPlayerDevice : GLib.Object, Noise.Device {

    Mount mount;
    Gdk.Pixbuf icon;
    int index = 0;
    int total = 0;
    LinkedList<Noise.Media> medias;
    LinkedList<Noise.Media> songs;
    LinkedList<Noise.Media> list;
    Noise.LibraryManager lm;
    bool currently_syncing = false;
    bool currently_transferring = false;
    bool sync_cancelled = false;
    bool transfer_cancelled = false;
    bool queue_is_finished = false;
    bool is_androphone = false;
    string current_operation = "";
    
    public GStreamerTagger tagger;
    
    public AudioPlayerDevice(Mount mount, Noise.LibraryManager lm, bool is_androphone) {
        this.lm = lm;
        this.mount = mount;
        this.is_androphone = is_androphone;
        if (is_androphone) {
            icon = Icons.render_icon("phone", Gtk.IconSize.MENU);
        } else {
            icon = Icons.render_icon("music-player", Gtk.IconSize.MENU);
        }
        medias = new LinkedList<Noise.Media> ();
        songs = new LinkedList<Noise.Media> ();
        tagger = new GStreamerTagger();
        
        tagger.media_imported.connect(media_imported);
        tagger.import_error.connect(import_error);
        tagger.queue_finished.connect(queue_finished);
    }
    
    void media_imported(Media m) {
        m.isTemporary = true;
        this.medias.add(m);
        this.songs.add(m);
        if (queue_is_finished)
            sync_finished (true);
    }
    
    void import_error(string file) {
    
    }
    
    void queue_finished() {
        lm.finish_file_operations();

        lm.lw.update_sensitivities ();
        Idle.add( () => {
            initialized(this);
            
            return false;
        });
        queue_is_finished = true;
    }
    
    public Noise.DevicePreferences get_preferences() {
        return new Noise.DevicePreferences(get_unique_identifier());
    }
    public void finish_initialization() {
        device_unmounted.connect( () => {
            
        });
        
        Threads.add (finish_initialization_thread);
    }
    public bool start_initialization() {
        return true;
    }
    void finish_initialization_thread() {
        LinkedList<string> files = new LinkedList<string> ();
        int items = 0;
        if (is_androphone) {
            var music_folder_file = GLib.File.new_for_uri (mount.get_root ().get_uri () + "/Music");
            items = lm.fo.count_music_files (music_folder_file, ref files);
        } else {
            var file = GLib.File.new_for_path(mount.get_root ().get_path () + "/.is_audio_player");
            LinkedList<string> folders = new LinkedList<string> ();
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
                                warning (folder);
                                folders.add (folder);
                            }
                        }
                    }
                }
            } catch (Error e) {
                stderr.printf ("Error: %s\n", e.message);
            }
            foreach (var folder in folders) {
                var music_folder_file = GLib.File.new_for_uri (mount.get_root ().get_uri () + "/" + folder);
                items += lm.fo.count_music_files (music_folder_file, ref files);
            }
        }

        debug ("found %d items to import\n", items);
        tagger.discoverer_import_media (files);
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
        uint64 rv = 0;
        
        try {
            var file_info = File.new_for_path(get_path()).query_filesystem_info("filesystem::*", null);
            rv = file_info.get_attribute_uint64(GLib.FileAttribute.FILESYSTEM_SIZE);
        }
        catch(Error err) {
            stdout.printf("Error calculating capacity of iPod: %s\n", err.message);
        }
        
        return rv;
    }
    
    public string get_fancy_capacity() {
        return GLib.format_size (get_capacity());
    }
    
    public uint64 get_used_space() {
        return get_capacity() - get_free_space();
    }
    
    public uint64 get_free_space() {
        uint64 rv = 0;
        
        try {
            var file_info = File.new_for_path(get_path()).query_filesystem_info("filesystem::*", null);
            rv = file_info.get_attribute_uint64(GLib.FileAttribute.FILESYSTEM_FREE);
        }
        catch(Error err) {
            stdout.printf("Error calculating free space on iPod: %s\n", err.message);
        }
        
        return rv;
    }
    
    public void unmount() {
        mount.unmount_with_operation (GLib.MountUnmountFlags.NONE, null);
    }
    
    public void eject() {
        if (mount.can_eject ()) {
            mount.get_volume ().get_drive ().eject_with_operation (GLib.MountUnmountFlags.NONE, null);
        }
    }
    
    
    public void get_device_type() {
        
    }
    
    public bool supports_podcasts() {
        return false;
    }
    
    public bool supports_audiobooks() {
        return false;
    }
    
    public Collection<Noise.Media> get_medias() {
        return medias;
    }
    
    public Collection<Noise.Media> get_songs() {
        return songs;
    }
    
    public Collection<Noise.Media> get_podcasts() {
        return new LinkedList<Noise.Media>();
    }
    
    public Collection<Noise.Media> get_audiobooks() {
        return new LinkedList<Noise.Media>();
    }
    
    public Collection<Noise.Media> get_playlists() {
        return new LinkedList<Noise.Media>();
    }
    
    public Collection<Noise.Media> get_smart_playlists() {
        return new LinkedList<Noise.Media>();
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
    
    public bool transfer_to_library(LinkedList<Noise.Media> tr_list) {
        if(currently_transferring) {
            warning("Tried to sync when already syncing\n");
            return false;
        }
        else if(lm.doing_file_operations()) {
            warning("Can't sync. Already doing file operations\n");
            return false;
        }
        else if(tr_list == null || tr_list.size == 0) {
            warning("No songs in transfer list\n");
            return false;
        }
        
        this.list = tr_list;
        lm.start_file_operations(_("Importing <b>%s</b> to library...").printf((list.size > 1) ? list.size.to_string() : (list.get(0)).title));
        current_operation = "Importing <b>" + ((list.size > 1) ? list.size.to_string() : (list.get(0)).title) + "</b> items to library...";
        
        Threads.add (transfer_medias_thread);
        
        return true;
    }
    
    void transfer_medias_thread() {
        if(this.list == null || this.list.size == 0)
            return;
        
        currently_transferring = true;
        transfer_cancelled = false;
        index = 0;
        total = list.size;
        Timeout.add(500, doProgressNotificationWithTimeout);
        
        foreach(var m in list) {
            if(transfer_cancelled)
                break;
            
            Noise.Media copy = m.copy();
            if(File.new_for_uri(copy.uri).query_exists()) {
                copy.rowid = 0;
                copy.isTemporary = false;
                copy.date_added = (int)time_t();
                lm.add_media_item (copy);
                
                current_operation = "Importing <b>" + copy.title + "</b> to library";
                lm.fo.update_file_hierarchy (copy, false, false);
            }
            else {
                stdout.printf("Skipped transferring media %s. Either already in library, or has invalid file path to ipod.\n", copy.title);
            }
            
            ++index;
        }
        
        index = total + 1;
        
        Idle.add( () => {
            lm.finish_file_operations();
            currently_transferring = false;
            
            return false;
        });
    }
    
    public bool is_syncing() {
        return currently_syncing;
    }
    
    public bool is_transferring() {
        return currently_transferring;
    }
    
    public void cancel_sync() {
        sync_cancelled = true;
    }
    
    public void cancel_transfer() {
        transfer_cancelled = true;
    }
    
    public bool will_fit(LinkedList<Noise.Media> list) {
        uint64 list_size = 0;
        foreach(var m in list) {
            list_size += m.file_size;
        }
        
        return get_capacity() > list_size;
    }
    
    public bool doProgressNotificationWithTimeout() {
        progress_notification(current_operation.replace("&", "&amp;"), (double)((double)index)/((double)total));
        
        if(index < total && (is_syncing() || is_transferring())) {
            return true;
        }
        
        return false;
    }
}
