/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2021 elementary, Inc. (https://elementary.io)
 */

public class Music.MainWindow : Gtk.ApplicationWindow {
    private Gtk.Button repeat_button;
    private Gtk.Button shuffle_button;
    private Settings settings;
    private Gtk.SearchEntry search_entry;
    private Gtk.Revealer search_revealer;

    construct {
        var playback_manager = PlaybackManager.get_default ();

        var start_window_controls = new Gtk.WindowControls (Gtk.PackType.START);

        shuffle_button = new Gtk.Button.from_icon_name ("media-playlist-shuffle-symbolic") {
            action_name = Application.ACTION_PREFIX + Application.ACTION_SHUFFLE,
            tooltip_text = _("Shuffle")
        };

        repeat_button = new Gtk.Button ();

        search_entry = new Gtk.SearchEntry () {
            placeholder_text = _("Search titles in playlist")
        };

        search_revealer = new Gtk.Revealer () {
            child = search_entry
        };

        playback_manager.bind_property (
            "has-items", search_revealer, "reveal-child", DEFAULT | SYNC_CREATE
        );
        var queue_header = new Gtk.HeaderBar () {
            show_title_buttons = false,
            title_widget = search_revealer
        };
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

        var add_button_label = new Gtk.Label (_("Open Files…"));

        var add_button_box = new Gtk.Box (HORIZONTAL, 0);
        add_button_box.append (new Gtk.Image.from_icon_name ("document-open-symbolic"));
        add_button_box.append (add_button_label);

        var add_button = new Gtk.Button () {
            child = add_button_box,
        };
        add_button.add_css_class (Granite.STYLE_CLASS_FLAT);

        add_button_label.mnemonic_widget = add_button;

        var queue_action_bar = new Gtk.ActionBar ();
        queue_action_bar.pack_start (add_button);

        var queue = new Adw.ToolbarView () {
            bottom_bar_style = RAISED,
            content = scrolled
        };
        queue.add_controller (drop_target);
        queue.add_css_class (Granite.STYLE_CLASS_VIEW);
        queue.add_top_bar (queue_header);
        queue.add_bottom_bar (queue_action_bar);

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

                File[] file_array = {};
                foreach (unowned var file in list.get_files ()) {
                    file_array += file;
                }

                var files_to_play = Application.loop_through_files (file_array);
                PlaybackManager.get_default ().queue_files (files_to_play);

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

        add_button.clicked.connect (action_open);

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

        search_entry.search_changed.connect (() => {
            int pos = playback_manager.find_title (search_entry.text);
            if (pos > 0) {
                queue_listbox.select_row (queue_listbox.get_row_at_index (pos));
                var adj = scrolled.vadjustment;
                // Search entry is hidden if n_items is zero so no need to check
                var ratio = (double)pos / (double)playback_manager.n_items;
                adj.@value = adj.upper * ratio;
            }
        });

        search_entry.activate.connect (() => {
            var selected = queue_listbox.get_selected_row ();
            if (selected != null) {
                selected.activate ();
            }
        });
    }

    public void start_search () {
        if (search_revealer.child_revealed) {
            search_entry.grab_focus ();
        }
    }

    private void action_open () {
        var all_files_filter = new Gtk.FileFilter () {
            name = _("All files"),
        };
        all_files_filter.add_pattern ("*");

        var music_files_filter = new Gtk.FileFilter () {
            name = _("Music files"),
        };
        music_files_filter.add_mime_type ("audio/*");

        var filter_model = new ListStore (typeof (Gtk.FileFilter));
        filter_model.append (all_files_filter);
        filter_model.append (music_files_filter);

        var file_dialog = new Gtk.FileDialog () {
            accept_label = _("Open"),
            default_filter = music_files_filter,
            filters = filter_model,
            modal = true,
            title = _("Open audio files")
        };

        file_dialog.open_multiple.begin (this, null, (obj, res) => {
            try {
                var files = file_dialog.open_multiple.end (res);

                File[] file_array = {};
                for (int i = 0; i < files.get_n_items (); i++) {
                    file_array += (File)(files.get_item (i));
                }

                var files_to_play = Application.loop_through_files (file_array);
                PlaybackManager.get_default ().queue_files (files_to_play);
            } catch (Error e) {
                if (e.matches (Gtk.DialogError.quark (), Gtk.DialogError.DISMISSED)) {
                    return;
                }

                var dialog = new Granite.MessageDialog (
                    "Couldn't add audio files",
                    e.message,
                    new ThemedIcon ("document-open")
                ) {
                    badge_icon = new ThemedIcon ("dialog-error"),
                    modal = true,
                    transient_for = this
                };
                dialog.present ();
                dialog.response.connect (dialog.destroy);
            }
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
