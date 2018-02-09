// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012-2017 elementary LLC. (https://elementary.io)
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
    public signal void close_subwindows ();

    public bool dragging_from_music { get; set; default = false; }
    public bool initialization_finished { get; private set; default = false; }
    public bool newly_created_playlist { get; set; default = false; }

    public ViewManager view_manager { get; private set; }

    public SourceListView source_list_view { get; private set; }
    public ViewStack view_stack { get; private set; }
    public Widgets.ViewSelector view_selector { get; private set; }
    public Gtk.SearchEntry search_entry { get; private set; }
    public Widgets.StatusBar statusbar { get; private set; }
    public Granite.Widgets.AlertView alert_view { get; private set; }
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
    private GLib.Settings saved_state_settings;
    private TopDisplay top_display;

    internal Gee.HashMap<unowned Playlist, int> match_playlists;
    private Gee.HashMap<string, int> match_devices;

    public SimpleActionGroup actions { get; construct; }

    public const string ACTION_PREFIX = "win.";
    public const string ACTION_IMPORT = "action_import";
    public const string ACTION_PLAY = "action_play";
    public const string ACTION_PLAY_NEXT = "action_play_next";
    public const string ACTION_PLAY_PREVIOUS = "action_play_previous";

    private const ActionEntry[] action_entries = {
        { ACTION_IMPORT, action_import },
        { ACTION_PLAY, action_play, null, "false" },
        { ACTION_PLAY_NEXT, action_play_next },
        { ACTION_PLAY_PREVIOUS, action_play_previous }
    };

    construct {
        actions = new SimpleActionGroup ();
        actions.add_action_entries (action_entries, this);
        insert_action_group ("win", actions);

        main_settings = Settings.Main.get_default ();

        view_manager = new ViewManager ();
        view_manager.notify["selected-view"].connect (() => {
            var view = view_manager.selected_view;

            // add this view to the stack if needed
            if (view_stack.get_child_by_name (view.id) == null) {
                view_stack.add_titled (view, view.id, view.title);
                view_stack.set_visible_child (view_manager.selected_view);
            }

            view_stack.visible_child = view_manager.selected_view;
            trigger_search (view_manager.selected_view);
        });
        view_manager.request_filtering.connect (trigger_search);

        library_manager.media_added.connect (update_sensitivities);
        library_manager.media_removed.connect (update_sensitivities);

        library_manager.playlist_added.connect ((p) => {add_playlist (p);});
        library_manager.playlist_removed.connect ((p) => {remove_playlist (p);});

        library_manager.smartplaylist_added.connect ((p) => {add_smartplaylist (p);});
        library_manager.smartplaylist_removed.connect ((p) => {remove_smartplaylist (p);});

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

        match_playlists = new Gee.HashMap<unowned Playlist, int> ();
        match_devices = new Gee.HashMap<string, int> ();

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

            if (App.player.current_media != null && (double)(main_settings.last_media_position/(double)App.player.current_media.length) > 0.90)
                added_to_play_count = true;
        }
    }

    /** Returns true if the code parameter matches the keycode of the keyval parameter for
    * any keyboard group or level (in order to allow for non-QWERTY keyboards) **/
    protected bool match_keycode (int keyval, uint code) {
        Gdk.KeymapKey [] keys;
        Gdk.Keymap keymap = Gdk.Keymap.get_default ();
        if (keymap.get_entries_for_keyval (keyval, out keys)) {
            foreach (var key in keys) {
                if (code == key.keycode)
                    return true;
                }
            }

        return false;
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

                if (typed_unichar.isalnum () || typed_unichar in special_chars)
                    search_entry.grab_focus ();
            }
        } else if ((event.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
            switch (event.keyval) {
                case Gdk.Key.@1:
                    view_selector.mode_button.selected = 1;
                    break;
                case Gdk.Key.@2:
                    view_selector.mode_button.selected = 2;
                    break;
                case Gdk.Key.@3:
                    view_selector.mode_button.selected = 3;
                    break;
            }

            uint keycode = event.hardware_keycode;
            if (match_keycode (Gdk.Key.f, keycode)) {
                search_entry.grab_focus ();
                return false;
            } else if (match_keycode (Gdk.Key.q, keycode) || match_keycode (Gdk.Key.w, keycode)) {
                destroy ();
                return true;
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

        alert_view = new Granite.Widgets.AlertView (_("No results"), _("Try another search"), "edit-find-symbolic");
        view_stack = new ViewStack ();
        view_stack.add_named (alert_view, "alert-view");
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

        saved_state_settings.bind ("sidebar-width", main_hpaned, "position", GLib.SettingsBindFlags.DEFAULT);

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
    }

    public void create_views () {
        view_manager.add_category (new Category ("library", _("Library")));
        view_manager.add_category (new Category ("network", _("Network")));
        view_manager.add_category (new Category ("playlists", _("Playlists")));

        // Add Music Library View
        view_manager.add (new HomeView (), true);
    }

    public void build_ui () {
        height_request = 350;
        width_request = 400;
        icon_name = "multimedia-audio-player";
        title = _("Music");

        saved_state_settings = new GLib.Settings ("io.elementary.music.saved-state");

        set_default_size (saved_state_settings.get_int ("window-width"), saved_state_settings.get_int ("window-height"));
        var window_x = saved_state_settings.get_int ("window-x");
        var window_y = saved_state_settings.get_int ("window-y");
        if (window_x != -1 ||  window_y != -1) {
            move (saved_state_settings.get_int ("window-x"), saved_state_settings.get_int ("window-y"));
        }

        if (saved_state_settings.get_enum ("window-state") == 1) {
            maximize ();
        }

        destroy.connect (on_quit);

        show ();

        build_main_widgets ();

        create_views ();

        load_playlists ();
        update_sensitivities_sync (); // we need to do this synchronously to avoid weird initial states

        view_selector.mode_button.selected = saved_state_settings.get_int ("view-mode");

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

        search_entry.search_changed.connect (() => {
            if (search_entry.text_length != 1) {
                trigger_search (view_manager.selected_view);
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

    private void trigger_search (View view_to_filter) {
        if (view_to_filter.filter (search_entry.text)) {
            view_stack.visible_child = view_to_filter;
        } else {
            view_stack.remove (alert_view);
            alert_view = new Granite.Widgets.AlertView (_("No results"), _("Try another search"), "edit-find-symbolic");
            view_to_filter.update_alert (alert_view);
            alert_view.show_all ();
            view_stack.add_named (alert_view, "alert-view");
            view_stack.visible_child = alert_view;
        }
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

        debug ("Finished loading playlists");
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

        if (!media_active || have_media && !App.player.playing) {
            ((SimpleAction) actions.lookup_action (ACTION_PLAY)).set_state (false);
        } else {
            ((SimpleAction) actions.lookup_action (ACTION_PLAY)).set_state (true);
        }

    }

    /**
     * StaticPlaylists
     */
    private void add_playlist (StaticPlaylist playlist) {
        var tvs = new TreeViewSetup (true);
        if (playlist is LocalStaticPlaylist) {
            tvs = new TreeViewSetup (true, "library:playlist%lld".printf (playlist.rowid), library_manager.connection);
        } else if (playlist == App.player.queue_playlist) {
            tvs = new TreeViewSetup (true, "library:queue", library_manager.connection);
        } else if (playlist == App.player.history_playlist) {
            tvs = new TreeViewSetup (true, "library:history", library_manager.connection);
        }

        view_manager.add (new StaticPlaylistView (playlist, tvs));
    }

    private void remove_playlist (StaticPlaylist playlist) {
        foreach (var view in view_manager.views) {
            if (view is PlaylistView && ((PlaylistView)view).playlist == playlist) {
                view_manager.remove_view (view);
                return;
            }
        }
    }

    public void create_new_playlist (Library? library = library_manager) {
        var playlist = new StaticPlaylist ();
        playlist.name = PlaylistsUtils.get_new_playlist_name (library_manager.get_playlists ());
        library.add_playlist (playlist);
        var view = show_playlist_view (playlist);
        Idle.add_full (Priority.LOW, () => {
            view.request_sidebar_editing ();
            return false;
        });
    }

    private View? show_playlist_view (Playlist playlist) {
        foreach (var view in view_manager.views) {
            if (view.id == playlist.id) {
                view_manager.select (view);
                return view;
            }
        }
        return null;
    }

    /**
     * SmartPlaylists
     */

    private void add_smartplaylist (SmartPlaylist smartplaylist) {
        var tvs = new TreeViewSetup (true);
        if (smartplaylist is LocalSmartPlaylist) {
            tvs = new TreeViewSetup (true, "library:s%lld".printf (smartplaylist.rowid), library_manager.connection);
        }

        view_manager.add (new SmartPlaylistView (smartplaylist, tvs));
    }

    private void remove_smartplaylist (SmartPlaylist smartplaylist) {
        foreach (var view in view_manager.views) {
            if (view is PlaylistView && ((PlaylistView)view).playlist == smartplaylist) {
                view_manager.remove_view (view);
                return;
            }
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
            debug("No media is currently playing. Starting from the top\n");

            App.player.get_next (true);
            App.player.start_playback ();

            if (!inhibit_notifications)
                notify_current_media_async.begin ();
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
            debug("Can't add to library.. already doing file operations\n");
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

    private void editPreferencesClick () {
        if (preferences == null)
            preferences = new PreferencesWindow ();
        preferences.show_all ();
        preferences.run ();
        preferences = null;
    }

    public void setMusicFolder(string folder) {
        if (library_manager.doing_file_operations ())
            return;

        // If different folder chosen or we have no songs anyways, do set.
        if (folder == "" || (folder == main_settings.music_folder && !library_manager.get_medias ().is_empty))
            return;

        if (!library_manager.get_medias ().is_empty || library_manager.playlist_count_without_read_only () > 0) {
            var smfc = new SetMusicFolderConfirmation(folder);
            smfc.finished.connect( (cont) => {
                if (cont) {
                    library_manager.set_music_folder.begin (folder);
                }
            });
        }
        else {
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
                var temp_media = new Gee.TreeSet<Media>();
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

    public virtual void dragReceived (Gdk.DragContext context, int x, int y, Gtk.SelectionData data, uint info, uint timestamp) {
        if (dragging_from_music)
            return;

        var files_dragged = new Gee.TreeSet<string> ();

        debug("dragged\n");

        foreach (string uri in data.get_uris ()) {
            files_dragged.add (File.new_for_uri (uri).get_path ());
        }

        library_manager.add_files_to_library (files_dragged);
    }

    public void doAlert(string title, string message) {
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

        saved_state_settings.set_int ("view-mode", view_selector.mode_button.selected);

        if (is_maximized) {
            saved_state_settings.set_enum ("window-state", 1);
        } else {
            saved_state_settings.set_enum ("window-state", 0);
        }
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
            close_subwindows ();
            hide ();

            return true;
        }

        return false; // can exit
    }

    public override bool configure_event (Gdk.EventConfigure event) {
        if (is_maximized == false) {
            int window_width, window_height, window_x, window_y;
            get_size (out window_width, out window_height);
            get_position (out window_x, out window_y);
            saved_state_settings.set_int ("window-height", window_height);
            saved_state_settings.set_int ("window-width", window_width);
            saved_state_settings.set_int ("window-x" , window_x);
            saved_state_settings.set_int ("window-y" , window_y);
        }

        return base.configure_event (event);
    }
}
