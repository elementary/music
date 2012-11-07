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
    Noise.DevicePreferences pref;
    bool currently_syncing = false;
    bool currently_transferring = false;
    bool sync_cancelled = false;
    bool transfer_cancelled = false;
    bool queue_is_finished = false;
    bool is_androphone = false;
    string current_operation = "";
    LinkedList<string> music_folders;
    LinkedList<string> imported_files;
    
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
        pref = lm.device_manager.get_device_preferences(get_unique_identifier());
        if(pref == null) {
            pref = new Noise.DevicePreferences(get_unique_identifier());
            lm.device_manager.add_device_preferences(pref);
        }
        medias = new LinkedList<Noise.Media> ();
        songs = new LinkedList<Noise.Media> ();
        tagger = new GStreamerTagger();
        music_folders = new LinkedList<string> ();
        imported_files = new LinkedList<string> ();
        
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

        lm.lw.update_sensitivities ();
        Idle.add( () => {
            initialized(this);
            
            return false;
        });
        queue_is_finished = true;
    }
    
    public Noise.DevicePreferences get_preferences() {
        return pref;
    }
    public void finish_initialization() {
        device_unmounted.connect( () => {
            
        });
        
        finish_initialization_thread ();
    }
    public bool start_initialization() {
        return true;
    }
    private async void finish_initialization_thread() {
        Threads.add (() => {
            if (is_androphone) {
                music_folders.add (mount.get_root ().get_uri () + "/Music");
                
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
            LinkedList<string> files = new LinkedList<string> ();
            int items = 0;
            foreach (var folder in music_folders) {
                var music_folder_file = GLib.File.new_for_uri (folder);
                items += lm.fo.count_music_files (music_folder_file, ref files);
            }

            debug ("found %d items to import\n", items);
            tagger.discoverer_import_media (files);
            Idle.add( () => {
                initialized(this);
                
                return false;
            });
        });

        yield;
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
        return "No Description";
    }
    
    public void set_mount(Mount mount) {
        this.mount = mount;
    }
    
    public Mount get_mount() {
        return mount;
    }
    
    public string get_uri() {
        return mount.get_default_location().get_uri();
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
            var file_info = File.new_for_uri(get_uri()).query_filesystem_info("filesystem::*", null);
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
            var file_info = File.new_for_uri(get_uri()).query_filesystem_info("filesystem::*", null);
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
    
    public bool has_custom_view() {
        return false;
    }
    
    public Gtk.Grid get_custom_view() {
        return new Gtk.Grid();
    }
    
    public bool read_only() {
        return false;
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
       if(currently_syncing) {
            warning("Tried to sync when already syncing\n");
            return false;
        }
        else if(lm.doing_file_operations()) {
            warning("Can't sync. Already doing file operations\n");
            return false;
        }
        
        if (lm.start_file_operations (_("Syncing <b>%s</b>...").printf (getDisplayName ()))) {
            current_operation = _("Syncing <b>%s</b>...").printf (getDisplayName ());
            lm.lw.update_sensitivities();
            this.list = list;
            
            currently_syncing = true;
            index = 0;
            total = 100;
            Timeout.add(500, doProgressNotificationWithTimeout);
            
            sync_medias_thread ();
        }
        return true;
    }
    
    private async void sync_medias_thread () {
        
        Threads.add (() => {
            int sub_index = 0;
            
            message("Found %d medias to sync.", list_to_sync ().size);
            Gee.LinkedList<Noise.Media> medias_to_remove = delete_doubles (songs, list_to_sync ());
            message("Found %d medias to remove.", medias_to_remove.size);
            Gee.LinkedList<Noise.Media> medias_to_sync = delete_doubles (list_to_sync (), songs);
            message("Found %d medias to add.", medias_to_sync.size);
            int total_medias = medias_to_remove.size + medias_to_sync.size;
            
            if (total_medias > 0) {
                if (will_fit_without(medias_to_sync, medias_to_remove)) {
                    foreach(var m in medias_to_remove) {
                        if(!sync_cancelled) {
                            remove_media(m);
                        }
                        ++sub_index;
                        index = (int)(85.0 * (double)((double)sub_index/(double)total_medias));
                    }
                    sub_index = 0;
                    imported_files = new LinkedList<string> ();
                    foreach(var m in medias_to_sync) {
                        if(!sync_cancelled) {
                            add_media(m);
                        }
                        ++sub_index;
                        index = (int)(85.0 * ((double)sub_index/(double)total_medias));
                    }
                    tagger.discoverer_import_media (imported_files);
                    
                    if(!sync_cancelled) {
                        // sync playlists
                        index = 90;
                        /* TODO: add support for podcasts & playlists
                        if (pref.sync_all_music == true) {
                            sync_playlists();
                        }
                        if (pref.sync_all_podcasts == true) {
                            sync_podcasts();
                        }*/
                        
                        current_operation = _("Finishing sync process...");
                        
                        index = 98;
                        
                    } else {
                        current_operation = _("Cancelling Sync...");
                        index = total + 1;
                    }
                } else {
                        infobar_message (_("There is not enough space on Device to complete the Sync..."), Gtk.MessageType.INFO);
                        current_operation = _("There is not enough space on Device to complete the Sync...");
                }
            }

            Idle.add( () => {
                index = total + 1;
                pref.last_sync_time = (int)time_t();
                currently_syncing = false;
                
                sync_finished(!sync_cancelled);
                lm.finish_file_operations();
                lm.lw.update_sensitivities();
                sync_cancelled = false;
                
                return false;
            });
        });

        yield;
    }
        
    public Gee.LinkedList<Noise.Media> list_to_sync () {
        var medias_to_sync = new Gee.LinkedList<Noise.Media> ();
        if (pref.sync_music == true) {
            if (pref.sync_all_music == true) {
                foreach (Media m in lm.media ()) {
                    if (m != null)
                        medias_to_sync.add (m);
                }
            } else {
                foreach (Media m in lm.playlist_from_name (pref.music_playlist).media ()) {
                    if (m != null)
                        medias_to_sync.add (m);
                }
            }
        }
        return medias_to_sync;
    }
    
    public Gee.LinkedList<Noise.Media> delete_doubles (Gee.Collection<Noise.Media> source_list, Gee.Collection<Noise.Media> to_remove) {
        var new_list = new Gee.LinkedList<Noise.Media> ();
        foreach(var m in source_list) {
            if (m != null) {
                bool needed = true;
                foreach(var med in to_remove) {
                    if (med != null && med.title != null) {
                        if (med.album != null && m.album != null) { // If you don't have the album name, don't care of it
                            if(med.title.down() == m.title.down() && med.artist.down() == m.artist.down() && med.album.down() == m.album.down()) {
                                needed = false;
                                break;
                            }
                        } else {
                            if(med.title.down() == m.title.down() && med.artist.down() == m.artist.down()) {
                                needed = false;
                                break;
                            }
                        }
                    }
                }
                if (needed == true)
                    new_list.add (m);
            }
        }
        
        return new_list;
    }
    public bool add_medias(LinkedList<Noise.Media> list) {
        if(currently_syncing) {
            warning("Tried to add when already syncing\n");
            return false;
        }
        else if(lm.doing_file_operations()) {
            warning("Can't add. Already doing file operations\n");
            return false;
        }
        
        if (lm.start_file_operations (_("Syncing <b>%s</b>...").printf (getDisplayName ()))) {
            current_operation = _("Syncing <b>%s</b>...").printf (getDisplayName ());
            lm.lw.update_sensitivities();
            this.list = list;
            
            currently_syncing = true;
            index = 0;
            Timeout.add(500, doProgressNotificationWithTimeout);
            int sub_index = 0;
            
            Gee.LinkedList<Noise.Media> medias_to_sync = delete_doubles (list, songs);
            message("Found %d medias to add.", medias_to_sync.size);
            int total_medias = medias_to_sync.size;
            
            if (total_medias > 0) {
                if (will_fit(medias_to_sync)) {
                    imported_files = new LinkedList<string> ();
                    foreach(var m in medias_to_sync) {
                        add_media(m);
                        ++sub_index;
                        index = (int)(100.0 * ((double)sub_index/(double)total_medias));
                    }
                    tagger.discoverer_import_media (imported_files);
                }
            }
        }
        return true;
    }
    
    public bool remove_medias(LinkedList<Noise.Media> list) {
        if(currently_syncing) {
            warning("Tried to add when already syncing\n");
            return false;
        }
        else if(lm.doing_file_operations()) {
            warning("Can't add. Already doing file operations\n");
            return false;
        }
        
        if (lm.start_file_operations (_("Removing from <b>%s</b>...").printf (getDisplayName ()))) {
            current_operation = _("Removing from <b>%s</b>...").printf (getDisplayName ());
            lm.lw.update_sensitivities();
            
            currently_syncing = true;
            index = 0;
            total = list.size;
            Timeout.add(500, doProgressNotificationWithTimeout);
            
            int sub_index = 0;
            foreach(var m in list) {
                remove_media(m);
                ++sub_index;
                index = (int)(100.0 * ((double)sub_index/(double)total));
            }
        }
        
        return true;
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
        
        current_operation = _("Importing <b>$NAME</b> by <b>$ARTIST</b> to library...");
        current_operation = current_operation.replace ("$NAME", (list.size > 1) ? list.size.to_string() : (list.get(0)).title ?? "");
        current_operation = current_operation.replace ("$ARTIST", (list.size > 1) ? list.size.to_string() : (list.get(0)).artist ?? "");
        lm.start_file_operations(current_operation);
        
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
                
                current_operation = _("Importing <b>$NAME</b> by <b>$ARTIST</b> to library...");
                current_operation = current_operation.replace ("$NAME", copy.title ?? "");
                current_operation = current_operation.replace ("$ARTIST", copy.artist ?? "");
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
    
    private bool will_fit_without(LinkedList<Noise.Media> list, LinkedList<Noise.Media> without) {
        uint64 list_size = 0;
        uint64 without_size = 0;
        foreach(var m in list) {
            list_size += m.file_size;
        }
        foreach(var m in without) {
            without_size += m.file_size;
        }
        if (without_size > list_size) {
            return true;
        } else {
            return get_capacity() > (list_size - without_size);
        }
    }
    
    public bool doProgressNotificationWithTimeout() {
        progress_notification(current_operation.replace("&", "&amp;"), (double)((double)index)/((double)total));
        
        if(index < total && (is_syncing() || is_transferring())) {
            return true;
        }
        
        return false;
    }
    
    void add_media(Noise.Media m) {
        if(m == null)
            return;

        current_operation = _("Adding <b>$NAME</b> by <b>$ARTIST</b> to $DEVICE");
        current_operation = current_operation.replace ("$NAME", m.title ?? "");
        current_operation = current_operation.replace ("$ARTIST", m.artist ?? "");
        current_operation = current_operation.replace ("$DEVICE", getDisplayName() ?? "");
        debug ("Adding media %s by %s\n", m.title, m.artist);
        
        var file = File.new_for_uri (m.uri);
        var destination_file = File.new_for_uri (music_folders.get(0) + file.get_basename ());
        
        try {
            file.copy (destination_file,GLib.FileCopyFlags.ALL_METADATA);
        } catch(Error err) {
            warning("Failed to copy track %s : %s\n", m.title, err.message);
            return;
        }
        imported_files.add (destination_file.get_uri());
    }
    
    void remove_media(Noise.Media m) {
        current_operation = _("Removing <b>$NAME</b> by <b>$ARTIST</b> to $DEVICE");
        current_operation = current_operation.replace ("$NAME", m.title ?? "");
        current_operation = current_operation.replace ("$ARTIST", m.artist ?? "");
        current_operation = current_operation.replace ("$DEVICE", getDisplayName() ?? "");
        /* first check if the file exists disk */
        if(m.uri != null) {
            var file = File.new_for_uri(m.uri);
            
            if(file.query_exists()) {
                medias.remove (m);
                songs.remove (m);
                try {
                    file.delete();
                } catch(Error err) {
                    warning("Could not delete File at %s: %s", m.uri, err.message);
                    return;
                }
                warning ("Successfully removed music file %s", m.uri);
            }
            else {
                warning("File not found, could not delete File at %s. File may already be deleted", m.uri);
            }
        }
        
    }
}
