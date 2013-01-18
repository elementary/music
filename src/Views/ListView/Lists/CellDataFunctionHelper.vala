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

#if HAVE_SMART_ALBUM_COLUMN
    // We want ALL the views to follow this
    private static bool? _smart_album_art_enabled;
    public static bool smart_album_art_enabled {
        get {
            if (_smart_album_art_enabled == null)
                _smart_album_art_enabled = saved_state.show_album_art_in_list_view;

            return _smart_album_art_enabled;
        }
        set {
            _smart_album_art_enabled = value;
            saved_state.show_album_art_in_list_view = value;
        }
    }
#endif

    public CellDataFunctionHelper (GenericList view) {
        this.view = view;
    }

#if HAVE_SMART_ALBUM_COLUMN
    // for Smart album column
    public void album_art_func (Gtk.CellLayout cell_layout, Gtk.CellRenderer renderer, Gtk.TreeModel tree_model, Gtk.TreeIter iter) {
        int index = FastView.get_index_from_iter (iter);

        var m = view.get_media_from_index (index);
        if (m == null)
            return;

        var cell = renderer as SmartAlbumRenderer;
        return_if_fail (cell != null);

        cell.m = m;

        if (smart_album_art_enabled) {
            var cover_art = CoverartCache.instance.get_cover (m);
            if (cover_art != null) {
                int range, top, bottom, current = index;
                range = get_coverart_boundaries (view, m, current, out top, out bottom);

                // We have enough space to draw art
                if (can_display_art (range)) {
                    cell.icon = cover_art;
                    cell.top = top;
                    cell.bottom = bottom;
                    cell.current = current;
                    cell.xalign = 0.5f;

                    return;
                }
            }
        }

        cell.xalign = 0;
        cell.icon = null;
    }

    public bool row_separator_func (Gtk.TreeModel model, Gtk.TreeIter iter) {
        int range = 0, top = 0, bottom = 0, current = FastView.get_index_from_iter (iter);
        var m = view.get_media_from_index (current);

        if (m != null)
            range = get_coverart_boundaries (view, m, current, out top, out bottom);

        return smart_album_art_enabled && current == bottom && can_display_art (range);
    }

    private bool can_display_art (int range) {
        // We need 8 rows for the image, but also 2 extra rows for Album name and year.
        // Since displaying the year is not vital (there's a dedicated column for that),
        // we can be okay with 9 rows.
        // TODO: Measure average column height and decide a number based on that. If
        // Gtk.TreeView.fixed_height_mode is enabled, then this is trivial (we can get
        // the background area of a row in the the tree). Then compute how many rows we
        // need to display the entire image and cache the result.
        return range >= 9;
    }

    private int get_coverart_boundaries (GenericList view, Media current_media, int current_index,
                                         out int top, out int bottom) {
        for (top = current_index; top >= 0; --top) {
            var top_media = view.get_media_from_index (top);

            if (top_media == null || top_media.album != current_media.album) {
                ++top;
                break;
            }
            else if (top == 0) {
                break;
            }
        }

        for (bottom = current_index; bottom < view.get_visible_table().size(); ++bottom) {
            var bottom_media = view.get_media_from_index(bottom);
            if (bottom_media == null || bottom_media.album != current_media.album) {
                --bottom;
                break;
            }
        }

        //warning ("range is %d, top is %d, bottom is %d, current is %d\n", range, top, bottom, current);
        return bottom - top + 1;
    }
#endif

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
            image_renderer.gicon = icon as GLib.Icon;
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

