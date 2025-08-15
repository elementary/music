/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2021 elementary, Inc. (https://elementary.io)
 */

public class Music.MainWindow : Gtk.ApplicationWindow {
    private const string ACTION_PREFIX = "win.";
    private const string ACTION_OPEN = "action-open";
    private const string ACTION_SAVE_M3U_PLAYLIST = "action-save-m3u-playlist";

    private Granite.Placeholder queue_placeholder;
    private Gtk.Button repeat_button;
    private Gtk.Button shuffle_button;
    private Gtk.ListView queue_listview;
    private Gtk.Revealer search_revealer;
    private Gtk.ScrolledWindow scrolled;
    private Gtk.SearchEntry search_entry;
    private Gtk.SingleSelection selection_model;
    private Gtk.Stack queue_stack;
    private Settings settings;
    private unowned PlaybackManager playback_manager;

    construct {
        playback_manager = PlaybackManager.get_default ();

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

        queue_placeholder = new Granite.Placeholder (_("Queue is Empty")) {
            description = _("Audio files opened from Files will appear here"),
            icon = new ThemedIcon ("playlist-queue")
        };

        selection_model = new Gtk.SingleSelection (playback_manager.queue_liststore);

        var factory = new Gtk.SignalListItemFactory ();

        queue_listview = new Gtk.ListView (selection_model, factory) {
            single_click_activate = true,
            hexpand = true,
            vexpand = true
        };

        scrolled = new Gtk.ScrolledWindow () {
            child = queue_listview
        };

        queue_stack = new Gtk.Stack ();
        queue_stack.add_child (queue_placeholder);
        queue_stack.add_child (scrolled);

        var drop_target = new Gtk.DropTarget (typeof (Gdk.FileList), Gdk.DragAction.COPY);

        var add_button_label = new Gtk.Label (_("Open Files…"));

        var add_button_box = new Gtk.Box (HORIZONTAL, 0);
        add_button_box.append (new Gtk.Image.from_icon_name ("document-open-symbolic"));
        add_button_box.append (add_button_label);

        var open_action = new SimpleAction (ACTION_OPEN, null);
        open_action.activate.connect (open_files);

        var save_action = new SimpleAction (ACTION_SAVE_M3U_PLAYLIST, null);
        save_action.activate.connect (action_save_m3u_playlist);

        var add_button = new Gtk.Button () {
            child = add_button_box,
            action_name = ACTION_PREFIX + ACTION_OPEN
        };
        add_button.add_css_class (Granite.STYLE_CLASS_FLAT);

        add_button_label.mnemonic_widget = add_button;

        var clear_button_label = new Gtk.Label (_("Clear Queue"));

        var clear_button_box = new Gtk.Box (HORIZONTAL, 0);
        clear_button_box.append (new Gtk.Image.from_icon_name ("edit-clear-all-symbolic"));
        clear_button_box.append (clear_button_label);

        var clear_button = new Gtk.Button () {
            child = clear_button_box,
            action_name = Application.ACTION_PREFIX + Application.ACTION_CLEAR_QUEUE
        };
        clear_button.add_css_class (Granite.STYLE_CLASS_FLAT);

        clear_button_label.mnemonic_widget = clear_button;

        var queue_action_bar = new Gtk.ActionBar ();
        queue_action_bar.pack_start (add_button);
        queue_action_bar.pack_end (clear_button);

        var queue = new Adw.ToolbarView () {
            bottom_bar_style = RAISED,
            content = queue_stack
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

        unowned var app = ((Gtk.Application) GLib.Application.get_default ());
        app.set_accels_for_action (ACTION_PREFIX + ACTION_OPEN, {"<Ctrl>O"});
        add_action (open_action);

        app.set_accels_for_action (ACTION_PREFIX + ACTION_SAVE_M3U_PLAYLIST, {"<Ctrl>S"});
        add_action (save_action);

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

        repeat_button.clicked.connect (() => {
            var enum_step = settings.get_enum ("repeat-mode");
            if (enum_step < 2) {
                settings.set_enum ("repeat-mode", enum_step + 1);
            } else {
                settings.set_enum ("repeat-mode", 0);
            }
        });

        factory.setup.connect ((obj) => {
            var list_item = (Gtk.ListItem) obj;
            list_item.child = new TrackRow ();
        });

        factory.bind.connect ((obj) => {
            var list_item = (Gtk.ListItem) obj;
            ((TrackRow) list_item.child).audio_object = (AudioObject) list_item.item;
        });

        queue_listview.activate.connect ((index) => {
            playback_manager.current_audio = (AudioObject) selection_model.get_item (index);
        });

        selection_model.items_changed.connect (on_items_changed);

        search_entry.search_changed.connect (() => {
            int pos = playback_manager.find_title (search_entry.text);
            if (pos >= 0) {
                queue_listview.scroll_to (pos, SELECT, null);
            }
        });

        search_entry.activate.connect (() => {
            var selected = selection_model.get_selected ();
            if (selected != -1) {
                var selected_audio = (AudioObject) selection_model.get_item (selected);
                playback_manager.current_audio = selected_audio;
            }
        });
    }

    public void start_search () {
        if (search_revealer.child_revealed) {
            search_entry.grab_focus ();
        }
    }

    private void open_files () {
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
                    _("Couldn't add audio files"),
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

    public void action_save_m3u_playlist () {
        var all_files_filter = new Gtk.FileFilter () {
            name = _("All files"),
        };
        all_files_filter.add_pattern ("*");

        var playlist_filter = new Gtk.FileFilter () {
            name = _("M3U Playlists"),
        };
        playlist_filter.add_mime_type ("audio/x-mpegurl");

        var filter_model = new ListStore (typeof (Gtk.FileFilter));
        filter_model.append (all_files_filter);
        filter_model.append (playlist_filter);

        var save_dialog = new Gtk.FileDialog () {
            accept_label = _("Save"),
            default_filter = playlist_filter,
            filters = filter_model,
            modal = true,
            title = _("Save playlist"),
            initial_name = "%s.m3u".printf (_("New playlist"))
        };

        save_dialog.save.begin (this, null, (obj, res) => {
            File? file;
            try {
                file = save_dialog.save.end (res);
                M3U.save_playlist (playback_manager.queue_liststore, file);
            } catch (Error err) {
                if (err.matches (Gtk.DialogError.quark (), Gtk.DialogError.DISMISSED)) {
                    return;
                }

                warning ("Failed to save playlist: %s", err.message);

                var dialog = new Granite.MessageDialog (
                    _("Couldn't save playlist"),
                    err.message,
                    new ThemedIcon ("audio-x-playlist")
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

    private void on_items_changed () {
        if (selection_model.n_items > 0) {
            queue_stack.visible_child = scrolled;
        } else {
            queue_stack.visible_child = queue_placeholder;
        }
    }
}
