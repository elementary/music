using Gtk;
using Gee;
using WebKit;
//using Notify;

public class BeatBox.LibraryWindow : Gtk.Window {
	BeatBox.LibraryManager lm;
	BeatBox.Settings settings;
	BeatBox.StreamPlayer player;
	LastFM.SimilarSongs similarSongs;
	
	string current_view_path;
	bool queriedlastfm; // whether or not we have queried last fm for the current song info
	bool song_considered_played; //whether or not we have updated last played and added to already played list
	bool added_to_play_count; // whether or not we have added one to play count on playing song
	bool loaded_pandora;
	bool loaded_groove_shark;
	string timeout_search;
	
	VBox verticalBox;
	VBox mainViews;
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
	ElementaryWidgets.ElementarySearchEntry searchField;
	ElementaryWidgets.AppMenu appMenu;
	Statusbar statusBar;
	
	MenuBar topMenu;
	
	// basic file stuff
	MenuItem fileRescanMusicFolder;
	MenuItem helpOnline;
	MenuItem helpTranslate;
	MenuItem helpReport;
	MenuItem helpAbout;
	MenuItem editPreferences;
	
	Menu settingsMenu;
	
	//Notify.Notification notification;
	
	public LibraryWindow(BeatBox.DataBaseManager dbm, BeatBox.StreamPlayer player) {
		settings = new BeatBox.Settings();
		this.player = player;
		
		//this is used by many objects, is the media backend
		lm = new BeatBox.LibraryManager(player, dbm, settings);
		similarSongs = new LastFM.SimilarSongs(lm);
		
		build_ui();
		
		this.player.end_of_stream.connect(end_of_stream);
		this.player.current_position_update.connect(current_position_update);
		
		this.lm.music_added.connect(musicAdded);
		this.lm.music_rescanned.connect(musicRescanned);
		this.lm.progress_notification.connect(progressNotification);
		this.lm.song_removed.connect(songRemovedFromManager);
		this.lm.song_played.connect(song_played);
		this.lm.songs_updated.connect(songs_updated);
		
		this.similarSongs.similar_retrieved.connect(similarRetrieved);
		
		destroy.connect (on_quit);
		check_resize.connect(on_resize);
		this.destroy.connect (Gtk.main_quit);
		
		if(lm.song_count() == 0 && settings.getMusicFolder() == "") {
			stdout.printf("First run, setting music folder and importing.\n");
			lm.set_music_folder(GLib.Environment.get_user_special_dir(UserDirectory.MUSIC));
		}
		else if(lm.song_count() == 0 && settings.getMusicFolder() != "") {
			stdout.printf("No songs but music folder is set, showing welcome screen.\n");
			//show welcome screen
		}
		else {
			lm.clearCurrent();
			((MusicTreeView)sideTree.getWidget(sideTree.library_music_iter)).setAsCurrentList("0");
		
			Song s = settings.getLastSongPlaying();
			s = lm.song_from_name(s.title, s.artist);
			if(s.rowid != 0) {
				int new_i = 0;
				foreach(int i in lm.current_songs()) {
					if(lm.song_from_id(i).rowid == s.rowid) {
						lm.current_index = new_i;
						break;
					}
					
					++new_i;
				}
				
				((MusicTreeView)sideTree.getWidget(sideTree.library_music_iter)).setAsCurrentList(new_i.to_string());
				
				lm.playSong(s.rowid);
				topDisplay.change_value(ScrollType.NONE, (int)settings.getLastSongPosition());
				topDisplaySliderMoved(ScrollType.NONE, (int)settings.getLastSongPosition());
			}
			
			//always rescan on startup
			fileRescanMusicFolderClick();
		}
	}
	
	public void build_ui() {
		// simple message to terminal
		stdout.printf("Building user interface\n");
		
		// set the size based on saved gconf settings
		set_size_request(settings.getWindowWidth(), settings.getWindowHeight());
		allow_shrink = true;
		
		// set the title
		set_title("BeatBox");
		
		/* Initialize all components */
		verticalBox = new VBox(false, 0);
		sourcesToSongs = new HPaned();
		contentBox = new VBox(false, 0);
		mainViews = new VBox(false, 0);
		sideTree = new SideTreeView(lm, this);	
		sideTreeScroll = new ScrolledWindow(null, null);
		coverArt = new Image();	
		topMenu = new MenuBar();
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
		//notification = new Notification("Title", "Artist\nAlbum", "", null);
		
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
		
		settingsMenu.append(fileRescanMusicFolder);
		settingsMenu.append(new SeparatorMenuItem());
		settingsMenu.append(helpOnline);
		settingsMenu.append(helpTranslate);
		settingsMenu.append(helpReport);
		settingsMenu.append(new SeparatorMenuItem());
		settingsMenu.append(helpAbout);
		settingsMenu.append(editPreferences);
		
		fileRescanMusicFolder.activate.connect(fileRescanMusicFolderClick);
		helpOnline.activate.connect( () => {
			string auth_uri = "https://answers.launchpad.net/beat-box";
			GLib.AppInfo.launch_default_for_uri (auth_uri, null);
		});
		helpTranslate.activate.connect( () => {
			string auth_uri = "https://translations.launchpad.net/beat-box";
			GLib.AppInfo.launch_default_for_uri (auth_uri, null);
		});
		helpReport.activate.connect( () => {
			string auth_uri = "https://bugs.launchpad.net/beat-box";
			GLib.AppInfo.launch_default_for_uri (auth_uri, null);
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
		sideTree.row_activated.connect(sideListDoubleClick);
		previousButton.clicked.connect(previousClicked);
		playButton.clicked.connect(playClicked);
		nextButton.clicked.connect(nextClicked);
		shuffleButton.clicked.connect(shuffleClicked);
		loveButton.clicked.connect(loveButtonClicked);
		banButton.clicked.connect(banButtonClicked);
		topDisplay.scale_value_changed.connect(topDisplaySliderMoved);
		searchField.changed.connect(searchFieldChanged);
		searchField.icon_press.connect(searchFieldIconPressed);
		
		show_all();
		topMenu.hide();
		topDisplay.show_scale();
		topDisplay.set_scale_sensitivity(false);
		coverArt.hide();
		sideTree.resetView();
		songInfoScroll.hide();
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
		mtv.view_being_searched.connect(musicTreeViewSearched);
		sideTree.addItem(sideTree.playlists_iter, null, mtv, "Queue");
		mainViews.pack_start(mtv, true, true, 0);
		
		mtv = new MusicTreeView(lm, this, -1);
		mtv.set_hint("history");
		mtv.populateView(lm.already_played(), false);
		mtv.view_being_searched.connect(musicTreeViewSearched);
		sideTree.addItem(sideTree.playlists_iter, null, mtv, "History");
		mainViews.pack_start(mtv, true, true, 0);
		
		mtv = new MusicTreeView(lm, this, -1);
		mtv.set_hint("music");
		mtv.populateView(lm.song_ids(), false);
		mtv.view_being_searched.connect(musicTreeViewSearched);
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
		int index = 0;
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
		mtv.hide();
		mtv.view_being_searched.connect(musicTreeViewSearched);
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
		}
		else {
			topDisplay.set_scale_sensitivity(true);
			previousButton.set_sensitive(true);
			playButton.set_sensitive(true);
			nextButton.set_sensitive(true);
			searchField.set_sensitive(true);
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
				coverArt.set_from_pixbuf(new Gdk.Pixbuf.from_file_at_size(file, sourcesToSongs.position, sourcesToSongs.position));
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
		var song_label = "<b>" + lm.song_from_id(i).title + "</b>" + " by " + "<b>" + lm.song_from_id(i).artist + "</b>" + " on " + "<b>" +lm.song_from_id(i).album + "</b>";
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
		//notification.close();
		//notification.summary = lm.song_from_id(i).title;
		//notification.body = lm.song_from_id(i).artist + "\n" + lm.song_from_id(i).album;
		
		updateCurrentSong();
		
		//show the notifier
		//notification.show();
		
		sideTree.updatePlayQueue();
	}
	
	public virtual void songs_updated(Collection<int> ids) {
		if(lm.song_info.song != null && ids.contains(lm.song_info.song.rowid)) {
			var song_label = "<b>" + lm.song_info.song.title + "</b>" + " by " + "<b>" + lm.song_info.song.artist + "</b>" + " on " + "<b>" +lm.song_info.song.album + "</b>";
			topDisplay.set_label_markup(song_label);
		}
	}
	
	public void* lastfm_thread_function () {
		bool update_track = false, update_artist = false, update_album = false;
		LastFM.ArtistInfo artist = new LastFM.ArtistInfo.basic();
		LastFM.TrackInfo track = new LastFM.TrackInfo.basic();
		LastFM.AlbumInfo album = new LastFM.AlbumInfo.basic();
		
		if(lm.song_info.album.name != lm.song_info.song.album || lm.song_info.album.artist != lm.song_info.song.artist) {
			update_album = true;
			
			if(!lm.album_info_exists(lm.song_info.song.album + " by " + lm.song_info.song.artist)) {
				//stdout.printf("Downloading new Album Info from Last FM\n");
				album = new LastFM.AlbumInfo.with_info(lm.song_info.song.artist, lm.song_info.song.album);
				
				//try to save album image locally
				if(lm.get_album_location(lm.song_info.song.rowid) == null)
					lm.save_album_locally(lm.song_info.song.rowid, album.url_image.url);
				
				lm.save_album(album);
			}
			else {
				album = lm.get_album(lm.song_info.song.album + " by " + lm.song_info.song.artist);
				
				//if no local image saved, save it now
				if(lm.get_album_location(lm.song_info.song.rowid) == null)
					lm.save_album_locally(lm.song_info.song.rowid, album.url_image.url);
			}
		}
		if(lm.song_info.artist.name != lm.song_info.song.artist) {
			update_artist = true;
			
			if(!lm.artist_info_exists(lm.song_info.song.artist)) {
				//stdout.printf("Downloading new Artist Info from Last FM\n");
				artist = new LastFM.ArtistInfo.with_artist(lm.song_info.song.artist);
				
				//try to save artist art locally
				if(lm.get_album_location(lm.song_info.song.rowid) == null)
					lm.save_artist_image_locally(lm.song_info.song.rowid, artist.url_image.url);
				
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
			player.play_stream();
			
			lm.getNext(true);
		}
		else {
			if(lm.playing) {
				lm.playing = false;
				player.pause_stream();
				playButton.set_stock_id(Gtk.Stock.MEDIA_PLAY);
			}
			else {
				lm.playing = true;
				player.play_stream();
				playButton.set_stock_id(Gtk.Stock.MEDIA_PAUSE);
			}
		}
	}
	
	public virtual void nextClicked() {
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
	
	/** implement search in librarymanager?????? **/
	public virtual void searchFieldChanged() {
		Timeout.add(350, () => {
			//make sure we still want to search
			if(searchField.get_text() == timeout_search && !searchField.is_searching) {
				Collection<int> songs;
				MusicTreeView mtv = (MusicTreeView)sideTree.get_current_widget();
					
				songs = lm.songs_from_search(searchField.get_text(), mtv.get_songs());
				mtv.populateView(songs, true);
			}
			
			return false;
		});
	}
	
	public virtual void searchFieldIconPressed(EntryIconPosition p0, Gdk.Event p1) {
		Widget w = sideTree.getSelectedWidget();
		w.focus(DirectionType.UP);
	}
	
	public virtual void musicTreeViewSearched(string search) {
		//searchField.focus(DirectionType.UP);
		//searchField.set_text(search);
		//searchField.move_cursor(MovementStep.VISUAL_POSITIONS, 1, false);
	}
	
	public virtual void sourcesToSongsHandleSet(Gdk.Rectangle rectangle) {
		if(settings.getSidebarWidth() != rectangle.width)
			updateCurrentSong();
		
		settings.setSidebarWidth(rectangle.width);
	}
	
	public virtual void on_resize() {
		int width;
		int height;
		this.get_size(out width, out height);
		settings.setWindowWidth(width);
		settings.setWindowHeight(height);
	}
	
	public virtual void on_quit() {
		//the user will never know that we don't actually close in the speed of light :p
		this.hide();
		
		lm.settings.setLastSongPosition((int)topDisplay.get_scale_value());
		
		// save the columns
		var columns = new ArrayList<TreeViewColumn>();
		
		Widget w = sideTree.getWidget(sideTree.library_music_iter);
		if(w is MusicTreeView) {
			MusicTreeView view = (MusicTreeView)w;
			
			foreach(TreeViewColumn tvc in view.get_columns()) {
				columns.add(tvc);
			}
			
			lm.save_song_list_columns(columns);
		}
		
		stdout.printf("Stopping playback\n");
		player.pause_stream();
		
		stdout.printf("Saving songs\n");
		lm.save_songs();
		
		stdout.printf("Saving playlists\n");
		lm.save_playlists();
		lm.save_smart_playlists();
		
		stdout.printf("Saving LastFM Info\n");
		lm.save_artists();
		lm.save_albums();
		lm.save_tracks();
		
		stdout.printf("Bye\n");
	}
	
	public virtual void fileSetMusicFolderClick() {
		string folder = "";
		var file_chooser = new FileChooserDialog ("Choose Music Folder", this,
                                      FileChooserAction.SELECT_FOLDER,
                                      Gtk.Stock.CANCEL, ResponseType.CANCEL,
                                      Gtk.Stock.OPEN, ResponseType.ACCEPT);
        if (file_chooser.run () == ResponseType.ACCEPT) {
            folder = file_chooser.get_filename();
        }
        file_chooser.destroy ();
        
        if(folder != "") {
			//topDisplay.set_label_showing(true);
			topDisplay.set_label_text("Importing music from " + folder);
			//topDisplay.show_progressbar();
			//lm.set_music_folder(folder);
		}
		
	}
	
	public virtual void fileRescanMusicFolderClick() {
		//topDisplay.set_label_showing(true);
		topDisplay.set_label_markup("<b>Rescanning music folder for changes</b>");
		topDisplay.show_progressbar();
		
		lm.rescan_music_folder();
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
	}
	
	public virtual void musicRescanned(LinkedList<string> not_imported) {
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
	}
	
	public virtual void songRemovedFromManager(int id) {
		updateSensitivities();
	}
	
	public virtual void helpAboutClick() {
		AboutDialog ad = new AboutDialog();
		
		ad.set_program_name("BeatBox");
		ad.set_version("0.1");
		ad.set_website("https://launchpad.net/beat-box");
		ad.set_website_label("Launchpad");
		ad.set_authors({"Scott Ringwelski"});
		
		ad.response.connect( (response_id) => { 
			ad.destroy(); 
		});
		
		ad.show();
	}
	
	public virtual void editPreferencesClick() {
		PreferencesWindow pw = new PreferencesWindow(lm);
		
		pw.changed.connect( (folder) => {
			topDisplay.set_label_markup("<b>Importing</b> music from <b>" + folder + "</b>");
			topDisplay.show_progressbar();
		});
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
	
	public virtual void topDisplaySliderMoved(ScrollType scroll, double val) {
		//temporarily disable updates
		player.current_position_update.disconnect(current_position_update);
		
		player.seek_position((int64)(val * 1000000000));
		
		//re-enable streamplayer's updates
		this.player.current_position_update.connect(current_position_update);
	}
	
	public virtual void similarRetrieved(LinkedList<Song> similarDo, LinkedList<Song> similarDont) {
		LinkedList<int> similarIDs = new LinkedList<int>();
		
		foreach(Song s in similarDo) {
			similarIDs.add(s.rowid);
		}
		
		Widget w = sideTree.getWidget(sideTree.playlists_similar_iter);
		((SimilarPane)w).updateSongs(lm.song_info.song, similarIDs, similarDont);
	}
}
