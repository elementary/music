// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012 Granite Developers (http://launchpad.net/granite)
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

public class Granite.Widgets.SidebarPaned : Gtk.Overlay, Gtk.Orientable {

    protected Gtk.Paned paned { get; private set; }
    private Gtk.EventBox? handle = null;

    private static const string STYLE_PROP_HANDLE_SIZE = "handle-size";
    private bool on_resize_mode = false;
    private Gdk.Cursor? arrow_cursor = null;

    protected int handle_size {
        get {
            int size;
            style_get (STYLE_PROP_HANDLE_SIZE, out size);
            return size;
        }
    }

    static construct {
        install_style_property (new ParamSpecInt (STYLE_PROP_HANDLE_SIZE,
                                                  "Handle size",
                                                  "Width of the invisible handle",
                                                  1, 50, 12,
                                                  ParamFlags.READABLE));
    }

    /**
     * PUBLIC API
     */

    public Gtk.Orientation orientation {
        get { return this.paned.orientation; }
        set { set_orientation_internal (value); }
    }

    public int position {
        get { return this.paned.position; }
        set { this.paned.position = value; }
    }

    public bool position_set {
        get { return this.paned.position_set; }
        set { this.paned.position_set = value; }    
    }

    public void pack1 (Gtk.Widget child, bool resize, bool shrink) {
        this.paned.pack1 (child, resize, shrink);
    }

    public void pack2 (Gtk.Widget child, bool resize, bool shrink) {
        this.paned.pack2 (child, resize, shrink);
    }

    public void add1 (Gtk.Widget child) {
        this.paned.add1 (child);
    }

    public void add2 (Gtk.Widget child) {
        this.paned.add2 (child);
    }

    public unowned Gtk.Widget? get_child1 () {
        return this.paned.get_child1 ();
    }

    public unowned Gtk.Widget? get_child2 () {
        return this.paned.get_child2 ();
    }

    public unowned Gdk.Window get_handle_window () {
        return this.handle.get_window ();
    }

    public SidebarPaned () {
        create_widget ();

        this.paned.get_style_context ().add_class ("sidebar-pane-separator");

        const string DEFAULT_STYLESHEET = """
            .sidebar-pane-separator {
                -GtkPaned-handle-size: 1px;
            }
        """;

        const string FALLBACK_STYLESHEET = """
            GraniteWidgetsSidebarPaned .pane-separator {
                background-color: shade (@bg_color, 0.75);
                border-width: 0;
            }
        """;

        set_theming (this.paned, DEFAULT_STYLESHEET, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        set_theming (this.paned, FALLBACK_STYLESHEET, Gtk.STYLE_PROVIDER_PRIORITY_THEME);
    }


    /**
     * INTERNALS
     */

    private void create_widget () {
        this.push_composite_child ();
        this.paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
        this.paned.set_composite_name ("paned");
        this.pop_composite_child ();

        this.paned.expand = true;

        this.add (this.paned);

        Gdk.RGBA transparent = { 0.0, 0.0, 0.0, 0.0 };
        this.override_background_color (0, transparent);

        setup_handle ();

        this.paned.notify["position"].connect (on_paned_position_update);
        this.paned.size_allocate.connect_after (on_paned_size_allocate);

        // Use POINTER_MOTION_HINT_MASK for performance reasons. It reduces
        // the amount of motion events emmited.
        this.add_events (Gdk.EventMask.POINTER_MOTION_MASK
                         | Gdk.EventMask.POINTER_MOTION_HINT_MASK);

        this.position = -1;
        this.orientation = Gtk.Orientation.HORIZONTAL;

        show_all ();
    }

    private void setup_handle () {
        this.push_composite_child ();
        this.handle = new Gtk.EventBox ();
        this.handle.set_composite_name ("handle");
        this.pop_composite_child ();

        Gdk.RGBA transparent = { 0.0, 0.0, 0.0, 0.0 };
        this.handle.override_background_color (0, transparent);

        this.add_overlay (handle);

        this.handle.add_events (Gdk.EventMask.BUTTON_PRESS_MASK
                               | Gdk.EventMask.BUTTON_RELEASE_MASK
                               | Gdk.EventMask.ENTER_NOTIFY_MASK
                               | Gdk.EventMask.LEAVE_NOTIFY_MASK);

        this.handle.enter_notify_event.connect (on_handle_enter_notify);
        this.handle.leave_notify_event.connect (on_handle_leave_notify);
        this.handle.button_press_event.connect (on_handle_button_press);
        this.handle.button_release_event.connect (on_handle_button_release);
        this.handle.grab_broken_event.connect (on_handle_grab_broken);
    }

    protected static void set_theming (Gtk.Widget widget, string stylesheet, int priority) {
        var css_provider = new Gtk.CssProvider ();

        try {
            css_provider.load_from_data (stylesheet, -1);
        }
        catch (Error e) {
            warning (e.message);
            return_if_reached ();
        }

        widget.get_style_context ().add_provider (css_provider, priority);
    }

    private void set_orientation_internal (Gtk.Orientation orientation) {
        this.paned.orientation = orientation;
        bool horizontal = orientation == Gtk.Orientation.HORIZONTAL;

        this.handle.hexpand = !horizontal;
        this.handle.vexpand = horizontal;
        this.handle.set_size_request (0, 0);

        if (horizontal) {
            this.arrow_cursor = new Gdk.Cursor (Gdk.CursorType.SB_H_DOUBLE_ARROW);
            this.handle.margin_top = 0;
            this.handle.halign = Gtk.Align.START;
            this.handle.valign = Gtk.Align.FILL;
        } else {
            this.arrow_cursor = new Gdk.Cursor (Gdk.CursorType.SB_V_DOUBLE_ARROW);
            this.handle.margin_left = 0;
            this.handle.halign = Gtk.Align.FILL;
            this.handle.valign = Gtk.Align.START;
        }

        on_paned_size_allocate ();
        update_virtual_handle_position ();

        var window = this.get_window ();
        if (window != null && window.get_cursor () != null)
            set_arrow_cursor (true);
    }

    private void on_paned_position_update () {
        update_virtual_handle_position ();
    }

    private void on_paned_size_allocate () {
        int size = this.handle_size;
        bool horizontal = this.orientation == Gtk.Orientation.HORIZONTAL;

        // GtkPaned's handle disappears when one of its children is hidden, destroyed,
        // or simply hasn't been packed yet. The virtual handle reproduces that behavior.
        var paned_handle = this.paned.get_handle_window ();
        if (paned_handle != null) {
            this.handle.visible = paned_handle.is_visible ();
            size += horizontal ? paned_handle.get_width () : paned_handle.get_height ();
        }

        if (horizontal)
            this.handle.set_size_request (size, -1);
        else
            this.handle.set_size_request (-1, size);

        if (!this.handle.visible)
            set_arrow_cursor (false);
    }

    private void update_virtual_handle_position () {
        int new_pos = this.position - this.handle_size / 2;
        new_pos = new_pos > 0 ? new_pos : 0;

        if (orientation == Gtk.Orientation.HORIZONTAL)
            this.handle.margin_left = new_pos;
        else
            this.handle.margin_top = new_pos;
    }

    public override bool motion_notify_event (Gdk.EventMotion e) {
        var window = this.paned.get_window ();
        return_val_if_fail (window != null, false);

        int x, y;
        window.get_device_position (e.device, out x, out y, null);

        if (this.on_resize_mode) {
            int pos = (this.orientation == Gtk.Orientation.HORIZONTAL) ? x : y;

            if (this.paned.get_realized () && this.paned.get_mapped () && this.paned.position_set)
                pos = pos.clamp (this.paned.min_position, this.paned.max_position);

            this.position = pos;
        }

        return false;
    }

    /**
     * Handle's event callbacks
     */

    private bool on_handle_button_press (Gdk.EventButton e) {
        if (!this.on_resize_mode && e.button == Gdk.BUTTON_PRIMARY) {
            this.on_resize_mode = true;
            Gtk.grab_add (this.handle);
        }

        return true;
    }

    private bool on_handle_button_release (Gdk.EventButton e) {
        this.on_resize_mode = false;
        Gtk.grab_remove (this.handle);

        return true;
    }

    private bool on_handle_grab_broken () {
        this.on_resize_mode = false;
        set_arrow_cursor (false);
        return false;
    }

    private bool on_handle_enter_notify (Gdk.EventCrossing event) {
        set_arrow_cursor (true);
        return false;
    }

    private bool on_handle_leave_notify (Gdk.EventCrossing event) {
        if (!this.on_resize_mode)
            set_arrow_cursor (false);

        return false;
    }

    private void set_arrow_cursor (bool use_arrow) {
        var window = this.get_window ();
        if (window != null)
            window.set_cursor (use_arrow ? arrow_cursor : null);
    }
}
