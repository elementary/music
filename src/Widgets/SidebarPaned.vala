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

public class Granite.Widgets.SidebarPaned : Gtk.Overlay {

    protected Gtk.Paned paned { get; private set; }
    private Gtk.EventBox left_handle = new Gtk.EventBox ();
    private Gtk.EventBox right_handle = new Gtk.EventBox ();

    private static const string HANDLE_SIZE_PROPERTY = "handle-size";
    private int handle_size = 1;

    static construct {
        install_style_property (new GLib.ParamSpecInt (HANDLE_SIZE_PROPERTY,
                                                       "Handle size",
                                                       "Width of the invisible handle",
                                                       1, 50, 12,
                                                       ParamFlags.READABLE));
    }


    /**
     * PUBLIC API
     */

    public int position {
        get {
            return this.paned.position;
        }
        set {
            this.paned.position = value;
        }
    }

    public Gtk.Widget? get_child1 () {
        return this.paned.get_child1 ();
    }

    public Gtk.Widget? get_child2 () {
        return this.paned.get_child2 ();
    }

    public void pack1 (Gtk.Widget child, bool resize = true, bool shrink = true) {
        this.paned.pack1 (child, resize, shrink);
    }

    public void pack2 (Gtk.Widget child, bool resize = true, bool shrink = true) {
        this.paned.pack2 (child, resize, shrink);
    }

    public void add1 (Gtk.Widget child) {
        this.paned.add1 (child);
    }

    public void add2 (Gtk.Widget child) {
        this.paned.add2 (child);
    }


    public SidebarPaned () {
        create_widget ();

        this.paned.get_style_context ().add_class ("sidebar-pane-separator");

        const string DEFAULT_STYLESHEET =
                        "*{-GtkPaned-handle-size: 1px;}";
        const string FALLBACK_STYLESHEET =
                        "*{background-color:shade(@bg_color,0.75);border-width:0;}";

        set_theming (this.paned, DEFAULT_STYLESHEET, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        set_theming (this.paned, FALLBACK_STYLESHEET, Gtk.STYLE_PROVIDER_PRIORITY_THEME);
    }

    /**
     * INTERNALS
     */

    private void create_widget () {
        style_get (HANDLE_SIZE_PROPERTY, out handle_size);
        this.handle_size = this.handle_size / 2;

        this.paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
        this.paned.expand = true;

        this.add (this.paned);

        Gdk.RGBA transparent = { 0.0, 0.0, 0.0, 0.0 };
        this.override_background_color (0, transparent);

        setup_handle (left_handle);
        setup_handle (right_handle);

        this.paned.notify["position"].connect (on_paned_position_update);

        this.position = 10;

        show_all ();
    }

    private void setup_handle (Gtk.EventBox handle) {
        handle.visible_window = true;
        handle.hexpand = false;
        handle.vexpand = true;
        handle.halign = Gtk.Align.START;
        handle.valign = Gtk.Align.FILL;

        Gdk.RGBA transparent = { 0.0, 0.0, 0.0, 0.0 };
        handle.override_background_color (0, transparent);
        this.add_overlay (handle);

        handle.set_size_request (this.handle_size, -1);

        handle.add_events (Gdk.EventMask.POINTER_MOTION_MASK
                           | Gdk.EventMask.BUTTON_PRESS_MASK
                           | Gdk.EventMask.BUTTON_RELEASE_MASK
                           | Gdk.EventMask.LEAVE_NOTIFY_MASK);

        handle.motion_notify_event.connect (on_handle_motion_notify);
        handle.leave_notify_event.connect (on_handle_leave_notify);
        handle.button_press_event.connect (on_handle_button_press);
        handle.button_release_event.connect (on_handle_button_release);
    }

    private static void set_theming (Gtk.Widget widget, string stylesheet, int priority) {
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


    private bool on_resize_mode = false;

    private void on_paned_position_update () {
        update_virtual_handle_position ();
    }

    private bool update_virtual_handle_position () {
        int new_pos = this.position;
        new_pos = new_pos > 0 ? new_pos : 0;
        debug ("Updating virtual handle position: new_x = %i", new_pos);

        // TODO: Clamp coordinates to valid values

        this.right_handle.margin_left = new_pos + this.paned.get_handle_window ().get_width ();
        this.left_handle.margin_left = new_pos - this.handle_size;

        return true;
    }

    private bool on_handle_button_press (Gtk.Widget handle, Gdk.EventButton e) {
        if (!this.on_resize_mode && e.button == Gdk.BUTTON_PRIMARY) {
            this.on_resize_mode = true;

            // Tell GDK that we're grabbing the virtual handle
            // so that it locks events comming from different sources
            // for this window
            Gtk.grab_add (handle);
        }

        return true;
    }

    private bool on_handle_button_release (Gtk.Widget handle, Gdk.EventButton e) {
        this.on_resize_mode = false;
        Gtk.grab_remove (handle);

        return true;
    }

    private bool on_handle_motion_notify (Gdk.EventMotion e) {
        if (this.on_resize_mode) {
            int x, y;
            this.paned.get_window ().get_device_position (e.device, out x, out y, null);
            this.position = x;
        }
        else {
            this.get_window ().set_cursor (new Gdk.Cursor (Gdk.CursorType.SB_H_DOUBLE_ARROW));
        }
 
        return true;
    }

    private bool on_handle_leave_notify () {
        if (!this.on_resize_mode)
            this.get_window ().set_cursor (null);

        return true;
    }
}