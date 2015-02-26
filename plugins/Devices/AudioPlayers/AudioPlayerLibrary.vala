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
 * Authored by: Corentin Noël <tintou@mailoo.org>
 */


public class Noise.Plugins.AudioPlayerLibrary : Noise.Library {
    
    AudioPlayerDevice device;
    Gee.LinkedList<Noise.Media> medias;
    Gee.LinkedList<Noise.Media> searched_medias;
    Gee.LinkedList<Noise.StaticPlaylist> playlists;
    bool operation_cancelled = false;
    bool is_doing_file_operations = false;
    bool queue_is_finished = false;
    Gee.LinkedList<string> imported_files;
    bool is_initialized = false;
    public int medias_rowid = 0;
    public int playlists_rowid = 0;
    public int smartplaylists_rowid = 0;
    
    public GStreamerTagger tagger;
    
    public AudioPlayerLibrary (AudioPlayerDevice device) {
        this.device = device;
        medias = new Gee.LinkedList<Noise.Media> ();
        searched_medias = new Gee.LinkedList<Noise.Media> ();
        playlists = new Gee.LinkedList<Noise.StaticPlaylist> ();
        imported_files = new Gee.LinkedList<string> ();
    
        tagger = new GStreamerTagger();
        
        tagger.media_imported.connect (media_imported_from_tagger);
        tagger.import_error.connect (import_error);
        tagger.queue_finished.connect (queue_finished);
        NotificationManager.get_default ().progress_canceled.connect( () => {operation_cancelled = true;});
    }

    void media_imported_from_tagger (Media m) {
        m.isTemporary = true;
        this.medias.add(m);
        m.rowid = medias_rowid;
        medias_rowid++;
        if (queue_is_finished)
            file_operations_done ();
    }
    
    void import_error(string file) {
    }
    
    public void queue_finished () {
        queue_is_finished = true;
        libraries_manager.progress = 1;
        if (is_initialized == false) {
            is_initialized = true;
            device.initialized (device);
            search_medias ("");
        }
    }
    
    public override void initialize_library () {
        
    }
    
    public override void add_files_to_library (Gee.Collection<string> files) {
    
    }
    
    public override Gee.Collection<Media> get_medias () {
        return medias;
    }
    public override Gee.Collection<StaticPlaylist> get_playlists () {
        return playlists;
    }
    public override Gee.Collection<SmartPlaylist> get_smart_playlists () {
        return new Gee.LinkedList<SmartPlaylist> ();
    }
    
    public override void search_medias (string search) {
        lock (searched_medias) {
            searched_medias.clear ();
            if (search == "" || search == null) {
                searched_medias.add_all (medias);
                search_finished ();
                return;
            }
            
            int parsed_rating;
            string parsed_search_string;
            String.base_search_method (search, out parsed_rating, out parsed_search_string);
            bool rating_search = parsed_rating > 0;
            
            lock (medias) {
                foreach (var m in medias) {
                    if (rating_search) {
                        if (m.rating == (uint) parsed_rating)
                            searched_medias.add (m);
                    } else if (Search.match_string_to_media (m, parsed_search_string)) {
                        searched_medias.add (m);
                    }
                }
            }
        }
        search_finished ();
    }
    
    public override Gee.Collection<Media> get_search_result () {
        return searched_medias;
    }
    
    public override void add_media (Media m) {
        if(m == null)
            return;

        string current_operation = _("Adding <b>$NAME</b> by <b>$ARTIST</b> to $DEVICE");
        current_operation = current_operation.replace ("$NAME", m.title ?? "");
        current_operation = current_operation.replace ("$ARTIST", m.artist ?? "");
        libraries_manager.current_operation = current_operation.replace ("$DEVICE", device.getDisplayName() ?? "");
        debug ("Adding media %s by %s\n", m.title, m.artist);
        
        var file = File.new_for_uri (m.uri);
        var destination_file = File.new_for_uri (device.get_music_folder () + file.get_basename ());
        
        try {
            file.copy (destination_file,GLib.FileCopyFlags.ALL_METADATA);
        } catch(Error err) {
            warning ("Failed to copy track %s : %s\n", m.title, err.message);
            return;
        }
        imported_files.add (destination_file.get_uri());
    }
    
    public override void add_medias (Gee.Collection<Media> list) {
        if(doing_file_operations ()) {
            warning("Tried to add when already syncing\n");
            return;
        }
        
        libraries_manager.current_operation = _("Syncing <b>%s</b>…").printf (device.getDisplayName ());
        
        is_doing_file_operations = true;
        Timeout.add(500, libraries_manager.do_progress_notification_with_timeout);
        int sub_index = 0;
        
        var medias_to_sync = new Gee.LinkedList<Noise.Media> ();
        medias_to_sync.add_all (device.delete_doubles (list, medias));
        message("Found %d medias to add.", medias_to_sync.size);
        int total_medias = medias_to_sync.size;
        
        if (total_medias > 0) {
            if (device.will_fit(medias_to_sync)) {
                imported_files = new Gee.LinkedList<string> ();
                foreach(var m in medias_to_sync) {
                    add_media(m);
                    ++sub_index;
                    libraries_manager.progress = (double)(sub_index/total_medias);
                }
                tagger.discoverer_import_media (imported_files);
            }
        }
        return;
    }
    
    public void sync_medias () {
        if(doing_file_operations ()) {
            warning("Tried to add when already syncing\n");
            return;
        }
        Playlist playlist = null;
        if (device.get_preferences().sync_all_music == false) {
            playlist = device.get_preferences().music_playlist;
            if (playlist == null)
                return;
        }
        
        
        libraries_manager.current_operation = _("Syncing <b>%s</b>…").printf (device.getDisplayName ());
        
        is_doing_file_operations = true;
        Timeout.add(500, libraries_manager.do_progress_notification_with_timeout);
        if (playlist == null)
            sync_medias_async.begin (libraries_manager.local_library.get_medias ());
        else
            sync_medias_async.begin (playlist.medias);
        return;
    }
    
    public async void sync_medias_async (Gee.Collection<Noise.Media> songs) {
        var medias_to_remove = new Gee.LinkedList<Noise.Media> ();
        medias_to_remove.add_all (device.delete_doubles (medias, songs));
        
        var medias_to_sync = new Gee.LinkedList<Noise.Media> ();
        medias_to_sync.add_all (device.delete_doubles (songs, medias));
        
        int total_medias = medias_to_remove.size + medias_to_sync.size;
        
        int sub_index = 0;
        if (total_medias > 0) {
            if (device.will_fit_without (medias_to_sync, medias_to_remove)) {
                foreach(var m in medias_to_remove) {
                    if(!operation_cancelled) {
                        remove_media(m, true);
                    }
                    ++sub_index;
                    libraries_manager.progress = (double)(sub_index/total_medias);
                }
                sub_index = 0;
                imported_files = new Gee.LinkedList<string> ();
                foreach(var m in medias_to_sync) {
                    if(!operation_cancelled) {
                        add_media (m);
                    }
                    ++sub_index;
                    libraries_manager.progress = (double)(sub_index/total_medias);
                }
                tagger.discoverer_import_media (imported_files);
                
                if(!operation_cancelled) {
                    // sync playlists
                    /* TODO: add support for podcasts & playlists
                    if (pref.sync_all_music == true) {
                        sync_playlists();
                    }
                    if (pref.sync_all_podcasts == true) {
                        sync_podcasts();
                    }*/
                    
                    libraries_manager.current_operation = _("Finishing sync process…");
                    
                } else {
                    libraries_manager.current_operation = _("Cancelling Sync…");
                    libraries_manager.progress = 1;
                }
            } else {
                    device.infobar_message (_("There is not enough space on Device to complete the Sync…"), Gtk.MessageType.INFO);
                    libraries_manager.current_operation = _("There is not enough space on Device to complete the Sync…");
            }
        }

        Idle.add( () => {
            libraries_manager.progress = 1;
            device.get_preferences().last_sync_time = (int)time_t();
            is_doing_file_operations = false;
            
            file_operations_done ();
            operation_cancelled = false;
            
            return false;
        });
    }
    
    public override Media? media_from_id (int id) {
        lock (medias) {
            foreach (var m in medias) {
                if (m.rowid == id) {
                    return m;
                }
            }
        }
        return null;
    }
    public override Gee.Collection<Media> medias_from_ids (Gee.Collection<int> ids) {
        var media_collection = new Gee.LinkedList<Media> ();

        lock (medias) {
            foreach (var m in medias) {
                if (ids.contains (m.rowid))
                    media_collection.add (m);
                if (media_collection.size == ids.size)
                    break;
            }
        }

        return media_collection;
    }

    public override Gee.Collection<Media> medias_from_uris (Gee.Collection<string> uris) {
        var media_collection = new Gee.LinkedList<Media> ();

        lock (medias) {
            foreach (var m in medias) {
                if (uris.contains (m.uri))
                    media_collection.add (m);
                if (media_collection.size == uris.size)
                    break;
            }
        }

        return media_collection;
    }
    
    public override Media? find_media (Media to_find) {
        Media? found = null;
        lock (medias) {
            foreach (var m in medias) {
                if (to_find.title.down () == m.title.down () && to_find.artist.down () == m.artist.down ()) {
                    found = m;
                    break;
                }
            }
        }
        return found;
    }
    public override Media? media_from_file (File file) {
        lock (medias) {
            foreach (var m in medias) {
                if (m != null && m.file.equal (file))
                    return m;
            }
        }

        return null;
    }
    public override Media? media_from_uri (string uri) {
        lock (medias) {
            foreach (var m in medias) {
                if (m != null && m.uri == uri)
                    return m;
            }
        }

        return null;
    }
    public override void update_media (Media s, bool updateMeta, bool record_time) {
    
    }
    public override void update_medias (Gee.Collection<Media> updates, bool updateMeta, bool record_time) {
    
    }
    public override void remove_media (Media m, bool trash) {
        string current_operation = _("Removing <b>$NAME</b> by <b>$ARTIST</b> from $DEVICE");
        current_operation = current_operation.replace ("$NAME", m.title ?? "");
        current_operation = current_operation.replace ("$ARTIST", m.artist ?? "");
        libraries_manager.current_operation = current_operation.replace ("$DEVICE", device.getDisplayName() ?? "");
        /* first check if the file exists disk */
        if(m.uri != null) {
            var file = File.new_for_uri(m.uri);
            
            if(file.query_exists()) {
                var media_list = new Gee.ArrayList<Media> ();
                media_list.add (m);
                media_removed (media_list);
                medias.remove (m);
                try {
                    file.delete();
                } catch (Error err) {
                    warning ("Could not delete File at %s: %s", m.uri, err.message);
                    return;
                }
                debug ("Successfully removed music file %s", m.uri);
            } else {
                warning("File not found, could not delete File at %s. File may already be deleted", m.uri);
            }
        }
    }
    public override void remove_medias (Gee.Collection<Media> list, bool trash) {
        if(doing_file_operations ()) {
            warning("Tried to add when already syncing\n");
            return;
        }
        
        libraries_manager.current_operation = _("Removing from <b>%s</b>…").printf (device.getDisplayName ());
        
        int total = list.size;
        Timeout.add(500, libraries_manager.do_progress_notification_with_timeout);
        
        int sub_index = 0;
        foreach(var m in list) {
            remove_media (m, true);
            ++sub_index;
            libraries_manager.progress = (double)(sub_index/total);
        }
        libraries_manager.progress = 1;
        file_operations_done ();
    }
    
    public override bool support_smart_playlists () {
        return false;
    }
    
    public override void add_smart_playlist (SmartPlaylist p) {
    
    }
    public override void remove_smart_playlist (int id) {
    
    }
    public override SmartPlaylist? smart_playlist_from_id (int id) {
        return null;
    }
    public override SmartPlaylist? smart_playlist_from_name (string name) {
        return null;
    }
    
    public override bool support_playlists () {
        return false;
    }
    
    public override void add_playlist (StaticPlaylist p) {
        
        playlists.add (p);
        playlist_added (p);
        keep_playlist_synchronized (p);
        p.media_added.connect(() => {keep_playlist_synchronized (p);});
        p.media_removed.connect(() => {keep_playlist_synchronized (p);});
        p.updated.connect ((old_name) => {remove_playlist_from_name (old_name); keep_playlist_synchronized (p);});
    }
    public override void remove_playlist (int id) {
        if (id < get_playlists ().size) {
            var array_v = new Gee.ArrayList<StaticPlaylist> ();
            array_v.add_all (playlists);
            var p = array_v.get (id);
            remove_playlist_from_name (p.name);
            playlist_removed (p);
            playlists.remove (p);
        }
    }
    
    private void remove_playlist_from_name (string name) {
        File dest = GLib.File.new_for_uri (Path.build_path("/", device.get_music_folder (), "Playlists", name.replace("/", "_") + ".m3u"));
        try {
            // find a file path that doesn't exist
            if (dest.query_exists()) {
                dest.delete ();
            }
        }
        catch(Error err) {
            warning ("Could not remove playlist %s to file %s: %s", name, dest.get_path(), err.message);
        }
    }
    
    private void keep_playlist_synchronized (StaticPlaylist p) {
        string content = PlaylistsUtils.get_playlist_m3u_file (p, device.get_uri ());
        content = content.replace (GLib.File.new_for_uri (device.get_uri ()).get_path (), "");
        
        File dest = GLib.File.new_for_uri (Path.build_path("/", device.get_music_folder (), "Playlists", p.name.replace("/", "_") + ".m3u"));
        try {
            // find a file path that doesn't exist
            if (dest.query_exists()) {
                dest.delete ();
            }
            
            var file_stream = dest.create(FileCreateFlags.NONE);
            
            // Write text data to file
            var data_stream = new DataOutputStream (file_stream);
            data_stream.put_string(content);
        }
        catch(Error err) {
            warning ("Could not save playlist %s to m3u file %s: %s\n", p.name, dest.get_path(), err.message);
        }
    }
    
    public override StaticPlaylist? playlist_from_id (int id) {
        if (id < get_playlists ().size) {
            var array = new Gee.ArrayList<StaticPlaylist> ();
            array.add_all (get_playlists ());
            return array.get (id);
        }
        return null;
    }
    public override StaticPlaylist? playlist_from_name (string name) {
        foreach (var playlist in get_playlists ()) {
            if (playlist.name == name) {
                return playlist;
            }
        }
        return null;
    }
    
    public override bool start_file_operations (string? message) {
        if (doing_file_operations ()) {
            
            return true;
        } else
            return false;
    }
    public override bool doing_file_operations () {
        return is_doing_file_operations;
    }
    public override void finish_file_operations () {
    
    }
    
}
