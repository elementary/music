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

    public LocalSmartPlaylist (Gda.Connection connection) {
        this.connection = connection;
        base (libraries_manager.local_library);
    }

    construct {
        media_added.connect ((media) => {
            update_database ();
        });

        media_removed.connect ((media) => {
            update_database ();
        });

        updated.connect ((old_name) => {
            update_database ();
        });

        cleared.connect (() => {
            update_database ();
        });
    }

    private void update_database () {
        var rowid_value = GLib.Value (typeof (int64));
        rowid_value.set_int64 (rowid);
        var col_names = new GLib.SList<string> ();
        col_names.append ("name");
        col_names.append ("and_or");
        col_names.append ("queries");
        col_names.append ("limited");
        col_names.append ("limit_amount");

        var values = new GLib.SList<Value ?> ();
        values.append (Database.make_string_value (name));
        values.append (Database.make_int_value ((int)conditional));
        values.append (Database.make_string_value (queries_to_string ()));
        values.append (Database.make_bool_value (limit));
        values.append (Database.make_int_value (limit_amount));
        try {
            connection.update_row_in_table_v ("playlists", "rowid", rowid_value, col_names, values);
        } catch (Error e) {
            critical (e.message);
        }
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
}
