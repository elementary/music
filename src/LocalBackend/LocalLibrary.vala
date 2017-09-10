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
 * Authored by: Scott Ringwelski <sgringwe@mtu.edu>
 *              Victor Eduardo <victoreduardm@gmail.com>
 *              Corentin Noël <corentin@elementary.io>
 */

/**
 * This is where all the media stuff happens. Here, media is retrieved
 * from the db, added to the queue, sorted, and more. LibraryWindow is
 * the visual representation of this class
 */
public class Noise.LocalLibrary : Library {
    private FileOperator fo;
    private GStreamerTagger tagger;

    private Gee.TreeSet<StaticPlaylist> _playlists;
    private Gee.TreeSet<SmartPlaylist> _smart_playlists;
    private Gee.HashMap<int64?, Media> _medias;
    private Gee.TreeSet<Media> _searched_medias;
    private Gee.HashMap<uint, Album> album_info;

    public StaticPlaylist p_music;

    public bool main_directory_set {
        get { return !String.is_empty (Settings.Main.get_default ().music_folder, true); }
    }

    private Gee.TreeSet<Media> open_media_list;
    private bool _doing_file_operations = false;

    public Gda.Connection connection { public get; private set; }

    private const string DB_FILE = "database_0_3_1";

    public LocalLibrary () {
        libraries_manager.local_library = this;
        _playlists = new Gee.TreeSet<StaticPlaylist> ();
        _smart_playlists = new Gee.TreeSet<SmartPlaylist> ();
        _medias = new Gee.HashMap<int64?, Media> ((Gee.HashDataFunc<int64?>)GLib.int64_hash,
                                                  (Gee.EqualDataFunc<int64?>?)GLib.int64_equal, null);
        _searched_medias = new Gee.TreeSet<Media> ();
        album_info = new Gee.HashMap<uint, Album> ();
        tagger = new GStreamerTagger();
        open_media_list = new Gee.TreeSet<Media> ();
        p_music = new StaticPlaylist ();
        p_music.name = MUSIC_PLAYLIST;

        this.fo = new FileOperator ();
    }

    public override void initialize_library () {
        init_database ();
        fo.connect_to_manager ();

        // Load all media from database
        var media_ids = get_rowids_from_table (Database.Media.TABLE_NAME);
        foreach (var media_id in media_ids) {
            var m = new LocalMedia (media_id, connection);
            if(m.dont_show == 1){
                remove_media(m, false);
                continue;
            }
            _medias.set (m.rowid, m);
            // Append the media into an album.
            if (m.get_album_hashkey () in album_info.keys) {
                var album = album_info.get (m.get_album_hashkey ());
                album.add_media (m);
            }

            if (m.album_info == null) {
                var album = new Album.from_media (m);
                album.add_media (m);
                album_info.set (album.get_hashkey (), album);
            }
        }

        // Load all smart playlists from database
        var sp_ids = get_rowids_from_table (Database.SmartPlaylists.TABLE_NAME);
        if (sp_ids.is_empty) {
            LocalSmartPlaylist.add_defaults (connection);
            sp_ids = get_rowids_from_table (Database.SmartPlaylists.TABLE_NAME);
        }

        foreach (var sp_id in sp_ids) {
            var sp = new LocalSmartPlaylist (sp_id, connection);
            _smart_playlists.add (sp);
        }

        // Load all static playlists from database
        var p_ids = get_rowids_from_table (Database.Playlists.TABLE_NAME);
        foreach (var p_id in p_ids) {
            var p = new LocalStaticPlaylist (p_id, connection);
            _playlists.add (p);
        }
    }

    /*
     * Database interaction
     */
    private void init_database () {
        var database_dir = FileUtils.get_data_directory ();
        try {
            database_dir.make_directory_with_parents (null);
        } catch (GLib.Error err) {
            if (err is IOError.EXISTS == false)
                error ("Could not create data directory: %s", err.message);
        }

        var db_file = database_dir.get_child (DB_FILE + ".db");
        bool new_db = !db_file.query_exists ();
        if (new_db) {
            try {
                db_file.create (FileCreateFlags.PRIVATE);
            } catch (Error e) {
                critical ("Error: %s", e.message);
            }
        }

        try {
            connection = new Gda.Connection.from_string ("SQLite", "DB_DIR=%s;DB_NAME=%s".printf (database_dir.get_path (), DB_FILE), null, Gda.ConnectionOptions.NONE);
            connection.open ();
        } catch (Error e) {
            error (e.message);
        }

        Database.create_tables (connection);
    }

    /************ Library/Collection management stuff ************/
    public bool doProgressNotificationWithTimeout () {
        if (_doing_file_operations) {
            NotificationManager.get_default ().update_progress (null, (double) fo.index / (double) fo.item_count);
        }

        if (fo.index < fo.item_count && _doing_file_operations)
            return true;

        return false;
    }

    public void remove_all_static_playlists () {
        var list = new Gee.TreeSet<int64?> ();
        lock (_playlists) {
            foreach (var p in _playlists) {
                if (p.read_only == false)
                    list.add (p.rowid);
            }
        }

        foreach (var id in list) {
                remove_playlist (id);
        }
    }

    public async void set_music_folder (string folder) {
        string m_folder = folder;
        m_folder = m_folder.replace ("/media", "");
        m_folder = m_folder.replace (GLib.Environment.get_home_dir ()+ "/", "");

        if (start_file_operations (_("Importing music from %s…").printf ("<b>" + Markup.escape_text (m_folder) + "</b>"))) {
            remove_all_static_playlists ();

            clear_medias ();

            App.player.unqueue_media (_medias.values);

            // FIXME: these are library window's internals. Shouldn't be here
            App.main_window.update_sensitivities.begin ();
            App.player.stop_playback ();

            set_music_folder_thread.begin (folder);
        }
    }

    private async void set_music_folder_thread (string folder) {
        var music_folder_file = File.new_for_path (folder);
        var files = new Gee.TreeSet<string> ();

        var items = FileUtils.count_music_files (music_folder_file, files);
        debug ("Found %d items to import in %s\n", items, folder);

        fo.resetProgress (files.size - 1);
        Timeout.add (100, doProgressNotificationWithTimeout);
        fo.import_files (files, FileOperator.ImportType.SET);
    }

    public override void add_files_to_library (Gee.Collection<string> files) {
        if (start_file_operations (_("Adding files to library…"))) {
            add_files_to_library_async.begin (files);
        }
    }

    private async void add_files_to_library_async (Gee.Collection<string> files) {
        var to_import = new Gee.TreeSet<string> ();
        to_import.add_all (files);

        fo.resetProgress (to_import.size - 1);
        Timeout.add (100, doProgressNotificationWithTimeout);
        fo.import_files (to_import, FileOperator.ImportType.IMPORT);
    }

    public void add_folder_to_library (Gee.Collection<string> folders) {
        if (start_file_operations (_("<b>Importing</b> music to library…"))) {
            add_folder_to_library_async.begin (folders);
        }
    }

    private async void add_folder_to_library_async (Gee.Collection<string> folders) {
        var files = new Gee.TreeSet<string> ();
        foreach (var folder in folders) {
            var file = File.new_for_path (folder);
            FileUtils.count_music_files (file, files);
        }

        foreach (var m in get_medias ()) {
            if (files.contains (m.uri))
                files.remove (m.uri);
        }

        if (!files.is_empty) {
            fo.resetProgress (files.size - 1);
            Timeout.add (100, doProgressNotificationWithTimeout);
            fo.import_files (files, FileOperator.ImportType.IMPORT);
        } else {
            debug ("No new songs to import.\n");
            finish_file_operations ();
            App.main_window.show_notification (_("All music files are already in your library"), _("No files were imported."));
        }
    }

    public void rescan_music_folder () {
        if (start_file_operations (_("Rescanning music for changes. This may take a while…"))) {
            App.main_window.update_sensitivities.begin ();
            rescan_music_folder_async.begin ();
        }
    }

    private async void rescan_music_folder_async () {
        var to_remove = new Gee.TreeSet<Media> ();
        var files = new Gee.TreeSet<string> ();

        var music_folder_dir = Settings.Main.get_default ().music_folder;
        var num_items = FileUtils.count_music_files (File.new_for_path (music_folder_dir), files);
        debug ("Found %d items to import in %s\n", num_items, music_folder_dir);

        foreach (var m in get_medias()) {
            if (!m.isTemporary && !m.isPreview && m.uri.contains (music_folder_dir)) {
                if (!File.new_for_uri (m.uri).query_exists ()) {
                    to_remove.add (m);
                }

                if (files.contains (m.uri)) {
                    files.remove (m.uri);
                }
            }
        }

        // Anything left in files should be imported
        if (!files.is_empty) {
            debug ("Importing %d new songs", files.size);
            fo.resetProgress (files.size - 1);
            Timeout.add (100, doProgressNotificationWithTimeout);
            fo.import_files (files, FileOperator.ImportType.RESCAN);
        } else {
            debug ("No new songs to import.");
        }

        if (files.is_empty) {
            finish_file_operations ();
        }

        if (!fo.cancellable.is_cancelled ()) {
            if(!to_remove.is_empty) {
                remove_medias (to_remove, false);
            }
        }
    }

    public void play_files (File[] files) {
        tagger.media_imported.connect (media_opened_imported);
        tagger.queue_finished.connect (media_opened_finished);
        var files_list = new Gee.TreeSet<string> ();
        foreach (var file in files) {
            files_list.add (file.get_uri ());
        }

        var found = medias_from_uris (files_list);
        foreach (var m in found) {
            files_list.remove (m.uri);
        }

        open_media_list.add_all (found);
        if (files_list.is_empty) {
            media_opened_finished ();
        } else {
            tagger.discoverer_import_media (files_list);
        }
    }

    private void media_opened_imported (Media m) {
        m.isTemporary = true;
        open_media_list.add (m);
    }

    private void media_opened_finished () {
        App.player.queue_media (open_media_list);
        if (open_media_list.size > 0) {
            if (!App.player.playing) {
                App.player.playMedia (open_media_list.first (), false);
                App.main_window.play_media ();
            } else {
                string primary_text = _("Added to your queue:");

                var secondary_text = new StringBuilder ();
                GLib.Icon icon = null;
                if (open_media_list.size == 1) {
                    var first = open_media_list.first ();
                    secondary_text.append (first.get_display_title ());
                    secondary_text.append ("\n");
                    secondary_text.append (first.get_display_artist ());
                    icon = first.album_info.cover_icon;
                } else {
                    secondary_text.append (ngettext ("%d Track", "%d Tracks", open_media_list.size).printf (open_media_list.size));
                }

                App.main_window.show_notification (primary_text, secondary_text.str, icon, NotificationPriority.NORMAL, "import");
            }
        }

        open_media_list.clear ();
    }

    /*
     * StaticPlaylist stuff
     */

    public override bool support_playlists () {
        return true;
    }

    public override Gee.Collection<StaticPlaylist> get_playlists () {
        var result = new Gee.TreeSet<StaticPlaylist> ();
        result.add_all (_playlists);
        return result;
    }

    public override StaticPlaylist? playlist_from_id (int64 id) {
        lock (_playlists) {
            foreach (var p in get_playlists ()) {
                if (p.rowid == id) {
                    return p;
                }
            }
        }

        return null;
    }

    public override StaticPlaylist? playlist_from_name (string name) {
        if (name == p_music.name)
            return p_music;

        lock (_playlists) {
            foreach (var p in get_playlists ()) {
                if (p.name == name) {
                    return p;
                }
            }
        }

        return null;
    }

    public override void add_playlist (StaticPlaylist p) {
        string rv = "";
        foreach (var m in p.medias) {
            if (rv == "") {
                rv = "%lld".printf (m.rowid);
            } else {
                rv += ";%lld".printf (m.rowid);
            }
        }

        try {
            var builder = new Gda.SqlBuilder (Gda.SqlStatementType.INSERT);
            builder.set_table (Database.Playlists.TABLE_NAME);
            builder.add_field_value_as_gvalue ("name", p.name);
            builder.add_field_value_as_gvalue ("media", rv);
            var statement = builder.get_statement ();
            Gda.Set last_insert_row;
            connection.statement_execute_non_select (statement, null, out last_insert_row);
            var local_p = new LocalStaticPlaylist (last_insert_row.get_holder_value (Database.Playlists.ROWID).get_int64 (), connection);

            lock (_playlists) {
                _playlists.add (local_p);
            }

            playlist_added (local_p);
            debug ("playlist %s added", local_p.name);
        } catch (Error e) {
            critical (e.message);
        }
    }

    public override void remove_playlist (int64 id) {
        lock (_playlists) {
            foreach (var playlist in get_playlists ()) {
                if (playlist.rowid == id) {
                    _playlists.remove (playlist);
                    playlist_removed (playlist);
                    break;
                }
            }

            try {
                connection.delete_row_from_table (Database.Playlists.TABLE_NAME, "rowid", id);
            } catch (Error e) {
                critical (e.message);
            }
        }
    }

    /*
     * Smart playlists
     */

    public override bool support_smart_playlists () {
        return true;
    }

    public override Gee.Collection<SmartPlaylist> get_smart_playlists () {
        var result = new Gee.TreeSet<SmartPlaylist> ();
        result.add_all (_smart_playlists);
        return result;
    }

    public override SmartPlaylist? smart_playlist_from_id (int64 id) {
        lock (_smart_playlists) {
            foreach (var p in get_smart_playlists ()) {
                if (p.rowid == id) {
                    return p;
                }
            }
        }

        return null;
    }

    public override SmartPlaylist? smart_playlist_from_name (string name) {
        lock (_smart_playlists) {
            foreach (var p in get_smart_playlists ()) {
                if (p.name == name) {
                    return p;
                }
            }
         }

        return null;
    }

    public override void add_smart_playlist (SmartPlaylist p) {
        try {
            var builder = new Gda.SqlBuilder (Gda.SqlStatementType.INSERT);
            builder.set_table (Database.SmartPlaylists.TABLE_NAME);
            builder.add_field_value_as_gvalue ("name", p.name);
            var statement = builder.get_statement ();
            Gda.Set last_insert_row;
            connection.statement_execute_non_select (statement, null, out last_insert_row);
            if (last_insert_row != null) {
                var local_sp = new LocalSmartPlaylist (last_insert_row.get_holder_value (Database.SmartPlaylists.ROWID).get_int64 (), connection);
                local_sp.conditional = p.conditional;
                local_sp.limit = p.limit;
                local_sp.limit_amount = p.limit_amount;
                local_sp.add_queries (p.get_queries ());

                lock (_smart_playlists) {
                    _smart_playlists.add (local_sp);
                }

                smartplaylist_added (local_sp);
            }
        } catch (Error e) {
            critical (e.message);
        }
    }

    public override void remove_smart_playlist (int64 id) {
        lock (_smart_playlists) {
            foreach (var p in get_smart_playlists ()) {
                if (p.rowid == id) {
                    _smart_playlists.remove (p);
                    smartplaylist_removed (p);
                    break;
                }
            }
        }

        try {
            connection.delete_row_from_table (Database.SmartPlaylists.TABLE_NAME, "rowid", id);
        } catch (Error e) {
            critical (e.message);
        }
    }


    /******************** Media stuff ******************/

    public override void search_medias (string search) {
        if (search == "") {
            lock (_searched_medias) {
                _searched_medias.clear ();
                _searched_medias.add_all (_medias.values);
            }
            search_finished ();
            return;
        }

        uint parsed_rating;
        string parsed_search_string;
        String.base_search_method (search, out parsed_rating, out parsed_search_string);
        bool rating_search = parsed_rating > 0;
        // If we search for a special rating, don't search for something else.
        try {
            if (parsed_rating > 0) {
                var sql = new Gda.SqlBuilder (Gda.SqlStatementType.SELECT);
                sql.select_add_target (Database.Media.TABLE_NAME, null);
                sql.select_add_field ("rowid", null, null);
                var id_field = sql.add_id ("rating");
                var id_value = sql.add_expr_value (null, parsed_rating);
                var id_cond = sql.add_cond (Gda.SqlOperatorType.GEQ, id_field, id_value, 0);
                sql.set_where (id_cond);

                var statm = sql.get_statement ();
                var data_model = connection.statement_execute_select (statm, null);
                var data_model_iter = data_model.create_iter ();
                data_model_iter.move_to_row (-1);
                var rowids = new Gee.TreeSet<int64?> ();
                while (data_model_iter.move_next ()) {
                    unowned Value? val = data_model_iter.get_value_at (0);
                    rowids.add (val.get_int64 ());
                }

                var meds = medias_from_ids (rowids);
                lock (_searched_medias) {
                    _searched_medias.clear ();
                    _searched_medias.add_all (meds);
                }
            } else {
                var sql = new Gda.SqlBuilder (Gda.SqlStatementType.SELECT);
                sql.select_add_target (Database.Media.TABLE_NAME, null);
                sql.select_add_field ("rowid", null, null);
                Gda.SqlBuilderId[] ids = null;

                string[] fields = {"title", "artist", "composer", "album_artist", "album", "grouping", "comment"};
                foreach (var field in fields) {
                    var id_field = sql.add_id (field);
                    var id_value = sql.add_expr_value (null, "%"+search+"%");
                    ids += sql.add_cond (Gda.SqlOperatorType.LIKE, id_field, id_value, 0);
                }

                var id_cond = sql.add_cond_v (Gda.SqlOperatorType.OR, ids);
                sql.set_where (id_cond);

                var statm = sql.get_statement ();
                var data_model = connection.statement_execute_select (statm, null);
                var data_model_iter = data_model.create_iter ();
                data_model_iter.move_to_row (-1);
                var rowids = new Gee.TreeSet<int64?> ();
                while (data_model_iter.move_next ()) {
                    unowned Value? val = data_model_iter.get_value_at (0);
                    rowids.add (val.get_int64 ());
                }

                var meds = medias_from_ids (rowids);
                lock (_searched_medias) {
                    _searched_medias.clear ();
                    _searched_medias.add_all (meds);
                }
            }
        } catch (Error e) {
            critical ("Could not search for %s: %s", search, e.message);
        }

        Idle.add (() => {
            search_finished ();
            return GLib.Source.REMOVE;
        });
    }

    public override Gee.Collection<Media> get_search_result () {
        var result = new Gee.TreeSet<Media> ();
        result.add_all (_searched_medias);
        return result;
    }

    public void clear_medias () {
        message ("-- Clearing medias");

        // We really only want to clear the songs that are permanent and on the file system
        // Dont clear podcasts that link to a url, device media, temporary media, previews, songs
        var unset = new Gee.LinkedList<Media> ();
        foreach (var s in _medias.values) {
            if (!s.isTemporary && !s.isPreview)
                unset.add (s);
        }

        remove_medias (unset, false);
        debug ("--- MEDIAS CLEARED ---");
    }

    public override Gee.Collection<Media> get_medias () {
        var result = new Gee.TreeSet<Media> ();
        result.add_all (_medias.values);
        return result;
    }

    public override void update_media (Media s, bool updateMeta, bool record_time) {
        var one = new Gee.TreeSet<Media> ();
        one.add (s);
        update_medias (one, updateMeta, record_time);
    }

    public override void update_medias (Gee.Collection<Media> updates, bool updateMeta, bool record_time) {
        var updated = new Gee.TreeSet<Media> ();
        updated.add_all (updates);
        if (record_time) {
            foreach (Media s in updated) {
                    s.last_modified = (int)time_t ();
            }
        }

        debug ("%d media updated", updated.size);
        media_updated (updated.read_only_view);
        /* now do background work. even if updateMeta is true, so must user preferences */
        if (updateMeta)
            fo.save_media.begin (updated);
    }

    /**
     * Used extensively. All other media data stores a media rowid, and then
     * use this to retrieve the media. This is for memory saving and
     * consistency
     */

    public override Media? media_from_id (int64 id) {
        return _medias.get (id);
    }

    public override Media? find_media (Media to_find) {
        Media? found = null;
        lock (_medias) {
            foreach (var m in _medias.values) {
                if (to_find.title.down () == m.title.down () && to_find.artist.down () == m.artist.down ()) {
                    found = m;
                    break;
                }
            }
        }

        return found;
    }

    public override Media? media_from_file (File file) {
        lock (_medias) {
            foreach (var m in _medias.values) {
                if (m != null && m.file.equal (file))
                    return m;
            }
        }

        return null;
    }

    public override Media? media_from_uri (string uri) {
        lock (_medias) {
            foreach (var m in _medias.values) {
                if (m != null && m.uri == uri)
                    return m;
            }
        }

        return null;
    }

    public override Gee.Collection<Media> medias_from_ids (Gee.Collection<int64?> ids) {
        var media_collection = new Gee.TreeSet<Media> ();
        foreach (var id in ids) {
            var m = _medias.get (id);
            if (m != null) {
                media_collection.add (m);
            }
        }

        return media_collection;
    }

    public override Gee.Collection<Media> medias_from_uris (Gee.Collection<string> uris) {
        var media_collection = new Gee.LinkedList<Media> ();
        lock (_medias) {
            foreach (var m in _medias.values) {
                if (uris.contains (m.uri))
                    media_collection.add (m);
                if (media_collection.size == uris.size)
                    break;
            }
        }

        return media_collection;
    }

    public override void add_media (Media s) {
        var coll = new Gee.TreeSet<Media> ();
        coll.add (s);
        add_medias (coll);
    }

    public override void add_medias (Gee.Collection<Media> new_media) {
        if (new_media.is_empty) // happens more often than you would think
            return;

        // make a copy of the media list so that it doesn't get modified before
        // the async code (e.g. updating the smart playlists) is done with it
        var media = new Gee.TreeSet<Media> ();
        media.add_all (new_media);

        var local_media = new Gee.HashMap<int64?, LocalMedia> ((Gee.HashDataFunc<int64?>)GLib.int64_hash,
                                                  (Gee.EqualDataFunc<int64?>?)GLib.int64_equal, null);
        foreach (var m in media) {
            var local_m = new LocalMedia.from_media (connection, m);
            local_media.set (local_m.rowid, local_m);
            // Append the media into an album.
            if (local_m.get_album_hashkey () in album_info.keys) {
                var album = album_info.get (local_m.get_album_hashkey ());
                album.add_media (local_m);
            }

            if (local_m.album_info == null) {
                var album = new Album.from_media (local_m);
                album.add_media (local_m);
                album_info.set (album.get_hashkey (), album);
                if (album.cover_icon == null) {
                    var cover_import = new CoverImport (album);
                    cover_import.start ();
                }
            }
        }

        _medias.set_all (local_media);

        media_added (local_media.values.read_only_view);

        // Update search results
        if (App.main_window.searchField.text == "") {
            _searched_medias.add_all (local_media.values);
        } else {
            uint parsed_rating;
            string parsed_search_string;
            String.base_search_method (App.main_window.searchField.text, out parsed_rating, out parsed_search_string);
            bool rating_search = parsed_rating > 0;
            foreach (var m in local_media.values) {
                if (rating_search) {
                    if (m.rating == parsed_rating)
                        _searched_medias.add (m);
                } else if (Search.match_string_to_media (m, parsed_search_string)) {
                    _searched_medias.add (m);
                }
            }
        }

        search_finished ();
    }

    public override void remove_media (Media s, bool trash) {
        var coll = new Gee.TreeSet<Media> ();
        coll.add (s);
        remove_medias (coll, trash);
    }

    public override void remove_medias (Gee.Collection<Media> to_remove, bool trash) {
        var toRemove = new Gee.TreeSet<Media> ();
        toRemove.add_all (to_remove);
        if (App.player.current_media in toRemove)
            App.player.stop_playback ();

        if (trash)
            fo.remove_media (toRemove);

        // Emit signal before actually removing the media because otherwise
        // media_from_id () and media_from_ids () wouldn't work.
        media_removed (toRemove.read_only_view);

        lock (_medias) {
            foreach (Media s in toRemove) {
                _searched_medias.remove (s);
                _medias.unset (s.rowid);
            }
        }

        lock (_playlists) {
            foreach (var p in get_playlists ())
                p.remove_medias (toRemove);
        }

        foreach (var m in toRemove) {
            try {
                if(trash){
                    connection.delete_row_from_table (Database.Media.TABLE_NAME, "rowid", m.rowid);
                }
                else{
                    debug("Don't show flag set");
                    m.dont_show = 1;
                }
            } catch (Error e) {
                critical (e.message);
            }
        }

        search_finished ();
    }

    public Gee.TreeSet<Noise.Media> answer_to_device_sync (Device device) {
        var medias_to_sync = new Gee.TreeSet<Noise.Media> ();
        var prefs = get_preferences_for_device (device);
        if (prefs.sync_music == true) {
            if (prefs.sync_all_music == true) {
                medias_to_sync.add_all (get_medias ());
            } else {
                medias_to_sync.add_all (prefs.music_playlist.medias);
            }
        }

        return medias_to_sync;
    }

    public override bool start_file_operations (string? message) {
        if (_doing_file_operations)
            return false;

        NotificationManager.get_default ().update_progress (message, 0.0);
        _doing_file_operations = true;
        App.main_window.update_sensitivities.begin ();
        file_operations_started ();
        return true;
    }

    public override bool doing_file_operations () {
        return _doing_file_operations;
    }

    public override void finish_file_operations () {
        _doing_file_operations = false;
        debug ("file operations finished or cancelled");

        fo.index = fo.item_count +1;
        NotificationManager.get_default ().update_progress (null, 1);
        file_operations_done ();
    }

    Gee.HashMap<string, DevicePreferences> preferences = new Gee.HashMap<string, DevicePreferences> ((Gee.HashDataFunc)GLib.str_hash, (Gee.EqualDataFunc)GLib.str_equal);
    public DevicePreferences get_preferences_for_device (Device d) {
        var key = d.get_unique_identifier ();
        if (preferences.has_key (key)) {
            return preferences.get (key);
        } else {
            var pref = new DevicePreferences (d, connection);
            preferences.set (key, pref);
            return pref;
        }
    }

    private Gee.Collection<int64?> get_rowids_from_table (string table_name) {
        var ids = new Gee.TreeSet<int64?> ();
        try {
            var builder = new Gda.SqlBuilder (Gda.SqlStatementType.SELECT);
            builder.select_add_target (table_name, null);
            builder.select_add_field ("rowid", null, null);
            var data_model = connection.statement_execute_select (builder.get_statement (), null);
            for (int i = 0; i < data_model.get_n_rows (); i++) {
                var rowid = data_model.get_value_at (data_model.get_column_index ("rowid"), i);
                ids.add (rowid.get_int64 ());
            }
        } catch (Error e) {
            // TODO: Expose errors to the user !
            critical ("Could not query table %s : %s", table_name, e.message);
        }

        return ids;
    }
}
