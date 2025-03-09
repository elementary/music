/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2021 elementary, Inc. (https://elementary.io)
 */

public class Music.MainWindow : Gtk.ApplicationWindow {
    private Settings settings;

    construct {
        var start_window_controls = new Gtk.WindowControls (START);

        var stack_switcher = new Gtk.StackSwitcher () {
            hexpand = false
        };
        ((Gtk.BoxLayout)stack_switcher.get_layout_manager ()).homogeneous = true;

        var start_header = new Gtk.HeaderBar () {
            show_title_buttons = false,
            title_widget = stack_switcher
        };
        start_header.add_css_class (Granite.STYLE_CLASS_FLAT);
        start_header.pack_start (start_window_controls);

        var library_view = new LibraryView ();

        var now_playing_view = new NowPlayingView () {
            margin_top = 12,
            margin_end = 12,
            margin_bottom = 24,
            margin_start = 12,
            vexpand = true
        };

        var now_playing_handle = new Gtk.WindowHandle () {
            child = now_playing_view
        };

        var stack = new Gtk.Stack ();
        stack.add_titled (library_view, null, _("Library"));
        stack.add_titled (now_playing_handle, null, _("Now Playing"));

        stack_switcher.stack = stack;

        var start_box = new Gtk.Box (VERTICAL, 0);
        start_box.add_css_class (Granite.STYLE_CLASS_VIEW);
        start_box.append (start_header);
        start_box.append (stack);

        var queue_view = new QueueView ();

        var paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL) {
            start_child = start_box,
            end_child = queue_view,
            resize_end_child = false,
            shrink_end_child = false,
            shrink_start_child = false
        };

        child = paned;

        // We need to hide the title area for the split headerbar
        var null_title = new Gtk.Grid () {
            visible = false
        };
        set_titlebar (null_title);

        settings = new Settings ("io.elementary.music");
        settings.bind ("pane-position", paned, "position", SettingsBindFlags.DEFAULT);
    }
}
