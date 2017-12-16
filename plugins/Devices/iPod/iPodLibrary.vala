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

public class Noise.Plugins.iPodLibrary : Noise.Library {
    private unowned GPod.iTunesDB db;
    Gee.HashMap<unowned GPod.Track, Noise.Medium> media;
    Gee.LinkedList<Noise.Medium> searched_media;
    Gee.HashMap<unowned GPod.Playlist, Noise.StaticPlaylist> playlists;
    Gee.HashMap<unowned GPod.Playlist, Noise.SmartPlaylist> smart_playlists;
    Device device;
    bool operation_cancelled = false;
    bool is_doing_file_operations = false;

    public iPodLibrary (GPod.iTunesDB db, Device device) {
        this.db = db;
        this.device = device;
        media = new Gee.HashMap<unowned GPod.Track, Noise.Medium>();
        playlists = new Gee.HashMap<unowned GPod.Playlist, Noise.StaticPlaylist>();
        smart_playlists = new Gee.HashMap<unowned GPod.Playlist, Noise.SmartPlaylist>();
        searched_media = new Gee.LinkedList<Noise.Medium>();
        NotificationManager.get_default ().progress_canceled.connect( () => {operation_cancelled = true;});
    }

    public override void initialize_library () {

    }

    public async void finish_initialization_async () {
        // get all songs first
        for (int i = 0; i < db.tracks.length(); ++i) {
            unowned GPod.Track t = db.tracks.nth_data (i);
            var m = iPodMediaHelper.medium_from_track (device.get_uri (), t);
            if (m.file_exists && !this.media.has (t, m)) {
                this.media.set (t, m);
            }
        }

        foreach (unowned GPod.Playlist p in db.playlists) {
            var playlist = iPodPlaylistHelper.get_playlist_from_gpod_playlist (p, media);
            if (playlist is StaticPlaylist) {
                playlist.rowid = playlists.size;
                playlists.set(p, (StaticPlaylist)playlist);
                playlist.media_added.connect((list) => {keep_playlist_synchronized ((StaticPlaylist)playlist, list, true);});
                playlist.media_removed.connect((list) => {keep_playlist_synchronized ((StaticPlaylist)playlist, list, false);});
            } else if (playlist is SmartPlaylist) {
                playlist.rowid = smart_playlists.size;
                smart_playlists.set(p, (SmartPlaylist)playlist);
            }
        }

        Idle.add (() => {
            device.initialized (device);
            search_media ("");
            return false;
        });
    }

    public override void add_files_to_library (Gee.Collection<string> files) {

    }

    public override void search_media (string search) {
        lock (searched_media) {
            searched_media.clear ();
            if (search == "" || search == null) {
                searched_media.add_all (media.values);
                search_finished ();
                return;
            }

            uint parsed_rating;
            string parsed_search_string;
            String.base_search_method (search, out parsed_rating, out parsed_search_string);
            bool rating_search = parsed_rating > 0;

            lock (media) {
                foreach (var m in media.values) {
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

    public override Gee.Collection<Medium> get_media () {
        return media.values;
    }

    public override Gee.Collection<StaticPlaylist> get_playlists () {
        return playlists.values;
    }

    public override Gee.Collection<SmartPlaylist> get_smart_playlists () {
        return smart_playlists.values;
    }

    public override void add_medium (Noise.Medium s) {
        if (s == null)
            return;

        GPod.Track t = iPodMediaHelper.track_from_medium (s);
        var icon = s.album_info.cover_icon;
        if (icon != null) {
            var icon_info = Gtk.IconTheme.get_default ().lookup_by_gicon (icon, 128, Gtk.IconLookupFlags.GENERIC_FALLBACK);
            try {
                var pixbuf = icon_info.load_icon ();
                t.set_thumbnails_from_pixbuf (pixbuf);
            } catch (Error e) {
                critical (e.message);
            }
        }

        string current_operation = _("Adding <b>$NAME</b> by <b>$ARTIST</b> to $DEVICE");
        current_operation = current_operation.replace ("$NAME", t.title ?? "");
        current_operation = current_operation.replace ("$ARTIST", t.artist ?? "");
        libraries_manager.current_operation = current_operation.replace ("$DEVICE", device.getDisplayName() ?? "");
        debug ("Adding medium %s by %s\n", t.title, t.artist);
        db.track_add((owned)t, -1);
        unowned GPod.Track added = db.tracks.nth_data(db.tracks.length() - 1);
        if (added == null || added.title != s.title) {
            warning ("Track was not properly appended. Returning.\n");
            return;
        }

        unowned GPod.Playlist mpl = db.playlist_mpl();
        mpl.add_track(added, -1);

        bool success = false;
        try {
            success = GPod.iTunesDB.cp_track_to_ipod (added, File.new_for_uri (s.uri).get_path ());
            debug ("Copied medium %s to ipod\n", added.title);
        } catch (Error err) {
            warning ("Error adding/copying song %s to iPod: %s\n", s.title, err.message);
        }

        if (success) {
            Noise.Medium on_ipod = iPodMediaHelper.medium_from_track (device.get_uri(), added);
            this.media.set (added, on_ipod);
        } else {
            warning ("Failed to copy track %s to iPod. Removing it from database.\n", added.title);
            remove_medium_from_ipod (added);
        }
    }

    public override void add_media (Gee.Collection<Noise.Medium> list) {
        if (is_doing_file_operations) {
            warning("Tried to add when already syncing\n");
            return;
        }

        // Check if all current media + this list will fit.
        var new_list = new Gee.LinkedList<Noise.Medium>();
        new_list.add_all(list);
        new_list.add_all(media.values);
        bool fits = device.will_fit (new_list);
        if (!fits) {
            warning("Tried to sync media that will not fit\n");
            return;
        }

        libraries_manager.current_operation = _("Syncing <b>%s</b>…").printf (device.getDisplayName ());
        is_doing_file_operations = true;
        Timeout.add(500, libraries_manager.do_progress_notification_with_timeout);
        add_media_async.begin (list);
    }

    async void add_media_async (Gee.Collection<Noise.Medium> to_add) {
        bool error_occurred = false;
        db.start_sync ();
        int total = to_add.size;
        int index = 0;

        // Actually add new items
        foreach (var m in to_add) {
            if (!operation_cancelled) {
                add_medium (m);
                ++index;
                libraries_manager.progress = (double)(index/total);
            }
        }

        if (!operation_cancelled) {
            libraries_manager.current_operation = _("Finishing sync process…");
            try {
                db.write ();
            } catch (GLib.Error err) {
                critical ("Error when writing iPod database. iPod contents may be incorrect: %s\n", err.message);
                error_occurred = true;
                operation_cancelled = true;
            }

            libraries_manager.progress = 1;
            db.stop_sync ();
        } else {
            libraries_manager.current_operation = _("Cancelling Sync…");
            try {
                db.write ();
            } catch (Error err) {
                critical ("Error when writing iPod database. iPod contents may be incorrect: %s\n", err.message);
            }

            db.stop_sync ();
            libraries_manager.progress = 1;
        }

        Idle.add (() => {
            is_doing_file_operations = false;
            file_operations_done ();
            operation_cancelled = false;
            return false;
        });
    }

    public override Medium? medium_from_id (int64 id) {
        return null;
    }

    public override Gee.Collection<Medium> media_from_ids (Gee.Collection<int64?> ids) {
        var media_collection = new Gee.LinkedList<Medium> ();
        lock (media) {
            foreach (var m in media.values) {
                if (ids.contains (m.rowid))
                    media_collection.add (m);
                if (media_collection.size == ids.size)
                    break;
            }
        }

        return media_collection;
    }

    public override Gee.Collection<Medium> media_from_uris (Gee.Collection<string> uris) {
        var media_collection = new Gee.LinkedList<Medium> ();
        lock (media) {
            foreach (var m in media.values) {
                if (uris.contains (m.uri))
                    media_collection.add (m);
                if (media_collection.size == uris.size)
                    break;
            }
        }

        return media_collection;
    }

    public override Medium? find_medium (Medium to_find) {
        Medium? found = null;
        lock (media) {
            foreach (var m in media.values) {
                if (to_find.title.down () == m.title.down () && to_find.artist.down () == m.artist.down ()) {
                    found = m;
                    break;
                }
            }
        }

        return found;
    }

    public override Medium? medium_from_file (File file) {
        lock (media) {
            foreach (var m in media.values) {
                if (m != null && m.file.equal (file))
                    return m;
            }
        }

        return null;
    }

    public override Medium? medium_from_uri (string uri) {
        lock (media) {
            foreach (var m in media.values) {
                if (m != null && m.uri == uri)
                    return m;
            }
        }

        return null;
    }

    public override void update_medium (Medium s, bool updateMeta, bool record_time) {

    }

    public override void update_media (Gee.Collection<Medium> updates, bool updateMeta, bool record_time) {

    }

    public override void remove_medium (Medium s, bool trash) {
        var list = new Gee.ArrayList<Medium> ();
        list.add (s);
        remove_medias (list, trash);
    }

    public override void remove_media (Gee.Collection<Medium> toRemove, bool trash) {
        if (is_doing_file_operations) {
            warning("Tried to add when already syncing\n");
            return;
        }

        libraries_manager.current_operation = _("Removing from <b>%s</b>…").printf (device.getDisplayName ());
        is_doing_file_operations = true;
        Timeout.add (500, libraries_manager.do_progress_notification_with_timeout);
        remove_medias_async.begin (toRemove);
        return;
    }

    async void remove_media_async (Gee.Collection<Noise.Medium> list) {
        bool error_occurred = false;
        int total = list.size;
        int index = 0;
        db.start_sync ();

        var removed = new Gee.HashMap<unowned GPod.Track, Noise.Medium> ();
        foreach (var e in media.entries) {
            foreach (var m in list) {
                if (!operation_cancelled) {
                    // If entry e is on the list to be removed, it is to be removed
                    if (m == e.value) {
                        unowned GPod.Track t = e.key;
                        if (t != null) {
                            removed.set (t, e.value);
                        }
                    }
                }
            }

            ++index;
            libraries_manager.progress = (double)(index/total);
        }

        foreach (var track in removed.keys) {
            remove_medium_from_ipod (track);
        }

        media.unset_all (removed);
        if (!operation_cancelled) {
            libraries_manager.current_operation = _("Finishing sync process…");
            try {
                db.write ();
            } catch (GLib.Error err) {
                critical ("Error when writing iPod database. iPod contents may be incorrect: %s", err.message);
                error_occurred = true;
                operation_cancelled = true;
            }

            libraries_manager.progress = 1;
            db.stop_sync ();
        } else {
            libraries_manager.current_operation = _("Cancelling Sync…");
            try {
                db.write ();
            } catch (Error err) {
                critical ("Error when writing iPod database. iPod contents may be incorrect: %s", err.message);
            }

            db.stop_sync ();
            libraries_manager.progress = 1;
            operation_cancelled = false;
        }

        Idle.add (() => {
            is_doing_file_operations = false;
            file_operations_done ();
            return false;
        });
    }

    public override void add_smart_playlist (SmartPlaylist p) {

    }

    public override bool support_smart_playlists () {
        return false;
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
        return true;
    }

    public override void add_playlist (StaticPlaylist p) {
        GPod.Playlist playlist = iPodPlaylistHelper.get_gpod_playlist_from_playlist (p, media, db);
        db.start_sync ();
        db.playlist_add ((owned)playlist, -1);
        try {
            db.write();
        } catch(Error err) {
            critical("Error when writing iPod database. iPod contents may be incorrect: %s", err.message);
        }

        db.stop_sync();
        playlists.set (playlist, p);
        playlist_added (p);
        p.media_added.connect((list) => {keep_playlist_synchronized (p, list, true);});
        p.media_removed.connect((list) => {keep_playlist_synchronized (p, list, false);});
    }

    public override void remove_playlist (int64 id) {
        unowned GPod.Playlist to_unset = null;
        foreach (var entry in playlists.entries) {
            if (entry.value.rowid == id) {
                playlist_removed (entry.value);
                to_unset = entry.key;
            }
        }

        if (to_unset != null)
            playlists.unset (to_unset);

        db.start_sync ();
        to_unset.remove ();
        try {
            db.write ();
        } catch (Error err) {
            critical ("Error when writing iPod database. iPod contents may be incorrect: %s", err.message);
        }

        db.stop_sync ();
    }

    private void keep_playlist_synchronized (StaticPlaylist p, Gee.Collection<Medium> m, bool to_add) {
        unowned GPod.Playlist pl = null;
        foreach (var entry in playlists.entries) {
            if (entry.value == p) {
                pl = entry.key;
            }
        }

        if (pl == null)
            return;

        db.start_sync ();
        foreach (var t in iPodPlaylistHelper.get_gpod_tracks_from_media (m, media)) {
            if (!pl.contains_track (t) && to_add == true) {
                 pl.add_track (t, -1);
            } else if (pl.contains_track (t) && to_add == false) {
                 pl.remove_track (t);
            }
        }

        try {
            db.write ();
        } catch (Error err) {
            critical ("Error when writing iPod database. iPod contents may be incorrect: %s", err.message);
        }

        db.stop_sync ();
    }

    public override StaticPlaylist? playlist_from_id (int64 id) {
        foreach (var p in playlists.values) {
            if (p.rowid == id) {
                return p;
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
        return true;
    }

    public override bool doing_file_operations () {
        return true;
    }

    public override void finish_file_operations () {

    }

    void remove_medium_from_ipod (GPod.Track t) {
        string current_operation = _("Removing <b>$NAME</b> by <b>$ARTIST</b> from $DEVICE");
        current_operation = current_operation.replace ("$NAME", t.title ?? "");
        current_operation = current_operation.replace ("$ARTIST", t.artist ?? "");
        libraries_manager.current_operation = current_operation.replace ("$DEVICE", device.getDisplayName() ?? "");
        /* first check if the file exists disk */
        if (t.ipod_path != null) {
            var uri = device.get_uri () + GPod.iTunesDB.filename_ipod2fs(t.ipod_path);
            var file = File.new_for_uri(uri);
            if (file.query_exists()) {
                try {
                    /* check each playlist for the song to remove */
                    if (db.playlists_number() != 0) {
                        db.playlist_mpl().remove_track(t);
                        db.playlist_podcasts().remove_track(t);
                    }

                    foreach (unowned GPod.Playlist p in db.playlists) {
                        if (p.contains_track (t))
                            p.remove_track (t);
                    }

                    foreach (unowned GPod.Playlist p in db.playlists) {
                        if (p.contains_track (t))
                            p.remove_track (t);
                    }

                    /* Remove from all stored lists */
                    var media_list = new Gee.ArrayList<Medium> ();
                    media_list.add (media.get (t));
                    media_removed (media_list);
                    media.unset (t, null);
                    t.remove ();
                    file.delete ();
                    warning ("Successfully removed music file %s from iPod Disk", uri);
                } catch (Error err) {
                    warning ("Could not delete iPod File at %s. Unused file will remain on iPod: %s", uri, err.message);
                }
            } else {
                warning ("File not found, could not delete iPod File at %s. File may already be deleted", uri);
            }
        }
    }

    void cleanup_files(GLib.File music_folder, Gee.LinkedList<string> used_uris) {
        GLib.FileInfo file_info = null;
        try {
            var enumerator = music_folder.enumerate_children (FileAttribute.STANDARD_NAME + "," + FileAttribute.STANDARD_TYPE, 0);
            while ((file_info = enumerator.next_file ()) != null) {
                var file_uri = music_folder.get_uri () + "/" + file_info.get_name ();
                if (file_info.get_file_type () == GLib.FileType.REGULAR && !used_uris.contains (file_uri)) {
                    message ("Deleting unused file %s\n", file_uri);
                    var file = File.new_for_uri (file_uri);
                    file.delete ();
                } else if (file_info.get_file_type () == GLib.FileType.REGULAR) {
                    used_uris.remove (file_uri);
                } else if (file_info.get_file_type () == GLib.FileType.DIRECTORY) {
                    cleanup_files (GLib.File.new_for_uri (file_uri), used_uris);
                }
            }
        } catch (GLib.Error err) {
            critical ("Could not pre-scan music folder. Progress percentage may be off: %s", err.message);
        }
    }
}
