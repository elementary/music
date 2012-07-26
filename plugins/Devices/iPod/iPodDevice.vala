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

public class Noise.Plugins.iPodDevice : GLib.Object, Noise.Device {
    Noise.LibraryManager lm;
    Noise.DevicePreferences pref;
    iTunesDB db;
    Mount mount;
    Gdk.Pixbuf icon;
    bool currently_syncing = false;
    bool currently_transferring = false;
    bool sync_cancelled = false;
    bool transfer_cancelled = false;
    LinkedList<Noise.Media> list;
    int index = 0;
    int total = 0;
    string current_operation = "";
    
    HashMap<unowned GPod.Track, Noise.Media> medias;
    HashMap<unowned GPod.Track, Noise.Media> songs;
    HashMap<unowned GPod.Track, Noise.Media> podcasts;
    HashMap<unowned GPod.Track, Noise.Media> audiobooks;
    HashMap<unowned GPod.Playlist, Noise.Playlist> playlists;
    HashMap<unowned GPod.Playlist, Noise.SmartPlaylist> smart_playlists;
    
    HashMap<Noise.Media, unowned GPod.Track> to_add; // used to add all new songs at the end when idle
    
    public iPodDevice(Noise.LibraryManager lm, Mount mount) {
        this.lm = lm;
        this.mount = mount;
        
        pref = lm.device_manager.get_device_preferences(get_unique_identifier());
        if(pref == null) {
            pref = new Noise.DevicePreferences(get_unique_identifier());
            lm.device_manager.add_device_preferences(pref);
        }
        
        if(isNew())
            icon = Icons.render_icon ("phone", Gtk.IconSize.MENU);
        else
            icon = Icons.render_icon ("multimedia-player", Gtk.IconSize.MENU);
        
        medias = new HashMap<unowned GPod.Track, Noise.Media>();
        songs = new HashMap<unowned GPod.Track, Noise.Media>();
        podcasts = new HashMap<unowned GPod.Track, Noise.Media>();
        audiobooks = new HashMap<unowned GPod.Track, Noise.Media>();
        playlists = new HashMap<unowned GPod.Playlist, Noise.Playlist>();
        smart_playlists = new HashMap<unowned GPod.Playlist, Noise.SmartPlaylist>();
        to_add = new HashMap<Noise.Media, unowned GPod.Track>();
    }
    
    public Noise.DevicePreferences get_preferences() {
        return pref;
    }
    
    public bool start_initialization() {
        try {
            db = iTunesDB.parse(get_path());
        }
        catch(Error err) {
            stdout.printf("Error parsing db at %s: %s\n", get_path(), err.message);
            return false;
        }
        
        return true;
    }
    
    public void finish_initialization() {
        device_unmounted.connect( () => {
            
        });
        
        try {
            new Thread<void*>.try (null, finish_initialization_thread);
        }
        catch(GLib.Error err) {
            stdout.printf("ERROR: Could not create thread to finish ipod initialization: %s \n", err.message);
        }
    }
    
    void* finish_initialization_thread() {
        // get all songs first
        for(int i = 0; i < db.tracks.length(); ++i) {
            unowned GPod.Track t = db.tracks.nth_data(i);
            //stdout.printf("found track and rating is %d and app rating %d and id is %d\n", (int)db.tracks.nth_data(i).rating, (int)db.tracks.nth_data(i).app_rating, (int)db.tracks.nth_data(i).id);
            var m = Noise.Media.from_track(get_path(), t);
            
            this.medias.set(t, m);
            if(t.mediatype == GPod.MediaType.AUDIO)
                this.songs.set(t, m);
            else if(t.mediatype == GPod.MediaType.PODCAST || t.mediatype == 0x00000006) // 0x00000006 = video podcast
                this.podcasts.set(t, m);
            else if(t.mediatype == GPod.MediaType.AUDIOBOOK)
                this.audiobooks.set(t, m);
        }
        
        
        //lock(lm._medias) {
            //lm.add_medias(trToSo, false);
        //}
        /*
        for(int i = 0; i < db.playlists.length(); ++i) {
            unowned GPod.Playlist p = db.playlists.nth_data(i);
            
            if(!p.is_spl) {
                Playlist bbPlaylist = Playlist.from_ipod(p);
                
                foreach(unowned GPod.Track t in medias.keys) {
                    if(p.contains_track(t)) {
                        bbPlaylist.addMedia(medias.get(t));
                    }
                }
                
                lm.add_playlist(bbPlaylist);
                playlists.set(p, bbPlaylist.rowid);
            }
            else {
                Noise.SmartPlaylist sp = Noise.SmartPlaylist.from_ipod(p);
                
                
            }
        }*/
        
        Idle.add( () => {
            initialized(this);
            
            return false;
        });
        
        return null;
    }
    
    public bool isNew() {
        return mount.get_default_location().get_parse_name().has_prefix("afc://");
    }
    
    public string getContentType() {
        if(isNew())
            return "ipod-new";
        else
            return "ipod-old";
    }
    
    public string getDisplayName() {
        return db.playlist_mpl().name;
    }
    
    public void setDisplayName(string name) {
        db.playlist_mpl().name = name;
        try {
            mount.get_default_location().set_display_name(name);
        }
        catch(GLib.Error err) {
            stdout.printf("Could not set iPod Mount Display Name: %s\n", err.message);
        }
        lm.lw.sideTree.setNameFromObject(lm.lw.sideTree.convertToFilter(lm.lw.sideTree.devices_iter), this, name);
    }
    
    public string get_fancy_description() {
        /*unowned GPod.iPodInfo ipod_info = db.device.get_ipod_info();
        stdout.printf("got here\n");
        GPod.iPodModel enum_model = ipod_info.ipod_model;
        GPod.iPodGeneration enum_gen = ipod_info.ipod_generation;*/
        stdout.printf("got here\n");
        string model = "model here";//GPod.iPodInfo.get_ipod_model_name_string(enum_model);
        stdout.printf("got here\n");
        //var gen = GPod.iPodInfo.get_ipod_generation_string(enum_gen);
        string gen = "gen 1";
        return gen + " " + model;
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
        mount.get_volume ().eject_with_operation (GLib.MountUnmountFlags.NONE, null);
    }
    
    public void get_device_type() {
        
    }
    
    public bool supports_podcasts() {
        return db.device.supports_podcast();
    }
    
    public bool supports_audiobooks() {
        return true; // no device.supports_audiobook(), but there is audiobook playlist
    }
    
    public Collection<Noise.Media> get_medias() {
        return medias.values;
    }
    
    public Collection<Noise.Media> get_songs() {
        return songs.values;
    }
    
    public Collection<Noise.Media> get_podcasts() {
        return podcasts.values;
    }
    
    public Collection<Noise.Media> get_audiobooks() {
        return audiobooks.values;
    }
    
    public Collection<Noise.Playlist> get_playlists() {
        return playlists.values;
    }
    
    public Collection<Noise.SmartPlaylist> get_smart_playlists() {
        return smart_playlists.values;
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
        
        bool fits = will_fit(list);
        if(!fits) {
            warning("Tried to sync medias that will not fit\n");
            return false;
        }
        
        lm.start_file_operations (_("Syncing <b>%s</b>...").printf (getDisplayName ()));
        current_operation = ("Syncing <b>%s</b>...").printf (getDisplayName ());
        lm.lw.update_sensitivities();
        to_add = new HashMap<Noise.Media, unowned GPod.Track>();
        this.list = list;
        
        try {
            new Thread<void*>.try (null, sync_medias_thread);
        }
        catch(GLib.Error err) {
            stdout.printf("ERROR: Could not create thread to sync medias: %s \n", err.message);
            return false;
        }
        
        return true;
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
            list_size += m.file_size; // convert from MB to bytes
        }
        
        return get_capacity() > list_size;
    }
    
    void* sync_medias_thread() {
        currently_syncing = true;
        bool error_occurred = false;
        index = 0;
        int sub_index = 0;
        total = 100;
        Timeout.add(500, doProgressNotificationWithTimeout);
        
        db.start_sync();
        
        // for each song that is on device, but not in this.list, remove
        current_operation = "Removing old medias from iPod and updating current ones";
        var removed = new HashMap<unowned GPod.Track, Noise.Media>();
        foreach(var e in medias.entries) {
            if(!sync_cancelled) {
                Noise.Media match = lm.match_media_to_list(e.value, list);
                
                // If entry e is not on the list to be synced, it is to be removed
                if(match == null) {
                    unowned GPod.Track t = e.key;
                    
                    if(t != null) {
                        remove_media(t);
                        removed.set(t, e.value);
                    }
                }
            }
            
            ++sub_index;
            index = (int)(15.0 * (double)((double)sub_index/(double)medias.size));
        }
        
        medias.unset_all(removed);
        songs.unset_all(removed);
        podcasts.unset_all(removed);
        audiobooks.unset_all(removed);
        
        stdout.printf("Updating existing tracks...\n");
        sub_index = 0;
        // anything left will be synced. update medias that are already on list
        foreach(var entry in medias.entries) {
            if(!sync_cancelled) {
                Noise.Media m = lm.match_media_to_list(entry.value, this.list);
                if(m != null) {
                    unowned GPod.Track t = entry.key;
                    m.update_track(ref t);
                    stdout.printf("updated trac and its rating is %d\n", (int)t.rating);
                    
                    var pix_from_file = lm.get_album_art_from_file(m.rowid);
                    if(pix_from_file != null)
                        t.set_thumbnails_from_pixbuf(pix_from_file);
                }
                else {
                    warning("Could not update %s, no match in sync list. Should have been removed\n", entry.key.title);
                }
            }
            
            index = (int)(15.0 + (double)(10.0 * (double)((double)sub_index /(double)medias.size)));
        }
        
        message("Adding new medias...\n");
        
        // now add all in list that weren't in medias
        current_operation = "Adding new media to iPod...";
        sub_index = 0;
        int new_media_size = 0;
        var list_to_add = new LinkedList<Noise.Media>();
        foreach(Noise.Media m in list) {
            bool found_match = false;
            foreach(var test in medias.values) {
                if(test != m && test.title.down() == m.title.down() && test.artist.down() == m.artist.down()) {
                    found_match = true;
                    break;
                }
            }
            
            if(!found_match) {
                list_to_add.add(m);
                ++new_media_size;
            }
        }
        
        // Actually add new items
        foreach(var m in list_to_add) {
            if(!sync_cancelled) {
                add_media(m);
                ++sub_index;
            }
            
            index = (int)(25.0 + (double)(50.0 * (double)((double)sub_index/(double)new_media_size)));
        }
        
        if(!sync_cancelled) {
            // sync playlists
            index = 78;
            sync_playlists();
            sync_podcasts();
            
            current_operation = "Finishing sync process...";
            
            try {
                db.write();
            }
            catch(GLib.Error err) {
                error_occurred = true;
                sync_cancelled = true;
            }
            
            index = 98;
            
            /// Clean up unused files
            stdout.printf("Cleaning up iPod File System\n");
            var music_folder = File.new_for_path(GPod.Device.get_music_dir(get_path()));
            var used_paths = new LinkedList<string>();
            foreach(unowned GPod.Track t in medias.keys) {
                used_paths.add(Path.build_path("/", get_path(), GPod.iTunesDB.filename_ipod2fs(t.ipod_path)));
            }
            cleanup_files(music_folder, used_paths);
            
            index = 101;
            
            db.stop_sync();
        }
        else {
            current_operation = "Cancelling Sync...";
            try {
                db.write();
            }
            catch(Error err) {
                critical("Error when writing iPod database. iPod contents may be incorrect: %s\n", err.message);
            }
            db.stop_sync();
            index = total + 1;
            sync_cancelled = false;
        }
        
        Idle.add( () => {
            pref.last_sync_time = (int)time_t();
            currently_syncing = false;
            
            sync_finished(!sync_cancelled);
            lm.finish_file_operations();
            
            return false;
        });
        
        return null;
    }
    
    /**********************************
     * Specifically only adding medias. This is different and not a part
     * of sync. This is usually called on drag and drop to iPod.
     *********************************/
    bool add_medias(LinkedList<Noise.Media> list) {
        if(currently_syncing) {
            warning("Tried to add when already syncing\n");
            return false;
        }
        else if(lm.doing_file_operations()) {
            warning("Can't add. Already doing file operations\n");
            return false;
        }
        
        // Check if all current media + this list will fit.
        var new_list = new LinkedList<Noise.Media>();
        foreach(var m in list)
            new_list.add(m);
        foreach(var m in medias.values)
            new_list.add(m);
        bool fits = will_fit(new_list);
        if(!fits) {
            warning("Tried to sync medias that will not fit\n");
            return false;
        }
        
        lm.start_file_operations(_("Syncing <b>%s</b>...").printf (getDisplayName ()));
        current_operation = ("Syncing <b>%s</b>...").printf (getDisplayName ());
        lm.lw.update_sensitivities();
        to_add = new HashMap<Noise.Media, unowned GPod.Track>();
        this.list = list;
        
        try {
            new Thread<void*>.try (null, add_medias_thread);
        }
        catch(GLib.Error err) {
            stdout.printf("ERROR: Could not create thread to add medias: %s \n", err.message);
            return false;
        }
        
        return true;
    }
    
    void* add_medias_thread() {
        currently_syncing = true;
        bool error_occurred = false;
        index = 0;
        total = list.size + 2;
        Timeout.add(500, doProgressNotificationWithTimeout);
        
        db.start_sync();
        
        ++index;
        
        // Actually add new items
        foreach(var m in list) {
            if(!sync_cancelled) {
                add_media(m);
                ++index;
            }
        }
        
        if(!sync_cancelled) {
            current_operation = "Finishing sync process...";
            
            ++index;
            
            try {
                db.write();
            }
            catch(GLib.Error err) {
                critical("Error when writing iPod database. iPod contents may be incorrect: %s\n", err.message);
                error_occurred = true;
                sync_cancelled = true;
            }
            
            index = total + 1;
            
            db.stop_sync();
        }
        else {
            current_operation = "Cancelling Sync...";
            
            try {
                db.write();
            }
            catch(Error err) {
                critical("Error when writing iPod database. iPod contents may be incorrect: %s\n", err.message);
            }
            
            db.stop_sync();
            index = total + 1;
            sync_cancelled = false;
        }
        
        Idle.add( () => {
            currently_syncing = false;
            
            sync_finished(!sync_cancelled);
            lm.finish_file_operations();
            
            return false;
        });
        
        return null;
    }
    
    /* Adds to track list, mpl, and copies the file over */
    void add_media(Noise.Media s) {
        if(s == null)
            return;
        
        GPod.Track t = s.track_from_media();
        
        var pix_from_file = lm.get_album_art_from_file(s.rowid);
        if(pix_from_file != null)
            t.set_thumbnails_from_pixbuf(pix_from_file);
        
        current_operation = "Adding <b>" + t.title + "</b> by <b>" + t.artist + "</b> to " + getDisplayName();
        message("Adding media %s by %s\n", t.title, t.artist);
        db.track_add((owned)t, -1);
        
        unowned GPod.Track added = db.tracks.nth_data(db.tracks.length() - 1);
        
        if(added == null || added.title != s.title) {
            warning("Track was not properly appended. Returning.\n");
            return;
        }
        
        unowned GPod.Playlist mpl = db.playlist_mpl();
        mpl.add_track(added, -1);
        
        if(added.mediatype == GPod.MediaType.PODCAST) {
            unowned GPod.Playlist ppl = db.playlist_podcasts();
            ppl.add_track(added, -1);
        }
        /*else if(added.mediatype == GPod.MediaType.AUDIOBOOK) {
            unowned GPod.Playlist apl = db.playlist_audiobooks();
            apl.add_track(added, -1);
        }*/
        
        bool success = false;
        try {
            success = db.cp_track_to_ipod(added, File.new_for_uri(s.uri).get_path());
            debug("Copied media %s to ipod\n", added.title);
        }
        catch(Error err) {
            warning("Error adding/copying song %s to iPod: %s\n", s.title, err.message);
        }
        
        if(success) {
            Noise.Media on_ipod = Noise.Media.from_track(get_path(), added);
            
            medias.set(added, on_ipod);
            if(added.mediatype == GPod.MediaType.AUDIO)
                this.songs.set(added, on_ipod);
            else if(added.mediatype == GPod.MediaType.PODCAST)
                this.podcasts.set(added, on_ipod);
            else if(added.mediatype == GPod.MediaType.AUDIOBOOK)
                this.audiobooks.set(added, on_ipod);
        }
        else {
            warning("Failed to copy track %s to iPod. Removing it from database.\n", added.title);
            remove_media(added);
        }
    }
    
    /**********************************
     * Specifically only removing medias. This is different and not a part
     * of sync. This is usually called on right click -> Remove.
     *********************************/
    bool remove_medias(LinkedList<Noise.Media> list) {
        if(currently_syncing) {
            warning("Tried to add when already syncing\n");
            return false;
        }
        else if(lm.doing_file_operations()) {
            warning("Can't add. Already doing file operations\n");
            return false;
        }
        
        lm.start_file_operations (_("Removing from <b>%s</b>...").printf (getDisplayName ()));
        current_operation = "Removing from <b>" + getDisplayName() + "</b>...";
        lm.lw.update_sensitivities();
        this.list = list;
        
        try {
            new Thread<void*>.try (null, remove_medias_thread);
        }
        catch(GLib.Error err) {
            stdout.printf("ERROR: Could not create thread to remove medias: %s \n", err.message);
            return false;
        }
        
        return true;
    }
    
    void* remove_medias_thread() {
        currently_syncing = true;
        bool error_occurred = false;
        index = 0;
        total = medias.size + 2;
        Timeout.add(500, doProgressNotificationWithTimeout);
        
        db.start_sync();
        
        ++index; // add first of 2 extra
        
        var removed = new HashMap<unowned GPod.Track, Noise.Media>();
        foreach(var e in medias.entries) {
            foreach(var m in list) {
                if(!sync_cancelled) {
                    // If entry e is on the list to be removed, it is to be removed
                    if(m == e.value) {
                        unowned GPod.Track t = e.key;
                        
                        if(t != null) {
                            remove_media(t);
                            removed.set(t, e.value);
                        }
                    }
                }
            }
            
            ++index;
        }
        
        medias.unset_all(removed);
        songs.unset_all(removed);
        podcasts.unset_all(removed);
        audiobooks.unset_all(removed);
        
        if(!sync_cancelled) {
            current_operation = "Finishing sync process...";
            
            ++index; // add second of 2 extra
            try {
                db.write();
            }
            catch(GLib.Error err) {
                critical("Error when writing iPod database. iPod contents may be incorrect: %s\n", err.message);
                error_occurred = true;
                sync_cancelled = true;
            }
            
            index = total + 1;
            
            db.stop_sync();
        }
        else {
            current_operation = "Cancelling Sync...";
            
            try {
                db.write();
            }
            catch(Error err) {
                critical("Error when writing iPod database. iPod contents may be incorrect: %s\n", err.message);
            }
            
            db.stop_sync();
            index = total + 1;
            sync_cancelled = false;
        }
        
        Idle.add( () => {
            currently_syncing = false;
            
            sync_finished(!sync_cancelled);
            lm.finish_file_operations();
            
            return false;
        });
        
        return null;
    }
    
    void remove_media(GPod.Track t) {
        string title = t.title;
        
        current_operation = "Removing <b>" + t.title + "</b> by <b>" + t.artist + "</b> from " + getDisplayName();
        /* first delete it off disk */
        if(t.ipod_path != null) {
            var path = Path.build_path("/", get_path(), GPod.iTunesDB.filename_ipod2fs(t.ipod_path));
            var file = File.new_for_path(path);
            
            if(file.query_exists()) {
                try {
                    file.delete();
                    debug("Successfully removed music file %s from iPod Disk\n", path);
                }
                catch(Error err) {
                    warning("Could not delete iPod File at %s. Unused file will remain on iPod: %s\n", path, err.message);
                }
            }
            else {
                warning("File not found, could not delete iPod File at %s. File may already be deletedd\n", path);
            }
        }
        
        t.remove();
        
        db.playlist_mpl().remove_track(t);
        db.playlist_podcasts().remove_track(t);
        foreach(unowned GPod.Playlist p in db.playlists) {
            if(p.contains_track(t));
                p.remove_track(t);
        }
        
        message("Removed media %s\n", title);
    }
    
    void cleanup_files(GLib.File music_folder, LinkedList<string> used_paths) {
        GLib.FileInfo file_info = null;
        
        try {
            var enumerator = music_folder.enumerate_children(FileAttribute.STANDARD_NAME + "," + FileAttribute.STANDARD_TYPE, 0);
            while ((file_info = enumerator.next_file ()) != null) {
                var file_path = Path.build_path("/", music_folder.get_path(), file_info.get_name());
                
                if(file_info.get_file_type() == GLib.FileType.REGULAR && !used_paths.contains(file_path)) { /* delete it, it's unused */
                    stdout.printf("Deleting unused file %s\n", file_path);
                    var file = File.new_for_path(file_path);
                    file.delete();
                }
                else if(file_info.get_file_type() == GLib.FileType.REGULAR) {
                    used_paths.remove(file_path);
                }
                else if(file_info.get_file_type() == GLib.FileType.DIRECTORY) {
                    cleanup_files(GLib.File.new_for_path(file_path), used_paths);
                }
            }
        }
        catch(GLib.Error err) {
            stdout.printf("Could not pre-scan music folder. Progress percentage may be off: %s\n", err.message);
        }
    }
    
    public bool doProgressNotificationWithTimeout() {
        progress_notification(current_operation.replace("&", "&amp;"), (double)((double)index)/((double)total));
        
        if(index < total && (is_syncing() || is_transferring())) {
            return true;
        }
        
        return false;
    }
    
    void sync_podcasts() {
        
    }
    
    /* should be called from thread */
    // index = 75 at this point. will go to 95
    private void sync_playlists() {
        current_operation = "Syncing playlists";
        // first remove all playlists from db
        var all_playlists = new LinkedList<unowned GPod.Playlist>();
        foreach(unowned GPod.Playlist p in db.playlists) {
            if(!p.is_mpl() && !p.is_podcasts() && !p.is_audiobooks()) {
                all_playlists.add(p);
            }
        }
        foreach(unowned GPod.Playlist p in all_playlists) {
            p.remove();
        }
        index = 78;
        
        int sub_index = 0;
        foreach(var playlist in lm.playlists()) {
            GPod.Playlist p = playlist.get_gpod_playlist();
            db.playlist_add((owned)p, -1);
            
            unowned GPod.Playlist added = db.playlists.nth_data(db.playlists.length() - 1);
            foreach(var entry in medias.entries) {
                Noise.Media match = lm.match_media_to_list (entry.value, lm.media_from_playlist(playlist.rowid));
                if(match != null) {
                    added.add_track(entry.key, -1);
                    ++sub_index;
                    index = (int)(78.0 + (double)(7.0 * (double)((double)sub_index/(double)lm.playlists().size)));
                }
            }
        }
        index = 85;
        sub_index = 0;
        foreach(var smart_playlist in lm.smart_playlists()) {
            GPod.Playlist p = smart_playlist.get_gpod_playlist();
            
            db.playlist_add((owned)p, -1);
            unowned GPod.Playlist pl = db.playlists.nth_data(db.playlists.length() - 1);
            smart_playlist.set_playlist_properties(pl);
            
            ++sub_index;
            index = (int)(85.0 + (double)(5.0 * (double)((double)sub_index/(double)lm.smart_playlists().size)));
        }
        index = 90;
        db.spl_update_live();
        index = 95;
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
        
        try {
            new Thread<void*>.try (null, transfer_medias_thread);
        }
        catch(GLib.Error err) {
            warning ("Could not create thread to transfer medias: %s \n", err.message);
            return false;
        }
        
        return true;
    }
    
    void* transfer_medias_thread() {
        if(this.list == null || this.list.size == 0)
            return null;
        
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
        
        return null;
    }
}
