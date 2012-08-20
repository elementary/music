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

        public double get_percentage () {
            switch (this) {
                case LOW:
                    return 0.20;
                case MEDIUM:
                    return 0.35;
                case HIGH:
                    return 0.45;
                default:
                    assert_not_reached ();
            }
        }
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

        Idle.add_full (Priority.LOW, () => {
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

        debug ("ideal_total_width\t= %i", ideal_total_width);
        debug ("total_min_width\t= %.1f", total_min_width);
        debug ("total_fixed_width\t= %.1f", total_fixed_width);


        // Nothing to do
        if (resizable_columns.size == 0)
            return;

        // Distribute remaining size based on priorities
        double available_width = (double)(ideal_total_width - total_fixed_width);


        debug ("available_width[1]\t= %.1f", available_width);

        // if negative or small, try to do the best we can by using a small value.
        // We want to allocate at least one pixel for each column (and hence we use
        // resizable_columns.size)
        if (available_width <= 0)
            available_width = (double)resizable_columns.size;

        debug ("available_width[2]\t= %.1f", available_width);

        double high_priority_cols = 0.0, medium_priority_cols = 0.0, low_priority_cols = 0.0;

        foreach (var col in resizable_columns) {
            switch (col.priority) {
                case SizePriority.HIGH:
                    high_priority_cols += 1.0;
                    break;
                case SizePriority.MEDIUM:
                    medium_priority_cols += 1.0;
                    break;
                case SizePriority.LOW:
                    low_priority_cols += 1.0;
                    break;
                default:
                    assert_not_reached ();
            }
        }

        double high_priority_width =
            SizePriority.HIGH.get_percentage () * available_width / high_priority_cols;

        double medium_priority_width =
            SizePriority.MEDIUM.get_percentage () * available_width / medium_priority_cols;

        double low_priority_width =
            SizePriority.LOW.get_percentage () * available_width / low_priority_cols;

        foreach (var col in resizable_columns) {
            switch (col.priority) {
                case SizePriority.HIGH:
                    int new_width = (int)high_priority_width;
                    col.column.fixed_width = new_width > 0 ? new_width : 1;
                    break;
                case SizePriority.MEDIUM:
                    int new_width = (int)medium_priority_width;
                    col.column.fixed_width = new_width > 0 ? new_width : 1;
                    break;
                case SizePriority.LOW:
                    int new_width = (int)low_priority_width;
                    col.column.fixed_width = new_width > 0 ? new_width : 1;
                    break;
                default:
                    assert_not_reached ();
            }
        }
    }
}
