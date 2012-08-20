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
 * Authored by: Victor Eduardo <victoreduardm@gmail.com>
 */

/**
 * An object that controls the size of the columns on a Gtk.TreeView. Its main
 * purpose is to avoid horizontal scrolling at all cost.
 */
public class Noise.TreeViewColumnSizer {

    public class Column {
        public SizePriority priority = SizePriority.LOW;
        public Gtk.TreeViewColumn column;
    }

    /**
     * The priority of the information displayed by a column. It is used to
     * decide how much width is assigned to a given column. If it's low, then
     * its width may be reduced when there's not enough space. For instance,
     * in a music-info treeview, the "Title" column should have a higher
     * priority than the "Last Played" column.
     */
    public enum SizePriority {
        LOW,
        MEDIUM,
        HIGH;
    }


    private Gee.Collection<Column> _columns;

    public Gee.Collection<Column> columns {
        private get {
            return _columns;
        }
        set {
            this._columns = value;
            queue_resize ();
        }
    }


    /**
     * The total width that should be preserved. There's no guarantee that this
     * value will actually be achieved through smart resizing, since columns could
     * have a fixed width or minimum width that exceeds this value.
     * Use a negative value to mean "unset".
     */
    public int ideal_total_width {
        get {
            return target_total_width;
        }
        set {
            if (target_total_width == value)
                return;

            target_total_width = value;
            queue_resize ();
        }
    }

    private int target_total_width = -1;

    /* id of the last queue_resize request. We only process the last in the
     * queue for performance reasons. */
    private uint last_resize = 0;


    /**
     * Queues a resize event to be processed. If various queue_resize() events
     * are queued simultaneously, only the last in the queue will most likely
     * be processed; the previous ones will be discarded.
     */
    public async void queue_resize () {
        uint stamp = ++last_resize;

        Idle.add_full (Priority.DEFAULT_IDLE - 30, () => {
            // if not the last resize request, don't waste time processing it.
            // Weneed this to make sure we only process the last request queued.
            if (stamp == last_resize)
                resize_columns ();

            return false;
        });

        yield;
    }


    private void resize_columns () {
        // target total width has not been set
        if (ideal_total_width <= 0)
            return;

        int total_fixed_width = 0, total_min_width = 0;
        var resizable_columns = new Gee.LinkedList<Column> ();

        // Get total width
        foreach (var col in columns) {
            var treeviewcolumn = col.column;

            if (treeviewcolumn != null && treeviewcolumn.visible) {
                if (treeviewcolumn.resizable) {
                    if (treeviewcolumn.min_width > 0)
                        total_min_width += treeviewcolumn.min_width;

                    resizable_columns.add (col);
                } else {
                    total_min_width += treeviewcolumn.fixed_width;
                    total_fixed_width += treeviewcolumn.fixed_width;
                }
            }
        }

#if TRACE_COLUMN_SIZER
        debug ("ideal_total_width\t= %i", ideal_total_width);
        debug ("total_min_width\t= %.1f", total_min_width);
        debug ("total_fixed_width\t= %.1f", total_fixed_width);
#endif

        // Nothing to do
        if (resizable_columns.size == 0)
            return;

        // Distribute remaining size based on priorities
        double available_width = (double)(ideal_total_width - total_fixed_width);

#if TRACE_COLUMN_SIZER
        debug ("available_width[1]\t= %.1f", available_width);
#endif

        double total_columns = (double)resizable_columns.size;

        // if negative or small, try to do the best we can by using a small value.
        // We want to allocate at least one pixel for each column (and hence we use
        // the total number of columns)
        if (available_width <= 0)
            available_width = total_columns;

#if TRACE_COLUMN_SIZER
        debug ("available_width[2]\t= %.1f", available_width);
#endif

        // The alghorithm works as follows:
        //
        // First, get the average column width, and after that increase/decrease it depending
        // on the column priority. We need to keep the total width balanced while doing it.
        //
        // For the reason above, if there are high-priority columns, we compute how much we
        // can increase their size (from the average), and for that to be possible, we need
        // at least one column between those with medium/low priority available, in order
        // to keep the total width balanced by reducing their widths. If there's no column
        // among these categories, we don't proceed and let the high-priority columns use
        // the average width. Otherwise, we try to see how much width we can steal from low-
        // priority columns, and if we can't, we see if it's possible to get that extra size
        // from medium-priority columns. In perfect conditions, we would increase the size
        // of high-priority columns; then compensate that extra-size by decreasing the size
        // of low-priority columns, and leave medium-priority columns untouched.

        double avg_width = available_width / total_columns;

#if TRACE_COLUMN_SIZER
        debug ("average_width\t= %.1f", avg_width);
#endif

        int high_priority_cols = 0, medium_priority_cols = 0, low_priority_cols = 0;

        foreach (var col in resizable_columns) {
            switch (col.priority) {
                case SizePriority.HIGH:
                    high_priority_cols++;
                    break;
                case SizePriority.MEDIUM:
                    medium_priority_cols++;
                    break;
                case SizePriority.LOW:
                    low_priority_cols++;
                    break;
                default:
                    assert_not_reached ();
            }
        }

        bool has_high_priority_cols = high_priority_cols > 0;
        bool has_medium_priority_cols = medium_priority_cols > 0;
        bool has_low_priority_cols = low_priority_cols > 0;

        // We will add more width to high-priority columns, and we need to decrease
        // enough space from the remaining columns in order to keep the total
        // width constant
        int to_increase_high = 0;
        int to_increase_medium = 0, to_decrease_medium = 0;
        int to_decrease_low = 0;

        if (has_high_priority_cols) {
            if (has_low_priority_cols) {
                to_increase_high = (int)((double)(avg_width * low_priority_cols) * 0.30);
                to_decrease_low = to_increase_high * high_priority_cols / low_priority_cols;
            } else if (has_medium_priority_cols) {
                to_increase_high = (int)((double)(avg_width * medium_priority_cols) * 0.20);
                to_decrease_medium = to_increase_high * high_priority_cols / medium_priority_cols;
            }
        } else if (has_medium_priority_cols) {
            if (has_low_priority_cols) {
                to_increase_medium = (int)((double)(avg_width * low_priority_cols) * 0.20);
                to_decrease_low = to_increase_medium * medium_priority_cols / low_priority_cols;
            }
        }


        // Increase/decrease widths respectively
        foreach (var col in resizable_columns) {
            int new_width = (int)avg_width;

            switch (col.priority) {
                case SizePriority.HIGH:
                    new_width += (int)to_increase_high;
                    break;
                case SizePriority.MEDIUM:
                    new_width += to_increase_medium;
                    new_width -= to_decrease_medium;
                    break;
                case SizePriority.LOW:
                    new_width -= to_decrease_low;
                    break;
                default:
                    assert_not_reached (); // all the priorities must be handled
            }

            col.column.fixed_width = new_width > 0 ? new_width : 1;
        }
    }
}
