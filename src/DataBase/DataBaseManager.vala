/*
 * Copyright (c) 2012 Noise Developers
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this program; see the file COPYING.  If not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Scott Ringwelski <sgringwe@mtu.edu>,
 *              Victor Eduardo <victoreduardm@gmail.com>
 */

public class Noise.DataBaseManager : GLib.Object {
    private Gda.Connection connection;
    private Gda.SqlParser parser;

    private static DataBaseManager? dbm = null;
    public static DataBaseManager get_default () {
        if (dbm == null)
            dbm = new DataBaseManager ();
        return dbm;
    }

    /** Creates a new DatabaseManager **/
    private DataBaseManager () {
        init_database ();
    }

    /** Creates/Reads the database file and folder **/
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

    /**
     * Loads media from db
     */
    public Gee.TreeSet<LocalMedia> load_media () {
        var rv = new Gee.TreeSet<LocalMedia>();
        try {
            var statement = parser.parse_string ("SELECT rowid FROM media", null);
            var data_model = connection.statement_execute_select (statement, null);
            var rows = data_model.get_n_rows ();
            var rowid_column = data_model.get_column_index ("rowid");
            for (int i = 0; i < rows; i++) {
                var rowid_value = data_model.get_value_at (rowid_column, i);
                var m = new LocalMedia (rowid_value.get_int ());
                rv.add (m);
            }
        } catch (Error e) {
            warning (e.message);
        }

        return rv;
    }

    public void clear_media () {
        try {
            var statement = parser.parse_string ("DELETE FROM media", null);
            connection.statement_execute_non_select (statement, null, null);
        } catch (Error e) {
            critical (e.message);
        }
    }

    public Gee.TreeSet<LocalMedia> add_media (Gee.Collection<Media> media) {
        assert (database != null);
        var tree_set = new Gee.TreeSet<LocalMedia> ();
        var col_names = get_media_columns ();
        try {
            var sql = """INSERT INTO media (uri, file_size, title, artist, composer, album_artist,
album, grouping, genre, comment, lyrics, has_embedded, year, track, track_count, album_number, album_count,
bitrate, length, samplerate, rating, playcount, skipcount, dateadded, lastplayed, lastmodified)
VALUES (:uri, :file_size, :title, :artist, :composer, :album_artist, :album, :grouping,
:genre, :comment, :lyrics, :has_embedded, :year, :track, :track_count, :album_number, :album_count, :bitrate, :length, :samplerate,
:rating, :playcount, :skipcount, :dateadded, :lastplayed, :lastmodified);""";
            Gda.Set parameters;
            var statement = connection.parse_sql_string (sql, out parameters);
            Gda.Set last_insert_row;
            foreach (var s in media) {
                if (!s.isTemporary) {
                    parameters.get_holder ("uri").set_value (make_string_value (s.uri));
                    parameters.get_holder ("title").set_value (make_string_value (s.title));
                    parameters.get_holder ("artist").set_value (make_string_value (s.artist));
                    parameters.get_holder ("composer").set_value (make_string_value (s.composer));
                    parameters.get_holder ("album_artist").set_value (make_string_value (s.album_artist));
                    parameters.get_holder ("album").set_value (make_string_value (s.album));
                    parameters.get_holder ("grouping").set_value (make_string_value (s.grouping));
                    parameters.get_holder ("genre").set_value (make_string_value (s.genre));
                    parameters.get_holder ("comment").set_value (make_string_value (s.comment));
                    parameters.get_holder ("lyrics").set_value (make_string_value (s.lyrics));

                    parameters.get_holder ("has_embedded").set_value (make_bool_value (s.has_embedded));

                    parameters.get_holder ("file_size").set_value (make_uint64_value (s.file_size));

                    parameters.get_holder ("year").set_value (make_uint_value (s.year));
                    parameters.get_holder ("track").set_value (make_uint_value (s.track));
                    parameters.get_holder ("track_count").set_value (make_uint_value (s.track_count));
                    parameters.get_holder ("year").set_value (make_uint_value (s.year));
                    parameters.get_holder ("album_number").set_value (make_uint_value (s.album_number));
                    parameters.get_holder ("album_count").set_value (make_uint_value (s.album_count));
                    parameters.get_holder ("bitrate").set_value (make_uint_value (s.bitrate));
                    parameters.get_holder ("length").set_value (make_uint_value (s.length));
                    parameters.get_holder ("samplerate").set_value (make_uint_value (s.samplerate));
                    parameters.get_holder ("rating").set_value (make_uint_value (s.rating));
                    parameters.get_holder ("playcount").set_value (make_uint_value (s.play_count));
                    parameters.get_holder ("skipcount").set_value (make_uint_value (s.skip_count));
                    parameters.get_holder ("dateadded").set_value (make_uint_value (s.date_added));
                    parameters.get_holder ("lastplayed").set_value (make_uint_value (s.last_played));
                    parameters.get_holder ("lastmodified").set_value (make_uint_value (s.last_modified));
                    connection.statement_execute_non_select (statement, parameters, out last_insert_row);
                    var local_media = new LocalMedia (last_insert_row.get_holder_value ("rowid").get_int ());
                    tree_set.add (local_media);
                }
            }
        } catch (Error e) {
            warning ("Could not save media: %s", e.message);
        }

        return tree_set;
    }

    public void remove_media (Gee.Collection<Media> media) {
        assert (database != null);
        try {
            transaction = database.begin_transaction();
            var query = transaction.prepare ("DELETE FROM media WHERE rowid=:rowid");

            foreach (var m in media) {
                query.set_int (":rowid", m.rowid);
                query.execute ();
            }

            transaction.commit ();
        }
        catch (SQLHeavy.Error err) {
            warning ("Could not remove media from db: %s\n", err.message);
        }
    }

    /** COLUMNS STATE **
     * load_columns_state() loads the state of each columns from db
     *
     */
    public Gee.HashMap<Playlist, TreeViewSetup> load_columns_state () {
        debug ("load columns");
        var rv = new Gee.HashMap<Playlist, TreeViewSetup>();

        /*try {
            string script = "SELECT * FROM columns";
            var query = new SQLHeavy.Query (database, script);

            for (var results = query.execute(); !results.finished; results.next() ) {
                if (results.fetch_int(0) == 0) {
                    StaticPlaylist p = libraries_manager.local_library.playlist_from_name (results.fetch_string(1));
                    var tvs = new TreeViewSetup (results.fetch_int(2), Gtk.SortType.ASCENDING, ViewWrapper.Hint.PLAYLIST);
                    tvs.set_sort_direction_from_string(results.fetch_string(3));
                    tvs.import_columns(results.fetch_string(4));
                    rv.set (p, tvs);
                } else {
                    SmartPlaylist p = libraries_manager.local_library.smart_playlist_from_name (results.fetch_string(1));
                    var tvs = new TreeViewSetup (results.fetch_int(2), Gtk.SortType.ASCENDING, ViewWrapper.Hint.SMART_PLAYLIST);
                    tvs.set_sort_direction_from_string(results.fetch_string(3));
                    tvs.import_columns(results.fetch_string(4));
                    rv.set (p, tvs);
                }
            }
        }
        catch (SQLHeavy.Error err) {
            warning ("Could not load columns from db: %s\n", err.message);
        }*/

        return rv;
    }

    public void save_columns_state (Gee.Collection<StaticPlaylist>? playlists = null, Gee.Collection<SmartPlaylist>? smart_playlists = null) {
        debug ("save columns");
        /*assert (database != null);
        try {
            database.execute("DELETE FROM columns");
            transaction = database.begin_transaction();
            var query = transaction.prepare ("""INSERT INTO columns (is_smart, name, sort_column_id, sort_direction, columns) 
                                                VALUES (:is_smart, :name, :sort_column_id, :sort_direction, :columns);""");

            if (playlists != null) {
                foreach(StaticPlaylist p in playlists) {
                    if (p.read_only == false) {
                        var tvs = App.main_window.get_treeviewsetup_from_playlist (p);
                        
                        query.set_int    (":is_smart", 0);
                        query.set_string (":name", p.name);
                        query.set_int    (":sort_column_id", tvs.sort_column_id);
                        query.set_string (":sort_direction", tvs.sort_direction_to_string());
                        query.set_string (":columns", tvs.columns_to_string());

                        query.execute();
                    }
                }
            }
            
            if (smart_playlists != null) {
                foreach(SmartPlaylist p in smart_playlists) {
                    var tvs = App.main_window.get_treeviewsetup_from_playlist (p);
                    
                    query.set_int    (":is_smart", 1);
                    query.set_string (":name", p.name);
                    query.set_int    (":sort_column_id", tvs.sort_column_id);
                    query.set_string (":sort_direction", tvs.sort_direction_to_string());
                    query.set_string (":columns", tvs.columns_to_string());

                    query.execute();
                }
            }

            transaction.commit();
        }
        catch(SQLHeavy.Error err) {
            warning ("Could not save playlists: %s \n", err.message);
        }*/
    }

    public void add_columns_state (StaticPlaylist? p = null, SmartPlaylist? sp = null) {
        debug ("add columns");
        /*assert (database != null);
        
        string name = "";
        int is_smart = 0;
        TreeViewSetup tvs;
        if (sp == null) {
            if (p == null)
                return;
            if (p.read_only == true)
                return;
            name = p.name;
            tvs = App.main_window.get_treeviewsetup_from_playlist (p);
        } else {
            if (sp == null)
                return;
            is_smart = 1;
            name = sp.name;
            tvs = App.main_window.get_treeviewsetup_from_playlist (sp);
        }

        try {
            transaction = database.begin_transaction();
            var query = transaction.prepare ("""INSERT INTO columns (is_smart, name, sort_column_id, sort_direction, columns) 
                                                VALUES (:is_smart, :name, :sort_column_id, :sort_direction, :columns);""");
            
            query.set_int    (":is_smart", is_smart);
            query.set_string (":name", name);
            query.set_int    (":sort_column_id", tvs.sort_column_id);
            query.set_string (":sort_direction", tvs.sort_direction_to_string());
            query.set_string (":columns", tvs.columns_to_string());
            query.execute();
            
            transaction.commit();
        }
        catch(SQLHeavy.Error err) {
            warning ("Could not add columns: %s \n", err.message);
        }*/
    }

    public void remove_columns_state (StaticPlaylist? p = null, SmartPlaylist? sp = null) {
        debug ("remove columns");
        /*assert (database != null);
        
        string name = "";
        if (sp == null) {
            if (p == null)
                return;
            if (p.read_only == true)
                return;
            name = p.name;
        } else {
            if (sp == null)
                return;
            name = sp.name;
        }
        try {
            transaction = database.begin_transaction();
            var query = transaction.prepare("""DELETE FROM columns WHERE name=:name""");

            query.set_string(":name", name);
            query.execute();

            transaction.commit();
        }
        catch (SQLHeavy.Error err) {
            warning ("Could not remove column from db: %s\n", err.message);
        }*/
    }

    public void add_default_columns () {
        assert (database != null);
        try {
            
            TreeViewSetup tvs = new TreeViewSetup (ListColumn.ARTIST, Gtk.SortType.ASCENDING, ViewWrapper.Hint.SMART_PLAYLIST);
            
            transaction = database.begin_transaction();
            var query = transaction.prepare ("""INSERT INTO columns (is_smart, name, sort_column_id, sort_direction, columns) 
                                                VALUES (:is_smart, :name, :sort_column_id, :sort_direction, :columns);""");

            query.set_int    (":is_smart", 1);
            query.set_string (":name", _("Favorite Songs"));
            query.set_int    (":sort_column_id", ListColumn.RATING);
            query.set_string (":sort_direction", tvs.sort_direction_to_string ());
            query.set_string (":columns", tvs.columns_to_string ());
            query.execute ();

            query.set_int    (":is_smart", 1);
            query.set_string (":name", _("Recently Added"));
            query.set_int    (":sort_column_id", ListColumn.ARTIST);
            query.set_string (":sort_direction", tvs.sort_direction_to_string ());
            query.set_string (":columns", tvs.columns_to_string ());
            query.execute ();

            query.set_int    (":is_smart", 1);
            query.set_string (":name", _("Recent Favorites"));
            query.set_int    (":sort_column_id", ListColumn.RATING);
            query.set_string (":sort_direction", tvs.sort_direction_to_string ());
            query.set_string (":columns", tvs.columns_to_string ());
            query.execute ();

            query.set_int    (":is_smart", 1);
            query.set_string (":name", _("Never Played"));
            query.set_int    (":sort_column_id", ListColumn.ARTIST);
            query.set_string (":sort_direction", tvs.sort_direction_to_string ());
            query.set_string (":columns", tvs.columns_to_string ());
            query.execute ();

            query.set_int    (":is_smart", 1);
            query.set_string (":name", _("Over Played"));
            query.set_int    (":sort_column_id", ListColumn.PLAY_COUNT);
            query.set_string (":sort_direction", tvs.sort_direction_to_string ());
            query.set_string (":columns", tvs.columns_to_string ());
            query.execute ();

            query.set_int    (":is_smart", 1);
            query.set_string (":name", _("Not Recently Played"));
            query.set_int    (":sort_column_id", ListColumn.NUMBER);
            query.set_string (":sort_direction", tvs.sort_direction_to_string ());
            query.set_string (":columns", tvs.columns_to_string ());
            query.execute ();

            transaction.commit();
        }
        catch (SQLHeavy.Error err) {
            warning ("Could not initialize columns: %s\n", err.message);
        }
    }

    /** PLAYLISTS **
     * load_playlists() loads playlists from db
     *
     * playlist_from_id loads playlist of given rowid
     *
     * playlist_from_name() loads playlsit given a name
     */
    public Gee.ArrayList<StaticPlaylist> load_playlists () {
        var rv = new Gee.ArrayList<StaticPlaylist>();
        assert (database != null);

        try {
            string script = "SELECT * FROM playlists";
            var query = new SQLHeavy.Query (database, script);

            for (var results = query.execute(); !results.finished; results.next() ) {
                var p = new StaticPlaylist.with_info(0, results.fetch_string(0));
                
                string media = results.fetch_string(1);
                
                string[] media_strings = media.split("<sep>", 0);
                int index;
                var uris = new Gee.LinkedList<string> ();
                for (index = 0; index < media_strings.length - 1; ++index) {
                    uris.add (media_strings[index]);
                }
                p.add_medias (libraries_manager.local_library.medias_from_uris (uris));

                if (!rv.contains (p))
                    rv.add(p);
            }
        }
        catch (SQLHeavy.Error err) {
            warning ("Could not load playlists from db: %s\n", err.message);
        }

        return rv;
    }

    public void save_playlists (Gee.Collection<StaticPlaylist> playlists) {
        assert (database != null);
        try {
            database.execute("DELETE FROM playlists");
            transaction = database.begin_transaction();
            var query = transaction.prepare ("INSERT INTO playlists (name, media) VALUES (:name, :media);");

            foreach (var p in playlists) {
                if (p.read_only == false || p.name == C_("Name of the playlist", "Queue") || p.name == _("History")) {
                    string rv = "";
                    
                    foreach (var m in p.medias) {
                        if (m != null)
                            rv += m.uri + "<sep>";
                    }
                    query.set_string(":name", p.name);
                    query.set_string(":media", rv);

                    query.execute();
                }
            }

            transaction.commit();
        }
        catch(SQLHeavy.Error err) {
            warning ("Could not save playlists: %s \n", err.message);
        }
    }

    public void save_playlist (StaticPlaylist p, string? old_name = null) {
        assert (database != null);
        try {
            if (p.read_only == true)
                return;
            
            if (old_name == null) {
                remove_playlist (p);
            } else {
                var pl = new StaticPlaylist.with_info (0, old_name);
                remove_playlist (pl);
            }
            transaction = database.begin_transaction();
            var query = transaction.prepare ("INSERT INTO playlists (name, media) VALUES (:name, :media);");

            string rv = "";
            
            foreach (var m in p.medias) {
                if (m != null)
                    rv += m.uri + "<sep>";
            }
            query.set_string(":name", p.name);
            query.set_string(":media", rv);

            query.execute();

            transaction.commit();
        }
        catch(SQLHeavy.Error err) {
            warning ("Could not save playlists: %s \n", err.message);
        }
    }

    public void add_playlist (StaticPlaylist p) {
        assert (database != null);
        if (p.read_only == true)
            return;
        string rv = "";
        
        foreach (var m in p.medias) {
            if (m != null)
                rv += m.uri + "<sep>";
        }

        try {
            transaction = database.begin_transaction();
            var query = transaction.prepare ("""INSERT INTO playlists (name, media)
                                                VALUES (:name, :media);""");

            query.set_string(":name", p.name);
            query.set_string(":media", rv);

            query.execute();

            transaction.commit();
        
            debug ("playlist %s stored into database", p.name);
        }
        catch(SQLHeavy.Error err) {
            warning ("Could not add playlists: %s \n", err.message);
        }
    }

    /*public void update_playlists(LinkedList<StaticPlaylist> playlists) {
        try {
            transaction = database.begin_transaction();
            var query = transaction.prepare("UPDATE playlists SET name=:name, media=:media, sort_column_id=:sort_column_id, sort_direction=:sort_direction, columns=:columns  WHERE name=:name");

            foreach (var p in playlists) {
                query.set_string(":name", p.name);
                query.set_string(":media", p.media_to_string(App.library_manager));
                query.set_int(":sort_column_id", p.tvs.sort_column_id);
                query.set_string(":sort_direction", p.tvs.sort_direction_to_string());
                query.set_string(":columns", p.tvs.columns_to_string());

                query.execute();
            }

            transaction.commit();
        }
        catch(SQLHeavy.Error err) {
            warning ("Could not update playlist: %s \n", err.message);
        }
    }*/

    public void remove_playlist (StaticPlaylist p) {
        assert (database != null);
        if (p.read_only == true)
            return;
        try {
            transaction = database.begin_transaction();
            var query = transaction.prepare("""DELETE FROM playlists WHERE name=:name""");

            query.set_string(":name", p.name);
            query.execute();

            transaction.commit();
        }
        catch (SQLHeavy.Error err) {
            warning ("Could not remove playlist from db: %s\n", err.message);
        }
    }

    /** SMART PLAYLISTS **/

    private static const string QUERY_SEPARATOR = "<query_sep>";
    private static const string VALUE_SEPARATOR = "<val_sep>";

    /** temp_playlist should be in format of #,#,#,#,#, **/
    public static Gee.LinkedList<SmartQuery> queries_from_string (string q) {
        string[] queries_in_string = q.split(QUERY_SEPARATOR, 0);
        int index;

        var queries = new Gee.LinkedList<SmartQuery> ();
        for(index = 0; index < queries_in_string.length - 1; index++) {
            string[] pieces_of_query = queries_in_string[index].split(VALUE_SEPARATOR, 3);
            pieces_of_query.resize (3);

            SmartQuery sq = new SmartQuery();
            sq.field = (SmartQuery.FieldType)int.parse(pieces_of_query[0]);
            sq.comparator = (SmartQuery.ComparatorType)int.parse(pieces_of_query[1]);
            sq.value = pieces_of_query[2];

            queries.add (sq);
        }

        return queries;
    }

    // FIXME: This is an implementation detail and should not be present in the core.
    public static string queries_to_string (Gee.Collection<SmartQuery> queries) {
        string rv = "";
        foreach (SmartQuery q in queries) {
            rv += ((int)q.field).to_string () + VALUE_SEPARATOR + ((int)q.comparator).to_string() + VALUE_SEPARATOR + q.value + QUERY_SEPARATOR;
        }

        return rv;
    }

    public void add_default_smart_playlists () {
        assert (database != null);
        try {
            transaction = database.begin_transaction();
            var query = transaction.prepare ("""INSERT INTO smart_playlists (name, and_or, queries, limit, limit_amount) VALUES (:name, :and_or, :queries, :limit, :limit_amount);""");

            query.set_string(":name", _("Favorite Songs"));
            query.set_int(":and_or", 1);
            query.set_string(":queries", "11<val_sep>2<val_sep>4<query_sep>13<val_sep>0<val_sep>0<query_sep>12<val_sep>6<val_sep>3<query_sep>");
            query.set_int(":limit", 1);
            query.set_int(":limit_amount", 50);
            query.execute();

            query.set_string(":name", _("Recently Added"));
            query.set_int(":and_or", 1);
            query.set_string(":queries", "5<val_sep>7<val_sep>7<query_sep>");
            query.set_int(":limit", 1);
            query.set_int(":limit_amount", 50);
            query.execute();

            /*
            query.set_string(":name", _("Recently Played"));
            query.set_int(":and_or", 1);
            query.set_string(":queries", "9<val_sep>7<val_sep>7<query_sep>");
            query.set_int(":limit", 0);
            query.set_int(":limit_amount", 50);
            query.execute();
            */

            query.set_string(":name", _("Recent Favorites"));
            query.set_int(":and_or", 1);
            query.set_string(":queries", "11<val_sep>2<val_sep>4<query_sep>13<val_sep>0<val_sep>0<query_sep>9<val_sep>7<val_sep>7<query_sep>");
            query.set_int(":limit", 1);
            query.set_int(":limit_amount", 50);
            query.execute();

            query.set_string(":name", _("Never Played"));
            query.set_int(":and_or", 0);
            query.set_string(":queries", "11<val_sep>0<val_sep>0<query_sep>");
            query.set_int(":limit", 1);
            query.set_int(":limit_amount", 50);
            query.execute();

            query.set_string(":name", _("Over Played"));
            query.set_int(":and_or", 1);
            query.set_string(":queries", "11<val_sep>4<val_sep>10<query_sep>");
            query.set_int(":limit", 1);
            query.set_int(":limit_amount", 50);
            query.execute();

            query.set_string(":name", _("Not Recently Played"));
            query.set_int(":and_or", 1);
            query.set_string(":queries", "9<val_sep>8<val_sep>7<query_sep>");
            query.set_int(":limit", 1);
            query.set_int(":limit_amount", 50);
            query.execute();

            transaction.commit();
        }
        catch (SQLHeavy.Error err) {
            warning ("Could not initialize smart playlists: %s\n", err.message);
        }
    }

    public Gee.ArrayList<SmartPlaylist> load_smart_playlists() {
        var rv = new Gee.ArrayList<SmartPlaylist>();
        assert (database != null);

        try {
            string script = "SELECT * FROM smart_playlists";
            var query = new SQLHeavy.Query(database, script);

            for (var results = query.execute(); !results.finished; results.next() ) {
                SmartPlaylist p = new SmartPlaylist (libraries_manager.local_library);

                p.name = results.fetch_string(0);
                p.conditional = (SmartPlaylist.ConditionalType)results.fetch_int(1);
                p.add_queries (queries_from_string(results.fetch_string (2)));
                p.limit = ( results.fetch_string(3) == "1") ? true : false;
                p.limit_amount = results.fetch_int(4);

                rv.add(p);
            }
        }
        catch (SQLHeavy.Error err) {
            warning ("Could not load smart playlists from db: %s\n", err.message);
        }

        return rv;
    }

    public void save_smart_playlists(Gee.Collection<SmartPlaylist> smarts) {
        assert (database != null);
        try {
            database.execute("DELETE FROM smart_playlists");
            transaction = database.begin_transaction();
            var query = transaction.prepare ("INSERT INTO smart_playlists (name, and_or, queries, limit, limit_amount) VALUES (:name, :and_or, :queries, :limit, :limit_amount);");

            foreach(SmartPlaylist s in smarts) {
                query.set_string(":name", s.name);
                query.set_int(":and_or", (int)s.conditional);
                query.set_string(":queries", queries_to_string (s.get_queries ()));
                query.set_int(":limit", ( s.limit ) ? 1 : 0);
                query.set_int(":limit_amount", s.limit_amount);

                query.execute();
            }

            transaction.commit();
        } catch (SQLHeavy.Error err) {
            warning ("Could not save smart playlists: %s \n", err.message);
        }
    }

    public void save_smart_playlist (SmartPlaylist p, string? old_name = null) {
        assert (database != null);
        if (old_name == null) {
            remove_smart_playlist (p);
        } else {
            var sp = new SmartPlaylist (libraries_manager.local_library);
            sp.name = old_name;
            remove_smart_playlist (sp);
        }

        try {
            transaction = database.begin_transaction();
            var query = transaction.prepare("""INSERT INTO smart_playlists (name, and_or, queries, limit, limit_amount) VALUES (:name, :and_or, :queries, :limit, :limit_amount);""");

            query.set_string(":name", p.name);
            query.set_int(":and_or", (int)p.conditional);
            query.set_string(":queries", queries_to_string (p.get_queries ()));
            query.set_int(":limit", ( p.limit ) ? 1 : 0);
            query.set_int(":limit_amount", p.limit_amount);

            query.execute();
            transaction.commit();
        } catch(SQLHeavy.Error err) {
            warning ("Could not update smart playlist: %s \n", err.message);
        }
    }

    public void remove_smart_playlist (SmartPlaylist p) {
        assert (database != null);
        try {
            transaction = database.begin_transaction();
            var query = transaction.prepare("""DELETE FROM smart_playlists WHERE name=:name""");

            query.set_string(":name", p.name);
            query.execute();

            transaction.commit();
        } catch (SQLHeavy.Error err) {
            warning ("Could not remove smart playlist from db: %s\n", err.message);
        }
    }

    public Gee.Collection<DevicePreferences> load_devices() {
        assert (database != null);
        var rv = new Gee.ArrayList<DevicePreferences>();

        try {
            string script = """SELECT rowid,* FROM devices""";
            var query = new SQLHeavy.Query(database, script);

            for (var results = query.execute(); !results.finished; results.next() ) {
                DevicePreferences dp = new DevicePreferences(results.fetch_string(1));

                dp.sync_when_mounted = (results.fetch_int(2) == 1);
                dp.sync_music = (results.fetch_int(3) == 1);
                dp.sync_podcasts = (results.fetch_int(4) == 1);
                dp.sync_audiobooks = (results.fetch_int(5) == 1);
                dp.sync_all_music = (results.fetch_int(6) == 1);
                dp.sync_all_podcasts = (results.fetch_int(7) == 1);
                dp.sync_all_audiobooks = (results.fetch_int(8) == 1);
                if (results.fetch_string(9) != null) {
                    dp.music_playlist = libraries_manager.local_library.playlist_from_name (results.fetch_string(9));
                    if (dp.music_playlist == null)
                        dp.music_playlist = libraries_manager.local_library.smart_playlist_from_name (results.fetch_string(9));
                }
                if (results.fetch_string(10) != null) {
                    dp.podcast_playlist = libraries_manager.local_library.playlist_from_name (results.fetch_string(10));
                    if (dp.podcast_playlist == null)
                        dp.podcast_playlist = libraries_manager.local_library.smart_playlist_from_name (results.fetch_string(10));
                }
                if (results.fetch_string(11) != null) {
                    dp.audiobook_playlist = libraries_manager.local_library.playlist_from_name (results.fetch_string(11));
                    if (dp.audiobook_playlist == null)
                        dp.audiobook_playlist = libraries_manager.local_library.smart_playlist_from_name (results.fetch_string(11));
                }
                dp.last_sync_time = results.fetch_int(12);

                rv.add (dp);
            }
        } catch (SQLHeavy.Error err) {
            warning ("Could not load devices from db: %s\n", err.message);
        }

        return rv;
    }

    public void save_devices(Gee.Collection<DevicePreferences> devices) {
        assert (database != null);
        try {
            database.execute("DELETE FROM devices");
            transaction = database.begin_transaction();
            var query = transaction.prepare("""INSERT INTO devices (unique_id, sync_when_mounted, sync_music,
            sync_podcasts, sync_audiobooks, sync_all_music, sync_all_podcasts, sync_all_audiobooks, music_playlist,
            podcast_playlist, audiobook_playlist, last_sync_time) VALUES (:unique_id, :sync_when_mounted, :sync_music, :sync_podcasts, :sync_audiobooks,
            :sync_all_music, :sync_all_podcasts, :sync_all_audiobooks, :music_playlist, :podcast_playlist, :audiobook_playlist, :last_sync_time);""");

            foreach(DevicePreferences dp in devices) {
                query.set_string(":unique_id", dp.id);
                query.set_int(":sync_when_mounted", dp.sync_when_mounted ? 1 : 0);

                query.set_int(":sync_music", dp.sync_music ? 1 : 0);
                query.set_int(":sync_podcasts", dp.sync_podcasts ? 1 : 0);
                query.set_int(":sync_audiobooks", dp.sync_audiobooks ? 1 : 0);

                query.set_int(":sync_all_music", dp.sync_all_music ? 1 : 0);
                query.set_int(":sync_all_podcasts", dp.sync_all_podcasts ? 1 : 0);
                query.set_int(":sync_all_audiobooks", dp.sync_all_audiobooks ? 1 : 0);
                
                string music_playlist = "";
                string podcast_playlist = "";
                string audiobook_playlist = "";
                
                if (dp.music_playlist != null)
                    music_playlist = dp.music_playlist.name;
                if (dp.podcast_playlist != null)
                    podcast_playlist = dp.podcast_playlist.name;
                if (dp.audiobook_playlist != null)
                    audiobook_playlist = dp.audiobook_playlist.name;

                query.set_string(":music_playlist", music_playlist);
                query.set_string(":podcast_playlist", podcast_playlist);
                query.set_string(":audiobook_playlist", audiobook_playlist);
                query.set_int(":last_sync_time", dp.last_sync_time);

                query.execute();
            }

            transaction.commit();
        } catch (SQLHeavy.Error err) {
            warning ("Could not save devices: %s\n", err.message);
        }
    }

    public void save_device (DevicePreferences dp) {
        assert (database != null);
        try {
            remove_device (dp);
            transaction = database.begin_transaction();
            var query = transaction.prepare("""INSERT INTO devices (unique_id, sync_when_mounted, sync_music,
            sync_podcasts, sync_audiobooks, sync_all_music, sync_all_podcasts, sync_all_audiobooks, music_playlist,
            podcast_playlist, audiobook_playlist, last_sync_time) VALUES (:unique_id, :sync_when_mounted, :sync_music, :sync_podcasts, :sync_audiobooks,
            :sync_all_music, :sync_all_podcasts, :sync_all_audiobooks, :music_playlist, :podcast_playlist, :audiobook_playlist, :last_sync_time);""");

            query.set_string(":unique_id", dp.id);
            query.set_int(":sync_when_mounted", dp.sync_when_mounted ? 1 : 0);

            query.set_int(":sync_music", dp.sync_music ? 1 : 0);
            query.set_int(":sync_podcasts", dp.sync_podcasts ? 1 : 0);
            query.set_int(":sync_audiobooks", dp.sync_audiobooks ? 1 : 0);

            query.set_int(":sync_all_music", dp.sync_all_music ? 1 : 0);
            query.set_int(":sync_all_podcasts", dp.sync_all_podcasts ? 1 : 0);
            query.set_int(":sync_all_audiobooks", dp.sync_all_audiobooks ? 1 : 0);
                
            string music_playlist = "";
            string podcast_playlist = "";
            string audiobook_playlist = "";
            
            if (dp.music_playlist != null)
                music_playlist = dp.music_playlist.name;
            if (dp.podcast_playlist != null)
                podcast_playlist = dp.podcast_playlist.name;
            if (dp.audiobook_playlist != null)
                audiobook_playlist = dp.audiobook_playlist.name;

            query.set_string(":music_playlist", music_playlist);
            query.set_string(":podcast_playlist", podcast_playlist);
            query.set_string(":audiobook_playlist", audiobook_playlist);
            query.set_int(":last_sync_time", dp.last_sync_time);

            query.execute();

            transaction.commit();
        }
        catch(SQLHeavy.Error err) {
            warning ("Could not save device: %s\n", err.message);
        }
    }

    public void remove_device (DevicePreferences device) {
        assert (database != null);
        try {
            transaction = database.begin_transaction();
            var query = transaction.prepare("""DELETE FROM devices WHERE unique_id=:unique_id""");

            query.set_string(":unique_id", device.id);
            query.execute();

            transaction.commit();
        }
        catch (SQLHeavy.Error err) {
            warning ("Could not remove smart playlist from db: %s\n", err.message);
        }
    }

    /*
     * Utility functions
     */

    private static Value make_string_value (string str) {
        var val = Value (typeof(string));
        val.set_string (str);
    }

    private static Value make_bool_value (bool bl) {
        var val = Value (typeof(bool));
        val.set_boolean (bl);
    }

    private static Value make_uint_value (uint val) {
        var val = Value (typeof(uint));
        val.set_uint (val);
    }

    private static Value make_uint64_value (uint64 val) {
        var val = Value (typeof(uint64));
        val.set_uint64 (val);
    }
}
