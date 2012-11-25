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

    public Noise.LibraryManager library_manager { get { return App.library_manager; } }

    /* Info related to the media being played */
    private bool media_considered_played    { get; set; default = false; } // whether or not we have updated last played and added to already played list
    private bool added_to_play_count        { get; set; default = false; } // whether or not we have added one to play count on playing media
    private bool tested_for_video           { get; set; default = false; } // whether or not we have tested if media is video and shown video
    private bool media_considered_previewed { get; set; default = false; }
    private bool media_half_played_sended   { get; set; default = false; }

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
    public SideTreeView               sideTree         { get; private set; }
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

    public signal void media_half_played (); // send after the half of the song
    public signal void update_media_info (); // send after 3 seconds
    
    PreferencesWindow? preferences = null;

    public LibraryWindow () {
        //FIXME? App.player.player.media_not_found.connect (media_not_found);
        this.library_manager.music_counted.connect (musicCounted);
        this.library_manager.music_added.connect (musicAdded);
        this.library_manager.music_imported.connect (musicImported);
        this.library_manager.music_rescanned.connect (musicRescanned);

        this.library_manager.media_updated.connect (medias_updated);
        this.library_manager.media_added.connect (update_sensitivities);
        this.library_manager.media_removed.connect (update_sensitivities);

        this.library_manager.progress_notification.connect (progressNotification);

        App.player.player.end_of_stream.connect (end_of_stream);
        App.player.player.current_position_update.connect (current_position_update);
        App.player.player.error_occured.connect (error_occured);
        App.player.media_played.connect_after (media_played);
        App.player.playback_stopped.connect (playback_stopped);


        // init some booleans
        if (main_settings.music_folder == "") {
            main_settings.music_folder = GLib.Environment.get_user_special_dir (GLib.UserDirectory.MUSIC);
            message("First run.\n");
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
    
    public TreeViewSetup? get_treeviewsetup_from_playlist (Playlist sp) {
        int index = 0;
        while (view_container.get_view (index) != null) {
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
    public void set_treeviewsetup_from_playlist (Playlist sp, TreeViewSetup tvs) {
        int index = 0;
        while (view_container.get_view (index) != null) {
            Gtk.Widget view = view_container.get_view (index);
            if (view is PlaylistViewWrapper) {
                if (((PlaylistViewWrapper)view).playlist_id == sp.rowid) {
                    ((PlaylistViewWrapper)view).tvs = tvs;
                }
            }
            index++;
        }
    }

    public override bool key_press_event (Gdk.EventKey event) {
        if (!searchField.has_focus) {
            switch (event.keyval) {
                case Gdk.Key.space:
                    playClicked();
                    return true;
                    break;
                case Gdk.Key.q:
                case Gdk.Key.w:
                    if ((event.state & Gdk.ModifierType.CONTROL_MASK) != 0)
                        this.destroy();
                    break;
            }
        }
       var typed_unichar = event.str.get_char ();
       // Redirect valid key presses to the search entry
       if (typed_unichar.validate () && searchField.sensitive && !searchField.has_focus) {
            unichar[] special_chars = {'&', '.', '-', '\'', '%', '(', ')', '=', '@', '!',
                                        '#', '+', '<', '>', ';', ':', '¿', '?', '¡', '~',
                                        '_', '¨', '*', '$', '"', '[', ']'};

            if (typed_unichar.isalnum () || typed_unichar in special_chars)
                searchField.grab_focus ();
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

        editPreferences.set_label (_("Preferences..."));

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
        topDisplay              = new TopDisplay (library_manager);
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

        info_panel = new InfoPanel (library_manager, this);


        /** Statusbar widgets **/

        statusbar = new Widgets.StatusBar (this);


        /** Main layout **/

        verticalBox           = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_hpaned           = new Granite.Widgets.ThinPaned ();
        view_container_hpaned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
        view_container        = new ViewContainer ();
        sideTree              = new SideTreeView (library_manager, this);

        // Set properties of various controls
        main_hpaned.position = saved_state.sidebar_width;
        int view_container_pos = saved_state.window_width - saved_state.sidebar_width - saved_state.more_width;
        view_container_hpaned.set_position (view_container_pos);

        view_container_hpaned.pack1 (view_container, true, false);
        view_container_hpaned.pack2 (info_panel, false, false);

        // put the sidebar in a scrolled window so that it can scroll vertically
        var sidebar_scrolled = new Gtk.ScrolledWindow (null, null);
        sidebar_scrolled.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
        sidebar_scrolled.add (sideTree);

        main_hpaned.pack1 (sidebar_scrolled, false, false);
        main_hpaned.pack2 (view_container_hpaned, true, false);

        // Add controls to the GUI
        verticalBox.pack_start (main_toolbar, false, false, 0);
        verticalBox.pack_start (main_hpaned, true, true, 0);
        verticalBox.pack_end (statusbar, false, false, 0);

        this.add (verticalBox);

        // Make all the widgets visible
        verticalBox.show_all ();

        debug ("Done with main widgets");
    }

    public void build_ui () {
        debug ("BUILDING USER INTERFACE");

        setup_window ();

        build_main_widgets ();

        // add mounts to side tree view
        library_manager.device_manager.loadPreExistingMounts();

        build_main_views ();
        load_playlists ();
        sideTree.resetView ();
        update_sensitivities_sync (); // we need to do this synchronously to avoid weird initial states

        // Now set the selected view
        viewSelector.selected = (Widgets.ViewSelector.Mode) saved_state.view_mode;

        initialization_finished = true;

        if (library_manager.media_count () < 1)
            setMusicFolder (Environment.get_user_special_dir(UserDirectory.MUSIC));

        /* Connect events to functions */
        previousButton.clicked.connect(previousClicked);
        playButton.clicked.connect(playClicked);
        nextButton.clicked.connect(nextClicked);

        searchField.activate.connect (searchFieldActivate);
        searchField.set_text (main_settings.search_string);

        debug ("DONE WITH USER INTERFACE");

        int last_playing_id = main_settings.last_media_playing;

        if (last_playing_id > 0) {
            var last_playing_media = library_manager.media_from_id (last_playing_id);
            if (last_playing_media != null && last_playing_media.file.query_exists ())
                App.player.playMedia (last_playing_media, true);
        }
    }


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
     * Description:
     * Builds the views (view wrapper) and adds the respective element to the sidebar TreeView.
     *
     * @return true if succeeds, false if fails.
     */
    public bool add_view (string view_name, ViewWrapper view_wrapper, out TreeIter? iter = null) {
        iter = null;

        /* Pack view wrapper into the main views */
        if (view_name == null || view_container.add_view (view_wrapper) < 0) {
            critical ("Failed to append view: %s", view_name);
            return false;
        }

        iter = sideTree.add_item (view_wrapper, view_name);

        return true;
    }

    /**
     * Sets the given view as the active item
     *
     * TODO: change Gtk.Widget to ViewWrapper when the transition of
     *       devices to the new API is finished
     */
    public void set_active_view (Gtk.Widget view) {
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
        var music_view_wrapper = new MusicViewWrapper (this);
        add_view (_("Music"), music_view_wrapper);

        debug ("Done with main views.");
    }
    
    private void load_playlists () {
        debug ("Loading playlists");

        // Add Queue view
        var queue_view = new QueueViewWrapper (this);
        add_view (C_("Name of the playlist", "Queue"), queue_view);

        // Add History view
        var history_view = new HistoryViewWrapper (this);
        add_view (_("History"), history_view);

        foreach (SmartPlaylist p in library_manager.smart_playlists()) {
            addSideListItem (p);
        }

        // load playlists.
        foreach (Playlist p in library_manager.playlists()) {
            addSideListItem (p);
        }

        debug ("Finished loading playlists");
    }

    public TreeIter addSideListItem (GLib.Object o) {
        TreeIter iter = sideTree.library_music_iter; //just a default

        if(o is Playlist) {
            Playlist p = o as Playlist;

            var view = new PlaylistViewWrapper (this, p.rowid, ViewWrapper.Hint.PLAYLIST);
            add_view (p.name, view, out iter);
        }
        else if(o is SmartPlaylist) {
            var p = o as SmartPlaylist;
            
            var view = new PlaylistViewWrapper (this, p.rowid, ViewWrapper.Hint.SMART_PLAYLIST);
            add_view (p.name, view, out iter);
        }
        /* XXX: Migrate this code to the new ViewWrapper API */
        else if(o is Device) {
            Device d = (Device)o;

            if(d.has_custom_view()) {

                message("new custom device (probably a CD) added with %d songs.\n", d.get_medias().size);

                Gtk.Grid dv = d.get_custom_view();
                iter = sideTree.addSideItem(sideTree.devices_iter, d, dv, d.getDisplayName(), ViewWrapper.Hint.NONE);
                view_container.add_view (dv);
            } else {
                debug ("adding device view with %d\n", d.get_medias().size);
                DeviceView dv = new DeviceView (library_manager, d);
                //vw = new DeviceViewWrapper(this, d.get_medias(), "Artist", Gtk.SortType.ASCENDING, ViewWrapper.Hint.DEVICE, -1, d);
                iter = sideTree.addSideItem(sideTree.devices_iter, d, dv, d.getDisplayName(), ViewWrapper.Hint.NONE);
                view_container.add_view (dv);
            }
        }
        /*else if(o is NetworkDevice) {

            var nd_setup = new TreeViewSetup (ListColumn.ALBUM, Gtk.SortType.ASCENDING, ViewWrapper.Hint.NETWORK_DEVICE);
            var view = new NetworkDeviceViewWrapper (this, nd_setup, (Noise.NetworkDevice)o);
            add_view (((Noise.NetworkDevice)o).getDisplayName(), view, out iter);

            view.set_media_async (((Noise.NetworkDevice)o).get_medias ());
        }*/

        return iter;
    }


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

    /**
     * This is handled more carefully inside each ViewWrapper object.
     */
    private void update_sensitivities_sync () {
        debug ("UPDATE SENSITIVITIES");

        bool folder_set = library_manager.main_directory_set;
        bool have_media = library_manager.have_media;
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
        sideTree.setVisibility (sideTree.playlists_iter, have_media);

        if(!App.player.media_active || have_media && !App.player.playing)
            playButton.set_stock_id(Gtk.Stock.MEDIA_PLAY);

        bool show_top_display = media_active || doing_ops;
        topDisplay.set_visible (show_top_display);

        topDisplay.set_scale_sensitivity(media_active);

        bool show_info_panel = saved_state.more_visible && info_panel.can_show_up;
        info_panel.set_visible (show_info_panel);

        statusbar.update_sensitivities ();
    }

    public virtual void progressNotification(string? message, double progress) {
        if(message != null && progress >= 0.0 && progress <= 1.0)
            topDisplay.set_label_markup(message);

        topDisplay.set_progress_value(progress);
    }

    public void updateInfoLabel () {
        if(library_manager.doing_file_operations()) {
            debug ("doing file operations, returning in updateInfoLabel");
            return;
        }

        if(!App.player.media_active) {
            topDisplay.set_label_markup("");
            debug ("setting info label as ''");
            return;
        }

        // Set the title
        var m = App.player.media_info.media;
        topDisplay.set_label_markup (m != null ? m.get_title_markup () : "");
    }


    /** This should be used whenever a call to play a new media is made
     *
     * XXX: this doesn't belong here, but to the playback manager or Last.fm plugin
     * @param s The media that is now playing
     */
    public void media_played(Media m) {
        /*if(old == -2 && i != -2) { // -2 is id reserved for previews
            Media s = settings.getLastMediaPlaying();
            s = library_manager.media_from_name(s.title, s.artist);

            if(s.rowid != 0) {
                library_manager.playMedia(s.rowid);
                int position = (int)settings.getLastMediaPosition();
                topDisplay.change_value(ScrollType.NONE, position);
            }

            return;
        }*/

        updateInfoLabel();

        //reset the media position
        topDisplay.set_scale_sensitivity(true);
        topDisplay.set_media (App.player.media_info.media);

        /*if(m.mediatype == 1 || m.mediatype == 2) {
            /*message("setting position to resume_pos which is %d\n", library_manager.media_from_id(i).resume_pos );
            Timeout.add(250, () => {
                topDisplay.change_value(ScrollType.NONE, library_manager.media_from_id(i).resume_pos);
                return false;
            });*
        }
        else {
            topDisplay.change_value(ScrollType.NONE, 0);
        }*/

        //if(!mediaPosition.get_sensitive())
        //    mediaPosition.set_sensitive(true);

        //reset some booleans
        tested_for_video = false;
        media_considered_previewed = false;
        media_considered_played = false;
        added_to_play_count = false;
        media_half_played_sended = false;
        
        update_sensitivities();

        Timeout.add(3000, () => {
            if (App.player.media_info.media != null && App.player.media_info.media == m) {
                update_media_info();
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

        update_sensitivities();

        debug ("stopped\n");
    }

    public virtual void medias_updated(Collection<int> ids) {
        if(App.player.media_active && ids.contains(App.player.media_info.media.rowid)) {
            updateInfoLabel();
        }
    }


    /**
     * @deprecated. Use play_media()
     */
    public virtual void playClicked () {
        play_media ();
    }


    /**
     * @deprecated. Use play_next_media()
     */
    public virtual void nextClicked () {
        play_next_media ();
    }


    /**
     * @deprecated. Use play_previous_media()
     */
    public virtual void previousClicked () {
        play_previous_media ();
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
        }
        else
            m = App.player.getNext(true);

        /* test to stop playback/reached end */
        if(m == null) {
            App.player.player.pause();
            App.player.playing = false;
            update_sensitivities();
            return;
        }

        if (!inhibit_notifications)
            notify_current_media_async.begin ();
    }

    public virtual void play_previous_media (bool inhibit_notifications = false) {
        if(App.player.player.getPosition() < 5000000000 || (App.player.media_active && App.player.media_info.media.mediatype == 3)) {
            bool play = true;
            var prev = App.player.getPrevious(true);

            /* test to stop playback/reached end */
            if(prev == null) {
                App.player.player.pause();
                App.player.playing = false;
                update_sensitivities();
                return;
            }
            else if (play && !inhibit_notifications) {
                notify_current_media_async.begin ();
            }
        }
        else
            topDisplay.change_value(ScrollType.NONE, 0);
    }

    public virtual void fileImportMusicClick() {
        if(!library_manager.doing_file_operations()) {
            /*if(!(GLib.File.new_for_path(library_manager.settings.getMusicFolder()).query_exists() && library_manager.settings.getCopyImportedMusic())) {
                var dialog = new MessageDialog(this, DialogFlags.DESTROY_WITH_PARENT, MessageType.ERROR, ButtonsType.OK,
                "Before importing, you must mount your music folder.");

                var result = dialog.run();
                dialog.destroy();

                return;
            }*/

            string folders_list = "";
            string[] folders = new string[0];
            var _folders = new SList<string> ();
            var file_chooser = new FileChooserDialog (_("Import Music"), this,
                                      FileChooserAction.SELECT_FOLDER,
                                      Gtk.Stock.CANCEL, ResponseType.CANCEL,
                                      Gtk.Stock.OPEN, ResponseType.ACCEPT);
            file_chooser.set_select_multiple (true);
            file_chooser.set_local_only(true);

            if (file_chooser.run () == ResponseType.ACCEPT) {
                _folders = file_chooser.get_filenames();
            }
            file_chooser.destroy ();


            // cancelled
            if (_folders.length () <= 0)
                return;


            for (uint i = 0; i < _folders.length (); i++) {
                var folder = _folders.nth_data (i);
                folders += folder;
            }

            for (int i=0;i<folders.length;i++) {
                if(folders[i] == "" || folders[i] != main_settings.music_folder) {
                    folders_list += folders[i];
                    if (i + 1 != folders.length)
                        folders_list += ", ";
                }
            }

            if(GLib.File.new_for_path (main_settings.music_folder).query_exists()) {
                topDisplay.set_label_markup(_("<b>Importing</b> music from <b>%s</b> to library.").printf(folders_list));
                topDisplay.show_progressbar();

                library_manager.add_folder_to_library(folders[0], folders[1:folders.length]);
                update_sensitivities();
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
                update_sensitivities();
            }
            else {
                doAlert(_("Could not find Music Folder"), _("Please make sure that your music folder is accessible and mounted."));
            }
        }
        else {
            debug ("Can't rescan.. doing file operations already\n");
        }
    }

    public void resetSideTree (bool clear_views) {
        sideTree.resetView ();

        // clear all other playlists, reset to Music, populate music
        if (clear_views) {
            message ("clearing all views...\n");

            view_container.get_children ().foreach( (w) => {
                if (w is ViewWrapper && !(w is DeviceViewWrapper)) {
                    ViewWrapper vw = w as ViewWrapper;
                    debug("doing clear\n");
                    //vw.do_update(vw.current_view, new LinkedList<int>(), true, true, false);
                    vw.set_media_async (new Gee.LinkedList<Media> ());
                    debug("cleared\n");
                }
            });

            message("all cleared\n");
        }
        else {
            var vw = sideTree.getWidget (sideTree.library_music_iter) as ViewWrapper;
            if (vw != null)
                vw.set_media_async.begin (library_manager.media ());
        }
    }

    public virtual void musicCounted(int count) {
        debug ("found %d media, importing.\n", count);
    }

    /* this is after setting the music library */
    public virtual void musicAdded (Gee.LinkedList<string> not_imported) {
        if(App.player.media_active)
            updateInfoLabel();
        else
            topDisplay.set_label_text("");

        if(not_imported.size > 0) {
            NotImportedWindow nim = new NotImportedWindow(this, not_imported, main_settings.music_folder);
            nim.show();
        }

        update_sensitivities();
    }

    /* this is when you import music from a foreign location into the library */
    public virtual void musicImported(LinkedList<Media> imported, LinkedList<string> not_imported) {
        if (App.player.media_active)
            updateInfoLabel();
        else
            topDisplay.set_label_text("");

        resetSideTree(false);

        update_sensitivities();


        //now notify user
        if (imported.size > 0)
            show_notification (_("Import Complete"), _("%s has imported your library.").printf (App.instance.get_name ()));
    }

    public virtual void musicRescanned (Gee.Collection<Media> new_medias, Gee.Collection<string> not_imported) {
        if (App.player.media_active)
            updateInfoLabel ();
        else
            topDisplay.set_label_text ("");

        resetSideTree(false);
        debug("music Rescanned\n");
        update_sensitivities();
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
        if (folder == "" || (folder == main_settings.music_folder && library_manager.media_count () > 0))
            return;

        if (library_manager.media_count () > 0 || library_manager.playlist_count() > 0) {
            var smfc = new SetMusicFolderConfirmation(library_manager, this, folder);
            smfc.finished.connect( (cont) => {
                if(cont) {
                    library_manager.set_music_folder(folder);
                }
            });
        }
        else {
            library_manager.set_music_folder (folder);
            resetSideTree (true);
        }
    }

    public virtual void end_of_stream() {
        nextClicked();
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

        if(App.player.player.set_resume_pos)
            App.player.media_info.media.resume_pos = (int)sec;

        // at about 3 seconds, update last fm. we wait to avoid excessive querying last.fm for info
        if(position > 3000000000 && !media_considered_previewed) {
            media_considered_previewed = true;
            update_media_info ();
        }

        //at 30 seconds in, we consider the media as played
        if(position > 30000000000 && !media_considered_played) {
            media_considered_played = true;
            App.player.media_info.media.last_played = (int)time_t();

            library_manager.update_media_item (App.player.media_info.media, false, false);

            // add to the already played list
            App.player.add_already_played (App.player.media_info.media);

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

        if(((double)(sec/(double)App.player.media_info.media.length) > 0.50) && (media_half_played_sended == false)) {
            media_half_played ();
            media_half_played_sended = true;
        }

        // at 80% done with media, add 1 to play count
        if((double)(sec/(double)App.player.media_info.media.length) > 0.80 && !added_to_play_count) {
            added_to_play_count = true;
            App.player.media_info.media.play_count++;
            library_manager.update_media_item (App.player.media_info.media, false, false);
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
        main_settings.last_media_position = (int)((double)App.player.player.getPosition
        ()/Numeric.NANO_INV);
        if(App.player.media_active) {
            App.player.media_info.media.resume_pos = (int)((double)App.player.player.getPosition()/Numeric.NANO_INV);
            library_manager.update_media_item (App.player.media_info.media, false, false);
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
                    message ("Using supported minimize_on_close shell");
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

