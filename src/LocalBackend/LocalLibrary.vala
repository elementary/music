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
 * Authored by: Scott Ringwelski <sgringwe@mtu.edu>
 *              Victor Eduardo <victoreduardm@gmail.com>
 *              Corentin Noël <tintou@mailoo.org>
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
    private Gee.TreeSet<Media> _medias;
    private Gee.TreeSet<Media> _searched_medias;

    public StaticPlaylist p_music;

    public bool main_directory_set {
        get { return !String.is_empty (Settings.Main.get_default ().music_folder, true); }
    }

    private Gee.TreeSet<Media> open_media_list;
    private bool _doing_file_operations = false;

    private Gda.Connection connection;
    private Gda.SqlParser parser;

    public LocalLibrary () {
        libraries_manager.local_library = this;
        _playlists = new Gee.TreeSet<StaticPlaylist> ();
        _smart_playlists = new Gee.TreeSet<SmartPlaylist> ();
        _medias = new Gee.TreeSet<Media> ();
        _searched_medias = new Gee.TreeSet<Media> ();
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
        /*lock (_medias) {
            foreach (var m in dbm.load_media ()) {
                _medias.add (m);
            }
        }

        // Load smart playlists from database
        lock (_smart_playlists) {
            foreach (var p in dbm.load_smart_playlists ()) {
                _smart_playlists.add (p);
                p.rowid = playlists_rowid;
                playlists_rowid++;
                p.updated.connect ((old_name) => {smart_playlist_updated (p, old_name);});
            }
        }

        // Load all static playlists from database

        lock (_playlists) {
            foreach (var p in dbm.load_playlists ()) {
                if (p.name == C_("Name of the playlist", "Queue") || p.name == _("History")) {
                    continue;
                } else if (p.name != MUSIC_PLAYLIST) {
                    _playlists.add (p);
                    p.rowid = playlists_rowid;
                    playlists_rowid++;
                    p.updated.connect ((old_name) => {playlist_updated (p, old_name);});
                    continue;
                }
            }
        }

        DeviceManager.get_default ().set_device_preferences (dbm.load_devices ());*/
        load_media_art_cache.begin ();
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

        bool new_db = !database_dir.get_child ("database_0_3_0.db").query_exists ();

        try {
            connection = new Gda.Connection.from_string ("SQLite", "DB_DIR=%s;DB_NAME=database_0_3_0".printf (database_dir.get_path ()), null, Gda.ConnectionOptions.NONE);
            connection.open ();
        } catch (Error e) {
            error (e.message);
        }

        parser = connection.create_parser ();

        load_table (Database.Tables.PLAYLISTS);
        load_table (Database.Tables.SMART_PLAYLISTS);
        load_table (Database.Tables.COLUMNS);
        load_table (Database.Tables.MEDIA);
        load_table (Database.Tables.DEVICES);

        if (new_db)
            add_default_smart_playlists ();
    }

    private void load_table (string table) {
        try {
            var statement = parser.parse_string (table, null);
            connection.statement_execute_non_select (statement, null, null);
        } catch (Error e) {
            critical (e.message);
        }
    }

    private void load_local_media () {
        
    }

    /*
     * Media art utilities.
     */
    private async void load_media_art_cache () {
        lock (_medias) {
            yield CoverartCache.instance.load_for_media_async (get_medias ());
        }
    }

    private async void update_media_art_cache () {
        yield CoverartCache.instance.fetch_all_cover_art_async (get_medias ());
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
        
        if (start_file_operations (_("Importing music from %s…").printf ("<b>" + String.escape (m_folder) + "</b>"))) {
            remove_all_static_playlists ();

            clear_medias ();

            App.player.unqueue_media (_medias);

            App.player.reset_already_played ();
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
        debug ("found %d items to import\n", items);

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
        var to_import = new Gee.TreeSet<string> ();
        var files = new Gee.TreeSet<string> ();

        // get a list of the current files
        var music_folder_dir = Settings.Main.get_default ().music_folder;
        FileUtils.count_music_files (File.new_for_path (music_folder_dir), files);
        
        foreach (var m in get_medias ()) {
            if (!m.isTemporary && !m.isPreview && m.uri.contains (music_folder_dir))

            if (!File.new_for_uri (m.uri).query_exists ())
                to_remove.add (m);
            if (files.contains (m.uri))
                files.remove (m.uri);
        }

        if (!to_import.is_empty) {
            debug ("Importing %d new songs", to_import.size);
            fo.resetProgress (to_import.size - 1);
            Timeout.add (100, doProgressNotificationWithTimeout);
            fo.import_files (to_import, FileOperator.ImportType.RESCAN);
        } else {
            debug ("No new songs to import.");
        }

        if (files.is_empty)
            finish_file_operations ();

        if (!fo.cancellable.is_cancelled ()) {
            remove_medias (to_remove, false);
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
                Gdk.Pixbuf? pixbuf = null;
                if (open_media_list.size == 1) {
                    var first = open_media_list.first ();
                    pixbuf = CoverartCache.instance.get_original_cover (first).scale_simple (128, 128, Gdk.InterpType.HYPER);
                    secondary_text.append (first.get_display_title ());
                    secondary_text.append ("\n");
                    secondary_text.append (first.get_display_artist ());
                } else {
                    secondary_text.append (ngettext ("%d Track", "%d Tracks", open_media_list.size).printf (open_media_list.size));
                }

#if HAVE_LIBNOTIFY
                App.main_window.show_notification (primary_text, secondary_text.str, pixbuf, Notify.Urgency.LOW);
#else
                App.main_window.show_notification (primary_text, secondary_text.str, pixbuf);
#endif
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
        var result = new Gee.TreeSet<Media> ();
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
            builder.set_table ("playlists");
            builder.add_field_value_as_gvalue ("name", Database.make_string_value (p.name));
            builder.add_field_value_as_gvalue ("media", Database.make_string_value (rv));
            var statement = builder.get_statement ();
            Gda.Set last_insert_row;
            var result = connection.statement_execute_non_select (statement, null, out last_insert_row);
            var local_p = new LocalStaticPlaylist (connection);
            if (last_insert_row != null) {
                local_p.rowid = last_insert_row.get_holder_value (Database.Playlists.ROWID).get_int64 ();
            }

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
                connection.delete_row_from_table ("playlists", "rowid", Database.make_int64_value (id));
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
        var result = new Gee.TreeSet<Media> ();
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
            builder.set_table ("smart_playlists");
            builder.add_field_value_as_gvalue ("name", Database.make_string_value (p.name));
            var statement = builder.get_statement ();
            Gda.Set last_insert_row;
            connection.statement_execute_non_select (statement, null, out last_insert_row);
            if (last_insert_row != null) {
                var local_sp = new LocalSmartPlaylist (connection);
                local_sp.rowid = last_insert_row.get_holder_value (Database.SmartPlaylists.ROWID).get_int64 ();
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
            connection.delete_row_from_table ("smart_playlists", "rowid", Database.make_int64_value (id));
        } catch (Error e) {
            critical (e.message);
        }
    }

    public void add_default_smart_playlists () {
        try {
            var col_names = new GLib.SList<string> ();
            col_names.append ("name");
            col_names.append ("queries");
            col_names.append ("and_or");
            col_names.append ("limited");
            col_names.append ("limit_amount");

            var values = new GLib.SList<GLib.Value?> ();
            values.append (Database.make_string_value (_("Favorite Songs")));
            values.append (Database.make_string_value ("11<val_sep>2<val_sep>4<query_sep>13<val_sep>0<val_sep>0<query_sep>12<val_sep>6<val_sep>3"));
            values.append (Database.make_int_value (1));
            values.append (Database.make_int_value (1));
            values.append (Database.make_int_value (50));
            connection.insert_row_into_table_v ("smart_playlists", col_names, values);

            values = new GLib.SList<GLib.Value?> ();
            values.append (Database.make_string_value (_("Recently Added")));
            values.append (Database.make_string_value ("5<val_sep>7<val_sep>7"));
            values.append (Database.make_int_value (1));
            values.append (Database.make_int_value (1));
            values.append (Database.make_int_value (50));
            connection.insert_row_into_table_v ("smart_playlists", col_names, values);

            values = new GLib.SList<GLib.Value?> ();
            values.append (Database.make_string_value (_("Recent Favorites")));
            values.append (Database.make_string_value ("11<val_sep>2<val_sep>4<query_sep>13<val_sep>0<val_sep>0<query_sep>9<val_sep>7<val_sep>7"));
            values.append (Database.make_int_value (1));
            values.append (Database.make_int_value (1));
            values.append (Database.make_int_value (50));
            connection.insert_row_into_table_v ("smart_playlists", col_names, values);

            values = new GLib.SList<GLib.Value?> ();
            values.append (Database.make_string_value (_("Never Played")));
            values.append (Database.make_string_value ("11<val_sep>0<val_sep>0"));
            values.append (Database.make_int_value (0));
            values.append (Database.make_int_value (1));
            values.append (Database.make_int_value (50));
            connection.insert_row_into_table_v ("smart_playlists", col_names, values);

            values = new GLib.SList<GLib.Value?> ();
            values.append (Database.make_string_value (_("Over Played")));
            values.append (Database.make_string_value ("11<val_sep>4<val_sep>10"));
            values.append (Database.make_int_value (1));
            values.append (Database.make_int_value (1));
            values.append (Database.make_int_value (50));
            connection.insert_row_into_table_v ("smart_playlists", col_names, values);

            values = new GLib.SList<GLib.Value?> ();
            values.append (Database.make_string_value (_("Not Recently Played")));
            values.append (Database.make_string_value ("9<val_sep>8<val_sep>7"));
            values.append (Database.make_int_value (1));
            values.append (Database.make_int_value (1));
            values.append (Database.make_int_value (50));
            connection.insert_row_into_table_v ("smart_playlists", col_names, values);
        } catch (Error e) {
            critical ("Could not initialize smart playlists: %s", e.message);
        }
    }

    /******************** Media stuff ******************/
    
    public override void search_medias (string search) {
        lock (_searched_medias) {
            _searched_medias.clear ();
            if (search == "") {
                _searched_medias.add_all (_medias);
                search_finished ();
                return;
            }

            int parsed_rating;
            string parsed_search_string;
            String.base_search_method (search, out parsed_rating, out parsed_search_string);
            bool rating_search = parsed_rating > 0;
            lock (_medias) {
                foreach (var m in _medias) {
                    if (rating_search) {
                        if (m.rating == (uint) parsed_rating)
                            _searched_medias.add (m);
                    } else if (Search.match_string_to_media (m, parsed_search_string)) {
                        _searched_medias.add (m);
                    }
                }
            }
        }

        search_finished ();
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
        foreach (var s in _medias) {
            if (!s.isTemporary && !s.isPreview)
                unset.add (s);
        }

        remove_medias (unset, false);
        debug ("--- MEDIAS CLEARED ---");
    }

    public override Gee.Collection<Media> get_medias () {
        var result = new Gee.TreeSet<Media> ();
        result.add_all (_medias);
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
        lock (_medias) {
            foreach (var m in _medias) {
                if (m.rowid == id)
                    return m;
            }
        }

        return null;
    }

    public override Media? find_media (Media to_find) {
        Media? found = null;
        lock (_medias) {
            foreach (var m in _medias) {
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
            foreach (var m in _medias) {
                if (m != null && m.file.equal (file))
                    return m;
            }
        }

        return null;
    }

    public override Media? media_from_uri (string uri) {
        lock (_medias) {
            foreach (var m in _medias) {
                if (m != null && m.uri == uri)
                    return m;
            }
        }

        return null;
    }

    public override Gee.Collection<Media> medias_from_ids (Gee.Collection<int64?> ids) {
        var media_collection = new Gee.TreeSet<Media> ();
        lock (_medias) {
            foreach (var m in _medias) {
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
        lock (_medias) {
            foreach (var m in _medias) {
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

        var local_media = new Gee.TreeSet<LocalMedia> ();
        foreach (var m in media) {
            try {
                var builder = new Gda.SqlBuilder (Gda.SqlStatementType.INSERT);
                builder.set_table ("media");
                builder.add_field_value_as_gvalue ("uri", Database.make_string_value (m.uri));
                var statement = builder.get_statement ();
                Gda.Set last_insert_row;
                connection.statement_execute_non_select (statement, null, out last_insert_row);
                if (last_insert_row != null) {
                    var rowid = last_insert_row.get_holder_value (Database.Media.ROWID).get_int64 ();
                    var local_m = new LocalMedia (rowid, connection);
                    local_m.file_size = m.file_size;
                    local_m.track = m.track;
                    local_m.track_count = m.track_count;
                    local_m.album_number = m.album_number;
                    local_m.album_count = m.album_count;
                    local_m.title = m.title;
                    local_m.artist = m.artist;
                    local_m.composer = m.composer;
                    local_m.album_artist = m.album_artist;
                    local_m.album = m.album;
                    local_m.genre = m.genre;
                    local_m.grouping = m.grouping;
                    local_m.comment = m.comment;
                    local_m.year = m.year;
                    local_m.bitrate = m.bitrate;
                    local_m.length = m.length;
                    local_m.samplerate = m.samplerate;
                    local_m.bpm = m.bpm;
                    local_m.rating = m.rating;
                    local_m.play_count = m.play_count;
                    local_m.skip_count = m.skip_count;
                    local_m.date_added = m.date_added;
                    local_m.last_played = m.last_played;
                    local_m.lyrics = m.lyrics; 
                    local_m.isPreview = m.isPreview;
                    local_m.isTemporary = m.isTemporary;
                    local_m.last_modified = m.last_modified;
                    local_m.showIndicator = m.showIndicator;
                    local_m.unique_status_image = m.unique_status_image;
                    local_m.location_unknown = m.location_unknown;
                    local_media.add (local_m);
                }
            } catch (Error e) {
                warning ("Could not save media: %s", e.message);
            }
        }

        _medias.add_all (local_media);
        media_added (local_media.read_only_view);

        // Update search results
        if (App.main_window.searchField.text == "") {
            _searched_medias.add_all (local_media);
        } else {
            int parsed_rating;
            string parsed_search_string;
            String.base_search_method (App.main_window.searchField.text, out parsed_rating, out parsed_search_string);
            bool rating_search = parsed_rating > 0;
            foreach (var m in local_media) {
                if (rating_search) {
                    if (m.rating == (uint) parsed_rating)
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
                _medias.remove (s);
            }
        }

        lock (_playlists) {
            foreach (var p in get_playlists ())
                p.remove_medias (toRemove);
        }

        foreach (var m in toRemove) {
            try {
                connection.delete_row_from_table ("media", "rowid", Database.make_int64_value (m.rowid));
            } catch (Error e) {
                critical (e.message);
            }
        }

        search_finished ();
    }

    public Gee.TreeSet<Noise.Media> answer_to_device_sync (Device device) {
        var medias_to_sync = new Gee.TreeSet<Noise.Media> ();
        if (device.get_preferences ().sync_music == true) {
            if (device.get_preferences ().sync_all_music == true) {
                medias_to_sync.add_all (get_medias ());
            } else {
                medias_to_sync.add_all (device.get_preferences ().music_playlist.medias);
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
        update_media_art_cache.begin ();
    }
}
