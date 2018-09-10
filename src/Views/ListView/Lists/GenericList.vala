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

public abstract class Noise.GenericList : Gtk.TreeView {
    public signal void import_requested (Gee.Collection<Media> to_import);
    public signal void rows_reordered ();

    public Gee.List<Type> columns { get; construct set; }
    public bool research_needed { get; set; default = false; }
    public bool is_current_list { get; private set; }
    public Playlist? playlist { get; set; default = null; }
    public TreeViewSetup tvs { get; construct set; }

    public ViewWrapper.Hint hint {
        get {
            return tvs.hint;
        }
        set {
            tvs.hint = value;
        }
    }

    private ViewWrapper _parent_wrapper;
    public ViewWrapper parent_wrapper {
        get {
            return _parent_wrapper;
        }
        construct set {
            _parent_wrapper = value;
            playlist = value.playlist;
        }
    }

    private const int OPTIMAL_COLUMN = -2;
    protected FastModel fm;

    /**
    * A list of all the medias to display
    */
    protected Gee.ArrayList<Media> table = new Gee.ArrayList<Media> (); // is not the same object as showing.

    /**
    * The media that are presently shown (some of them can be absent because of search)
    */
    protected Gee.ArrayList<Media> showing = new Gee.ArrayList<Media> (); // should never point to table.

    /* sortable stuff */
    public delegate int SortCompareFunc (
        int sort_column_id,
        Gtk.SortType sort_direction,
        Media a,
        Media b,
        int index_a, // position of items in the view's @table
        int index_b
    );

    protected int sort_column_id;
    protected Gtk.SortType sort_direction;
    private unowned SortCompareFunc compare_func;

    // search stuff
    public delegate void ViewSearchFunc (string search, Gee.ArrayList<Media> table, Gee.ArrayList<Media> showing);
    private unowned ViewSearchFunc search_func;

    protected bool dragging;
    protected CellDataFunctionHelper cell_data_helper;

    public GenericList (ViewWrapper view_wrapper, TreeViewSetup tvs) {
        Object (parent_wrapper: view_wrapper, tvs: tvs);
    }

    construct {
        columns = new Gee.ArrayList<Type> ();
        foreach (var type in ListColumn.get_all ()) {
            columns.add (type.get_data_type ());
        }

        fm = new FastModel (columns);
        sort_column_id = OPTIMAL_COLUMN;
        sort_direction = Gtk.SortType.ASCENDING;

        fm.reorder_requested.connect (reorder_requested);

        set_table (table, true);
        set_model (fm);

        cell_data_helper = new CellDataFunctionHelper (this);

        // Set sort data from saved session
        set_sort_column_id (tvs.sort_column_id, tvs.sort_direction);

        enable_search = false; // we don't want the built-in search

        set_fixed_height_mode (true);
        set_reorderable (false);

        foreach (Gtk.TreeViewColumn tvc in tvs.get_columns ()) {
            add_column (tvc, TreeViewSetup.get_column_type (tvc));
        }

        // allow selecting multiple rows
        get_selection ().set_mode (Gtk.SelectionMode.MULTIPLE);

        rows_reordered.connect (on_rows_reordered);

        key_press_event.connect ((event) => {
            if (event.keyval == Gdk.Key.Delete) {
                mediaRemoveClicked ();
            }

            return false;
        });

        // drag source
        Gtk.TargetEntry te = { "text/uri-list", Gtk.TargetFlags.SAME_APP, 0};
        Gtk.drag_source_set (this, Gdk.ModifierType.BUTTON1_MASK, { te }, Gdk.DragAction.COPY);

        drag_begin.connect (on_drag_begin);
        drag_data_get.connect (on_drag_data_get);
        drag_end.connect (on_drag_end);

        parent_wrapper.library.media_updated.connect (queue_draw);

        App.player.queue_cleared.connect (() => {
            is_current_list = false;
        });

        App.player.media_played.connect (media_played);
    }

    protected abstract void add_column (Gtk.TreeViewColumn column, ListColumn type);
    protected abstract void mediaRemoveClicked ();

    public void set_media (Gee.Collection<Media> to_add) {
        var new_table = new Gee.ArrayList<Media> ();
        new_table.add_all (to_add);

        // set table and resort
        set_table (new_table, true);

        scroll_to_current_media (false);
    }

    protected void set_fixed_column_width (Gtk.Widget treeview, Gtk.TreeViewColumn column, Gtk.CellRendererText renderer, string[] strings, int padding) {
        int max_width = 0;

        foreach (unowned string str in strings) {
            renderer.text = str;
            // XXX should we use minimum size instead?
            Gtk.Requisition natural_size;
            renderer.get_preferred_size (treeview, null, out natural_size);

            if (natural_size.width > max_width)
                max_width = natural_size.width;
        }

        column.fixed_width = max_width + padding;
    }

    private Media? get_media_from_index (int index) {
        return get_object_from_index (index);
    }

    // When the user clicks over a cell in the rating column, that cell renderer
    // emits the rating_changed signal. We need to update that rating...
    protected void on_rating_cell_changed (int new_rating, Gtk.Widget widget, string path) {
        var m = get_media_from_index (int.parse (path));

        return_if_fail (m != null);

        m.rating = new_rating;

        var to_update = new Gee.TreeSet<Media> ();
        to_update.add (m);
        parent_wrapper.library.update_medias (to_update, true, true);
    }

    private void on_rows_reordered () {
        scroll_to_current_media (false);
        if (is_current_list)
            set_as_current_list ();
    }

    public override void row_activated (Gtk.TreePath path, Gtk.TreeViewColumn column) {
        var m = get_media_from_index (int.parse (path.to_string ()));

        // Now update current_list and current_index in LM
        set_as_current_list (m);

        // Now play the song
        App.player.play_media (m);

        if (!App.player.playing) {
            App.main_window.play_media ();
        }
    }

    private async void media_played (Media m) {
        queue_draw ();

        Idle.add_full (Priority.HIGH_IDLE + 10, media_played.callback);
        yield;

        scroll_to_current_media (false);
    }

    public void set_as_current_list (Media? m = null) {
        Media to_set = m == null ? App.player.current_media : m;

        is_current_list = true;
        var main_settings = Settings.Main.get_default ();

        if (!main_settings.privacy_mode_enabled ()) {
            if (playlist == null || playlist == ((Noise.LocalLibrary)libraries_manager.local_library).p_music || parent_wrapper.library != libraries_manager.local_library) {
                App.saved_state.set_string ("last-playlist-playing", "");
            } else if (playlist is SmartPlaylist) {
                App.saved_state.set_string ("last-playlist-playing", "s%lld".printf (playlist.rowid));
            } else {
                if (((StaticPlaylist)playlist).read_only == false) {
                    App.saved_state.set_string ("last-playlist-playing", "p%lld".printf (playlist.rowid));
                } else {
                    App.saved_state.set_string ("last-playlist-playing", "");
                }
            }
        }

        var queue = start_at (to_set, get_visible_table ());
        foreach (var q in queue) {
            debug ("QUEING: %s", q.title);
        }
        App.player.clear_queue ();
        App.player.queue_medias (queue);
        App.player.current_index = 0;

        // order the queue like this list
        var view = App.main_window.match_playlists[App.player.queue_playlist];
        view.list_view.list_view.set_sort_column_id (tvs.sort_column_id, tvs.sort_direction);

        media_played.begin (App.player.current_media);
    }

    /**
    * Shift a list (of media) to make it start at a given element
    */
    private Gee.List<Media> start_at (Media start, Gee.List<Media> media) {
        int index = 0;
        for ( ; index < media.size && media[index].uri != start.uri; ++index);
        debug ( @"TO START: '$(start.title)', size = $(media.size), index: $(index)");

        if (index == media.size) {
            return media; // nothing to shift
        }

        var res = new Gee.ArrayList<Media> ();
        res.add_all (media[index: media.size]);
        res.add_all (media[0: index]);
        return res;
    }

    public Gee.Collection<Media> get_selected_medias () {
        var rv = new Gee.ArrayQueue<Media> ();
        Gtk.TreeModel temp;

        foreach (Gtk.TreePath path in get_selection ().get_selected_rows (out temp)) {
            var m = get_media_from_index (int.parse (path.to_string ()));
            rv.add (m);
        }

        return rv;
    }

    public void scroll_to_current_media (bool unfilter_if_not_found) {
        if (App.player.current_media == null)
            return;

        for (int i = 0; i < get_visible_table ().size; ++i) {
            var m = get_media_from_index (i);

            if (m == App.player.current_media) {
                var path = new Gtk.TreePath.from_indices (i, -1);

                // Only scroll to the middle (true) if the cell *is not within the visible range*;
                // otherwise, do a minimum effort (false) to avoid unnecessary scrolling when
                // a cell is already visible.
                bool center_cell = false;

                Gtk.TreePath start_path, end_path;

                if (get_visible_range (out start_path, out end_path)) {
                    int start_index = start_path.get_indices ()[0];
                    int end_index = end_path.get_indices ()[0];

                    // If the cell is only one position away from being visible (+1 or -1),
                    // then avoid scrolling to the center because it would result confusing
                    // for new users (if, for example, they were constantly clicking the
                    // *next* button to play the next song without shuffle enabled, it's always
                    // better if we only do a minimum amount of scrolling).
                    if (i < start_index - 1 || i > end_index + 1)
                        center_cell = true;
                }

                scroll_to_cell (path, null, center_cell, 0.5f, 0);

                var column = get_column (0);
                set_cursor_on_cell (path, column, column.get_cells ().nth_data (0), false);

                break;
            }
        }
    }

    /** Should not be manipulated by client */
    public Gee.BidirList<Media> get_table () {
        return table.read_only_view;
    }

    /** Should not be manipulated by client */
    public Gee.BidirList<Media> get_visible_table () {
        return showing.read_only_view;
    }

    public static int get_index_from_iter (Gtk.TreeIter iter) {
        return (int) iter.user_data;
    }

    public Media? get_object_from_index (int index) {
        return index < showing.size ? showing[index] : null;
    }

    public void set_value_func (FastModel.ValueReturnFunc func) {
        fm.set_value_func (func);
    }

    public void set_table (Gee.ArrayList<Media> table, bool do_resort) {
        this.table = table;

        if (do_resort) {
            resort (); // this also calls search
        } else {
            do_search (null);
        }
    }

    public void set_search_func (ViewSearchFunc func) {
        search_func = func;
    }

    public void do_search (string? search = null) {
        if (search_func == null || research_needed == false) {
            return;
        }

        research_needed = false;
        var old_size = showing.size;

        showing.clear ();
        search_func (search ?? "", table, showing);

        if (showing.size == old_size) {
            fm.set_table (showing);
            queue_draw ();
        } else if (old_size == 0) { // if first population, just do normal
            set_model (null);
            fm.set_table (showing);
            set_model (fm);
        } else if (old_size > showing.size) { // removing
            while (fm.iter_n_children (null) > showing.size) {
                Gtk.TreeIter iter;
                fm.iter_nth_child (out iter, null, fm.iter_n_children (null) - 1);
                fm.remove (iter);
            }

            fm.set_table (showing);
            queue_draw ();
        } else if (showing.size > old_size) { // adding
            Gtk.TreeIter iter;

            while (fm.iter_n_children (null) < showing.size) {
                fm.append (out iter);
            }

            fm.set_table (showing);
            queue_draw ();
        }
    }

    /* Sorting is done in the treeview, not the model. That way the whole
     * table is sorted and ready to go and we do not need to resort every
     * time we repopulate/search the model
     */
    public void set_sort_column_id (int sort_column_id, Gtk.SortType order) {
        fm.set_sort_column_id (sort_column_id, order); // The model will then go back to us at reorder_requested
    }

    private void reorder_requested (int column, Gtk.SortType direction) {
        if (column == sort_column_id && direction == sort_direction) {
            return;
        }

        sort_column_id = column;
        sort_direction = direction;

        quicksort (0, table.size - 1);
        research_needed = true;
        do_search (null);

        // Let it be known the row order changed
        rows_reordered ();
    }

    public void resort () {
        quicksort (0, table.size - 1);

        research_needed = true;
        do_search (null);
    }

    public void set_compare_func (SortCompareFunc func) {
        compare_func = func;
    }

    private void swap (int a, int b) {
        var temp = table[a];
        table[a] = table[b];
        table[b] = temp;
    }

    private void quicksort (int start, int end) {
        if (table.size == 0) {
            return;
        }

        int pivot_index = (start + end) / 2;
        var pivot = table[pivot_index];
        int i = start;
        int j = end;

        while (i <= j) {
            while (i < end && compare_func (sort_column_id, sort_direction, table[i], pivot, i, pivot_index) < 0) ++i;
            while (j > start && compare_func (sort_column_id, sort_direction, table[j], pivot, j, pivot_index) > 0) --j;
            if (i <= j) {
                swap (i, j);
                ++i; --j;
            }
        }

        if (start < j) {
            quicksort (start, j);
        }
        if (i < end) {
            quicksort (i, end);
        }
    }

    /** **********************************************************
     * Drag and drop support. GenericList is a source for media and can
     * be dragged to a playlist in the sidebar. No support for reordering
     * is implemented yet.
    ***************************************************************/
    private void on_drag_begin (Gtk.Widget sender, Gdk.DragContext context) {
        dragging = true;
        debug ("drag begin");

        Gdk.drag_abort (context, Gtk.get_current_event_time ());

        int selected_rows = get_selection ().count_selected_rows ();

        if (selected_rows > 0)
            Gtk.drag_source_set_icon_name (this, "audio-x-generic");
    }

    private void on_drag_data_get (Gdk.DragContext context, Gtk.SelectionData selection_data, uint info, uint time_) {
        string[] uris = null;

        foreach (Media m in get_selected_medias ())
            uris += m.uri;

        if (uris != null)
            selection_data.set_uris (uris);
    }

    private void on_drag_end (Gtk.Widget sender, Gdk.DragContext context) {
        dragging = false;

        debug ("drag end\n");

        //unset_rows_drag_dest ();
        Gtk.drag_dest_set (this,
                          Gtk.DestDefaults.ALL,
                          {},
                          Gdk.DragAction.COPY|
                          Gdk.DragAction.MOVE
                          );
    }
}
