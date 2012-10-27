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

using Gee;
using Gtk;

public abstract class Noise.GenericList : FastView {

    public signal void import_requested (Gee.LinkedList<Media> to_import);

    //for header column chooser
    protected Gtk.Menu column_chooser_menu;
    private Gtk.MenuItem autosize_menu_item;
#if HAVE_SMART_ALBUM_COLUMN
    private Gtk.CheckMenuItem smart_album_art_menu_item;
#endif

    protected LibraryManager lm;
    protected LibraryWindow lw;
    protected ViewWrapper parent_wrapper;

    protected TreeViewSetup tvs;
    protected int relative_id;
    protected bool is_current_list;

    protected bool dragging;

    protected CellDataFunctionHelper cell_data_helper;

    public GenericList (ViewWrapper view_wrapper, TreeViewSetup tvs) {
		var types = new GLib.List<Type> ();
        foreach (var type in ListColumn.get_all ())
            types.append (type.get_data_type ());

        base (types);

        this.tvs = tvs;

        set_parent_wrapper (view_wrapper);

        cell_data_helper = new CellDataFunctionHelper (this);

        // Set sort data from saved session
        set_sort_column_id (tvs.sort_column_id, tvs.sort_direction);

        enable_search = false; // we don't want the built-in search

        set_headers_clickable (true);
        set_headers_visible (tvs.get_hint () != ViewWrapper.Hint.ALBUM_LIST);
        set_fixed_height_mode (true);
#if HAVE_SMART_ALBUM_COLUMN
        set_rules_hint (!CellDataFunctionHelper.smart_album_art_enabled);
#else
        set_rules_hint (true);
#endif
        set_reorderable (false);

        add_columns ();

        // allow selecting multiple rows
        get_selection ().set_mode (SelectionMode.MULTIPLE);

        rows_reordered.connect (on_rows_reordered);

        key_press_event.connect ((event) => {
                if (event.keyval == Gdk.Key.Delete)
                    mediaRemoveClicked ();

                return false;
        });

#if 0
        // drag source
        TargetEntry te = { "text/uri-list", TargetFlags.SAME_APP, 0};
        drag_source_set (this, Gdk.ModifierType.BUTTON1_MASK, { te }, Gdk.DragAction.COPY);
        //enable_model_drag_source (Gdk.ModifierType.BUTTON1_MASK, {te}, Gdk.DragAction.COPY);

        //vadjustment.value_changed.connect (view_scroll);
        drag_begin.connect (on_drag_begin);
        drag_data_get.connect (on_drag_data_get);
        drag_end.connect (on_drag_end);
#endif

        lm.media_updated.connect (media_updated);

        App.player.current_cleared.connect (current_cleared);
        App.player.media_played.connect (media_played);
    }

    protected abstract void mediaRemoveClicked ();

    public void set_parent_wrapper (ViewWrapper parent) {
        this.parent_wrapper = parent;
        this.lm = parent_wrapper.lm;
        this.lw = parent_wrapper.lw;
        this.relative_id = parent_wrapper.relative_id;
    }

    protected void add_column_chooser_menu_item (TreeViewColumn tvc, ListColumn type) {
        if (type == ListColumn.TITLE || type == ListColumn.ICON)
            return;

        if (get_hint () == ViewWrapper.Hint.MUSIC && type == ListColumn.NUMBER)
            return;

        if (column_chooser_menu == null) {
            column_chooser_menu = new Gtk.Menu ();

            autosize_menu_item = new Gtk.MenuItem.with_label (_("Autosize Columns"));
            autosize_menu_item.activate.connect (columns_autosize);

            column_chooser_menu.append (autosize_menu_item);
            column_chooser_menu.append (new Gtk.SeparatorMenuItem ());

#if HAVE_SMART_ALBUM_COLUMN
            smart_album_art_menu_item = new Gtk.CheckMenuItem.with_label (_("Display Album Art"));
            column_chooser_menu.append (smart_album_art_menu_item);
            column_chooser_menu.append (new Gtk.SeparatorMenuItem ());

            smart_album_art_menu_item.active = CellDataFunctionHelper.smart_album_art_enabled;

            smart_album_art_menu_item.toggled.connect (() => {
                CellDataFunctionHelper.smart_album_art_enabled = smart_album_art_menu_item.active;
                 set_rules_hint (!CellDataFunctionHelper.smart_album_art_enabled);
                queue_draw ();
            });
#endif

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
        var new_table = new HashTable<int, Object> (null, null);

        foreach (var m in to_add)
            new_table.set ((int) new_table.size (), m);

        // set table and resort
        set_table (new_table, true);

        scroll_to_current_media (false);
    }

    /* If a Media is in to_remove but not in table, will just ignore */
    public void remove_media (Gee.Collection<Media> to_remove) {
        var to_remove_set = new Gee.HashSet<Media> (null, null);
        foreach (var m in to_remove)
            to_remove_set.add (m);

        var new_table = new HashTable<int, Object> (null, null);
        for (int i = 0; i < table.size (); ++i) {
            var m = table.get (i) as Media;
            // create a new table. if not in to_remove, and is in table, add it.
            if (m != null && !to_remove_set.contains (m))
                new_table.set ((int)new_table.size (), m);
        }

        // no need to resort, just removing
        set_table (new_table, false);
    }

    public void add_media (Gee.Collection<Object> to_add) {
        // Check for duplicates
        var existing = new Gee.HashSet<Object> ();
        foreach (var m in table.get_values ())
            existing.add (m);

        var new_media = new Gee.LinkedList<Object> ();
        foreach (var m in to_add) {
            if (!existing.contains (m))
                new_media.add (m);
        }

        // skip calling set_table and just do it ourselves (faster)
        foreach (var m in new_media)
            table.set ((int) table.size (), m);

        // resort the new songs in. this will also call do_search
        resort ();
    }

    public abstract void update_sensitivities ();

    /** TreeViewColumn header functions. Has to do with sorting and
     * remembering column widths/sort column/sort direction between
     * sessions.
    **/
    protected abstract void updateTreeViewSetup ();

    protected void set_fixed_column_width (Gtk.Widget treeview, Gtk.TreeViewColumn column,
                                          Gtk.CellRendererText renderer, string[] strings, int padding)
    {
        UI.set_tree_view_column_fixed_width (treeview, column, renderer, strings, padding);
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
        foreach (TreeViewColumn tvc in tvs.get_columns ())
            add_column (tvc, TreeViewSetup.get_column_type (tvc));
    }

    public Media? get_media_from_index (int index) {
        return get_object_from_index (index) as Media;
    }

    // When the user clicks over a cell in the rating column, that cell renderer
    // emits the rating_changed signal. We need to update that rating...
    protected void on_rating_cell_changed (int new_rating, Gtk.Widget widget, string path) {
        var m = get_media_from_index (int.parse (path));

        return_if_fail (m != null);

        m.rating = new_rating;

        var to_update = new Gee.LinkedList<Media> ();
        to_update.add (m);
        lm.update_media (to_update, true, true);
    }

    protected bool view_header_click (Gdk.EventButton e, bool is_selector_col) {
        if (e.button == Gdk.BUTTON_SECONDARY || is_selector_col) {
            column_chooser_menu.popup (null, null, null, Gdk.BUTTON_SECONDARY, e.time);
            return true;
        }

        return false;
    }

    public void on_rows_reordered () {
        updateTreeViewSetup ();
        scroll_to_current_media (false);
    }

    public override void row_activated (TreePath path, TreeViewColumn column) {
        if (tvs.get_hint () == ViewWrapper.Hint.DEVICE_AUDIO || tvs.get_hint () == ViewWrapper.Hint.DEVICE_PODCAST) {
            lw.doAlert (_("Playing not Supported"), _("Due to issues with playing songs on certain iOS devices, playing songs off devices is currently not supported."));
            return;
        }

        var m = get_media_from_index (int.parse (path.to_string ()));

        // We need to first set this as the current list
        App.player.clearCurrent ();
        is_current_list = true;

        // Now update current_list and current_index in LM
        set_as_current_list (m);

        // Now play the song
        App.player.playMedia (m, false);

        if (!App.player.playing) {
            lw.playClicked ();
        }
    }

    private async void media_played (Media m) {
        queue_draw ();

        Idle.add_full (Priority.HIGH_IDLE + 10, media_played.callback);
        yield;

        scroll_to_current_media (false);
    }

    public void media_updated (LinkedList<int> ids) {
        queue_draw ();
    }

    void current_cleared () {
        is_current_list = false;
    }

    public void set_as_current_list (Media? m = null) {
        Media to_set;
        if (m != null)
            to_set = m;
        else
            to_set = App.player.media_info.media;

        App.player.clearCurrent ();
        is_current_list = true;

        App.player.current_index = 0;
        var vis_table = get_visible_table ();
        for (int i = 0; i < vis_table.size (); ++i) {
            var test = vis_table.get (i) as Media;
            App.player.addToCurrent (test);


            if (to_set == test) {
                App.player.current_index = i;
            }
        }

        media_played (App.player.media_info.media);
    }

    protected GLib.List<Media> get_selected_medias () {
        var rv = new GLib.List<Media> ();
        TreeModel temp;

        foreach (TreePath path in get_selection ().get_selected_rows (out temp)) {
            var m = get_media_from_index (int.parse (path.to_string ()));
            rv.append (m);
        }

        return rv;
    }

    protected void mediaScrollToCurrentRequested () {
        scroll_to_current_media (true);
    }

    public void scroll_to_current_media (bool unfilter_if_not_found) {
        if (App.player.media_info.media == null)
            return;

        for (int i = 0; i < get_visible_table ().size (); ++i) {
            var m = get_media_from_index (i);

            if (m == App.player.media_info.media) {
                var path = new TreePath.from_indices (i, -1);

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

/*
        if (unfilter_if_not_found) {
            // At this point, it was not scrolled to. Let's see if it's in ALL the songs
            // and if so, undo the search and filters and scroll to it.
            var whole_table = get_table ();
            for (int i = 0; i < whole_table.size (); ++i) {
                var m = whole_table.get (i) as Media;

                if (m.rowid == App.player.media_info.media.rowid) {
                    // Undo search and filter
                    parent_wrapper.clear_filters ();

                    // And now scroll to it.
                    scroll_to_cell (new TreePath.from_string (i.to_string ()), null, false, 0.0f, 0.0f);

                    return;
                }
            }
        }
*/
    }

    /***************************************
     * Simple setters and getters
     * *************************************/
    public void set_hint (ViewWrapper.Hint hint) {
        tvs.set_hint (hint);
    }

    public ViewWrapper.Hint get_hint () {
        return tvs.get_hint ();
    }

    public void set_relative_id (int id) {
        this.relative_id = id;
    }

    public int get_relative_id () {
        return relative_id;
    }

    public bool get_is_current_list () {
        return is_current_list;
    }

#if 0
    /** **********************************************************
     * Drag and drop support. GenericView is a source for uris and can
     * be dragged to a playlist in the sidebar. No support for reordering
     * is implemented yet.
    ***************************************************************/
    void on_drag_begin (Gtk.Widget sender, Gdk.DragContext context) {
        dragging = true;
        lw.dragging_from_music = true;
        debug ("drag begin\n");

        Gdk.drag_abort (context, Gtk.get_current_event_time ());

        if (get_selection ().count_selected_rows () == 1) {
            drag_source_set_icon_stock (this, Gtk.Stock.DND);
        }
        else if (get_selection ().count_selected_rows () > 1) {
            drag_source_set_icon_stock (this, Gtk.Stock.DND_MULTIPLE);
        }
        else {
            return;
        }
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
        lw.dragging_from_music = false;

        debug ("drag end\n");

        //unset_rows_drag_dest ();
        Gtk.drag_dest_set (this,
                          Gtk.DestDefaults.ALL,
                          {},
                          Gdk.DragAction.COPY|
                          Gdk.DragAction.MOVE
                          );
    }
#endif
}

