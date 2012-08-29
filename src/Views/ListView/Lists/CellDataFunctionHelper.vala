/*-
 * Copyright (c) 2011-2012       Scott Ringwelski <sgringwe@mtu.edu>
 *
 * Originally Written by Scott Ringwelski for BeatBox Music Player
 * BeatBox Music Player: http://www.launchpad.net/beat-box
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
 */

using Gtk;
using Gdk;

public class Noise.CellDataFunctionHelper {
    public Noise.GenericList view;
    private static string NOT_AVAILABLE = _("N/A");

#if HAVE_SMART_ALBUM_COLUMN
    // We want ALL the views to follow this
    private static bool? _smart_album_art_enabled;
    public static bool smart_album_art_enabled {
        get {
            if (_smart_album_art_enabled == null)
                _smart_album_art_enabled = Settings.SavedState.instance.show_album_art_in_list_view;

            return _smart_album_art_enabled;
        }
        set {
            _smart_album_art_enabled = value;
            Settings.SavedState.instance.show_album_art_in_list_view = value;
        }
    }
#endif

    public CellDataFunctionHelper (GenericList view) {
        this.view = view;
    }

#if HAVE_SMART_ALBUM_COLUMN
    // for Smart album column
    public void album_art_func (Gtk.TreeViewColumn tvc, Gtk.CellRenderer renderer,
                                Gtk.TreeModel tree_model, Gtk.TreeIter iter) {
        int index = view.get_index_from_iter (iter);

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
        int range = 0, top = 0, bottom = 0, current = view.get_index_from_iter (iter);
        var m = view.get_media_from_index (current);

        if (m != null)
            range = get_coverart_boundaries (view, m, current, out top, out bottom);

        return smart_album_art_enabled && current == bottom && can_display_art (range);
    }

    private bool can_display_art (int range) {
        // We need 8 rows for the image, but also 2 extra rows for Album name and year.
        // Since displaying the year is not vital (there's a dedicated column for that),
        // we can be okay with 9 rows
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

    /** For spinner/unique icon on each row **/
    public void icon_func (CellLayout layout, CellRenderer renderer, TreeModel model, TreeIter iter) {
        var tvc = layout as Gtk.TreeViewColumn;

        return_if_fail (tvc != null);

        bool showIndicator = false;
        var s = view.get_object_from_index(view.get_index_from_iter (iter)) as Media;

        if (s == null)
            return;
        else
            showIndicator = s.showIndicator;

        if (renderer is CellRendererPixbuf) {
            Value? icon;
            model.get_value (iter, MusicListView.MusicColumn.ICON, out icon); // ICON column is same for all

            var pix_renderer = renderer as CellRendererPixbuf;
            pix_renderer.follow_state = true;
            pix_renderer.gicon = (icon as GLib.Icon);

            renderer.visible = !showIndicator;
            renderer.width = showIndicator ? 0 : 16;
        }
        if (renderer is CellRendererSpinner) {
            if (showIndicator) {
                ((CellRendererSpinner)renderer).active = true;
            }

            renderer.visible = showIndicator;
            renderer.width = showIndicator ? 16 : 0;
        }
    }

    // for Track, Year, #, Plays, Skips. Simply shows nothing if less than 1.
    public void intelligent_func (TreeViewColumn tvc, CellRenderer cell, TreeModel tree_model, TreeIter iter) {
        Value val;
        tree_model.get_value(iter, tvc.sort_column_id, out val);

        if (val.get_int() <= 0)
            ((CellRendererText)cell).markup = "";
        else
            ((CellRendererText)cell).markup = String.escape (val.get_int().to_string());
    }

    public void string_func (TreeViewColumn tvc, CellRenderer cell, TreeModel tree_model, TreeIter iter) {
        Value val;
        tree_model.get_value(iter, tvc.sort_column_id, out val);

        var str = val.get_string ();

        if (str == null)
            return;

        ((CellRendererText)cell).markup = String.escape (str);
    }

    // for Bitrate. Append 'kbps'
    public void bitrate_func (TreeViewColumn tvc, CellRenderer cell, TreeModel tree_model, TreeIter iter) {
        Value val;
        tree_model.get_value(iter, tvc.sort_column_id, out val);

        var n = val.get_int ();
        var text_cell = cell as CellRendererText;

        if (n <= 0)
            text_cell.markup = NOT_AVAILABLE;
        else
            text_cell.markup = _("%i kbps").printf (n);
    }

    // turns int of seconds into pretty length mm:ss format
    public void length_func (TreeViewColumn tvc, CellRenderer cell, TreeModel tree_model, TreeIter iter) {
        Value val;
        tree_model.get_value(iter, tvc.sort_column_id, out val);

        var text_cell = cell as CellRendererText;

        uint ms = (uint)val.get_int ();

        if (ms <= 0)
            text_cell.markup = NOT_AVAILABLE;
        else
            text_cell.markup = String.escape (TimeUtils.pretty_length_from_ms (ms));
    }

    // turns seconds since Jan 1, 1970 into date format
    public void date_func (TreeViewColumn tvc, CellRenderer cell, TreeModel tree_model, TreeIter iter) {
        Value val;
        tree_model.get_value(iter, tvc.sort_column_id, out val);

        int n = val.get_int ();
        var text_cell = cell as CellRendererText;

        if (n <= 0)
            text_cell.markup = _("Never");
        else {
            var t = Time.local (n);
            var str = TimeUtils.pretty_timestamp_from_time (t);
            text_cell.markup = String.escape (str);
        }
    }

    public void rating_func (TreeViewColumn tvc, CellRenderer cell, TreeModel tree_model, TreeIter iter) {
        Value val;
        tree_model.get_value(iter, tvc.sort_column_id, out val);

        // now let's set the rating!
        var rating_cell = cell as Granite.Widgets.CellRendererRating;
        return_if_fail (rating_cell != null);
        rating_cell.rating = val.get_int ();
    }
}

