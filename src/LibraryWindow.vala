using Gtk;
using Gee;
using WebKit;
using Notify;

public class BeatBox.LibraryWindow : Gtk.Window {
	BeatBox.LibraryManager lm;
	BeatBox.Settings settings;
	LastFM.SimilarSongs similarSongs;
	BeatBox.MediaKeyListener mkl;
	
	bool queriedlastfm; // whether or not we have queried last fm for the current song info
	bool song_considered_played; //whether or not we have updated last played and added to already played list
	bool added_to_play_count; // whether or not we have added one to play count on playing song
	LinkedList<string> timeout_search;//stops from doing useless search
	string last_search;//stops from searching same thing multiple times
	
	public bool dragging_from_music;
	
	VBox verticalBox;
	VBox mainViews;
	ElementaryWidgets.Welcome welcomeScreen;
	HPaned sourcesToSongs; //allows for draggable
	HPaned songsToInfo; // song info pane
	ScrolledWindow sideTreeScroll;
	VBox sideBar;
	VBox contentBox;
	SideTreeView sideTree;
	ScrolledWindow songInfoScroll;
	ScrolledWindow pandoraScroll;
	ScrolledWindow grooveSharkScroll;
	InfoPanel infoPanel;
	Image coverArt;
	Toolbar topControls;
	ToolButton previousButton;
	ToolButton playButton;
	ToolButton nextButton;
	Button loveButton;
	Button banButton;
	ElementaryWidgets.TopDisplay topDisplay;
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
	MenuItem fileImportMusic;
	MenuItem fileRescanMusicFolder;
	ImageMenuItem helpOnline;
	MenuItem helpTranslate;
	MenuItem helpReport;
	ImageMenuItem helpAbout;
	ImageMenuItem editPreferences;
	
	Menu settingsMenu;
	
	Notify.Notification notification;
	
	public LibraryWindow(BeatBox.DataBaseManager dbm, BeatBox.StreamPlayer player) {
		settings = new BeatBox.Settings();
		//this.player = player;
		
		//this is used by many objects, is the media backend
		lm = new BeatBox.LibraryManager(player, dbm, settings, this);
		similarSongs = new LastFM.SimilarSongs(lm);
		timeout_search = new LinkedList<string>();
		mkl = new MediaKeyListener(lm, this);
		last_search = "";
		
		dragging_from_music = false;
		
		build_ui();
		
		this.lm.player.end_of_stream.connect(end_of_stream);
		this.lm.player.current_position_update.connect(current_position_update);
		this.lm.music_counted.connect(musicCounted);
		this.lm.music_added.connect(musicAdded);
		this.lm.music_imported.connect(musicImported);
		this.lm.music_rescanned.connect(musicRescanned);
		this.lm.progress_notification.connect(progressNotification);
		this.lm.song_added.connect(song_added);
		this.lm.songs_removed.connect(songs_removed);
		this.lm.song_played.connect(song_played);
		this.lm.songs_updated.connect(songs_updated);
		
		this.similarSongs.similar_retrieved.connect(similarRetrieved);
		
		destroy.connect (on_quit);
		check_resize.connect(on_resize);
		this.destroy.connect (Gtk.main_quit);
		
		this.present();
		if(lm.song_count() == 0 && settings.getMusicFolder() == "") {
			stdout.printf("First run, setting music folder and importing.\n");
			setMusicFolder(GLib.Environment.get_user_special_dir(UserDirectory.MUSIC));
		}
		else if(lm.song_count() == 0 && settings.getMusicFolder() != "") {
			setMusicFolder(GLib.Environment.get_user_special_dir(UserDirectory.MUSIC));
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
			
			Song s = settings.getLastSongPlaying();
			s = lm.song_from_name(s.title, s.artist);
			if(s.rowid != 0) {
				/* time out works because... monkeys eat bananas */
				int position = (int)settings.getLastSongPosition();
				Timeout.add(200, () => {
					lm.playSong(s.rowid);
					
					((MusicTreeView)sideTree.getWidget(sideTree.library_music_iter)).setAsCurrentList(0);
					if(settings.getShuffleMode() == LibraryManager.Shuffle.ALL)
						lm.setShuffleMode(LibraryManager.Shuffle.ALL);
					
					((MusicTreeView)sideTree.getWidget(sideTree.library_music_iter)).scrollToCurrent();
					
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
		mainViews = new VBox(false, 0);
		welcomeScreen = new ElementaryWidgets.Welcome("Get some tunes.", "BeatBox can't seem to find your music");
		sideTree = new SideTreeView(lm, this);	
		sideTreeScroll = new ScrolledWindow(null, null);
		coverArt = new Image();	
		topMenu = new MenuBar();
		libraryOperations = new ImageMenuItem.from_stock("folder-music", null);
		libraryOperationsMenu = new Menu();
		fileImportMusic = new MenuItem.with_label("Import to Library");
		fileRescanMusicFolder = new MenuItem.with_label("Rescan Music Folder");
		helpOnline = new ImageMenuItem.from_stock(Gtk.Stock.HELP, null);
		helpTranslate = new MenuItem.with_label("Translate This Application...");
		helpReport = new MenuItem.with_label("Report a Problem...");
		helpAbout = new ImageMenuItem.from_stock(Gtk.Stock.ABOUT, null);
		editPreferences = new ImageMenuItem.from_stock(Gtk.Stock.PREFERENCES, null);
		settingsMenu = new Menu();
		topControls = new Toolbar();
		previousButton = new ToolButton.from_stock(Gtk.Stock.MEDIA_PREVIOUS);
		playButton = new ToolButton.from_stock(Gtk.Stock.MEDIA_PLAY);
		nextButton = new ToolButton.from_stock(Gtk.Stock.MEDIA_NEXT);
		loveButton = new Button.with_label("Love");
		banButton = new Button.with_label("Ban");
		topDisplay = new ElementaryWidgets.TopDisplay(lm);
		searchField = new ElementaryWidgets.ElementarySearchEntry("Search...");
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
		infoPanelChooser = new SimpleOptionChooser(render_icon("help-info", IconSize.SMALL_TOOLBAR, null), render_icon("help-info", IconSize.SMALL_TOOLBAR, null));
		
		notification = (Notify.Notification)GLib.Object.new (
						typeof (Notify.Notification),
						"summary", "Title",
						"body", "Artist\nAlbum");
		
		/* Set properties of various controls */
		sourcesToSongs.set_position(settings.getSidebarWidth());
		songsToInfo.set_position((lm.settings.getWindowWidth() - lm.settings.getSidebarWidth()) - lm.settings.getMoreWidth());
		
		//for setting maximum size for setting hpane position max size
		//sideBar.set_geometry_hints(
		
		buildSideTree();
		
		loveButton.relief = Gtk.ReliefStyle.NONE;
		banButton.relief = Gtk.ReliefStyle.NONE;
		
		updateSensitivities();
		
		/* create appmenu menu */
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
		settingsMenu.append(helpAbout);
		settingsMenu.append(editPreferences);
		
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
		editPreferences.activate.connect(editPreferencesClick);
		
		// make the background white
		EventBox statusEventBox = new EventBox();
		statusEventBox.add(statusBar);
		
		Gdk.Color c = Gdk.Color();
		Gdk.Color.parse("#FFFFFF", out c);
		statusEventBox.modify_bg(StateType.NORMAL, c);
		
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
        verticalBox.pack_start(sourcesToSongs, true, true, 0);
        
        ToolItem topDisplayBin = new ToolItem();
        ToolItem searchFieldBin = new ToolItem();
        ToolItem appMenuBin = new ToolItem();
        topDisplayBin.add(topDisplay);
        topDisplayBin.set_border_width(5);
        searchFieldBin.add(searchField);
        appMenuBin.add(appMenu);
        
        topDisplayBin.set_expand(true);
        
        topControls.insert(previousButton, 0);
        topControls.insert(playButton, 1);
        topControls.insert(nextButton, 2);
        topControls.insert(topDisplayBin, 3);
        topControls.insert(searchFieldBin, 4);
        topControls.insert(appMenuBin, 5);
		
		//set the name for elementary theming
		sourcesToSongs.name = "SidebarHandleLeft";
		sideTree.name = "SidebarContent";
		
		contentBox.pack_start(welcomeScreen, true, true, 0);
		welcomeScreen.append("folder-music", "Import", "Select your music folder to import from.");
		
		contentBox.pack_start(mainViews, true, true, 0);
		contentBox.pack_start(statusEventBox, false, true, 0);
		
		songsToInfo.pack1(contentBox, true, true);
		songsToInfo.pack2(infoPanel, true, false);
		
		sourcesToSongs.pack1(sideBar, true, true);
		sourcesToSongs.pack2(songsToInfo, true, false);
		
		sideBar.pack_start(sideTreeScroll, true, true, 0);
		sideBar.pack_end(coverArt, false, true, 0);
		
		statusBar.pack_start(shuffleChooser, false, false, 2);
		statusBar.pack_start(repeatChooser, false, false, 2);
		statusBar.pack_start(statusBarLabel, true, true, 0);
		statusBar.pack_start(infoPanelChooser, false, false, 2);
		
		
		/* Connect events to functions */
		sourcesToSongs.child1.size_allocate.connect(sourcesToSongsHandleSet);
		welcomeScreen.activated.connect(welcomeScreenActivated);
		sideTree.row_activated.connect(sideListDoubleClick);
		previousButton.clicked.connect(previousClicked);
		playButton.clicked.connect(playClicked);
		nextButton.clicked.connect(nextClicked);
		loveButton.clicked.connect(loveButtonClicked);
		banButton.clicked.connect(banButtonClicked);
		infoPanel.size_allocate.connect(infoPanelResized);
		repeatChooser.option_changed.connect(repeatChooserOptionChanged);
		shuffleChooser.option_changed.connect(shuffleChooserOptionChanged);
		infoPanelChooser.option_changed.connect(infoPanelChooserOptionChanged);
		
		/* set up drag dest stuff */
		drag_dest_set(this, DestDefaults.ALL, {}, Gdk.DragAction.MOVE);
		Gtk.drag_dest_add_uri_targets(this);
		drag_data_received.connect(dragReceived);
		
		show_all();
		topMenu.hide();
		topDisplay.show_scale();
		topDisplay.set_scale_sensitivity(false);
		coverArt.hide();
		sideTree.resetView();
		welcomeScreen.hide();
		infoPanel.set_visible(settings.getMoreVisible());
		updateSensitivities();
		((SimilarPane)sideTree.getWidget(sideTree.playlists_similar_iter)).initializeView();
	}
	
	/** Builds the side tree on TreeView view
	 * @param view The side tree to build it on
	 */
	private void buildSideTree() {
		MusicTreeView mtv;
		
		sideTree.addBasicItems();
		
		SimilarPane sp = new SimilarPane(lm, this);
		sideTree.addItem(sideTree.playlists_iter, null, sp, "Similar");
		mainViews.pack_start(sp, true, true, 0);
		
		mtv = new MusicTreeView(lm, this, lm.queue_setup.sort_column, lm.queue_setup.sort_direction, MusicTreeView.Hint.QUEUE, -1);
		mtv.populateView(lm.queue(), false);
		sideTree.addItem(sideTree.playlists_iter, null, mtv, "Queue");
		mainViews.pack_start(mtv, true, true, 0);
		
		mtv = new MusicTreeView(lm, this,  lm.history_setup.sort_column, lm.history_setup.sort_direction, MusicTreeView.Hint.HISTORY, -1);
		mtv.populateView(lm.already_played(), false);
		sideTree.addItem(sideTree.playlists_iter, null, mtv, "History");
		mainViews.pack_start(mtv, true, true, 0);
		
		mtv = new MusicTreeView(lm, this,  lm.music_setup.sort_column, lm.music_setup.sort_direction, MusicTreeView.Hint.MUSIC, -1);
		mtv.populateView(lm.song_ids(), false);
		sideTree.addItem(sideTree.library_iter, null, mtv, "Music");
		mainViews.pack_start(mtv, true, true, 0);
		
		// load smart playlists
		foreach(SmartPlaylist p in lm.smart_playlists()) {
			addSideListItem(p);
		}
		
		// load playlists
		foreach(Playlist p in lm.playlists()) {
			addSideListItem(p);
		}
		
		
		sideTree.resetView();
		sideTree.expand_all();
		
		sideTreeScroll = new ScrolledWindow(null, null);
		sideTreeScroll.set_policy (PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
		sideTreeScroll.add(sideTree);
	}
	
	public void addSideListItem(GLib.Object o) {
		TreeIter item = sideTree.library_music_iter;
		MusicTreeView mtv = null;
		
		if(o is Playlist) {
			Playlist p = (Playlist)o;
			
			mtv = new MusicTreeView(lm, this, p.tvs.sort_column, p.tvs.sort_direction, MusicTreeView.Hint.PLAYLIST, p.rowid);
			mtv.populateView(lm.songs_from_playlist(p.rowid), false);
			item = sideTree.addItem(sideTree.playlists_iter, p, mtv, p.name);
			mainViews.pack_start(mtv, true, true, 0);
		}
		else if(o is SmartPlaylist) {
			SmartPlaylist p = (SmartPlaylist)o;
			
			mtv = new MusicTreeView(lm, this, p.tvs.sort_column, p.tvs.sort_direction, MusicTreeView.Hint.SMART_PLAYLIST, p.rowid);
			mtv.populateView(lm.songs_from_smart_playlist(p.rowid), false);
			item = sideTree.addItem(sideTree.playlists_iter, p, mtv, p.name);
			mainViews.pack_start(mtv, true, true, 0);
		}
		
		mtv.show_all();
	}
	
	public void updateSensitivities() {
		if(lm.song_count() == 0) {
			topDisplay.set_scale_sensitivity(false);
			previousButton.set_sensitive(false);
			playButton.set_sensitive(false);
			nextButton.set_sensitive(false);
			searchField.set_sensitive(false);
			statusBar.hide();
			
			if(settings.getMusicFolder() != "") {
				mainViews.hide();
				songInfoScroll.hide();
				welcomeScreen.show();
			}
		}
		else {
			if(lm.song_info.song != null)
				topDisplay.set_scale_sensitivity(true);
			
			previousButton.set_sensitive(true);
			playButton.set_sensitive(true);
			nextButton.set_sensitive(true);
			searchField.set_sensitive(true);
			statusBar.show();
		}
		
		if(lm.doing_file_operations) {
			fileImportMusic.set_sensitive(false);
			fileRescanMusicFolder.set_sensitive(false);
		}
		else {
			fileImportMusic.set_sensitive(true);
			fileRescanMusicFolder.set_sensitive(true);
		}
	}
	
	public virtual void progressNotification(string? message, double progress) {
		//THIS IS WHAT CAUSES IT TO CRASH... WTF. SOMETHING WITH PANGO
		if(message != null)
			topDisplay.set_label_markup(message);
		
		if(progress != 0.0 && progress > 0.0 && progress < 1.0)
			topDisplay.set_progress_value(progress);
	}
	
	public virtual void sideListDoubleClick (TreePath path, TreeViewColumn column) {
		
	}
	
	public bool updateCurrentSong() {
		//loop through all musictreeviews and call updatecurrentsong
		
		if(lm.song_info.song != null) {
			string file = "";
			if((file = lm.get_album_location(lm.song_info.song.rowid)) != null) {
				coverArt.show();
				try {
					coverArt.set_from_pixbuf(new Gdk.Pixbuf.from_file_at_size(file, sourcesToSongs.position, sourcesToSongs.position));
				}
				catch(GLib.Error err) {
					stdout.printf("Could not set image art: %s\n", err.message);
				}
			}
			else
				coverArt.hide();
		}
		
		return false;
	}
	
	/** This should be used whenever a call to play a new song is made
	 * @param s The song that is now playing
	 */
	public virtual void song_played(int i) {
		//set the title
		var song_label = "<b>" + lm.song_from_id(i).title.replace("&", "&amp;") + "</b>" + " by " + "<b>" + lm.song_from_id(i).artist.replace("&", "&amp;") + "</b>" + " on " + "<b>" +lm.song_from_id(i).album.replace("&", "&amp;") + "</b>";
		topDisplay.set_label_markup(song_label);
		
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
		
		
		//update the notifier
		if(!has_toplevel_focus) {
			try {
				notification.set_timeout(1);
				notification.update(lm.song_from_id(i).title, lm.song_from_id(i).artist + "\n" + lm.song_from_id(i).album, "");
				
				Gdk.Pixbuf notify_pix;
				if(lm.get_album_location(i) != null)
					notify_pix = new Gdk.Pixbuf.from_file(lm.get_album_location(i));
				else
					notify_pix = render_icon("beatbox", IconSize.DIALOG, null);
				
				if(notify_pix != null)
					notification.set_image_from_pixbuf(notify_pix);
				
				notification.show();
				notification.set_timeout(5000);
			}
			catch(GLib.Error err) {
				stderr.printf("Could not show notification: %s\n", err.message);
			}
		}
		
		updateCurrentSong();
		
		infoPanel.updateSong(lm.song_info.song.rowid);
		if(settings.getMoreVisible())
			infoPanel.set_visible(true);
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
			artist_s == lm.song_info.song.artist && lm.get_album_location(lm.song_info.song.rowid) == null) {
				lm.song_info.album = album;
			
                if (album.url_image.url != null)
    				lm.save_album_locally(lm.song_info.song.rowid, album.url_image.url);
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
			lm.get_artist_image_location(lm.song_info.song.rowid) == null) {
				lm.song_info.artist = artist;
				
				lm.save_artist_image_locally(lm.song_info.song.rowid, artist.url_image.url);
			}
			else {
				return null;
			}
		}
		
		Idle.add( () => { infoPanel.updateArtistImage(); return false;});
		
		return null;
	}
    
    public bool updateSongInfo() {
		infoPanel.updateSong(lm.song_info.song.rowid);
		
		return false;
	}
	
	public virtual void previousClicked () {
		if(!queriedlastfm)
			lm.getPrevious(true);
		else
			topDisplay.change_value(ScrollType.NONE, 0);
	}
	
	public virtual void playClicked () {
		if(lm.song_info.song == null) {
			//set current songs by current view
			Widget w = sideTree.getSelectedWidget();
			if(w is MusicTreeView) {
				((MusicTreeView)w).setAsCurrentList(1);
			}
			else {
				w = sideTree.getWidget(sideTree.library_music_iter);
				((MusicTreeView)w).setAsCurrentList(1);
			}
			
			lm.playing = true;
			playButton.set_stock_id(Gtk.Stock.MEDIA_PAUSE);
			lm.player.play_stream();
			
			lm.getNext(true);
		}
		else {
			if(lm.playing) {
				lm.playing = false;
				lm.player.pause_stream();
				playButton.set_stock_id(Gtk.Stock.MEDIA_PLAY);
			}
			else {
				lm.playing = true;
				lm.player.play_stream();
				playButton.set_stock_id(Gtk.Stock.MEDIA_PAUSE);
			}
		}
	}
	
	public virtual void nextClicked() {
		int next_id = lm.getNext(true);
		
		/* test to stop playback/reached end */
		if(next_id == 0) {
			lm.player.pause_stream();
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
	
	public virtual void sourcesToSongsHandleSet(Gdk.Rectangle rectangle) {
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
		this.hide();
		
		//second: stop music
		stdout.printf("Stopping playback\n");
		lm.player.pause_stream();
		
		lm.settings.setLastSongPosition((int)topDisplay.get_scale_value());
		
		//stdout.printf("Saving songs\n");
		//lm.save_songs();
		
		stdout.printf("Saving playlists\n");
		lm.save_playlists();
		lm.save_smart_playlists();
		
		stdout.printf("Saving LastFM Info\n");
		lm.save_artists();
		lm.save_albums();
		lm.save_tracks();
	}
	
	public virtual void fileImportMusicClick() {
		if(!lm.doing_file_operations) {
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
				topDisplay.set_label_markup("<b>Importing</b> music from <b>" + folder + "</b> to library.");
				topDisplay.show_progressbar();
				
				lm.add_folder_to_library(folder);
				updateSensitivities();
			}
		}
		else {
			stdout.printf("Can't add to library.. already doing file operations\n");
		}
	}
	
	public virtual void fileRescanMusicFolderClick() {
		if(!lm.doing_file_operations) {
			topDisplay.set_label_markup("<b>Rescanning music folder for changes</b>");
			topDisplay.show_progressbar();
			
			lm.rescan_music_folder();
			updateSensitivities();
		}
		else {
			stdout.printf("Can't rescan.. doing file operations already\n");
		}
	}
	
	public virtual void musicCounted(int count) {
		stdout.printf("taha!\n");
		if(count > 0) {
			//hide welcome view if showing
			welcomeScreen.hide();
			mainViews.show();
		}
	}
	
	/* this is after setting the music library */
	public virtual void musicAdded(LinkedList<string> not_imported) {
		sideTree.resetView();
		topDisplay.show_scale();
		
		if(lm.song_info.song != null) {
			var song_label = "<b>" + lm.song_info.song.title + "</b>" + " by " + "<b>" + lm.song_info.song.artist + "</b>" + " on " + "<b>" +lm.song_info.song.album + "</b>";
			topDisplay.set_label_markup(song_label);
		}
		else
			topDisplay.set_label_text("");
		
		//repopulate collection and playlists and reset queue and already played
		Widget w = sideTree.getWidget(sideTree.library_music_iter);
		((MusicTreeView)w).populateView(lm.song_ids(), false);
		
		if(not_imported.size > 0) {
			NotImportedWindow nim = new NotImportedWindow(this, not_imported);
			nim.show();
		}
		
		updateSensitivities();
		
		lm.save_songs();
		
		//now notify user
		try {
			notification.close();
			if(!has_toplevel_focus) {
				notification.update("Import Complete", "BeatBox has imported your library", "beatbox");
				notification.set_image_from_pixbuf(render_icon("beatbox", IconSize.DIALOG, null));
				
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
		topDisplay.show_scale();
		
		if(lm.song_info.song != null) {
			var song_label = "<b>" + lm.song_info.song.title + "</b>" + " by " + "<b>" + lm.song_info.song.artist + "</b>" + " on " + "<b>" +lm.song_info.song.album + "</b>";
			topDisplay.set_label_markup(song_label);
		}
		else
			topDisplay.set_label_text("");
		
		stdout.printf("TODO: add all new songs from import to music treeview\n");
		/*foreach(Song s in new_songs) {
			((MusicTreeView)sideTree.getWidget(sideTree.library_music_iter)).addSong(s);
		}*/
		
		if(searchField.text != "" && searchField.text != searchField.hint_string) {
			((MusicTreeView)sideTree.getWidget(sideTree.library_music_iter)).searchFieldChanged();
			((MusicTreeView)sideTree.getWidget(sideTree.library_music_iter)).searchFieldChanged();
		}
		
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
		
		stdout.printf("TODO: add all new songs from import to music treeview\n");
		/*foreach(Song s in new_songs) {
			((MusicTreeView)sideTree.getWidget(sideTree.library_music_iter)).addSong(s);
		}*/
		
		if(searchField.text != "" && searchField.text != searchField.hint_string) {
			((MusicTreeView)sideTree.getWidget(sideTree.library_music_iter)).searchFieldChanged();
			((MusicTreeView)sideTree.getWidget(sideTree.library_music_iter)).searchFieldChanged();
		}
		
		updateSensitivities();
	}
	
	public virtual void song_added(int id) {
		
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
	
	public virtual void editPreferencesClick() {
		PreferencesWindow pw = new PreferencesWindow(lm, this);
		
		pw.changed.connect( (folder) => {
			setMusicFolder(folder);
		});
	}
	
	public void setMusicFolder(string folder) {
		topDisplay.set_label_markup("<b>Importing</b> music from <b>" + folder + "</b>");
		topDisplay.show_progressbar();
		lm.set_music_folder(folder);
	}
	
	public virtual void end_of_stream(Song s) {
		nextClicked();
	}
	
	public virtual void current_position_update(int64 position) {
		double sec = 0.0;
		if(lm.song_info.song != null) {
			sec = ((double)position/1000000000);
			
			// at about 5 seconds, update last fm. we wait to avoid excessive querying last.fm for info
			if(position > 5000000000 && !queriedlastfm) {
				queriedlastfm = true;
				
				similarSongs.queryForSimilar(lm.song_info.song);
				
				try {
					Thread.create<void*>(lastfm_track_thread_function, false);
					Thread.create<void*>(lastfm_album_thread_function, false);
					Thread.create<void*>(lastfm_artist_thread_function, false);
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
	
	public virtual void similarRetrieved(LinkedList<int> similarIDs, LinkedList<Song> similarDont) {
		Widget w = sideTree.getWidget(sideTree.playlists_similar_iter);
		((SimilarPane)w).updateSongs(lm.song_info.song, similarIDs);
		
		infoPanel.updateSongList(similarDont);
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
			
			if(folder != "" && folder != settings.getMusicFolder()) {
				setMusicFolder(folder);
			}
		}
	}
	
	public virtual void infoPanelResized(Gdk.Rectangle rectangle) {
		int height, width;
		get_size(out width, out height);
		
		if(sourcesToSongs.get_position() > height/2)
			return;
		
		if(songsToInfo.get_position() < (lm.settings.getWindowWidth() - lm.settings.getSidebarWidth()) - 250) {
			songsToInfo.set_position((lm.settings.getWindowWidth() - lm.settings.getSidebarWidth()) - 250);
			return;
		}
		else if(songsToInfo.get_position() > (lm.settings.getWindowWidth() - lm.settings.getSidebarWidth()) - 150) {
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
}
