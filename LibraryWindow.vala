using Gtk;
using Gee;
using WebKit;
using Notify;

public class BeatBox.LibraryWindow : Gtk.Window {
	BeatBox.LibraryManager lm;
	BeatBox.Settings settings;
	BeatBox.StreamPlayer player;
	
	string current_view_path;
	bool queriedlastfm; // whether or not we have queried last fm for the current song info
	bool song_considered_played; //whether or not we have updated last played and added to already played list
	bool added_to_play_count; // whether or not we have added one to play count on playing song
	bool loaded_pandora;
	bool loaded_groove_shark;
	
	VBox verticalBox;
	VBox mainViews;
	HPaned sourcesToSongs; //allows for draggable
	ScrolledWindow sideTreeScroll;
	VBox sideBar;
	SideTreeView sideTree;
	ScrolledWindow songInfoScroll;
	ScrolledWindow pandoraScroll;
	ScrolledWindow grooveSharkScroll;
	WebView songInfo;
	WebView pandora;
	WebView grooveShark;
	Image coverArt;
	HBox topControls;
	Button previousButton;
	Button playButton;
	Button nextButton;
	Button shuffleButton;
	Button loveButton;
	Button banButton;
	EventBox songPositionEvent;
	ProgressBar songPosition;
	ElementaryWidgets.ElementarySearchEntry searchField;
	ElementaryWidgets.AppMenu appMenu;
	Statusbar statusBar;
	ProgressBar statusBarProgress;
	
	MenuBar topMenu;
	
	// basic file stuff
	Menu fileMenu;
	MenuItem fileMenuItem;
	MenuItem fileSetMusicFolder;
	MenuItem fileRescanMusicFolder;
	Menu editMenu;
	MenuItem editMenuItem;
	MenuItem editPreferences;
	
	Menu settingsMenu;
	
	//Notify.Notification notification;
	
	public LibraryWindow(BeatBox.DataBaseManager dbm, BeatBox.StreamPlayer player) {
		settings = new BeatBox.Settings();
		this.player = player;
		
		//this is used by many objects, is the media backend
		lm = new BeatBox.LibraryManager(player, dbm, settings);
		
		build_ui();
		
		this.player.end_of_stream.connect(end_of_stream);
		this.player.current_position_update.connect(current_position_update);
		this.lm.music_added.connect(musicAdded);
		this.lm.music_rescanned.connect(musicRescanned);
		this.lm.progress_notification.connect(progressNotification);
		this.lm.song_removed.connect(songRemovedFromManager);
		this.lm.song_played.connect(song_played);
		destroy.connect (on_quit);
		check_resize.connect(on_resize);
		this.destroy.connect (Gtk.main_quit);
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
		verticalBox = new VBox(false, 4);
		sourcesToSongs = new HPaned();
		mainViews = new VBox(false, 4);
		sideTree = new SideTreeView(lm, this);	
		sideTreeScroll = new ScrolledWindow(null, null);	
		topMenu = new MenuBar();
		fileMenu = new Menu();
		fileMenuItem = new MenuItem.with_label("File");
		fileSetMusicFolder = new MenuItem.with_label("Set Music Folder");
		fileRescanMusicFolder = new MenuItem.with_label("Rescan Music Folder");
		editMenu = new Menu();
		editMenuItem = new MenuItem.with_label("Edit");
		editPreferences = new MenuItem.with_label("Preferences");
		settingsMenu = new Menu();
		topControls = new HBox(false, 5);
		previousButton = new Button();
		playButton = new Button();
		nextButton = new Button();
		shuffleButton = new Button.with_label("shuffle");
		loveButton = new Button.with_label("Love");
		banButton = new Button.with_label("Ban");
		songPositionEvent = new EventBox();
		songPosition = new ProgressBar();
		searchField = new ElementaryWidgets.ElementarySearchEntry("Search...");
		appMenu = new ElementaryWidgets.AppMenu.from_stock(Gtk.Stock.PROPERTIES, Gtk.IconSize.MENU, "Menu", settingsMenu);
		songInfoScroll = new ScrolledWindow(null, null);
		pandoraScroll = new ScrolledWindow(null, null);
		grooveSharkScroll = new ScrolledWindow(null, null);
		songInfo = new WebView();
		pandora = new WebView();
		grooveShark = new WebView();
		sideBar = new VBox(false, 2);
		coverArt = new Image.from_file(Environment.get_home_dir () + "/.beatbox/default_cover.jpg");
		statusBar = new Statusbar();
		statusBarProgress = new ProgressBar();
		//notification = new Notification("Title", "Artist\nAlbum", "", null);
		
		/* Set properties of various controls */
		sourcesToSongs.child1_resize = 1;
		sideBar.set_size_request(settings.getSidebarWidth(), -1);
		buildSideTree();
		
		previousButton.relief = Gtk.ReliefStyle.NONE;
		previousButton.image = new Gtk.Image.from_stock(Gtk.Stock.MEDIA_PREVIOUS, Gtk.IconSize.SMALL_TOOLBAR);
		playButton.relief = Gtk.ReliefStyle.NONE;
		playButton.image = new Gtk.Image.from_stock(Gtk.Stock.MEDIA_PLAY, Gtk.IconSize.SMALL_TOOLBAR);
		nextButton.relief = Gtk.ReliefStyle.NONE;
		nextButton.image = new Gtk.Image.from_stock(Gtk.Stock.MEDIA_NEXT, Gtk.IconSize.SMALL_TOOLBAR);
		shuffleButton.relief = Gtk.ReliefStyle.NONE;
		//shuffleButton.image = new Gtk.Image.from_stock(Gtk.Stock.MEDIA_SHUFFLE, Gtk.IconSize.SMALL_TOOLBAR);
		loveButton.relief = Gtk.ReliefStyle.NONE;
		banButton.relief = Gtk.ReliefStyle.NONE;
		
		songPositionEvent.add(songPosition);
		songPositionEvent.child = songPosition;
		songPosition.set_sensitive(false);
		
		if(lm.song_count() != 0)
			searchField.set_sensitive(true);
		else
			searchField.set_sensitive(false);
		
		settingsMenu.append(fileSetMusicFolder);
		settingsMenu.append(fileRescanMusicFolder);
		settingsMenu.append(editPreferences);
		
		fileSetMusicFolder.activate.connect(fileSetMusicFolderClick);
		fileRescanMusicFolder.activate.connect(fileRescanMusicFolderClick);
		editPreferences.activate.connect(editPreferencesClick);
		
		songInfo.open("file://"+Environment.get_home_dir () + "/.beatbox/song_info.html");
		
		statusBar.has_resize_grip = true;
		
		/* Add controls to the GUI */
		add(verticalBox);
		verticalBox.pack_start(topMenu, false, true, 0);
		verticalBox.pack_start(topControls, false, true, 1);
        verticalBox.pack_start(sourcesToSongs, true, true, 1);
        verticalBox.pack_start(statusBar, false, true, 0);
        		
		topControls.pack_start(previousButton, false, false, 1);
		topControls.pack_start(playButton, false, false, 1);
		topControls.pack_start(nextButton, false, false, 1);
		topControls.pack_start(shuffleButton, false, false, 1);
		topControls.pack_start(songPositionEvent, true, true, 1);
		topControls.pack_start(searchField, false, false, 1);
		topControls.pack_start(appMenu, false, false, 1);
		
		//set the name for elementary theming
		sourcesToSongs.name = "SidebarHandleLeft";
		sideTree.name = "SidebarContent";
		
		sourcesToSongs.add1(sideBar);
		sourcesToSongs.add2(mainViews);
		
		songInfoScroll.add(songInfo);
		pandoraScroll.add(pandora);
		grooveSharkScroll.add(grooveShark);
		
		sideBar.pack_start(sideTreeScroll, true, true, 1);
		sideBar.pack_end(coverArt, false, true, 1);
		
		statusBar.pack_start(statusBarProgress);
		
		/* Connect events to functions */
		sourcesToSongs.child1.size_allocate.connect(sourcesToSongsHandleSet);
		sideTree.row_activated.connect(sideListDoubleClick);
		previousButton.clicked.connect(previousClicked);
		playButton.clicked.connect(playClicked);
		nextButton.clicked.connect(nextClicked);
		shuffleButton.clicked.connect(shuffleClicked);
		loveButton.clicked.connect(loveButtonClicked);
		banButton.clicked.connect(banButtonClicked);
		songPositionEvent.button_press_event.connect(onSongPositionButtonPress);
		searchField.activate.connect(searchFieldActivated);
		
		show_all();
		topMenu.hide();
		statusBarProgress.hide();
		coverArt.hide();
		sideTree.resetView();
	}
	
	/** Builds the side tree on TreeView view
	 * @param view The side tree to build it on
	 */
	private void buildSideTree() {
		MusicTreeView mtv;
		
		// put song info first so it is on top when using multiple views
		sideTree.addItem(null, new GLib.Object(), songInfoScroll, "Song Info");
		mainViews.pack_start(songInfoScroll, true, true, 0);
		
		mtv = new MusicTreeView(lm, this, -1);
		mtv.set_hint("collection");
		mtv.populateView(lm.song_ids(), false);
		sideTree.addItem(null, new GLib.Object(), mtv, "Collection");
		mainViews.pack_start(mtv, true, true, 0);
		
		mtv = new MusicTreeView(lm, this, -1);
		mtv.set_hint("queue");
		mtv.populateView(lm.queue(), false);
		sideTree.addItem(null, new GLib.Object(), mtv, "Queue");
		mainViews.pack_start(mtv, true, true, 0);
		
		mtv = new MusicTreeView(lm, this, -1);
		mtv.set_hint("already played");
		mtv.populateView(lm.already_played(), false);
		sideTree.addItem(null, new GLib.Object(), mtv, "Already Played");
		mainViews.pack_start(mtv, true, true, 0);
		
		sideTree.addBasicItems();
		
		//why should i have internet sources on a music player???
		//I should just concentrate on playing local music files
		/*pandora
		sideTree.addItem(sideTree.get_internet_iter(), new GLib.Object(), pandoraScroll, "Pandora");
		mainViews.pack_start(pandoraScroll, true, true, 0);
		
		//groooveshark
		sideTree.addItem(sideTree.get_internet_iter(), new GLib.Object(), grooveSharkScroll, "Groove Shark");
		mainViews.pack_start(grooveSharkScroll, true, true, 0);*/
		
		// load smart playlists
		foreach(SmartPlaylist p in lm.smart_playlists()) {
			addSideListItem(p);
		}
		
		// load playlists
		foreach(Playlist p in lm.playlists()) {
			addSideListItem(p);
		}
		
		
		sideTree.get_selection().select_iter(sideTree.get_collection_iter());
		sideTree.sideListSelectionChange();
		sideTree.expand_all();
		
		sideTreeScroll = new ScrolledWindow(null, null);
		sideTreeScroll.set_policy (PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
		sideTreeScroll.add(sideTree);
	}
	
	public void addSideListItem(GLib.Object o) {
		TreeIter item = sideTree.get_collection_iter();
		int index = 0;
		MusicTreeView mtv = null;
		
		if(o is Playlist) {
			Playlist p = (Playlist)o;
			
			mtv = new MusicTreeView(lm, this, -1);
			mtv.set_hint("playlist");
			mtv.set_id(p.rowid);
			mtv.populateView(lm.songs_from_playlist(p.rowid), false);
			item = sideTree.addItem(sideTree.get_playlist_iter(), p, mtv, p.name);
			mainViews.pack_start(mtv, true, true, 0);
		}
		else if(o is SmartPlaylist) {
			SmartPlaylist p = (SmartPlaylist)o;
			
			mtv = new MusicTreeView(lm, this, -1);
			mtv.set_hint("smart playlist");
			mtv.set_id(p.rowid);
			mtv.populateView(lm.songs_from_smart_playlist(p.rowid), false);
			item = sideTree.addItem(sideTree.get_playlist_iter(), p, mtv, p.name);
			mainViews.pack_start(mtv, true, true, 0);
		}
		
		mtv.show();
		show_all();
		sideTree.get_selection().unselect_all();
		sideTree.get_selection().select_iter(item);
	}
	
	public virtual void progressNotification(string message, double progress) {
		if(message != "") {
			statusBar.pop(0);
			statusBar.push(0, message);
		}
		
		if(progress != 0.0) {
			statusBarProgress.set_fraction(progress);
		}
	}
	
	public virtual void sideListDoubleClick (TreePath path, TreeViewColumn column) {
		
	}
	
	public bool updateCurrentSong() {
		//loop through all musictreeviews and call updatecurrentsong
		
		string file = "";
		if((file = lm.get_album_location(lm.song_info.song.rowid)) != null) {
			coverArt.show();
			coverArt.set_from_file(file);
		}
		else if(lm.song_info.album.url_image.image != null) {
			coverArt.show();
			coverArt.set_from_pixbuf(lm.song_info.album.url_image.image);
		}
		else
			coverArt.hide();
		
		return false;
	}
	
	/** This should be used whenever a call to play a new song is made
	 * @param s The song that is now playing
	 */
	public virtual void song_played(int i) {
		//set the title
		var title = lm.song_from_id(i).title + " by " + lm.song_from_id(i).artist + " - BeatBox";
		this.set_title(title);
		
		//reset the song position
		songPosition.set_fraction(0.0);
		
		if(!songPosition.get_sensitive())
			songPosition.set_sensitive(true);
		
		//reset some booleans
		queriedlastfm = false;
		song_considered_played = false;
		added_to_play_count = false;
		
		
		//update the notifier
		//notification.close();
		//notification.summary = lm.song_from_id(i).title;
		//notification.body = lm.song_from_id(i).artist + "\n" + lm.song_from_id(i).album;
		
		//look for album art
		string file = "";
		if((file = lm.get_album_location(lm.song_info.song.rowid)) != null) {
			coverArt.show();
			coverArt.set_from_pixbuf(new LastFM.Image.with_url("file://" + file, true).image);
			//notification.set_image_from_pixbuf(new Gdk.Pixbuf.from_file(file));
		}
		else {
			//notification.set_image_from_pixbuf(new Gdk.Pixbuf.from_file(Environment.get_home_dir () + "/.beatbox/default_cover.jpg"));
			coverArt.hide();
		}
		
		//show the notifier
		//notification.show();
		
		sideTree.updatePlayQueue();
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
				w = sideTree.getWidget(sideTree.get_collection_iter());
				((MusicTreeView)w).setAsCurrentList("0");
			}
			
			lm.playing = true;
			playButton.image = new Gtk.Image.from_stock(Gtk.Stock.MEDIA_PAUSE, Gtk.IconSize.SMALL_TOOLBAR);
			player.play_stream();
			
			lm.getNext(true);
		}
		else {
			if(lm.playing) {
				lm.playing = false;
				player.pause_stream();
				playButton.image = new Gtk.Image.from_stock(Gtk.Stock.MEDIA_PLAY, Gtk.IconSize.SMALL_TOOLBAR);
			}
			else {
				lm.playing = true;
				player.play_stream();
				playButton.image = new Gtk.Image.from_stock(Gtk.Stock.MEDIA_PAUSE, Gtk.IconSize.SMALL_TOOLBAR);
			}
		}
	}
	
	public virtual void nextClicked() {
		lm.getNext(true);
	}
	
	public virtual void shuffleClicked() {
		lm.shuffleMusic();
	}
	
	public virtual void loveButtonClicked() {
		lm.lfm.loveTrack(lm.song_info.song.title, lm.song_info.song.artist);
	}
	
	public virtual void banButtonClicked() {
		lm.lfm.banTrack(lm.song_info.song.title, lm.song_info.song.artist);
	}
	
	/** implement search in librarymanager?????? **/
	public virtual void searchFieldActivated () {
			Collection<int> songs;
			
			if(sideTree.get_current_widget() is MusicTreeView) {
				MusicTreeView mtv = (MusicTreeView)sideTree.get_current_widget();
				
				songs = lm.songs_from_search(searchField.text, mtv.get_songs());
				mtv.populateView(songs, true);
			}
	}
	
	public virtual void sourcesToSongsHandleSet(Gdk.Rectangle rectangle) {
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
		// save the columns
		var columns = new ArrayList<TreeViewColumn>();
		Widget w = sideTree.getWidget(sideTree.get_collection_iter());
		
		foreach(TreeViewColumn tvc in ((MusicTreeView)w).get_columns()) {
			columns.add(tvc);
		}
		
		lm.save_song_list_columns(columns);
		
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
			statusBar.push(0, "Importing music from " + folder + ". This may take a while");
			statusBarProgress.show();
			lm.set_music_folder(folder);
		}
		
	}
	
	public virtual void fileRescanMusicFolderClick() {
		statusBar.push(0, "Rescanning music. This may take a while");
		lm.rescan_music_folder();
		statusBarProgress.show();
	}
	
	public virtual void musicAdded() {
		int index = 0;
		
		sideTree.resetView();
		
		statusBarProgress.set_fraction(0.0);
		statusBar.pop(0);
		statusBarProgress.hide();
		
		//repopulate collection and playlists and reset queue and already played
		
		if(lm.song_count() != 0)
			searchField.set_sensitive(true);
		else
			searchField.set_sensitive(false);
	}
	
	public virtual void musicRescanned() {
		statusBarProgress.set_fraction(0.0);
		statusBar.pop(0);
		statusBarProgress.hide();
		
		sideTree.resetView();
		
		if(lm.song_count() != 0)
			searchField.set_sensitive(true);
		else
			searchField.set_sensitive(false);
	}
	
	public virtual void songRemovedFromManager(int id) {
		if(lm.song_count() != 0)
			searchField.set_sensitive(true);
		else
			searchField.set_sensitive(false);
	}
	
	public virtual void editPreferencesClick() {
		PreferencesWindow pw = new PreferencesWindow(lm);
		
	}
	
	public virtual void end_of_stream(Song s) {
		nextClicked();
	}
	
	public virtual void current_position_update(int64 position) {
		double newpos = 0.0;
		if(lm.song_info.song != null) {
			newpos = ((double)position/1000000000)/lm.song_info.song.length;
			
			if(newpos >= 0.0 && newpos <= 1.0)
				songPosition.set_fraction(newpos);
			
			//make pretty current position
			string current, total;
			int minute = 0;
			int seconds = (int)((double)position/1000000000);
			
			while(seconds >= 60) {
				++minute;
				seconds -= 60;
			}
			current = minute.to_string() + ":" + ((seconds < 10 ) ? "0" + seconds.to_string() : seconds.to_string());
			
			//make pretty total time
			minute = 0;
			seconds = lm.song_info.song.length;
			
			while(seconds >= 60) {
				++minute;
				seconds -= 60;
			}
			total = minute.to_string() + ":" + ((seconds < 10 ) ? "0" + seconds.to_string() : seconds.to_string());
			
			songPosition.set_text(current + "/" + total);
			
			// at about 5 seconds, update last fm. we wait to avoid excessive querying last.fm for info
			if(position > 5000000000 && !queriedlastfm) {
				queriedlastfm = true;
				try {
					Thread.create<void*>(lastfm_thread_function, false);
				}
				catch(GLib.ThreadError err) {
					stdout.printf("ERROR: Could not create last fm thread: %s \n", err.message);
				}
				
			}
			
			//at 30 seconds in, we consider the song as played
			if(position > 30000000000 && !song_considered_played) {
				song_considered_played = true;
				
				lm.song_info.song.last_played = (int)time_t();
				lm.update_song(lm.song_info.song);
				
				// add to the already played list
				lm.add_already_played(lm.song_info.song.rowid);
				sideTree.updateAlreadyPlayed();
			}
			
			// at 90% done with song, add 1 to play count
			if(newpos > 0.90 && !added_to_play_count) {
				added_to_play_count = true;
				lm.song_info.song.play_count++;
				updateCurrentSong();
			}
			
		}
		else {
			
		}
	}
	
	public virtual bool onSongPositionButtonPress(Gdk.EventButton event) {
		player.current_position_update.disconnect(current_position_update);
		if(event.type == Gdk.EventType.BUTTON_PRESS) { //mouse click
			//seek to right position
			//calculate percentage to go to based on location
			Gtk.Allocation extents;
			int point_x = 0;
			int point_y = 0;
			
			songPositionEvent.get_pointer(out point_x, out point_y);
			songPositionEvent.get_allocation(out extents);
			
			// get seconds of song
			double songtime = (double)((double)point_x/(double)extents.width) * (double)lm.song_info.song.length;
			int64 nanoseconds = (int64)songtime * (int64)1000000000;
			
			player.seek_position(nanoseconds);
			songPosition.fraction = (double)point_x / (double)extents.width;
		}
		this.player.current_position_update.connect(current_position_update);
		return true;
    }
}
