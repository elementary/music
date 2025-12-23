/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2021 elementary, Inc. (https://elementary.io)
 */

public class Music.MainWindow : Gtk.ApplicationWindow {
    public const string ACTION_PREFIX = "win.";
    public const string ACTION_OPEN = "action-open";

    private QueueView queue_view;

    construct {
        queue_view = new QueueView ();

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
            start_child = queue_view,
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

        var settings = new Settings ("io.elementary.music");
        settings.bind ("pane-position", paned, "position", SettingsBindFlags.DEFAULT);

        var open_action = new SimpleAction (ACTION_OPEN, null);
        open_action.activate.connect (open_files);
        add_action (open_action);

        unowned var app = ((Gtk.Application) GLib.Application.get_default ());
        app.set_accels_for_action (ACTION_PREFIX + ACTION_OPEN, {"<Ctrl>O"});
    }

    public void start_search () {
        queue_view.start_search ();
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
}
