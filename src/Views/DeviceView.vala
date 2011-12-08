using Gtk;
using Gee;

public class BeatBox.DeviceView : VBox {
	LibraryManager lm;
	LibraryWindow lw;
	Device d;
	
	DeviceBar bar;
	DeviceSummaryWidget summary;
	public DeviceViewWrapper music_list;
	DeviceViewWrapper podcast_list;
	
	public DeviceView(LibraryManager lm, Device d) {
		this.lm = lm;
		this.lw = lm.lw;
		this.d = d;
		
		
		buildUI();
		
		ulong connector = lm.progress_cancel_clicked.connect( () => {
			if(d.is_syncing()) {
				lw.doAlert("Cancelling Sync", "Device Sync has been cancelled. Importing will stop after this song.");
				d.cancel_sync();
			}
		});
		d.device_unmounted.connect( () => {
			stdout.printf("device unmounted\n");
			d.disconnect(connector);
		});
	}
	
	void buildUI() {
		bar = new DeviceBar(lm, d);
		summary = new DeviceSummaryWidget(lm, lw, d);
		music_list = new DeviceViewWrapper(lm, lw, d.get_songs(), "Artist", SortType.ASCENDING, ViewWrapper.Hint.DEVICE_AUDIO, -1, d);
		podcast_list = new DeviceViewWrapper(lm, lw, d.get_podcasts(), "Artist", SortType.ASCENDING, ViewWrapper.Hint.DEVICE_PODCAST, -1, d);
		
		pack_start(bar, false, true, 0);
		pack_end(summary, true, true, 0);
		pack_end(music_list, true, true, 0);
		pack_end(podcast_list, true, true, 0);
		
		show_all();
		bar_option_changed(0);
		
		bar.option_changed.connect(bar_option_changed);
		bar.sync_requested.connect(syncClicked);
		d.progress_notification.connect(deviceProgress);
	}
	
	public void updateChildren() {
		music_list.doUpdate(music_list.getView(), music_list.songs, true, false);
		podcast_list.doUpdate(podcast_list.getView(), podcast_list.songs, true, false);
	}
	
	public void set_is_current_view(bool val) {
		music_list.set_is_current_view(val);
		podcast_list.set_is_current_view(val);
		
		if(val) {
			// loop through and turn on/off views
			for(int i = 0; i < get_children().length(); ++i) {
				if(get_children().nth_data(i) is ViewWrapper) {
					ViewWrapper vw = (ViewWrapper)get_children().nth_data(i);
					
					vw.set_is_current_view(vw.visible);
					if(vw.visible) {
						vw.doUpdate(vw.getView(), vw.songs, true, false);
					}
					
					// no millers in device view's for now. it looks weird.
					/*if(lw.initializationFinished && (lw.viewSelector.selected == 2)) {
						stdout.printf("doing miller update from device view\n");
						lw.miller.populateColumns("device", vw.songs);
					}
					lw.updateMillerColumns();*/
					vw.set_statusbar_text();
				}
				else {
					//lw.updateMillerColumns();
				}
			}
		}
	}
	
	void bar_option_changed(int option) {
		if(option == 0) {
			summary.show();
			summary.refreshPlaylistList();
			music_list.hide();
			podcast_list.hide();
		}
		else if(option == 1) {
			summary.hide();
			music_list.show();
			podcast_list.hide();
		}
		else if(option == 2) {
			summary.hide();
			music_list.hide();
			podcast_list.show();
		}
		
		lw.updateMillerColumns();
		set_is_current_view(true);
	}
	
	public int currentViewIndex() {
		return bar.currentPage();
	}
	
	void syncClicked() {
		LinkedList<int> list = new LinkedList<int>();
		
		if(summary.allSongsSelected()) {
			foreach(var s in lm.songs())
				list.add(s.rowid);
		}
		else {
			GLib.Object p = summary.selected_playlist();
			
			if(p == null) {
				lw.doAlert("Cannot Sync", "You must either select a playlist to sync, or select to sync all your songs");
			}
			else if(p is Playlist) {
				list = lm.songs_from_playlist(((Playlist)p).rowid);
			}
			else if(p is SmartPlaylist) {
				list = lm.songs_from_smart_playlist(((SmartPlaylist)p).rowid);
			}
		}
			
		
		bool fits = d.will_fit(list);
		if(!fits) {
			lw.doAlert("Cannot Sync", "Cannot Sync Device with selected songs. Not enough space on disk\n");
		}
		else if(d.is_syncing()) {
			lw.doAlert("Cannot Sync", "Device is already being synced.");
		}
		else {
			d.sync_songs(list);
		}
	}
	
	void deviceProgress(string? message, double progress) {
		lw.progressNotification(message, progress);
	}
}
