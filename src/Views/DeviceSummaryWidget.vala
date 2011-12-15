using Gtk;

public class BeatBox.DeviceSummaryWidget : ScrolledWindow {
	LibraryManager lm;
	LibraryWindow lw;
	Device dev;
	
	Granite.Widgets.HintedEntry deviceName;
	CheckButton syncAtStart;
	CheckButton syncMusic;
	CheckButton syncPodcasts;
	CheckButton syncAudiobooks;
	ComboBox musicDropdown;
	ComboBox podcastDropdown;
	ComboBox audiobookDropdown;
	ListStore musicList;
	ListStore podcastList;
	ListStore audiobookList;
	
	Gtk.Image deviceImage;
	SpaceWidget spaceWidget;
	Button syncButton;
	
	public DeviceSummaryWidget(LibraryManager lm, LibraryWindow lw, Device d) {
		this.lm = lm;
		this.lw = lw;
		this.dev = d;
		
		buildUI();
	}
	
	public void buildUI() {
		// options at top
		deviceName = new Granite.Widgets.HintedEntry("Device Name");
		syncAtStart = new CheckButton.with_label("Automatically sync when mounted");
		syncMusic = new CheckButton.with_label("Sync Music with");
		syncPodcasts = new CheckButton.with_label("Sync Podcasts with");
		syncAudiobooks = new CheckButton.with_label("Sync Audiobooks with");
		musicDropdown = new ComboBox();
		podcastDropdown = new ComboBox();
		audiobookDropdown = new ComboBox();
		musicList = new ListStore(2, typeof(GLib.Object), typeof(string));
		podcastList = new ListStore(2, typeof(GLib.Object), typeof(string));
		audiobookList = new ListStore(2, typeof(GLib.Object), typeof(string));
		
		deviceImage = new Gtk.Image.from_gicon(dev.get_icon(), IconSize.DIALOG);
		spaceWidget = new SpaceWidget((double)dev.get_capacity());
		syncButton = new Button.with_label("Sync");
		
		Label deviceNameLabel = new Label("Device Name:");
		Label syncOptionsLabel = new Label("Sync Options:");
		
		var content = new VBox(false, 10);
		
		setupLists();
		
		setupSpaceWidget();
		
		// create layout
		var deviceNameBox = new HBox(true, 6);
		deviceNameBox.pack_start(deviceNameLabel, false, true, 0);
		deviceNameBox.pack_start(deviceName, false, true, 0);
		
		/* music box */
		var musicBox = new HBox(false, 6);
		musicBox.pack_start(syncMusic, false, false, 0);
		musicBox.pack_start(musicDropdown, false, false, 0);
		/* podcast box */
		var podcastBox = new HBox(false, 6);
		podcastBox.pack_start(syncPodcasts, false, false, 0);
		podcastBox.pack_start(podcastDropdown, false, false, 0);
		/* audiobook box */
		var audiobookBox = new HBox(false, 6);
		audiobookBox.pack_start(syncAudiobooks, false, false, 0);
		audiobookBox.pack_start(audiobookDropdown, false, false, 0);
		
		/* vbox of all checkboxes */
		var syncOptionsBox = new VBox(false, 0);
		syncOptionsBox.pack_start(syncAtStart, false, false, 0);
		syncOptionsBox.pack_start(musicBox, false, false, 0);
		
		if(dev.supports_podcasts())
			syncOptionsBox.pack_start(podcastBox, false, false, 0);
		if(dev.supports_audiobooks())
			syncOptionsBox.pack_start(audiobookBox, false, false, 0);
		
		/* has list of sync options */
		var syncHBox = new HBox(true, 6);
		syncHBox.pack_start(syncOptionsLabel, false, true, 0);
		syncHBox.pack_start(syncOptionsBox, false, true, 0);
		
		// create bottom section
		var syncButtonBox = new VBox(false, 0);
		syncButtonBox.pack_end(syncButton, false, false, 0);
		
		var bottomBox = new HBox(false, 0);
		bottomBox.pack_start(deviceImage, false, true, 0);
		bottomBox.pack_start(spaceWidget, true, true, 0);
		bottomBox.pack_start(syncButtonBox, false, false, 0);
		
		// put it all together
		content.pack_start(deviceNameBox, false, true, 0);
		content.pack_start(syncHBox, false, true, 0);
		content.pack_end(bottomBox, false, true, 0);
		
		add_with_viewport(wrap_alignment(content, 15, 10, 10, 10));
		
		deviceNameLabel.xalign = 1.0f;
		deviceName.halign = Align.START;
		if(dev.getDisplayName() != "")
			deviceName.set_text(dev.getDisplayName());
		
		syncOptionsLabel.yalign = 0.0f;
		syncOptionsLabel.xalign = 1.0f;
		syncOptionsBox.halign = Align.START;
		
		set_policy(PolicyType.AUTOMATIC, PolicyType.NEVER);
		spaceWidget.set_size_request(-1, 20);
		
		refreshLists();
		
		// set initial values
		syncAtStart.active = dev.get_preferences().sync_when_mounted;
		syncMusic.active = dev.get_preferences().sync_music;
		syncPodcasts.active = dev.get_preferences().sync_podcasts;
		syncAudiobooks.active = dev.get_preferences().sync_audiobooks;
		
		if(dev.get_preferences().sync_all_music)
			musicDropdown.set_active(0);
		else {
			bool success = musicDropdown.set_active_id(dev.get_preferences().music_playlist);
			if(!success) {
				lw.doAlert("Missing Sync Playlist", "The playlist named <b>" + dev.get_preferences().music_playlist + "</b> is used to sync device <b>" + dev.getDisplayName() + "</b>, but could not be found.");
				dev.get_preferences().music_playlist = "";
				dev.get_preferences().sync_all_music = true;
				musicDropdown.set_active(0);
			}
		}
		if(dev.get_preferences().sync_all_podcasts)
			podcastDropdown.set_active(0);
		else {
			bool success = podcastDropdown.set_active_id(dev.get_preferences().podcast_playlist);
			if(!success) {
				lw.doAlert("Missing Sync Playlist", "The playlist named <b>" + dev.get_preferences().podcast_playlist + "</b> is used to sync device <b>" + dev.getDisplayName() + "</b>, but could not be found.");
				dev.get_preferences().podcast_playlist = "";
				dev.get_preferences().sync_all_podcasts = true;
				podcastDropdown.set_active(0);
			}
		}
		if(dev.get_preferences().sync_all_audiobooks)
			audiobookDropdown.set_active(0);
		else {
			bool success = audiobookDropdown.set_active_id(dev.get_preferences().audiobook_playlist);
			if(!success) {
				lw.doAlert("Missing Sync Playlist", "The playlist named <b>" + dev.get_preferences().audiobook_playlist + "</b> is used to sync device <b>" + dev.getDisplayName() + "</b>, but could not be found.");
				dev.get_preferences().audiobook_playlist = "";
				dev.get_preferences().sync_all_audiobooks = true;
				audiobookDropdown.set_active(0);
			}
		}
		
		// hop onto signals to save preferences
		syncAtStart.toggled.connect(savePreferences);
		syncMusic.toggled.connect(savePreferences);
		syncPodcasts.toggled.connect(savePreferences);
		syncAudiobooks.toggled.connect(savePreferences);
		musicDropdown.changed.connect(savePreferences);
		podcastDropdown.changed.connect(savePreferences);
		audiobookDropdown.changed.connect(savePreferences);
		
		deviceName.changed.connect(deviceNameChanged);
		syncButton.clicked.connect(syncClicked);
		
		show_all();
	}
	
	void setupSpaceWidget() {
		double song_size = 0.0; double podcast_size = 0.0; double audiobook_size = 0.0;
		
		foreach(int i in dev.get_songs()) {
			song_size += (double)(lm.song_from_id(i).file_size * 1000000);
		}
		foreach(int i in dev.get_podcasts()) {
			podcast_size += (double)(lm.song_from_id(i).file_size * 1000000);
		}
		foreach(int i in dev.get_audiobooks()) {
			audiobook_size += (double)(lm.song_from_id(i).file_size * 1000000);
		}
		
		spaceWidget.add_item("Songs", song_size, 0, 0, 128);
		spaceWidget.add_item("Podcasts", podcast_size, 255, 165, 0);
		spaceWidget.add_item("Audiobooks", audiobook_size, 255, 0, 0);
	}
	
	void setupLists() {
		musicDropdown.set_model(musicList);
		podcastDropdown.set_model(podcastList);
		audiobookDropdown.set_model(audiobookList);
		
		musicDropdown.set_id_column(1);
		podcastDropdown.set_id_column(1);
		audiobookDropdown.set_id_column(1);
		
		musicDropdown.set_row_separator_func(rowSeparatorFunc);
		podcastDropdown.set_row_separator_func(rowSeparatorFunc);
		audiobookDropdown.set_row_separator_func(rowSeparatorFunc);
		
		var cell = new CellRendererText();
		cell.ellipsize = Pango.EllipsizeMode.END;
		musicDropdown.pack_start(cell, true);
		musicDropdown.add_attribute(cell, "text", 1);
		podcastDropdown.pack_start(cell, true);
		podcastDropdown.add_attribute(cell, "text", 1);
		audiobookDropdown.pack_start(cell, true);
		audiobookDropdown.add_attribute(cell, "text", 1);
		
		musicDropdown.popup.connect(refreshLists);
		podcastDropdown.popup.connect(refreshLists);
		audiobookDropdown.popup.connect(refreshLists);
	}
	
	bool rowSeparatorFunc(TreeModel model, TreeIter iter) {
		string sep = "";
		model.get(iter, 1, out sep);
		
		return sep == "<separator_item_unique_name>";
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
	
	void deviceNameChanged() {
		dev.setDisplayName(deviceName.get_text());
	}
	
	void savePreferences() {
		var pref = dev.get_preferences();
		
		pref.sync_when_mounted = syncAtStart.active;
		pref.sync_music = syncMusic.active;
		pref.sync_podcasts = syncPodcasts.active;
		pref.sync_audiobooks = syncAudiobooks.active;
		
		pref.sync_all_music = musicDropdown.get_active() == 0;
		pref.sync_all_podcasts = podcastDropdown.get_active() == 0;
		pref.sync_all_audiobooks = audiobookDropdown.get_active() == 0;
		
		pref.music_playlist = musicDropdown.get_active_id();
		pref.podcast_playlist = podcastDropdown.get_active_id();
		pref.audiobook_playlist = audiobookDropdown.get_active_id();
		
		lm.save_device_preferences();
	}
	
	public bool allSongsSelected() {
		return false;
	}
	
	public void refreshLists() {
		stdout.printf("refreshing lists\n");
		string musicString = musicDropdown.get_active_id();
		string podcastString = podcastDropdown.get_active_id();
		string audiobookString = audiobookDropdown.get_active_id();
		
		TreeIter iter;
		musicList.clear();
		podcastList.clear();
		audiobookList.clear();
		
		/* add entire library options */
		musicList.append(out iter);
		musicList.set(iter, 0, null, 1, "Entire Music Library");
		podcastList.append(out iter);
		podcastList.set(iter, 0, null, 1, "Entire Podcast Library");
		audiobookList.append(out iter);
		audiobookList.set(iter, 0, null, 1, "Entire Audiobook Library");
		
		/* add separator */
		musicList.append(out iter);
		musicList.set(iter, 0, null, 1, "<separator_item_unique_name>");
		podcastList.append(out iter);
		podcastList.set(iter, 0, null, 1, "<separator_item_unique_name>");
		audiobookList.append(out iter);
		audiobookList.set(iter, 0, null, 1, "<separator_item_unique_name>");
		
		/* add all playlists */
		foreach(var p in lm.smart_playlists()) {
			musicList.append(out iter);
			musicList.set(iter, 0, p, 1, p.name);
			podcastList.append(out iter);
			podcastList.set(iter, 0, p, 1, p.name);
			audiobookList.append(out iter);
			audiobookList.set(iter, 0, p, 1, p.name);
		}
		foreach(var p in lm.playlists()) {
			musicList.append(out iter);
			musicList.set(iter, 0, p, 1, p.name);
			podcastList.append(out iter);
			podcastList.set(iter, 0, p, 1, p.name);
			audiobookList.append(out iter);
			audiobookList.set(iter, 0, p, 1, p.name);
		}
		
		if(!musicDropdown.set_active_id(musicString))
			musicDropdown.set_active(0);
		if(!podcastDropdown.set_active_id(podcastString))
			podcastDropdown.set_active(0);
		if(!audiobookDropdown.set_active_id(audiobookString))
			audiobookDropdown.set_active(0);
	}
	
	void syncClicked() {
		Gee.LinkedList<int> list = new Gee.LinkedList<int>();
		var pref = dev.get_preferences();
		
		if(pref.sync_music) {
			if(pref.sync_all_music) {
				foreach(var s in lm.songs()) {
					if(s.mediatype == 0)
						list.add(s.rowid);
				}
			}
			else {
				var p = lm.playlist_from_name(pref.music_playlist);
				
				if(p != null) {
					foreach(int i in p.songs()) {
						if(lm.song_from_id(i).mediatype == 0)
							list.add(i);
					}
				}
				else {
					lw.doAlert("Sync Failed", "The playlist named <b>" + pref.music_playlist + "</b> is used to sync device <b>" + dev.getDisplayName() + "</b>, but could not be found.");
					pref.music_playlist = "";
					pref.sync_all_music = true;
					musicDropdown.set_active(0);
					return;
				}
			}
		}
		if(pref.sync_podcasts) {
			if(pref.sync_all_podcasts) {
				foreach(var s in lm.songs()) {
					if(s.mediatype == 1)
						list.add(s.rowid);
				}
			}
			else {
				var p = lm.playlist_from_name(pref.podcast_playlist);
				
				if(p != null) {
					foreach(int i in p.songs()) {
						if(lm.song_from_id(i).mediatype == 1)
							list.add(i);
					}
				}
				else {
					lw.doAlert("Sync Failed", "The playlist named <b>" + pref.podcast_playlist + "</b> is used to sync device <b>" + dev.getDisplayName() + "</b>, but could not be found.");
					pref.podcast_playlist = "";
					pref.sync_all_podcasts = true;
					musicDropdown.set_active(0);
					return;
				}
			}
		}
		if(pref.sync_audiobooks) {
			if(pref.sync_all_audiobooks) {
				foreach(var s in lm.songs()) {
					if(s.mediatype == 2)
						list.add(s.rowid);
				}
			}
			else {
				var p = lm.playlist_from_name(pref.audiobook_playlist);
				
				if(p != null) {
					foreach(int i in p.songs()) {
						if(lm.song_from_id(i).mediatype == 2)
							list.add(i);
					}
				}
				else {
					lw.doAlert("Sync Failed", "The playlist named <b>" + pref.audiobook_playlist + "</b> is used to sync device <b>" + dev.getDisplayName() + "</b>, but could not be found.");
					pref.audiobook_playlist = "";
					pref.sync_all_audiobooks = true;
					musicDropdown.set_active(0);
					return;
				}
			}
		}
		
		bool fits = dev.will_fit(list);
		if(!fits) {
			lw.doAlert("Cannot Sync", "Cannot Sync Device with selected sync settings. Not enough space on disk\n");
		}
		else if(dev.is_syncing()) {
			lw.doAlert("Cannot Sync", "Device is already being synced.");
		}
		else {
			dev.sync_songs(list);
		}
	}
}
