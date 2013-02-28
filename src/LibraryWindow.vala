// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012 Noise Developers (http://launchpad.net/noise)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Scott Ringwelski <sgringwe@mtu.edu>,
 *              Victor Eduardo <victoreduardm@gmail.com>
 */

using Gtk;
using Gee;

public class Noise.LibraryWindow : LibraryWindowInterface, Gtk.Window {
    public signal void playPauseChanged ();

    public enum WindowState {
        NORMAL,
        MAXIMIZED,
        FULLSCREEN
    }

    public Noise.LocalLibrary library_manager { get { return (Noise.LocalLibrary)libraries_manager.local_library; } }

    /* Info related to the media being played */
    private bool media_considered_played    { get; set; default = false; } // whether or not we have updated last played and added to already played list
    private bool added_to_play_count        { get; set; default = false; } // whether or not we have added one to play count on playing media
    private bool tested_for_video           { get; set; default = false; } // whether or not we have tested if media is video and shown video
    private bool media_considered_previewed { get; set; default = false; }
    private bool media_half_played_sended   { get; set; default = false; }
    private bool search_field_has_focus     { get; set; default = true; }

    public bool dragging_from_music         { get; set; default = false; }
    public bool initialization_finished     { get; private set; default = false; }


    /* Main layout widgets */
    private Gtk.Box       verticalBox;
    private Gtk.Paned     view_container_hpaned; // view_container / info_panel
    public InfoPanel      info_panel;

    private Gtk.Toolbar    main_toolbar; // Toolbar
    private Gtk.ToolButton previousButton;
    private Gtk.ToolButton playButton;
    private Gtk.ToolButton nextButton;

    public Granite.Widgets.ThinPaned  main_hpaned      { get; private set; }
    public SourceListView             source_list_view { get; private set; }
    public ViewContainer              view_container   { get; private set; }
    public TopDisplay                 topDisplay       { get; private set; }
    private FixedBin                  topDisplayBin    { get; private set; }
    public Widgets.ViewSelector       viewSelector     { get; private set; }
    public Granite.Widgets.SearchBar  searchField      { get; private set; }
    public Widgets.StatusBar          statusbar        { get; private set; }

    /* AppMenu items */
    private Gtk.Menu          settingsMenu;
    private Gtk.MenuItem      fileImportMusic;
    private Gtk.MenuItem      fileRescanMusicFolder;
    private Gtk.ImageMenuItem editPreferences;

    /* Window state properties */
    private bool window_maximized = false;
    private bool window_fullscreen = false;
    private int window_width = 0;
    private int window_height = 0;

    private Cancellable notification_cancellable;
    
    PreferencesWindow? preferences = null;
    
    private Gee.HashMap<int, int> match_playlist;
    private Gee.HashMap<int, int> match_smartplaylist;
    private Gee.HashMap<string, int> match_devices;
    private Gee.HashMap<unowned Playlist, SourceListEntry> match_playlist_entry;
    private Gee.HashMap<int, TreeViewSetup> match_playlist_tvs;
    private Gee.HashMap<int, TreeViewSetup> match_smartplaylist_tvs;

    public LibraryWindow () {
        //FIXME? App.player.player.media_not_found.connect (media_not_found);
        this.library_manager.music_counted.connect (musicCounted);
        this.library_manager.music_added.connect (musicAdded);
        this.library_manager.music_imported.connect (musicImported);
        this.library_manager.music_rescanned.connect (musicRescanned);

        this.library_manager.media_updated.connect (medias_updated);
        this.library_manager.media_added.connect (update_sensitivities);
        this.library_manager.media_removed.connect (update_sensitivities);

        this.library_manager.playlist_added.connect (add_playlist);
        this.library_manager.playlist_removed.connect (remove_playlist);

        this.library_manager.smartplaylist_added.connect (add_smartplaylist);
        this.library_manager.smartplaylist_removed.connect (remove_smartplaylist);

        device_manager.device_added.connect ((item) => {addSourceListItem (item);});
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
        
        notification_manager.alertNotification.connect (doAlert);
        
        match_playlist = new Gee.HashMap<int, int> ();
        match_smartplaylist = new Gee.HashMap<int, int> ();
        match_devices = new Gee.HashMap<string, int> ();
        match_playlist_entry = new Gee.HashMap<unowned Playlist, SourceListEntry> ();
        match_playlist_tvs = new Gee.HashMap<int, TreeViewSetup> ();
        match_smartplaylist_tvs = new Gee.HashMap<int, TreeViewSetup> ();


        // init some booleans
        if (main_settings.music_folder == "") {
            main_settings.music_folder = GLib.Environment.get_user_special_dir (GLib.UserDirectory.MUSIC);
            debug ("First run.");
        }
        else {
            App.player.clearCurrent();

            // make sure we don't re-count stats
            if (main_settings.last_media_position > 5)
                media_considered_previewed = true;
            if(main_settings.last_media_position > 30)
                media_considered_played = true;
            if(App.player.media_active && (double)(main_settings.last_media_position/(double)App.player.media_info.media.length) > 0.90)
                added_to_play_count = true;
        }

        /*if(!File.new_for_path(settings.getMusicFolder()).query_exists() && settings.getMusicFolder() != "") {
            doAlert("Music folder not mounted", "Your music folder is not mounted. Please mount your music folder before using Noise.");
        }*/
    }

    public override bool key_press_event (Gdk.EventKey event) {
        var modifiers = Gtk.accelerator_get_default_mod_mask ();
        bool modifiers_active = (event.state & modifiers) != 0;

        if (!modifiers_active) {
            if (event.keyval == Gdk.Key.space && !searchField.has_focus && !source_list_view.editing) {
                play_media (); // toggle play/pause
                return true;
            }

            var typed_unichar = event.str.get_char ();
            // Redirect valid key presses to the search entry
            if (typed_unichar.validate () && searchField.sensitive && !searchField.has_focus) {
                unichar[] special_chars = {'&', '.', '-', '\\', '%', '(', ')', '=', '@',
                                           '#', '+', '<', '>', ';', ':', '¿', '?', '¡',
                                           '_', '¨', '*', '$', '"', '[', ']', '!', '~'};

                if (typed_unichar.isalnum () || typed_unichar in special_chars)
                    searchField.grab_focus ();
            }
        } else if ((event.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
            switch (event.keyval) {
                case Gdk.Key.f:
                    return false;
                case Gdk.Key.q:
                case Gdk.Key.w:
                    this.destroy ();
                    return true;
            }
        }

        return base.key_press_event (event);
    }
 
    private inline void setup_window () {
        debug ("setting up main window");

        this.height_request = 440;
        this.width_request = 750;
        this.window_position = Gtk.WindowPosition.CENTER;

        // set the size based on saved settings
        this.set_default_size (saved_state.window_width, saved_state.window_height);

        // Maximize window if necessary
        switch (saved_state.window_state) {
            case WindowState.MAXIMIZED:
                this.maximize ();
                break;
            case WindowState.FULLSCREEN:
                this.fullscreen ();
                break;
            default:
                break;
        }

        this.set_title (App.instance.get_name ());
        this.set_icon (Icons.NOISE.render_at_size (64));

        // set up drag dest stuff
        /*
        Gtk.drag_dest_set (this, DestDefaults.ALL, {}, Gdk.DragAction.MOVE);
        Gtk.drag_dest_add_uri_targets (this);
        this.drag_data_received.connect (dragReceived);
        */
        this.destroy.connect (on_quit);

        this.show ();
        debug ("done with main window");
    }

    private inline void build_main_widgets () {
        debug ("Building main widgets");

        /** App menu widgets **/

        settingsMenu            = new Gtk.Menu ();
        fileImportMusic         = new Gtk.MenuItem.with_label (_("Import to Library"));
        fileRescanMusicFolder   = new Gtk.MenuItem.with_label (_("Rescan Music Folder"));
        editPreferences         = new Gtk.ImageMenuItem.from_stock (Gtk.Stock.PREFERENCES, null);

        editPreferences.set_label (_("Preferences"));

        settingsMenu.append (fileImportMusic);
        settingsMenu.append (fileRescanMusicFolder);
        settingsMenu.append (new Gtk.SeparatorMenuItem ());
        settingsMenu.append (editPreferences);

        fileImportMusic.activate.connect (fileImportMusicClick);
        fileRescanMusicFolder.activate.connect ( () => { rescan_music_folder (); }); // FIXME
        editPreferences.activate.connect(editPreferencesClick);

        /** Toolbar widgets **/

        main_toolbar            = new Gtk.Toolbar ();
        previousButton          = new Gtk.ToolButton.from_stock (Gtk.Stock.MEDIA_PREVIOUS);
        playButton              = new Gtk.ToolButton.from_stock (Gtk.Stock.MEDIA_PLAY);
        nextButton              = new Gtk.ToolButton.from_stock (Gtk.Stock.MEDIA_NEXT);
        topDisplay              = new TopDisplay ();
        topDisplayBin           = new FixedBin (-1, -1, 800, -1);
        viewSelector            = new Widgets.ViewSelector ();
        searchField             = new Granite.Widgets.SearchBar (_("Search Music"));

        main_toolbar.get_style_context ().add_class (Gtk.STYLE_CLASS_PRIMARY_TOOLBAR);

        topDisplayBin.set_widget (topDisplay, true, false);

        // Set search timeout in ms
        searchField.pause_delay = 80;

        var top_display_item   = new Gtk.ToolItem ();
        var search_field_item  = new Gtk.ToolItem ();

        top_display_item.add (topDisplayBin);
        search_field_item.add (searchField);

        // Tweak view selector's size
        viewSelector.margin_left = 12;
        viewSelector.margin_right = 6;

        viewSelector.valign = Gtk.Align.CENTER;

        top_display_item.set_expand (true);
        topDisplay.margin_left = 30;
        topDisplay.margin_right = 30;

        main_toolbar.insert (previousButton, -1);
        main_toolbar.insert (playButton, -1);
        main_toolbar.insert (nextButton, -1);
        main_toolbar.insert (viewSelector, -1);
        main_toolbar.insert (top_display_item, -1);
        main_toolbar.insert (search_field_item, -1);
        main_toolbar.insert (App.instance.create_appmenu (settingsMenu), -1);


        /** Info Panel **/

        info_panel = new InfoPanel ();


        /** Statusbar widgets **/

        statusbar = new Widgets.StatusBar (this);


        /** Main layout **/

        verticalBox           = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_hpaned           = new Granite.Widgets.ThinPaned ();
        view_container_hpaned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
        view_container        = new ViewContainer ();
        source_list_view      = new SourceListView ();

        // Set properties of various controls
        main_hpaned.position = saved_state.sidebar_width;
        int view_container_pos = saved_state.window_width - saved_state.sidebar_width - saved_state.more_width;
        view_container_hpaned.set_position (view_container_pos);

        view_container_hpaned.pack1 (view_container, true, false);
        view_container_hpaned.pack2 (info_panel, false, false);

        main_hpaned.pack1 (source_list_view, false, false);
        main_hpaned.pack2 (view_container_hpaned, true, false);

        // Add controls to the GUI
        verticalBox.pack_start (main_toolbar, false, false, 0);
        verticalBox.pack_start (main_hpaned, true, true, 0);
        verticalBox.pack_end (statusbar, false, false, 0);

        this.add (verticalBox);

        // Make all the widgets visible
        verticalBox.show_all ();
        connect_to_sourcelist_signals ();

        debug ("Done with main widgets");
    }

    public void connect_to_sourcelist_signals () {
        
        source_list_view.selection_changed.connect ( (page_number) => {
            view_container.set_current_view_from_index (page_number);
        });
        
        source_list_view.item_action_activated.connect ( (page_number) => {
            var view = view_container.get_view (page_number);
            if (view is DeviceView) {
                ((DeviceView)view).d.eject();
            }
        });
        source_list_view.edited.connect (playlist_name_edited);

        source_list_view.playlist_rename_clicked.connect ( (page_number) => {
            var view = view_container.get_view (page_number);
            if (view is PlaylistViewWrapper) {
                source_list_view.start_editing_item(source_list_view.selected);
            }
        });
        
        source_list_view.playlist_edit_clicked.connect ( (page_number) => {
            var view = view_container.get_view (page_number);
            if (view is PlaylistViewWrapper) {
                show_smart_playlist_dialog(library_manager.smart_playlist_from_id(((PlaylistViewWrapper)view).playlist_id));
            }
        });
        
        source_list_view.playlist_remove_clicked.connect ( (page_number) => {
            var view = view_container.get_view (page_number);
            if (view is PlaylistViewWrapper) {
                var playlistview = (PlaylistViewWrapper)view;
                if (playlistview.hint == ViewWrapper.Hint.PLAYLIST) {
                    ((ViewWrapper)view).library.remove_playlist(playlistview.playlist_id);
                } else if (playlistview.hint == ViewWrapper.Hint.SMART_PLAYLIST) {
                    ((ViewWrapper)view).library.remove_smart_playlist(playlistview.playlist_id);
                }
            }
        });
        
        source_list_view.device_import_clicked.connect ( (page_number) => {
            foreach (var device in device_manager.devices) {
                if(page_number == match_devices.get (device.get_unique_identifier())) {
                    libraries_manager.transfer_to_local_library (device.get_library().get_medias ());
                    break;
                }
            }
        });
        
        source_list_view.device_new_playlist_clicked.connect ( (page_number) => {
            foreach (var device in device_manager.devices) {
                if(page_number == match_devices.get (device.get_unique_identifier())) {
                    create_new_playlist (device.get_library());
                    break;
                }
            }
        });
        
        source_list_view.device_sync_clicked.connect ( (page_number) => {
            warning ("");
            foreach (var device in device_manager.devices) {
                if(page_number == match_devices.get (device.get_unique_identifier())) {
                    device.synchronize ();
                    break;
                }
            }
        });
        
        source_list_view.device_eject_clicked.connect ( (page_number) => {
            foreach (var device in device_manager.devices) {
                if(page_number == match_devices.get (device.get_unique_identifier())) {
                    device.eject();
                    break;
                }
            }
        });
        
        source_list_view.playlist_remove_clicked.connect ( (page_number) => {
            var view = view_container.get_view (page_number);
            if (view is PlaylistViewWrapper) {
                var playlistview = (PlaylistViewWrapper)view;
                if (playlistview.hint == ViewWrapper.Hint.PLAYLIST) {
                    ((ViewWrapper)view).library.remove_playlist(playlistview.playlist_id);
                } else if (playlistview.hint == ViewWrapper.Hint.SMART_PLAYLIST) {
                    ((ViewWrapper)view).library.remove_smart_playlist(playlistview.playlist_id);
                }
            }
        });
        
        source_list_view.playlist_save_clicked.connect ( (page_number) => {
            var view = view_container.get_view (page_number);
            if (view is ReadOnlyPlaylistViewWrapper) {
                var playlistview = (ReadOnlyPlaylistViewWrapper)view;
                var playlist = library_manager.playlist_from_id (playlistview.playlist_id);
                if (playlist != null) {
                    var new_playlist = new StaticPlaylist();
                    new_playlist.name = PlaylistsUtils.get_new_playlist_name (library_manager.get_playlists (), playlist.name);
                    new_playlist.add_medias (playlist.medias);
                    library_manager.add_playlist(new_playlist);
                }
            }
        });
        
        source_list_view.playlist_export_clicked.connect ( (page_number) => {
            var view = view_container.get_view (page_number);
            if (view is ReadOnlyPlaylistViewWrapper) {
                var playlistview = (ReadOnlyPlaylistViewWrapper)view;
                var playlist = ((ViewWrapper)view).library.playlist_from_id (playlistview.playlist_id);
                if (playlist != null) {
                    PlaylistsUtils.export_playlist (playlist);
                }
            } else if (view is PlaylistViewWrapper) {
                var playlistview = (PlaylistViewWrapper)view;
                if (playlistview.hint == ViewWrapper.Hint.PLAYLIST) {
                    PlaylistsUtils.export_playlist (((ViewWrapper)view).library.playlist_from_id (playlistview.playlist_id));
                } else if (playlistview.hint == ViewWrapper.Hint.SMART_PLAYLIST) {
                    PlaylistsUtils.export_playlist (((ViewWrapper)view).library.smart_playlist_from_id (playlistview.playlist_id));
                }
            }
        });
        
        source_list_view.playlist_import_clicked.connect ( () => {
            try {
                library_manager.fo.import_from_playlist_file_info(Noise.PlaylistsUtils.get_playlists_to_import ());
                update_sensitivities.begin ();
            } catch (GLib.Error e) {
                warning (e.message);
            }
        });
    }

    public void build_ui () {
        debug ("BUILDING USER INTERFACE");

        setup_window ();

        build_main_widgets ();

        // add mounts to side tree view
        device_manager.loadPreExistingMounts();

        build_main_views ();
        load_playlists ();
        //sideTree.resetView ();
        update_sensitivities_sync (); // we need to do this synchronously to avoid weird initial states

        // Now set the selected view
        viewSelector.selected = (Widgets.ViewSelector.Mode) saved_state.view_mode;

        initialization_finished = true;

        if (library_manager._medias.is_empty)
            setMusicFolder (Environment.get_user_special_dir(UserDirectory.MUSIC));

        /* Connect events to functions */
        previousButton.clicked.connect (() => {play_previous_media ();});
        playButton.clicked.connect (() => {play_media ();});
        nextButton.clicked.connect (() => {play_next_media ();});

        searchField.activate.connect (searchFieldActivate);
        searchField.text = main_settings.search_string;

        debug ("DONE WITH USER INTERFACE");

        int last_playing_id = main_settings.last_media_playing;

        if (last_playing_id > 0) {
            var last_playing_media = library_manager.media_from_id (last_playing_id);
            if (last_playing_media != null && last_playing_media.file.query_exists ())
                App.player.playMedia (last_playing_media, true);
        }
    }

    /**
     * Notifications
     */
#if HAVE_LIBNOTIFY
    private Notify.Notification? notification = null;
#endif

    public void show_notification (string primary_text, string secondary_text, Gdk.Pixbuf? pixbuf = null, int urgency = -1) {
#if HAVE_LIBNOTIFY
        // Don't show notifications if the window is active
        if (!main_settings.show_notifications || this.is_active)
            return;

        if (urgency == -1)
            urgency = Notify.Urgency.NORMAL;

        if (!Notify.is_initted ()) {
            if (!Notify.init (App.instance.get_id ())) {
                warning ("Could not init libnotify");
                return;
            }
        }

        if (notification == null) {
            notification = new Notify.Notification (primary_text, secondary_text, "");
        } else {
            notification.clear_hints ();
            notification.clear_actions ();
            notification.update (primary_text, secondary_text, "");
        }
        if (pixbuf != null)
            notification.set_image_from_pixbuf (pixbuf);
        else
            notification.icon_name = Icons.NOISE.name;

        notification.set_urgency ((Notify.Urgency) urgency);

        try {
            notification.show ();
        } catch (GLib.Error err) {
            warning ("Could not show notification: %s", err.message);
        }
#endif
    }

    public async void show_notification_from_media_async (Media media) {
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

        Gdk.Pixbuf? pixbuf = CoverartCache.instance.get_original_cover (media).scale_simple (128, 128, Gdk.InterpType.HYPER);

        if (!notification_cancellable.is_cancelled ()) {
#if HAVE_LIBNOTIFY
            show_notification (primary_text, secondary_text.str, pixbuf, Notify.Urgency.LOW);
#else
            show_notification (primary_text, secondary_text.str, pixbuf);
#endif
        }
    }

    private async void notify_current_media_async () {
        Idle.add (notify_current_media_async.callback);
        yield;

        if (App.player.media_info != null && App.player.media_info.media != null)
            yield show_notification_from_media_async (App.player.media_info.media);
    }


    /**
     * Sets the given view as the active item
     */
    public void set_active_view (ViewWrapper view) {
        if (!initialization_finished)
            return;

        view_container.set_current_view (view);

        if (view is ViewWrapper)
            (view as ViewWrapper).set_as_current_view ();
    }

    /**
     * Builds and sets up the default views. That includes main sidebar elements
     * and categories, which at the same time wrap treeviews, icon views, welcome screens, etc.
     */
    private void build_main_views () {
        debug ("Building main views ...");

        // Add Music Library View
        var music_view_wrapper = new MusicViewWrapper (null, library_manager);
        int view_number = view_container.add_view (music_view_wrapper);
        source_list_view.add_item  (view_number, _("Music"), ViewWrapper.Hint.MUSIC, Icons.MUSIC.gicon);
        // set as the current view
        view_container.set_current_view (music_view_wrapper);
        music_view_wrapper.set_as_current_view ();

        debug ("Done with main views.");
    }

    public void remove_view_and_update (int index) {
        view_container.remove_view (view_container.get_view (index));
    }

    private void load_playlists () {
        debug ("Loading playlists");
        
        library_manager.add_playlist (App.player.queue_playlist);
        library_manager.add_playlist (App.player.history_playlist);
        
        var treeview_setups = library_manager.dbm.load_columns_state ();
        
        foreach (SmartPlaylist p in library_manager.get_smart_playlists()) {
            addSourceListItem (p);
            match_smartplaylist_tvs.set (p.rowid, treeview_setups.get (p));
        }

        foreach (StaticPlaylist p in library_manager.get_playlists()) {
            if (p.name != App.player.queue_playlist.name && p.name != App.player.history_playlist.name)
                addSourceListItem (p);
            match_smartplaylist_tvs.set (p.rowid, treeview_setups.get (p));
        }

        debug ("Finished loading playlists");
    }
    

    /**
     * SourceList Configuration
     */

    public void update_badge_on_playlist_update (Playlist p, SourceListEntry entry) {
        match_playlist_entry.set (p, entry);
        p.media_added.connect((s) => { update_playlist_badge (p); });
        p.media_removed.connect((s) => { update_playlist_badge (p); });
    }

    private void update_playlist_badge (Playlist playlist) {
        var entry = match_playlist_entry.get (playlist);
        int media_count = playlist.medias.size;
        string new_badge = media_count > 0 ? media_count.to_string() : "";
        entry.badge = new_badge;
    }
    public void addSourceListItem (GLib.Object o, GLib.Object? source_o = null) {

        if (o is StaticPlaylist) {
            create_playlist_source_list ((StaticPlaylist) o);
        }
        else if(o is SmartPlaylist) {
            create_smartplaylist_source_list ((SmartPlaylist) o);
        }
        else if(o is Device) {
            create_device_source_list ((Device) o);
        }
        /*else if(o is NetworkDevice) {

            var nd_setup = new TreeViewSetup (ListColumn.ALBUM, Gtk.SortType.ASCENDING, ViewWrapper.Hint.NETWORK_DEVICE);
            var view = new NetworkDeviceViewWrapper (this, nd_setup, (Noise.NetworkDevice)o);
            add_view (((Noise.NetworkDevice)o).getDisplayName(), view, out iter);

            view.set_media_async (((Noise.NetworkDevice)o).get_medias ());
        }*/
        //source_list_added (o, view_number);
    }


    /**
     * Updating the interface
     */

    private bool update_sensitivities_pending = false;

    public async void update_sensitivities () {
        if (update_sensitivities_pending)
            return;

        update_sensitivities_pending = true;
        Idle.add_full (Priority.HIGH_IDLE + 30, update_sensitivities.callback);
        yield;

        update_sensitivities_sync ();
        update_sensitivities_pending = false;
    }
    private void update_sensitivities_sync () {
        debug ("UPDATE SENSITIVITIES");

        bool folder_set = library_manager.main_directory_set;
        bool have_media = library_manager.get_medias ().size > 0;
        bool doing_ops = library_manager.doing_file_operations ();
        bool media_active = App.player.media_active;

        fileImportMusic.set_sensitive (!doing_ops && folder_set);
        fileRescanMusicFolder.set_sensitive (!doing_ops && folder_set);

        if(doing_ops) {
            topDisplay.show_progressbar ();
        }
        else if(media_active && App.player.media_info.media.mediatype == 3) {
            topDisplay.hide_scale_and_progressbar ();
        }
        else {
            topDisplay.show_scale();
        }

        // Play, pause, ...
        bool media_available = App.player.current_media ().size > 0;
        previousButton.set_sensitive (media_active || media_available);
        playButton.set_sensitive (media_active || media_available);
        nextButton.set_sensitive (media_active || media_available);

        // hide playlists when media list is empty
        source_list_view.change_playlist_category_visibility (have_media);

        if(!App.player.media_active || have_media && !App.player.playing)
            playButton.set_stock_id(Gtk.Stock.MEDIA_PLAY);

        bool show_top_display = media_active || doing_ops;
        topDisplay.set_visible (show_top_display);

        topDisplay.set_scale_sensitivity(media_active);

        bool show_info_panel = saved_state.more_visible && info_panel.can_show_up;
        info_panel.set_visible (show_info_panel);

        statusbar.update_sensitivities ();
    }

    public void updateInfoLabel () {
        if(library_manager.doing_file_operations()) {
            debug ("doing file operations, returning in updateInfoLabel");
            return;
        }

        if(!App.player.media_active) {
            notification_manager.doSongNotification ("");
            debug ("setting info label as ''");
            return;
        }

        // Set the title
        var m = App.player.media_info.media;
        notification_manager.doSongNotification (m != null ? m.get_title_markup () : "");
    }

    /**
     * Devices
     */
    private void change_device_name (Device device) {
        int page_number = match_devices.get (device.get_unique_identifier());
        source_list_view.change_device_name (page_number, device.getDisplayName());
    }
    
    private void remove_device (Device device) {
        if (!match_devices.has_key (device.get_unique_identifier()))
            return;
        int page_number = match_devices.get (device.get_unique_identifier());
        foreach (int number in source_list_view.remove_device(page_number)) {
            remove_view_and_update (number);
        }
        match_devices.unset (device.get_unique_identifier());
        remove_view_and_update (page_number);
    }
    
    private void create_device_source_list (Device d) {
        lock (match_devices) {
        SourceListEntry? entry;
        var dv = new DeviceView (d);
        int view_number = view_container.add_view (dv);
        match_devices.set (d.get_unique_identifier(), view_number);
        if(d.has_custom_view()) {
            message("new custom device (probably a CD) added with %d songs.\n", d.get_library ().get_medias().size);

            entry = source_list_view.add_item  (view_number, d.getDisplayName(), ViewWrapper.Hint.DEVICE, d.get_icon(), Icons.EJECT_SYMBOLIC.gicon, null, d);
        } else {
            debug ("adding device view with %d\n", d.get_library ().get_medias().size);
            var music_view_wrapper = new DeviceViewWrapper(new TreeViewSetup(ListColumn.ARTIST, SortType.ASCENDING, ViewWrapper.Hint.DEVICE_AUDIO), d, d.get_library ());
            
            int subview_number = view_container.add_view (music_view_wrapper);
            entry = source_list_view.add_item  (view_number, d.getDisplayName(), ViewWrapper.Hint.DEVICE, d.get_icon(), Icons.EJECT_SYMBOLIC.gicon, null, d);
            source_list_view.add_item (subview_number, _("Music"), ViewWrapper.Hint.DEVICE_AUDIO, Icons.MUSIC.gicon, null, entry as SourceListExpandableItem, d);
            if (d.get_library ().support_playlists () == true) {
                foreach (var p in d.get_library ().get_playlists ()) {
                    create_playlist_source_list (p, (SourceListExpandableItem)entry, d.get_library ());
                }
                d.get_library ().playlist_added.connect ( (np) => {create_playlist_source_list (np, (SourceListExpandableItem)entry, d.get_library ());});
                d.get_library ().playlist_removed.connect ( (np) => {create_playlist_source_list (np, (SourceListExpandableItem)entry, d.get_library ());});
            }
        }
    }
    }

    /**
     * StaticPlaylists
     */
    private void add_playlist (StaticPlaylist playlist) {
        addSourceListItem (playlist, null);
    }

    private void remove_playlist (StaticPlaylist playlist) {
        int page_number = match_playlist.get (playlist.rowid);
        lock (match_playlist) {
            source_list_view.remove_playlist(page_number);
            match_playlist.unset (playlist.rowid);
        }
        remove_view_and_update (page_number);
    }

    public void create_new_playlist (Library? library = library_manager) {
        var playlist = new StaticPlaylist ();
        playlist.name = PlaylistsUtils.get_new_playlist_name (library_manager.get_playlists ());
        library.add_playlist(playlist);
    }

    public TreeViewSetup? get_treeviewsetup_from_playlist (StaticPlaylist sp) {
        int index = 0;
        while (view_container.get_view (index) != null && sp != null) {
            Gtk.Widget view = view_container.get_view (index);
            if (view is PlaylistViewWrapper) {
                if (((PlaylistViewWrapper)view).playlist_id == sp.rowid) {
                    return ((PlaylistViewWrapper)view).tvs;
                }
            }
            index++;
        }
        return null;
    }
    
    private void create_playlist_source_list (StaticPlaylist p, SourceListExpandableItem? into_expandable = null, Library? library = library_manager) {
        SourceListEntry? entry;
        int view_number;
        if (p.read_only == false) {
            var view = new PlaylistViewWrapper (p.rowid, ViewWrapper.Hint.PLAYLIST, null, library);
            view_number = view_container.add_view (view);
            entry = source_list_view.add_item  (view_number, p.name, ViewWrapper.Hint.PLAYLIST, p.icon, null, into_expandable);
        } else {
            if (p.name == C_("Name of the playlist", "Queue")) {
                var queue_view = new ReadOnlyPlaylistViewWrapper (App.player.queue_playlist.rowid, 
                                        match_playlist_tvs.get (App.player.queue_playlist.rowid), true, library);
                queue_view.set_no_media_alert_message (_("No songs in Queue"), 
                        _("To add songs to the queue, use the <b>secondary click</b> on an item and choose <b>Queue</b>. When a song finishes, the queued songs will be played first before the next song in the currently playing list."), Gtk.MessageType.INFO);
                view_number = view_container.add_view (queue_view);
                entry = source_list_view.add_item  (view_number, App.player.queue_playlist.name,
                                                    ViewWrapper.Hint.READ_ONLY_PLAYLIST, Icons.QUEUE.gicon);
                update_badge_on_playlist_update (p, entry);
                App.player.queue_media (p.medias);
            } else if (p.name == _("History")) {
                var history_view = new ReadOnlyPlaylistViewWrapper (App.player.history_playlist.rowid, 
                                                match_playlist_tvs.get(App.player.history_playlist.rowid), false, library);
                history_view.set_no_media_alert_message (_("No songs in History"), 
                        _("After a part of a song has been played, it is added to the history list.\nYou can use this list to see all the songs you have played during the current session."), Gtk.MessageType.INFO);
                view_number = view_container.add_view (history_view);
                entry = source_list_view.add_item  (view_number, App.player.history_playlist.name,
                                                    ViewWrapper.Hint.READ_ONLY_PLAYLIST, Icons.HISTORY.gicon);
                App.player.history_playlist.add_medias (p.medias);
            } else {
                var view = new ReadOnlyPlaylistViewWrapper (p.rowid, match_playlist_tvs.get(p.rowid), false, library);
                view_number = view_container.add_view (view);
                entry = source_list_view.add_item  (view_number, p.name, ViewWrapper.Hint.READ_ONLY_PLAYLIST, p.icon, null, into_expandable);
                if (p.show_badge == true) {
                    update_badge_on_playlist_update (p, entry);
                }
            }
        }
    }

    /**
     * SmartPlaylists
     */
    public TreeViewSetup? get_treeviewsetup_from_smartplaylist (SmartPlaylist sp) {
        int index = 0;
        while (view_container.get_view (index) != null && sp != null) {
            Gtk.Widget view = view_container.get_view (index);
            if (view is PlaylistViewWrapper) {
                if (((PlaylistViewWrapper)view).playlist_id == sp.rowid) {
                    return ((PlaylistViewWrapper)view).tvs;
                }
            }
            index++;
        }
        return null;
    }

    private void add_smartplaylist (SmartPlaylist smartplaylist) {
        addSourceListItem (smartplaylist);
    }

    private void remove_smartplaylist (SmartPlaylist smartplaylist) {
        int page_number = match_smartplaylist.get (smartplaylist.rowid);
        lock (match_smartplaylist) {
            match_smartplaylist.unset (smartplaylist.rowid);
            source_list_view.remove_playlist(page_number);
        }
        remove_view_and_update (page_number);
    }

    private void playlist_name_edited (int page_number, string new_name) {
        var unparsed_view = view_container.get_view (page_number);
        if (unparsed_view is PlaylistViewWrapper) {
            var view = unparsed_view as PlaylistViewWrapper;
            if (view.hint == ViewWrapper.Hint.PLAYLIST || view.hint == ViewWrapper.Hint.READ_ONLY_PLAYLIST) {
                var playlist = library_manager.playlist_from_id(((PlaylistViewWrapper)view).playlist_id);
                if (playlist.name != new_name) {
                    if (library_manager.playlist_from_name (new_name) == null) {
                        playlist.name = new_name;
                        library_manager.playlist_name_updated (playlist);
                    }
                }
            } else if (view.hint == ViewWrapper.Hint.SMART_PLAYLIST) {
                var smartplaylist = library_manager.smart_playlist_from_id(((PlaylistViewWrapper)view).playlist_id);
                if (smartplaylist.name != new_name) {
                    if (library_manager.smart_playlist_from_name (new_name) == null) {
                        smartplaylist.name = new_name;
                        library_manager.smartplaylist_name_updated (smartplaylist);
                    }
                }
            }
        }
    }
    private void create_smartplaylist_source_list (SmartPlaylist p, SourceListExpandableItem? into_expandable = null) {
        SourceListEntry? entry;
        int view_number;
        
        var view = new PlaylistViewWrapper (p.rowid, ViewWrapper.Hint.SMART_PLAYLIST, match_smartplaylist_tvs.get(p.rowid), library_manager);
        view.button_clicked.connect ((playlist_id) => {
            show_smart_playlist_dialog(library_manager.smart_playlist_from_id(playlist_id));
        });
        view_number = view_container.add_view (view);
        entry = source_list_view.add_item  (view_number, p.name, ViewWrapper.Hint.SMART_PLAYLIST, p.icon);
        p.updated.connect ((old_name) => {
            if (old_name != null)
                source_list_view.change_playlist_name (match_smartplaylist.get(p.rowid), p.name);
        });
        lock (match_smartplaylist) {
            match_smartplaylist.set (p.rowid, view_number);
        }
    }

    /**
     * Dialogs from the interface
     */

    public void show_smart_playlist_dialog (SmartPlaylist? smartplaylist = null) {
        SmartPlaylistEditor spe = null;
        spe = new SmartPlaylistEditor (smartplaylist, library_manager);
        spe.window_position = WindowPosition.CENTER;
        spe.type_hint = Gdk.WindowTypeHint.DIALOG;
        spe.set_transient_for (this);
        spe.set_modal(true);
        spe.destroy_with_parent = true;
        spe.show_all();
        spe.load_smart_playlist ();
    }

    /** This should be used whenever a call to play a new media is made
     *
     * XXX: this doesn't belong here, but to the playback manager
     * @param s The media that is now playing
     */
    public void media_played (Media m) {

        updateInfoLabel ();

        //reset the media position
        topDisplay.set_scale_sensitivity(true);
        topDisplay.set_media (App.player.media_info.media);

        //reset some booleans
        tested_for_video = false;
        media_considered_previewed = false;
        media_considered_played = false;
        added_to_play_count = false;
        media_half_played_sended = false;
        
        update_sensitivities.begin ();

        Timeout.add(3000, () => {
            if (App.player.media_info.media != null && App.player.media_info.media == m) {
                update_media_info(App.player.media_info.media);
            }
            
            return false;
        });
    }


    public virtual void playback_stopped(int was_playing) {
        //reset some booleans
        tested_for_video = false;
        media_considered_previewed = false;
        media_considered_played = false;
        added_to_play_count = false;

        update_sensitivities.begin ();

        debug ("stopped\n");
    }

    public virtual void medias_updated(Collection<int> ids) {
        if(App.player.media_active && ids.contains(App.player.media_info.media.rowid)) {
            updateInfoLabel();
        }
    }

    public virtual void play_media (bool inhibit_notifications = false) {
        if(!App.player.media_active) {
            debug("No media is currently playing. Starting from the top\n");

            App.player.getNext (true);
            App.player.playing = true;
            playButton.set_stock_id(Gtk.Stock.MEDIA_PAUSE);
            App.player.player.play();

            if (!inhibit_notifications)
                notify_current_media_async.begin ();
        }
        else {
            if(App.player.playing) {
                App.player.playing = false;
                App.player.player.pause();

                playButton.set_stock_id(Gtk.Stock.MEDIA_PLAY);
            }
            else {
                App.player.playing = true;
                App.player.player.play();
                playButton.set_stock_id(Gtk.Stock.MEDIA_PAUSE);
            }
        }

        playPauseChanged();
    }

    public virtual void play_next_media (bool inhibit_notifications = false) {
        // if not 90% done, skip it
        if(!added_to_play_count) {
            App.player.media_info.media.skip_count++;

            // don't update, it will be updated eventually
            //library_manager.update_media_item (App.player.media_info.media, false, false);
        }

        Media? m = null;
        if(App.player.next_gapless_id != 0) {
            int next_id = App.player.next_gapless_id;
            m = library_manager.media_from_id (next_id);
            App.player.playMedia (m, false);
        } else
            m = App.player.getNext (true);

        /* test to stop playback/reached end */
        if(m == null) {
            App.player.player.pause();
            App.player.playing = false;
            update_sensitivities.begin ();
            return;
        }

        if (!inhibit_notifications)
            notify_current_media_async.begin ();
    }

    public virtual void play_previous_media (bool inhibit_notifications = false) {
        if(App.player.player.get_position() < 5000000000 || (App.player.media_active && App.player.media_info.media.mediatype == 3)) {
            bool play = true;
            var prev = App.player.getPrevious(true);

            /* test to stop playback/reached end */
            if(prev == null) {
                App.player.player.pause();
                App.player.playing = false;
                update_sensitivities.begin ();
                return;
            } else if (play && !inhibit_notifications) {
                notify_current_media_async.begin ();
            }
        } else
            topDisplay.change_value(ScrollType.NONE, 0);
    }

    public virtual void fileImportMusicClick() {
        if(!library_manager.doing_file_operations()) {

            var folders = new Gee.ArrayList<string> ();
            var file_chooser = new FileChooserDialog (_("Import Music"), this,
                                      FileChooserAction.SELECT_FOLDER,
                                      Gtk.Stock.CANCEL, ResponseType.CANCEL,
                                      Gtk.Stock.OPEN, ResponseType.ACCEPT);
            file_chooser.set_select_multiple (true);
            file_chooser.set_local_only(true);

            if (file_chooser.run () == ResponseType.ACCEPT) {
                foreach (var folder in file_chooser.get_filenames()) {
                    folders.add (folder);
                }
            }
            file_chooser.destroy ();


            // cancelled
            if (folders.is_empty)
                return;

            if(GLib.File.new_for_path (main_settings.music_folder).query_exists()) {
                topDisplay.set_label_markup(_("<b>Importing</b> music to library…"));
                topDisplay.show_progressbar();

                library_manager.add_folder_to_library (folders);
                update_sensitivities.begin ();
            }
        }
        else {
            debug("Can't add to library.. already doing file operations\n");
        }
    }

    public void rescan_music_folder () {
        if (!library_manager.doing_file_operations ()) {
            if (GLib.File.new_for_path (main_settings.music_folder).query_exists()) {
                topDisplay.set_label_markup("<b>" + _("Rescanning music folder for changes") + "</b>");
                topDisplay.show_progressbar();

                library_manager.rescan_music_folder();
                update_sensitivities.begin ();
            }
            else {
                doAlert(_("Could not find Music Folder"), _("Please make sure that your music folder is accessible and mounted."));
            }
        }
        else {
            debug ("Can't rescan.. doing file operations already\n");
        }
    }
    
    public virtual void musicCounted(int count) {
        debug ("found %d media, importing.\n", count);
    }

    /* this is after setting the music library */
    public virtual void musicAdded (Gee.Collection<string> not_imported) {
        if(App.player.media_active)
            updateInfoLabel();
        else
            topDisplay.set_label_text("");

        if(not_imported.size > 0) {
            NotImportedWindow nim = new NotImportedWindow(not_imported, main_settings.music_folder);
            nim.show();
        }

        update_sensitivities.begin ();
    }

    /* this is when you import music from a foreign location into the library */
    public virtual void musicImported(Collection<Media> imported, Collection<string> not_imported) {
        if (App.player.media_active)
            updateInfoLabel();
        else
            topDisplay.set_label_text("");

        //resetSideTree(false);

        update_sensitivities.begin ();


        //now notify user
        if (imported.size > 0)
            show_notification (_("Import Complete"), _("%s has imported your library.").printf (App.instance.get_name ()));
    }

    public virtual void musicRescanned (Gee.Collection<Media> new_medias, Gee.Collection<string> not_imported) {
        if (App.player.media_active)
            updateInfoLabel ();
        else
            topDisplay.set_label_text ("");

        //resetSideTree(false);
        debug("music Rescanned\n");
        update_sensitivities.begin ();
    }

    public void editPreferencesClick() {
        if (preferences == null)
            preferences = new PreferencesWindow(this);
        preferences.show_all ();
        preferences.run ();
        preferences.hide ();
    }

    public void setMusicFolder(string folder) {
        if (library_manager.doing_file_operations ())
            return;

        // If different folder chosen or we have no songs anyways, do set.
        if (folder == "" || (folder == main_settings.music_folder && !library_manager._medias.is_empty))
            return;

        if (!library_manager._medias.is_empty || !library_manager._playlists.is_empty) {
            var smfc = new SetMusicFolderConfirmation(folder);
            smfc.finished.connect( (cont) => {
                if(cont) {
                    library_manager.set_music_folder.begin (folder);
                }
            });
        }
        else {
            library_manager.set_music_folder.begin (folder);
            
            //resetSideTree (true);
        }
    }

    public virtual void end_of_stream() {
        play_next_media ();
    }

    public virtual void error_occured () {
        if(App.player.media_active) {
            play_media ();
        }
    }

    public virtual void current_position_update (int64 position) {
        if (!App.player.media_active)
            return;

        double sec = ((double)position/1000000000);
        double media_length = ((double)App.player.media_info.media.length/1000);

        if(App.player.file_player.set_resume_pos)
            App.player.media_info.media.resume_pos = (int)sec;

        // at about 3 seconds, update last fm. we wait to avoid excessive querying last.fm for info
        if(sec > 3 && !media_considered_previewed) {
            media_considered_previewed = true;
            update_media_info (App.player.media_info.media);
        }

        //at 30 seconds in, we consider the media as played
        if(sec > 30 && !media_considered_played) {
            media_considered_played = true;
            App.player.media_info.media.last_played = (int)time_t();

            library_manager.update_media (App.player.media_info.media, false, false);

            // add to the already played list
            if(!App.player.history_playlist.medias.contains (App.player.media_info.media)) {
                var temp_media = new Gee.LinkedList<Media>();
                temp_media.add (App.player.media_info.media);
                App.player.history_playlist.add_medias (temp_media);
            }

#if HAVE_ZEITGEIST
            var event = new Zeitgeist.Event.full (Zeitgeist.ZG_ACCESS_EVENT,
                                                   Zeitgeist.ZG_SCHEDULED_ACTIVITY, "app://%s".printf (App.instance.get_desktop_file_name ()),
                                                   new Zeitgeist.Subject.full(App.player.media_info.media.uri,
                                                                               Zeitgeist.NFO_AUDIO,
                                                                               Zeitgeist.NFO_FILE_DATA_OBJECT,
                                                                               "text/plain", "",
                                                                               App.player.media_info.media.title, ""));
            new Zeitgeist.Log ().insert_events_no_reply(event);
#endif
        }

        if((sec/media_length > 0.50) && (media_half_played_sended == false)) {
            media_half_played (App.player.media_info.media);
            media_half_played_sended = true;
        }

        // at 80% done with media, add 1 to play count
        if(sec/media_length > 0.80 && !added_to_play_count) {
            added_to_play_count = true;
            App.player.media_info.media.play_count++;
            library_manager.update_media (App.player.media_info.media, false, false);
        }
    }

    public void media_not_found(int id) {
// XXX FIXME TODO Don't depend on ids
#if 0
        var not_found = new FileNotFoundDialog(library_manager, this, id);
        not_found.show();
#endif
    }

    public void searchFieldActivate() {
        var vw = view_container.get_current_view ();

        if (vw != null && vw is ViewWrapper) {
            (vw as ViewWrapper).play_first_media ();
        }
    }

    public virtual void dragReceived (Gdk.DragContext context, int x, int y, Gtk.SelectionData data, uint info, uint timestamp) {
        if (dragging_from_music)
            return;

        var files_dragged = new LinkedList<string> ();

        debug("dragged\n");

        foreach (string uri in data.get_uris ()) {
            files_dragged.add (File.new_for_uri (uri).get_path ());
        }

        library_manager.add_files_to_library (files_dragged);
    }

    public void doAlert(string title, string message) {
        var dialog = new MessageDialog (this, DialogFlags.MODAL, MessageType.ERROR, ButtonsType.OK, title);

        dialog.title = App.instance.get_name ();
        dialog.secondary_text = message;
        dialog.secondary_use_markup = true;

        dialog.run();
        dialog.destroy();
    }

    private void on_quit () {
        // Save media position and info
        main_settings.last_media_position = (int)((double)App.player.player.get_position
        ()/Numeric.NANO_INV);
        if(App.player.media_active) {
            App.player.media_info.media.resume_pos = (int)((double)App.player.player.get_position()/Numeric.NANO_INV);
            library_manager.update_media (App.player.media_info.media, false, false);
        }
        App.player.player.pause();

        // Now set the selected view
        saved_state.view_mode = viewSelector.selected;

        // Search FIXME: Temporarily disabled
        //main_settings.search_string = searchField.get_text ();
        
        // Save info pane (context pane) width
        saved_state.more_width = info_panel.get_allocated_width ();

        // Save sidebar width
        saved_state.sidebar_width = main_hpaned.position;


        // Save window state
        if (window_maximized)
                saved_state.window_state = WindowState.MAXIMIZED;
        else if (window_fullscreen)
                saved_state.window_state = WindowState.FULLSCREEN;
        else
                saved_state.window_state = WindowState.NORMAL;

        saved_state.window_width = window_width;
        saved_state.window_height = window_height;
    }

    /**
     * Called when the user tries to quit the application using a mechanism provided
     * by the desktop shell (close button, quicklists, etc.)
     *
     * This doesn't apply to calls to App.instance.quit ()
     */
    public override bool delete_event (Gdk.EventAny event) {
        bool playing = App.player.media_active && App.player.playing;

        // if playing a song, don't allow closing
        if (!main_settings.close_while_playing && playing) {
            if (minimize_on_close ()) 
                iconify (); // i.e. minimize
             else 
                hide ();
            

            return true;
        }

        return false; // can exit
    }

    /**
     * Checks whether the window should be hidden or minimized when closing the
     * application. The caller is responsible for checking whether there's an active
     * song and whether the close_while_playing option is enabled on settings. This
     * method assumes that both are true and returns a value based on that.
     *
     * @return true if the window should be minimized; false if it should be hidden.
     */
    public static bool minimize_on_close () {
        bool minimize_on_close = false;
        string? current_shell = Utils.get_desktop_shell ();

        if (current_shell != null) {
            debug ("Current shell: %s", current_shell);

            foreach (string shell in main_settings.minimize_while_playing_shells) {
                if (current_shell == shell) {
                    debug ("Using supported minimize_on_close shell");
                    minimize_on_close = true;
                    break;
                }
            }
        }

        return minimize_on_close;
    }

    public override bool configure_event (Gdk.EventConfigure event) {
        // Get window dimensions.
        window_maximized = (get_window ().get_state () == Gdk.WindowState.MAXIMIZED);

        if (!(window_maximized || window_fullscreen))
            get_size (out window_width, out window_height);

        return base.configure_event (event);
    }
}

