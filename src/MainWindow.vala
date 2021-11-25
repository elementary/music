/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2021 elementary, Inc. (https://elementary.io)
 */

public class Music.MainWindow : Gtk.ApplicationWindow {
    construct {
        // try {
        //     var css_provider = new Gtk.CssProvider ();
        //     css_provider.load_from_data ("@define-color accent_color @ORANGE_500;");

        //     Gtk.StyleContext.add_provider_for_display (Gdk.Display.get_default (), css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        // } catch (Error e) {
        //     critical ("Can't set accent color: %s", e.message);
        // }

        var queue_header = new Gtk.HeaderBar () {
            css_classes = {"default-decoration", "flat"},
            hexpand = true,
            show_title_buttons = true
        };

        // var queue_placeholder = new Granite.Widgets.AlertView (
        //     _("Queue is Empty"),
        //     _("Audio files opened from Files will appear here"),
        //     "playlist-queue"
        // );

        var queue_listbox = new Gtk.ListBox () {
            hexpand = true,
            vexpand = true
        };
        queue_listbox.bind_model (PlaybackManager.get_default ().queue_liststore, create_queue_row);
        // queue_listbox.set_placeholder (queue_placeholder);

        var scrolled = new Gtk.ScrolledWindow () {
            child = queue_listbox
        };

        var queue = new Gtk.Grid () {
            css_classes = {"view"}
        };
        queue.attach (queue_header, 0, 0);
        queue.attach (scrolled, 0, 1);

        var headerbar = new Gtk.HeaderBar () {
            css_classes = {"default-decoration", "flat"},
            hexpand = true,
            show_title_buttons = true
        };

        var now_playing_view = new NowPlayingView () {
            margin_top = 12,
            margin_end = 12,
            margin_bottom = 24,
            margin_start = 12,
            valign = Gtk.Align.CENTER,
            vexpand = true
        };

        var now_playing = new Gtk.Grid ();
        now_playing.attach (headerbar, 0, 0);
        now_playing.attach (now_playing_view, 0, 1);

        // var now_playing_handle = new Hdy.WindowHandle ();
        // now_playing_handle.add (now_playing);

        var paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL) {
            position = 350,
            start_child = queue,
            resize_end_child = false,
            resize_start_child = true,
            shrink_end_child = false,
            shrink_start_child = false
        };
        paned.set_end_child (now_playing);

        child = paned;

        // var header_group = new Hdy.HeaderGroup ();
        // header_group.add_header_bar (queue_header);
        // header_group.add_header_bar (headerbar);
    }

    private Gtk.Widget create_queue_row (GLib.Object object) {
        unowned var audio_object = (AudioObject) object;
        return new TrackRow (audio_object);
    }
}
