/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2021 elementary, Inc. (https://elementary.io)
 */

public class Music.MainWindow : Gtk.ApplicationWindow {
    construct {
        var css_provider = new Gtk.CssProvider ();
        css_provider.load_from_data ("@define-color accent_color @ORANGE_500;".data);

        Gtk.StyleContext.add_provider_for_display (Gdk.Display.get_default (), css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        var start_window_controls = new Gtk.WindowControls (Gtk.PackType.START);

        var queue_header = new Gtk.WindowHandle () {
            child = start_window_controls
        };
        queue_header.add_css_class ("titlebar");
        queue_header.add_css_class (Granite.STYLE_CLASS_FLAT);
        queue_header.add_css_class (Granite.STYLE_CLASS_DEFAULT_DECORATION);

        var queue_placeholder = new Granite.Widgets.AlertView (
            _("Queue is Empty"),
            _("Audio files opened from Files will appear here"),
            "playlist-queue"
        );

        var queue_listbox = new Gtk.ListBox () {
            hexpand = true,
            vexpand = true
        };
        queue_listbox.bind_model (PlaybackManager.get_default ().queue_liststore, create_queue_row);
        queue_listbox.set_placeholder (queue_placeholder);

        var scrolled = new Gtk.ScrolledWindow () {
            child = queue_listbox
        };

        var queue = new Gtk.Grid ();
        queue.add_css_class (Granite.STYLE_CLASS_VIEW);
        queue.attach (queue_header, 0, 0);
        queue.attach (scrolled, 0, 1);

        var end_window_controls = new Gtk.WindowControls (Gtk.PackType.END) {
            halign = Gtk.Align.END
        };
        end_window_controls.add_css_class ("titlebar");
        end_window_controls.add_css_class (Granite.STYLE_CLASS_FLAT);
        end_window_controls.add_css_class (Granite.STYLE_CLASS_DEFAULT_DECORATION);

        var now_playing_view = new NowPlayingView () {
            margin_top = 12,
            margin_end = 12,
            margin_bottom = 24,
            margin_start = 12,
            vexpand = true
        };

        var now_playing = new Gtk.Grid ();
        now_playing.attach (end_window_controls, 0, 0);
        now_playing.attach (now_playing_view, 0, 1);

        var now_playing_handle = new Gtk.WindowHandle () {
            child = now_playing
        };

        var paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL) {
            position = 350,
            start_child = queue,
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
    }

    private Gtk.Widget create_queue_row (GLib.Object object) {
        unowned var audio_object = (AudioObject) object;
        return new TrackRow (audio_object);
    }
}
