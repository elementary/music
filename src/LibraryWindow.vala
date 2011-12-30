/*-
 * Copyright (c) 2011       Scott Ringwelski <sgringwe@mtu.edu>
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

public class BeatBox.LibraryWindow : Gtk.Window {
	public static Granite.Application app { get; private set; }
	
	public BeatBox.LibraryManager lm;
	BeatBox.Settings settings;
	LastFM.SimilarSongs similarSongs;
	BeatBox.MediaKeyListener mkl;
	
	bool queriedlastfm; // whether or not we have queried last fm for the current song info
	bool song_considered_played; //whether or not we have updated last played and added to already played list
	bool added_to_play_count; // whether or not we have added one to play count on playing song
	bool tested_for_video; // whether or not we have tested if song is video and shown video
	bool scrobbled_track;
	LinkedList<string> timeout_search;//stops from doing useless search
	string last_search;//stops from searching same thing multiple times
	
	public bool dragging_from_music;
	public bool millerVisible;
	bool askToSetFolder;
	
	public bool initializationFinished;
	
	VBox verticalBox;
	public VBox mainViews;
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
	public ElementaryWidgets.TopDisplay topDisplay;
	public Granite.Widgets.ModeButton viewSelector;
	public Granite.Widgets.SearchBar searchField;
	HBox statusBar;
	Label statusBarLabel;
	SimpleOptionChooser shuffleChooser;
	SimpleOptionChooser repeatChooser;
	SimpleOptionChooser infoPanelChooser;
	
	// basic file stuff
	ImageMenuItem libraryOperations;
	Menu libraryOperationsMenu;
	MenuItem fileSetMusicFolder;
	MenuItem fileImportMusic;
	MenuItem fileRescanMusicFolder;
	MenuItem editEqualizer;
	ImageMenuItem editPreferences;
	
	Menu settingsMenu;
	
	public Notify.Notification notification;
	
	public signal void playPauseChanged();
	
	public LibraryWindow(Granite.Application app, string[] args) {
		this.app = app;
		settings = new BeatBox.Settings();
		
		//this is used by many objects, is the media backend
		lm = new BeatBox.LibraryManager(settings, this, args);
		
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
		
		this.lm.player.end_of_stream.connect(end_of_stream);
		this.lm.player.current_position_update.connect(current_position_update);
		//this.lm.player.song_not_found.connect(song_not_found);
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
		
		if(lm.song_count() == 0 && settings.getMusicFolder() == "") {
			stdout.printf("First run.\n");
			
		}
		else {
			lm.clearCurrent();
			//((MusicTreeView)sideTree.getWidget(sideTree.library_music_iter)).set_as_current_list("0");
			
			// make sure we don't re-count stats
			if((int)settings.getLastSongPosition() > 5)
				queriedlastfm = true;
			if((int)settings.getLastSongPosition() > 30)
				song_considered_played = true;
			if(lm.song_info.song != null && (double)((int)settings.getLastSongPosition()/(double)lm.song_info.song.length) > 0.90)
				added_to_play_count = true;
			
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
		resize(settings.getWindowWidth(), settings.getWindowHeight());
		
		// set window min/max
		Gdk.Geometry geo = Gdk.Geometry();
		geo.min_width = 700;
		geo.min_height = 400;
		set_geometry_hints(this, geo, Gdk.WindowHints.MIN_SIZE);
		
		// set the title
		set_title("BeatBox");
		
		// set the icon
		set_icon(lm.icons.beatbox_icon.render (IconSize.MENU, null));
		
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
		libraryOperations = new ImageMenuItem.from_stock("library-music", null);
		libraryOperationsMenu = new Menu();
		fileSetMusicFolder = new MenuItem.with_label("Set Music Folder");
		fileImportMusic = new MenuItem.with_label("Import to Library");
		fileRescanMusicFolder = new MenuItem.with_label("Rescan Music Folder");
		editEqualizer = new MenuItem.with_label("Equalizer");
		editPreferences = new ImageMenuItem.from_stock(Gtk.Stock.PREFERENCES, null);
		settingsMenu = new Menu();
		topControls = new Toolbar();
		previousButton = new ToolButton.from_stock(Gtk.Stock.MEDIA_PREVIOUS);
		playButton = new ToolButton.from_stock(Gtk.Stock.MEDIA_PLAY);
		nextButton = new ToolButton.from_stock(Gtk.Stock.MEDIA_NEXT);
		topDisplay = new ElementaryWidgets.TopDisplay(lm);
		viewSelector = new Granite.Widgets.ModeButton();
		searchField = new Granite.Widgets.SearchBar("Search...");
		miller = new MillerColumns(lm, this); //miller must be below search for it to work properly
		songInfoScroll = new ScrolledWindow(null, null);
		pandoraScroll = new ScrolledWindow(null, null);
		grooveSharkScroll = new ScrolledWindow(null, null);
		infoPanel = new InfoPanel(lm, this);
		sideBar = new VBox(false, 0);
		statusBar = new HBox(false, 0);
		statusBarLabel = new Label("");
		
		var statusBarStyle = statusBar.get_style_context ();

		var shuffle_on_icon = lm.icons.shuffle_on_icon.render (IconSize.MENU, statusBarStyle);
		var shuffle_off_icon = lm.icons.shuffle_off_icon.render (IconSize.MENU, statusBarStyle);
		var repeat_on_icon = lm.icons.repeat_on_icon.render (IconSize.MENU, statusBarStyle);
		var repeat_off_icon = lm.icons.repeat_off_icon.render (IconSize.MENU, statusBarStyle);

		shuffleChooser = new SimpleOptionChooser(shuffle_on_icon, shuffle_off_icon);
		repeatChooser = new SimpleOptionChooser(repeat_on_icon, repeat_off_icon);
		infoPanelChooser = new SimpleOptionChooser(lm.icons.info_icon.render(IconSize.MENU, null), lm.icons.info_icon.render(IconSize.MENU, null));
		
		notification = (Notify.Notification)GLib.Object.new (
						typeof (Notify.Notification),
						"summary", "Title",
						"body", "Artist\nAlbum");
		
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
		settingsMenu.append(editEqualizer);
		settingsMenu.append(editPreferences);
		
		fileSetMusicFolder.activate.connect(editPreferencesClick);
		fileImportMusic.activate.connect(fileImportMusicClick);
		fileRescanMusicFolder.activate.connect(fileRescanMusicFolderClick);
		
		editPreferences.set_label("Preferences");
		
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
		verticalBox.pack_start(topControls, false, true, 0);
		verticalBox.pack_start(videoArea, true, true, 0);
		verticalBox.pack_start(sourcesToSongs, true, true, 0);
		
		ToolItem topDisplayBin = new ToolItem();
		ToolItem viewSelectorBin = new ToolItem();
		ToolItem searchFieldBin = new ToolItem();
		topDisplayBin.add(topDisplay);
		topDisplayBin.set_border_width(1);
		viewSelectorBin.add(viewSelector);
		viewSelectorBin.set_border_width(3);
		searchFieldBin.add(searchField);
		
		topDisplayBin.set_expand(true);
		
		var viewSelectorStyle = viewSelector.get_style_context ();
		
		var view_column_icon = lm.icons.view_column_icon.render (IconSize.MENU, viewSelectorStyle);
		var view_details_icon = lm.icons.view_details_icon.render (IconSize.MENU, viewSelectorStyle);
		var view_icons_icon = lm.icons.view_icons_icon.render (IconSize.MENU, viewSelectorStyle);
		var view_video_icon = lm.icons.view_video_icon.render (IconSize.MENU, viewSelectorStyle);

		viewSelector.append(new Image.from_pixbuf(view_icons_icon));
		viewSelector.append(new Image.from_pixbuf(view_details_icon));
		viewSelector.append(new Image.from_pixbuf(view_column_icon));
		//viewSelector.append(new Image.from_pixbuf(view_video_icon));
		
		topControls.insert(previousButton, 0);
		topControls.insert(playButton, 1);
		topControls.insert(nextButton, 2);
		topControls.insert(viewSelectorBin, 3);
		topControls.insert(topDisplayBin, 4);
		topControls.insert(searchFieldBin, 5);
		topControls.insert(app.create_appmenu(settingsMenu), 6);
		
		// for consistency
		topControls.set_size_request(-1, 45);
		//viewSelector.set_size_request(-1, 20);
		
		viewSelector.get_style_context().add_class("raised");
		topControls.get_style_context().add_class("primary-toolbar");
		
		//set the name for elementary theming
		//sourcesToSongs.name = "SidebarHandleLeft";
		//sideTree.name = "SidebarContent";
		sourcesToSongs.get_style_context().add_class("sidebar-pane-separator");
		sideTree.get_style_context().add_class("sidebar");
		
		contentBox.pack_start(welcomeScreen, true, true, 0);
		welcomeScreen.append("library-music", "Set Music Folder", "Select your music folder and build your library.");
		
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
		
		// add mounts to side tree view
		lm.dm.loadPreExistingMounts();
		
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
		viewSelector.mode_changed.connect(updateMillerColumns);
		viewSelector.mode_changed.connect( () => { updateSensitivities(); } );
		millerPane.get_child1().size_allocate.connect(millerResized);
		searchField.activate.connect(searchFieldActivate);
		
		/* set up drag dest stuff */
		drag_dest_set(this, DestDefaults.ALL, {}, Gdk.DragAction.MOVE);
		Gtk.drag_dest_add_uri_targets(this);
		drag_data_received.connect(dragReceived);
		
		show_all();
		
		// nowthat everything is added, resize to proper height
		resize(settings.getWindowWidth(), this.default_height);
		viewSelector.selected = settings.getViewMode();
		
		sideTree.resetView();
		
		bool genreV, artistV, albumV;
		lm.settings.getMillerVisibilities(out genreV, out artistV, out albumV);
		miller.updateColumnVisibilities(genreV, artistV, albumV);
		stdout.printf("User interface has been built\n");
		
		int i = settings.getLastSongPlaying();
		if(i != 0) {
			/* time out works because... monkeys eat bananas */
			int position = (int)settings.getLastSongPosition();
			//Timeout.add(250, () => {
				lm.playSong(i);
				
				((ViewWrapper)sideTree.getWidget(sideTree.library_music_iter)).list.set_as_current_list(0, true);
				if(settings.getShuffleMode() == LibraryManager.Shuffle.ALL) {
					lm.setShuffleMode(LibraryManager.Shuffle.ALL, true);
				}
				
				searchField.set_text(lm.settings.getSearchString());
				
				topDisplay.change_value(ScrollType.NONE, position);
					
				//return false;
			//});
		}
		else {
			/* don't show info panel if nothing playing */
			infoPanel.set_visible(false);
		}
		
		initializationFinished = true;
		updateSensitivities();
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
		
		vw = new ViewWrapper(lm, this, new LinkedList<int>(), lm.similar_setup.sort_column, lm.similar_setup.sort_direction, ViewWrapper.Hint.SIMILAR, -1);
		sideTree.addSideItem(sideTree.playlists_iter, null, vw, "Similar");
		mainViews.pack_start(vw, true, true, 0);
		
		vw = new ViewWrapper(lm, this, lm.queue(), lm.queue_setup.sort_column, lm.queue_setup.sort_direction, ViewWrapper.Hint.QUEUE, -1);
		sideTree.addSideItem(sideTree.playlists_iter, null, vw, "Queue");
		mainViews.pack_start(vw, true, true, 0);
		
		vw = new ViewWrapper(lm, this, lm.already_played(), lm.history_setup.sort_column, lm.history_setup.sort_direction, ViewWrapper.Hint.HISTORY, -1);
		sideTree.addSideItem(sideTree.playlists_iter, null, vw, "History");
		mainViews.pack_start(vw, true, true, 0);
		
		vw = new ViewWrapper(lm, this, lm.song_ids(), lm.music_setup.sort_column, lm.music_setup.sort_direction, ViewWrapper.Hint.MUSIC, -1);
		sideTree.addSideItem(sideTree.library_iter, null, vw, "Music");
		mainViews.pack_start(vw, true, true, 0);
		
		vw = new ViewWrapper(lm, this, lm.podcast_ids(), lm.podcast_setup.sort_column, lm.podcast_setup.sort_direction, ViewWrapper.Hint.PODCAST, -1);
		sideTree.addSideItem(sideTree.library_iter, null, vw, "Podcasts");
		mainViews.pack_start(vw, true, true, 0);
		
		vw = new ViewWrapper(lm, this, lm.station_ids(), lm.station_setup.sort_column, lm.station_setup.sort_direction, ViewWrapper.Hint.STATION, -1);
		sideTree.addSideItem(sideTree.network_iter, null, vw, "Radio Stations");
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
			
			vw = new ViewWrapper(lm, this, lm.songs_from_playlist(p.rowid), p.tvs.sort_column, p.tvs.sort_direction, ViewWrapper.Hint.PLAYLIST, p.rowid);
			item = sideTree.addSideItem(sideTree.playlists_iter, p, vw, p.name);
			mainViews.pack_start(vw, true, true, 0);
		}
		else if(o is SmartPlaylist) {
			SmartPlaylist p = (SmartPlaylist)o;
			
			vw = new ViewWrapper(lm, this, lm.songs_from_smart_playlist(p.rowid), p.tvs.sort_column, p.tvs.sort_direction, ViewWrapper.Hint.SMART_PLAYLIST, p.rowid);
			item = sideTree.addSideItem(sideTree.playlists_iter, p, vw, p.name);
			mainViews.pack_start(vw, true, true, 0);
		}
		else if(o is Device) {
			Device d = (Device)o;
			
			if(d.getContentType() == "cdrom") {
				vw = new CDRomViewWrapper(lm, this, new Gee.LinkedList<int>(), "Track", Gtk.SortType.ASCENDING, ViewWrapper.Hint.CDROM, -1, d);
				item = sideTree.addSideItem(sideTree.devices_iter, d, vw, d.getDisplayName());
				mainViews.pack_start(vw, true, true, 0);
			}
			else {
				stdout.printf("adding ipod device view with %d\n", d.get_songs().size);
				DeviceView dv = new DeviceView(lm, d);
				//vw = new DeviceViewWrapper(lm, this, d.get_songs(), "Artist", Gtk.SortType.ASCENDING, ViewWrapper.Hint.DEVICE, -1, d);
				item = sideTree.addSideItem(sideTree.devices_iter, d, dv, d.getDisplayName());
				mainViews.pack_start(dv, true, true, 0);
			}
		}
		
		if(vw == null || vw.list == null || vw.albumView == null)
			return;
		
		vw.show_all();
		if(viewSelector.selected == 0) {
			vw.albumView.show();
			vw.list.hide();
		}
		else {
			vw.list.show();
			vw.albumView.hide();
		}
	}
	
	public void updateSensitivities() {
		if(!initializationFinished)
			return;
		
		bool folderSet = (lm.settings.getMusicFolder() != "");
		bool haveSongs = lm.song_count() > 0;
		bool doingOps = lm.doing_file_operations;
		bool nullSong = (lm.song_info.song == null);
		bool showMore = lm.settings.getMoreVisible();
		
		bool showingSongList = (sideTree.getSelectedWidget() is ViewWrapper);
		
		fileSetMusicFolder.set_sensitive(!doingOps);
		fileImportMusic.set_sensitive(!doingOps && folderSet);
		fileRescanMusicFolder.set_sensitive(!doingOps && folderSet);
		
		if(doingOps)
			topDisplay.show_progressbar();
		else if(!nullSong && lm.song_info.song.mediatype == 3) {
			topDisplay.hide_scale_and_progressbar();
		}
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
		miller.set_visible(haveSongs && viewSelector.selected == 2 && showingSongList);
		welcomeScreen.set_visible(!haveSongs);
		welcomeScreen.set_sensitivity(0, !doingOps);
		statusBar.set_visible(haveSongs);
		
		infoPanel.set_visible(haveSongs && showMore && !nullSong);
		infoPanelChooser.set_visible(haveSongs && !nullSong);
		coverArt.set_visible(!nullSong);
		
		// hide playlists when song list is empty
		sideTree.setVisibility(sideTree.playlists_iter, haveSongs);
		
		if(lm.song_info.song == null || haveSongs && !lm.playing) {
			playButton.set_stock_id(Gtk.Stock.MEDIA_PLAY);
		}
	}
	
	public virtual void progressNotification(string? message, double progress) {
		if(message != null && progress >= 0.0 && progress <= 1.0)
			topDisplay.set_label_markup(message);
		
		topDisplay.set_progress_value(progress);
		
		// if we are adding songs, refresh periodically
		ViewWrapper vw = (ViewWrapper)sideTree.getWidget(sideTree.library_music_iter);
		if(lm.songs().size - vw.song_count >= 500) {
			
			vw.doUpdate(vw.currentView, lm.song_ids(), true, true);
			miller.populateColumns("", lm.song_ids());
			
			updateSensitivities();
		}
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
					var dropAlbum = GLib.Path.build_filename("/", Build.ICON_FOLDER, "hicolor", "128x128", "mimetypes", "drop-album.svg");
					coverArt.set_from_pixbuf(new Gdk.Pixbuf.from_file_at_size(dropAlbum, sourcesToSongs.position, sourcesToSongs.position));
				}
				catch(GLib.Error err) {
					stdout.printf("Could not set image art: %s\n", err.message);
				}
			}
		}
		
		return false;
	}
	
	public void updateInfoLabel() {
		if(lm.doing_file_operations) {
			stdout.printf("doing file operations, returning null in updateInfoLabel\n");
			return;
		}
			
		if(lm.song_info.song == null) {
			topDisplay.set_label_markup("");
			stdout.printf("setting info label as ''\n");
			return;
		}
		
		string beg = "";
		if(lm.song_info.song.mediatype == 3) // radio
			beg = "<b>" + lm.song_info.song.album_artist.replace("\n", "") + "</b>\n";
		
		//set the title
		Song s = lm.song_info.song;
		var title = "<b>" + s.title.replace("&", "&amp;") + "</b>";
		var artist = ((s.artist != "" && s.artist != "Unknown Artist") ? (" by " + "<b>" + s.artist.replace("&", "&amp;") + "</b>") : "");
		var album = ((s.album != "" && s.album != "Unknown Album") ? (" on " + "<b>" + s.album.replace("&", "&amp;") + "</b>") : "");
		
		var song_label = beg + title + artist + album;
		topDisplay.set_label_markup(song_label);
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
		
		updateInfoLabel();
		
		//reset the song position
		topDisplay.set_scale_sensitivity(true);
		topDisplay.set_scale_range(0.0, lm.song_info.song.length);
		
		if(lm.song_from_id(i).mediatype == 1 || lm.song_from_id(i).mediatype == 2) {
			stdout.printf("setting position to resume_pos which is %d\n", lm.song_from_id(i).resume_pos );
			Timeout.add(250, () => {
				topDisplay.change_value(ScrollType.NONE, lm.song_from_id(i).resume_pos);
				return false;
			});
		}
		else {
			topDisplay.change_value(ScrollType.NONE, 0);
		}
		
		//if(!songPosition.get_sensitive())
		//	songPosition.set_sensitive(true);
		
		//reset some booleans
		tested_for_video = false;
		queriedlastfm = false;
		song_considered_played = false;
		added_to_play_count = false;
		scrobbled_track = false;
		
		if(!lm.song_info.song.isPreview) {
			updateCurrentSong();
			
			infoPanel.updateSong(lm.song_info.song.rowid);
			if(settings.getMoreVisible())
				infoPanel.set_visible(true);
			
			updateMillerColumns();
		}
		
		updateSensitivities();
		
		// if radio, we can't depend on current_position_update. do that stuff now.
		if(lm.song_info.song.mediatype == 3) {
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
			
			// always show notifications for the radio, since user likely does not know song
			mkl.showNotification(lm.song_info.song.rowid);
		}
	}
	
	public virtual void playback_stopped(int was_playing) {
		//reset some booleans
		tested_for_video = false;
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
			updateInfoLabel();
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
		if(!lm.album_info_exists(album_s + " by " + artist_s) || lm.get_album_art(lm.song_info.song.rowid) == null) {
			album = new LastFM.AlbumInfo.with_info(artist_s, album_s);
			
			if(album != null)
				lm.save_album(album);
			
			/* make sure we save image to right location (user hasn't changed songs) */
			if(lm.song_info.song != null && album != null && album_s == lm.song_info.song.album &&
			artist_s == lm.song_info.song.artist && lm.song_info.song.getAlbumArtPath().contains("media-audio.png")) {
				lm.song_info.album = album;
			
				if (album.url_image.url != null && lm.settings.getUpdateFolderHierarchy()) {
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
		if(lm.player.getPosition() < 5000000000) {
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
			stdout.printf("No song is currently playing. Starting from the top\n");
			//set current songs by current view
			Widget w = sideTree.getSelectedWidget();
			if(w is ViewWrapper) {
				((ViewWrapper)w).list.set_as_current_list(1, true);
			}
			else {
				w = sideTree.getWidget(sideTree.library_music_iter);
				((ViewWrapper)w).list.set_as_current_list(1, true);
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
		
		playPauseChanged();
	}
	
	public virtual void nextClicked() {
		// if not 90% done, skip it
		if(!added_to_play_count) {
			lm.song_info.song.skip_count++;
			lm.update_song(lm.song_info.song, false, false);
		}
		
		int next_id;
		if(lm.next_gapless_id != 0) {
			next_id = lm.next_gapless_id;
			lm.playSong(lm.next_gapless_id);
		}
		else
			next_id = lm.getNext(true);
		
		/* test to stop playback/reached end */
		if(next_id == 0) {
			lm.player.pause();
			lm.playing = false;
			updateSensitivities();
			return;
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
		stdout.printf("Stopping playback\n");
		lm.settings.setLastSongPosition((int)((double)lm.player.getPosition()/1000000000));
		lm.player.pause();
		
		stdout.printf("TODO: Clean up play queue\n");
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
				if(GLib.File.new_for_path(lm.settings.getMusicFolder()).query_exists()) {
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
	
	public void resetSideTree(/*bool clear_views*/) {
		sideTree.resetView();
		
		// clear all other playlists, reset to Music, populate music
		/*if(clear_views) {
			mainViews.get_children().foreach( (w) => {
				if(w is ViewWrapper && !(w is CDRomViewWrapper) && !(w is DeviceViewWrapper)) {
					ViewWrapper vw = (ViewWrapper)w;
					vw.doUpdate(vw.currentView, new LinkedList<int>(), true, true);
				}
			});
		}
		searchField.changed();*/
		
		ViewWrapper vw = (ViewWrapper)sideTree.getWidget(sideTree.library_music_iter);
		vw.doUpdate(vw.currentView, lm.song_ids(), true, true);
		miller.populateColumns("", lm.song_ids());
		
		vw = (ViewWrapper)sideTree.getWidget(sideTree.library_podcasts_iter);
		vw.doUpdate(vw.currentView, lm.podcast_ids(), true, true);
	}
	
	public virtual void musicCounted(int count) {
		stdout.printf("found %d songs, importing.\n", count);
	}
	
	/* this is after setting the music library */
	public virtual void musicAdded(LinkedList<string> not_imported) {
		
		if(lm.song_info.song != null) {
			updateInfoLabel();
		}
		else
			topDisplay.set_label_text("");
		
		resetSideTree();
		//var init = searchField.get_text();
		//searchField.set_text("up");
		
		if(not_imported.size > 0) {
			NotImportedWindow nim = new NotImportedWindow(this, not_imported, lm.settings.getMusicFolder());
			nim.show();
		}
		
		updateSensitivities();
		
		//now notify user
		try {
			notification.close();
			if(!has_toplevel_focus) {
				notification.update("Import Complete", "BeatBox has imported your library", "beatbox");
				
				var beatbox_icon = lm.icons.beatbox_icon.render (IconSize.DIALOG, null);
				notification.set_image_from_pixbuf(beatbox_icon);
				
				notification.show();
				notification.set_timeout(5000);
			}
		}
		catch(GLib.Error err) {
			stderr.printf("Could not show notification: %s\n", err.message);
		}
	}
	
	/* this is when you import music from a foreign location into the library */
	public virtual void musicImported(LinkedList<Song> new_songs, LinkedList<string> not_imported) {
		if(lm.song_info.song != null) {
			updateInfoLabel();	
		}
		else
			topDisplay.set_label_text("");
		
		resetSideTree();
		//searchField.changed();
		
		updateSensitivities();
	}
	
	public virtual void musicRescanned(LinkedList<Song> new_songs, LinkedList<string> not_imported) {
		if(lm.song_info.song != null) {
			updateInfoLabel();
		}
		else
			topDisplay.set_label_text("");
		
		resetSideTree();
		//searchField.changed();
		stdout.printf("music Rescanned\n");
		updateSensitivities();
	}
	
	public virtual void songs_removed(LinkedList<int> removed) {
		updateSensitivities();
	}
	
	public void editEqualizerClick() {
		EqualizerWindow ew = new EqualizerWindow(lm, this);
		ew.show();
	}
	
	public void editPreferencesClick() {
		PreferencesWindow pw = new PreferencesWindow(lm, this);
		
		pw.changed.connect( (folder) => {
			setMusicFolder(folder);
		});
	}
	
	public void setMusicFolder(string folder) {
		if(lm.doing_file_operations)
			return;
		
		if(lm.song_count() > 0 || lm.playlist_count() > 0) {
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
		if(lm.song_info.song != null && lm.song_info.song.rowid == -2) // is preview
			return;
		
		double sec = 0.0;
		if(lm.song_info.song != null) {
			sec = ((double)position/1000000000);
			
			// if podcast or audiobook, and song is considered played, remember position
			if(lm.song_info.song.mediatype == 1 || lm.song_info.song.mediatype == 2 && song_considered_played)
				lm.song_info.song.resume_pos = (int)sec;
			
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
				lm.update_song(lm.song_info.song, false, false);
				
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
				lm.update_song(lm.song_info.song, false, false);
			}
			
		}
		else {
			
		}
	}
	
	public void song_not_found(int id) {
		var not_found = new FileNotFoundDialog(lm, this, id);
		not_found.show();
	}
	
	public virtual void similarRetrieved(LinkedList<int> similarIDs, LinkedList<Song> similarDont) {
		Widget w = sideTree.getWidget(sideTree.playlists_similar_iter);
		
		((ViewWrapper)w).similarsFetched = true;
		((ViewWrapper)w).doUpdate(((ViewWrapper)w).currentView, similarIDs, true, true);
		
		infoPanel.updateSongList(similarDont);
		
		if(((ViewWrapper)w).isCurrentView && !((ViewWrapper)w).list.get_is_current()) {
			miller.populateColumns("", ((ViewWrapper)w).list.get_songs());
			updateMillerColumns();
		}
	}
	
	public void set_statusbar_text(string text) {
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
			lm.setShuffleMode(LibraryManager.Shuffle.OFF, true);
		else if(val == 1)
			lm.setShuffleMode(LibraryManager.Shuffle.ALL, true);
	}
	
	public virtual void infoPanelChooserOptionChanged(int val) {
		infoPanel.set_visible(val == 1);
		lm.settings.setMoreVisible(val == 1);
	}
	
	public void updateMillerColumns() {
		if(viewSelector.selected != 3)
			settings.setViewMode(viewSelector.selected);
			
		bool similarcheck = sideTree.getSelectedWidget() is ViewWrapper  && 
							((ViewWrapper)sideTree.getSelectedWidget()).errorBox != null && 
							((ViewWrapper)sideTree.getSelectedWidget()).errorBox.visible;
		bool isCdrom = sideTree.getSelectedWidget() is CDRomViewWrapper;
		bool isDeviceView = sideTree.getSelectedWidget() is DeviceView/* && ((DeviceView)sideTree.getSelectedWidget()).currentViewIndex() == 0*/;
		bool storecheck = (sideTree.getSelectedWidget() is Store.StoreView);
		bool haveSongs = (lm.song_count() != 0);
		
		miller.set_visible(viewSelector.selected == 2 && !similarcheck && !storecheck && !isCdrom && !isDeviceView && haveSongs);
		millerVisible = (viewSelector.selected == 0); // used for when an album is clicked from icon view
		
		// populate if selected == 2 (miller columns)
		/*if(initializationFinished && viewSelector.selected == 2 && sideTree.getSelectedWidget() is ViewWrapper && miller.visible) {
			ViewWrapper vw = (ViewWrapper)sideTree.getSelectedWidget();
			
			miller.populateColumns("", vw.songs);
		}*/
	}
	
	public void searchFieldActivate() {
		Widget w = sideTree.getSelectedWidget();
		
		if(w is ViewWrapper) {
			ViewWrapper vw = (ViewWrapper)w;
			
			vw.list.set_as_current_list(1, !vw.list.get_is_current());
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
