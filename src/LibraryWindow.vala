/*-
 * Copyright (c) 2011-2012       Scott Ringwelski <sgringwe@mtu.edu>
 *
 * Originally Written by Scott Ringwelski for BeatBox Music Player
 * BeatBox Music Player: http://www.launchpad.net/beat-box
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

using Gtk;
using Gee;
using Notify;

public class BeatBox.LibraryWindow : LibraryWindowInterface, Gtk.ApplicationWindow {

	public BeatBox.Beatbox app { get { return (application as BeatBox.Beatbox); } }

	// signals
	public signal void playPauseChanged ();

	public BeatBox.LibraryManager lm { get; private set; }
	public BeatBox.Settings settings { get; private set; }

	private BeatBox.MediaKeyListener mkl;

	private bool queriedlastfm; // whether or not we have queried last fm for the current media info
	private bool media_considered_played; // whether or not we have updated last played and added to already played list
	private bool added_to_play_count; // whether or not we have added one to play count on playing media
	private bool tested_for_video; // whether or not we have tested if media is video and shown video
	private bool scrobbled_track;

	public bool dragging_from_music { get; set; }

	public bool initialization_finished { get; private set; default = false; }

	private Gtk.Box verticalBox;

	public ViewContainer view_container { get; private set; }

	public Gtk.Paned main_hpaned { get; private set; } //allows for draggable

	public Gtk.Paned view_container_hpaned { get; private set; } // media info pane

	public SideTreeView sideTree { get; private set; }

	public InfoPanel info_panel { get; private set; }

	private Toolbar topControls;
	public ToolButton previousButton { get; private set; }
	public ToolButton playButton { get; private set; }
	public ToolButton nextButton { get; private set; }

	public ToggleButton column_browser_toggle { get; private set; }

	public TopDisplay topDisplay { get; private set; }

	public Granite.Widgets.ModeButton viewSelector { get; private set; }
	public Granite.Widgets.SearchBar  searchField  { get; private set; }

	public Granite.Widgets.StatusBar statusbar { get; private set; }

	private SimpleOptionChooser addPlaylistChooser;
	private SimpleOptionChooser shuffleChooser;
	private SimpleOptionChooser repeatChooser;
	private SimpleOptionChooser info_panel_chooser;
	private SimpleOptionChooser eq_option_chooser;

	// basic file stuff
	private Gtk.Menu settingsMenu;
	private Gtk.MenuItem fileImportMusic;
	private Gtk.MenuItem fileRescanMusicFolder;
	private ImageMenuItem editPreferences;

	private Notify.Notification notification;

	// Window properties
	private bool window_maximized = false;
	private int window_width = 0;
	private int window_height = 0;

	public LibraryWindow (BeatBox.Beatbox app) {
		set_application (app);

		this.settings = app.settings;

		// Load icon information
		Icons.init ();

		//this is used by many objects, is the media backend
		lm = new BeatBox.LibraryManager(this);

		//various objects
		mkl = new MediaKeyListener(this);

#if HAVE_INDICATE
#if HAVE_DBUSMENU
		message("Initializing MPRIS and sound menu\n");
		var mpris = new BeatBox.MPRIS (this);
		mpris.initialize();
#endif
#endif

		dragging_from_music = false;

		this.lm.player.end_of_stream.connect(end_of_stream);
		this.lm.player.current_position_update.connect(current_position_update);
		//FIXME? this.lm.player.media_not_found.connect(media_not_found);
		this.lm.music_counted.connect(musicCounted);
		this.lm.music_added.connect(musicAdded);
		this.lm.music_imported.connect(musicImported);
		this.lm.music_rescanned.connect(musicRescanned);
		this.lm.progress_notification.connect(progressNotification);
		this.lm.media_updated.connect(medias_updated);
		this.lm.media_played.connect(media_played);
		this.lm.playback_stopped.connect(playback_stopped);

		// TODO: Move this to LibraryManager
		if(lm.media_count() == 0 && settings.getMusicFolder() == "") {
			message("First run.\n");
		}
		else {
			lm.clearCurrent();

			// make sure we don't re-count stats
			if((int)settings.getLastMediaPosition() > 5)
				queriedlastfm = true;
			if((int)settings.getLastMediaPosition() > 30)
				media_considered_played = true;
			if(lm.media_active && (double)((int)settings.getLastMediaPosition()/(double)lm.media_info.media.length) > 0.90)
				added_to_play_count = true;

			// rescan on startup
			/*lm.rescan_music_folder();*/
		}

		/*if(!File.new_for_path(settings.getMusicFolder()).query_exists() && settings.getMusicFolder() != "") {
			doAlert("Music folder not mounted", "Your music folder is not mounted. Please mount your music folder before using BeatBox.");
		}*/
	}

	public void build_ui() {
		debug ("Building user interface");

		height_request = 440;
		width_request = 750;
		window_position = Gtk.WindowPosition.CENTER;

		// set the size based on saved gconf settings
		set_default_size (settings.getWindowWidth(), settings.getWindowHeight());

		// Maximize window if necessary
		if (settings.getWindowMaximized ())
			this.maximize ();

		// set the title
		set_title(app.get_name ());

		// set the icon
		set_icon(Icons.BEATBOX.render (IconSize.MENU, null));


		verticalBox = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

		// wraps the sidebar and view_container_hpaned
		main_hpaned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
		
		// wraps the view container and the info panel
		view_container_hpaned = new Paned (Gtk.Orientation.HORIZONTAL);

		view_container = new ViewContainer ();

		sideTree = new SideTreeView(lm, this);
		fileImportMusic = new Gtk.MenuItem.with_label(_("Import to Library"));
		fileRescanMusicFolder = new Gtk.MenuItem.with_label(_("Rescan Music Folder"));
		editPreferences = new ImageMenuItem.from_stock(Gtk.Stock.PREFERENCES, null);
		settingsMenu = new Gtk.Menu();
		topControls = new Toolbar();
		previousButton = new ToolButton.from_stock(Gtk.Stock.MEDIA_PREVIOUS);
		playButton = new ToolButton.from_stock(Gtk.Stock.MEDIA_PLAY);
		nextButton = new ToolButton.from_stock(Gtk.Stock.MEDIA_NEXT);
		topDisplay = new TopDisplay(lm);
		
		column_browser_toggle = new ToggleButton ();
		viewSelector = new Granite.Widgets.ModeButton();
		searchField = new Granite.Widgets.SearchBar(_("Search Music"));

		// Set search timeout
		searchField.pause_delay = 150;

		info_panel = new InfoPanel(lm, this);
		statusbar = new Granite.Widgets.StatusBar();

		var add_playlist_image = Icons.render_image ("list-add-symbolic", IconSize.MENU);
		var shuffle_on_image = Icons.SHUFFLE_ON.render_image (IconSize.MENU);
		var shuffle_off_image = Icons.SHUFFLE_OFF.render_image (IconSize.MENU);
		var repeat_on_image = Icons.REPEAT_ON.render_image (IconSize.MENU);
		var repeat_off_image = Icons.REPEAT_OFF.render_image (IconSize.MENU);
		var info_panel_show = Icons.PANE_SHOW_SYMBOLIC.render_image (IconSize.MENU);
		var info_panel_hide = Icons.PANE_HIDE_SYMBOLIC.render_image (IconSize.MENU);
		var eq_show_image = Icons.EQ_SYMBOLIC.render_image (IconSize.MENU);
		var eq_hide_image = Icons.EQ_SYMBOLIC.render_image (IconSize.MENU);

		addPlaylistChooser = new SimpleOptionChooser.from_image (add_playlist_image);
		shuffleChooser = new SimpleOptionChooser.from_image (shuffle_on_image, shuffle_off_image);
		repeatChooser = new SimpleOptionChooser.from_image (repeat_on_image, repeat_off_image);
		info_panel_chooser = new SimpleOptionChooser.from_image (info_panel_hide, info_panel_show);
		eq_option_chooser = new SimpleOptionChooser.from_image (eq_hide_image, eq_show_image);

		repeatChooser.setTooltip (_("Disable Repeat"), _("Enable Repeat"));
		shuffleChooser.setTooltip (_("Disable Shuffle"), _("Enable Shuffle"));
		info_panel_chooser.setTooltip (_("Hide Info Panel"), _("Show Info Panel"));
		addPlaylistChooser.setTooltip (_("Add Playlist"));
		eq_option_chooser.setTooltip (_("Hide Equalizer"), _("Show Equalizer"));

		statusbar.insert_widget (addPlaylistChooser, true);
		statusbar.insert_widget (new Gtk.Box (Orientation.HORIZONTAL, 12), true);
		statusbar.insert_widget (shuffleChooser, true);
		statusbar.insert_widget (repeatChooser, true);
		statusbar.insert_widget (eq_option_chooser);
		statusbar.insert_widget (info_panel_chooser);

		// Set properties of various controls
		main_hpaned.set_position(settings.getSidebarWidth());
		view_container_hpaned.set_position((lm.settings.getWindowWidth() - lm.settings.getSidebarWidth()) - lm.settings.getMoreWidth());

		/* create appmenu menu */

		settingsMenu.append(fileImportMusic);
		settingsMenu.append(fileRescanMusicFolder);
		settingsMenu.append(new SeparatorMenuItem());
		settingsMenu.append(editPreferences);

		fileImportMusic.activate.connect(fileImportMusicClick);
		fileRescanMusicFolder.activate.connect ( () => { rescan_music_folder (); });

		editPreferences.set_label(_("Preferences"));

		editPreferences.activate.connect(editPreferencesClick);

		repeatChooser.appendItem(_("Off"));
		repeatChooser.appendItem(_("Song"));
		repeatChooser.appendItem(_("Album"));
		repeatChooser.appendItem(_("Artist"));
		repeatChooser.appendItem(_("All"));

		shuffleChooser.appendItem(_("Off"));
		shuffleChooser.appendItem(_("All"));

		info_panel_chooser.appendItem(_("Hide"));
		info_panel_chooser.appendItem(_("Show"));

		eq_option_chooser.appendItem(_("Hide"));
		eq_option_chooser.appendItem(_("Show"));

		repeatChooser.setOption(settings.getRepeatMode());
		shuffleChooser.setOption(settings.getShuffleMode());
		info_panel_chooser.setOption(settings.getMoreVisible() ? 1 : 0);
		eq_option_chooser.setOption(0);

		// Add controls to the GUI
		add(verticalBox);
		verticalBox.pack_start(topControls, false, true, 0);
#if HAVE_PODCASTS
		verticalBox.pack_start(videoArea, true, true, 0);
#endif
		verticalBox.pack_start(main_hpaned, true, true, 0);
		verticalBox.pack_end(statusbar, false, true, 0);

		var column_toggle_bin = new ToolItem();
		var topDisplayBin = new ToolItem();
		var viewSelectorBin = new ToolItem();
		var searchFieldBin = new ToolItem();

		viewSelector.append(Icons.VIEW_ICONS.render_image (IconSize.MENU));
		viewSelector.append(Icons.VIEW_DETAILS.render_image (IconSize.MENU));

		column_browser_toggle.set_image (Icons.VIEW_COLUMN.render_image (IconSize.MENU));

		// Tweak view selector's size
		viewSelector.margin_left = 12;
		viewSelector.margin_right = 8;

		viewSelector.valign = column_browser_toggle.valign = Gtk.Align.CENTER;
		
		viewSelectorBin.add(viewSelector);

		column_toggle_bin.add (column_browser_toggle);

		topDisplayBin.add(topDisplay);
		topDisplayBin.set_expand(true);

		topDisplay.margin_left = 30;
		topDisplay.margin_right = 30;

		searchFieldBin.add(searchField);
		searchFieldBin.margin_right = 12;

		// Set theming
		topControls.get_style_context().add_class(STYLE_CLASS_PRIMARY_TOOLBAR);
		main_hpaned.get_style_context().add_class ("sidebar-pane-separator");

		topControls.set_vexpand (false);
		topControls.set_hexpand (true);

		topControls.insert(previousButton, -1);
		topControls.insert(playButton, -1);
		topControls.insert(nextButton, -1);
		topControls.insert(viewSelectorBin, -1);
		topControls.insert(column_toggle_bin, -1);
		topControls.insert(topDisplayBin, -1);
		topControls.insert(searchFieldBin, -1);
		topControls.insert(app.create_appmenu(settingsMenu), -1);


		view_container_hpaned.pack1(view_container, true, false);
		view_container_hpaned.pack2(info_panel, false, false);

		// put the sidebar in a scrolled window so that it can scroll vertically
		var sidebar_scrolled = new Gtk.ScrolledWindow (null, null);
		sidebar_scrolled.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
		sidebar_scrolled.add (sideTree);

		main_hpaned.pack1 (sidebar_scrolled, false, false);
		main_hpaned.pack2 (view_container_hpaned, true, false);

		// add mounts to side tree view
		lm.device_manager.loadPreExistingMounts();

		int i = settings.getLastMediaPlaying();
		if(i != 0 && lm.media_from_id(i) != null && File.new_for_uri(lm.media_from_id(i).uri).query_exists()) {
			lm.playMedia(lm.media_from_id(i), true);
		}
		else {
			// don't show info panel if nothing playing
			info_panel.set_visible(false);
		}

		/* Connect events to functions */
		previousButton.clicked.connect(previousClicked);
		playButton.clicked.connect(playClicked);
		nextButton.clicked.connect(nextClicked);

		addPlaylistChooser.button_press_event.connect(addPlaylistChooserOptionClicked);
		eq_option_chooser.option_changed.connect(eq_option_chooser_clicked);

		repeatChooser.option_changed.connect(repeatChooserOptionChanged);
		shuffleChooser.option_changed.connect(shuffleChooserOptionChanged);
		info_panel_chooser.option_changed.connect(info_panel_chooserOptionChanged);

		searchField.activate.connect(searchFieldActivate);

		/* set up drag dest stuff */
		drag_dest_set(this, DestDefaults.ALL, {}, Gdk.DragAction.MOVE);
		Gtk.drag_dest_add_uri_targets(this);
		drag_data_received.connect(dragReceived);


		// ADD MAIN VIEWS
		build_main_views ();

		// ADD PLAYLIST VIEWS
		load_playlists();

		sideTree.resetView ();

		initialization_finished = true;

		update_sensitivities();
		show_all ();
		

		if(lm.media_active) {
			if(settings.getShuffleMode() == LibraryManager.Shuffle.ALL) {
				lm.setShuffleMode(LibraryManager.Shuffle.ALL, true);
			}
		}

		info_panel.set_visible (lm.settings.getMoreVisible());

		// Now set the selected view
		viewSelector.selected = settings.getViewMode();

		searchField.set_text(lm.settings.getSearchString());

		if(lm.song_ids().size == 0)
			setMusicFolder(Environment.get_user_special_dir(UserDirectory.MUSIC));
		
		// Redirect key presses to the search box.
		this.key_press_event.connect( (event) => {
			if (!searchField.sensitive || searchField.has_focus) {
				return false;
			}

			var typed_unichar = event.str.get_char ();
			if (!typed_unichar.validate ()) {
				return false;
			}

			unichar[] special_chars = {'&', '.', '-', '\'', '%', '(', ')', '=', '@', '!',
			                            '#', '+', '<', '>', ';', ':', '¿', '?', '¡'}; 

			if (typed_unichar.isalnum () || typed_unichar in special_chars) {
				searchField.grab_focus ();
				
				// Check if it actually got focused
				if (!searchField.has_focus)
					searchField.insert_at_cursor (event.str);
			}

			return false;
		});

		lm.media_added.connect (update_sensitivities);
		lm.media_removed.connect (update_sensitivities);
	}


	/**
	 * Show notification asyncronously
	 */
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

	private void notify_current_media () {
		if (lm.media_info != null && lm.media_info.media != null)
			show_notification_from_media (lm.media_info.media);
	}

	/**
	 * Description:
	 * Builds the views (view wrapper) and adds the respective element to the sidebar TreeView.
	 *
	 * @return true if succeeds, false if fails.
	 */
	public bool add_view (string view_name, ViewWrapper view_wrapper, out TreeIter? iter = null)
	{
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
		music_view_wrapper.set_media_from_ids_async (lm.song_ids ());

		debug ("Done with main views.");
	}
	
	private void load_playlists () {
		debug ("Loading playlists");

		// Add Similar playlist. FIXME: This is part of LastFM and shouldn't belong to the core in the future
		var similar_view = new SimilarViewWrapper (this);
		add_view (_("Similar"), similar_view);

		// Add Queue view
		var queue_view = new QueueViewWrapper (this);
		add_view (_("Queue"), queue_view);
		queue_view.set_media_async (lm.queue ());

		// Add History view
		var history_view = new HistoryViewWrapper (this);
		add_view (_("History"), history_view);
		history_view.set_media_async (lm.already_played ());

		// load smart playlists
		foreach(SmartPlaylist p in lm.smart_playlists()) {
			addSideListItem (p);
		}

		// load playlists
		foreach(Playlist p in lm.playlists()) {
			addSideListItem (p);
		}

		debug ("Finished loading playlists");
	}

	public TreeIter addSideListItem (GLib.Object o) {
		TreeIter iter = sideTree.library_music_iter; //just a default

		if(o is Playlist) {
			Playlist p = (Playlist)o;

			var view = new PlaylistViewWrapper (this, p.tvs, p.rowid);
			add_view (p.name, view, out iter);
			// TODO: does p.media () work? it's faster
			view.set_media_async (lm.media_from_playlist (p.rowid));
		}
		else if(o is SmartPlaylist) {
			SmartPlaylist p = (SmartPlaylist)o;
			
			var view = new PlaylistViewWrapper (this, p.tvs, p.rowid);
			add_view (p.name, view, out iter);
			view.set_media_async (lm.media_from_smart_playlist (p.rowid));
		}
		/* XXX: Migrate this code to the new API */
		else if(o is Device) {
			Device d = (Device)o;

			if(d.getContentType() == "cdrom") {

				message("CD added with %d songs.\n", d.get_medias().size);

				/* FIXME: this can be easily migrated. Not doing it now to avoid
				 *        breaking stuff.
				 */
				 var cd_setup = new TreeViewSetup(MusicListView.MusicColumn.ALBUM, Gtk.SortType.ASCENDING, ViewWrapper.Hint.CDROM);
				var vw = new DeviceViewWrapper (this, cd_setup, d);
				vw.set_media_async (d.get_medias ());
				iter = sideTree.addSideItem(sideTree.devices_iter, d, vw, d.getDisplayName(), ViewWrapper.Hint.CDROM);
				view_container.add_view (vw);
			}
			else {
				debug ("adding ipod device view with %d\n", d.get_medias().size);
				DeviceView dv = new DeviceView(lm, d);
				//vw = new DeviceViewWrapper(this, d.get_medias(), "Artist", Gtk.SortType.ASCENDING, ViewWrapper.Hint.DEVICE, -1, d);
				iter = sideTree.addSideItem(sideTree.devices_iter, d, dv, d.getDisplayName(), ViewWrapper.Hint.NONE);
				view_container.add_view (dv);
			}
		}
		
		return iter;
	}



	/**
	 * This is handled more carefully inside each ViewWrapper object.
	 */
	public void update_sensitivities() {
		if(!initialization_finished)
			return;

		debug ("UPDATE SENSITIVITIES");

		bool folder_set = (settings.getMusicFolder () != "");
		bool have_media = lm.media_count() > 0;
		bool doing_ops = lm.doing_file_operations();
		bool media_active = lm.media_active;

		fileImportMusic.set_sensitive(!doing_ops && folder_set);
		fileRescanMusicFolder.set_sensitive(!doing_ops && folder_set);

		if(doing_ops) {
			topDisplay.show_progressbar();
		}
		else if(media_active && lm.media_info.media.mediatype == 3) {
			topDisplay.hide_scale_and_progressbar();
		}
		else {
			topDisplay.show_scale();
		}

		bool show_top_display = media_active || doing_ops;
		topDisplay.set_visible (show_top_display);

		topDisplay.set_scale_sensitivity(media_active);

		bool show_info_panel = settings.getMoreVisible () && media_active && folder_set;
		info_panel.set_visible (show_info_panel);
		
		statusbar.set_sensitive (media_active && folder_set);

		// hide playlists when media list is empty
		sideTree.setVisibility(sideTree.playlists_iter, have_media);

		if(!lm.media_active || have_media && !lm.playing) {
			playButton.set_stock_id(Gtk.Stock.MEDIA_PLAY);
		}
	}

	public virtual void progressNotification(string? message, double progress) {
		if(message != null && progress >= 0.0 && progress <= 1.0)
			topDisplay.set_label_markup(message);

		topDisplay.set_progress_value(progress);
	}

	public void updateInfoLabel() {
		if(lm.doing_file_operations()) {
			debug ("doing file operations, returning null in updateInfoLabel\n");
			return;
		}

		if(!lm.media_active) {
			topDisplay.set_label_markup("");
			debug ("setting info label as ''\n");
			return;
		}

		string beg = "";

		if(lm.media_info.media.mediatype == 3) // radio
			beg = "<b>" + lm.media_info.media.album_artist.replace("\n", "") + "</b>\n";

		//set the title
		Media s = lm.media_info.media;
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
			s = lm.media_from_name(s.title, s.artist);

			if(s.rowid != 0) {
				lm.playMedia(s.rowid);
				int position = (int)settings.getLastMediaPosition();
				topDisplay.change_value(ScrollType.NONE, position);
			}

			return;
		}*/

		updateInfoLabel();

		//reset the media position
		topDisplay.set_scale_sensitivity(true);
		topDisplay.set_scale_range(0.0, lm.media_info.media.length);

		/*if(m.mediatype == 1 || m.mediatype == 2) {
			/*message("setting position to resume_pos which is %d\n", lm.media_from_id(i).resume_pos );
			Timeout.add(250, () => {
				topDisplay.change_value(ScrollType.NONE, lm.media_from_id(i).resume_pos);
				return false;
			});*
		}
		else {
			topDisplay.change_value(ScrollType.NONE, 0);
		}*/

		//if(!mediaPosition.get_sensitive())
		//	mediaPosition.set_sensitive(true);

		//reset some booleans
		tested_for_video = false;
		queriedlastfm = false;
		media_considered_played = false;
		added_to_play_count = false;
		scrobbled_track = false;
		
		update_sensitivities();

		// if radio, we can't depend on current_position_update. do that stuff now.
		if(lm.media_info.media.mediatype == Media.MediaType.STATION) {
			queriedlastfm = true;
			
			lm.lfm.fetchCurrentAlbumInfo();
			lm.lfm.fetchCurrentArtistInfo();
			lm.lfm.fetchCurrentTrackInfo();
			lm.lfm.postNowPlaying();
			
			// always show notifications for the radio, since user likely does not know media
			notify_current_media ();
		}
		else {
			Timeout.add(3000, () => {
				if(lm.media_info.media != null && lm.media_info.media == m && m.rowid != LibraryManager.PREVIEW_MEDIA_ID) {
					lm.lfm.fetchCurrentSimilarSongs();
				}
				
				return false;
			});
		}
	}


	public virtual void playback_stopped(int was_playing) {
		//reset some booleans
		tested_for_video = false;
		queriedlastfm = false;
		media_considered_played = false;
		added_to_play_count = false;

		update_sensitivities();

		debug ("stopped\n");
	}

	public virtual void medias_updated(Collection<int> ids) {
		if(lm.media_active && ids.contains(lm.media_info.media.rowid)) {
			updateInfoLabel();
		}
	}



	public virtual void loveButtonClicked() {
		lm.lfm.loveTrack(lm.media_info.media.title, lm.media_info.media.artist);
	}

	public virtual void banButtonClicked() {
		lm.lfm.banTrack(lm.media_info.media.title, lm.media_info.media.artist);
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
		if(!lm.media_active) {
			debug("No media is currently playing. Starting from the top\n");
			//set current medias by current view
			Gtk.Widget w = view_container.get_current_view ();
			
			if(w is ViewWrapper) {
				(w as ViewWrapper).play_first_media ();
			}

			lm.getNext(true);

			lm.playing = true;
			playButton.set_stock_id(Gtk.Stock.MEDIA_PAUSE);
			lm.player.play();

			if (!inhibit_notifications)
				notify_current_media ();
		}
		else {
			if(lm.playing) {
				lm.playing = false;
				lm.player.pause();

				playButton.set_stock_id(Gtk.Stock.MEDIA_PLAY);
			}
			else {
				lm.playing = true;
				lm.player.play();
				playButton.set_stock_id(Gtk.Stock.MEDIA_PAUSE);
			}
		}

		playPauseChanged();
	}

	public virtual void play_next_media (bool inhibit_notifications = false) {
		// if not 90% done, skip it
		if(!added_to_play_count) {
			lm.media_info.media.skip_count++;

			// don't update, it will be updated eventually
			//lm.update_media_item (lm.media_info.media, false, false);
		}

		Media? m = null;
		if(lm.next_gapless_id != 0) {
			int next_id = lm.next_gapless_id;
			m = lm.media_from_id (next_id);
			lm.playMedia (m, false);
		}
		else
			m = lm.getNext(true);

		/* test to stop playback/reached end */
		if(m == null) {
			lm.player.pause();
			lm.playing = false;
			update_sensitivities();
			return;
		}

		if (!inhibit_notifications)
			notify_current_media ();
	}

	public virtual void play_previous_media (bool inhibit_notifications = false) {
		if(lm.player.getPosition() < 5000000000 || (lm.media_active && lm.media_info.media.mediatype == 3)) {
			bool play = true;
			var prev = lm.getPrevious(true);

			/* test to stop playback/reached end */
			if(prev == null) {
				lm.player.pause();
				lm.playing = false;
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
		if(!lm.doing_file_operations()) {
			/*if(!(GLib.File.new_for_path(lm.settings.getMusicFolder()).query_exists() && lm.settings.getCopyImportedMusic())) {
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
			    if(folders[i] == "" || folders[i] != settings.getMusicFolder()) {
			        folders_list += folders[i];
			        if (i + 1 != folders.length)
			            folders_list += ", ";
			    }
			}
			if(GLib.File.new_for_path(lm.settings.getMusicFolder()).query_exists()) {
				topDisplay.set_label_markup(_("<b>Importing</b> music from <b>%s</b> to library.").printf(folders_list));
				topDisplay.show_progressbar();

				lm.add_folder_to_library(folders[0], folders[1:folders.length]);
				update_sensitivities();
			}
		}
		else {
			debug("Can't add to library.. already doing file operations\n");
		}
	}

	public void rescan_music_folder () {
		if (!lm.doing_file_operations ()) {
			if (GLib.File.new_for_path (this.settings.getMusicFolder ()).query_exists()) {
				topDisplay.set_label_markup("<b>" + _("Rescanning music folder for changes") + "</b>");
				topDisplay.show_progressbar();

				lm.rescan_music_folder();
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
			//vw.do_update(vw.current_view, lm.song_ids(), true, true, false);
			//vw.column_browser.populate (lm.song_ids());
			vw.set_media_from_ids_async (lm.song_ids());
		}
	}

	public virtual void musicCounted(int count) {
		debug ("found %d media, importing.\n", count);
	}

	/* this is after setting the music library */
	public virtual void musicAdded(LinkedList<string> not_imported) {

		if(lm.media_active) {
			updateInfoLabel();
		}
		else
			topDisplay.set_label_text("");

		if(not_imported.size > 0) {
			NotImportedWindow nim = new NotImportedWindow(this, not_imported, lm.settings.getMusicFolder());
			nim.show();
		}

		update_sensitivities();

		//now notify user
		show_notification (_("Import Complete"), _("%s has imported your library.").printf (app.get_name ()));
	}

	/* this is when you import music from a foreign location into the library */
	public virtual void musicImported(LinkedList<Media> new_medias, LinkedList<string> not_imported) {
		if(lm.media_active) {
			updateInfoLabel();
		}
		else
			topDisplay.set_label_text("");

		resetSideTree(false);

		update_sensitivities();
	}

	public virtual void musicRescanned(LinkedList<Media> new_medias, LinkedList<string> not_imported) {
		if(lm.media_active) {
			updateInfoLabel();
		}
		else
			topDisplay.set_label_text("");

		resetSideTree(false);
		debug("music Rescanned\n");
		update_sensitivities();
	}

	public void editPreferencesClick() {
		PreferencesWindow pw = new PreferencesWindow(lm, this);

		pw.changed.connect( (folder) => {
			setMusicFolder(folder);
		});
	}

	public void setMusicFolder(string folder) {
		if(lm.doing_file_operations())
			return;

		if(lm.song_ids().size > 0 || lm.playlist_count() > 0) {
			var smfc = new SetMusicFolderConfirmation(lm, this, folder);
			smfc.finished.connect( (cont) => {
				if(cont) {
					lm.set_music_folder(folder);
				}
			});
		}
		else {
			lm.set_music_folder(folder);
		}
	}

	public virtual void end_of_stream() {
		nextClicked();
	}

	public virtual void current_position_update(int64 position) {
		if (!lm.media_active)
			return;

		if (lm.media_info.media.rowid == Media.PREVIEW_ROWID) // is preview
			return;

		double sec = ((double)position/1000000000);

		if(lm.player.set_resume_pos)
			lm.media_info.media.resume_pos = (int)sec;

		// at about 3 seconds, update last fm. we wait to avoid excessive querying last.fm for info
		if(position > 3000000000 && !queriedlastfm) {
			queriedlastfm = true;

			lm.lfm.fetchCurrentSimilarSongs();
			lm.lfm.fetchCurrentAlbumInfo();
			lm.lfm.fetchCurrentArtistInfo();
			lm.lfm.fetchCurrentTrackInfo();
			lm.lfm.postNowPlaying();
		}

		//at 30 seconds in, we consider the media as played
		if(position > 30000000000 && !media_considered_played) {
			media_considered_played = true;
			lm.media_info.media.last_played = (int)time_t();

#if HAVE_PODCASTS
			if(lm.media_info.media.mediatype == 1) { //podcast
				added_to_play_count = true;
				++lm.media_info.media.play_count;
			}
#endif

			lm.update_media_item (lm.media_info.media, false, false);

			// add to the already played list
			lm.add_already_played (lm.media_info.media);

#if HAVE_ZEITGEIST
			var event = new Zeitgeist.Event.full (Zeitgeist.ZG_ACCESS_EVENT,
			                                       Zeitgeist.ZG_SCHEDULED_ACTIVITY, "app://beatbox.desktop",
			                                       new Zeitgeist.Subject.full(lm.media_info.media.uri,
			                                                                   Zeitgeist.NFO_AUDIO,
			                                                                   Zeitgeist.NFO_FILE_DATA_OBJECT,
			                                                                   "text/plain", "",
			                                                                   lm.media_info.media.title, ""));
			new Zeitgeist.Log ().insert_events_no_reply(event);
#endif
		}

		// at halfway, scrobble
		if((double)(sec/(double)lm.media_info.media.length) > 0.50 && !scrobbled_track) {
			scrobbled_track = true;
			lm.lfm.postScrobbleTrack ();
		}

		// at 80% done with media, add 1 to play count
		if((double)(sec/(double)lm.media_info.media.length) > 0.80 && !added_to_play_count) {
			added_to_play_count = true;
			lm.media_info.media.play_count++;
			lm.update_media_item (lm.media_info.media, false, false);
		}
	}

	public void media_not_found(int id) {
// XXX FIXME TODO
#if 0
		var not_found = new FileNotFoundDialog(lm, this, id);
		not_found.show();
#endif
	}

	public void set_statusbar_info (string message)
	{
		statusbar.set_text (message);
	}

	public virtual void repeatChooserOptionChanged(int val) {
		lm.settings.setRepeatMode(val);

		if(val == 0)
			lm.repeat = LibraryManager.Repeat.OFF;
		else if(val == 1)
			lm.repeat = LibraryManager.Repeat.MEDIA;
		else if(val == 2)
			lm.repeat = LibraryManager.Repeat.ALBUM;
		else if(val == 3)
			lm.repeat = LibraryManager.Repeat.ARTIST;
		else if(val == 4)
			lm.repeat = LibraryManager.Repeat.ALL;
	}

	public virtual void shuffleChooserOptionChanged(int val) {
		if(val == 0)
			lm.setShuffleMode(LibraryManager.Shuffle.OFF, true);
		else if(val == 1)
			lm.setShuffleMode(LibraryManager.Shuffle.ALL, true);
	}

	public virtual bool addPlaylistChooserOptionClicked(Gdk.EventButton event) {
		if (event.type == Gdk.EventType.BUTTON_PRESS && event.button == 1) {
			sideTree.playlistMenuNewClicked();
			return true;
		}

		return false;
	}


	private Gtk.Window? equalizer_window = null;

	public virtual void eq_option_chooser_clicked (int val) {
		if (equalizer_window == null && val == 1) {
			equalizer_window = new EqualizerWindow (lm, this);
			equalizer_window.show_all ();
			equalizer_window.destroy.connect ( () => {
				// revert the option to "Hide equalizer" after the window is destroyed
				eq_option_chooser.setOption (0);
			});
		}
		else if (val == 0 && equalizer_window != null) {
			equalizer_window.destroy ();
			equalizer_window = null;
		}
	}


	public virtual void info_panel_chooserOptionChanged(int val) {
		info_panel.set_visible(val == 1);
		lm.settings.setMoreVisible(val == 1);
	}

	public void searchFieldActivate() {
		var vw = view_container.get_current_view ();

		if (vw != null && vw is ViewWrapper) {
			(vw as ViewWrapper).play_first_media ();
		}
	}

	public virtual void dragReceived(Gdk.DragContext context, int x, int y, Gtk.SelectionData data, uint info, uint timestamp) {
		if(dragging_from_music)
			return;

		var files_dragged = new LinkedList<string>();
		debug("dragged\n");
		foreach (string uri in data.get_uris ()) {
			files_dragged.add(File.new_for_uri(uri).get_path());
		}

		lm.add_files_to_library(files_dragged);
	}

	public void doAlert(string title, string message) {
		var dialog = new MessageDialog(this, DialogFlags.MODAL, MessageType.ERROR, ButtonsType.OK,
				title);

		dialog.title = app.get_name ();
		dialog.secondary_text = message;
		dialog.secondary_use_markup = true;

		dialog.run();
		dialog.destroy();
	}

	public override void destroy() {
		this.hide ();
		
		// Save media position and info
		lm.settings.setLastMediaPosition((int)((double)lm.player.getPosition
		()/1000000000));
		if(lm.media_active) {
			lm.media_info.media.resume_pos = (int)((double)lm.player.getPosition()/1000000000);
			lm.update_media_item (lm.media_info.media, false, false);
		}
		lm.player.pause();

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
		settings.setViewMode (viewSelector.selected);

		// Search FIXME: Temporary disabled
		//settings.setSearchString (searchField.get_text());
		
		// Save info pane (context pane) width
		settings.setMoreWidth(info_panel.get_allocated_width());

		// Save sidebar width
		settings.setSidebarWidth (main_hpaned.position);
		
		// Save window state
		settings.setWindowMaximized (window_maximized);
		settings.setWindowWidth (window_width);
		settings.setWindowHeight (window_height);

		base.destroy ();
	}

	public override bool configure_event(Gdk.EventConfigure event) {
		// Get window dimensions.
		window_maximized = (get_window().get_state() == Gdk.WindowState.MAXIMIZED);
		if (!window_maximized)
			get_size (out window_width, out window_height);
        
		return base.configure_event(event);
	}
}

