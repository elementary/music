// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012-2018 elementary LLC. (https://elementary.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * The Noise authors hereby grant permission for non-GPL compatible
 * GStreamer plugins to be used and distributed together with GStreamer
 * and Noise. This permission is above and beyond the permissions granted
 * by the GPL license by which Noise is covered. If you modify this code
 * you may extend this exception to your version of the code, but you are not
 * obligated to do so. If you do not wish to do so, delete this exception
 * statement from your version.
 *
 * Authored by: Scott Ringwelski <sgringwe@mtu.edu>,
 *              Victor Eduardo <victoreduardm@gmail.com>
 */

public class Noise.LibraryWindow : LibraryWindowInterface, Gtk.Window {
    public signal void play_pause_changed ();

    public bool initialization_finished { get; private set; default = false; }
    public bool newly_created_playlist { get; set; default = false; }

    public SourceListView source_list_view { get; private set; }
    public ViewStack view_stack { get; private set; }
    public Widgets.ViewSelector view_selector { get; private set; }
    public Gtk.SearchEntry search_entry { get; private set; }
    public Widgets.StatusBar statusbar { get; private set; }
    public Noise.LocalLibrary library_manager { get { return (Noise.LocalLibrary)libraries_manager.local_library; } }

    private bool media_considered_played { get; set; default = false; } // whether or not we have updated last played and added to already played list
    private bool added_to_play_count { get; set; default = false; } // whether or not we have added one to play count on playing media
    private bool media_considered_previewed { get; set; default = false; }
    private bool media_half_played_sended { get; set; default = false; }
    private bool search_field_has_focus { get; set; default = true; }

    private Gtk.Paned main_hpaned;
    private Cancellable notification_cancellable;
    private PreferencesWindow? preferences = null;
    private Settings.Main main_settings;
    private TopDisplay top_display;

    internal Gee.HashMap<unowned Playlist, ViewWrapper> match_playlists;
    private Gee.HashMap<string, DeviceView> match_devices;
    private Gee.HashMap<unowned Playlist, SourceListEntry> match_playlist_entry;

    public SimpleActionGroup actions { get; construct; }

    public const string ACTION_PREFIX = "win.";
    public const string ACTION_IMPORT = "action_import";
    public const string ACTION_PLAY = "action_play";
    public const string ACTION_PLAY_NEXT = "action_play_next";
    public const string ACTION_PLAY_PREVIOUS = "action_play_previous";
    public const string ACTION_QUIT = "action_quit";
    public const string ACTION_SEARCH = "action_search";
    public const string ACTION_VIEW_ALBUMS = "action_view_albums";
    public const string ACTION_VIEW_COLUMNS = "action_view_columns";
    public const string ACTION_VIEW_LIST = "action_view_list";

    private const ActionEntry[] action_entries = {
        { ACTION_IMPORT, action_import },
        { ACTION_PLAY, action_play, null, "false" },
        { ACTION_PLAY_NEXT, action_play_next },
        { ACTION_PLAY_PREVIOUS, action_play_previous },
        { ACTION_QUIT, action_quit },
        { ACTION_SEARCH, action_search },
        { ACTION_VIEW_ALBUMS, action_view_albums },
        { ACTION_VIEW_COLUMNS, action_view_columns },
        { ACTION_VIEW_LIST, action_view_list }
    };

    public LibraryWindow (Gtk.Application application) {
        Object (application: application);

        application.set_accels_for_action (ACTION_PREFIX + ACTION_QUIT, {"<Control>q", "<Control>w"});
        application.set_accels_for_action (ACTION_PREFIX + ACTION_SEARCH, {"<Control>f"});
        application.set_accels_for_action (ACTION_PREFIX + ACTION_VIEW_ALBUMS, {"<Control>1"});
        application.set_accels_for_action (ACTION_PREFIX + ACTION_VIEW_LIST, {"<Control>2"});
        application.set_accels_for_action (ACTION_PREFIX + ACTION_VIEW_COLUMNS, {"<Control>3"});
    }

    construct {
        actions = new SimpleActionGroup ();
        actions.add_action_entries (action_entries, this);
        insert_action_group ("win", actions);

        main_settings = Settings.Main.get_default ();

        library_manager.media_added.connect (update_sensitivities);
        library_manager.media_removed.connect (update_sensitivities);

        library_manager.playlist_added.connect ((p) => {add_playlist (p);});
        library_manager.playlist_removed.connect ((p) => {remove_playlist (p);});

        library_manager.smartplaylist_added.connect ((p) => {add_smartplaylist (p);});
        library_manager.smartplaylist_removed.connect ((p) => {remove_smartplaylist (p);});

        var device_manager = DeviceManager.get_default ();
        device_manager.device_added.connect ((item) => {create_device_source_list (item);});
        device_manager.device_name_changed.connect (change_device_name);
        device_manager.device_removed.connect (remove_device);

        App.player.player.end_of_stream.connect (end_of_stream);
        App.player.player.current_position_update.connect (current_position_update);
        App.player.player.error_occured.connect (error_occured);
        App.player.media_played.connect_after (media_played);
        App.player.playback_stopped.connect (playback_stopped);
        App.player.changing_player.connect (() => {
            App.player.player.end_of_stream.disconnect (end_of_stream);
            App.player.player.current_position_update.disconnect (current_position_update);
            App.player.player.error_occured.disconnect (error_occured);
        });
        App.player.player_changed.connect (() => {
            App.player.player.end_of_stream.connect (end_of_stream);
            App.player.player.current_position_update.connect (current_position_update);
            App.player.player.error_occured.connect (error_occured);
        });

        NotificationManager.get_default ().show_alert.connect (doAlert);

        match_playlists = new Gee.HashMap<unowned Playlist, ViewWrapper> ();
        match_devices = new Gee.HashMap<string, DeviceView> ();
        match_playlist_entry = new Gee.HashMap<unowned Playlist, SourceListEntry> ();

        libraries_manager.add_headless_playlist.connect ((playlist) => {
            add_playlist (playlist);
        });

        // init some booleans
        if (library_manager.get_medias ().size > 0) {
            App.player.clear_queue ();

            // make sure we don't re-count stats
            if (main_settings.last_media_position > 5) {
                media_considered_previewed = true;

                if (main_settings.last_media_position > 30) {
                    media_considered_played = true;
                }
            }

            if (App.player.current_media != null && (double)(main_settings.last_media_position / (double)App.player.current_media.length) > 0.90) {
                added_to_play_count = true;
            }
        }
    }

    public override bool key_press_event (Gdk.EventKey event) {
        // when typing in an editable widget, such as Gtk.Entry, don't block the event
        var focus_widget = get_focus ();
        if (focus_widget != null && focus_widget is Gtk.Editable)
            return base.key_press_event (event);

        var modifiers = Gtk.accelerator_get_default_mod_mask ();
        bool modifiers_active = (event.state & modifiers) != 0;

        if (!modifiers_active && search_field_has_focus) {
            if (event.keyval == Gdk.Key.space && !search_entry.has_focus && !source_list_view.editing) {
                play_media (); // toggle play/pause
                return true;
            }

            var typed_unichar = event.str.get_char ();
            // Redirect valid key presses to the search entry
            if (typed_unichar.validate () && search_entry.sensitive && !search_entry.has_focus) {
                unichar[] special_chars = {'&', '.', '-', '\\', '%', '(', ')', '=', '@',
                                           '#', '+', '<', '>', ';', ':', '¿', '?', '¡',
                                           '_', '¨', '*', '$', '"', '[', ']', '!', '~'};

                if (typed_unichar.isalnum () || typed_unichar in special_chars) {
                    action_search ();
                }
            }
        }

        return base.key_press_event (event);
    }

    private inline void build_main_widgets () {
        var import_menuitem = new Gtk.MenuItem.with_label (_("Import to Library…"));
        import_menuitem.action_name = ACTION_PREFIX + ACTION_IMPORT;

        var preferences_menuitem = new Gtk.MenuItem.with_label (_("Preferences"));
        preferences_menuitem.activate.connect (editPreferencesClick);

        var menu = new Gtk.Menu ();
        menu.append (import_menuitem);
        menu.append (new Gtk.SeparatorMenuItem ());
        menu.append (preferences_menuitem);
        menu.show_all ();

        var menu_button = new Gtk.MenuButton ();
        menu_button.image = new Gtk.Image.from_icon_name ("open-menu", Gtk.IconSize.LARGE_TOOLBAR);
        menu_button.popup = menu;
        menu_button.valign = Gtk.Align.CENTER;

        var previous_button = new Gtk.Button.from_icon_name ("media-skip-backward-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
        previous_button.action_name = ACTION_PREFIX + ACTION_PLAY_PREVIOUS;
        previous_button.tooltip_text = _("Previous");

        var play_button = new Gtk.Button.from_icon_name ("media-playback-start-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
        play_button.action_name = ACTION_PREFIX + ACTION_PLAY;
        play_button.tooltip_text = _("Play");

        var next_button = new Gtk.Button.from_icon_name ("media-skip-forward-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
        next_button.action_name = ACTION_PREFIX + ACTION_PLAY_NEXT;
        next_button.tooltip_text = _("Next");

        search_entry = new Gtk.SearchEntry ();
        search_entry.valign = Gtk.Align.CENTER;
        search_entry.placeholder_text = _("Search Music");

        view_selector = new Widgets.ViewSelector ();
        view_selector.margin_start = 12;
        view_selector.margin_end = 6;
        view_selector.valign = Gtk.Align.CENTER;

        top_display = new TopDisplay ();
        top_display.margin_start = 30;
        top_display.margin_end = 30;

        var headerbar = new Gtk.HeaderBar ();
        headerbar.show_close_button = true;
        headerbar.pack_start (previous_button);
        headerbar.pack_start (play_button);
        headerbar.pack_start (next_button);
        headerbar.pack_start (view_selector);
        headerbar.pack_end (menu_button);
        headerbar.pack_end (search_entry);
        headerbar.set_title (_("Music"));
        headerbar.set_custom_title (top_display);
        headerbar.show_all ();

        view_stack = new ViewStack ();
        source_list_view = new SourceListView ();

        statusbar = new Widgets.StatusBar ();

        var grid = new Gtk.Grid ();
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.add (source_list_view);
        grid.add (statusbar);

        main_hpaned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
        main_hpaned.pack1 (grid, false, false);
        main_hpaned.pack2 (view_stack, true, false);
        main_hpaned.show_all ();

        App.saved_state.bind ("sidebar-width", main_hpaned, "position", GLib.SettingsBindFlags.DEFAULT);

        add (main_hpaned);
        set_titlebar (headerbar);

        actions.action_state_changed.connect ((name, new_state) => {
            if (name == ACTION_PLAY) {
                if (new_state.get_boolean () == false) {
                    play_button.image = new Gtk.Image.from_icon_name ("media-playback-start-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
                    play_button.tooltip_text = _("Play");
                } else {
                    play_button.image = new Gtk.Image.from_icon_name ("media-playback-pause-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
                    play_button.tooltip_text = _("Pause");
                }
            }
        });

        library_manager.search_finished.connect (() => {
            view_stack.hide_alert ();
        });

        libraries_manager.library_added.connect ((lib) => {
            lib.search_finished.connect (() => {
                view_stack.hide_alert ();
            });
        });

        connect_to_sourcelist_signals ();
    }

    private void connect_to_sourcelist_signals () {
        source_list_view.selection_changed.connect ((view) => {
            view_stack.visible_child = view;
        });

        source_list_view.activated.connect ( () => {
            search_field_has_focus = false;
        });

        source_list_view.item_action_activated.connect ((view) => {
            if (view is DeviceView) {
                ((DeviceView) view).device.eject ();
            }
        });
        source_list_view.edited.connect (playlist_name_edited);

        source_list_view.playlist_rename_clicked.connect ((view) => {
            if (view is PlaylistViewWrapper) {
                search_field_has_focus = false;
            }
        });

        source_list_view.playlist_edit_clicked.connect ((view) => {
            if (view is PlaylistViewWrapper) {
                var p = ((PlaylistViewWrapper)view).playlist;
                if (p is SmartPlaylist) {
                    show_smart_playlist_dialog ((SmartPlaylist) p);
                }
            }
        });

        source_list_view.playlist_remove_clicked.connect ((view) => {
            if (view is PlaylistViewWrapper) {
                var playlistview = (PlaylistViewWrapper)view;
                if (playlistview.hint == ViewWrapper.Hint.PLAYLIST) {
                    playlistview.library.remove_playlist (playlistview.playlist.rowid);
                } else if (playlistview.hint == ViewWrapper.Hint.SMART_PLAYLIST) {
                    playlistview.library.remove_smart_playlist (playlistview.playlist.rowid);
                }
            }
        });

        source_list_view.device_import_clicked.connect ((view) => {
            if (view is DeviceViewWrapper) {
                foreach (var device in DeviceManager.get_default ().get_initialized_devices ()) {
                    if (((DeviceViewWrapper)view).d == device) {
                        libraries_manager.transfer_to_local_library (device.get_library ().get_medias ());
                        break;
                    }
                }
            }
        });

        source_list_view.device_new_playlist_clicked.connect ((view) => {
            if (view is DeviceViewWrapper) {
                foreach (var device in DeviceManager.get_default ().get_initialized_devices ()) {
                    if (((DeviceViewWrapper)view).d == device) {
                        create_new_playlist (device.get_library ());
                        break;
                    }
                }
            }
        });

        source_list_view.device_sync_clicked.connect ((view) => {
            if (view is DeviceViewWrapper) {
                foreach (var device in DeviceManager.get_default ().get_initialized_devices ()) {
                    if (((DeviceViewWrapper)view).d == device) {
                        device.synchronize ();
                        break;
                    }
                }
            }
        });

        source_list_view.device_eject_clicked.connect ((view) => {
            if (view is DeviceViewWrapper) {
                foreach (var device in DeviceManager.get_default ().get_initialized_devices ()) {
                    if (((DeviceViewWrapper)view).d == device) {
                        device.eject ();
                        break;
                    }
                }
            }
        });

        source_list_view.playlist_remove_clicked.connect ((view) => {
            if (view is PlaylistViewWrapper) {
                var playlistview = (PlaylistViewWrapper)view;
                if (playlistview.hint == ViewWrapper.Hint.PLAYLIST) {
                    playlistview.library.remove_playlist (playlistview.playlist.rowid);
                } else if (playlistview.hint == ViewWrapper.Hint.SMART_PLAYLIST) {
                    playlistview.library.remove_smart_playlist (playlistview.playlist.rowid);
                }
            }
        });

        source_list_view.playlist_save_clicked.connect ((view) => {
            if (view is PlaylistViewWrapper) {
                var playlistview = (PlaylistViewWrapper)view;
                if (playlistview.hint != ViewWrapper.Hint.READ_ONLY_PLAYLIST)
                    return;
                var playlist = playlistview.playlist;
                if (playlist != null) {
                    var new_playlist = new StaticPlaylist ();
                    new_playlist.name = PlaylistsUtils.get_new_playlist_name (library_manager.get_playlists (), playlist.name);
                    new_playlist.add_medias (playlist.medias);
                    library_manager.add_playlist (new_playlist);
                }
            }
        });

        source_list_view.playlist_export_clicked.connect ((view) => {
            if (view is PlaylistViewWrapper) {
                var playlistview = (PlaylistViewWrapper)view;
                switch (playlistview.hint) {
                    case ViewWrapper.Hint.PLAYLIST:
                    case ViewWrapper.Hint.READ_ONLY_PLAYLIST:
                        PlaylistsUtils.export_playlist (playlistview.playlist);
                        break;
                    case ViewWrapper.Hint.SMART_PLAYLIST:
                        PlaylistsUtils.export_playlist (playlistview.playlist);
                        break;
                }
            }
        });

        source_list_view.playlist_media_added.connect ((view, uris) => {
            if (view is PlaylistViewWrapper) {
                var playlistview = (PlaylistViewWrapper) view;
                if (playlistview.hint == ViewWrapper.Hint.PLAYLIST) {
                    var library = playlistview.library;
                    var playlist = playlistview.playlist;
                    if (playlist == null)
                        return;

                    var uri_set = new Gee.HashSet<string> ();
                    foreach (string uri in uris)
                        uri_set.add (uri);

                    var media_list = library.medias_from_uris (uri_set);
                    playlist.add_medias (media_list);
                }
            }
        });

        source_list_view.playlist_import_clicked.connect (() => {
            try {
                PlaylistsUtils.import_from_playlist_file_info (Noise.PlaylistsUtils.get_playlists_to_import (), library_manager);
                update_sensitivities.begin ();
            } catch (GLib.Error e) {
                warning (e.message);
            }
        });
    }

    public void build_ui () {
        height_request = 350;
        width_request = 400;
        icon_name = "multimedia-audio-player";
        title = _("Music");

        var window_height = App.saved_state.get_int ("window-height");
        var window_width = App.saved_state.get_int ("window-width");
        var rect = Gtk.Allocation ();
        rect.height = window_height;
        rect.width = window_width;
        set_allocation (rect);

        var window_x = App.saved_state.get_int ("window-x");
        var window_y = App.saved_state.get_int ("window-y");
        if (window_x != -1 ||  window_y != -1) {
            move (window_x, window_y);
        }

        if (App.saved_state.get_enum ("window-state") == 1) {
            maximize ();
        }

        destroy.connect (on_quit);

        show ();

        build_main_widgets ();

        load_playlists ();
        update_sensitivities_sync (); // we need to do this synchronously to avoid weird initial states

        view_selector.selected = (Widgets.ViewSelector.Mode) App.saved_state.get_int ("view-mode");

        library_manager.rescan_music_folder ();
        initialization_finished = true;

        // Set the focus on the current view
        if (main_settings.last_playlist_playing != "") {
            Playlist? p = null;
            if (main_settings.last_playlist_playing.contains ("s")) {
                int64 rowid = int64.parse (main_settings.last_playlist_playing.replace ("s", ""));
                p = library_manager.smart_playlist_from_id (rowid);
            } else {
                int64 rowid = int64.parse (main_settings.last_playlist_playing.replace ("p", ""));
                p = library_manager.playlist_from_id (rowid);
            }

            if (p != null) {
                show_playlist_view (p);
            } else {
                show_playlist_view (library_manager.p_music);
            }
        } else {
            show_playlist_view (library_manager.p_music);
        }

        search_entry.activate.connect (search_entry_activate);
        search_entry.search_changed.connect (() => {
            if (search_entry.text_length != 1) {
                libraries_manager.search_for_string (search_entry.text);
            }
        });
        search_entry.text = main_settings.search_string;

        int64 last_playing_id = main_settings.last_media_playing;
        if (last_playing_id >= 0) {
            var last_playing_media = library_manager.media_from_id (last_playing_id);
            if (last_playing_media != null && last_playing_media.file.query_exists ()) {
                App.player.play_media (last_playing_media);
            }
        }
        libraries_manager.search_for_string (Settings.Main.get_default ().search_string);
    }

    /**
     * Notifications
     */

    public void show_notification (string title, string body, GLib.Icon? icon = null, NotificationPriority priority = GLib.NotificationPriority.LOW, string context = "music") {
        // Don't show notifications if the window is active
        if (is_active) {
            return;
        }

        var notification = new Notification (title);
        notification.set_body (body);
        notification.set_priority (priority);
        if (icon != null) {
            notification.set_icon (icon);
        } else {
            notification.set_icon (new ThemedIcon ("multimedia-audio-player"));
        }

        notification.set_default_action ("app.present");
        GLib.Application.get_default ().send_notification (context, notification);
    }

    private async void show_notification_from_media_async (Media media) {
        if (media == null)
            return;

        if (notification_cancellable != null)
            notification_cancellable.cancel ();

        notification_cancellable = new Cancellable ();

        string primary_text = media.get_display_title ();

        var secondary_text = new StringBuilder ();
        secondary_text.append (media.get_display_artist ());
        secondary_text.append ("\n");
        secondary_text.append (media.get_display_album ());
        if (!notification_cancellable.is_cancelled ()) {
            show_notification (primary_text, secondary_text.str, media.album_info.cover_icon);
        }
    }

    private async void notify_current_media_async () {
        if (App.player.current_media != null)
            yield show_notification_from_media_async (App.player.current_media);
    }


    /**
     * Sets the given view as the active item
     */
    private void set_active_view (ViewWrapper view) {
        if (!initialization_finished)
            return;

        view_stack.visible_child = view;

        if (view is ViewWrapper)
            (view as ViewWrapper).set_as_current_view ();
    }

    private void load_playlists () {
        debug ("Loading playlists");

        foreach (SmartPlaylist p in library_manager.get_smart_playlists ()) {
            add_smartplaylist (p);
        }

        foreach (StaticPlaylist p in library_manager.get_playlists ()) {
            add_playlist (p);
        }

        libraries_manager.add_headless_playlist (App.player.queue_playlist);
        libraries_manager.add_headless_playlist (App.player.history_playlist);

        // Add Music Library View
        var music_tvs = new TreeViewSetup (ViewWrapper.Hint.MUSIC, "library:main", library_manager.connection);
        var music_view_wrapper = new MusicViewWrapper (music_tvs, library_manager, top_display);
        view_stack.add_view (music_view_wrapper);
        var entry = source_list_view.add_item (music_view_wrapper, _("Music"), ViewWrapper.Hint.MUSIC, new ThemedIcon ("library-music"));
        match_playlist_entry.set (library_manager.p_music, entry);
        match_playlists.set (library_manager.p_music, music_view_wrapper);

        debug ("Finished loading playlists");
    }


    /**
     * SourceList Configuration
     */

    private void update_badge_on_playlist_update (Playlist p, SourceListEntry entry) {
        p.media_added.connect ((s) => { update_playlist_badge (p); });
        p.media_removed.connect ((s) => { update_playlist_badge (p); });
        p.cleared.connect ((s) => { update_playlist_badge (p); });
    }

    private void update_playlist_badge (Playlist playlist) {
        var entry = match_playlist_entry.get (playlist);
        int media_count = playlist.medias.size;
        string new_badge = media_count > 0 ? media_count.to_string () : "";
        entry.badge = new_badge;
    }

    /**
     * Updating the interface
     */

    private bool update_sensitivities_pending = false;

    private async void update_sensitivities () {
        if (update_sensitivities_pending)
            return;

        update_sensitivities_pending = true;
        update_sensitivities_sync ();
        update_sensitivities_pending = false;
    }
    private void update_sensitivities_sync () {
        debug ("UPDATE SENSITIVITIES");

        bool folder_set = library_manager.main_directory_set;
        bool have_media = library_manager.get_medias ().size > 0;
        bool doing_ops = library_manager.doing_file_operations ();
        bool media_active = App.player.current_media != null;
        bool media_available = App.player.get_current_media_list ().size > 0;

        ((SimpleAction) actions.lookup_action (ACTION_IMPORT)).set_enabled (!doing_ops && folder_set);
        ((SimpleAction) actions.lookup_action (ACTION_PLAY)).set_enabled (media_active || media_available);
        ((SimpleAction) actions.lookup_action (ACTION_PLAY_NEXT)).set_enabled (media_active || media_available);
        ((SimpleAction) actions.lookup_action (ACTION_PLAY_PREVIOUS)).set_enabled (media_active || media_available);

        // hide playlists when media list is empty
        source_list_view.change_playlist_category_visibility (have_media);
        statusbar.playlist_menubutton_sensitive = folder_set && have_media;

        if (!media_active || have_media && !App.player.playing) {
            ((SimpleAction) actions.lookup_action (ACTION_PLAY)).set_state (false);
        } else {
            ((SimpleAction) actions.lookup_action (ACTION_PLAY)).set_state (true);
        }

    }

    /**
     * Devices
     */
    private void change_device_name (Device device) {
        var view = match_devices.get (device.get_unique_identifier ());
        source_list_view.change_device_name (view, device.get_display_name ());
    }

    private void remove_device (Device device) {
        if (!match_devices.has_key (device.get_unique_identifier ())) {
            return;
        }

        var view = match_devices.get (device.get_unique_identifier ());

        foreach (var subview in source_list_view.remove_device (view)) {
            view_stack.remove_view (subview);
        }

        match_devices.unset (device.get_unique_identifier ());
        view_stack.remove_view (view);
    }

    private void create_device_source_list (Device d) {
        lock (match_devices) {
            SourceListEntry? entry;
            var pref = library_manager.get_preferences_for_device (d);
            var dv = new DeviceView (d, pref);
            view_stack.add_view (dv);
            match_devices.set (d.get_unique_identifier (), dv);
            if (d.only_use_custom_view ()) {
                message ("new custom device (probably a CD) added with %d songs.\n", d.get_library ().get_medias ().size);

                entry = source_list_view.add_item (dv, d.get_display_name (), ViewWrapper.Hint.DEVICE, d.get_icon (), new ThemedIcon ("media-eject-symbolic"), null, d);
            } else {
                debug ("adding device view with %d\n", d.get_library ().get_medias ().size);
                var tvs = new TreeViewSetup (ViewWrapper.Hint.DEVICE_AUDIO);
                var music_view_wrapper = new DeviceViewWrapper (tvs, d, d.get_library ());

                view_stack.add_view (music_view_wrapper);
                entry = source_list_view.add_item  (dv, d.get_display_name (), ViewWrapper.Hint.DEVICE, d.get_icon (), new ThemedIcon ("media-eject-symbolic"), null, d);
                source_list_view.add_item (music_view_wrapper, _("Music"), ViewWrapper.Hint.DEVICE_AUDIO, new ThemedIcon ("library-music"), null, entry as SourceListExpandableItem, d);
                if (d.get_library ().support_playlists () == true) {
                    foreach (var p in d.get_library ().get_playlists ()) {
                        create_playlist_source_list (p, (SourceListExpandableItem)entry, d.get_library ());
                    }
                    d.get_library ().playlist_added.connect ( (np) => {add_playlist (np, d.get_library (), (SourceListExpandableItem)entry);});
                    d.get_library ().playlist_removed.connect ( (np) => {remove_playlist (np);});
                }
            }
        }
    }

    /**
     * StaticPlaylists
     */
    private void add_playlist (StaticPlaylist playlist, Library? library = library_manager, SourceListExpandableItem? entry = null) {
        create_playlist_source_list (playlist, entry, library);
    }

    private void remove_playlist (StaticPlaylist playlist) {
        var view = match_playlists.get (playlist);
        lock (match_playlists) {
            source_list_view.remove_playlist (view);
            match_playlist_entry.unset (playlist);
            match_playlists.unset (playlist);
        }

        view_stack.remove_view (view);
    }

    public void create_new_playlist (Library? library = library_manager) {
        var playlist = new StaticPlaylist ();
        playlist.name = PlaylistsUtils.get_new_playlist_name (library_manager.get_playlists ());
        newly_created_playlist = true;
        library.add_playlist (playlist);
    }

    private void show_playlist_view (Playlist p) {
        if (match_playlists.has_key (p)) {
            source_list_view.selected = match_playlist_entry.get (p);
            set_active_view (match_playlists[p]);
        }
    }

    private void create_playlist_source_list (StaticPlaylist p, SourceListExpandableItem? into_expandable = null, Library? library = library_manager) {
        ViewWrapper.Hint hint = ViewWrapper.Hint.PLAYLIST;
        if (p.read_only == true) {
            hint = ViewWrapper.Hint.READ_ONLY_PLAYLIST;
        }

        TreeViewSetup? tvs = null;
        if (p is LocalStaticPlaylist) {
            tvs = new TreeViewSetup (hint, "library:p%lld".printf (p.rowid), library_manager.connection);
        } else if (p == App.player.queue_playlist) {
            tvs = new TreeViewSetup (hint, "library:queue", library_manager.connection);
        } else if (p == App.player.history_playlist) {
            tvs = new TreeViewSetup (hint, "library:history", library_manager.connection);
        } else {
            tvs = new TreeViewSetup (hint);
        }

        var view = new PlaylistViewWrapper (p, hint, tvs, library);
        view_stack.add_view (view);
        var entry = source_list_view.add_item (view, p.name, hint, p.icon, null, into_expandable);
        if (p.show_badge == true) {
            update_badge_on_playlist_update (p, entry);
        }

        if (p == App.player.queue_playlist) {
            view.set_no_media_alert_message (_("No songs in Queue"), _("To add songs to the queue, use the <b>secondary click</b> on an item and choose <b>Queue</b>. When a song finishes, the queued songs will be played first before the next song in the currently playing list."));
            App.player.queue_medias (p.medias);
        } else if (p == App.player.history_playlist) {
            view.set_no_media_alert_message (_("No songs in History"), _("After a part of a song has been played, it is added to the history list.\nYou can use this list to see all the songs you have played during the current session."));
        }

        match_playlist_entry.set (p, entry);
        match_playlists.set (p, view);

        if (newly_created_playlist == true && p.read_only == false) {
            newly_created_playlist = false;
            show_playlist_view (p);

            // the playlist view steals focus from the source list
            // right after it's created. We add a delay to the edit
            // operation to prevent this from happening.
            Idle.add_full (Priority.LOW, () => {
                source_list_view.start_editing_item (entry);
                return false;
            });
        }
    }

    /**
     * SmartPlaylists
     */

    private void add_smartplaylist (SmartPlaylist smartplaylist, Library? library = library_manager, SourceListExpandableItem? entry = null) {
        create_smartplaylist_source_list (smartplaylist);
    }

    private void remove_smartplaylist (SmartPlaylist smartplaylist) {
        var view = match_playlists.get (smartplaylist);
        lock (match_playlists) {
            match_playlists.unset (smartplaylist);
            source_list_view.remove_playlist (view);
            match_playlists.unset (smartplaylist);
        }

        view_stack.remove_view (view);
    }

    private void playlist_name_edited (Gtk.Grid view_wrapper, string new_name) {
        search_field_has_focus = true;
        if (view_wrapper is PlaylistViewWrapper) {
            var view = view_wrapper as PlaylistViewWrapper;
            if (view.hint == ViewWrapper.Hint.PLAYLIST || view.hint == ViewWrapper.Hint.READ_ONLY_PLAYLIST || view.hint == ViewWrapper.Hint.SMART_PLAYLIST) {
                foreach (var entry in match_playlists.entries) {
                    if (entry.key == view.playlist) {
                        if (entry.key.name != new_name) {
                            entry.key.name = new_name;
                            return;
                        }
                    }
                }
            }
        }
    }

    private void create_smartplaylist_source_list (SmartPlaylist p, SourceListExpandableItem? into_expandable = null, Library? library = library_manager) {
        TreeViewSetup? tvs = null;
        if (p is LocalSmartPlaylist) {
            tvs = new TreeViewSetup (ViewWrapper.Hint.SMART_PLAYLIST, "library:s%lld".printf (p.rowid), library_manager.connection);
        } else {
            tvs = new TreeViewSetup (ViewWrapper.Hint.SMART_PLAYLIST);
        }

        var view = new PlaylistViewWrapper (p, ViewWrapper.Hint.SMART_PLAYLIST, tvs, library_manager);
        view.button_clicked.connect ((playlist) => {
            if (playlist is SmartPlaylist) {
                show_smart_playlist_dialog ((SmartPlaylist) playlist);
            }
        });

        view_stack.add_view (view);
        var entry = source_list_view.add_item  (view, p.name, ViewWrapper.Hint.SMART_PLAYLIST, p.icon);
        p.updated.connect ((old_name) => {
            if (old_name != null)
                source_list_view.change_playlist_name (view, p.name);
        });

        lock (match_playlists) {
            match_playlist_entry.set (p, entry);
            match_playlists.set (p, view);
        }

        if (newly_created_playlist == true) {
            newly_created_playlist = false;
            show_playlist_view (p);
        }
    }

    /**
     * Dialogs from the interface
     */

    public void show_smart_playlist_dialog (SmartPlaylist? smartplaylist = null) {
        SmartPlaylistEditor spe = null;
        spe = new SmartPlaylistEditor (smartplaylist, library_manager);
        spe.show ();
    }

    /** This should be used whenever a call to play a new media is made
     *
     * XXX: this doesn't belong here, but to the playback manager
     * @param s The media that is now playing
     */
    private void media_played (Media m) {
        //reset the media position
        top_display.update_media ();

        //reset some booleans
        media_considered_previewed = false;
        media_considered_played = false;
        added_to_play_count = false;
        media_half_played_sended = false;

        update_sensitivities.begin ();

        Timeout.add (3000, () => {
            if (App.player.current_media != null && App.player.current_media == m) {
                new Thread<void*> (null, () => {
                    update_media_info (App.player.current_media);
                    return null;
                });
            }

            return false;
        });
    }


    public virtual void playback_stopped (int64 was_playing) {
        ((SimpleAction) actions.lookup_action (ACTION_PLAY)).set_state (false);
        //reset some booleans
        media_considered_previewed = false;
        media_considered_played = false;
        added_to_play_count = false;

        update_sensitivities.begin ();

        debug ("playback stopped");
    }

    public virtual void play_media (bool inhibit_notifications = false) {
        if (App.player.current_media == null) {
            debug ("No media is currently playing. Starting from the top\n");

            App.player.get_next (true);
            App.player.start_playback ();

            if (!inhibit_notifications) {
                notify_current_media_async.begin ();
            }
        } else {
            if (App.player.playing) {
                App.player.pause_playback ();
            } else {
                App.player.start_playback ();
            }
        }

        play_pause_changed ();
    }

    public virtual void play_next_media (bool inhibit_notifications = false) {
        // if not 90% done, skip it
        if (!added_to_play_count) {
            App.player.current_media.skip_count++;
        }

        Media? m = App.player.get_next (true);

        /* test to stop playback/reached end */
        if (m == null) {
            App.player.stop_playback ();
            update_sensitivities.begin ();
            return;
        }

        if (!inhibit_notifications) {
            notify_current_media_async.begin ();
        }
    }

    public virtual void play_previous_media (bool inhibit_notifications = false) {
        if (App.player.player.get_position () < 5000000000) {
            bool play = true;
            var prev = App.player.get_previous (true);

            /* test to stop playback/reached end */
            if (prev == null) {
                App.player.stop_playback ();
                update_sensitivities.begin ();
                return;
            } else if (play && !inhibit_notifications) {
                notify_current_media_async.begin ();
            }
        } else {
            top_display.change_value (Gtk.ScrollType.NONE, 0);
        }
    }

    public virtual void action_import () {
        if (!library_manager.doing_file_operations ()) {

            var folders = new Gee.TreeSet<string> ();
            var file_chooser = new Gtk.FileChooserDialog (_("Import Music"), this,
                                      Gtk.FileChooserAction.SELECT_FOLDER,
                                      _("Cancel"), Gtk.ResponseType.CANCEL,
                                      _("Open"), Gtk.ResponseType.ACCEPT);
            file_chooser.set_select_multiple (true);
            file_chooser.set_local_only (true);
            if (file_chooser.run () == Gtk.ResponseType.ACCEPT) {
                foreach (var folder in file_chooser.get_filenames ()) {
                    folders.add (folder);
                }
            }

            file_chooser.destroy ();

            // cancelled
            if (folders.is_empty)
                return;

            if (GLib.File.new_for_path (main_settings.music_folder).query_exists ()) {
                library_manager.add_folder_to_library (folders);
                update_sensitivities.begin ();
            }
        } else {
            debug ("Can't add to library.. already doing file operations\n");
        }
    }

    private void action_play () {
        play_media ();
    }

    private void action_play_next () {
        play_next_media ();
    }

    private void action_play_previous () {
        play_previous_media ();
    }

    private void action_quit () {
        destroy ();
    }

    private void action_search () {
        search_entry.grab_focus ();
    }

    private void action_view_albums () {
        view_selector.selected = Widgets.ViewSelector.Mode.GRID;
    }

    private void action_view_columns () {
        view_selector.selected = Widgets.ViewSelector.Mode.COLUMN;
    }

    private void action_view_list () {
        view_selector.selected = Widgets.ViewSelector.Mode.LIST;
    }

    private void editPreferencesClick () {
        if (preferences == null)
            preferences = new PreferencesWindow ();
        preferences.show_all ();
        preferences.run ();
        preferences = null;
    }

    public void setMusicFolder (string folder) {
        if (library_manager.doing_file_operations ()) {
            return;
        }

        // If different folder chosen or we have no songs anyways, do set.
        if (folder == "" || (folder == main_settings.music_folder && !library_manager.get_medias ().is_empty)) {
            return;
        }

        if (!library_manager.get_medias ().is_empty || library_manager.playlist_count_without_read_only () > 0) {
            var smfc = new SetMusicFolderConfirmation (folder);
            smfc.finished.connect ((cont) => {
                if (cont) {
                    library_manager.set_music_folder.begin (folder);
                }
            });
        } else {
            library_manager.set_music_folder.begin (folder);
        }
    }

    public virtual void end_of_stream () {
        play_next_media ();
    }

    public virtual void error_occured () {
        if (App.player.current_media != null) {
            play_media ();
        }
    }

    public virtual void current_position_update (int64 position) {
        if (App.player.current_media == null)
            return;

        double sec = ((double)position/1000000000);
        double media_length = ((double)App.player.current_media.length/1000);

        if (App.player.file_player.set_resume_pos)
            App.player.current_media.resume_pos = (int)sec;

        // at about 3 seconds, update last fm. we wait to avoid excessive querying last.fm for info
        if (sec > 3 && !media_considered_previewed) {
            media_considered_previewed = true;
            update_media_info (App.player.current_media);
        }

        //at 30 seconds in, we consider the media as played
        if (sec > 30 && !media_considered_played) {
            media_considered_played = true;
            App.player.current_media.last_played = (int)time_t ();

            library_manager.update_media (App.player.current_media, false, false);

            // add to the already played list
            if (!App.player.history_playlist.medias.contains (App.player.current_media)) {
                var temp_media = new Gee.TreeSet<Media> ();
                temp_media.add (App.player.current_media);
                App.player.history_playlist.add_medias (temp_media);
            }
        }

        if ((sec/media_length > 0.50) && (media_half_played_sended == false)) {
            media_half_played (App.player.current_media);
            media_half_played_sended = true;
        }

        // at 80% done with media, add 1 to play count
        if (sec/media_length > 0.80 && !added_to_play_count) {
            added_to_play_count = true;
            App.player.current_media.play_count++;
            library_manager.update_media (App.player.current_media, false, false);
        }
    }

    private void search_entry_activate () {
        var vw = view_stack.visible_child;

        if (vw != null && vw is ViewWrapper) {
            (vw as ViewWrapper).play_first_media ();
        }
    }

    public virtual void dragReceived (Gdk.DragContext context, int x, int y, Gtk.SelectionData data, uint info, uint timestamp) {
        var files_dragged = new Gee.TreeSet<string> ();

        debug ("dragged\n");

        foreach (string uri in data.get_uris ()) {
            files_dragged.add (File.new_for_uri (uri).get_path ());
        }

        library_manager.add_files_to_library (files_dragged);
    }

    public void doAlert (string title, string message) {
        var dialog = new Gtk.MessageDialog (this, Gtk.DialogFlags.MODAL, Gtk.MessageType.ERROR, Gtk.ButtonsType.OK, "%s", title);

        dialog.title = _("Music");
        dialog.secondary_text = message;
        dialog.secondary_use_markup = true;

        dialog.run ();
        dialog.destroy ();
    }

    private void on_quit () {
        if (!main_settings.privacy_mode_enabled ()) {
            // Save media position and info
            main_settings.last_media_position = (int)((double)App.player.player.get_position
            ()/TimeUtils.NANO_INV);
            if (App.player.current_media != null) {
                App.player.current_media.resume_pos = (int)((double)App.player.player.get_position ()/TimeUtils.NANO_INV);
                library_manager.update_media (App.player.current_media, false, false);
            }
        }
        App.player.player.pause ();

        // Search
        if (!main_settings.privacy_mode_enabled ()) {
            main_settings.search_string = search_entry.text;
        }

        App.saved_state.set_int ("view-mode", view_selector.selected);
    }

    /**
     * Called when the user tries to quit the application using a mechanism provided
     * by the desktop shell (close button, quicklists, etc.)
     *
     * This doesn't apply to calls to App.instance.quit ()
     */
    public override bool delete_event (Gdk.EventAny event) {
        bool playing = App.player.current_media != null && App.player.playing;

        // if playing a song, don't allow closing
        if (!main_settings.close_while_playing && playing) {
            hide ();

            return true;
        }

        return false; // can exit
    }

    public override bool configure_event (Gdk.EventConfigure event) {
        if (is_maximized) {
            App.saved_state.set_enum ("window-state", 1);
        } else {
            App.saved_state.set_enum ("window-state", 0);

            Gtk.Allocation rect;
            get_allocation (out rect);
            App.saved_state.set_int ("window-height", rect.height);
            App.saved_state.set_int ("window-width", rect.width);

            int window_x, window_y;
            get_position (out window_x, out window_y);
            App.saved_state.set_int ("window-x" , window_x);
            App.saved_state.set_int ("window-y" , window_y);
        }

        return base.configure_event (event);
    }
}
