// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012 Noise Developers (http://launchpad.net/noise)
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
 * Authored by: Scott Ringwelski <sgringwe@mtu.edu>,
 *              Victor Eduardo <victoreduardm@gmail.com>
 */

public class Noise.TreeViewSetup : Object {

    private const string ASCENDING_STRING = "ASCENDING";
    private const string DESCENDING_STRING = "DESCENDING";
    private const string COLUMN_SEP_STRING = "<c_sep>";
    private const string VALUE_SEP_STRING = "<v_sep>";
    private const string TYPE_DATA_KEY = "setup-list-column-type";

    public int sort_column_id { get; set; default = 0; }
    public Gtk.SortType sort_direction { get; set; default = Gtk.SortType.ASCENDING; }

    private ViewWrapper.Hint hint;
    private Gee.LinkedList<Gtk.TreeViewColumn> columns = new Gee.LinkedList<Gtk.TreeViewColumn> ();

    public TreeViewSetup (int sort_col, Gtk.SortType sort_dir, ViewWrapper.Hint hint) {
        set_hint (hint);
        sort_column_id = sort_col;
        sort_direction = sort_dir;
    }

    public ViewWrapper.Hint get_hint () {
        return hint;
    }

    public void set_hint (ViewWrapper.Hint hint) {
        this.hint = hint;
    }

    public string sort_direction_to_string () {
        return sort_direction == Gtk.SortType.ASCENDING ? ASCENDING_STRING : DESCENDING_STRING;
    }

    public void set_sort_direction_from_string (string dir) {
        sort_direction = dir == ASCENDING_STRING ? Gtk.SortType.ASCENDING : Gtk.SortType.DESCENDING;
    }

    public List<Gtk.TreeViewColumn> get_columns () {
        if (columns.size < 1 || columns.size > ListColumn.N_COLUMNS) {
            message ("Creating a new TreeViewSetup for %s", get_hint ().to_string ());
            create_default_columns ();
        }

        var rv = new List<Gtk.TreeViewColumn> ();
        foreach (var tvc in columns)
            rv.append (tvc);

        return rv;
    }

    /**
     * Sets the list of columns that will be stored by the treeview setup.
     *
     * Each column must have been created using create_column(), or bad things
     * will happen. E.g. columns_to_string() will not work.
     */
    public void set_columns (List<Gtk.TreeViewColumn> cols) {
        columns.clear ();
        foreach (var tvc in cols)
            columns.add (tvc);
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
    public bool import_columns (string cols) {
        string[] col_strings = cols.split (COLUMN_SEP_STRING, 0);
        var new_columns = new List<Gtk.TreeViewColumn> ();

        // the '-1' because col_strings has blank column at end
        for (int index = 0; index < col_strings.length - 1; ++index) {
            string[] pieces_of_column = col_strings[index].split (VALUE_SEP_STRING, 0);

            var type = (ListColumn) int.parse (pieces_of_column[0]);

            int visible_val = int.parse (pieces_of_column[1]);
            if (visible_val != 1 && visible_val != 0)
                return false;

            new_columns.append (create_column (type, visible_val == 1));
        }

        set_columns (new_columns);
        return true;
    }

    public string columns_to_string () {
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
    public Gtk.TreeViewColumn create_column (ListColumn type, bool visible = true) {
        var column = new Gtk.TreeViewColumn ();
        set_column_type (column, type);
        column.title = type.to_string ();
        column.visible = visible;
        return column;
    }

    public static ListColumn get_column_type (Gtk.TreeViewColumn column) {
        int type = column.get_data<int> (TYPE_DATA_KEY);

        if (type < 0) {
            critical ("get_column_type: Column '%s' has no associated type.", column.title); 
            return_if_reached ();
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
                columns.add (create_column (ListColumn.ICON));
                columns.add (create_column (ListColumn.TITLE));
                columns.add (create_column (ListColumn.LENGTH));
            break;

            case ViewWrapper.Hint.CDROM:
                columns.add (create_column (ListColumn.ICON));
                columns.add (create_column (ListColumn.NUMBER, false));
                columns.add (create_column (ListColumn.TRACK));
                columns.add (create_column (ListColumn.TITLE));
                columns.add (create_column (ListColumn.LENGTH));
                columns.add (create_column (ListColumn.ARTIST));
                columns.add (create_column (ListColumn.ALBUM));
                columns.add (create_column (ListColumn.GENRE));
            break;

            default:
                columns.add (create_column (ListColumn.ICON));

                bool num_column_visible = hint == ViewWrapper.Hint.QUEUE
                                       || hint == ViewWrapper.Hint.HISTORY
                                       || hint == ViewWrapper.Hint.PLAYLIST;

                columns.add (create_column (ListColumn.NUMBER, num_column_visible));
                columns.add (create_column (ListColumn.TRACK, false));
                columns.add (create_column (ListColumn.TITLE));
                columns.add (create_column (ListColumn.LENGTH));
                columns.add (create_column (ListColumn.ARTIST));
                columns.add (create_column (ListColumn.ALBUM));
                columns.add (create_column (ListColumn.GENRE));
                columns.add (create_column (ListColumn.YEAR, false));
                columns.add (create_column (ListColumn.BITRATE, false));
                columns.add (create_column (ListColumn.RATING, false));
                columns.add (create_column (ListColumn.PLAY_COUNT, false));
                columns.add (create_column (ListColumn.SKIP_COUNT, false));
                columns.add (create_column (ListColumn.DATE_ADDED, false));
                columns.add (create_column (ListColumn.LAST_PLAYED, false));
                columns.add (create_column (ListColumn.BPM, false));
            break;
        }
    }
}

