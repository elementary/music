// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012-2017 elementary LLC. (https://elementary.io)
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

public abstract class Noise.GenericList : FastView {
    public signal void import_requested (Gee.Collection<Media> to_import);

    public Playlist? playlist { get; set; default = null; }
    public ViewWrapper.Hint hint {
        get {
            return tvs.hint;
        }
        set {
            tvs.hint = value;
        }
    }

    //for header column chooser
    protected Gtk.Menu column_chooser_menu;
    private Gtk.MenuItem autosize_menu_item;

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

    public TreeViewSetup tvs { get; construct set; }
    protected bool is_current_list;

    protected bool dragging;

    protected CellDataFunctionHelper cell_data_helper;

    public GenericList (ViewWrapper view_wrapper, TreeViewSetup tvs) {
        Object (parent_wrapper: view_wrapper, tvs: tvs);
    }

    construct {
        cell_data_helper = new CellDataFunctionHelper (this);

        // Set sort data from saved session
        set_sort_column_id (tvs.sort_column_id, tvs.sort_direction);

        enable_search = false; // we don't want the built-in search

        set_headers_clickable (true);
        set_headers_visible (hint != ViewWrapper.Hint.ALBUM_LIST);
        set_fixed_height_mode (true);
        set_reorderable (false);

        add_columns ();

        // allow selecting multiple rows
        get_selection ().set_mode (Gtk.SelectionMode.MULTIPLE);

        rows_reordered.connect (on_rows_reordered);

        key_press_event.connect ((event) => {
                if (event.keyval == Gdk.Key.Delete)
                    mediaRemoveClicked ();

                return false;
        });

        // drag source
        Gtk.TargetEntry te = { "text/uri-list", Gtk.TargetFlags.SAME_APP, 0};
        Gtk.drag_source_set (this, Gdk.ModifierType.BUTTON1_MASK, { te }, Gdk.DragAction.COPY);
        //enable_model_drag_source (Gdk.ModifierType.BUTTON1_MASK, {te}, Gdk.DragAction.COPY);

        //vadjustment.value_changed.connect (view_scroll);
        drag_begin.connect (on_drag_begin);
        drag_data_get.connect (on_drag_data_get);
        drag_end.connect (on_drag_end);

        parent_wrapper.library.media_updated.connect (media_updated);

        App.player.queue_cleared.connect (current_cleared);
        App.player.media_played.connect (media_played);
    }

    protected abstract void mediaRemoveClicked ();

    protected void add_column_chooser_menu_item (Gtk.TreeViewColumn tvc, ListColumn type) {
        if (type == ListColumn.TITLE || type == ListColumn.ICON)
            return;

        if (hint == ViewWrapper.Hint.MUSIC && type == ListColumn.NUMBER)
            return;

        if (column_chooser_menu == null) {
            column_chooser_menu = new Gtk.Menu ();

            autosize_menu_item = new Gtk.MenuItem.with_label (_("Autosize Columns"));
            autosize_menu_item.activate.connect (columns_autosize);

            column_chooser_menu.append (autosize_menu_item);
            column_chooser_menu.append (new Gtk.SeparatorMenuItem ());

            column_chooser_menu.show_all ();
        }

        var menu_item = new Gtk.CheckMenuItem.with_label (tvc.title);
        menu_item.active = tvc.visible;

        column_chooser_menu.append (menu_item);
        column_chooser_menu.show_all ();

        // Show/hide the current column
        menu_item.toggled.connect (() => {
            tvc.visible = menu_item.active;

            columns_autosize ();
        });
    }

    public void set_media (Gee.Collection<Media> to_add) {
        var new_table = new Gee.ArrayList<Media> ();
        new_table.add_all (to_add);

        // set table and resort
        set_table (new_table, true);

        scroll_to_current_media (false);
    }

    /* If a Media is in to_remove but not in table, will just ignore */
    public void remove_media (Gee.Collection<Media> to_remove) {
        var new_table = new Gee.ArrayList<Media> ();

        foreach (Media m in table) {
            if (!(m in to_remove)) {
                new_table.add (m);
            }
        }

        // no need to resort, just removing
        set_table (new_table, false);
    }

    public void add_media (Gee.Collection<Media> to_add) {
        // skip calling set_table and just do it ourselves (faster)
        table.add_all (to_add);

        // resort the new songs in. this will also call do_search
        resort ();
    }

    public abstract void update_sensitivities ();

    protected void set_fixed_column_width (Gtk.Widget treeview, Gtk.TreeViewColumn column,
                                          Gtk.CellRendererText renderer, string[] strings, int padding)
    {
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

    private void reset_column_widths () {
        foreach (var column in get_columns ()) {
            if (column.min_width > 0)
                column.fixed_width = column.min_width;
        }
    }

    public new void columns_autosize () {
        reset_column_widths ();
        base.columns_autosize ();
    }

    protected abstract void add_column (Gtk.TreeViewColumn column, ListColumn type);

    protected void add_columns () {
        foreach (Gtk.TreeViewColumn tvc in tvs.get_columns ())
            add_column (tvc, TreeViewSetup.get_column_type (tvc));
    }

    public Media? get_media_from_index (int index) {
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

    protected bool view_header_click (Gdk.EventButton e, bool is_selector_col) {
        if (e.button == Gdk.BUTTON_SECONDARY || is_selector_col) {
            column_chooser_menu.popup (null, null, null, Gdk.BUTTON_SECONDARY, e.time);
            return true;
        }

        return false;
    }

    public void on_rows_reordered () {
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

    public void media_updated (Gee.Collection<int> ids) {
        queue_draw ();
    }

    void current_cleared () {
        is_current_list = false;
    }

    public void set_as_current_list (Media? m = null) {
        Media to_set = m == null ? App.player.current_media : m;

        is_current_list = true;
        var main_settings = Settings.Main.get_default ();

        if (!main_settings.privacy_mode_enabled ()) {
            if (playlist == null || playlist == ((Noise.LocalLibrary)libraries_manager.local_library).p_music || parent_wrapper.library != libraries_manager.local_library) {
                main_settings.last_playlist_playing = "";
            } else if (playlist is SmartPlaylist) {
                main_settings.last_playlist_playing = "s%lld".printf (playlist.rowid);
            } else {
                if (((StaticPlaylist)playlist).read_only == false) {
                    main_settings.last_playlist_playing = "p%lld".printf (playlist.rowid);
                } else {
                    main_settings.last_playlist_playing = "";
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
        var queue_view_id = App.main_window.match_playlists[App.player.queue_playlist];
        var view = (ViewWrapper) App.main_window.view_stack.get_child_by_name (queue_view_id.to_string ());
        view.list_view.list_view.set_sort_column_id (tvs.sort_column_id, tvs.sort_direction);

        media_played.begin (App.player.current_media);
    }

    /**
    * Shift a list (of media) to make it start at a given element
    */
    private Gee.ArrayList<Media> start_at (Media start, Gee.List<Media> media) {
        debug ("TO START: %s (size = %d)", start.title, media.size);
        var res = new Gee.ArrayList<Media> ();
        int index = media.index_of (start);
        for (int _ = 0; _ < media.size; _++) {
            res.add (media[index]);
            index++;

            if (index == media.size) {
                index = 0;
            }
        }

        return res;
    }

    protected Gee.Collection<Media> get_selected_medias () {
        var rv = new Gee.ArrayQueue<Media> ();
        Gtk.TreeModel temp;

        foreach (Gtk.TreePath path in get_selection ().get_selected_rows (out temp)) {
            var m = get_media_from_index (int.parse (path.to_string ()));
            rv.add (m);
        }

        return rv;
    }

    protected void media_scroll_to_current_requested () {
        scroll_to_current_media (true);
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

    /***************************************
     * Simple setters and getters
     * *************************************/

    public bool get_is_current_list () {
        return is_current_list;
    }

    /** **********************************************************
     * Drag and drop support. GenericList is a source for media and can
     * be dragged to a playlist in the sidebar. No support for reordering
     * is implemented yet.
    ***************************************************************/
    void on_drag_begin (Gtk.Widget sender, Gdk.DragContext context) {
        dragging = true;
        debug ("drag begin");

        Gdk.drag_abort (context, Gtk.get_current_event_time ());

        int selected_rows = get_selection ().count_selected_rows ();

        if (selected_rows > 0)
            Gtk.drag_source_set_icon_name (this, "audio-x-generic");
    }

    void on_drag_data_get (Gdk.DragContext context, Gtk.SelectionData selection_data, uint info, uint time_) {
        string[] uris = null;

        foreach (Media m in get_selected_medias ())
            uris += m.uri;

        if (uris != null)
            selection_data.set_uris (uris);
    }

    void on_drag_end (Gtk.Widget sender, Gdk.DragContext context) {
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
