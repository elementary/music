// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012-2015 Noise Developers (https://launchpad.net/noise)
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
 * Authored by: Corentin Noël <corentin@elementary.io>
 */

public class Noise.LocalSmartPlaylist : SmartPlaylist {
    private static const string QUERY_SEPARATOR = "<query_sep>";
    private static const string VALUE_SEPARATOR = "<val_sep>";
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
        set {
            _name = value;
            Database.set_field (rowid, connection, Database.SmartPlaylists.TABLE_NAME, "name", Database.make_string_value (value));
        }
    }


    public override SmartPlaylist.ConditionalType conditional {
        get {
            return (SmartPlaylist.ConditionalType) Database.query_field (rowid, connection, Database.SmartPlaylists.TABLE_NAME, "and_or").get_int ();
        }
        set {
            Database.set_field (rowid, connection, Database.SmartPlaylists.TABLE_NAME, "and_or", Database.make_int_value (value));
        }
    }

    public override uint limit_amount {
        get {
            return (uint)Database.query_field (rowid, connection, Database.SmartPlaylists.TABLE_NAME, "limit_amount").get_int ();
        }
        set {
            Database.set_field (rowid, connection, Database.SmartPlaylists.TABLE_NAME, "limit_amount", Database.make_uint_value (value));
        }
    }

    public override bool limit {
        get {
            var val = Database.query_field (rowid, connection, Database.SmartPlaylists.TABLE_NAME, "limited");
            return (bool)val.get_int ();
        }
        set {
            Database.set_field (rowid, connection, Database.SmartPlaylists.TABLE_NAME, "limited", Database.make_bool_value (value));
        }
    }

    public LocalSmartPlaylist (int64 rowid, Gda.Connection connection) {
        base (libraries_manager.local_library);
        this.connection = connection;
        this.rowid = rowid;
        var queries_str = Database.query_field (rowid, connection, Database.SmartPlaylists.TABLE_NAME, "queries").get_string ();
        queries_from_string (queries_str);
    }

    //TODO: override this to search directly into the database.
    /*public override void analyse_all () {
        
    }*/

    public override void clear_queries () {
        base.clear_queries ();
        Database.set_field (rowid, connection, Database.SmartPlaylists.TABLE_NAME, "queries", Database.make_string_value (""));
    }

    public override void add_query (SmartQuery s) {
        base.add_query (s);
        Database.set_field (rowid, connection, Database.SmartPlaylists.TABLE_NAME, "queries", Database.make_string_value (queries_to_string ()));
    }

    public override void add_queries (Gee.Collection<SmartQuery> queries) {
        base.add_queries (queries);
        Database.set_field (rowid, connection, Database.SmartPlaylists.TABLE_NAME, "queries", Database.make_string_value (queries_to_string ()));
    }

    private string queries_to_string () {
        string rv = "";
        foreach (SmartQuery q in queries) {
            string query_str = ((int)q.field).to_string () + VALUE_SEPARATOR + ((int)q.comparator).to_string() + VALUE_SEPARATOR + q.value;
            if (rv == "") {
                rv = query_str;
            } else {
                rv += QUERY_SEPARATOR + query_str;
            }
        }

        return rv;
    }

    public void queries_from_string (string q) {
        string[] queries_in_string = q.split(QUERY_SEPARATOR, 0);
        foreach (var query_string in queries_in_string) {
            if (query_string == "")
                continue;

            string[] pieces_of_query = query_string.split (VALUE_SEPARATOR, 3);
            pieces_of_query.resize (3);

            SmartQuery sq = new SmartQuery();
            sq.field = (SmartQuery.FieldType)int.parse (pieces_of_query[0]);
            sq.comparator = (SmartQuery.ComparatorType)int.parse (pieces_of_query[1]);
            sq.value = pieces_of_query[2];

            queries.add (sq);
        }
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
            values.append (Database.make_string_value (_("Favorite Songs")));
            values.append (Database.make_string_value ("11<val_sep>2<val_sep>4<query_sep>13<val_sep>0<val_sep>0<query_sep>12<val_sep>6<val_sep>3"));
            values.append (Database.make_int_value (1));
            values.append (Database.make_int_value (1));
            values.append (Database.make_int_value (50));
            connection.insert_row_into_table_v (Database.SmartPlaylists.TABLE_NAME, col_names, values);

            values = new GLib.SList<GLib.Value?> ();
            values.append (Database.make_string_value (_("Recently Added")));
            values.append (Database.make_string_value ("5<val_sep>7<val_sep>7"));
            values.append (Database.make_int_value (1));
            values.append (Database.make_int_value (1));
            values.append (Database.make_int_value (50));
            connection.insert_row_into_table_v (Database.SmartPlaylists.TABLE_NAME, col_names, values);

            values = new GLib.SList<GLib.Value?> ();
            values.append (Database.make_string_value (_("Recent Favorites")));
            values.append (Database.make_string_value ("11<val_sep>2<val_sep>4<query_sep>13<val_sep>0<val_sep>0<query_sep>9<val_sep>7<val_sep>7"));
            values.append (Database.make_int_value (1));
            values.append (Database.make_int_value (1));
            values.append (Database.make_int_value (50));
            connection.insert_row_into_table_v (Database.SmartPlaylists.TABLE_NAME, col_names, values);

            values = new GLib.SList<GLib.Value?> ();
            values.append (Database.make_string_value (_("Never Played")));
            values.append (Database.make_string_value ("11<val_sep>0<val_sep>0"));
            values.append (Database.make_int_value (0));
            values.append (Database.make_int_value (1));
            values.append (Database.make_int_value (50));
            connection.insert_row_into_table_v (Database.SmartPlaylists.TABLE_NAME, col_names, values);

            values = new GLib.SList<GLib.Value?> ();
            values.append (Database.make_string_value (_("Over Played")));
            values.append (Database.make_string_value ("11<val_sep>4<val_sep>10"));
            values.append (Database.make_int_value (1));
            values.append (Database.make_int_value (1));
            values.append (Database.make_int_value (50));
            connection.insert_row_into_table_v (Database.SmartPlaylists.TABLE_NAME, col_names, values);

            values = new GLib.SList<GLib.Value?> ();
            values.append (Database.make_string_value (_("Not Recently Played")));
            values.append (Database.make_string_value ("9<val_sep>8<val_sep>7"));
            values.append (Database.make_int_value (1));
            values.append (Database.make_int_value (1));
            values.append (Database.make_int_value (50));
            connection.insert_row_into_table_v (Database.SmartPlaylists.TABLE_NAME, col_names, values);
        } catch (Error e) {
            critical ("Could not initialize smart playlists: %s", e.message);
        }
    }
}
