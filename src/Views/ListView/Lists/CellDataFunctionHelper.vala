// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012 Noise Developers (http://launchpad.net/noise)
 *
 * This software is licensed under the GNU General Public License
 * (version 2 or later). See the COPYING file in this distribution.
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

using Gtk;

public class Noise.CellDataFunctionHelper {
    private const string NOT_AVAILABLE = ""; //("N/A");

    private GenericList view;

    public CellDataFunctionHelper (GenericList view) {
        this.view = view;
    }

    /**
     * For unique icon on each row
     */
    public void icon_func (Gtk.CellLayout layout, Gtk.CellRenderer renderer, Gtk.TreeModel model, Gtk.TreeIter iter) {
        var m = view.get_object_from_index (FastView.get_index_from_iter (iter)) as Media;
        if (m == null)
            return;

        renderer.visible = !m.showIndicator;

        var image_renderer = renderer as Gtk.CellRendererPixbuf;
        return_if_fail (image_renderer != null);

        if (renderer.visible) {
            Value icon;
            model.get_value (iter, ListColumn.ICON, out icon); // ICON column is same for all
            image_renderer.gicon = icon.get_object () as GLib.Icon;
        }
    }

    public void spinner_func (Gtk.CellLayout layout, Gtk.CellRenderer renderer, Gtk.TreeModel model, Gtk.TreeIter iter) {
        var m = view.get_object_from_index (FastView.get_index_from_iter (iter)) as Media;
        if (m == null)
            return;

        renderer.visible = m.showIndicator;

        var spinner_renderer = renderer as Gtk.CellRendererSpinner;
        return_if_fail (spinner_renderer != null);

        spinner_renderer.active = true;
        spinner_renderer.pulse++;
    }

    public static inline void file_size_func (Gtk.CellLayout layout, CellRenderer cell, TreeModel tree_model, TreeIter iter) {
        Value val;
        tree_model.get_value (iter, ListColumn.FILE_SIZE, out val);
        uint64 n = val.get_uint64 ();
        (cell as Gtk.CellRendererText).text = n > 0 ? format_size (n) : NOT_AVAILABLE;
    }

    public static inline string get_file_size_sample () {
        return format_size (1024 * 1024 * 932); // 932 MB. We want a long string
    }

    // For numbers. Needed because the column is not sortable and intelligent_func
    // requires the column to be sortable to work properly.
    public static inline void number_func (Gtk.CellLayout layout, CellRenderer cell, TreeModel tree_model, TreeIter iter) {
        set_renderer_number (cell as Gtk.CellRendererText, iter, tree_model, ListColumn.NUMBER);
    }

    // for Track, Year, Plays, Skips. Simply shows nothing if less than 1.
    public static inline void intelligent_func (Gtk.CellLayout layout, CellRenderer cell, TreeModel tree_model, TreeIter iter) {
        var tvc = layout as Gtk.TreeViewColumn;
        return_if_fail (tvc != null);

        // All the other columns have a fixed row number, but we need to check in the case
        // of this method because it is used by many different columns.
        int column = tvc.sort_column_id;
        if (column < 0)
            return;

        set_renderer_number (cell as Gtk.CellRendererText, iter, tree_model, column);
    }

    private static inline void set_renderer_number (Gtk.CellRendererText renderer, Gtk.TreeIter iter, Gtk.TreeModel model, int column) {
        Value val;
        model.get_value (iter, column, out val);
        uint n = val.get_uint ();
        renderer.text = n > 0 ? n.to_string () : "";
    }

    public static inline void string_func (Gtk.CellLayout layout, CellRenderer cell, TreeModel tree_model, TreeIter iter) {
        var tvc = layout as Gtk.TreeViewColumn;
        return_if_fail (tvc != null);

        // All the other columns have a fixed row number, but we need to check in the case
        // of this method because it is used by many different columns.
        int column = tvc.sort_column_id;
        if (column < 0)
            return;

        Value val;
        tree_model.get_value (iter, column, out val);
        (cell as CellRendererText).text = val.get_string ();
    }

    // for Bitrate. Append 'kbps'
    public static inline void bitrate_func (Gtk.CellLayout layout, CellRenderer cell, TreeModel tree_model, TreeIter iter) {
        Value val;
        tree_model.get_value(iter, ListColumn.BITRATE, out val);
        var text_cell = cell as CellRendererText;
        uint n = val.get_uint ();
        text_cell.text = n <= 0 ? NOT_AVAILABLE : _("%i kbps").printf (n);
    }

    // turns int of seconds into pretty length mm:ss format
    public static inline void length_func (Gtk.CellLayout layout, CellRenderer cell, TreeModel tree_model, TreeIter iter) {
        Value val;
        tree_model.get_value(iter, ListColumn.LENGTH, out val);
        uint ms = val.get_uint ();
        var text_cell = cell as CellRendererText;
        text_cell.text = (ms <= 0) ? NOT_AVAILABLE : TimeUtils.pretty_length_from_ms (ms);
    }

    public static inline string get_date_func_sample_string () {
        return get_date_string (1324512000);
    }

    // turns seconds since Jan 1, 1970 into date format
    public static inline void date_func (Gtk.CellLayout layout, CellRenderer cell, TreeModel tree_model, TreeIter iter) {
        Value val;
        tree_model.get_value(iter, ListColumn.DATE_ADDED, out val);
        var text_cell = cell as CellRendererText;
        text_cell.text = get_date_string (val.get_uint ());
    }

    private static inline string get_date_string (uint n) {
        return n == 0 ? _("Never") : TimeUtils.pretty_timestamp_from_time (Time.local (n));
    }

    public static inline void rating_func (Gtk.CellLayout layout, CellRenderer cell, TreeModel tree_model, TreeIter iter) {
        Value val;
        tree_model.get_value(iter, ListColumn.RATING, out val);
        var rating_cell = cell as Granite.Widgets.CellRendererRating;
        rating_cell.rating = val.get_uint ();
    }
}

