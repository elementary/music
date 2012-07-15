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

public class BeatBox.LibraryWindow : LibraryWindowInterface, Gtk.Window {

    /* signals */
    public signal void playPauseChanged ();

    /* Application */
    public BeatBox.Beatbox app { get { return (application as BeatBox.Beatbox); } }

    /* Library Manager */
    public BeatBox.LibraryManager library_manager { get; private set; }

    public Noise.Settings   main_settings         { get; private set; }
    public Noise.SavedState savedstate_settings   { get; private set; }
    public Noise.Equalizer  equalizer_settings    { get; private set; }

    private BeatBox.MediaKeyListener mkl;

    /* Info related to the media being played */
    private bool media_considered_played    { get; set; default = false; } // whether or not we have updated last played and added to already played list
    private bool added_to_play_count        { get; set; default = false; } // whether or not we have added one to play count on playing media
    private bool tested_for_video           { get; set; default = false; } // whether or not we have tested if media is video and shown video
    private bool media_considered_previewed { get; set; default = false; }
    private bool media_half_played_sended   { get; set; default = false; }

    public bool dragging_from_music         { get; set; default = false; } // TODO: make private
    public bool initialization_finished     { get; private set; default = false; }


    /* Main layout widgets */
    private Gtk.Box       verticalBox;
    private Gtk.Paned     view_container_hpaned; // view_container / info_panel
    public InfoPanel      info_panel;

    private Gtk.Toolbar    main_toolbar; // Toolbar
    private Gtk.ToolButton previousButton;
    private Gtk.ToolButton playButton;
    private Gtk.ToolButton nextButton;

    public Gtk.Paned                  main_hpaned           { get; private set; } // TODO: make private
    public SideTreeView               sideTree              { get; private set; }
    public ViewContainer              view_container        { get; private set; } // TODO: make private
    public ToggleButton               column_browser_toggle { get; private set; }
    public TopDisplay                 topDisplay            { get; private set; } // TODO: make private
    private FixedBin                  topDisplayBin         { get; private set; }
    public Granite.Widgets.ModeButton viewSelector          { get; private set; } // TODO: make private
    public Granite.Widgets.SearchBar  searchField           { get; private set; } // TODO: make private
    public BottomStatusBar            statusbar             { get; private set; } // TODO: make private
    private Granite.Widgets.Welcome   welcome_screen        { get; private set; } // TODO: make private

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

    public signal void media_half_played (); // send after the half of the song
    public signal void update_media_informations (); // send after 3 seconds

    public LibraryWindow (BeatBox.Beatbox app) {
        set_application (app);

        //this.settings = app.settings;
        main_settings       = new Noise.Settings ();
        savedstate_settings = new Noise.SavedState ();
        equalizer_settings  = new Noise.Equalizer ();

        // Load icon information
        Icons.init ();

        //this is used by many objects, is the media backend
        library_manager = new BeatBox.LibraryManager (this);

        #if HAVE_INDICATE
            #if HAVE_DBUSMENU
                message ("Initializing MPRIS and sound menu");
                var mpris = new BeatBox.MPRIS (this);
                mpris.initialize ();
            #endif
        #endif

        //various objects
        mkl = new MediaKeyListener (this);

        this.library_manager.player.end_of_stream.connect (end_of_stream);
        this.library_manager.player.current_position_update.connect (current_position_update);
        //FIXME? this.library_manager.player.media_not_found.connect (media_not_found);
        this.library_manager.music_counted.connect (musicCounted);
        this.library_manager.music_added.connect (musicAdded);
        this.library_manager.music_imported.connect (musicImported);
        this.library_manager.music_rescanned.connect (musicRescanned);
        this.library_manager.progress_notification.connect (progressNotification);
        this.library_manager.media_updated.connect (medias_updated);
        this.library_manager.media_played.connect (media_played);
        this.library_manager.playback_stopped.connect (playback_stopped);

        this.library_manager.media_added.connect (update_sensitivities);
        this.library_manager.media_removed.connect (update_sensitivities);

        // init some booleans
        if (main_settings.music_folder == "") {
            main_settings.music_folder = GLib.Environment.get_user_special_dir (GLib.UserDirectory.MUSIC);
            message("First run.\n");
        }
        else {
            library_manager.clearCurrent();

            // make sure we don't re-count stats
            if (main_settings.last_media_position > 5)
                media_considered_previewed = true;
            if(main_settings.last_media_position > 30)
                media_considered_played = true;
            if(library_manager.media_active && (double)(main_settings.last_media_position/(double)library_manager.media_info.media.length) > 0.90)
                added_to_play_count = true;
        }

        /*if(!File.new_for_path(settings.getMusicFolder()).query_exists() && settings.getMusicFolder() != "") {
            doAlert("Music folder not mounted", "Your music folder is not mounted. Please mount your music folder before using BeatBox.");
        }*/
    }

    private bool on_key_press_event (Gdk.EventKey event) {
        if (searchField == null || !searchField.sensitive || searchField.has_focus)
            return false;

        var typed_unichar = event.str.get_char ();

        if (!typed_unichar.validate ())
            return false;

        unichar[] special_chars = {'&', '.', '-', '\'', '%', '(', ')', '=', '@', '!',
                                    '#', '+', '<', '>', ';', ':', '¿', '?', '¡'}; 

        // Redirect valid key presses to the search field
        if (typed_unichar.isalnum () || typed_unichar in special_chars) {
            searchField.grab_focus ();

            // Check if the search field actually got focus
            if (!searchField.has_focus)
                searchField.insert_at_cursor (event.str);
        }

        return false;
    }

    private inline void setup_window () {
        debug ("setting up main window");

        this.height_request = 440;
        this.width_request = 750;
        this.window_position = Gtk.WindowPosition.CENTER;

        // set the size based on saved settings
        this.set_default_size (savedstate_settings.window_width, savedstate_settings.window_height);

        // Maximize window if necessary
        switch (savedstate_settings.window_state) {
            case Noise.WindowState.MAXIMIZED:
                this.maximize ();
                break;
            case Noise.WindowState.FULLSCREEN:
                this.fullscreen ();
                break;
            default :
                break;
        }

        this.set_title (this.app.get_name ());
        this.set_icon (Icons.BEATBOX.render (IconSize.MENU, null));

        // Redirect key presses to the search box.
        this.key_press_event.connect (on_key_press_event);

        // set up drag dest stuff
        Gtk.drag_dest_set (this, DestDefaults.ALL, {}, Gdk.DragAction.MOVE);
        Gtk.drag_dest_add_uri_targets (this);
        this.drag_data_received.connect (dragReceived);

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
        column_browser_toggle   = new Gtk.ToggleButton ();
        topDisplay              = new TopDisplay (library_manager);
        topDisplayBin           = new FixedBin(300, -1, 350, -1, false);
        viewSelector            = new Granite.Widgets.ModeButton ();
        searchField             = new Granite.Widgets.SearchBar (_("Search Music"));

        main_toolbar.get_style_context ().add_class (Gtk.STYLE_CLASS_PRIMARY_TOOLBAR);
        main_toolbar.set_hexpand (true);

        viewSelector.append (Icons.VIEW_ICONS.render_image (IconSize.MENU));
        viewSelector.append (Icons.VIEW_DETAILS.render_image (IconSize.MENU));

        column_browser_toggle.set_image (Icons.VIEW_COLUMN.render_image (Gtk.IconSize.MENU));

        topDisplayBin.set_widget (topDisplay, false, false);

        // Set search timeout in ms
        searchField.pause_delay = 150;

        var column_toggle_item = new Gtk.ToolItem ();
        var top_display_item   = new Gtk.ToolItem ();
        var view_selector_item = new Gtk.ToolItem ();
        var search_field_item  = new Gtk.ToolItem ();
        var separator_item     = new Gtk.SeparatorToolItem ();

        view_selector_item.add (viewSelector);
        column_toggle_item.add (column_browser_toggle);
        top_display_item.add (topDisplayBin);
        search_field_item.add (searchField);

        // Tweak view selector's size
        viewSelector.margin_left = 12;
        viewSelector.margin_right = 8;

        viewSelector.valign = column_browser_toggle.valign = Gtk.Align.CENTER;

        top_display_item.set_expand (true);
        topDisplay.margin_left = 30;
        topDisplay.margin_right = 30;

        search_field_item.margin_right = 12;

        separator_item.set_expand (true);
        separator_item.set_draw (false);
        
        main_toolbar.insert (previousButton, -1);
        main_toolbar.insert (playButton, -1);
        main_toolbar.insert (nextButton, -1);
        main_toolbar.insert (view_selector_item, -1);
        main_toolbar.insert (column_toggle_item, -1);
        //main_toolbar.insert (separator_item, -1);
        main_toolbar.insert (top_display_item, -1);
        main_toolbar.insert (separator_item, -1);
        main_toolbar.insert (search_field_item, -1);
        main_toolbar.insert (app.create_appmenu (settingsMenu), -1);

        /** Statusbar widgets **/

        statusbar = new BottomStatusBar (this);

        /** Info Panel **/

        info_panel = new InfoPanel (library_manager, this);


        /** Main layout **/

        verticalBox           = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_hpaned           = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
        view_container_hpaned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
        view_container        = new ViewContainer ();
        sideTree              = new SideTreeView (library_manager, this);

        // Set theming
        main_hpaned.get_style_context().add_class ("sidebar-pane-separator");

        // Set properties of various controls
        main_hpaned.set_position (savedstate_settings.sidebar_width);
        int view_container_pos = savedstate_settings.window_width - savedstate_settings.sidebar_width - savedstate_settings.more_width;
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

        int i = main_settings.last_media_playing;
        if(i != 0 && library_manager.media_from_id (i) != null && File.new_for_uri (library_manager.media_from_id(i).uri).query_exists()) {
            library_manager.playMedia (library_manager.media_from_id (i), true);
        }

        // ADD MAIN VIEWS
        build_main_views ();

        // show window
        update_sensitivities();

        // Now set the selected view
        viewSelector.selected = savedstate_settings.view_mode;

        // ADD PLAYLIST VIEWS
        load_playlists_async ();

        initialization_finished = true;

        if (library_manager.song_ids().size == 0)
            setMusicFolder (Environment.get_user_special_dir(UserDirectory.MUSIC));


        /* Connect events to functions */
        previousButton.clicked.connect(previousClicked);
        playButton.clicked.connect(playClicked);
        nextButton.clicked.connect(nextClicked);

        searchField.activate.connect (searchFieldActivate);
        searchField.set_text (main_settings.search_string);

        debug ("DONE WITH USER INTERFACE");
    }


    /**
     * Show notification asynchronously
     */

    private Notify.Notification? notification = null;

    public async void show_notification (string primary_text, string secondary_text, Gdk.Pixbuf? pixbuf = null, bool force = false) {
        if (!Notify.is_initted ()) {
            if (!Notify.init (app.get_id ())) {
                warning ("Could not init libnotify");
                return;
            }
        }

        if (!force) {
            // don't show a notification if the user is already viewing
            // this application. Please note that this is not perfect.
            // 'is_active' is FALSE when a child window (i.e. a dialog, etc.)
            // has the toplevel focus.
            if (is_active)
                return;
        }

        if (notification == null) {
            notification = new Notify.Notification (primary_text, secondary_text, "");
        }
        else {
            notification.clear_hints ();
            notification.clear_actions ();
            notification.update (primary_text, secondary_text, "");
        }

        // If the passed pixbuf is NULL, let's use the app's icon
        var image = pixbuf;
        if (image == null)
            image = Icons.BEATBOX.render (IconSize.DIALOG);

        notification.set_image_from_pixbuf (image);

        try {
            notification.show();
        }
        catch (GLib.Error err) {
            warning ("Could not show notification: %s", err.message);
        }
    }

    public void show_notification_from_media (Media media, bool force = false) {
        if (media == null)
            return;

        string primary_text = media.title;

        string secondary_text = media.artist + "\n" + media.album;

        if (media.getAlbumArtPath() != "" && media.getAlbumArtPath() != null) {
            Gdk.Pixbuf? pixbuf = null;
            try {
                pixbuf = new Gdk.Pixbuf.from_file_at_size (media.getAlbumArtPath(), 48, 48);
            }
            catch (Error err) {
                // Media often doesn't have an associated album art,
                // so we shouldn't threat this as an unexpected error.
                message (err.message);
            }

            show_notification (primary_text, secondary_text, pixbuf, force);
        }
        else
            show_notification (primary_text, secondary_text, null, force);
    }

    private void notify_current_media () {
        if (library_manager.media_info != null && library_manager.media_info.media != null)
            show_notification_from_media (library_manager.media_info.media);
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
     * Description:
     * Builds the views (view wrapper) and adds the respective element to the sidebar TreeView.
     *
     * @param name The name of the item in the sidebar
     * @param widget Widget containing the custom view
     * @param tree The sidebar tree to build it on [if NULL is passed it uses the default tree]
     *
     * IMPORTANT: Currently every item added through this method will be put under the Network category
     */
#if 0
    public ViewWrapper add_custom_view (string name, Gtk.Widget widget) {
        var view_wrapper = new ViewWrapper.with_view (widget);
        sideTree.add_item (view_wrapper, name);

        /* Pack view wrapper into the main views */
        if (view_container.add_view (view_wrapper) < 0)
            critical ("Failed to append view '%s' to %s's main views", name, app.get_name ());

        return view_wrapper;
    }
#endif

    /**
     * Builds and sets up the default views. That includes main sidebar elements
     * and categories, which at the same time wrap treeviews, icon views, welcome screens, etc.
     */
    private void build_main_views () {
        debug ("Building main views ...");

        // Add Music Library View
        var music_view_wrapper = new MusicViewWrapper (this);
        add_view (_("Music"), music_view_wrapper);
        music_view_wrapper.set_media_from_ids_async (library_manager.song_ids ());

        // Add Queue view
        var queue_view = new QueueViewWrapper (this);
        add_view (_("Queue"), queue_view);
        queue_view.set_media_async (library_manager.queue ());

        // Add History view
        var history_view = new HistoryViewWrapper (this);
        add_view (_("History"), history_view);
        history_view.set_media_async (library_manager.already_played ());

        debug ("Done with main views.");
    }
    
    private async void load_playlists_async () {
        Idle.add_full (Priority.DEFAULT_IDLE, load_playlists_async.callback);
        yield;

        debug ("Loading playlists");

        // load smart playlists. Don't populate.
        foreach (SmartPlaylist p in library_manager.smart_playlists()) {
            addSideListItem (p, false);
            // queue the populate operation on this playlists. The PlaylistViewWrapper
            // view has signal handlers that listen for changes after analyze() has been triggered
            Idle.add_full (Priority.DEFAULT_IDLE + 20, () => {
                library_manager.media_from_smart_playlist (p.rowid);
                return false;
            });
        }

        // load playlists.
        foreach (Playlist p in library_manager.playlists()) {
            addSideListItem (p);
        }

        sideTree.resetView ();
        update_sensitivities ();

        debug ("Finished loading playlists");
    }

    public TreeIter addSideListItem (GLib.Object o, bool populate = true) {
        TreeIter iter = sideTree.library_music_iter; //just a default

        if(o is Playlist) {
            Playlist p = (Playlist)o;

            var view = new PlaylistViewWrapper (this, p.tvs, p.rowid);
            add_view (p.name, view, out iter);

            if (populate)
                view.set_media_async (library_manager.media_from_playlist (p.rowid));
        }
        else if(o is SmartPlaylist) {
            SmartPlaylist p = (SmartPlaylist)o;
            
            var view = new PlaylistViewWrapper (this, p.tvs, p.rowid);
            add_view (p.name, view, out iter);
            
            if (populate)
                view.set_media_async (library_manager.media_from_smart_playlist (p.rowid));
        }
        /* XXX: Migrate this code to the new ViewWrapper API */
        else if(o is Device) {
            Device d = (Device)o;

            if(d.getContentType() == "cdrom") {

                message("CD added with %d songs.\n", d.get_medias().size);

                /* FIXME: this can be easily migrated. Not doing it now to avoid
                 *        breaking stuff.
                 */
                 // TODO: Convert the current DeviceViewWrapper into CDViewWrapper
                 var cd_setup = new TreeViewSetup (MusicListView.MusicColumn.ALBUM, Gtk.SortType.ASCENDING, ViewWrapper.Hint.CDROM);
                 var vw = new DeviceViewWrapper (this, cd_setup, d);

                 if (populate)
                     vw.set_media_async (d.get_medias ());
                 iter = sideTree.addSideItem(sideTree.devices_iter, d, vw, d.getDisplayName(), ViewWrapper.Hint.CDROM);
                 view_container.add_view (vw);
            }
            else {
                debug ("adding ipod device view with %d\n", d.get_medias().size);
                DeviceView dv = new DeviceView (library_manager, d);
                //vw = new DeviceViewWrapper(this, d.get_medias(), "Artist", Gtk.SortType.ASCENDING, ViewWrapper.Hint.DEVICE, -1, d);
                iter = sideTree.addSideItem(sideTree.devices_iter, d, dv, d.getDisplayName(), ViewWrapper.Hint.NONE);
                view_container.add_view (dv);
            }
        }
        else if(o is NetworkDevice) {

            var nd_setup = new TreeViewSetup (MusicListView.MusicColumn.ALBUM, Gtk.SortType.ASCENDING, ViewWrapper.Hint.NETWORK_DEVICE);
            var view = new NetworkDeviceViewWrapper (this, nd_setup, (BeatBox.NetworkDevice)o);
            add_view (((BeatBox.NetworkDevice)o).getDisplayName(), view, out iter);

            if (populate)
                view.set_media_async (((BeatBox.NetworkDevice)o).get_medias ());
        }
        
        return iter;
    }



    /**
     * This is handled more carefully inside each ViewWrapper object.
     */
    public async void update_sensitivities () {
        Idle.add_full (Priority.HIGH_IDLE, update_sensitivities.callback);
        yield;

        debug ("UPDATE SENSITIVITIES");

        bool folder_set = (main_settings.music_folder != "");
        bool have_media = library_manager.media_count () > 0;
        bool doing_ops = library_manager.doing_file_operations ();
        bool media_active = library_manager.media_active;

        fileImportMusic.set_sensitive (!doing_ops && folder_set);
        fileRescanMusicFolder.set_sensitive (!doing_ops && folder_set);

        if(doing_ops) {
            topDisplay.show_progressbar ();
        }
        else if(media_active && library_manager.media_info.media.mediatype == 3) {
            topDisplay.hide_scale_and_progressbar ();
        }
        else {
            topDisplay.show_scale();
        }

        // Play, pause, ...
        bool media_available = library_manager.current_media ().size > 0;
        previousButton.set_sensitive (media_active || media_available);
        playButton.set_sensitive (media_active || media_available);
        nextButton.set_sensitive (media_active || media_available);

        bool show_top_display = media_active || doing_ops;
        topDisplay.set_visible (show_top_display);

        topDisplay.set_scale_sensitivity(media_active);

        // TODO: also update statusbar option chooser
        bool show_info_panel = savedstate_settings.more_visible && media_active && folder_set;
        info_panel.set_visible (show_info_panel);

        statusbar.set_sensitive (folder_set);

        // hide playlists when media list is empty
        sideTree.setVisibility (sideTree.playlists_iter, have_media);

        if(!library_manager.media_active || have_media && !library_manager.playing) {
            playButton.set_stock_id(Gtk.Stock.MEDIA_PLAY);
        }
    }

    public virtual void progressNotification(string? message, double progress) {
        if(message != null && progress >= 0.0 && progress <= 1.0)
            topDisplay.set_label_markup(message);

        topDisplay.set_progress_value(progress);
    }

    public void updateInfoLabel () {
        if(library_manager.doing_file_operations()) {
            debug ("doing file operations, returning null in updateInfoLabel");
            return;
        }

        if(!library_manager.media_active) {
            topDisplay.set_label_markup("");
            debug ("setting info label as ''");
            return;
        }

        string beg = "";

        if(library_manager.media_info.media.mediatype == 3) // radio
            beg = "<b>" + library_manager.media_info.media.album_artist.replace("\n", "") + "</b>\n";

        //set the title
        Media s = library_manager.media_info.media;
        var title = "<b>" + String.escape (s.title) + "</b>";
        var artist = ((s.artist != "" && s.artist != _("Unknown Artist")) ? (_(" by ") + "<b>" + String.escape (s.artist) + "</b>") : "");
        var album = ((s.album != "" && s.album != _("Unknown Album")) ? (_(" on ") + "<b>" + String.escape (s.album) + "</b>") : "");

        var media_label = beg + title + artist + album;
        topDisplay.set_label_markup(media_label);
    }


    /** This should be used whenever a call to play a new media is made
     * @param s The media that is now playing
     */
    public virtual void media_played(Media m) {
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
        topDisplay.set_scale_range(0.0, library_manager.media_info.media.length);

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

        // if radio, we can't depend on current_position_update. do that stuff now.
        if(library_manager.media_info.media.mediatype == Media.MediaType.STATION) {
            media_considered_previewed = true;
            update_media_informations ();
            
            // always show notifications for the radio, since user likely does not know media
            notify_current_media ();
        }
        else {
            Timeout.add(3000, () => {
                if(library_manager.media_info.media != null && library_manager.media_info.media == m && m.rowid != LibraryManager.PREVIEW_MEDIA_ID) {
                    update_media_informations();
                }
                
                return false;
            });
        }
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
        if(library_manager.media_active && ids.contains(library_manager.media_info.media.rowid)) {
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
        if(!library_manager.media_active) {
            debug("No media is currently playing. Starting from the top\n");
            //set current medias by current view
            Gtk.Widget w = view_container.get_current_view ();
            
            if(w is ViewWrapper) {
                (w as ViewWrapper).play_first_media ();
            }

            library_manager.getNext(true);

            library_manager.playing = true;
            playButton.set_stock_id(Gtk.Stock.MEDIA_PAUSE);
            library_manager.player.play();

            if (!inhibit_notifications)
                notify_current_media ();
        }
        else {
            if(library_manager.playing) {
                library_manager.playing = false;
                library_manager.player.pause();

                playButton.set_stock_id(Gtk.Stock.MEDIA_PLAY);
            }
            else {
                library_manager.playing = true;
                library_manager.player.play();
                playButton.set_stock_id(Gtk.Stock.MEDIA_PAUSE);
            }
        }

        playPauseChanged();
    }

    public virtual void play_next_media (bool inhibit_notifications = false) {
        // if not 90% done, skip it
        if(!added_to_play_count) {
            library_manager.media_info.media.skip_count++;

            // don't update, it will be updated eventually
            //library_manager.update_media_item (library_manager.media_info.media, false, false);
        }

        Media? m = null;
        if(library_manager.next_gapless_id != 0) {
            int next_id = library_manager.next_gapless_id;
            m = library_manager.media_from_id (next_id);
            library_manager.playMedia (m, false);
        }
        else
            m = library_manager.getNext(true);

        /* test to stop playback/reached end */
        if(m == null) {
            library_manager.player.pause();
            library_manager.playing = false;
            update_sensitivities();
            return;
        }

        if (!inhibit_notifications)
            notify_current_media ();
    }

    public virtual void play_previous_media (bool inhibit_notifications = false) {
        if(library_manager.player.getPosition() < 5000000000 || (library_manager.media_active && library_manager.media_info.media.mediatype == 3)) {
            bool play = true;
            var prev = library_manager.getPrevious(true);

            /* test to stop playback/reached end */
            if(prev == null) {
                library_manager.player.pause();
                library_manager.playing = false;
                update_sensitivities();
                return;
            }
            else if (play && !inhibit_notifications) {
                notify_current_media ();
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
            string[] folders = {};
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
            
            for (int i=0;i< (int)(_folders.length ());i++) {
                folders += _folders.nth_data (i);
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

    public void resetSideTree(bool clear_views) {
        sideTree.resetView();

        // clear all other playlists, reset to Music, populate music
        if(clear_views) {
            message("clearing all views...\n");
            view_container.get_children().foreach( (w) => {
                if(w is ViewWrapper && !(w is DeviceViewWrapper)) {
                    ViewWrapper vw = (ViewWrapper)w;
                    debug("doing clear\n");
                    //vw.do_update(vw.current_view, new LinkedList<int>(), true, true, false);
                    vw.set_media_async (new LinkedList<Media>());
                    debug("cleared\n");
                }
            });
            message("all cleared\n");
        }
        else {
            ViewWrapper vw = (ViewWrapper)sideTree.getWidget(sideTree.library_music_iter);
            //vw.do_update(vw.current_view, library_manager.song_ids(), true, true, false);
            //vw.column_browser.populate (library_manager.song_ids());
            vw.set_media_from_ids_async (library_manager.song_ids());
        }
    }

    public virtual void musicCounted(int count) {
        debug ("found %d media, importing.\n", count);
    }

    /* this is after setting the music library */
    public virtual void musicAdded(LinkedList<string> not_imported) {

        if(library_manager.media_active) {
            updateInfoLabel();
        }
        else
            topDisplay.set_label_text("");

        if(not_imported.size > 0) {
            NotImportedWindow nim = new NotImportedWindow(this, not_imported, main_settings.music_folder);
            nim.show();
        }

        update_sensitivities();

        //now notify user
        show_notification (_("Import Complete"), _("%s has imported your library.").printf (app.get_name ()));
    }

    /* this is when you import music from a foreign location into the library */
    public virtual void musicImported(LinkedList<Media> new_medias, LinkedList<string> not_imported) {
        if(library_manager.media_active) {
            updateInfoLabel();
        }
        else
            topDisplay.set_label_text("");

        resetSideTree(false);

        update_sensitivities();
    }

    public virtual void musicRescanned(LinkedList<Media> new_medias, LinkedList<string> not_imported) {
        if(library_manager.media_active) {
            updateInfoLabel();
        }
        else
            topDisplay.set_label_text("");

        resetSideTree(false);
        debug("music Rescanned\n");
        update_sensitivities();
    }

    public void editPreferencesClick() {
        PreferencesWindow pw = new PreferencesWindow(library_manager, this);

        pw.changed.connect( (folder) => {
            setMusicFolder(folder);
        });
    }

    public void setMusicFolder(string folder) {
        if (library_manager.doing_file_operations ())
            return;

        // If different folder chosen or we have no songs anyways, do set.
        if (folder == "" || (folder == main_settings.music_folder && library_manager.song_count () > 0))
            return;

        if (library_manager.song_ids().size > 0 || library_manager.playlist_count() > 0) {
            var smfc = new SetMusicFolderConfirmation(library_manager, this, folder);
            smfc.finished.connect( (cont) => {
                if(cont) {
                    library_manager.set_music_folder(folder);
                }
            });
        }
        else {
            library_manager.set_music_folder (folder);
        }
    }

    public virtual void end_of_stream() {
        nextClicked();
    }

    public virtual void current_position_update (int64 position) {
        if (!library_manager.media_active)
            return;

        double sec = ((double)position/1000000000);

        if(library_manager.player.set_resume_pos)
            library_manager.media_info.media.resume_pos = (int)sec;

        // at about 3 seconds, update last fm. we wait to avoid excessive querying last.fm for info
        if(position > 3000000000 && !media_considered_previewed) {
            media_considered_previewed = true;
            update_media_informations ();
        }

        //at 30 seconds in, we consider the media as played
        if(position > 30000000000 && !media_considered_played) {
            media_considered_played = true;
            library_manager.media_info.media.last_played = (int)time_t();

#if HAVE_PODCASTS
            if(library_manager.media_info.media.mediatype == 1) { //podcast
                added_to_play_count = true;
                ++library_manager.media_info.media.play_count;
            }
#endif

            library_manager.update_media_item (library_manager.media_info.media, false, false);

            // add to the already played list
            library_manager.add_already_played (library_manager.media_info.media);

#if HAVE_ZEITGEIST
            var event = new Zeitgeist.Event.full (Zeitgeist.ZG_ACCESS_EVENT,
                                                   Zeitgeist.ZG_SCHEDULED_ACTIVITY, "app://%s".printf (app.get_desktop_file_name ()),
                                                   new Zeitgeist.Subject.full(library_manager.media_info.media.uri,
                                                                               Zeitgeist.NFO_AUDIO,
                                                                               Zeitgeist.NFO_FILE_DATA_OBJECT,
                                                                               "text/plain", "",
                                                                               library_manager.media_info.media.title, ""));
            new Zeitgeist.Log ().insert_events_no_reply(event);
#endif
        }

        if(((double)(sec/(double)library_manager.media_info.media.length) > 0.50) && (media_half_played_sended == false)) {
            media_half_played ();
            media_half_played_sended = true;
        }

        // at 80% done with media, add 1 to play count
        if((double)(sec/(double)library_manager.media_info.media.length) > 0.80 && !added_to_play_count) {
            added_to_play_count = true;
            library_manager.media_info.media.play_count++;
            library_manager.update_media_item (library_manager.media_info.media, false, false);
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

        dialog.title = app.get_name ();
        dialog.secondary_text = message;
        dialog.secondary_use_markup = true;

        dialog.run();
        dialog.destroy();
    }

    public override void destroy() {
        this.hide ();
        
        // Save media position and info
        main_settings.last_media_position = (int)((double)library_manager.player.getPosition
        ()/1000000000);
        if(library_manager.media_active) {
            library_manager.media_info.media.resume_pos = (int)((double)library_manager.player.getPosition()/1000000000);
            library_manager.update_media_item (library_manager.media_info.media, false, false);
        }
        library_manager.player.pause();

        // Terminate Libnotify
        if (Notify.is_initted ()) {
            if (notification != null) {
                try {
                    notification.close ();
                }
                catch (Error err) {
                    warning (err.message);
                }
            }
            Notify.uninit ();
        }

        // Now set the selected view
        savedstate_settings.view_mode = viewSelector.selected;

        // Search FIXME: Temporary disabled
        //main_settings.search_string = searchField.get_text ();
        
        // Save info pane (context pane) width
        savedstate_settings.more_width = info_panel.get_allocated_width ();

        // Save sidebar width
        savedstate_settings.sidebar_width = main_hpaned.position;

        // Save window state
        if (window_maximized)
                savedstate_settings.window_state = Noise.WindowState.MAXIMIZED;
        else if (window_fullscreen)
                savedstate_settings.window_state = Noise.WindowState.FULLSCREEN;
        else
                savedstate_settings.window_state = Noise.WindowState.NORMAL;

        savedstate_settings.window_width = window_width;
        savedstate_settings.window_height = window_height;

        base.destroy ();
    }

    public override bool configure_event (Gdk.EventConfigure event) {
        // Get window dimensions.
        window_maximized = (get_window ().get_state () == Gdk.WindowState.MAXIMIZED);

        if (!(window_maximized || window_fullscreen))
            get_size (out window_width, out window_height);

        return base.configure_event (event);
    }
}

