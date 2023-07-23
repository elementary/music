/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2021 elementary, Inc. (https://elementary.io)
 */

public class Music.MainWindow : Gtk.ApplicationWindow {
    private Gtk.Stack stack;
    private Settings settings;

    construct {
        var start_window_controls = new Gtk.WindowControls (Gtk.PackType.START);

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

        var queue_view = new QueueView ();

        var library_view = new LibraryView ();

        stack = new Gtk.Stack ();
        stack.add_titled (library_view, null, _("Library"));
        stack.add_titled (queue_view, null, _("Play Queue"));

        stack_switcher.stack = stack;

        var start_box = new Gtk.Box (VERTICAL, 0);
        start_box.add_css_class (Granite.STYLE_CLASS_VIEW);
        start_box.append (start_header);
        start_box.append (stack);

        var end_window_controls = new Gtk.WindowControls (Gtk.PackType.END);

        var end_header = new Gtk.HeaderBar () {
            show_title_buttons = false,
            title_widget = new Gtk.Label ("")
        };
        end_header.add_css_class (Granite.STYLE_CLASS_FLAT);
        end_header.pack_end (end_window_controls);

        var now_playing_view = new NowPlayingView () {
            margin_top = 12,
            margin_end = 12,
            margin_bottom = 24,
            margin_start = 12,
            vexpand = true
        };

        var now_playing = new Gtk.Box (VERTICAL, 0);
        now_playing.append (end_header);
        now_playing.append (now_playing_view);

        var now_playing_handle = new Gtk.WindowHandle () {
            child = now_playing
        };

        var paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL) {
            start_child = start_box,
            end_child = now_playing_handle,
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
