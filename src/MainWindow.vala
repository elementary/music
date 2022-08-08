/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2021 elementary, Inc. (https://elementary.io)
 */

public class Music.MainWindow : Gtk.ApplicationWindow {
    private Gtk.Button repeat_button;
    private Gtk.Button shuffle_button;
    private Settings settings;

    construct {
        var playback_manager = PlaybackManager.get_default ();

        var start_window_controls = new Gtk.WindowControls (Gtk.PackType.START) {
            hexpand = true
        };

        shuffle_button = new Gtk.Button.from_icon_name ("media-playlist-shuffle-symbolic") {
            action_name = Application.ACTION_PREFIX + Application.ACTION_SHUFFLE,
            margin_end = 3,
            tooltip_text = _("Shuffle")
        };

        repeat_button = new Gtk.Button () {
            margin_end = 6
        };

        var queue_header = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        queue_header.add_css_class ("titlebar");
        queue_header.add_css_class (Granite.STYLE_CLASS_FLAT);
        queue_header.add_css_class (Granite.STYLE_CLASS_DEFAULT_DECORATION);
        queue_header.append (start_window_controls);
        queue_header.append (shuffle_button);
        queue_header.append (repeat_button);

        var queue_placeholder = new Granite.Placeholder (_("Queue is Empty")) {
            description = _("Audio files opened from Files will appear here"),
            icon = new ThemedIcon ("playlist-queue")
        };

        var queue_listbox = new Gtk.ListBox () {
            hexpand = true,
            vexpand = true
        };
        queue_listbox.bind_model (playback_manager.queue_liststore, create_queue_row);
        queue_listbox.set_placeholder (queue_placeholder);

        var scrolled = new Gtk.ScrolledWindow () {
            child = queue_listbox
        };

        var drop_target = new Gtk.DropTarget (typeof (Gdk.FileList), Gdk.DragAction.COPY);

        var queue = new Gtk.Grid ();
        queue.add_css_class (Granite.STYLE_CLASS_VIEW);
        queue.attach (queue_header, 0, 0);
        queue.attach (scrolled, 0, 1);
        queue.add_controller (drop_target);

        var error_toast = new Granite.Toast ("");

        var queue_overlay = new Gtk.Overlay () {
            child = queue
        };
        queue_overlay.add_overlay (error_toast);

        var queue_handle = new Gtk.WindowHandle () {
            child = queue_overlay
        };

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
            start_child = queue_handle,
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
        settings.changed["repeat-mode"].connect (update_repeat_button);

        update_repeat_button ();

        drop_target.on_drop.connect ((target, value, x, y) => {
            if (value.type () == typeof (Gdk.FileList)) {

                File[] files;
                foreach (unowned var file in (SList<File>) value.get_boxed ()) {
                    files += file;
                }

                playback_manager.queue_files (files);

                return true;
            }

            return false;
        });

        playback_manager.invalids_found.connect ((count) => {
            error_toast.title = ngettext (
                "%d invalid file was not added to the queue",
                "%d invalid files were not added to the queue",
                count).printf (count);
            error_toast.send_notification ();
        });

        repeat_button.clicked.connect (() => {
            var enum_step = settings.get_enum ("repeat-mode");
            if (enum_step < 2) {
                settings.set_enum ("repeat-mode", enum_step + 1);
            } else {
                settings.set_enum ("repeat-mode", 0);
            }
        });

        queue_listbox.row_activated.connect ((row) => {
            playback_manager.current_audio = ((TrackRow) row).audio_object;
        });
    }

    private void update_repeat_button () {
        switch (settings.get_string ("repeat-mode")) {
            case "disabled":
                repeat_button.icon_name = "media-playlist-no-repeat-symbolic";
                repeat_button.tooltip_text = _("Repeat None");
                break;
            case "all":
                repeat_button.icon_name = "media-playlist-repeat-symbolic";
                repeat_button.tooltip_text = _("Repeat All");
                break;
            case "one":
                repeat_button.icon_name = "media-playlist-repeat-song-symbolic";
                repeat_button.tooltip_text = _("Repeat One");
                break;
        }
    }

    private Gtk.Widget create_queue_row (GLib.Object object) {
        unowned var audio_object = (AudioObject) object;
        return new TrackRow (audio_object);
    }
}
