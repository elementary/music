using Gtk;

public class BeatBox.PreferencesWindow : Window {
	private BeatBox.LibraryManager _lm;
	string music_folder_choice;
	
	//for padding around notebook mostly
	private VBox content;
	private HBox padding;
	
	//category labels
	private Label musicLabel;
	private Label managementLabel;
	private Label lastfmLabel;
	
	private ListStore musicFolderList;
	private ComboBox musicFolderCombo;
	
	private CheckButton organizeFolders;
	private CheckButton copyImportedMusic;
	
	private Button lastfmLogin;
	private Label lastfmInfo;
	
	private Button saveChanges;
	
	private string lastfm_token;
	
	public PreferencesWindow(LibraryManager lm) {
		this._lm = lm;
		
		buildUI();
		
		/* Generate music folder combobox items */
		TreeIter iter;
		musicFolderList.append(out iter);
		musicFolderList.set(iter, 0, this.render_icon("music-library", Gtk.IconSize.MENU, null), 1, "Music");
		musicFolderList.append(out iter);
		musicFolderList.set(iter, 0, null, 1, "Other");
	}
	
	public void buildUI() {
		// set the title
		set_title("Preferences");
		
		this.window_position = WindowPosition.CENTER;
		
		// set the size
		set_size_request(400, 300);
		allow_shrink = true;
		
		content = new VBox(false, 10);
		padding = new HBox(false, 10);
		
		musicLabel = new Label("Music Folder Location");
		musicFolderList = new ListStore(2, typeof(Gdk.Pixbuf), typeof(string));
		musicFolderCombo = new ComboBox.with_model(musicFolderList);
		
		managementLabel = new Label("Library Management");
		organizeFolders = new CheckButton.with_label("Keep Music folder organized");
		copyImportedMusic = new CheckButton.with_label("Copy files to Music folder when added to Library");
		
		lastfmLabel = new Label("Last FM Integration");
		lastfmInfo = new Label("To allow for Last FM integration, you must give permission to BeatBox. You only need to do this once.");
		lastfmLogin = new Button.with_label("Enable Scrobbling");
		
		saveChanges = new Button.with_label("Close");
		
		/* have to put in cell renderers ourselves */
		CellRenderer cell;

        cell = new CellRendererPixbuf();
        musicFolderCombo.pack_start(cell, false);
        musicFolderCombo.set_attributes(cell, "pixbuf", 0);
		
		cell = new CellRendererText();
        musicFolderCombo.pack_end(cell, true);
        musicFolderCombo.set_attributes(cell, "text", 1);
		
		/* fancy up the category labels */
		musicLabel.xalign = 0.0f;
		managementLabel.xalign = 0.0f;
		lastfmLabel.xalign = 0.0f;
		musicLabel.set_markup("<b>Music Folder Location</b>");
		managementLabel.set_markup("<b>Library Management</b>");
		lastfmLabel.set_markup("<b>Last FM Integration</b>");
		
		/* initialize library management settings */
		organizeFolders.set_active(_lm.settings.getUpdateFolderHierarchy());
		copyImportedMusic.set_active(_lm.settings.getCopyImportedMusic());
		
		lastfmInfo.set_line_wrap(true);
		
		/** Add save and cancel buttons **/
		HButtonBox bottomButtons = new HButtonBox();
		bottomButtons.set_layout(ButtonBoxStyle.END);
		bottomButtons.pack_end(saveChanges, false, false, 0);
		
		/** put it all together **/
		content.pack_start(wrap_alignment(musicLabel, 10, 0, 0, 0), false, true, 0);
		content.pack_start(wrap_alignment(musicFolderCombo, 0, 0, 0, 10), false, true, 0);
		content.pack_start(managementLabel, false, true, 0);
		content.pack_start(wrap_alignment(organizeFolders, 0, 0, 0, 10), false, true, 0);
		content.pack_start(wrap_alignment(copyImportedMusic, 0, 0, 0, 10), false, true, 0);
		content.pack_start(lastfmLabel, false, true, 0);
		content.pack_start(wrap_alignment(lastfmInfo, 0, 0, 0, 10), false, true, 0);
		content.pack_start(wrap_alignment(lastfmLogin, 0, 0, 0, 10), false, true, 0);
		content.pack_end(bottomButtons, false, true, 10);
		
		padding.pack_start(content, true, true, 10);
		
		this.add(padding);
		show_all();
		
		musicFolderCombo.changed.connect(comboItemChanged);
		lastfmLogin.clicked.connect(lastfmLoginClick);
		saveChanges.clicked.connect(saveClicked);
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
	
	public virtual void comboItemChanged() {
		TreeIter active;
		string title;
		musicFolderCombo.get_active_iter(out active);
		musicFolderList.get(active, 1, out title);
		
		if(title == "Other") {
			var file_chooser = new FileChooserDialog ("Choose Music Folder", this,
										  FileChooserAction.SELECT_FOLDER,
										  Gtk.Stock.CANCEL, ResponseType.CANCEL,
										  Gtk.Stock.OPEN, ResponseType.ACCEPT);
			if (file_chooser.run () == ResponseType.ACCEPT) {
				music_folder_choice = file_chooser.get_filename();
			}
			file_chooser.destroy ();
		}
		else if(title == "Music") {
			stdout.printf("TODO: Set to xdg (or w/e it is) music folder\n");
		}
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
		
	public virtual void saveClicked() {
		if(music_folder_choice != _lm.settings.getMusicFolder()) {
			_lm.set_music_folder(music_folder_choice);
		}
		
		_lm.settings.setUpdateFolderHierarchy(organizeFolders.get_active());
		stdout.printf("no setting for copying imported music\n");
		this.destroy();
	}
	
	public virtual void cancelClicked() {
		this.destroy();
	}
}
