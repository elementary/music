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

public class Noise.LocalStaticPlaylist : StaticPlaylist {
    private Gda.Connection connection;

    /**
     * Metadata Fields
     */
    private string _name = null;
    public override string name {
        get {
            try {
                if (_name != null)
                    return _name;

                var sql = new Gda.SqlBuilder (Gda.SqlStatementType.SELECT);
                sql.select_add_target (Database.Playlists.TABLE_NAME, null);
                sql.add_field_value_id (sql.add_id ("name"), 0);
                var id_field = sql.add_id ("rowid");
                var id_param = sql.add_expr_value (null, Database.make_int64_value (rowid));
                var id_cond = sql.add_cond (Gda.SqlOperatorType.EQ, id_field, id_param, 0);
                sql.set_where (id_cond);
                var data_model = connection.statement_execute_select (sql.get_statement (), null);
                _name = data_model.get_value_at (data_model.get_column_index ("name"), 0).dup_string ();
                return _name;
            } catch (Error e) {
                critical ("Could not query field name: %s", e.message);
                return "";
            }
        }
        set {
            try {
                var rowid_value = GLib.Value (typeof (int64));
                rowid_value.set_int64 (rowid);
                var col_names = new GLib.SList<string> ();
                col_names.append ("name");
                var values = new GLib.SList<GLib.Value?> ();
                values.append (Database.make_string_value (value));
                connection.update_row_in_table_v (Database.Playlists.TABLE_NAME, "rowid", rowid_value, col_names, values);
                _name = value;
            } catch (Error e) {
                critical ("Could not set field name: %s", e.message);
            }
        }
    }

    public LocalStaticPlaylist (int64 rowid, Gda.Connection connection) {
        this.rowid = rowid;
        this.connection = connection;
        var sql = new Gda.SqlBuilder (Gda.SqlStatementType.SELECT);
        sql.select_add_target (Database.Playlists.TABLE_NAME, null);
        sql.add_field_value_id (sql.add_id ("media"), 0);
        var id_field = sql.add_id ("rowid");
        var id_param = sql.add_expr_value (null, Database.make_int64_value (rowid));
        var id_cond = sql.add_cond (Gda.SqlOperatorType.EQ, id_field, id_param, 0);
        sql.set_where (id_cond);
        try {
            var data_model = connection.statement_execute_select (sql.get_statement (), null);
            var all = data_model.get_value_at (data_model.get_column_index ("media"), 0).dup_string ();
            foreach (var id in all.split (";")) {
                medias.add (libraries_manager.local_library.media_from_id (int64.parse (id)));
            }
        } catch (Error e) {
            critical (e.message);
        }
    }

    construct {
        updated.connect ((old_name) => {
            update_database ();
        });
    }

    private void update_database () {
        var rowid_value = GLib.Value (typeof (int64));
        rowid_value.set_int64 (rowid);
        var col_names = new GLib.SList<string> ();
        col_names.append ("name");
        col_names.append ("media");
        var values = new GLib.SList<Value ?> ();
        string rv = "";
        foreach (var m in medias) {
            if (rv == "") {
                rv = "%lld".printf (m.rowid);
            } else {
                rv += ";%lld".printf (m.rowid);
            }
        }

        values.append (Database.make_string_value (name));
        values.append (Database.make_string_value (rv));
        try {
            connection.update_row_in_table_v (Database.Playlists.TABLE_NAME, "rowid", rowid_value, col_names, values);
        } catch (Error e) {
            critical (e.message);
        }
    }
}
