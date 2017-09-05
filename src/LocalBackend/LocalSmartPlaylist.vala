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

public class Noise.LocalSmartPlaylist : SmartPlaylist {
    private const string QUERY_SEPARATOR = "<query_sep>";
    private const string VALUE_SEPARATOR = "<val_sep>";
    private Gda.Connection connection;

    /**
     * Metadata Fields
     */
    private string _name = null;
    public override string name {
        get {
            if (_name != null)
                return _name;

            _name = Database.query_field (rowid, connection, Database.SmartPlaylists.TABLE_NAME, "name").dup_string ();
            return _name;
        }
        construct set {
            _name = value;
            Database.set_field (rowid, connection, Database.SmartPlaylists.TABLE_NAME, "name", value);
        }
    }


    public override SmartPlaylist.ConditionalType conditional {
        get {
            return (SmartPlaylist.ConditionalType) Database.query_field (rowid, connection, Database.SmartPlaylists.TABLE_NAME, "and_or").get_int ();
        }
        set {
            Database.set_field (rowid, connection, Database.SmartPlaylists.TABLE_NAME, "and_or", value);
        }
    }

    public override uint limit_amount {
        get {
            return (uint)Database.query_field (rowid, connection, Database.SmartPlaylists.TABLE_NAME, "limit_amount").get_int ();
        }
        set {
            Database.set_field (rowid, connection, Database.SmartPlaylists.TABLE_NAME, "limit_amount", value);
        }
    }

    public override bool limit {
        get {
            var val = Database.query_field (rowid, connection, Database.SmartPlaylists.TABLE_NAME, "limited");
            return (bool)val.get_int ();
        }
        set {
            Database.set_field (rowid, connection, Database.SmartPlaylists.TABLE_NAME, "limited", value);
        }
    }

    public LocalSmartPlaylist (int64 rowid, Gda.Connection connection) {
        base (libraries_manager.local_library);
        this.connection = connection;
        this.rowid = rowid;
        var queries_str = Database.query_field (rowid, connection, Database.SmartPlaylists.TABLE_NAME, "queries").get_string ();
        queries_from_string (queries_str);
    }

    public override void analyse_all () {
        if (queries.is_empty) {
            var meds = library.get_medias ();
            medias.add_all (meds);
            media_added (meds);
            return;
        }

        var rowids = new Gee.TreeSet<int64?> ();
        try {
            var sql = new Gda.SqlBuilder (Gda.SqlStatementType.SELECT);
            sql.select_add_target (Database.Media.TABLE_NAME, null);
            sql.select_add_field ("rowid", null, null);
            Gda.SqlBuilderId[] ids = null;
            foreach (var q in queries) {
                ids += Database.process_smart_query (sql, q);
            }

            var sql_operator_type = Gda.SqlOperatorType.AND;
            if (conditional == ConditionalType.ANY) {
                sql_operator_type = Gda.SqlOperatorType.OR;
            }

            var id_cond = sql.add_cond_v (sql_operator_type, ids);
            sql.set_where (id_cond);

            var statm = sql.get_statement ();
            var data_model = connection.statement_execute_select (statm, null);
            var data_model_iter = data_model.create_iter ();
            data_model_iter.move_to_row (-1);
            while (data_model_iter.move_next ()) {
                unowned Value? val = data_model_iter.get_value_at (0);
                rowids.add (val.get_int64 ());
            }

            var meds = library.medias_from_ids (rowids);
            medias.add_all (meds);
            media_added (meds);
        } catch (Error e) {
            critical ("Could not query media for smart playlist %s: %s", name, e.message);
        }
    }

    public override void clear_queries () {
        base.clear_queries ();
        Database.set_field (rowid, connection, Database.SmartPlaylists.TABLE_NAME, "queries", "");
    }

    public override void add_query (SmartQuery s) {
        base.add_query (s);
        Database.set_field (rowid, connection, Database.SmartPlaylists.TABLE_NAME, "queries", queries_to_string ());
    }

    public override void add_queries (Gee.Collection<SmartQuery> queries) {
        base.add_queries (queries);
        Database.set_field (rowid, connection, Database.SmartPlaylists.TABLE_NAME, "queries", queries_to_string ());
    }

    private string queries_to_string () {
        var sb = new GLib.StringBuilder ();
        foreach (SmartQuery q in queries) {
            if (sb.len != 0) {
                sb.append (QUERY_SEPARATOR);
            }

            sb.append_printf ("%d", (int) q.field);
            sb.append (VALUE_SEPARATOR);
            sb.append_printf ("%d", (int) q.comparator);
            sb.append (VALUE_SEPARATOR);
            if (q.value.type () == typeof (string)) {
                sb.append (q.value.get_string ());
            } else {
                sb.append_printf ("%d", q.value.get_int ());
            }
        }

        return sb.str;
    }

    public void queries_from_string (string q) {
        string[] queries_in_string = q.split(QUERY_SEPARATOR, 0);
        var new_queries = new Gee.TreeSet<SmartQuery> ();
        foreach (var query_string in queries_in_string) {
            if (query_string == "")
                continue;

            string[] pieces_of_query = query_string.split (VALUE_SEPARATOR, 3);
            pieces_of_query.resize (3);

            SmartQuery sq = new SmartQuery();
            sq.field = (SmartQuery.FieldType)int.parse (pieces_of_query[0]);
            sq.comparator = (SmartQuery.ComparatorType)int.parse (pieces_of_query[1]);
            switch (sq.field) {
                case SmartQuery.FieldType.ALBUM:
                case SmartQuery.FieldType.ARTIST:
                case SmartQuery.FieldType.COMPOSER:
                case SmartQuery.FieldType.COMMENT:
                case SmartQuery.FieldType.GENRE:
                case SmartQuery.FieldType.GROUPING:
                case SmartQuery.FieldType.TITLE:
                    var val = Value (typeof (string));
                    val.set_string (pieces_of_query[2]);
                    sq.value = val;
                    break;
                default:
                    var val = Value (typeof (int));
                    val.set_int (int.parse (pieces_of_query[2]));
                    sq.value = val;
                    break;
            }

            new_queries.add (sq);
        }

        add_queries (new_queries);
    }

    public static void add_defaults (Gda.Connection connection) {
        try {
            var col_names = new GLib.SList<string> ();
            col_names.append ("name");
            col_names.append ("queries");
            col_names.append ("and_or");
            col_names.append ("limited");
            col_names.append ("limit_amount");

            var values = new GLib.SList<GLib.Value?> ();
            values.append (_("Favorite Songs"));
            values.append ("10<val_sep>2<val_sep>4<query_sep>12<val_sep>0<val_sep>0<query_sep>11<val_sep>6<val_sep>3");
            values.append (1);
            values.append (1);
            values.append (50);
            connection.insert_row_into_table_v (Database.SmartPlaylists.TABLE_NAME, col_names, values);

            values = new GLib.SList<GLib.Value?> ();
            values.append (_("Recently Added"));
            values.append ("5<val_sep>7<val_sep>7");
            values.append (1);
            values.append (1);
            values.append (50);
            connection.insert_row_into_table_v (Database.SmartPlaylists.TABLE_NAME, col_names, values);

            values = new GLib.SList<GLib.Value?> ();
            values.append (_("Recent Favorites"));
            values.append ("10<val_sep>2<val_sep>4<query_sep>12<val_sep>0<val_sep>0<query_sep>8<val_sep>7<val_sep>7");
            values.append (1);
            values.append (1);
            values.append (50);
            connection.insert_row_into_table_v (Database.SmartPlaylists.TABLE_NAME, col_names, values);

            values = new GLib.SList<GLib.Value?> ();
            values.append (_("Never Played"));
            values.append ("10<val_sep>0<val_sep>0");
            values.append (0);
            values.append (1);
            values.append (50);
            connection.insert_row_into_table_v (Database.SmartPlaylists.TABLE_NAME, col_names, values);

            values = new GLib.SList<GLib.Value?> ();
            values.append (_("Over Played"));
            values.append ("10<val_sep>6<val_sep>10");
            values.append (1);
            values.append (1);
            values.append (50);
            connection.insert_row_into_table_v (Database.SmartPlaylists.TABLE_NAME, col_names, values);

            values = new GLib.SList<GLib.Value?> ();
            values.append (_("Not Recently Played"));
            values.append ("8<val_sep>8<val_sep>7");
            values.append (1);
            values.append (1);
            values.append (50);
            connection.insert_row_into_table_v (Database.SmartPlaylists.TABLE_NAME, col_names, values);
        } catch (Error e) {
            critical ("Could not initialize smart playlists: %s", e.message);
        }
    }
}
