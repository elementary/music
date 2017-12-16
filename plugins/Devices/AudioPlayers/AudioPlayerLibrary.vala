// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012-2017 elementary LLC. (https://elementary.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * The Noise authors hereby grant permission for non-GPL compatible
 * GStreamer plugins to be used and distributed together with GStreamer
 * and Noise. This permission is above and beyond the permissions granted
 * by the GPL license by which Noise is covered. If you modify this code
 * you may extend this exception to your version of the code, but you are not
 * obligated to do so. If you do not wish to do so, delete this exception
 * statement from your version.
 *
 * Authored by: Corentin Noël <corentin@elementary.io>
 */

public class Noise.Plugins.AudioPlayerLibrary : Noise.Library {
    AudioPlayerDevice device;
    Gee.LinkedList<Noise.Medium> media;
    Gee.LinkedList<Noise.Medium> searched_media;
    Gee.LinkedList<Noise.StaticPlaylist> playlists;
    bool operation_cancelled = false;
    bool is_doing_file_operations = false;
    bool queue_is_finished = false;
    Gee.LinkedList<string> imported_files;
    bool is_initialized = false;
    public int media_rowid = 0;
    public int playlists_rowid = 0;
    public int smartplaylists_rowid = 0;

    public GStreamerTagger tagger;

    public AudioPlayerLibrary (AudioPlayerDevice device) {
        this.device = device;
        media = new Gee.LinkedList<Noise.Medium> ();
        searched_media = new Gee.LinkedList<Noise.Medium> ();
        playlists = new Gee.LinkedList<Noise.StaticPlaylist> ();
        imported_files = new Gee.LinkedList<string> ();

        tagger = new GStreamerTagger();

        tagger.medium_imported.connect (medium_imported_from_tagger);
        tagger.import_error.connect (import_error);
        tagger.queue_finished.connect (queue_finished);
        NotificationManager.get_default ().progress_canceled.connect( () => {operation_cancelled = true;});
    }

    void medium_imported_from_tagger (Medium m) {
        m.isTemporary = true;
        media.add (m);
        m.rowid = media_rowid;
        media_rowid++;
        if (queue_is_finished) {
            file_operations_done ();
        }
    }

    void import_error(string file) {
    }

    public void queue_finished () {
        queue_is_finished = true;
        libraries_manager.progress = 1;
        if (is_initialized == false) {
            is_initialized = true;
            device.initialized (device);
            search_media ("");
        }
    }

    public override void initialize_library () {

    }

    public override void add_files_to_library (Gee.Collection<string> files) {

    }

    public override Gee.Collection<Medium> get_media () {
        return media;
    }
    public override Gee.Collection<StaticPlaylist> get_playlists () {
        return playlists;
    }
    public override Gee.Collection<SmartPlaylist> get_smart_playlists () {
        return new Gee.LinkedList<SmartPlaylist> ();
    }

    public override void search_media (string search) {
        lock (searched_media) {
            searched_media.clear ();
            if (search == "" || search == null) {
                searched_media.add_all (media);
                search_finished ();
                return;
            }

            uint parsed_rating;
            string parsed_search_string;
            String.base_search_method (search, out parsed_rating, out parsed_search_string);
            bool rating_search = parsed_rating > 0;

            lock (media) {
                foreach (var m in media) {
                    if (rating_search) {
                        if (m.rating == parsed_rating)
                            searched_media.add (m);
                    } else if (Search.match_string_to_medium (m, parsed_search_string)) {
                        searched_media.add (m);
                    }
                }
            }
        }
        search_finished ();
    }

    public override Gee.Collection<Medium> get_search_result () {
        return searched_media;
    }

    public override void add_medium (Medium m) {
        if(m == null)
            return;

        string current_operation = _("Adding <b>$NAME</b> by <b>$ARTIST</b> to $DEVICE");
        current_operation = current_operation.replace ("$NAME", m.title ?? "");
        current_operation = current_operation.replace ("$ARTIST", m.artist ?? "");
        libraries_manager.current_operation = current_operation.replace ("$DEVICE", device.getDisplayName() ?? "");
        debug ("Adding medium %s by %s\n", m.title, m.artist);

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

    public override void add_media (Gee.Collection<Medium> list) {
        if(doing_file_operations ()) {
            warning("Tried to add when already syncing\n");
            return;
        }

        libraries_manager.current_operation = _("Syncing <b>%s</b>…").printf (device.getDisplayName ());

        is_doing_file_operations = true;
        Timeout.add(500, libraries_manager.do_progress_notification_with_timeout);
        int sub_index = 0;

        var media_to_sync = new Gee.LinkedList<Noise.Medium> ();
        media_to_sync.add_all (device.delete_doubles (list, media));
        message("Found %d medias to add.", media_to_sync.size);
        int total_media = media_to_sync.size;

        if (total_media > 0) {
            if (device.will_fit (media_to_sync)) {
                imported_files = new Gee.LinkedList<string> ();
                foreach (var m in media_to_sync) {
                    add_medium (m);
                    ++sub_index;
                    libraries_manager.progress = (double)(sub_index / total_media);
                }
                tagger.discoverer_import_media (imported_files);
            }
        }
        return;
    }

    public override Medium? medium_from_id (int64 id) {
        lock (media) {
            foreach (var m in media) {
                if (m.rowid == id) {
                    return m;
                }
            }
        }
        return null;
    }

    public override Gee.Collection<Medium> media_from_ids (Gee.Collection<int64?> ids) {
        var media_collection = new Gee.LinkedList<Medium> ();

        lock (media) {
            foreach (var m in media) {
                if (ids.contains (m.rowid)) {
                    media_collection.add (m);
                }

                if (media_collection.size == ids.size) {
                    break;
                }
            }
        }

        return media_collection;
    }

    public override Gee.Collection<Medium> media_from_uris (Gee.Collection<string> uris) {
        var media_collection = new Gee.LinkedList<Medium> ();

        lock (media) {
            foreach (var m in media) {
                if (uris.contains (m.uri)) {
                    media_collection.add (m);
                }

                if (media_collection.size == uris.size) {
                    break;
                }
            }
        }

        return media_collection;
    }

    public override Medium? find_medium (Medium to_find) {
        lock (media) {
            foreach (var m in media) {
                if (to_find.title.down () == m.title.down () && to_find.artist.down () == m.artist.down ()) {
                    return m;
                }
            }
        }
        return null;
    }
    public override Medium? medium_from_file (File file) {
        lock (media) {
            foreach (var m in media) {
                if (m != null && m.file.equal (file)) {
                    return m;
                }
            }
        }

        return null;
    }
    public override Medium? medium_from_uri (string uri) {
        lock (media) {
            foreach (var m in media) {
                if (m != null && m.uri == uri) {
                    return m;
                }
            }
        }

        return null;
    }
    public override void update_medium (Medium s, bool updateMeta, bool record_time) {

    }
    public override void update_media (Gee.Collection<Medium> updates, bool updateMeta, bool record_time) {

    }
    public override void remove_medium (Medium m, bool trash) {
        string current_operation = _("Removing <b>$NAME</b> by <b>$ARTIST</b> from $DEVICE");
        current_operation = current_operation.replace ("$NAME", m.title ?? "");
        current_operation = current_operation.replace ("$ARTIST", m.artist ?? "");
        libraries_manager.current_operation = current_operation.replace ("$DEVICE", device.getDisplayName() ?? "");
        /* first check if the file exists disk */
        if(m.uri != null) {
            var file = File.new_for_uri(m.uri);

            if(file.query_exists()) {
                var media_list = new Gee.ArrayList<Medium> ();
                media_list.add (m);
                media_removed (media_list);
                media.remove (m);
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
    public override void remove_media (Gee.Collection<Medium> list, bool trash) {
        if (doing_file_operations ()) {
            warning("Tried to add when already syncing\n");
            return;
        }

        libraries_manager.current_operation = _("Removing from <b>%s</b>…").printf (device.getDisplayName ());

        int total = list.size;
        Timeout.add(500, libraries_manager.do_progress_notification_with_timeout);

        int sub_index = 0;
        foreach (var m in list) {
            remove_medium (m, true);
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
    public override void remove_smart_playlist (int64 id) {

    }
    public override SmartPlaylist? smart_playlist_from_id (int64 id) {
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
        p.media_added.connect(() => { keep_playlist_synchronized (p); });
        p.media_removed.connect(() => { keep_playlist_synchronized (p); });
        p.updated.connect ((old_name) => { remove_playlist_from_name (old_name); keep_playlist_synchronized (p); });
    }

    public override void remove_playlist (int64 id) {
        if (id < get_playlists ().size) {
            var array_v = new Gee.ArrayList<StaticPlaylist> ();
            array_v.add_all (playlists);
            foreach (var p in array_v) {
                if (p.rowid == id) {
                    remove_playlist_from_name (p.name);
                    playlist_removed (p);
                    playlists.remove (p);
                    return;
                }
            }
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

    public override StaticPlaylist? playlist_from_id (int64 id) {
        if (id < get_playlists ().size) {
            var array = new Gee.ArrayList<StaticPlaylist> ();
            array.add_all (get_playlists ());
            foreach (var playlist in array) {
                if (playlist.rowid == id)
                    return playlist;
            }
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
