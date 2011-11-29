using Gtk;

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
	}
	
	void buildUI() {
		bar = new DeviceBar(lm, d);
		summary = new DeviceSummaryWidget(lm, lw, d);
		music_list = new DeviceViewWrapper(lm, lw, d.get_songs(), "Artist", SortType.ASCENDING, MusicTreeView.Hint.DEVICE, -1, d);
		podcast_list = new DeviceViewWrapper(lm, lw, new Gee.LinkedList<int>(), "Artist", SortType.ASCENDING, MusicTreeView.Hint.DEVICE, -1, d);
		
		pack_start(bar, false, true, 0);
		pack_end(summary, true, true, 0);
		pack_end(music_list, true, true, 0);
		pack_end(podcast_list, true, true, 0);
		
		show_all();
		bar_option_changed(0);
		
		bar.option_changed.connect(bar_option_changed);
		bar.sync_requested.connect(syncClicked);
	}
	
	public void updateChildren() {
		music_list.doUpdate(music_list.getView(), music_list.songs, true, false);
		podcast_list.doUpdate(podcast_list.getView(), podcast_list.songs, true, false);
	}
	
	public void setIsCurrentView(bool val) {
		music_list.setIsCurrentView(val);
		podcast_list.setIsCurrentView(val);
		
		if(val) {
			// loop through and turn on/off views
			for(int i = 0; i < get_children().length(); ++i) {
				if(get_children().nth_data(i) is ViewWrapper) {
					ViewWrapper vw = (ViewWrapper)get_children().nth_data(i);
					
					vw.setIsCurrentView(vw.visible);
					if(vw.visible) {
						vw.doUpdate(vw.getView(), vw.songs, true, false);
					}
					
					if(lw.initializationFinished && (lw.viewSelector.selected == 2)) {
						stdout.printf("doing miller update from device view\n");
						lw.miller.populateColumns("device", vw.songs);
					}
					lw.updateMillerColumns();
					vw.setStatusBarText();
				}
				else {
					lw.updateMillerColumns();
				}
			}
		}
	}
	
	void bar_option_changed(int option) {
		if(option == 0) {
			summary.show();
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
		
		setIsCurrentView(true);
	}
	
	void syncClicked() {
		Playlist p = summary.selected_playlist();
		
		bool fits = d.will_fit(lm.songs_from_playlist(p.rowid));
		if(!fits) {
			lw.doAlert("Cannot Sync", "Cannot Sync Device with playlist " + p.name + ". Not enough space on disk\n");
		}
		else if(d.is_syncing()) {
			lw.doAlert("Cannot Sync", "Device is already being synced.");
		}
		else {
			d.sync_songs(lm.songs_from_playlist(p.rowid));
		}
	}
}
