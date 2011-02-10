using Gtk;

public class BeatBox.PreferencesWindow : Window {
	private BeatBox.LibraryManager _lm;
	
	private Gee.LinkedList<string> origLocations;
	private Gee.LinkedList<string> newLocations;
	Gee.LinkedList<string> removed; //as we find folders from before, remove them from removed.
	
	//for padding around notebook mostly
	private VBox vert;
	private HBox horiz;
	
	private Notebook notebook;
	private Viewport generalPage;
	private Viewport lastfmPage;
	
	private ScrolledWindow musicLocationsScroll;
	private TreeView musicLocationsView;
	private ListStore musicLocationsModel;
	private Button musicLocationsAdd;
	private Button musicLocationsRemove;
	private CheckButton updateFolderNames;
	private CheckButton copyImportedMusic;
	
	private Button lastfmLogin;
	
	private Button saveChanges;
	private Button cancelChanges;
	
	private string lastfm_token;
	
	public PreferencesWindow(LibraryManager lm) {
		this._lm = lm;
		origLocations = _lm.settings.getMusicFoldersList();
		
		buildUI();
	}
	
	public void buildUI() {
		// set the title
		set_title("Preferences");
		
		this.window_position = WindowPosition.CENTER;
		
		// set the size
		set_size_request(400, 300);
		allow_shrink = true;
		
		vert = new VBox(false, 10);
		horiz = new HBox(false, 10);
		notebook = new Notebook();
		generalPage = new Viewport(null, null);
		lastfmPage = new Viewport(null, null);
		
		musicLocationsScroll = new ScrolledWindow(null, null);
		musicLocationsView = new TreeView();
		musicLocationsModel = new ListStore(1, typeof(string));
		musicLocationsAdd = new Button.with_label("Add");
		musicLocationsRemove = new Button.with_label("Remove");
		updateFolderNames = new CheckButton.with_label("Update folder names based on Metadata");
		copyImportedMusic = new CheckButton.with_label("Copy imported music to music folder");
		
		Label lastfmInfo = new Label("To allow for scrobbling, love, bans, etc. in Last FM, you must give permission to BeatBox. You only need to do this once. It is a two-step process.");
		lastfmLogin = new Button.with_label("Enable Scrobbling");
		
		saveChanges = new Button.with_label("Save");
		cancelChanges = new Button.with_label("Cancel");
		
		/** build general page **/
		VBox genVert = new VBox(false, 3);
		notebook.append_page(generalPage, new Label("General"));
		generalPage.add(genVert);
		
		musicLocationsView.insert_column_with_attributes(-1, "Music Folder", new CellRendererText(), "text", 0, null);
		musicLocationsView.set_model(musicLocationsModel);
		
		foreach(string s in _lm.settings.getMusicFoldersList()) {
			TreeIter added;
			musicLocationsModel.append(out added);
			musicLocationsModel.set(added, 0, s);
		}
		
		musicLocationsScroll.add(musicLocationsView);
		musicLocationsScroll.set_policy(PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
		
		VBox musicFolderButtonsBox = new VBox(false, 0);
		musicFolderButtonsBox.pack_start(musicLocationsAdd, false, false, 0);
		musicFolderButtonsBox.pack_start(musicLocationsRemove, false, false, 0);
		
		HBox musicFolderBox = new HBox(false, 0);
		musicFolderBox.pack_start(musicLocationsScroll, true, true, 5);
		musicFolderBox.pack_start(musicFolderButtonsBox, false, false, 0);
		
		updateFolderNames.set_active(_lm.settings.getUpdateFolderHierarchy());
		copyImportedMusic.set_active(_lm.settings.getCopyImportedMusic());
		
		genVert.pack_start(musicFolderBox, true, true, 0);
		genVert.pack_start(updateFolderNames, false, true, 0);
		genVert.pack_start(copyImportedMusic, false, true, 0);
		
		/** build lastfm page **/
		VBox lastfmVert = new VBox(false, 3);
		notebook.append_page(lastfmPage, new Label("Last FM"));
		lastfmPage.add(lastfmVert);
		
		lastfmInfo.set_line_wrap(true);
		
		lastfmVert.pack_start(lastfmInfo, false, true, 0);
		lastfmVert.pack_start(lastfmLogin, false, true, 0);
		
		lastfmLogin.clicked.connect(lastfmLoginClick);
		
		/** Add save and cancel buttons **/
		HButtonBox bottomButtons = new HButtonBox();
		bottomButtons.pack_start(cancelChanges, false, false, 0);
		bottomButtons.pack_end(saveChanges, false, false, 0);
		
		/** put it all together **/
		vert.pack_start(notebook, true, true, 0);
		vert.pack_start(bottomButtons, false, true, 0);
		
		horiz.pack_start(vert, true, true, 10);
		
		this.add(horiz);
		show_all();
		
		saveChanges.clicked.connect(saveClicked);
		cancelChanges.clicked.connect(cancelClicked);
		musicLocationsAdd.clicked.connect(musicLocationsAddClicked);
		musicLocationsRemove.clicked.connect(musicLocationsRemoveClicked);
	}
	
	public virtual void lastfmLoginClick() {
		if(_lm.settings.getLastFMSessionKey() != "")
			stdout.printf("We already have a key this is pointless...\n");
		
		if(lastfmLogin.get_label() == "Enable Scrobbling" || lastfmLogin.get_label() == "Unsuccessful. Click to try again.") {
			lastfm_token = _lm.lfm.getToken();
			if(lastfm_token == null) {
				lastfmLogin.set_label("Unsuccessful. Click to try again.");
				stdout.printf("Could not get a token. check internet connection\n");
			}
			else {
				string auth_uri = "http://www.last.fm/api/auth/?api_key=" + LastFM.Core.api + "&token=" + lastfm_token;
				GLib.AppInfo.launch_default_for_uri (auth_uri, null);
				
				//set button text. we are done this time around. next time we get session key
				lastfmLogin.set_label("Complete login");
			}
		}
		else {
			if(lastfm_token == null) {
				lastfmLogin.set_label("Unsuccessful. Click to try again.");
				stdout.printf("Invalid token. Cannot continue\n");
			}
			else {
				var sk = _lm.lfm.getSessionKey(lastfm_token);
				if(sk == null) {
					lastfmLogin.set_label("Unsuccessful. Click to try again.");
					stdout.printf("Could not get Last FM session key\n");
				}
				else {
					_lm.settings.setLastFMSessionKey(sk);
					stdout.printf("Successfully obtained a sessionkey\n");
					lastfmLogin.set_sensitive(false);
					lastfmLogin.set_label("Success!");
				}
			}
		}
	}
	
	public virtual void musicLocationsAddClicked() {
		string folder = "";
		var file_chooser = new FileChooserDialog ("Add Music Folder", this,
                                      FileChooserAction.SELECT_FOLDER,
                                      Gtk.Stock.CANCEL, ResponseType.CANCEL,
                                      Gtk.Stock.OPEN, ResponseType.ACCEPT);
        if (file_chooser.run () == ResponseType.ACCEPT) {
            folder = file_chooser.get_filename();
        }
        file_chooser.destroy ();
        
        if(folder != "") {
			TreeIter added;
			musicLocationsModel.append(out added);
			musicLocationsModel.set(added, 0, folder);
		}
	}
	
	public virtual void musicLocationsRemoveClicked() {
		TreeModel model;
		TreeIter iter;
		musicLocationsView.get_selection().get_selected(out model, out iter);
		
		musicLocationsModel.remove(iter);
	}
		
	public bool buildFoldersChanges(TreeModel model, TreePath path, TreeIter iter) {
		string loc;
		model.get(iter, 0, out loc);
		
		newLocations.add(loc);
		
		if(loc in origLocations)
			removed.remove(loc);
			
		return false;
	}
		
	public virtual void saveClicked() {
		/** loop through all strings in locations view. if a folder was
		 * removed, remove all those songs first. then go through all the new
		 * folders that were added and add the files from there
		 */
		
		removed = origLocations; //as we find folders from before, remove them from removed.
		newLocations = new Gee.LinkedList<string>();
		musicLocationsModel.foreach(buildFoldersChanges);
		
		_lm.settings.setMusicFoldersFromList(newLocations);
		
		/* remove songs belonging to the folders that were removed */
		var removed_songs = new Gee.LinkedList<int>();
		foreach(Song s in _lm.songs()) {
			bool remove = false;
			foreach(string removeLoc in removed) {
				if(removeLoc in s.file) {
					remove = true;
					stdout.printf("removed:%s in %s\n", s.file, removeLoc);
					break;
				}
			}
			
			if(remove)
				removed_songs.add(s.rowid);
		}
		
		foreach(int id in removed_songs) {
			_lm.remove_song_from_id(id);
		}
		
		//consolidate files lazily
		//save new songs to db and reload
		_lm.save_songs();
		_lm.clear_songs();
		foreach(Song s in _lm.dbm.load_songs()) {
			_lm.add_song(s);
		}
		
		//now rescan the folders
		_lm.rescan_music_folders();
		
		_lm.settings.setUpdateFolderHierarchy(updateFolderNames.get_active());
		stdout.printf("no setting for copying imported music\n");
		this.destroy();
	}
	
	public virtual void cancelClicked() {
		this.destroy();
	}
}
