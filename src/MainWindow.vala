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

        var start_window_controls = new Gtk.WindowControls (Gtk.PackType.START);

        shuffle_button = new Gtk.Button.from_icon_name ("media-playlist-shuffle-symbolic") {
            action_name = Application.ACTION_PREFIX + Application.ACTION_SHUFFLE,
            tooltip_text = _("Shuffle")
        };

        repeat_button = new Gtk.Button ();

        var queue_header = new Gtk.HeaderBar () {
            show_title_buttons = false,
            title_widget = new Gtk.Label ("")
        };
        queue_header.add_css_class (Granite.STYLE_CLASS_FLAT);
        queue_header.add_css_class (Granite.STYLE_CLASS_DEFAULT_DECORATION);
        queue_header.pack_start (start_window_controls);
        queue_header.pack_end (shuffle_button);
        queue_header.pack_end (repeat_button);

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

        var add_button_label = new Gtk.Label (_("Add Music…"));
        var add_button_box = new Gtk.Box (HORIZONTAL, 0);
        add_button_box.append (new Gtk.Image.from_icon_name ("list-add-symbolic"));
        add_button_box.append (add_button_label);

        var add_button = new Gtk.Button () {
            child = add_button_box,
            action_name = Application.ACTION_PREFIX + Application.ACTION_OPEN
        };
        add_button.add_css_class (Granite.STYLE_CLASS_FLAT);

        var queue_action_bar = new Gtk.ActionBar ();
        queue_action_bar.pack_start (add_button);
        queue_action_bar.add_css_class (Granite.STYLE_CLASS_FLAT);

        var queue = new Gtk.Grid ();
        queue.add_css_class (Granite.STYLE_CLASS_VIEW);
        queue.attach (queue_header, 0, 0);
        queue.attach (scrolled, 0, 1);
        queue.attach (queue_action_bar, 0, 2);
        queue.add_controller (drop_target);

        var error_toast = new Granite.Toast ("");

        var queue_overlay = new Gtk.Overlay () {
            child = queue
        };
        queue_overlay.add_overlay (error_toast);

        var queue_handle = new Gtk.WindowHandle () {
            child = queue_overlay
        };

        var end_window_controls = new Gtk.WindowControls (Gtk.PackType.END);

        var end_header = new Gtk.HeaderBar () {
            show_title_buttons = false,
            title_widget = new Gtk.Label ("")
        };
        end_header.add_css_class (Granite.STYLE_CLASS_FLAT);
        end_header.add_css_class (Granite.STYLE_CLASS_DEFAULT_DECORATION);
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

        drop_target.drop.connect ((target, value, x, y) => {
            if (value.type () == typeof (Gdk.FileList)) {
                var list = (Gdk.FileList)value;
                queue_files (list.get_files ());
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

    public void queue_files (SList<weak File> files) {
        File[] file_array = {};
        SList<File> file_list = null;
        foreach (unowned var file in files) {
            var file_type = file.query_file_type (FileQueryInfoFlags.NONE);
            if (file_type == FileType.DIRECTORY) {
                prepend_directory_files (file, ref file_list);
            } else {
                file_list.prepend (file);
            }
        }

        file_list.reverse ();
        foreach (unowned var file in file_list) {
            file_array += file;
        }

        PlaybackManager.get_default ().queue_files (file_array);
    }
    //Array concatenation not permitted for parameters so use a list instead
    private void prepend_directory_files (GLib.File dir, ref SList<File> file_list) {
        try {
            var enumerator = dir.enumerate_children (
                "standard::*",
                FileQueryInfoFlags.NOFOLLOW_SYMLINKS,
                null
            );

            FileInfo info = null;
            while ((info = enumerator.next_file (null)) != null) {
                var child = dir.resolve_relative_path (info.get_name ());
                if (info.get_file_type () == FileType.DIRECTORY) {
                    prepend_directory_files (child, ref file_list);
                } else {
                    file_list.prepend (child);
                }
            }
        } catch (Error e) {
            warning ("Error while enumerating children of %s: %s", dir.get_uri (), e.message);
        }
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
