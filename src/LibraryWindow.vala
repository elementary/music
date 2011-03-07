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
	
	VBox verticalBox;
	VBox mainViews;
	ElementaryWidgets.Welcome welcomeScreen;
	HPaned sourcesToSongs; //allows for draggable
	ScrolledWindow sideTreeScroll;
	VBox sideBar;
	VBox contentBox;
	SideTreeView sideTree;
	ScrolledWindow songInfoScroll;
	ScrolledWindow pandoraScroll;
	ScrolledWindow grooveSharkScroll;
	WebView songInfo;
	WebView pandora;
	WebView grooveShark;
	Image coverArt;
	Toolbar topControls;
	ToolButton previousButton;
	ToolButton playButton;
	ToolButton nextButton;
	Button shuffleButton;
	Button loveButton;
	Button banButton;
	ElementaryWidgets.TopDisplay topDisplay;
	public ElementaryWidgets.ElementarySearchEntry searchField;
	ElementaryWidgets.AppMenu appMenu;
	Statusbar statusBar;
	
	MenuBar topMenu;
	
	// basic file stuff
	MenuItem libraryOperations;
	Menu libraryOperationsMenu;
	MenuItem fileImportMusic;
	MenuItem fileRescanMusicFolder;
	MenuItem helpOnline;
	MenuItem helpTranslate;
	MenuItem helpReport;
	MenuItem helpAbout;
	MenuItem editPreferences;
	
	Menu settingsMenu;
	
	Notify.Notification notification;
	
	public LibraryWindow(BeatBox.DataBaseManager dbm, BeatBox.StreamPlayer player) {
		settings = new BeatBox.Settings();
		//this.player = player;
		
		//this is used by many objects, is the media backend
		lm = new BeatBox.LibraryManager(player, dbm, settings);
		similarSongs = new LastFM.SimilarSongs(lm);
		timeout_search = new LinkedList<string>();
		mkl = new MediaKeyListener(lm, this);
		last_search = "";
		
		build_ui();
		
		this.lm.player.end_of_stream.connect(end_of_stream);
		this.lm.player.current_position_update.connect(current_position_update);
		this.lm.music_counted.connect(musicCounted);
		this.lm.music_added.connect(musicAdded);
		this.lm.music_imported.connect(musicImported);
		this.lm.music_rescanned.connect(musicRescanned);
		this.lm.progress_notification.connect(progressNotification);
		this.lm.song_added.connect(song_added);
		this.lm.song_removed.connect(song_removed);
		this.lm.song_played.connect(song_played);
		this.lm.songs_updated.connect(songs_updated);
		
		this.similarSongs.similar_retrieved.connect(similarRetrieved);
		
		destroy.connect (on_quit);
		check_resize.connect(on_resize);
		this.destroy.connect (Gtk.main_quit);
		
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
		
			Song s = settings.getLastSongPlaying();
			s = lm.song_from_name(s.title, s.artist);
			if(s.rowid != 0) {
				lm.playSong(s.rowid);
				
				/* time out works because... monkeys eat bananas */
				int position = (int)settings.getLastSongPosition();
				Timeout.add(500, () => {
					topDisplay.change_value(ScrollType.NONE, position);
					return false;
				});
			}
			
			// make sure we don't re-count stats
			if((int)settings.getLastSongPosition() > 30)
				song_considered_played = true;
			if((double)((int)settings.getLastSongPosition()/(double)lm.song_info.song.length) > 0.90)
				added_to_play_count = true;
			
			//this gives gee.hashmap error... not sure why
			((MusicTreeView)sideTree.getWidget(sideTree.library_music_iter)).setAsCurrentList(null);
			
			// rescan on startup
			lm.rescan_music_folder();
		}
	}
	
	public void build_ui() {
		// simple message to terminal
		stdout.printf("Building user interface\n");
		
		// set the size based on saved gconf settings
		set_size_request(900, 600);
		set_size_request(settings.getWindowWidth(), settings.getWindowHeight());
		allow_shrink = true;
		
		// set the title
		set_title("BeatBox");
		
		/* Initialize all components */
		verticalBox = new VBox(false, 0);
		sourcesToSongs = new HPaned();
		contentBox = new VBox(false, 0);
		mainViews = new VBox(false, 0);
		welcomeScreen = new ElementaryWidgets.Welcome("Get some tunes.", "BeatBox can't seem to find your music");
		sideTree = new SideTreeView(lm, this);	
		sideTreeScroll = new ScrolledWindow(null, null);
		coverArt = new Image();	
		topMenu = new MenuBar();
		libraryOperations = new MenuItem.with_label("Library");
		libraryOperationsMenu = new Menu();
		fileImportMusic = new MenuItem.with_label("Import to Library");
		fileRescanMusicFolder = new MenuItem.with_label("Rescan Music Folder");
		helpOnline = new MenuItem.with_label("Get Help Online...");
		helpTranslate = new MenuItem.with_label("Translate This Application...");
		helpReport = new MenuItem.with_label("Report a Problem...");
		helpAbout = new MenuItem.with_label("About");
		editPreferences = new MenuItem.with_label("Preferences");
		settingsMenu = new Menu();
		topControls = new Toolbar();
		previousButton = new ToolButton.from_stock(Gtk.Stock.MEDIA_PREVIOUS);
		playButton = new ToolButton.from_stock(Gtk.Stock.MEDIA_PLAY);
		nextButton = new ToolButton.from_stock(Gtk.Stock.MEDIA_NEXT);
		shuffleButton = new Button.with_label("Shuffle");
		loveButton = new Button.with_label("Love");
		banButton = new Button.with_label("Ban");
		topDisplay = new ElementaryWidgets.TopDisplay(lm);
		searchField = new ElementaryWidgets.ElementarySearchEntry("Search...");
		appMenu = new ElementaryWidgets.AppMenu.from_stock(Gtk.Stock.PROPERTIES, Gtk.IconSize.MENU, "Menu", settingsMenu);
		songInfoScroll = new ScrolledWindow(null, null);
		pandoraScroll = new ScrolledWindow(null, null);
		grooveSharkScroll = new ScrolledWindow(null, null);
		songInfo = new WebView();
		pandora = new WebView();
		grooveShark = new WebView();
		sideBar = new VBox(false, 0);
		statusBar = new Statusbar();
		notification = (Notify.Notification)GLib.Object.new (
						typeof (Notify.Notification),
						"summary", "Title",
						"body", "Artist\nAlbum");
		
		/* Set properties of various controls */
		sourcesToSongs.child1_resize = 1;
		sideBar.set_size_request(settings.getSidebarWidth(), -1);
		
		//for setting maximum size for setting hpane position max size
		//sideBar.set_geometry_hints(
		
		buildSideTree();
		
		shuffleButton.relief = Gtk.ReliefStyle.NONE;
		//shuffleButton.image = new Gtk.Image.from_stock(Gtk.Stock.MEDIA_SHUFFLE, Gtk.IconSize.SMALL_TOOLBAR);
		loveButton.relief = Gtk.ReliefStyle.NONE;
		banButton.relief = Gtk.ReliefStyle.NONE;
		
		updateSensitivities();
		
		libraryOperationsMenu.append(fileImportMusic);
		libraryOperationsMenu.append(fileRescanMusicFolder);
		libraryOperations.submenu = libraryOperationsMenu;
		
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
		helpAbout.activate.connect(helpAboutClick);
		editPreferences.activate.connect(editPreferencesClick);
		
		statusBar.has_resize_grip = true;
		
		/* Add controls to the GUI */
		add(verticalBox);
		verticalBox.pack_start(topMenu, false, true, 0);
		verticalBox.pack_start(topControls, false, true, 0);
        verticalBox.pack_start(sourcesToSongs, true, true, 0);
        //verticalBox.pack_start(statusBar, false, true, 0);
        
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
		contentBox.pack_start(statusBar, false, true, 0);
		
		sourcesToSongs.add1(sideBar);
		sourcesToSongs.add2(contentBox);
		
		songInfoScroll.add(songInfo);
		pandoraScroll.add(pandora);
		grooveSharkScroll.add(grooveShark);
		
		songInfo.window_features.scrollbar_visible = false;
		
		sideBar.pack_start(sideTreeScroll, true, true, 0);
		sideBar.pack_end(coverArt, false, true, 0);
		
		statusBar.pack_start(shuffleButton);
		
		/* Connect events to functions */
		sourcesToSongs.child1.size_allocate.connect(sourcesToSongsHandleSet);
		welcomeScreen.activated.connect(welcomeScreenActivated);
		sideTree.row_activated.connect(sideListDoubleClick);
		previousButton.clicked.connect(previousClicked);
		playButton.clicked.connect(playClicked);
		nextButton.clicked.connect(nextClicked);
		shuffleButton.clicked.connect(shuffleClicked);
		loveButton.clicked.connect(loveButtonClicked);
		banButton.clicked.connect(banButtonClicked);
		
		show_all();
		topMenu.hide();
		topDisplay.show_scale();
		topDisplay.set_scale_sensitivity(false);
		coverArt.hide();
		sideTree.resetView();
		songInfoScroll.hide();
		welcomeScreen.hide();
		updateSensitivities();
	}
	
	/** Builds the side tree on TreeView view
	 * @param view The side tree to build it on
	 */
	private void buildSideTree() {
		MusicTreeView mtv;
		
		sideTree.addBasicItems();
		
		// put song info first so it is on top when using multiple views
		//sideTree.addItem(null, new GLib.Object(), songInfoScroll, "Song Info");
		mainViews.pack_start(songInfoScroll, true, true, 0);
		
		SimilarPane sp = new SimilarPane(lm, this);
		sideTree.addItem(sideTree.playlists_iter, null, sp, "Similar");
		mainViews.pack_start(sp, true, true, 0);
		
		mtv = new MusicTreeView(lm, this, -1);
		mtv.set_hint("queue");
		mtv.populateView(lm.queue(), false);
		sideTree.addItem(sideTree.playlists_iter, null, mtv, "Queue");
		mainViews.pack_start(mtv, true, true, 0);
		
		mtv = new MusicTreeView(lm, this, -1);
		mtv.set_hint("history");
		mtv.populateView(lm.already_played(), false);
		sideTree.addItem(sideTree.playlists_iter, null, mtv, "History");
		mainViews.pack_start(mtv, true, true, 0);
		
		mtv = new MusicTreeView(lm, this, -1);
		mtv.set_hint("music");
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
			
			mtv = new MusicTreeView(lm, this, -1);
			mtv.set_hint("playlist");
			mtv.set_id(p.rowid);
			mtv.populateView(lm.songs_from_playlist(p.rowid), false);
			item = sideTree.addItem(sideTree.playlists_iter, p, mtv, p.name);
			mainViews.pack_start(mtv, true, true, 0);
		}
		else if(o is SmartPlaylist) {
			SmartPlaylist p = (SmartPlaylist)o;
			
			mtv = new MusicTreeView(lm, this, -1);
			mtv.set_hint("smart playlist");
			mtv.set_id(p.rowid);
			mtv.populateView(lm.songs_from_smart_playlist(p.rowid), false);
			item = sideTree.addItem(sideTree.playlists_iter, p, mtv, p.name);
			mainViews.pack_start(mtv, true, true, 0);
		}
		
		mtv.show_all();
		//sideTree.get_selection().unselect_all();
		//sideTree.get_selection().select_iter(item);
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
			
			welcomeScreen.hide();
			mainViews.show();
		}
	}
	
	public virtual void progressNotification(string? message, double progress) {
		//THIS IS WHAT CAUSES IT TO CRASH... WTF. SOMETHING WITH PANGO
		//if(message != null)
			//topDisplay.set_label_text(message);
		
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
				notification.close();
				notification.summary = lm.song_from_id(i).title;
				notification.body = lm.song_from_id(i).artist + "\n" + lm.song_from_id(i).album;
				
				if(lm.get_album_location(i) != null) {
					notification.set_image_from_pixbuf(new Gdk.Pixbuf.from_file(lm.get_album_location(i)));
				}
				else {
					//set to beatbox icon
				}
				
				notification.show();
			}
			catch(GLib.Error err) {
				stderr.printf("Could not show notification: %s\n", err.message);
			}
		}
		
		//updateCurrentSong();
		sideTree.updatePlayQueue();
	}
	
	public virtual void songs_updated(Collection<int> ids) {
		if(lm.song_info.song != null && ids.contains(lm.song_info.song.rowid)) {
			var song_label = "<b>" + lm.song_info.song.title.replace("&", "&amp;") + "</b>" + " by " + "<b>" + lm.song_info.song.artist.replace("&", "&amp;")  + "</b>" + " on " + "<b>" +lm.song_info.song.album.replace("&", "&amp;")  + "</b>";
			topDisplay.set_label_markup(song_label);
		}
	}
	
	public void* lastfm_thread_function () {
		/*bool update_track = false, update_artist = false, update_album = false;
		LastFM.ArtistInfo artist = new LastFM.ArtistInfo.basic();
		LastFM.TrackInfo track = new LastFM.TrackInfo.basic();
		LastFM.AlbumInfo album = new LastFM.AlbumInfo.basic();
		
		if(lm.song_info.album.name != lm.song_info.song.album || lm.song_info.album.artist != lm.song_info.song.artist) {
			update_album = true;
			
			if(!lm.album_info_exists(lm.song_info.song.album + " by " + lm.song_info.song.artist)) {
				//stdout.printf("Downloading new Album Info from Last FM\n");
				album = new LastFM.AlbumInfo.with_info(lm.song_info.song.artist, lm.song_info.song.album);
				
				//try to save album image locally
				if(lm.get_album_location(lm.song_info.song.rowid) == null && album != null)
					lm.save_album_locally(lm.song_info.song.rowid, album.url_image.url);
				
				if(album != null)
					lm.save_album(album);
			}
			else {
				album = lm.get_album(lm.song_info.song.album + " by " + lm.song_info.song.artist);
				
				//if no local image saved, save it now
				if(lm.get_album_location(lm.song_info.song.rowid) == null && album != null)
					lm.save_album_locally(lm.song_info.song.rowid, album.url_image.url);
			}
		}
		if(lm.song_info.artist.name != lm.song_info.song.artist) {
			update_artist = true;
			
			if(!lm.artist_info_exists(lm.song_info.song.artist)) {
				//stdout.printf("Downloading new Artist Info from Last FM\n");
				artist = new LastFM.ArtistInfo.with_artist(lm.song_info.song.artist);
				
				//try to save artist art locally
				if(lm.get_album_location(lm.song_info.song.rowid) == null && artist != null)
					lm.save_artist_image_locally(lm.song_info.song.rowid, artist.url_image.url);
				
				if(artist != null)
					lm.save_artist(artist);
			}
			else {
				artist = lm.get_artist(lm.song_info.song.artist);
				
				//if no local image saved, save it now
				if(lm.get_artist_image_location(lm.song_info.song.rowid) == null)
					lm.save_artist_image_locally(lm.song_info.song.rowid, artist.url_image.url);
			}
		}
		if(lm.song_info.track.name != lm.song_info.song.title || lm.song_info.track.artist != lm.song_info.song.artist) {
			update_track = true;
			
			if(!lm.track_info_exists(lm.song_info.song.title + " by " + lm.song_info.song.artist)) {
				//stdout.printf("Downloading new Track Info from Last FM\n");
				track = new LastFM.TrackInfo.with_info(lm.song_info.song.artist, lm.song_info.song.title);
				
				if(track != null)
					lm.save_track(track);
			}
			else
				track = lm.get_track(lm.song_info.song.title + " by " + lm.song_info.song.artist);
		}
		
		//test if song info is still what we want or if user has moved on
		bool update_song_display = false;
		
		if(lm.song_info.album.name != album.name && update_album) {
			update_song_display = true;
			lm.song_info.album = album;
		}
		if(lm.song_info.artist.name != artist.name && update_artist) {
			update_song_display = true;
			lm.song_info.artist = artist;
		}
		if(lm.song_info.track.name != track.name && update_track) {
			update_song_display = true;
			lm.song_info.track = track;
		}
		
		if(update_song_display) {
			Idle.add(updateSongInfo);
			Idle.add(updateCurrentSong);
		}
		*/
		return null;
    }
    
    public bool updateSongInfo() {
		string html_file = lm.song_info.update_file(lm.song_info.artist, lm.song_info.track, lm.song_info.album, lm.song_info.song);
		songInfo.open(html_file);
		
		return false;
	}
	
	public virtual void previousClicked () {
		lm.getPrevious(true);
	}
	
	public virtual void playClicked () {
		if(lm.song_info.song == null) {
			//set current songs by current view
			Widget w = sideTree.getSelectedWidget();
			if(w is MusicTreeView) {
				((MusicTreeView)w).setAsCurrentList("0");
			}
			else {
				w = sideTree.getWidget(sideTree.library_music_iter);
				((MusicTreeView)w).setAsCurrentList("0");
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
		// if not 90% done, skip it
		if(!added_to_play_count) {
			lm.song_info.song.skip_count++;
			//don't need to update song because it will be updated when the new song is played
		}
		
		lm.getNext(true);
	}
	
	public virtual void shuffleClicked() {
		if(shuffleButton.get_label() == "Shuffle") {
			shuffleButton.set_label("Unshuffle");
			lm.shuffleMusic();
		}
		else {
			shuffleButton.set_label("Shuffle");
			lm.unShuffleMusic();
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
		
		stdout.printf("Saving songs\n");
		lm.save_songs();
		
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
			}
		}
	}
	
	public virtual void fileRescanMusicFolderClick() {
		topDisplay.set_label_markup("<b>Rescanning music folder for changes</b>");
		topDisplay.show_progressbar();
		
		lm.rescan_music_folder();
	}
	
	public virtual void musicCounted(int count) {
		stdout.printf("taha!\n");
		if(count > 0) {
			//hide welcome view if showing
			welcomeScreen.hide();
			mainViews.show();
		}
	}
	
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
			NotImportedWindow nim = new NotImportedWindow(not_imported);
			nim.show();
		}
		
		updateSensitivities();
		
		lm.save_songs();
		
		//now notify user
		try {
			notification.close();
			if(!has_toplevel_focus) {
				notification.summary = "Import Complete";
				notification.body = "BeatBox has imported your library";
				//notification.set_image_from_pixbuf(this.render_icon("music-folder", IconSize.SMALL_TOOLBAR, null));
				
				notification.show();
			}
		}
		catch(GLib.Error err) {
			stderr.printf("Could not show notification: %s\n", err.message);
		}
	}
	
	public virtual void musicImported(LinkedList<Song> new_songs, LinkedList<string> not_imported) {
		topDisplay.show_scale();
		
		if(lm.song_info.song != null) {
			var song_label = "<b>" + lm.song_info.song.title + "</b>" + " by " + "<b>" + lm.song_info.song.artist + "</b>" + " on " + "<b>" +lm.song_info.song.album + "</b>";
			topDisplay.set_label_markup(song_label);
		}
		else
			topDisplay.set_label_text("");
		
		stdout.printf("TODO: re-populate view without freezing view\n");
		
		foreach(Song s in new_songs) {
			stdout.printf("NEW SONG %s by %s\n", s.title, s.artist);
			((MusicTreeView)sideTree.getWidget(sideTree.library_music_iter)).addSong(s);
		}
		
		((MusicTreeView)sideTree.getWidget(sideTree.library_music_iter)).searchFieldChanged();
		
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
		
		stdout.printf("TODO: re-populate view without freezing view\n");
		//Widget w = sideTree.getWidget(sideTree.library_music_iter);
		//((MusicTreeView)w).populateView(lm.song_ids(), false);
		
		foreach(Song s in new_songs) {
			stdout.printf("NEW SONG %s by %s\n", s.title, s.artist);
			((MusicTreeView)sideTree.getWidget(sideTree.library_music_iter)).addSong(s);
		}
		
		((MusicTreeView)sideTree.getWidget(sideTree.library_music_iter)).searchFieldChanged();
		
		updateSensitivities();
	}
	
	public virtual void song_added(int id) {
		
	}
	
	public virtual void song_removed(int id) {
		updateSensitivities();
	}
	
	public virtual void helpAboutClick() {
		AboutDialog ad = new AboutDialog();
		
		ad.set_program_name("BeatBox");
		ad.set_version("0.1");
		ad.set_website("https://launchpad.net/beat-box");
		ad.set_website_label("Launchpad");
		
		string[] authors = new string[1];
		authors[0] = "Scott Ringwelski";
		ad.set_authors(authors);
		
		ad.response.connect( (response_id) => { 
			ad.destroy(); 
		});
		
		ad.show();
	}
	
	public virtual void editPreferencesClick() {
		PreferencesWindow pw = new PreferencesWindow(lm);
		
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
				try {
					Thread.create<void*>(lastfm_thread_function, false);
				}
				catch(GLib.ThreadError err) {
					stdout.printf("ERROR: Could not create last fm thread: %s \n", err.message);
				}
				
				similarSongs.queryForSimilar(lm.song_info.song);
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
	
	public virtual void similarRetrieved(LinkedList<Song> similar) {
		LinkedList<int> similarIDs = new LinkedList<int>();
		var similarDont = new LinkedList<Song>();
		
		foreach(BeatBox.Song sim in similar) {
			BeatBox.Song s = lm.song_from_name(sim.title, sim.artist);
			if(s.rowid != 0) {
				similarIDs.add(s.rowid);
			}
			else {
				similarDont.add(sim);
			}
		}
		
		Widget w = sideTree.getWidget(sideTree.playlists_similar_iter);
		((SimilarPane)w).updateSongs(lm.song_info.song, similarIDs, similarDont);
	}
	
	public void setStatusBarText(string text) {
		stdout.printf("View changed, set text to %s\n", text);
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
}
