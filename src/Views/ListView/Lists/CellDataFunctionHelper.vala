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

namespace Noise.CellDataFunctionHelper {

    private const string NOT_AVAILABLE = N_("N/A");

#if HAVE_SMART_ALBUM_COLUMN
    // for Smart album column
    public static void album_art_func (Gtk.TreeViewColumn tvc, Gtk.CellRenderer renderer,
                                         Gtk.TreeModel tree_model, Gtk.TreeIter iter) {
        var view = tvc.get_tree_view () as Noise.FastView;

        if (view == null)
            return;

        int index = (int)iter.user_data;

        var m = view.get_object_from_index (index) as Media;
        return_if_fail (m != null);

        var cell = renderer as SmartAlbumRenderer;
        return_if_fail (cell != null);

        cell.m = m;

        var cover_art = CoverartCache.instance.get_cover (m);

        if (cover_art != null) {
            int top, bottom, current, range;

            current = index;

            for (top = current; top >= 0; --top) {
                var top_media = view.get_object_from_index (top) as Media;

                if (top_media == null || top_media.album != m.album) {
                    ++top;
                    break;
                }
                else if (top == 0) {
                    break;
                }
            }

            for (bottom = current; bottom < view.get_visible_table().size(); ++bottom) {
                if ((view.get_object_from_index(bottom) as Media).album != m.album) {
                    --bottom;
                    break;
                }
            }

            range = (bottom - top) + 1;
            //warning ("range is %d, top is %d, bottom is %d, current is %d\n", range, top, bottom, current);

            // We have enough space to draw art
            if (range >= 6) {
                cell.icon = cover_art;
                cell.top = top;
                cell.bottom = bottom;
                cell.current = current;
                cell.xalign = 0.5f;
            }
            else {
                cell.icon = null;
                cell.xalign = 0f;
            }
        }
        else {
            cell.xalign = 0f;
            cell.icon = null;
        }
    }
#endif

    /** For spinner/unique icon on each row **/
    public static void icon_func (CellLayout layout, CellRenderer renderer, TreeModel model, TreeIter iter) {
        var tvc = layout as Gtk.TreeViewColumn;

        return_if_fail (tvc != null);

        var view = tvc.get_tree_view () as Noise.FastView;

        if (view == null)
            return;

        bool showIndicator = false;
        var s = view.get_object_from_index((int)iter.user_data) as Media;

        if (s == null)
            return;
        else
            showIndicator = s.showIndicator;

        if (renderer is CellRendererPixbuf) {
            Value? icon;
            model.get_value (iter, MusicListView.MusicColumn.ICON, out icon); // ICON column is same for all

            /* Themed icon */
            (renderer as CellRendererPixbuf).follow_state = true;
            (renderer as CellRendererPixbuf).gicon = (icon as GLib.Icon);

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
    public static void intelligent_func (TreeViewColumn tvc, CellRenderer cell, TreeModel tree_model, TreeIter iter) {
        Value val;
        tree_model.get_value(iter, tvc.sort_column_id, out val);

        if (val.get_int() <= 0)
            ((CellRendererText)cell).markup = "";
        else
            ((CellRendererText)cell).markup = String.escape (val.get_int().to_string());
    }

    public static void string_func (TreeViewColumn tvc, CellRenderer cell, TreeModel tree_model, TreeIter iter) {
        Value val;
        tree_model.get_value(iter, tvc.sort_column_id, out val);

        var str = val.get_string ();

        if (str == null)
            return;

        ((CellRendererText)cell).markup = String.escape (str);
    }

    // for Bitrate. Append 'kbps'
    public static void bitrate_func (TreeViewColumn tvc, CellRenderer cell, TreeModel tree_model, TreeIter iter) {
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
    public static void length_func (TreeViewColumn tvc, CellRenderer cell, TreeModel tree_model, TreeIter iter) {
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
    public static void date_func (TreeViewColumn tvc, CellRenderer cell, TreeModel tree_model, TreeIter iter) {
        Value val;
        tree_model.get_value(iter, tvc.sort_column_id, out val);

        int n = val.get_int ();
        var text_cell = cell as CellRendererText;

        if (n <= 0)
            text_cell.markup = "";
        else {
            var t = Time.local (n);
            var str = TimeUtils.pretty_timestamp_from_time (t);
            text_cell.markup = String.escape (str);
        }
    }

    public static void rating_func (TreeViewColumn tvc, CellRenderer cell, TreeModel tree_model, TreeIter iter) {
        Value val;
        tree_model.get_value(iter, tvc.sort_column_id, out val);

        // now let's set the rating!
        var rating_cell = cell as Granite.Widgets.CellRendererRating;
        return_if_fail (rating_cell != null);
        rating_cell.rating = val.get_int ();
    }
}

