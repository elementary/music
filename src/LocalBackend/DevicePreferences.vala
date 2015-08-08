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
 * Authored by: Scott Ringwelski <sgringwe@mtu.edu>
 *              Corentin Noël <corentin@elementary.io>
 */

public class Noise.DevicePreferences : GLib.Object {
    private string id;

    public bool? _sync_when_mounted = null;
    public bool sync_when_mounted {
        get {
            common_bool_getter ("sync_when_mounted", ref _sync_when_mounted);
            return _sync_when_mounted;
        }
        set {
            common_bool_setter ("sync_when_mounted", value, ref _sync_when_mounted);
        }
    }

    public uint? _last_sync_time = null;
    public uint last_sync_time {
        get {
            common_uint_getter ("last_sync_time", ref _last_sync_time);
            return _last_sync_time;
        }
        set {
            common_uint_setter ("last_sync_time", value, ref _last_sync_time);
        }
    }

    public bool? _sync_music = null;
    public bool sync_music {
        get {
            common_bool_getter ("sync_music", ref _sync_music);
            return _sync_music;
        }
        set {
            common_bool_setter ("sync_music", value, ref _sync_music);
        }
    }

    public bool? _sync_all_music = null;
    public bool sync_all_music {
        get {
            common_bool_getter ("sync_all_music", ref _sync_all_music);
            return _sync_all_music;
        }
        set {
            common_bool_setter ("sync_all_music", value, ref _sync_all_music);
        }
    }

    public Playlist? music_playlist {
        owned get {
            var result = query_field ("music_playlist");
            if (result.type () == typeof (Gda.Null)) {
                return null;
            }

            string playlist_string = result.get_string ();
            if (playlist_string == "" || playlist_string == null)
                return null;
            if ("p" in playlist_string) {
                playlist_string = playlist_string.replace ("p", "");
                return Noise.libraries_manager.local_library.playlist_from_id (int64.parse (playlist_string));
            } else {
                playlist_string = playlist_string.replace ("s", "");
                return Noise.libraries_manager.local_library.smart_playlist_from_id (int64.parse (playlist_string));
            }
        }
        set {
            string playlist_string = "";
            if (value != null) {
                if (value is StaticPlaylist) {
                    playlist_string = "p%lld".printf (value.rowid);
                } else {
                    playlist_string = "s%lld".printf (value.rowid);
                }
            }

            set_field ("music_playlist", Database.make_string_value (playlist_string));
        }
    }

    private Gda.Connection connection;

    public DevicePreferences (Noise.Device device, Gda.Connection connection) {
        this.id = device.get_unique_identifier ();
        this.connection = connection;
        if (query_field ("sync_music") == null) {
            try {
                var builder = new Gda.SqlBuilder (Gda.SqlStatementType.INSERT);
                builder.set_table (Database.Devices.TABLE_NAME);
                builder.add_field_value_as_gvalue ("unique_id", Database.make_string_value (id));
                connection.statement_execute_non_select (builder.get_statement (), null, null);
            } catch (Error e) {
                warning ("Could not save media: %s", e.message);
            }
        }
    }

    private uint common_uint_getter (string field, ref uint? temp) {
        if (temp != null)
            return temp;

        var result = query_field (field);
        if (result.type () == typeof (Gda.Null)) {
            temp = 0;
            return temp;
        }

        temp = (uint)result.get_int ();
        return temp;
    }

    private void common_uint_setter (string field, uint value, ref uint? temp) {
        temp = value;
        set_field (field, Database.make_uint_value (value));
    }

    private bool common_bool_getter (string field, ref bool? temp) {
        if (temp != null)
            return temp;

        var result = query_field (field);
        if (result.type () == typeof (Gda.Null)) {
            temp = false;
            return temp;
        }

        temp = result.get_int () == 1;
        return temp;
    }

    private void common_bool_setter (string field, bool value, ref bool? temp) {
        temp = value;
        set_field (field, Database.make_bool_value (value));
    }

    private GLib.Value? query_field (string field) {
        try {
            var sql = new Gda.SqlBuilder (Gda.SqlStatementType.SELECT);
            sql.select_add_target (Database.Devices.TABLE_NAME, null);
            sql.add_field_value_id (sql.add_id (field), 0);
            var id_field = sql.add_id ("unique_id");
            var id_param = sql.add_expr_value (null, Database.make_string_value (id));
            var id_cond = sql.add_cond (Gda.SqlOperatorType.EQ, id_field, id_param, 0);
            sql.set_where (id_cond);
            var data_model = connection.statement_execute_select (sql.get_statement (), null);
            return data_model.get_value_at (data_model.get_column_index (field), 0);
        } catch (Error e) {
            critical ("Could not query field %s: %s", field, e.message);
            return null;
        }
    }

    private void set_field (string field, GLib.Value value) {
        try {
            var col_names = new GLib.SList<string> ();
            col_names.append (field);
            var values = new GLib.SList<GLib.Value?> ();
            values.append (value);
            connection.update_row_in_table_v (Database.Devices.TABLE_NAME, "unique_id", Database.make_string_value (id), col_names, values);
        } catch (Error e) {
            critical ("Could not set field %s: %s", field, e.message);
        }
    }
}
