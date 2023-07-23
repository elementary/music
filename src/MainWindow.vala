/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2021 elementary, Inc. (https://elementary.io)
 */

public class Music.MainWindow : Gtk.ApplicationWindow {
    private Gtk.Button back_button;
    private QueueView queue_view;
    private Gtk.Stack stack;
    private Settings settings;

    construct {
        var start_window_controls = new Gtk.WindowControls (Gtk.PackType.START);

        back_button = new Gtk.Button.with_label (_("Library"));
        back_button.add_css_class (Granite.STYLE_CLASS_BACK_BUTTON);

        var queue_button = new Gtk.Button.from_icon_name ("view-list-symbolic");

        var start_header = new Gtk.HeaderBar () {
            show_title_buttons = false,
            title_widget = new Gtk.Label ("")
        };
        start_header.add_css_class (Granite.STYLE_CLASS_FLAT);
        start_header.pack_start (start_window_controls);
        start_header.pack_start (back_button);
        start_header.pack_end (queue_button);

        queue_view = new QueueView ();

        var library_view = new LibraryView ();

        stack = new Gtk.Stack ();
        stack.add_child (queue_view);
        stack.add_child (library_view);
        stack.visible_child = library_view;

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

        update_header_buttons ();
        stack.notify["visible-child"].connect (update_header_buttons);

        queue_button.clicked.connect (() => {
            stack.visible_child = queue_view;
        });

        back_button.clicked.connect (() => {
            stack.visible_child = library_view;
        });
    }

    private void update_header_buttons () {
        back_button.visible = stack.visible_child == queue_view;
    }
}
