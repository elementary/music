// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012-2018 elementary LLC. (https://elementary.io)
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
 * Authored by: Scott Ringwelski <sgringwe@mtu.edu>,
 *              Victor Eduardo <victoreduardm@gmail.com>
 */

public class Noise.TreeViewSetup : Object {
    private const string ASCENDING_STRING = "ASCENDING";
    private const string DESCENDING_STRING = "DESCENDING";
    private const string COLUMN_SEP_STRING = "<c_sep>";
    private const string VALUE_SEP_STRING = "<v_sep>";
    private const string TYPE_DATA_KEY = "setup-list-column-type";

    public ListColumn sort_column_id { get; set; default = ListColumn.ARTIST; }
    public Gtk.SortType sort_direction { get; set; default = Gtk.SortType.ASCENDING; }
    public ViewWrapper.Hint hint { get; set; }
    public Gda.Connection? connection { get; construct; default = null; }
    public string? uid { get; construct; default = null; }

    private Gee.LinkedList<Gtk.TreeViewColumn> columns = new Gee.LinkedList<Gtk.TreeViewColumn> ();

    public TreeViewSetup (ViewWrapper.Hint hint, string? uid = null, Gda.Connection? connection = null) {
        Object (
            connection: connection,
            hint: hint,
            uid: uid
        );
    }

    construct {
        switch (hint) {
            case ViewWrapper.Hint.PLAYLIST:
            case ViewWrapper.Hint.READ_ONLY_PLAYLIST:
            case ViewWrapper.Hint.SMART_PLAYLIST:
                sort_column_id = ListColumn.NUMBER;
                break;
        }

        if (uid != null) {
            if (exists () == false) {
                try {
                    var builder = new Gda.SqlBuilder (Gda.SqlStatementType.INSERT);
                    builder.set_table (Database.Columns.TABLE_NAME);
                    builder.add_field_value_as_gvalue ("unique_id", uid);
                    connection.statement_execute_non_select (builder.get_statement (), null, null);
                } catch (Error e) {
                    warning ("Could not save treeviewsetup: %s", e.message);
                }
            } else {
                var direction = query_field ("sort_direction");
                if (direction != null && direction.type () != typeof (Gda.Null)) {
                    sort_direction = (Gtk.SortType) direction.get_int ();
                }

                var direction_column = query_field ("sort_column_id");
                if (direction_column != null && direction_column.type () != typeof (Gda.Null)) {
                    sort_column_id = (ListColumn) direction_column.get_int ();
                }

                var columns_var = query_field ("columns");
                if (columns_var != null && columns_var.type () != typeof (Gda.Null)) {
                    import_columns (columns_var.get_string ());
                }
            }

            notify["sort-direction"].connect (() => {
                set_field ("sort_direction", (int) sort_direction);
            });

            notify["sort-column-id"].connect (() => {
                set_field ("sort_column_id", (int) sort_column_id);
            });
        }
    }

    public Gee.Collection<Gtk.TreeViewColumn> get_columns () {
        if (columns.size < 1 || columns.size != ListColumn.N_COLUMNS) {
            debug ("Creating a new TreeViewSetup for %s", hint.to_string ());
            create_default_columns ();
        }

        return columns.read_only_view;
    }

    /**
     * Sets the list of columns that will be stored by the treeview setup.
     *
     * Each column must have been created using create_column(), or bad things
     * will happen. E.g. columns_to_string() will not work.
     */
    private void set_columns (Gee.Collection<Gtk.TreeViewColumn> cols) {
        columns.clear ();
        columns.add_all (cols);
    }

    /**
     * Transforms the string representation of the columns into a real list of
     * treeview columns. This overwrites the previous list of columns.
     *
     * It the string cannot be parsed, //false// is returned and the previous
     * list of columns remains unmodified.
     *
     * @param cols string representation of columns created by columns_to_string().
     * @return Whether the string was succesfully parsed and imported.
     */
    private bool import_columns (string cols) {
        string[] col_strings = cols.split (COLUMN_SEP_STRING, 0);
        var new_columns = new Gee.TreeSet<Gtk.TreeViewColumn> (column_compare_func);

        // the '-1' because col_strings has blank column at end
        for (int index = 0; index < col_strings.length - 1; ++index) {
            string[] pieces_of_column = col_strings[index].split (VALUE_SEP_STRING, 0);

            var type = (ListColumn) int.parse (pieces_of_column[0]);

            int visible_val = int.parse (pieces_of_column[1]);
            if (visible_val != 1 && visible_val != 0)
                return false;

            new_columns.add (create_column (type, visible_val == 1));
        }

        set_columns (new_columns);
        return true;
    }

    private string columns_to_string () {
        var columns_string = new StringBuilder ();

        var columns = get_columns ();
        foreach (var tvc in columns) {
            // Retrieve column type:
            // Please note that we store the value as an integer and not as a ListColumn
            // because we only want to_string() to return a number and not the entire string
            // representation that ListColumn.to_string() returns. This is needed in order
            // to make TreeViewSetup database representations valid even if the users swich
            // their default language. If we stored what ListColumn.to_string() returns,
            // there would be no way to tell whether a column's title needs to be updated
            // to the new locale or not.
            int type = get_column_type (tvc);
            columns_string.append (type.to_string ());
            columns_string.append (VALUE_SEP_STRING);
            columns_string.append (tvc.visible ? "1" : "0");
            columns_string.append (COLUMN_SEP_STRING);
        }

        return columns_string.str;
    }

    /**
     * Creates a new treeview column for use in the views and treeview setups.
     *
     * Every column that goes into a list *must* be created by this method. Otherwise,
     * columns_to_string() won't work and bad things could happen.
     */
    private Gtk.TreeViewColumn create_column (ListColumn type, bool visible = true) {
        var column = new Gtk.TreeViewColumn ();
        set_column_type (column, type);
        column.title = type.to_string ();
        column.visible = visible;

        if (type == sort_column_id) {
            column.set_sort_order (sort_direction);
        }

        column.notify["visible"].connect (() => {
            set_field ("columns", columns_to_string ());
        });

        column.clicked.connect (() => {
            sort_direction = column.get_sort_order ();
            sort_column_id = get_column_type (column);
        });
        return column;
    }

    public static ListColumn? get_column_type (Gtk.TreeViewColumn column) {
        int type = column.get_data<int> (TYPE_DATA_KEY);

        if (type < 0) {
            critical ("get_column_type: Column '%s' has no associated type.", column.title);
            return_val_if_reached (null);
        }

        return (ListColumn) type;
    }

    private static void set_column_type (Gtk.TreeViewColumn column, ListColumn type) {
        // Associate column type to the object
        column.set_data<int> (TYPE_DATA_KEY, type);
    }

    private void create_default_columns () {
        columns.clear ();

        // Initial column state, as added during the first-run / database-reset.
        // Columns are ordered.
        switch (hint) {
            case ViewWrapper.Hint.ALBUM_LIST: // same as normal music list, but most are hidden
                append_new_column (ListColumn.ICON);
                append_new_column (ListColumn.TITLE);
                append_new_column (ListColumn.LENGTH);
            break;

            case ViewWrapper.Hint.CDROM:
                append_new_column (ListColumn.ICON);
                append_new_column (ListColumn.NUMBER, false);
                append_new_column (ListColumn.TRACK);
                append_new_column (ListColumn.TITLE);
                append_new_column (ListColumn.LENGTH);
                append_new_column (ListColumn.ARTIST, false);
                append_new_column (ListColumn.ALBUM, false);
                append_new_column (ListColumn.GENRE, false);
            break;

            default:
                append_new_column (ListColumn.ICON);

                bool num_column_visible = hint == ViewWrapper.Hint.READ_ONLY_PLAYLIST
                                       || hint == ViewWrapper.Hint.PLAYLIST;

                append_new_column (ListColumn.NUMBER, num_column_visible);
                append_new_column (ListColumn.TRACK, false);
                append_new_column (ListColumn.TITLE);
                append_new_column (ListColumn.LENGTH);
                append_new_column (ListColumn.ARTIST);
                append_new_column (ListColumn.ALBUM);
                append_new_column (ListColumn.ALBUM_ARTIST, false);
                append_new_column (ListColumn.COMPOSER, false);
                append_new_column (ListColumn.GENRE);
                append_new_column (ListColumn.YEAR, false);
                append_new_column (ListColumn.GROUPING, false);
                append_new_column (ListColumn.BITRATE, false);
                append_new_column (ListColumn.RATING, false);
                append_new_column (ListColumn.PLAY_COUNT, false);
                append_new_column (ListColumn.SKIP_COUNT, false);
                append_new_column (ListColumn.DATE_ADDED, false);
                append_new_column (ListColumn.LAST_PLAYED, false);
                append_new_column (ListColumn.BPM, false);
                append_new_column (ListColumn.FILE_LOCATION, false);
                append_new_column (ListColumn.FILE_SIZE, false);
            break;
        }
    }

    private void append_new_column (ListColumn column, bool initially_visible = true) {
        columns.add (create_column (column, initially_visible));
    }

    private int column_compare_func (Gtk.TreeViewColumn column_a, Gtk.TreeViewColumn column_b) {
        int a = (int) get_column_type (column_a);
        int b = (int) get_column_type (column_b);

        // return negative value if a<b;zero if a=b;positive value if a>b
        return (int) (a > b) - (int) (a < b);
    }

    /*
     * Database management
     */

    private bool exists () {
        try {
            var sql = new Gda.SqlBuilder (Gda.SqlStatementType.SELECT);
            sql.select_add_target (Database.Columns.TABLE_NAME, null);
            sql.add_field_value_id (sql.add_id ("*"), 0);
            var id_field = sql.add_id ("unique_id");
            var id_param = sql.add_expr_value (null, uid);
            var id_cond = sql.add_cond (Gda.SqlOperatorType.EQ, id_field, id_param, 0);
            sql.set_where (id_cond);
            var data_model = connection.statement_execute_select (sql.get_statement (), null);
            if (data_model.get_value_at (data_model.get_column_index ("unique_id"), 0) == null) {
                return false;
            }

            return true;
        } catch (Error e) {
            debug ("Column %lld doesn't exist, a new one will be created", uid);
            return false;
        }
    }

    private GLib.Value? query_field (string field) {
        try {
            var sql = new Gda.SqlBuilder (Gda.SqlStatementType.SELECT);
            sql.select_add_target (Database.Columns.TABLE_NAME, null);
            sql.add_field_value_id (sql.add_id (field), 0);
            var id_field = sql.add_id ("unique_id");
            var id_param = sql.add_expr_value (null, uid);
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
            connection.update_row_in_table_v (Database.Columns.TABLE_NAME, "unique_id", uid, col_names, values);
        } catch (Error e) {
            critical ("Could not set field %s: %s", field, e.message);
        }
    }
}
