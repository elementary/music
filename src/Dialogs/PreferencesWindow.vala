/*-
 * Copyright (c) 2011-2012       Scott Ringwelski <sgringwe@mtu.edu>
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

/* Merely a place holder for multiple pieces of information regarding
 * the current media playing. Mostly here because of dependence. */

using Gtk;

public class BeatBox.PreferencesWindow : Gtk.Window {
	BeatBox.LibraryManager _lm;
	BeatBox.LibraryWindow _lw;

	FileChooserButton fileChooser;
	
	CheckButton organizeFolders;
	CheckButton writeMetadataToFile;
	CheckButton copyImportedMusic;

	Button saveChanges;

#if HAVE_PODCASTS
	CheckButton downloadNewPodcasts;
#endif

#if HAVE_LAST_FM
	Button lastfmLogin;
	string lastfm_token;

	private string SUCCESS_MSG = _("Success!");
	private string ENABLE_SCROBBLING_MSG = _("Enable Scrobbling");
	private string UNSUCCESSFUL_MSG = _("Unsuccessful. Click to try again.");
#endif
	
	public signal void changed(string folder);
	
	public PreferencesWindow (LibraryManager lm, LibraryWindow lw) {
	
		this._lm = lm;
		this._lw = lw;
		
		build_ui();
		
		_lm.file_operations_done.connect(fileOperationsDone);
	}
	
	void build_ui () {
	
		set_title(_("Preferences"));

		// Window properties
		window_position = WindowPosition.CENTER;
		type_hint = Gdk.WindowTypeHint.DIALOG;
		modal = true;
		resizable = false;
		set_transient_for(_lw);
		set_size_request(400, -1);

		var content = new VBox(false, 10);
		var padding = new HBox(false, 10);
		
		var musicLabel = new Label("");
		fileChooser = new FileChooserButton(_("Music Folder"), FileChooserAction.SELECT_FOLDER);
		
		var managementLabel = new Label("");
		organizeFolders = new CheckButton.with_label(_("Keep music folder organized"));
		writeMetadataToFile = new CheckButton.with_label(_("Write metadata to file"));
		copyImportedMusic = new CheckButton.with_label(_("Copy files to music folder when added to library"));
#if HAVE_PODCASTS
		downloadNewPodcasts = new CheckButton.with_label(_("Automatically download new podcast episodes"));
#endif

#if HAVE_LAST_FM
		var lastfmLabel = new Label("");
		var lastfmInfo = new Granite.Widgets.WrapLabel(_("To allow for Last.fm integration, you must give permission to %s. You only need to do this once.").printf (lw.app.get_name ()));
		
		if(_lm.settings.getLastFMSessionKey() == null || _lm.settings.getLastFMSessionKey() == "")
			lastfmLogin = new Button.with_label (ENABLE_SCROBBLING_MSG);
		else {
			lastfmLogin = new Button.with_label (_("Scrobbling already Enabled"));
			lastfmLogin.set_tooltip_text (_("Click to redo the Last.fm Login Process"));
		}
#endif
		
		saveChanges = new Button.with_label(_("Close"));
		
		// fancy up the category labels
		musicLabel.xalign = 0.0f;
		managementLabel.xalign = 0.0f;
		musicLabel.set_markup ("<b>%s</b>".printf (_("Music Folder Location")));
		managementLabel.set_markup("<b>%s</b>".printf (_("Library Management")));

#if HAVE_LAST_FM
		lastfmLabel.xalign = 0.0f;
		lastfmLabel.set_markup("<b>%s</b>".printf (_("Last.fm Integration")));
#endif		
		// file chooser stuff
		fileChooser.set_current_folder(_lm.settings.getMusicFolder());
		//fileChooser.set_local_only(true);
		
		if (_lm.doing_file_operations()) {
			fileChooser.set_sensitive(false);
			fileChooser.set_tooltip_text(_("You must wait until previous file operations finish before setting your music folder"));
		}
		
		// initialize library management settings
		organizeFolders.set_active(_lm.settings.getUpdateFolderHierarchy());
		writeMetadataToFile.set_active(_lm.settings.getWriteMetadataToFile());
		copyImportedMusic.set_active(_lm.settings.getCopyImportedMusic());
#if HAVE_PODCASTS
		downloadNewPodcasts.set_active(_lm.settings.getDownloadNewPodcasts());
#endif

#if HAVE_LAST_FM	
		lastfmInfo.set_line_wrap(true);
#endif
		
		// Add save button
		var bottomButtons = new HButtonBox();
		bottomButtons.set_layout(ButtonBoxStyle.END);
		bottomButtons.pack_end(saveChanges, false, false, 0);
		
		// Pack all widgets
		content.pack_start(UI.wrap_alignment (musicLabel, 10, 0, 0, 0), false, true, 0);
		content.pack_start(UI.wrap_alignment (fileChooser, 0, 0, 0, 10), false, true, 0);
		content.pack_start(managementLabel, false, true, 0);
		content.pack_start(UI.wrap_alignment (organizeFolders, 0, 0, 0, 10), false, true, 0);
		content.pack_start(UI.wrap_alignment (writeMetadataToFile, 0, 0, 0, 10), false, true, 0);
		content.pack_start(UI.wrap_alignment (copyImportedMusic, 0, 0, 0, 10), false, true, 0);
#if HAVE_PODCASTS
		content.pack_start(UI.wrap_alignment (downloadNewPodcasts, 0, 0, 0, 10), false, true, 0);
#endif
#if HAVE_LAST_FM
		content.pack_start(lastfmLabel, false, true, 0);
		content.pack_start(UI.wrap_alignment (lastfmInfo, 0, 0, 0, 10), false, true, 0);
		content.pack_start(UI.wrap_alignment (lastfmLogin, 0, 0, 0, 10), false, true, 0);
#endif
		content.pack_end(bottomButtons, false, true, 10);
		
		padding.pack_start(content, true, true, 10);
		add(padding);

#if HAVE_LAST_FM		
		lastfmLogin.clicked.connect(lastfmLoginClick);
#endif
		saveChanges.clicked.connect(saveClicked);
		
		show_all();
	}
	

#if HAVE_LAST_FM
	void lastfmLoginClick() {
	
		if(lastfmLogin.get_label() == ENABLE_SCROBBLING_MSG || lastfmLogin.get_label() == UNSUCCESSFUL_MSG) {
			lastfm_token = _lm.lfm.getToken();
			if(lastfm_token == null) {
				lastfmLogin.set_label(UNSUCCESSFUL_MSG);
				stdout.printf("Could not get a token. check internet connection\n");
			}
			else {
				string auth_uri = "http://www.last.fm/api/auth/?api_key=" + LastFM.Core.api + "&token=" + lastfm_token;
				try {
					GLib.AppInfo.launch_default_for_uri (auth_uri, null);
				}
				catch(GLib.Error err) {
					stdout.printf("Could not open Last.fm website to authorize: %s\n", err.message);
				}
				
				//set button text. we are done this time around. next time we get session key
				lastfmLogin.set_label(_("Complete login"));
			}
		}
		else {
			if(lastfm_token == null) {
				lastfmLogin.set_label(UNSUCCESSFUL_MSG);
				stdout.printf("Invalid token. Cannot continue\n");
			}
			else {
				var sk = _lm.lfm.getSessionKey(lastfm_token);
				if(sk == null) {
					lastfmLogin.set_label(UNSUCCESSFUL_MSG);
					stdout.printf("Could not get Last.fm session key\n");
				}
				else {
					_lm.settings.setLastFMSessionKey(sk);
					_lm.lfm.session_key = sk;
					_lm.lfm.logged_in();
					stdout.printf("Successfully obtained a sessionkey\n");
					lastfmLogin.set_sensitive(false);
					lastfmLogin.set_label(SUCCESS_MSG);
				}
			}
		}
	}
#endif
		
	void saveClicked() {
	
		if(fileChooser.get_current_folder() != _lm.settings.getMusicFolder() || _lm.media_count() == 0) {
			changed(fileChooser.get_current_folder());
		}
		
		_lm.settings.setUpdateFolderHierarchy(organizeFolders.get_active());
		_lm.settings.setWriteMetadataToFile(writeMetadataToFile.get_active());
		_lm.settings.setCopyImportedMusic(copyImportedMusic.get_active());
#if HAVE_PODCASTS
		_lm.settings.setDownloadNewPodcasts(downloadNewPodcasts.get_active());
#endif
		
		destroy();
	}

	void fileOperationsDone () {
	
		fileChooser.set_tooltip_text("");
		fileChooser.set_sensitive(true);
	}
}
