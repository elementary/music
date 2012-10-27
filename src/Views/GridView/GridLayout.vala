/*-
 * Copyright (c) 2012 Noise Developers
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
 * Authored by: Victor Eduardo <victoreduardm@gmail.com>
 */

public abstract class Noise.GridLayout : ViewTextOverlay {

	public ViewWrapper parent_view_wrapper { get; protected set; }

    private FastGrid icon_view;
    private Gtk.ScrolledWindow scroll;

    // Spacing Workarounds
#if !GTK_ICON_VIEW_BUG_IS_FIXED
    private Gtk.EventBox vpadding_box;
    private Gtk.EventBox hpadding_box;
#endif

    private const string STYLESHEET = "*:selected{background-color:@transparent;}";
    private const int ITEM_PADDING = 0;
    private const int MIN_SPACING = 6;
    private const int ITEM_WIDTH = Icons.ALBUM_VIEW_IMAGE_SIZE;

    public GridLayout (ViewWrapper view_wrapper) {
		parent_view_wrapper = view_wrapper;
        build_ui ();
        clear_objects ();

        icon_view.set_search_func (search_func);
    }

    protected abstract void item_activated (Object? object);
    protected abstract Value? val_func (int row, int column, Object o);
    protected abstract int compare_func (Object a, Object b);
	protected abstract void search_func (string search, HashTable<int, Object> table, ref HashTable<int, Object> showing);

    protected void add_objects (Gee.Collection<Object> objects) {
        icon_view.add_objects (objects);
    }

    protected void do_search (string? search) {
        icon_view.do_search (search);
    }

    protected void remove_objects (Gee.HashSet<Object> objects) {
        icon_view.remove_objects (objects);
    }

    protected void clear_objects () {
        icon_view.set_table (new HashTable<int, Album> (null, null), true);
    }

    protected List<unowned Object> get_objects () {
        return icon_view.get_table ().get_values ();
    }

    protected List<unowned Object> get_visible_objects () {
        return icon_view.get_visible_table ().get_values ();
    }


    private void build_ui () {
        scroll = new Gtk.ScrolledWindow (null, null);
        scroll.set_policy (Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
        add (scroll);

        icon_view = new FastGrid ();
        icon_view.set_compare_func (compare_func);
        icon_view.set_value_func (val_func);

        icon_view.set_columns (-1);

// Should be defined for GTK+ 3.4.3 or later
#if !GTK_ICON_VIEW_BUG_IS_FIXED

        var wrapper_vbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        var wrapper_hbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);

        vpadding_box = new Gtk.EventBox();
        hpadding_box = new Gtk.EventBox();

        vpadding_box.get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
        hpadding_box.get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
        this.get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);

        vpadding_box.get_style_context().add_class (Granite.STYLE_CLASS_CONTENT_VIEW);
        hpadding_box.get_style_context().add_class (Granite.STYLE_CLASS_CONTENT_VIEW);
        this.get_style_context().add_class (Granite.STYLE_CLASS_CONTENT_VIEW);

        vpadding_box.set_size_request (-1, MIN_SPACING + ITEM_PADDING);
        hpadding_box.set_size_request (MIN_SPACING + ITEM_PADDING, -1);

        vpadding_box.button_press_event.connect ( () => {
            item_activated (null);
            return false;
        });

        hpadding_box.button_press_event.connect ( () => {
            item_activated (null);
            return false;
        });


        wrapper_vbox.pack_start (vpadding_box, false, false, 0);
        wrapper_vbox.pack_start (wrapper_hbox, true, true, 0);
        wrapper_hbox.pack_start (hpadding_box, false, false, 0);
        wrapper_hbox.pack_start (icon_view, true, true, 0);

        scroll.add_with_viewport (wrapper_vbox);

        icon_view.margin = 0;

#else

        scroll.add (icon_view);
        icon_view.margin = MIN_SPACING;

#endif


        icon_view.item_width = ITEM_WIDTH;
        icon_view.item_padding = ITEM_PADDING;
        icon_view.spacing = 0;
        icon_view.row_spacing = MIN_SPACING;
        icon_view.column_spacing = MIN_SPACING;

        icon_view.add_events (Gdk.EventMask.POINTER_MOTION_MASK);
        icon_view.motion_notify_event.connect (on_motion_notify);
        icon_view.scroll_event.connect (on_scroll_event);

        //icon_view.button_press_event.connect (on_button_press);
        icon_view.button_release_event.connect (on_button_release);
        icon_view.item_activated.connect (on_item_activated);

        int MIN_N_ITEMS = 2; // we will allocate horizontal space for at least two items
        int TOTAL_ITEM_WIDTH = ITEM_WIDTH + 2 * ITEM_PADDING;
        int TOTAL_MARGIN = MIN_N_ITEMS * (MIN_SPACING + ITEM_PADDING);
        int MIDDLE_SPACE = MIN_N_ITEMS * MIN_SPACING;

        scroll.min_content_width = MIN_N_ITEMS * TOTAL_ITEM_WIDTH + TOTAL_MARGIN + MIDDLE_SPACE;

        set_theming ();
        scroll.get_hadjustment ().changed.connect (on_resize);

        show_all ();
    }

    private void set_theming () {
        // Change background color
        Granite.Widgets.Utils.set_theming (icon_view, STYLESHEET, null, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
    }

    private void on_item_activated (Gtk.TreePath? path) {
        if (path == null)
            item_activated (null);

        var obj = icon_view.get_object_from_index (int.parse (path.to_string ()));
        item_activated (obj);
    }

    private bool on_button_release (Gdk.EventButton ev) {
        if (ev.type == Gdk.EventType.BUTTON_RELEASE && ev.button == 1) {
            Gtk.TreePath path;
            Gtk.CellRenderer cell;

            icon_view.get_item_at_pos ((int)ev.x, (int)ev.y, out path, out cell);

            // blank area
            if (path == null) {
                item_activated (null);
                return false;
            }

            var obj = icon_view.get_object_from_index (int.parse (path.to_string ()));
            item_activated (obj);
        }

        return false;
    }

    private inline void set_cursor (int x, int y) {
        Gtk.TreePath path;
        Gtk.CellRenderer cell;

        icon_view.get_item_at_pos (x, y, out path, out cell);

        if (path == null) // blank area
            icon_view.get_window ().set_cursor (null);
        else
            icon_view.get_window ().set_cursor (new Gdk.Cursor (Gdk.CursorType.HAND1));

    }

    private bool on_motion_notify (Gdk.EventMotion ev) {
        set_cursor ((int)ev.x, (int)ev.y);
        return false;
    }

    private bool on_scroll_event (Gdk.EventScroll ev) {
        set_cursor ((int)ev.x, (int)ev.y);
        return false;
    }


    /**
     * Smart spacing
     */
    private bool waiting_resize = false;

    private void on_resize () {
        if (waiting_resize)
            return;

        waiting_resize = true;

        int priority = parent_view_wrapper.is_current_wrapper ? Priority.HIGH_IDLE : Priority.LOW;

        Idle.add_full (priority , () => {
            update_spacing ();
            waiting_resize = false;
            return false;
        });
    }

    private int get_current_width () {
        return (int) scroll.get_hadjustment ().page_size;
    }

    private void update_spacing () {
        if (!visible)
            return;

        int new_width = get_current_width ();

        int TOTAL_WIDTH = new_width; // width of view wrapper, not scrolled window!
        int TOTAL_ITEM_WIDTH = ITEM_WIDTH + 2 * ITEM_PADDING;

        // Calculate the number of columns
        float n = (float)(TOTAL_WIDTH - MIN_SPACING) / (float)(TOTAL_ITEM_WIDTH + MIN_SPACING);
        int n_columns = Numeric.lowest_int_from_float (n);

        if (n_columns < 1)
            return;

        icon_view.set_columns (n_columns);

        // We don't want to adjust the spacing if the row is not full
        if (icon_view.get_table ().size () < n_columns)
            return;

        // You're not supposed to understand this.
        float spacing = (float)(TOTAL_WIDTH - n_columns * (ITEM_WIDTH + 1) - 2 * n_columns * ITEM_PADDING) / (float)(n_columns + 1);
        int new_spacing = Numeric.int_from_float (spacing);

        if (new_spacing < 0)
            return;

        if (TOTAL_WIDTH < 750)
            -- new_spacing;

        // apply new spacing
        set_spacing (new_spacing);
    }

    private void set_spacing (int spacing) {
        if (spacing < 0)
            return;

        int item_offset = ITEM_PADDING / icon_view.columns;
        int item_spacing = spacing - ((item_offset > 0) ? item_offset : 1);

        icon_view.set_column_spacing (item_spacing);
        icon_view.set_row_spacing (item_spacing);

        int margin_width = spacing + ITEM_PADDING;

#if GTK_ICON_VIEW_BUG_IS_FIXED
        icon_view.set_margin (margin_width);
#else
        vpadding_box.set_size_request (-1, margin_width);
        hpadding_box.set_size_request (margin_width, -1);
#endif
    }
}
