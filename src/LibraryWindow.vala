/*-
 * Copyright (c) 2011       Scott Ringwelski <sgringwe@mtu.edu>
 *
 * Originaly Written by Scott Ringwelski for BeatBox Music Player
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
//using Notify;

public class BeatBox.LibraryWindow : Gtk.Window {
	public BeatBox.LibraryManager lm;
	BeatBox.Settings settings;
	LastFM.SimilarSongs similarSongs;
	BeatBox.MediaKeyListener mkl;
	
	bool queriedlastfm; // whether or not we have queried last fm for the current song info
	bool song_considered_played; //whether or not we have updated last played and added to already played list
	bool added_to_play_count; // whether or not we have added one to play count on playing song
	bool scrobbled_track;
	LinkedList<string> timeout_search;//stops from doing useless search
	string last_search;//stops from searching same thing multiple times
	
	public bool dragging_from_music;
	public bool millerVisible;
	bool askToSetFolder;
	
	VBox verticalBox;
	VBox mainViews;
	public MillerColumns miller;
	VPaned millerPane;
	ElementaryWidgets.Welcome welcomeScreen;
	public DrawingArea videoArea;
	HPaned sourcesToSongs; //allows for draggable
	HPaned songsToInfo; // song info pane
	ScrolledWindow sideTreeScroll;
	VBox sideBar;
	VBox contentBox;
	public SideTreeView sideTree;
	ScrolledWindow songInfoScroll;
	ScrolledWindow pandoraScroll;
	ScrolledWindow grooveSharkScroll;
	InfoPanel infoPanel;
	CoverArtImage coverArt;
	Toolbar topControls;
	ToolButton previousButton;
	ToolButton playButton;
	ToolButton nextButton;
	ElementaryWidgets.TopDisplay topDisplay;
	public ElementaryWidgets.ModeButton viewSelector;
	public ElementaryWidgets.ElementarySearchEntry searchField;
	ElementaryWidgets.AppMenu appMenu;
	HBox statusBar;
	Label statusBarLabel;
	SimpleOptionChooser shuffleChooser;
	SimpleOptionChooser repeatChooser;
	SimpleOptionChooser infoPanelChooser;
	
	MenuBar topMenu;
	
	// basic file stuff
	ImageMenuItem libraryOperations;
	Menu libraryOperationsMenu;
	MenuItem fileSetMusicFolder;
	MenuItem fileImportMusic;
	MenuItem fileRescanMusicFolder;
	ImageMenuItem helpOnline;
	MenuItem helpTranslate;
	MenuItem helpReport;
	ImageMenuItem helpAbout;
	MenuItem editEqualizer;
	ImageMenuItem editPreferences;
	
	Menu settingsMenu;
	
	//Notify.Notification notification;
	
	public LibraryWindow(BeatBox.DataBaseManager dbm, string[] args) {
		settings = new BeatBox.Settings();
		//this.player = player;
		
		//this is used by many objects, is the media backend
		lm = new BeatBox.LibraryManager(dbm, settings, this, args);
		
		//various objects
		similarSongs = new LastFM.SimilarSongs(lm);
		timeout_search = new LinkedList<string>();
		mkl = new MediaKeyListener(lm, this);
		last_search = "";
		
#if HAVE_INDICATE
#if HAVE_DBUSMENU
		stdout.printf("Initializing MPRIS and sound menu\n");
		var mpris = new BeatBox.MPRIS(lm, this);
#endif
#endif
		
		dragging_from_music = false;
		askToSetFolder = false;
		
		build_ui();
		
		this.lm.player.end_of_stream.connect(end_of_stream);
		this.lm.player.current_position_update.connect(current_position_update);
		this.lm.player.song_not_found.connect(song_not_found);
		this.lm.music_counted.connect(musicCounted);
		this.lm.music_added.connect(musicAdded);
		this.lm.music_imported.connect(musicImported);
		this.lm.music_rescanned.connect(musicRescanned);
		this.lm.progress_notification.connect(progressNotification);
		this.lm.songs_removed.connect(songs_removed);
		this.lm.song_played.connect(song_played);
		this.lm.playback_stopped.connect(playback_stopped);
		this.lm.songs_updated.connect(songs_updated);
		
		this.similarSongs.similar_retrieved.connect(similarRetrieved);
		
		destroy.connect (on_quit);
		check_resize.connect(on_resize);
		this.destroy.connect (Gtk.main_quit);
		
		this.present();
		if(lm.song_count() == 0 && settings.getMusicFolder() == "") {
			stdout.printf("First run.\n");
			
		}
		else {
			lm.clearCurrent();
			//((MusicTreeView)sideTree.getWidget(sideTree.library_music_iter)).setAsCurrentList("0");
			
			// make sure we don't re-count stats
			if((int)settings.getLastSongPosition() > 5)
				queriedlastfm = true;
			if((int)settings.getLastSongPosition() > 30)
				song_considered_played = true;
			if(lm.song_info.song != null && (double)((int)settings.getLastSongPosition()/(double)lm.song_info.song.length) > 0.90)
				added_to_play_count = true;
			
			int i = settings.getLastSongPlaying();
			if(i != 0) {
				/* time out works because... monkeys eat bananas */
				int position = (int)settings.getLastSongPosition();
				Timeout.add(250, () => {
					lm.playSong(i);
					
					((ViewWrapper)sideTree.getWidget(sideTree.convertToFilter(sideTree.library_music_iter))).list.setAsCurrentList(0);
					if(settings.getShuffleMode() == LibraryManager.Shuffle.ALL)
						lm.setShuffleMode(LibraryManager.Shuffle.ALL);
					
					searchField.set_text(lm.settings.getSearchString());
					
					topDisplay.change_value(ScrollType.NONE, position);
						
					return false;
				});
			}
			else {
				/* don't show info panel if nothing playing */
				infoPanel.set_visible(false);
			}
			
			// rescan on startup
			/*lm.rescan_music_folder();*/
		}
		
		/*if(!File.new_for_path(settings.getMusicFolder()).query_exists() && settings.getMusicFolder() != "") {
			doAlert("Music folder not mounted", "Your music folder is not mounted. Please mount your music folder before using BeatBox.");
		}*/
	}
	
	public void build_ui() {
		// simple message to terminal
		stdout.printf("Building user interface\n");
		
		// set the size based on saved gconf settings
		set_default_size(settings.getWindowWidth(), settings.getWindowHeight());
		
		// set window min/max
		Gdk.Geometry geo = Gdk.Geometry();
		geo.min_width = 700;
		geo.min_height = 400;
		set_geometry_hints(this, geo, Gdk.WindowHints.MIN_SIZE);
		
		// set the title
		set_title("BeatBox");
		
		// set the icon
		set_icon( render_icon("beatbox", IconSize.DIALOG, null));
		
		/* Initialize all components */
		verticalBox = new VBox(false, 0);
		sourcesToSongs = new HPaned();
		songsToInfo = new HPaned();
		contentBox = new VBox(false, 0);
		millerPane = new VPaned();
		mainViews = new VBox(false, 0);
		videoArea = new DrawingArea();
		welcomeScreen = new ElementaryWidgets.Welcome("Get some tunes.", "BeatBox can't seem to find your music");
		sideTree = new SideTreeView(lm, this);	
		sideTreeScroll = new ScrolledWindow(null, null);
		coverArt = new CoverArtImage(lm, this);	
		topMenu = new MenuBar();
		libraryOperations = new ImageMenuItem.from_stock("folder-music", null);
		libraryOperationsMenu = new Menu();
		fileSetMusicFolder = new MenuItem.with_label("Set Music Folder");
		fileImportMusic = new MenuItem.with_label("Import to Library");
		fileRescanMusicFolder = new MenuItem.with_label("Rescan Music Folder");
		helpOnline = new ImageMenuItem.from_stock(Gtk.Stock.HELP, null);
		helpTranslate = new MenuItem.with_label("Translate This Application...");
		helpReport = new MenuItem.with_label("Report a Problem...");
		helpAbout = new ImageMenuItem.from_stock(Gtk.Stock.ABOUT, null);
		editEqualizer = new MenuItem.with_label("Equalizer");
		editPreferences = new ImageMenuItem.from_stock(Gtk.Stock.PREFERENCES, null);
		settingsMenu = new Menu();
		topControls = new Toolbar();
		previousButton = new ToolButton.from_stock(Gtk.Stock.MEDIA_PREVIOUS);
		playButton = new ToolButton.from_stock(Gtk.Stock.MEDIA_PLAY);
		nextButton = new ToolButton.from_stock(Gtk.Stock.MEDIA_NEXT);
		topDisplay = new ElementaryWidgets.TopDisplay(lm);
		viewSelector = new ElementaryWidgets.ModeButton();
		searchField = new ElementaryWidgets.ElementarySearchEntry("Search...");
		miller = new MillerColumns(lm, this); //miller must be below search for it to work properly
		appMenu = new ElementaryWidgets.AppMenu.from_stock(Gtk.Stock.PROPERTIES, Gtk.IconSize.MENU, "Menu", settingsMenu);
		songInfoScroll = new ScrolledWindow(null, null);
		pandoraScroll = new ScrolledWindow(null, null);
		grooveSharkScroll = new ScrolledWindow(null, null);
		infoPanel = new InfoPanel(lm, this);
		sideBar = new VBox(false, 0);
		statusBar = new HBox(false, 0);
		statusBarLabel = new Label("");
		shuffleChooser = new SimpleOptionChooser(render_icon("media-playlist-shuffle-active-symbolic", IconSize.SMALL_TOOLBAR, null), render_icon("media-playlist-shuffle-symbolic", IconSize.SMALL_TOOLBAR, null));
		repeatChooser = new SimpleOptionChooser(render_icon("media-playlist-repeat-active-symbolic", IconSize.SMALL_TOOLBAR, null), render_icon("media-playlist-repeat-symbolic", IconSize.SMALL_TOOLBAR, null));
		infoPanelChooser = new SimpleOptionChooser(render_icon("info", IconSize.SMALL_TOOLBAR, null), render_icon("info", IconSize.SMALL_TOOLBAR, null));
		
		/*notification = (Notify.Notification)GLib.Object.new (
						typeof (Notify.Notification),
						"summary", "Title",
						"body", "Artist\nAlbum");*/
		
		/* Set properties of various controls */
		sourcesToSongs.set_position(settings.getSidebarWidth());
		songsToInfo.set_position((lm.settings.getWindowWidth() - lm.settings.getSidebarWidth()) - lm.settings.getMoreWidth());
		
		//for setting maximum size for setting hpane position max size
		//sideBar.set_geometry_hints(
		
		miller.populateColumns("", lm.song_ids());
		buildSideTree();
		
		sideTreeScroll = new ScrolledWindow(null, null);
		sideTreeScroll.set_policy (PolicyType.NEVER, PolicyType.AUTOMATIC);
		sideTreeScroll.add(sideTree);
		
		millerPane.set_position(settings.getMillerHeight());
		
		updateSensitivities();
		
		/* create appmenu menu */
		libraryOperationsMenu.append(fileSetMusicFolder);
		libraryOperationsMenu.append(fileImportMusic);
		libraryOperationsMenu.append(fileRescanMusicFolder);
		libraryOperations.submenu = libraryOperationsMenu;
		libraryOperations.set_label("Library");
		
		settingsMenu.append(libraryOperations);
		settingsMenu.append(new SeparatorMenuItem());
		settingsMenu.append(helpOnline);
		settingsMenu.append(helpTranslate);
		settingsMenu.append(helpReport);
		settingsMenu.append(new SeparatorMenuItem());
		settingsMenu.append(editEqualizer);
		settingsMenu.append(editPreferences);
		settingsMenu.append(helpAbout);
		
		fileSetMusicFolder.activate.connect(editPreferencesClick);
		fileImportMusic.activate.connect(fileImportMusicClick);
		fileRescanMusicFolder.activate.connect(fileRescanMusicFolderClick);
		
		helpOnline.set_label("Get Help Online...");
		helpOnline.activate.connect( () => {
			string auth_uri = "https://answers.launchpad.net/beat-box";
			try {
				GLib.AppInfo.launch_default_for_uri (auth_uri, null);
			}
			catch(GLib.Error err) {
				stdout.printf("Could not load webpage %s: %s\n", auth_uri, err.message);
			}
		});
		helpTranslate.activate.connect( () => {
			string auth_uri = "https://translations.launchpad.net/beat-box";
			try {
				GLib.AppInfo.launch_default_for_uri (auth_uri, null);
			}
			catch(GLib.Error err) {
				stdout.printf("Could not load webpage %s: %s\n", auth_uri, err.message);
			}
		});
		helpReport.activate.connect( () => {
			string auth_uri = "https://bugs.launchpad.net/beat-box";
			try {
				GLib.AppInfo.launch_default_for_uri (auth_uri, null);
			}
			catch(GLib.Error err) {
				stdout.printf("Could not load webpage %s: %s\n", auth_uri, err.message);
			}
		});
		
		helpAbout.set_label("About");
		editPreferences.set_label("Preferences");
		
		helpAbout.activate.connect(helpAboutClick);
		editEqualizer.activate.connect(editEqualizerClick);
		editPreferences.activate.connect(editPreferencesClick);
		
		// make the background white
		EventBox statusEventBox = new EventBox();
		statusEventBox.add(statusBar);
		
		Gdk.Color c = Gdk.Color();
		Gdk.Color.parse("#FFFFFF", out c);
		statusEventBox.modify_bg(Gtk.StateType.NORMAL, sideTree.style.base[Gtk.StateType.NORMAL]);
		
		repeatChooser.appendItem("Off");
		repeatChooser.appendItem("Song");
		repeatChooser.appendItem("Album");
		repeatChooser.appendItem("Artist");
		repeatChooser.appendItem("All");
		
		shuffleChooser.appendItem("Off");
		shuffleChooser.appendItem("All");
		
		infoPanelChooser.appendItem("Hide");
		infoPanelChooser.appendItem("Show");
		
		repeatChooser.setOption(settings.getRepeatMode());
		shuffleChooser.setOption(settings.getShuffleMode());
		infoPanelChooser.setOption(settings.getMoreVisible() ? 1 : 0);
		
		/* Add controls to the GUI */
		add(verticalBox);
		verticalBox.pack_start(topMenu, false, true, 0);
		verticalBox.pack_start(topControls, false, true, 0);
		verticalBox.pack_start(videoArea, true, true, 0);
        verticalBox.pack_start(sourcesToSongs, true, true, 0);
        
        ToolItem topDisplayBin = new ToolItem();
        ToolItem viewSelectorBin = new ToolItem();
        ToolItem searchFieldBin = new ToolItem();
        ToolItem appMenuBin = new ToolItem();
        topDisplayBin.add(topDisplay);
        topDisplayBin.set_border_width(1);
        viewSelectorBin.add(viewSelector);
        viewSelectorBin.set_border_width(3);
        searchFieldBin.add(searchField);
        appMenuBin.add(appMenu);
        
        topDisplayBin.set_expand(true);
        viewSelector.append(new Image.from_stock("view-list-icons-symbolic", IconSize.MENU));
        viewSelector.append(new Image.from_stock("view-list-details-symbolic", IconSize.MENU));
        viewSelector.append(new Image.from_stock("view-list-column-symbolic", IconSize.MENU));
        viewSelector.append(new Image.from_stock("view-list-video-symbolic", IconSize.MENU));
        
        topControls.insert(previousButton, 0);
        topControls.insert(playButton, 1);
        topControls.insert(nextButton, 2);
        topControls.insert(viewSelectorBin, 3);
        topControls.insert(topDisplayBin, 4);
        topControls.insert(searchFieldBin, 5);
        topControls.insert(appMenuBin, 6);
		
		//set the name for elementary theming
		sourcesToSongs.name = "SidebarHandleLeft";
		sideTree.name = "SidebarContent";
		
		contentBox.pack_start(welcomeScreen, true, true, 0);
		welcomeScreen.append("folder-music", "Set Music Folder", "Select your music folder and build your library.");
		
		millerPane.pack1(miller, false, true);
		millerPane.pack2(mainViews, true, true);
		
		contentBox.pack_start(millerPane, true, true, 0);
		contentBox.pack_start(statusEventBox, false, true, 0);
		
		songsToInfo.pack1(contentBox, true, true);
		songsToInfo.pack2(infoPanel, false, false);
		
		sourcesToSongs.pack1(sideBar, false, true);
		sourcesToSongs.pack2(songsToInfo, true, true);
		
		sideBar.pack_start(sideTreeScroll, true, true, 0);
		sideBar.pack_end(coverArt, false, true, 0);
		
		statusBar.pack_start(shuffleChooser, false, false, 2);
		statusBar.pack_start(repeatChooser, false, false, 2);
		statusBar.pack_start(statusBarLabel, true, true, 0);
		statusBar.pack_start(wrap_alignment(infoPanelChooser, 0, 10, 0, 0), false, false, 2);
		
		/* Connect events to functions */
		sourcesToSongs.get_child1().size_allocate.connect(sourcesToSongsHandleSet);
		welcomeScreen.activated.connect(welcomeScreenActivated);
		//sideTree.row_activated.connect(sideListDoubleClick);
		previousButton.clicked.connect(previousClicked);
		playButton.clicked.connect(playClicked);
		nextButton.clicked.connect(nextClicked);
		infoPanel.size_allocate.connect(infoPanelResized);
		repeatChooser.option_changed.connect(repeatChooserOptionChanged);
		shuffleChooser.option_changed.connect(shuffleChooserOptionChanged);
		infoPanelChooser.option_changed.connect(infoPanelChooserOptionChanged);
		viewSelector.notify["selected"].connect(updateMillerColumns);
		viewSelector.notify["selected"].connect( () => { updateSensitivities(); } );
		millerPane.get_child1().size_allocate.connect(millerResized);
		searchField.activate.connect(searchFieldActivate);
		
		/* set up drag dest stuff */
		drag_dest_set(this, DestDefaults.ALL, {}, Gdk.DragAction.MOVE);
		Gtk.drag_dest_add_uri_targets(this);
		drag_data_received.connect(dragReceived);
		
		show_all();
		//topMenu.hide();
		//topDisplay.show_scale();
		sideTree.resetView();
		//topDisplay.set_scale_sensitivity(false);
		viewSelector.selected = settings.getViewMode();
		//welcomeScreen.hide();
		//infoPanel.set_visible(settings.getMoreVisible());
		updateSensitivities();
		viewSelector.set_showing(3, false);
		updateMillerColumns();
		
		// add mounts to side tree view
		sideTree.dm.loadPreExistingMounts();
		
		bool genreV, artistV, albumV;
		lm.settings.getMillerVisibilities(out genreV, out artistV, out albumV);
		miller.updateColumnVisibilities(genreV, artistV, albumV);
	}
	
	public static Gtk.Alignment wrap_alignment (Gtk.Widget widget, int top, int right, int bottom, int left) {
		var alignment = new Gtk.Alignment(0.0f, 0.0f, 1.0f, 1.0f);
		alignment.top_padding = top;
		alignment.right_padding = right;
		alignment.bottom_padding = bottom;
		alignment.left_padding = left;
		
		alignment.add(widget);
		return alignment;
	}
	
	/** Builds the side tree on TreeView view
	 * @param view The side tree to build it on
	 */
	private void buildSideTree() {
		//var newRockReleases = store.newReleasesByTag("rock", 1);
		//var la = store.getReleasesInRange("20110601", null, 1);
		//var topTracks = store.topTracks("month", null, 1);
		/*foreach(var artist in store.topArtists("week", null, null, 1)) {
			stdout.printf("%s\n", artist.name);
		}*/
		
		ViewWrapper vw;
		
		sideTree.addBasicItems();
		
		vw = new ViewWrapper(lm, this, new LinkedList<int>(), lm.similar_setup.sort_column, lm.similar_setup.sort_direction, MusicTreeView.Hint.SIMILAR, -1);
		sideTree.addSideItem(sideTree.playlists_iter, null, vw, "Similar");
		mainViews.pack_start(vw, true, true, 0);
		
		vw = new ViewWrapper(lm, this, lm.queue(), lm.queue_setup.sort_column, lm.queue_setup.sort_direction, MusicTreeView.Hint.QUEUE, -1);
		sideTree.addSideItem(sideTree.playlists_iter, null, vw, "Queue");
		mainViews.pack_start(vw, true, true, 0);
		
		vw = new ViewWrapper(lm, this, lm.already_played(), lm.history_setup.sort_column, lm.history_setup.sort_direction, MusicTreeView.Hint.HISTORY, -1);
		sideTree.addSideItem(sideTree.playlists_iter, null, vw, "History");
		mainViews.pack_start(vw, true, true, 0);
		
		vw = new ViewWrapper(lm, this, lm.song_ids(), lm.music_setup.sort_column, lm.music_setup.sort_direction, MusicTreeView.Hint.MUSIC, -1);
		sideTree.addSideItem(sideTree.library_iter, null, vw, "Music");
		mainViews.pack_start(vw, true, true, 0);
		
		if(BeatBox.Beatbox.enableStore) {
			Store.StoreView storeView = new Store.StoreView(lm, this);
			sideTree.addSideItem(sideTree.network_iter, null, storeView, "Music Store");
			mainViews.pack_start(storeView, true, true, 0);
		}
		
		
		// load smart playlists
		foreach(SmartPlaylist p in lm.smart_playlists()) {
			addSideListItem(p);
		}
		
		// load playlists
		foreach(Playlist p in lm.playlists()) {
			addSideListItem(p);
		}
		
		sideTree.expand_all();
		sideTree.resetView();
	}
	
	public void addSideListItem(GLib.Object o) {
		TreeIter item = sideTree.library_music_iter; //just a default
		ViewWrapper vw = null;
		
		if(o is Playlist) {
			Playlist p = (Playlist)o;
			
			vw = new ViewWrapper(lm, this, lm.songs_from_playlist(p.rowid), p.tvs.sort_column, p.tvs.sort_direction, MusicTreeView.Hint.PLAYLIST, p.rowid);
			item = sideTree.addSideItem(sideTree.playlists_iter, p, vw, p.name);
			mainViews.pack_start(vw, true, true, 0);
		}
		else if(o is SmartPlaylist) {
			SmartPlaylist p = (SmartPlaylist)o;
			
			vw = new ViewWrapper(lm, this, lm.songs_from_smart_playlist(p.rowid), p.tvs.sort_column, p.tvs.sort_direction, MusicTreeView.Hint.SMART_PLAYLIST, p.rowid);
			item = sideTree.addSideItem(sideTree.playlists_iter, p, vw, p.name);
			mainViews.pack_start(vw, true, true, 0);
		}
		else if(o is Device) {
			Device d = (Device)o;
			
			if(d.getContentType() == "cdrom") {
				vw = new DeviceViewWrapper(lm, this, new Gee.LinkedList<int>(), "Track", Gtk.SortType.ASCENDING, MusicTreeView.Hint.CDROM, -1, d);
				item = sideTree.addSideItem(sideTree.devices_iter, d, vw, d.getDisplayName());
				mainViews.pack_start(vw, true, true, 0);
			}
			else if(d.getContentType().contains("ipod")) {
				Label l = new Label(d.getDescription());
				item = sideTree.addSideItem(sideTree.devices_iter, d, l, d.getDisplayName());
				mainViews.pack_start(l, true, true, 0);
			}
			else if(d.getContentType() == "android") {
				Label l = new Label(d.getDescription());
				item = sideTree.addSideItem(sideTree.devices_iter, d, l, d.getDisplayName());
				mainViews.pack_start(l, true, true, 0);

			}
		}
		
		vw.show_all();
	}
	
	public void updateSensitivities() {
		bool haveSongs = (lm.song_count() != 0);
		bool doingOps = lm.doing_file_operations;
		bool nullSong = (lm.song_info.song == null);
		bool showMore = lm.settings.getMoreVisible();
		
		fileSetMusicFolder.set_sensitive(!doingOps);
		fileImportMusic.set_sensitive(!doingOps && haveSongs);
		fileRescanMusicFolder.set_sensitive(!doingOps && haveSongs);
		
		if(doingOps)
			topDisplay.show_progressbar();
		else
			topDisplay.show_scale();
		
		sourcesToSongs.set_visible(viewSelector.selected != 3);
		videoArea.set_visible(viewSelector.selected == 3);
		
		topDisplay.set_visible(!nullSong || doingOps);
		topDisplay.set_scale_sensitivity(!nullSong);
		
		previousButton.set_sensitive(haveSongs);
		playButton.set_sensitive(haveSongs);
		nextButton.set_sensitive(haveSongs);
		searchField.set_sensitive(haveSongs);
		viewSelector.set_sensitive(haveSongs);
		
		mainViews.set_visible(haveSongs);
		miller.set_visible(haveSongs && viewSelector.selected == 2);
		songInfoScroll.set_visible(haveSongs);
		welcomeScreen.set_visible(!haveSongs);
		statusBar.set_visible(haveSongs);
		
		infoPanel.set_visible(haveSongs && showMore && !nullSong);
		infoPanelChooser.set_visible(haveSongs && !nullSong);
		
		/*if(lm.song_count() == 0) {
			fileImportMusic.set_sensitive(false);
			fileRescanMusicFolder.set_sensitive(false);
			topDisplay.set_scale_sensitivity(false);
			previousButton.set_sensitive(false);
			playButton.set_sensitive(false);
			nextButton.set_sensitive(false);
			searchField.set_sensitive(false);
			viewSelector.selected = 1;
			viewSelector.set_sensitive(false);
			statusBar.hide();
			
			//if(settings.getMusicFolder() != "") {
				mainViews.hide();
				miller.hide();
				songInfoScroll.hide();
				welcomeScreen.show();
			//}
		}
		else {
			if(lm.song_info.song != null)
				topDisplay.set_scale_sensitivity(true);
			
			previousButton.set_sensitive(true);
			playButton.set_sensitive(true);
			nextButton.set_sensitive(true);
			viewSelector.set_sensitive(true);
			searchField.set_sensitive(true);
			statusBar.show();
			welcomeScreen.hide();
			
			
			if(lm.doing_file_operations) {
				fileSetMusicFolder.set_sensitive(false);
				fileImportMusic.set_sensitive(false);
				fileRescanMusicFolder.set_sensitive(false);
			}
			else {
				fileSetMusicFolder.set_sensitive(true);
				fileImportMusic.set_sensitive(true);
				fileRescanMusicFolder.set_sensitive(true);
			}
		}*/
		
		if(lm.song_info.song == null || lm.song_count() == 0) {
			//topDisplay.set_visible(false);
			playButton.set_stock_id(Gtk.Stock.MEDIA_PLAY);
			//infoPanel.set_visible(false);
			//infoPanelChooser.set_visible(false);
		}
		/*else {
			topDisplay.set_visible(true);
			
			if(lm.settings.getMoreVisible())
				infoPanel.set_visible(true);
				
			infoPanelChooser.set_visible(true);
		}
		
		if(lm.doing_file_operations)
			topDisplay.set_visible(true);*/
	}
	
	public virtual void progressNotification(string? message, double progress) {
		//THIS IS WHAT CAUSES IT TO CRASH... WTF. SOMETHING WITH PANGO
		if(message != null)
			topDisplay.set_label_markup(message);
		
		topDisplay.set_progress_value(progress);
	}
	
	public bool updateCurrentSong() {
		//loop through all musictreeviews and call updatecurrentsong
		
		if(lm.song_info.song != null) {
			string file = lm.song_info.song.getAlbumArtPath();
			if(file.contains(settings.getMusicFolder())) {
				try {
					coverArt.set_from_pixbuf(new Gdk.Pixbuf.from_file_at_size(file, sourcesToSongs.position, sourcesToSongs.position));
				}
				catch(GLib.Error err) {
					stdout.printf("Could not set image art: %s\n", err.message);
					lm.song_info.song.setAlbumArtPath("");
				}
			}
			else {
				try {
					var dropAlbum = GLib.Path.build_filename("/usr", "share", "icons", "hicolor", "128x128", "mimetypes", "drop-album.svg");
					coverArt.set_from_pixbuf(new Gdk.Pixbuf.from_file_at_size(dropAlbum, sourcesToSongs.position, sourcesToSongs.position));
				}
				catch(GLib.Error err) {
					stdout.printf("Could not set image art: %s\n", err.message);
				}
			}
		}
		
		return false;
	}
	
	/** This should be used whenever a call to play a new song is made
	 * @param s The song that is now playing
	 */
	public virtual void song_played(int i, int old) {
		/*if(old == -2 && i != -2) { // -2 is id reserved for previews
			Song s = settings.getLastSongPlaying();
			s = lm.song_from_name(s.title, s.artist);
			
			if(s.rowid != 0) {
				lm.playSong(s.rowid);
				int position = (int)settings.getLastSongPosition();
				topDisplay.change_value(ScrollType.NONE, position);
			}
			
			return;
		}*/
		
		//set the title
		var song_label = "<b>" + lm.song_from_id(i).title.replace("&", "&amp;") + "</b>" + ((lm.song_from_id(i).artist != "") ? " by " : "") + "<b>" + lm.song_from_id(i).artist.replace("&", "&amp;") + "</b>" + ((lm.song_from_id(i).album != "") ? " on " : "") + "<b>" + lm.song_from_id(i).album.replace("&", "&amp;") + "</b>";
		topDisplay.set_label_markup(song_label);
		//this.set_title(lm.song_from_id(i).title + " by " + lm.song_from_id(i).artist + " on " + lm.song_from_id(i).album);
		
		//reset the song position
		topDisplay.set_scale_sensitivity(true);
		topDisplay.set_scale_range(0.0, lm.song_info.song.length);
		topDisplay.set_scale_value(0.0);
		
		//if(!songPosition.get_sensitive())
		//	songPosition.set_sensitive(true);
		
		//reset some booleans
		queriedlastfm = false;
		song_considered_played = false;
		added_to_play_count = false;
		scrobbled_track = false;
		
		
		//update the notifier
		/*if(!has_toplevel_focus) {
			try {
				notification.set_timeout(1);
				notification.update(lm.song_from_id(i).title, lm.song_from_id(i).artist + "\n" + lm.song_from_id(i).album, "");
				
				Gdk.Pixbuf notify_pix;
				if(File.new_for_path(lm.song_from_id(i).getAlbumArtPath()).query_exists())
					notify_pix = new Gdk.Pixbuf.from_file(lm.song_from_id(i).getAlbumArtPath());
				else
					notify_pix = render_icon("beatbox", IconSize.DIALOG, null);
				
				if(notify_pix != null)
					notification.set_image_from_pixbuf(notify_pix);
				else {
					/* create blank pixbuf so we don't show old album art */
					/*Gdk.Pixbuf blank = new Gdk.Pixbuf(Gdk.Colorspace.RGB, true, 8, 2, 2);
					blank.fill((uint) 0xffffff00);
					notification.set_image_from_pixbuf(blank);*
				}
				
				notification.show();
				notification.set_timeout(5000);
			}
			catch(GLib.Error err) {
				stderr.printf("Could not show notification: %s\n", err.message);
			}
		}*/
		
		 //FIXME: Could give errors for song previews, non-native files, etc.
		if(!GLib.File.new_for_path(lm.song_info.song.file).query_exists() && this.visible) {
			song_not_found();
		}
		
		if(!lm.song_info.song.isPreview) {
			updateCurrentSong();
			
			infoPanel.updateSong(lm.song_info.song.rowid);
			if(settings.getMoreVisible())
				infoPanel.set_visible(true);
			
			updateMillerColumns();
		}
		
		updateSensitivities();
		
		// if it is a video, show the video option and select it
		/*Gst.Discoverer disc = new Gst.Discoverer((Gst.ClockTime)(10*Gst.SECOND));
		if(disc.discover_uri("file://" + lm.song_info.song.file).get_video_streams().length() > 0) {
			if(!viewSelector.get_showing(3)) {
				viewSelector.set_showing(3, true);
				viewSelector.selected = 3;
			}
		}
		else {
			//stdout.printf("is not video, removing\n");
			viewSelector.set_showing(3, false);
			viewSelector.selected = settings.getViewMode();
		}*/
	}
	
	public virtual void playback_stopped(int was_playing) {
		//reset some booleans
		queriedlastfm = false;
		song_considered_played = false;
		added_to_play_count = false;
		
		// this will hide album cover art
		updateCurrentSong();
		
		updateSensitivities();
		
		stdout.printf("stopped\n");
	}
	
	public virtual void songs_updated(Collection<int> ids) {
		if(lm.song_info.song != null && ids.contains(lm.song_info.song.rowid)) {
			var song_label = "<b>" + lm.song_info.song.title.replace("&", "&amp;") + "</b>" + " by " + "<b>" + lm.song_info.song.artist.replace("&", "&amp;")  + "</b>" + " on " + "<b>" +lm.song_info.song.album.replace("&", "&amp;")  + "</b>";
			topDisplay.set_label_markup(song_label);
		}
	}
	
	public void* lastfm_track_thread_function () {
		LastFM.TrackInfo track = new LastFM.TrackInfo.basic();
		
		string artist_s = lm.song_info.song.artist;
		string track_s = lm.song_info.song.title;
		
		/* first fetch track info since that is most likely to change */
		if(!lm.track_info_exists(track_s + " by " + artist_s)) {
			track = new LastFM.TrackInfo.with_info(artist_s, track_s);
			
			if(track != null)
				lm.save_track(track);
			
			if(track_s == lm.song_info.song.title && artist_s == lm.song_info.song.artist)
				lm.song_info.track = track;
		}
		
		return null;
	}
	
	public void* lastfm_album_thread_function () {
		LastFM.AlbumInfo album = new LastFM.AlbumInfo.basic();
		
		string artist_s = lm.song_info.song.artist;
		string album_s = lm.song_info.song.album;
		
		/* fetch album info now. only save if still on current song */
		if(!lm.album_info_exists(album_s + " by " + artist_s)) {
			album = new LastFM.AlbumInfo.with_info(artist_s, album_s);
			
			if(album != null)
				lm.save_album(album);
			
			/* make sure we save image to right location (user hasn't changed songs) */
			if(lm.song_info.song != null && album != null && album_s == lm.song_info.song.album &&
			artist_s == lm.song_info.song.artist && lm.song_info.song.getAlbumArtPath().contains("media-audio.png")) {
				lm.song_info.album = album;
			
                if (album.url_image.url != null) {
					lm.save_album_locally(lm.song_info.song.rowid, album.url_image.url);
					
					// start thread to load all the songs pixbuf's
					try {
						Thread.create<void*>(lm.fetch_thread_function, false);
					}
					catch(GLib.ThreadError err) {
						stdout.printf("Could not create thread to load song pixbuf's: %s \n", err.message);
					}
				}
			}
			else {
				return null;
			}
		}
		
		Idle.add(updateCurrentSong);
		
		return null;
	}
	
	public void* lastfm_artist_thread_function () {
		LastFM.ArtistInfo artist = new LastFM.ArtistInfo.basic();
		
		string artist_s = lm.song_info.song.artist;
		
		/* fetch artist info now. save only if still on current song */
		if(!lm.artist_info_exists(artist_s)) {
			artist = new LastFM.ArtistInfo.with_artist(artist_s);
			
			if(artist != null)
				lm.save_artist(artist);
			
			//try to save artist art locally
			if(lm.song_info.song != null && artist != null && artist_s == lm.song_info.song.artist &&
			!File.new_for_path(lm.song_info.song.getArtistImagePath()).query_exists()) {
				lm.song_info.artist = artist;
				
				if (artist.url_image.url != null)
					lm.save_artist_image_locally(lm.song_info.song.rowid, artist.url_image.url);
			}
			else {
				return null;
			}
		}
		
		Idle.add( () => { infoPanel.updateArtistImage(true); return false;});
		
		return null;
	}
	
	public void* lastfm_update_nowplaying_thread_function() {
		if(lm.song_info.song != null) {
			lm.lfm.updateNowPlaying(lm.song_info.song.title, lm.song_info.song.artist);
		}
		
		return null;
	}
	
	public void* lastfm_scrobble_thread_function () {
		if(lm.song_info.song != null) {
			lm.lfm.scrobbleTrack(lm.song_info.song.title, lm.song_info.song.artist);
		}
		
		return null;
	}
    
    public bool updateSongInfo() {
		infoPanel.updateSong(lm.song_info.song.rowid);
		
		return false;
	}
	
	public virtual void previousClicked () {
		if(!queriedlastfm) {
			int prev_id = lm.getPrevious(true);
			
			/* test to stop playback/reached end */
			if(prev_id == 0) {
				lm.player.pause();
				lm.playing = false;
				updateSensitivities();
				return;
			}
		}
		else
			topDisplay.change_value(ScrollType.NONE, 0);
	}
	
	public virtual void playClicked () {
		if(lm.song_info.song == null) {
			//set current songs by current view
			Widget w = sideTree.getSelectedWidget();
			if(w is ViewWrapper) {
				((ViewWrapper)w).list.setAsCurrentList(1);
			}
			else {
				w = sideTree.getWidget(sideTree.convertToFilter(sideTree.library_music_iter));
				((ViewWrapper)w).list.setAsCurrentList(1);
			}
			
			lm.playing = true;
			playButton.set_stock_id(Gtk.Stock.MEDIA_PAUSE);
			lm.player.play();
			
			lm.getNext(true);
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
	}
	
	public virtual void nextClicked() {
		int next_id = lm.getNext(true);
		
		/* test to stop playback/reached end */
		if(next_id == 0) {
			lm.player.pause();
			lm.playing = false;
			updateSensitivities();
			return;
		}
		
		// if not 90% done, skip it
		if(!added_to_play_count) {
			lm.song_info.song.skip_count++;
		}
	}
	
	public virtual void loveButtonClicked() {
		lm.lfm.loveTrack(lm.song_info.song.title, lm.song_info.song.artist);
	}
	
	public virtual void banButtonClicked() {
		lm.lfm.banTrack(lm.song_info.song.title, lm.song_info.song.artist);
	}
	
	public virtual void searchFieldIconPressed(EntryIconPosition p0, Gdk.Event p1) {
		Widget w = sideTree.getSelectedWidget();
		w.focus(DirectionType.UP);
	}
	
	public virtual void millerResized(Allocation rectangle) {
		if(viewSelector.selected == 2) {
			settings.setMillerHeight(rectangle.height);
		}
	}
	
	public virtual void sourcesToSongsHandleSet(Allocation rectangle) {
		int height, width;
		get_size(out width, out height);
		
		if(rectangle.width > height/2) {
			sourcesToSongs.set_position(height/2);
			return;
		}
		
		if(settings.getSidebarWidth() != rectangle.width) {
			updateCurrentSong();
			settings.setSidebarWidth(rectangle.width);
		}
	}
	
	public virtual void on_resize() {
		int width;
		int height;
		this.get_size(out width, out height);
		settings.setWindowWidth(width);
		settings.setWindowHeight(height);
	}
	
	public virtual void on_quit() {
		//first: the user will never know that we don't actually close in the speed of light :p
		//this.hide();
		
		//second: stop music
		stdout.printf("Stopping playback\n");
		lm.player.pause();
		
		stdout.printf("Saving songs\n");
		//lm.save_songs();
		
		stdout.printf("Saving playlists\n");
		//lm.save_playlists();
		//lm.save_smart_playlists();
		
		stdout.printf("Saving LastFM Info\n");
		//lm.save_artists();
		//lm.save_albums();
		//lm.save_tracks();
	}
	
	public virtual void fileImportMusicClick() {
		if(!lm.doing_file_operations) {
			/*if(!(GLib.File.new_for_path(lm.settings.getMusicFolder()).query_exists() && lm.settings.getCopyImportedMusic())) {
				var dialog = new MessageDialog(this, DialogFlags.DESTROY_WITH_PARENT, MessageType.ERROR, ButtonsType.OK, 
				"Before importing, you must mount your music folder.");
				
				var result = dialog.run();
				dialog.destroy();
				
				return;
			}*/
			
			string folder = "";
            var file_chooser = new FileChooserDialog ("Choose Music Folder", this,
                                      FileChooserAction.SELECT_FOLDER,
                                      Gtk.Stock.CANCEL, ResponseType.CANCEL,
                                      Gtk.Stock.OPEN, ResponseType.ACCEPT);
			if (file_chooser.run () == ResponseType.ACCEPT) {
				folder = file_chooser.get_filename();
			}
			file_chooser.destroy ();
			
			if(folder != "" && folder != settings.getMusicFolder()) {
				if(GLib.File.new_for_path(lm.settings.getMusicFolder()).query_exists() && lm.settings.getCopyImportedMusic()) {
					topDisplay.set_label_markup("<b>Importing</b> music from <b>" + folder + "</b> to library.");
					topDisplay.show_progressbar();
					
					lm.add_folder_to_library(folder);
					updateSensitivities();
				}
			}
		}
		else {
			stdout.printf("Can't add to library.. already doing file operations\n");
		}
	}
	
	public virtual void fileRescanMusicFolderClick() {
		if(!lm.doing_file_operations) {
			if(GLib.File.new_for_path(this.settings.getMusicFolder()).query_exists()) {
				topDisplay.set_label_markup("<b>Rescanning music folder for changes</b>");
				topDisplay.show_progressbar();
				
				lm.rescan_music_folder();
				updateSensitivities();
			}
			else {
				doAlert("Could not find Music Folder", "Please make sure that your music folder is accessible and mounted.");
			}
		}
		else {
			stdout.printf("Can't rescan.. doing file operations already\n");
		}
	}
	
	public void resetSideTree() {
		sideTree.resetView();
		
		// clear all other playlists, reset to Music, populate music
		mainViews.get_children().foreach( (vw) => {
			stdout.printf("hi\n");
			if(vw is ViewWrapper)
				((ViewWrapper)vw).clear();
		});
		
		ViewWrapper vw = (ViewWrapper)sideTree.getWidget(sideTree.convertToFilter(sideTree.library_music_iter));
		vw.doUpdate(vw.currentView, lm.song_ids(), true, true);
		miller.populateColumns("", lm.song_ids());
	}
	
	public virtual void musicCounted(int count) {
		stdout.printf("found %d songs, importing.\n", count);
	}
	
	/* this is after setting the music library */
	public virtual void musicAdded(LinkedList<string> not_imported) {
		
		if(lm.song_info.song != null) {
			var song_label = "<b>" + lm.song_info.song.title + "</b>" + " by " + "<b>" + lm.song_info.song.artist + "</b>" + " on " + "<b>" +lm.song_info.song.album + "</b>";
			topDisplay.set_label_markup(song_label);
		}
		else
			topDisplay.set_label_text("");
		
		resetSideTree();
		
		if(not_imported.size > 0) {
			NotImportedWindow nim = new NotImportedWindow(this, not_imported, lm.settings.getMusicFolder());
			nim.show();
		}
		
		updateSensitivities();
		
		//now notify user
		/*try {
			notification.close();
			if(!has_toplevel_focus) {
				notification.update("Import Complete", "BeatBox has imported your library", "beatbox");
				
				Gdk.Pixbuf my_pix = render_icon("beatbox", IconSize.DIALOG, null);
				
				if(my_pix != null)
					notification.set_image_from_pixbuf(my_pix);
				
				notification.show();
				notification.set_timeout(5000);
			}
		}
		catch(GLib.Error err) {
			stderr.printf("Could not show notification: %s\n", err.message);
		}*/
	}
	
	/* this is when you import music from a foreign location into the library */
	public virtual void musicImported(LinkedList<Song> new_songs, LinkedList<string> not_imported) {
		topDisplay.show_scale();
		
		if(lm.song_info.song != null) {
			var song_label = "<b>" + lm.song_info.song.title + "</b>" + " by " + "<b>" + lm.song_info.song.artist + "</b>" + " on " + "<b>" +lm.song_info.song.album + "</b>";
			topDisplay.set_label_markup(song_label);
		}
		else
			topDisplay.set_label_text("");
		
		resetSideTree();
		
		updateSensitivities();
	}
	
	public virtual void musicRescanned(LinkedList<Song> new_songs, LinkedList<string> not_imported) {
		//sideTree.resetView();
		topDisplay.show_scale();
		
		if(lm.song_info.song != null) {
			var song_label = "<b>" + lm.song_info.song.title + "</b>" + " by " + "<b>" + lm.song_info.song.artist + "</b>" + " on " + "<b>" +lm.song_info.song.album + "</b>";
			topDisplay.set_label_markup(song_label);
		}
		else
			topDisplay.set_label_text("");
		
		resetSideTree();
		
		updateSensitivities();
	}
	
	public virtual void songs_removed(LinkedList<int> removed) {
		updateSensitivities();
	}
	
	public virtual void helpAboutClick() {
		AboutDialog ad = new AboutDialog();
		
		ad.set_program_name("BeatBox");
		ad.set_version("0.1");
		ad.set_website("https://launchpad.net/beat-box");
		ad.set_website_label("Launchpad");
		ad.set_icon( render_icon(Gtk.Stock.ABOUT, IconSize.DIALOG, null));
		ad.logo = render_icon("beatbox", IconSize.DIALOG, null);
		
		string[] authors = new string[1];
		authors[0] = "Scott Ringwelski";
		ad.set_authors(authors);
		
		ad.response.connect( (response_id) => { 
			ad.destroy(); 
		});
		
		ad.show();
	}
	
	public void editEqualizerClick() {
		EqualizerWindow ew = new EqualizerWindow(lm, this);
		
	}
	
	public void editPreferencesClick() {
		PreferencesWindow pw = new PreferencesWindow(lm, this);
		
		pw.changed.connect( (folder) => {
			setMusicFolder(folder);
		});
	}
	
	public void setMusicFolder(string folder) {
		stdout.printf("SETTING MUSIC FOLDER TO %s\n", folder);
		topDisplay.set_label_markup("<b>Importing</b> music from <b>" + folder + "</b>");
		topDisplay.show_progressbar();
		lm.set_music_folder(folder);
		updateSensitivities();
	}
	
	public virtual void end_of_stream() {
		nextClicked();
	}
	
	public virtual void current_position_update(int64 position) {
		if(lm.song_info.song != null && lm.song_info.song.rowid == -2) // is preview
			return;
		
		double sec = 0.0;
		if(lm.song_info.song != null) {
			sec = ((double)position/1000000000);
			
			lm.settings.setLastSongPosition((int)sec);
			
			// at about 5 seconds, update last fm. we wait to avoid excessive querying last.fm for info
			if(position > 5000000000 && !queriedlastfm) {
				queriedlastfm = true;
				
				similarSongs.queryForSimilar(lm.song_info.song);
				
				try {
					Thread.create<void*>(lastfm_track_thread_function, false);
					Thread.create<void*>(lastfm_album_thread_function, false);
					Thread.create<void*>(lastfm_artist_thread_function, false);
					Thread.create<void*>(lastfm_update_nowplaying_thread_function, false);
				}
				catch(GLib.ThreadError err) {
					stdout.printf("ERROR: Could not create last fm thread: %s \n", err.message);
				}
			}
			
			//at 30 seconds in, we consider the song as played
			if(position > 30000000000 && !song_considered_played) {
				song_considered_played = true;
				
				lm.song_info.song.last_played = (int)time_t();
				lm.update_song(lm.song_info.song, false);
				
				// add to the already played list
				lm.add_already_played(lm.song_info.song.rowid);
				sideTree.updateAlreadyPlayed();
				
#if HAVE_ZEITGEIST
				var event = new Zeitgeist.Event.full(Zeitgeist.ZG_ACCESS_EVENT,
					Zeitgeist.ZG_SCHEDULED_ACTIVITY, "app://beatbox.desktop",
					new Zeitgeist.Subject.full(
					GLib.File.new_for_path(lm.song_info.song.file).get_uri(),
					Zeitgeist.NFO_AUDIO, Zeitgeist.NFO_FILE_DATA_OBJECT,
					"text/plain", "", lm.song_info.song.title, ""));
				new Zeitgeist.Log ().insert_events_no_reply(event);
#endif
			}
			
			// at halfway, scrobble
			if((double)(sec/(double)lm.song_info.song.length) > 0.50 && !scrobbled_track) {
				scrobbled_track = true;
				try {
					Thread.create<void*>(lastfm_scrobble_thread_function, false);
				}
				catch(GLib.ThreadError err) {
					stdout.printf("ERROR: Could not create last fm thread: %s \n", err.message);
				}
			}
			
			// at 90% done with song, add 1 to play count
			if((double)(sec/(double)lm.song_info.song.length) > 0.90 && !added_to_play_count) {
				added_to_play_count = true;
				lm.song_info.song.play_count++;
				lm.update_song(lm.song_info.song, false);
			}
			
		}
		else {
			
		}
	}
	
	public void song_not_found() {
		var not_found = new FileNotFoundDialog(lm, this, lm.song_info.song.rowid);
	}
	
	public virtual void similarRetrieved(LinkedList<int> similarIDs, LinkedList<Song> similarDont) {
		Widget w = sideTree.getWidget(sideTree.convertToFilter(sideTree.playlists_similar_iter));
		
		((ViewWrapper)w).similarsFetched = true;
		((ViewWrapper)w).doUpdate(((ViewWrapper)w).currentView, similarIDs, true, true);
		
		infoPanel.updateSongList(similarDont);
		
		if(((ViewWrapper)w).isCurrentView) {
			miller.populateColumns("", ((ViewWrapper)w).list.get_songs());
			updateMillerColumns();
		}
	}
	
	public void setStatusBarText(string text) {
		statusBarLabel.set_text(text);
	}
	
	public void welcomeScreenActivated(int index) {
		if(!lm.doing_file_operations && index == 0) {
			string folder = "";
            var file_chooser = new FileChooserDialog ("Choose Music Folder", this,
                                      FileChooserAction.SELECT_FOLDER,
                                      Gtk.Stock.CANCEL, ResponseType.CANCEL,
                                      Gtk.Stock.OPEN, ResponseType.ACCEPT);
			if (file_chooser.run () == ResponseType.ACCEPT) {
				folder = file_chooser.get_filename();
			}
			file_chooser.destroy ();
			
			if(folder != "" && (folder != settings.getMusicFolder() || lm.song_count() == 0)) {
				setMusicFolder(folder);
			}
		}
	}
	
	public virtual void infoPanelResized(Allocation rectangle) {
		int height, width;
		get_size(out width, out height);
		
		if(sourcesToSongs.get_position() > height/2)
			return;
		
		//songsToInfo.max_position = (lm.settings.getWindowWidth() - lm.settings.getSidebarWidth()) - 300;
		//songsToInfo.min_position = (lm.settings.getWindowWidth() - lm.settings.getSidebarWidth()) - 150;
		
		if(songsToInfo.get_position() < (lm.settings.getWindowWidth() - lm.settings.getSidebarWidth()) - 300) { // this is max size
			songsToInfo.set_position((lm.settings.getWindowWidth() - lm.settings.getSidebarWidth()) - 300);
			return;
		}
		else if(songsToInfo.get_position() > (lm.settings.getWindowWidth() - lm.settings.getSidebarWidth()) - 150) { // this is min size
			songsToInfo.set_position((lm.settings.getWindowWidth() - lm.settings.getSidebarWidth()) - 150);
			return;
		}
		
		if(lm.settings.getMoreWidth() != rectangle.width) {
			lm.settings.setMoreWidth(rectangle.width);
		}
	}
	
	public virtual void repeatChooserOptionChanged(int val) {
		lm.settings.setRepeatMode(val);
		
		if(val == 0)
			lm.repeat = LibraryManager.Repeat.OFF;
		else if(val == 1)
			lm.repeat = LibraryManager.Repeat.SONG;
		else if(val == 2)
			lm.repeat = LibraryManager.Repeat.ALBUM;
		else if(val == 3)
			lm.repeat = LibraryManager.Repeat.ARTIST;
		else if(val == 4)
			lm.repeat = LibraryManager.Repeat.ALL;
	}
	
	public virtual void shuffleChooserOptionChanged(int val) {
		if(val == 0)
			lm.setShuffleMode(LibraryManager.Shuffle.OFF);
		else if(val == 1)
			lm.setShuffleMode(LibraryManager.Shuffle.ALL);
	}
	
	public virtual void infoPanelChooserOptionChanged(int val) {
		infoPanel.set_visible(val == 1);
		lm.settings.setMoreVisible(val == 1);
	}
	
	public void updateMillerColumns() {
		if(viewSelector.selected != 3)
			settings.setViewMode(viewSelector.selected);
			
		bool similarcheck = sideTree.getSelectedWidget() is ViewWrapper && 
							((ViewWrapper)sideTree.getSelectedWidget()).list is SimilarPane && 
							!((ViewWrapper)sideTree.getSelectedWidget()).similarsFetched;
		bool storecheck = (sideTree.getSelectedWidget() is Store.StoreView);
		
		miller.set_visible(viewSelector.selected == 2 && !similarcheck && !storecheck);
		millerVisible = (viewSelector.selected == 0); // used for when an album is clicked from icon view
	}
	
	public void searchFieldActivate() {
		Widget w = sideTree.getSelectedWidget();
		
		if(w is ViewWrapper) {
			ViewWrapper vw = (ViewWrapper)w;
			
			vw.list.setAsCurrentList(1);
			lm.current_index = 0;
			lm.playSong(lm.songFromCurrentIndex(0));
			
			if(!lm.playing)
				playClicked();
		}
	}
	
	public virtual void dragReceived(Gdk.DragContext context, int x, int y, Gtk.SelectionData data, uint info, uint timestamp) {
		if(dragging_from_music)
			return;
		
		var files_dragged = new LinkedList<string>();
		stdout.printf("dragged\n");
		foreach (string uri in data.get_uris ()) {
			files_dragged.add(uri);
		}
		
		lm.add_files_to_library(files_dragged);
	}
	
	public void doAlert(string title, string message) {
		var dialog = new MessageDialog(this, DialogFlags.MODAL, MessageType.ERROR, ButtonsType.OK, 
				title);
		
		dialog.title = "BeatBox";
		dialog.secondary_text = message;
		dialog.secondary_use_markup = true;
				
		dialog.run();
		dialog.destroy();
	}
}
