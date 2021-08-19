/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2021 elementary, Inc. (https://elementary.io)
 */

public class Music.MainWindow : Hdy.ApplicationWindow {
    construct {
        Hdy.init ();

        var queue_header = new Hdy.HeaderBar () {
            hexpand = true,
            show_close_button = true
        };

        unowned var queue_header_context = queue_header.get_style_context ();
        queue_header_context.add_class (Granite.STYLE_CLASS_DEFAULT_DECORATION);
        queue_header_context.add_class (Gtk.STYLE_CLASS_FLAT);

        var queue_placeholder = new Granite.Widgets.AlertView (
            _("Queue is Empty"),
            _("Audio files opened from Files will appear here"),
            "playlist-queue"
        );
        queue_placeholder.show_all ();

        var queue_listbox = new Gtk.ListBox () {
            expand = true
        };
        queue_listbox.bind_model (PlaybackManager.get_default ().queue_liststore, create_queue_row);
        queue_listbox.set_placeholder (queue_placeholder);

        var queue = new Gtk.Grid ();
        queue.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        queue.attach (queue_header, 0, 0);
        queue.attach (queue_listbox, 0, 1);

        var headerbar = new Hdy.HeaderBar () {
            hexpand = true,
            show_close_button = true
        };

        unowned var header_context = headerbar.get_style_context ();
        header_context.add_class (Granite.STYLE_CLASS_DEFAULT_DECORATION);
        header_context.add_class (Gtk.STYLE_CLASS_FLAT);

        var now_playing_view = new NowPlayingView () {
            margin = 12,
            margin_bottom = 24,
            valign = Gtk.Align.CENTER,
            vexpand = true
        };

        var now_playing = new Gtk.Grid ();
        now_playing.attach (headerbar, 0, 0);
        now_playing.attach (now_playing_view, 0, 1);

        var now_playing_handle = new Hdy.WindowHandle ();
        now_playing_handle.add (now_playing);

        var paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL) {
            position = 350
        };
        paned.pack1 (queue, true, false);
        paned.pack2 (now_playing_handle, false, false);

        add (paned);

        var header_group = new Hdy.HeaderGroup ();
        header_group.add_header_bar (queue_header);
        header_group.add_header_bar (headerbar);
    }

    private Gtk.Widget create_queue_row (GLib.Object object) {
        unowned var audio_object = (AudioObject) object;

        var label = new Gtk.Label (audio_object.title) {
            ellipsize = Pango.EllipsizeMode.MIDDLE,
            xalign = 0
        };

        var grid = new Gtk.Grid () {
            margin = 6,
            margin_start = 12,
            margin_end = 12,
            sensitive = false
        };
        grid.add (label);
        grid.show_all ();

        audio_object.bind_property ("title", label, "label");

        return grid;
    }
}
