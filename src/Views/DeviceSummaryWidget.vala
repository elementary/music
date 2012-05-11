/*-
 * Copyright (c) 2011-2012       Scott Ringwelski <sgringwe@mtu.edu>
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

public class BeatBox.DeviceSummaryWidget : VBox {
	LibraryManager lm;
	LibraryWindow lw;
	Device dev;
	
	Granite.Widgets.HintedEntry deviceName;
	Switch syncAtStart;
	
	CheckButton syncMusic;
#if HAVE_PODCASTS
	CheckButton syncPodcasts;
#endif
	//CheckButton syncAudiobooks;
	ComboBox musicDropdown;
#if HAVE_PODCASTS
	ComboBox podcastDropdown;
#endif
	//ComboBox audiobookDropdown;
	ListStore musicList;
#if HAVE_PODCASTS
	ListStore podcastList;
#endif
	//ListStore audiobookList;
	
	Gtk.Image deviceImage;
	SpaceWidget spaceWidget;
	
	int files_index;
	int music_index;
	int podcast_index;

	//int audiobook_index;
	
	public DeviceSummaryWidget(LibraryManager lm, LibraryWindow lw, Device d) {
		this.lm = lm;
		this.lw = lw;
		this.dev = d;
		
		buildUI();
	}
	
	public void buildUI() {
		// options at top
		deviceName = new Granite.Widgets.HintedEntry(_("Device Name"));
		syncAtStart = new Gtk.Switch();
		syncMusic = new CheckButton();
#if HAVE_PODCASTS
		syncPodcasts = new CheckButton();
#endif
		//syncAudiobooks = new CheckButton();
		musicDropdown = new ComboBox();
#if HAVE_PODCASTS
		podcastDropdown = new ComboBox();
#endif
		//audiobookDropdown = new ComboBox();
		musicList = new ListStore(3, typeof(GLib.Object), typeof(string), typeof(Gdk.Pixbuf));
#if HAVE_PODCASTS
		podcastList = new ListStore(3, typeof(GLib.Object), typeof(string), typeof(Gdk.Pixbuf));
#endif
		//audiobookList = new ListStore(3, typeof(GLib.Object), typeof(string), typeof(Gdk.Pixbuf));
		
		deviceImage = new Gtk.Image.from_gicon(dev.get_icon(), IconSize.DIALOG);
		spaceWidget = new SpaceWidget((double)dev.get_capacity()/1000000);

		Label deviceNameLabel = new Label(_("Device Name:"));
		Label autoSyncLabel = new Label(_("Automatically sync when plugged in:"));
		Label syncOptionsLabel = new Label(_("Sync:"));
		
		var content = new VBox(false, 10);
		
		setupLists();

		files_index = spaceWidget.add_item(_("Other Files"), 0.0, SpaceWidget.ItemColor.GREEN);
		music_index = spaceWidget.add_item(_("Music"), 0.0, SpaceWidget.ItemColor.BLUE);
		podcast_index = spaceWidget.add_item(_("Podcasts"), 0.0, SpaceWidget.ItemColor.PURPLE);
		//audiobook_index = spaceWidget.add_item("Audiobooks", 0.0, SpaceWidget.ItemColor.GREEN);
		
		refreshSpaceWidget();
		
		// device name box
		var deviceNameBox = new HBox(true, 6);
		deviceNameBox.pack_start(deviceNameLabel, false, true, 0);
		deviceNameBox.pack_start(deviceName, false, true, 0);
		
		// auto sync box
		var autoSyncBox = new HBox(true, 6);
		autoSyncBox.pack_start(autoSyncLabel, false, true, 0);
		autoSyncBox.pack_start(wrap_alignment(syncAtStart, 0, 0, 0, 0), false, true, 0);
		
		// sync options box
		var musicBox = new HBox(false, 6);
		musicBox.pack_start(syncMusic, false, false, 0);
		musicBox.pack_start(musicDropdown, false, false, 0);

#if HAVE_PODCASTS
		var podcastBox = new HBox(false, 6);
		podcastBox.pack_start(syncPodcasts, false, false, 0);
		podcastBox.pack_start(podcastDropdown, false, false, 0);
#endif
		
		//var audiobookBox = new HBox(false, 6);
		//audiobookBox.pack_start(syncAudiobooks, false, false, 0);
		//audiobookBox.pack_start(audiobookDropdown, false, false, 0);
		
		var syncOptionsBox = new VBox(false, 0);
		syncOptionsBox.pack_start(musicBox, false, false, 0);
#if HAVE_PODCASTS
		if(dev.supports_podcasts()) 	syncOptionsBox.pack_start(podcastBox, false, false, 0);
#endif
		//if(dev.supports_audiobooks()) 	syncOptionsBox.pack_start(audiobookBox, false, false, 0);
		
		var syncHBox = new HBox(true, 6);
		syncHBox.pack_start(syncOptionsLabel, false, true, 0);
		syncHBox.pack_start(syncOptionsBox, false, true, 0);
		
		// create bottom section
		//var syncBox = new VBox(false, 0);
		//var syncButtonBox = new VButtonBox();
		//syncButtonBox.set_layout(ButtonBoxStyle.END);
		//syncButtonBox.pack_end(syncButton, false, false, 0);
		//syncBox.pack_end(syncButton, false, false, 0);
		
		//var bottomBox = new HBox(false, 0);
		//bottomBox.pack_start(deviceImage, false, true, 0);
		//bottomBox.pack_start(spaceWidgetScroll, true, true, 0);
		//bottomBox.pack_start(syncButtonBox, false, false, 0);
		
		// put it all together
		content.pack_start(deviceNameBox, false, true, 0);
		content.pack_start(autoSyncBox, false, true, 0);
		content.pack_start(syncHBox, false, true, 0);
		
		/* put it in event box so we can color background white */
		EventBox eb = new EventBox();
		
		eb.add(new Label("test"));

		// add content-view styling
		eb.get_style_context ().add_class (Granite.STYLE_CLASS_CONTENT_VIEW);
		
		//var content_plus_spacewidget = new Box(Orientation.VERTICAL, 0);
		this.set_border_width(0);
		this.pack_start(wrap_alignment(content, 15, 10, 10, 10), true, true, 0);
		this.pack_end(spaceWidget, false, true, 0);
		//this.pack_end(eb, false, true, 0);
		
		//add_with_viewport(content_plus_spacewidget);//wrap_alignment(content, 15, 10, 10, 10));
		
		deviceNameLabel.xalign = 1.0f;
		deviceName.halign = Align.START;
		if(dev.getDisplayName() != "")
			deviceName.set_text(dev.getDisplayName());
			
		autoSyncLabel.xalign = 1.0f;
		syncAtStart.halign = Align.START;
		
		syncOptionsLabel.yalign = 0.0f;
		syncOptionsLabel.xalign = 1.0f;
		syncOptionsBox.halign = Align.START;
		
		//set_policy(PolicyType.AUTOMATIC, PolicyType.NEVER);
		
		refreshLists();
		
		// set initial values
		syncAtStart.active = dev.get_preferences().sync_when_mounted;
		syncMusic.active = dev.get_preferences().sync_music;
#if HAVE_PODCASTS
		syncPodcasts.active = dev.get_preferences().sync_podcasts;
#endif
		//syncAudiobooks.active = dev.get_preferences().sync_audiobooks;
		
		if(dev.get_preferences().sync_all_music)
			musicDropdown.set_active(0);
		else {
			bool success = musicDropdown.set_active_id(dev.get_preferences().music_playlist);
			if(!success) {
				//lw.doAlert("Missing Sync Playlist", "The playlist named <b>" + dev.get_preferences().music_playlist + "</b> is used to sync device <b>" + dev.getDisplayName() + "</b>, but could not be found.");
				dev.get_preferences().music_playlist = "";
				dev.get_preferences().sync_all_music = true;
				musicDropdown.set_active(0);
			}
		}

#if HAVE_PODCASTS
		if(dev.get_preferences().sync_all_podcasts)
			podcastDropdown.set_active(0);

		else {
			bool success = podcastDropdown.set_active_id(dev.get_preferences().podcast_playlist);
			if(!success) {
				//lw.doAlert("Missing Sync Playlist", "The playlist named <b>" + dev.get_preferences().podcast_playlist + "</b> is used to sync device <b>" + dev.getDisplayName() + "</b>, but could not be found.");
				dev.get_preferences().podcast_playlist = "";
				dev.get_preferences().sync_all_podcasts = true;
				podcastDropdown.set_active(0);
			}
		}
#endif

		/*if(dev.get_preferences().sync_all_audiobooks)
			audiobookDropdown.set_active(0);
		else {
			bool success = audiobookDropdown.set_active_id(dev.get_preferences().audiobook_playlist);
			if(!success) {
				//lw.doAlert("Missing Sync Playlist", "The playlist named <b>" + dev.get_preferences().audiobook_playlist + "</b> is used to sync device <b>" + dev.getDisplayName() + "</b>, but could not be found.");
				dev.get_preferences().audiobook_playlist = "";
				dev.get_preferences().sync_all_audiobooks = true;
				audiobookDropdown.set_active(0);
			}
		}*/
		
		// hop onto signals to save preferences
		syncAtStart.notify["active"].connect(savePreferences);
		syncMusic.toggled.connect(savePreferences);
#if HAVE_PODCASTS
		syncPodcasts.toggled.connect(savePreferences);
#endif
		//syncAudiobooks.toggled.connect(savePreferences);
		musicDropdown.changed.connect(savePreferences);
#if HAVE_PODCASTS
		podcastDropdown.changed.connect(savePreferences);
#endif
		//audiobookDropdown.changed.connect(savePreferences);
		
		deviceName.changed.connect(deviceNameChanged);
		spaceWidget.sync_clicked.connect(syncClicked);
		dev.sync_finished.connect(sync_finished);
		
		show_all();
	}
	
	void refreshSpaceWidget() {
		double other_files_size = 0.0;
		double music_size = 0.0;
#if HAVE_PODCASTS
		double podcast_size = 0.0;
#endif
		//double audiobook_size = 0.0;


		foreach(int i in dev.get_songs()) {
			music_size += (double)(lm.media_from_id(i).file_size);
		}
#if HAVE_PODCASTS
		foreach(int i in dev.get_podcasts()) {
			podcast_size += (double)(lm.media_from_id(i).file_size);
		}
#endif

#if HAVE_PODCASTS
		// Get other used space
		other_files_size = (double)dev.get_used_space()/1000000 - music_size - podcast_size;
#else
		other_files_size = (double)dev.get_used_space()/1000000 - music_size;
#endif
		//foreach(int i in dev.get_audiobooks()) {
		//	audiobook_size += (double)(lm.media_from_id(i).file_size);
		//}
		
		spaceWidget.update_item_size(music_index, music_size);
#if HAVE_PODCASTS
		spaceWidget.update_item_size(podcast_index, podcast_size);
#endif
		spaceWidget.update_item_size(files_index, other_files_size);
		//spaceWidget.update_item_size(audiobook_index, audiobook_size);
	}
	
	void setupLists() {
		musicDropdown.set_model(musicList);
#if HAVE_PODCASTS
		podcastDropdown.set_model(podcastList);
#endif
		//audiobookDropdown.set_model(audiobookList);
		
		musicDropdown.set_id_column(1);
#if HAVE_PODCASTS
		podcastDropdown.set_id_column(1);
#endif
		//audiobookDropdown.set_id_column(1);
		
		musicDropdown.set_row_separator_func(rowSeparatorFunc);
#if HAVE_PODCASTS
		podcastDropdown.set_row_separator_func(rowSeparatorFunc);
#endif
		//audiobookDropdown.set_row_separator_func(rowSeparatorFunc);
		
		var music_cell = new CellRendererPixbuf();
		musicDropdown.pack_start(music_cell, false);
		musicDropdown.add_attribute(music_cell, "pixbuf", 2);
#if HAVE_PODCASTS
		podcastDropdown.pack_start(music_cell, false);
		podcastDropdown.add_attribute(music_cell, "pixbuf", 2);
#endif
		//audiobookDropdown.pack_start(music_cell, false);
		//audiobookDropdown.add_attribute(music_cell, "pixbuf", 2);
		
		var cell = new CellRendererText();
		cell.ellipsize = Pango.EllipsizeMode.END;
		musicDropdown.pack_start(cell, true);
		musicDropdown.add_attribute(cell, "text", 1);
#if HAVE_PODCASTS
		podcastDropdown.pack_start(cell, true);
		podcastDropdown.add_attribute(cell, "text", 1);
#endif
		//audiobookDropdown.pack_start(cell, true);
		//audiobookDropdown.add_attribute(cell, "text", 1);
		
		musicDropdown.popup.connect(refreshLists);
#if HAVE_PODCASTS
		podcastDropdown.popup.connect(refreshLists);
#endif
		//audiobookDropdown.popup.connect(refreshLists);
		
		musicDropdown.set_button_sensitivity(SensitivityType.ON);
#if HAVE_PODCASTS
		Dropdown.set_button_sensitivity(SensitivityType.ON);
#endif
		//audiobookDropdown.set_button_sensitivity(SensitivityType.ON);
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
#if HAVE_PODCASTS
		pref.sync_podcasts = syncPodcasts.active;
#endif
		//pref.sync_audiobooks = syncAudiobooks.active;
		
		pref.sync_all_music = musicDropdown.get_active() == 0;

#if HAVE_PODCASTS
		pref.sync_all_podcasts = podcastDropdown.get_active() == 0;
#endif
		//pref.sync_all_audiobooks = audiobookDropdown.get_active() == 0;
		
		pref.music_playlist = musicDropdown.get_active_id();
#if HAVE_PODCASTS
		pref.podcast_playlist = podcastDropdown.get_active_id();
#endif
		//pref.audiobook_playlist = audiobookDropdown.get_active_id();
		
		musicDropdown.sensitive = syncMusic.active;
#if HAVE_PODCASTS
		podcastDropdown.sensitive = syncPodcasts.active;
#endif
		//audiobookDropdown.sensitive = syncAudiobooks.active;
	}
	
	public bool allMediasSelected() {
		return false;
	}
	
	public void refreshLists() {
		message("refreshing lists\n");
		string musicString = musicDropdown.get_active_id();
#if HAVE_PODCASTS
		string podcastString = podcastDropdown.get_active_id();
#endif
		//string audiobookString = audiobookDropdown.get_active_id();
		
		TreeIter iter;
		musicList.clear();
#if HAVE_PODCASTS
		podcastList.clear();
#endif
		//audiobookList.clear();
		
		/* add entire library options */
		musicList.append(out iter);
		musicList.set(iter, 0, null, 1, _("All Music"), 2, Icons.MUSIC.render(IconSize.MENU));
#if HAVE_PODCASTS
		podcastList.append(out iter);
		podcastList.set(iter, 0, null, 1, _("All Podcasts"), 2, Icons.PODCAST.render(IconSize.MENU));
#endif
		//audiobookList.append(out iter);
		//audiobookList.set(iter, 0, null, 1, "All Audiobooks");//, 2, Icons.audiobook_icon.render(IconSize.MENU, audiobookDropdown.get_style_context()));
		
		/* add separator */
		musicList.append(out iter);
		musicList.set(iter, 0, null, 1, "<separator_item_unique_name>");
#if HAVE_PODCASTS
		podcastList.append(out iter);
		podcastList.set(iter, 0, null, 1, "<separator_item_unique_name>");
#endif
		//audiobookList.append(out iter);
		//audiobookList.set(iter, 0, null, 1, "<separator_item_unique_name>");
		
		/* add all playlists */
		var smart_playlist_pix = Icons.SMART_PLAYLIST.render(IconSize.MENU, null);
		var playlist_pix = Icons.PLAYLIST.render(IconSize.MENU, null);
		foreach(var p in lm.smart_playlists()) {
			//bool music, podcasts, audiobooks;
			//test_media_types(lm.medias_from_smart_playlist(p.rowid), out music, out podcasts, out audiobooks);
			
			//if(music) {
				musicList.append(out iter);
				musicList.set(iter, 0, p, 1, p.name, 2, smart_playlist_pix);
			//}
#if HAVE_PODCASTS
			//if(podcasts) {
				podcastList.append(out iter);
				podcastList.set(iter, 0, p, 1, p.name, 2, smart_playlist_pix);
			//}
#endif
			//if(audiobooks) {
				//audiobookList.append(out iter);
				//audiobookList.set(iter, 0, p, 1, p.name, 2, smart_playlist_pix);
			//}
		}
		foreach(var p in lm.playlists()) {
			//bool music, podcasts, audiobooks;
			//test_media_types(lm.medias_from_smart_playlist(p.rowid), out music, out podcasts, out audiobooks);
			
			//if(music) {
				musicList.append(out iter);
				musicList.set(iter, 0, p, 1, p.name, 2, playlist_pix);
			//}
#if HAVE_PODCASTS
			//if(podcasts) {
				podcastList.append(out iter);
				podcastList.set(iter, 0, p, 1, p.name, 2, playlist_pix);
			//}
#endif
			//if(audiobooks) {
				//audiobookList.append(out iter);
				//audiobookList.set(iter, 0, p, 1, p.name, 2, playlist_pix);
			//}
		}
		
		if(!musicDropdown.set_active_id(musicString))
			musicDropdown.set_active(0);
#if HAVE_PODCASTS
		if(!podcastDropdown.set_active_id(podcastString))
			podcastDropdown.set_active(0);
#endif
		//if(!audiobookDropdown.set_active_id(audiobookString))
		//	audiobookDropdown.set_active(0);
		
		message("setting sensitivity\n");
		musicDropdown.sensitive = dev.get_preferences().sync_music;
#if HAVE_PODCASTS
		podcastDropdown.sensitive = dev.get_preferences().sync_podcasts;
#endif
		//audiobookDropdown.sensitive = dev.get_preferences().sync_audiobooks;
	}
	
	/*void test_media_types(Gee.Collection<int> items, out bool music, out bool podcasts, out bool audiobooks) {
		music = false;
		podcasts = false;
		audiobooks = false;
		
		if(items.size == 0) {
			music = true; podcasts = true; audiobooks = true;
			return;
		}
		
		foreach(int i in items) {
			if(!music && lm.media_from_id(i).mediatype == 0)
				music = true;
			if(!podcasts && lm.media_from_id(i).mediatype == 1)
				podcasts = true;
			if(!audiobooks && lm.media_from_id(i).mediatype == 2)
				audiobooks = true;
		}
	}*/
	
	void sync_finished(bool success) {
		refreshSpaceWidget();
		spaceWidget.set_sync_button_sensitive(true);
	}
	
	public void syncClicked() {
		Gee.LinkedList<int> list = new Gee.LinkedList<int>();
		var pref = dev.get_preferences();
		
		if(pref.sync_music) {
			if(pref.sync_all_music) {
				foreach(var s in lm.media()) {
					if(s.mediatype == 0 && !s.isTemporary)
						list.add(s.rowid);
				}
			}
			else {
				GLib.Object p = lm.playlist_from_name(pref.music_playlist);
				if(p == null)
					p = lm.smart_playlist_from_name(pref.music_playlist);
				
				if(p != null) {
					if(p is Playlist) {
						foreach(int i in ((Playlist)p).media()) {
							if(lm.media_from_id(i).mediatype == 0)
								list.add(i);
						}
					}
					else {
						foreach(int i in ((SmartPlaylist)p).analyze(lm, lm.media_ids())) {
							if(lm.media_from_id(i).mediatype == 0)
								list.add(i);
						}
					}
				}
				else {
					lw.doAlert(_("Sync Failed"), _("The playlist named %s is used to sync device %s, but could not be found.").printf("<b>" + pref.music_playlist + "</b>", "<b>" + dev.getDisplayName() + "</b>"));
					
					pref.music_playlist = "";
					pref.sync_all_music = true;
					musicDropdown.set_active(0);
					return;
				}
			}
		}

#if HAVE_PODCASTS
		if(pref.sync_podcasts) {
			if(pref.sync_all_podcasts) {
				foreach(var s in lm.media()) {
					if(s.mediatype == 1 && !s.isTemporary)
						list.add(s.rowid);
				}
			}
			else {
				GLib.Object p = lm.playlist_from_name(pref.podcast_playlist);
				if(p == null)
					p = lm.smart_playlist_from_name(pref.podcast_playlist);
				
				if(p != null) {
					if(p is Playlist) {
						foreach(int i in ((Playlist)p).media ()) {
							if(lm.media_from_id(i).mediatype == 1 && !lm.media_from_id(i).uri.has_prefix("http:/"))
								list.add(i);
						}
					}
					else {
						foreach(int i in ((SmartPlaylist)p).analyze(lm, lm.media_ids())) {
							if(lm.media_from_id(i).mediatype == 1 && !lm.media_from_id(i).uri.has_prefix("http:/"))
								list.add(i);
						}
					}
				}
				else {
					lw.doAlert(_("Sync Failed"), _("The playlist named %s is used to sync device %s, but could not be found.").printf("<b>" + pref.podcast_playlist + "</b>", "<b>" + dev.getDisplayName() + "</b>"));
					pref.podcast_playlist = "";
					pref.sync_all_podcasts = true;
					musicDropdown.set_active(0);
					return;
				}
			}
		}
#endif

		/*if(pref.sync_audiobooks) {
			if(pref.sync_all_audiobooks) {
				foreach(var s in lm.media()) {
					if(s.mediatype == 2 && !s.isTemporary)
						list.add(s.rowid);
				}
			}
			else {
				GLib.Object p = lm.playlist_from_name(pref.audiobook_playlist);
				if(p == null)
					p = lm.smart_playlist_from_name(pref.audiobook_playlist);
				
				if(p != null) {
					if(p is Playlist) {
						foreach(int i in ((Playlist)p).medias()) {
							if(lm.media_from_id(i).mediatype == 2)
								list.add(i);
						}
					}
					else {
						foreach(int i in ((SmartPlaylist)p).analyze(lm)) {
							if(lm.media_from_id(i).mediatype == 2)
								list.add(i);
						}
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
		}*/
		
		bool fits = dev.will_fit(list);
		if(!fits) {
			lw.doAlert(_("Cannot Sync"), _("Cannot sync device with selected sync settings. Not enough space on disk") +"\n");
		}
		else if(dev.is_syncing()) {
			lw.doAlert(_("Cannot Sync"), _("Device is already being synced."));
		}
		else {
			var to_remove = new Gee.LinkedList<int>();
			foreach(int i in dev.get_medias()) {
				int match = lm.match_media_to_list(i, lm.media_ids());
				if(match == 0)
					to_remove.add(i);
			}
			
			if(to_remove.size > 0) { // hand control over to SWD
				SyncWarningDialog swd = new SyncWarningDialog(lm, lw, dev, list, to_remove);
				swd.show();
			}
			else {
				spaceWidget.set_sync_button_sensitive(false);
				dev.sync_medias(list);
			}
		}
	}
}
