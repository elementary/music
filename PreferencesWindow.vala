using Gtk;

public class BeatBox.PreferencesWindow : Window {
	private BeatBox.LibraryManager _lm;
	private string origMusicFolder;
	
	private Notebook notebook;
	private Viewport generalPage;
	private Viewport lastfmPage;
	
	private Entry musicFolderEntry;
	private Button browseForMusicFolderButton;
	private CheckButton writeToMetaData;
	private CheckButton updateFolderNames;
	private CheckButton copyImportedMusic;
	
	private Button lastfmLogin;
	
	private string lastfm_token;
	
	public PreferencesWindow(LibraryManager lm) {
		this._lm = lm;
		origMusicFolder = _lm.settings.getMusicFolder();
		
		buildUI();
		destroy.connect(on_quit);
	}
	
	public void buildUI() {
		
		// set the title
		set_title("Preferences");
		
		// set the size
		set_size_request(250, 150);
		allow_shrink = true;
		
		notebook = new Notebook();
		generalPage = new Viewport(null, null);
		lastfmPage = new Viewport(null, null);
		
		musicFolderEntry = new Entry();
		browseForMusicFolderButton = new Button.with_label("...");
		writeToMetaData = new CheckButton.with_label("Write to Metadata");
		updateFolderNames = new CheckButton.with_label("Update folder names based on Metadata");
		copyImportedMusic = new CheckButton.with_label("Copy imported music to music folder");
		
		Label lastfmInfo = new Label("To allow for scrobbling, love, bans, etc. in Last FM, you must give permission to BeatBox. You only need to do this once. It is a two-step process.");
		lastfmLogin = new Button.with_label("Enable Scrobbling");
		
		/** build general page **/
		VBox genVert = new VBox(false, 3);
		notebook.append_page(generalPage, new Label("General"));
		generalPage.add(genVert);
		
		HBox musicFolderBox = new HBox(false, 1);
		musicFolderBox.pack_start(new Label("Music Folder:"), false, false, 0);
		musicFolderBox.pack_start(musicFolderEntry, false, true, 0);
		musicFolderBox.pack_start(browseForMusicFolderButton, false, false, 0);
		musicFolderEntry.set_text(_lm.settings.getMusicFolder());
		
		writeToMetaData.set_active(_lm.settings.getWriteToMetadata());
		updateFolderNames.set_active(_lm.settings.getUpdateFolderHierarchy());
		copyImportedMusic.set_active(_lm.settings.getCopyImportedMusic());
		
		genVert.pack_start(musicFolderBox, false, true, 0);
		genVert.pack_start(writeToMetaData, false, true, 0);
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
		
		this.add(notebook);
		show_all();
	}
	
	public virtual void lastfmLoginClick() {
		if(_lm.settings.getLastFMSessionKey() != "")
			stdout.printf("we already have a key this is pointless...\n");
		
		if(lastfmLogin.get_label() == "Enable Scrobbling") {
			lastfm_token = _lm.lfm.getToken();
			if(lastfm_token == null)
				stdout.printf("could not get a token. check internet connection\n");
			else {
				string auth_uri = "http://www.last.fm/api/auth/?api_key=" + LastFM.Core.api + "&token=" + lastfm_token;
				GLib.AppInfo.launch_default_for_uri (auth_uri, null);
				
				//set button text. we are done this time around. next time we get session key
				lastfmLogin.set_label("Complete login");
			}
		}
		else {
			if(lastfm_token == null)
				stdout.printf("Invalid token. Cannot continue\n");
			else {
				var sk = _lm.lfm.getSessionKey(lastfm_token);
				if(sk == null) {
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
	
	public virtual void on_quit() {
		_lm.settings.setMusicFolder(musicFolderEntry.get_text());
		
		if(musicFolderEntry.get_text() != origMusicFolder)
			_lm.set_music_folder(musicFolderEntry.get_text());
			
		_lm.settings.setWriteToMetadata(writeToMetaData.get_active());
		_lm.settings.setUpdateFolderHierarchy(updateFolderNames.get_active());
		stdout.printf("no setting for copying imported music\n");
	}
}
