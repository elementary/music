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
 */

namespace Noise.Database {
    /*
     * NOTE:
     * Update those constants when you change the order of columns.
     */
    namespace Playlists {
        public const string TABLE_NAME = "playlists";
        public const string NAME = "+0";
        public const string MEDIA = "+1";
        public const string ROWID = "+2";
    }

    namespace SmartPlaylists {
        public const string TABLE_NAME = "smart_playlists";
        public const string NAME = "+0";
        public const string AND_OR = "+1";
        public const string QUERIES = "+2";
        public const string LIMITED = "+3";
        public const string LIMIT_AMOUNT = "+4";
        public const string ROWID = "+5";
    }

    namespace Media {
        public const string TABLE_NAME = "media";
        public const string URI = "+0";
        public const string FILE_SIZE = "+1";
        public const string TITLE = "+2";
        public const string ARTIST = "+3";
        public const string COMPOSER = "+4";
        public const string ALBUM_ARTIST = "+5";
        public const string ALBUM = "+6";
        public const string GROUPING = "+7";
        public const string GENRE = "+8";
        public const string COMMENT = "+9";
        public const string LYRICS = "+10";
        public const string HAS_EMBEDDED = "+11";
        public const string YEAR = "+12";
        public const string TRACK = "+13";
        public const string TRACK_COUNT = "+14";
        public const string ALBUM_NUMBER = "+15";
        public const string ALBUM_COUNT = "+16";
        public const string BITRATE = "+17";
        public const string LENGTH = "+18";
        public const string SAMPLERATE = "+19";
        public const string RATING = "+20";
        public const string PLAYCOUNT = "+21";
        public const string SKIPCOUNT = "+22";
        public const string DATEADDED = "+23";
        public const string LASTPLAYED = "+24";
        public const string LASTMODIFIED = "+25";
        public const string ROWID = "+26";
        public const string SHOW = "+27";
    }

    namespace Devices {
        public const string TABLE_NAME = "devices";
        public const string UNIQUE_ID = "+0";
        public const string SYNC_WHEN_MOUNTED = "+1";
        public const string SYNC_MUSIC = "+2";
        public const string SYNC_ALL_MUSIC = "+3";
        public const string MUSIC_PLAYLIST = "+4";
        public const string LAST_SYNC_TIME = "+5";
    }

    namespace Columns {
        public const string TABLE_NAME = "columns";
        public const string UNIQUE_ID = "+0";
        public const string SORT_COLUMN_ID = "+1";
        public const string SORT_DIRECTION = "+2";
        public const string COLUMNS = "+3";
    }

    public static GLib.Value? query_field (int64 rowid, Gda.Connection connection, string table, string field) {
        try {
            var sql = new Gda.SqlBuilder (Gda.SqlStatementType.SELECT);
            sql.select_add_target (table, null);
            sql.add_field_value_id (sql.add_id (field), 0);
            var id_field = sql.add_id ("rowid");
            var id_param = sql.add_expr_value (null, rowid);
            var id_cond = sql.add_cond (Gda.SqlOperatorType.EQ, id_field, id_param, 0);
            sql.set_where (id_cond);
            var data_model = connection.statement_execute_select (sql.get_statement (), null);
            return data_model.get_value_at (data_model.get_column_index (field), 0);
        } catch (Error e) {
            critical ("Could not query field %s: %s", field, e.message);
            return null;
        }
    }

    public static void set_field (int64 rowid, Gda.Connection connection, string table, string field, GLib.Value value) {
        try {
            var rowid_value = GLib.Value (typeof (int64));
            rowid_value.set_int64 (rowid);
            var col_names = new GLib.SList<string> ();
            col_names.append (field);
            var values = new GLib.SList<GLib.Value?> ();
            values.append (value);
            connection.update_row_in_table_v (table, "rowid", rowid_value, col_names, values);
        } catch (Error e) {
            critical ("Could not set field %s: %s", field, e.message);
        }
    }

    public static Gda.SqlBuilderId process_smart_query (Gda.SqlBuilder builder, SmartQuery sq) {
        Value value = Value (sq.value.type ());
        sq.value.copy (ref value);
        string field;
        switch (sq.field) {
            case SmartQuery.FieldType.ALBUM:
                field = "album";
                break;
            case SmartQuery.FieldType.ARTIST:
                field = "artist";
                break;
            case SmartQuery.FieldType.BITRATE:
                field = "bitrate";
                break;
            case SmartQuery.FieldType.COMMENT:
                field = "comment";
                break;
            case SmartQuery.FieldType.COMPOSER:
                field = "composer";
                break;
            case SmartQuery.FieldType.DATE_ADDED:
                // We need the current timestamp because this field is relative.
                value = Value (typeof (int));
                value.set_int ((int)time_t ());
                field = "dateadded";
                break;
            case SmartQuery.FieldType.GENRE:
                field = "genre";
                break;
            case SmartQuery.FieldType.GROUPING:
                field = "grouping";
                break;
            case SmartQuery.FieldType.LAST_PLAYED:
                // We need the current timestamp because this field is relative.
                value = Value (typeof (int));
                value.set_int ((int)time_t ());
                field = "lastplayed";
                break;
            case SmartQuery.FieldType.LENGTH:
                field = "length";
                break;
            case SmartQuery.FieldType.PLAYCOUNT:
                field = "playcount";
                break;
            case SmartQuery.FieldType.RATING:
                field = "rating";
                break;
            case SmartQuery.FieldType.SKIPCOUNT:
                field = "skipcount";
                break;
            case SmartQuery.FieldType.YEAR:
                field = "year";
                break;
            case SmartQuery.FieldType.TITLE:
            default:
                field = "title";
                break;
        }

        Gda.SqlOperatorType sql_operator_type;
        switch (sq.comparator) {
            case SmartQuery.ComparatorType.IS_NOT:
                sql_operator_type = Gda.SqlOperatorType.NOT;
                break;
            case SmartQuery.ComparatorType.CONTAINS:
            case SmartQuery.ComparatorType.NOT_CONTAINS:
                value = "%" + value.get_string () + "%";
                sql_operator_type = Gda.SqlOperatorType.LIKE;
                break;
            case SmartQuery.ComparatorType.IS_EXACTLY:
                sql_operator_type = Gda.SqlOperatorType.EQ;
                break;
            case SmartQuery.ComparatorType.IS_AT_MOST:
                sql_operator_type = Gda.SqlOperatorType.LEQ;
                break;
            case SmartQuery.ComparatorType.IS_AT_LEAST:
                sql_operator_type = Gda.SqlOperatorType.GEQ;
                break;
            case SmartQuery.ComparatorType.IS_WITHIN:
                sql_operator_type = Gda.SqlOperatorType.LEQ;
                break;
            case SmartQuery.ComparatorType.IS_BEFORE:
                sql_operator_type = Gda.SqlOperatorType.GEQ;
                break;
            case SmartQuery.ComparatorType.IS:
            default:
                sql_operator_type = Gda.SqlOperatorType.LIKE;
                break;
        }

        var id_field = builder.add_id (field);
        var id_value = builder.add_expr_value (null, value);
        if (sq.comparator == SmartQuery.ComparatorType.NOT_CONTAINS) {
            var cond = builder.add_cond (sql_operator_type, id_field, id_value, 0);;
            return builder.add_cond (Gda.SqlOperatorType.NOT, cond, 0, 0);
        } else {
            return builder.add_cond (sql_operator_type, id_field, id_value, 0);
        }
    }

    public static void create_tables (Gda.Connection connection) {
        Error e = null;

        /*
         * Creating the playlists table
         */
        var operation = Gda.ServerOperation.prepare_create_table (connection, "playlists", e,
                                                                      "name", typeof (string), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                      "media", typeof (string), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                      "rowid", typeof (int64), Gda.ServerOperationCreateTableFlag.PKEY_AUTOINC_FLAG);
        if (e != null) {
            critical (e.message);
        } else {
            try {
                operation.perform_create_table ();
            } catch (Error e) {
                // e.code == 1 is when the table already exists.
                if (e.code != 1) {
                    critical (e.message);
                }
            }
        }

        /*
         * Creating the smart_playlists table
         */
        operation = Gda.ServerOperation.prepare_create_table (connection, "smart_playlists", e,
                                                                      "name", typeof (string), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                      "and_or", typeof (int), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                      "queries", typeof (string), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                      "limited", typeof (int), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                      "limit_amount", typeof (int), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                      "rowid", typeof (int64), Gda.ServerOperationCreateTableFlag.PKEY_AUTOINC_FLAG);
        if (e != null) {
            critical (e.message);
        } else {
            try {
                operation.perform_create_table ();
            } catch (Error e) {
                // e.code == 1 is when the table already exists.
                if (e.code != 1) {
                    critical (e.message);
                }
            }
        }

        /*
         * Creating the columns table
         */
        operation = Gda.ServerOperation.prepare_create_table (connection, "columns", e,
                                                                      "unique_id", typeof (string), Gda.ServerOperationCreateTableFlag.UNIQUE_FLAG,
                                                                      "sort_column_id", typeof (int), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                      "sort_direction", typeof (int), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                      "columns", typeof (string), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                      "rowid", typeof (int64), Gda.ServerOperationCreateTableFlag.PKEY_AUTOINC_FLAG);
        if (e != null) {
            critical (e.message);
        } else {
            try {
                operation.perform_create_table ();
            } catch (Error e) {
                // e.code == 1 is when the table already exists.
                if (e.code != 1) {
                    critical (e.message);
                }
            }
        }

        /*
         * Creating the media table
         */
        operation = Gda.ServerOperation.prepare_create_table (connection, "media", e,
                                                                      "uri", typeof (string), Gda.ServerOperationCreateTableFlag.UNIQUE_FLAG,
                                                                      "file_size", typeof (int), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                      "title", typeof (string), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                      "artist", typeof (string), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                      "composer", typeof (string), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                      "album_artist", typeof (string), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                      "album", typeof (string), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                      "grouping", typeof (string), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                      "genre", typeof (string), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                      "comment", typeof (string), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                      "lyrics", typeof (string), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                      "has_embedded", typeof (int), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                      "year", typeof (int), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                      "track", typeof (int), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                      "track_count", typeof (int), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                      "album_number", typeof (int), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                      "album_count", typeof (int), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                      "bitrate", typeof (int), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                      "length", typeof (int), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                      "samplerate", typeof (int), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                      "rating", typeof (int), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                      "playcount", typeof (int), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                      "skipcount", typeof (int), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                      "dateadded", typeof (int), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                      "lastplayed", typeof (int), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                      "lastmodified", typeof (int), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                      "rowid", typeof (int64), Gda.ServerOperationCreateTableFlag.PKEY_AUTOINC_FLAG,
                                                                      "show", typeof (int), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG);
        if (e != null) {
            critical (e.message);
        } else {
            try {
                operation.perform_create_table ();
            } catch (Error e) {
                // e.code == 1 is when the table already exists.
                if (e.code != 1) {
                    critical (e.message);
                }
            }
        }

        /*
         * Creating the devices table
         */
        operation = Gda.ServerOperation.prepare_create_table (connection, "devices", e,
                                                                      "unique_id", typeof (string), Gda.ServerOperationCreateTableFlag.UNIQUE_FLAG,
                                                                      "sync_when_mounted", typeof (int), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                      "sync_music", typeof (int), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                      "sync_all_music", typeof (int), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                      "music_playlist", typeof (string), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG,
                                                                      "last_sync_time", typeof (int), Gda.ServerOperationCreateTableFlag.NOTHING_FLAG);
        if (e != null) {
            critical (e.message);
        } else {
            try {
                operation.perform_create_table ();
            } catch (Error e) {
                // e.code == 1 is when the table already exists.
                if (e.code != 1) {
                    critical (e.message);
                }
            }
        }
    }
}
