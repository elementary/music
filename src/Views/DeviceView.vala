using Gtk;
using Gee;

public class BeatBox.DeviceView : VBox {
	LibraryManager lm;
	LibraryWindow lw;
	Device d;
	
	//DeviceBar bar;
	Granite.Widgets.StaticNotebook tabs;
	DeviceSummaryWidget summary;
	public DeviceViewWrapper music_list;
	DeviceViewWrapper podcast_list;
	DeviceViewWrapper audiobook_list;
	
	public DeviceView(LibraryManager lm, Device d) {
		this.lm = lm;
		this.lw = lm.lw;
		this.d = d;
		
		
		buildUI();
		
		ulong connector = lm.progress_cancel_clicked.connect( () => {
			if(d.is_syncing()) {
				lw.doAlert("Cancelling Sync", "Device Sync has been cancelled. Operation will stop after this media.");
				d.cancel_sync();
			}
			if(d.is_transferring()) {
				lw.doAlert("Cancelling Import", "Import from device has been cancelled. Operation will stop after this media.");
				d.cancel_transfer();
			}
		});
		d.device_unmounted.connect( () => {
			stdout.printf("device unmounted\n");
			d.disconnect(connector);
		});
	}
	
	void buildUI() {
		//bar = new DeviceBar(lm, d);
		tabs = new Granite.Widgets.StaticNotebook();
		
		summary = new DeviceSummaryWidget(lm, lw, d);
		tabs.append_page(summary, new Label("General"));
		
		music_list = new DeviceViewWrapper(lm, lw, d.get_medias(), "Artist", SortType.ASCENDING, ViewWrapper.Hint.DEVICE_AUDIO, -1, d);
		tabs.append_page(music_list, new Label("Music"));
		music_list.import_requested.connect(import_requested);
		
		if(d.supports_podcasts()) {
			podcast_list = new DeviceViewWrapper(lm, lw, d.get_podcasts(), "Artist", SortType.ASCENDING, ViewWrapper.Hint.DEVICE_PODCAST, -1, d);
			tabs.append_page(podcast_list, new Label("Podcasts"));
			podcast_list.import_requested.connect(import_requested);
		}
		if(d.supports_audiobooks()) {
			
		}
		
		pack_start(tabs, true, true, 0);
		
		var spaceWidget = new SpaceWidget((double)d.get_capacity()/1000000);
		
		pack_end(spaceWidget, false, true, 0);
		
		show_all();
		bar_option_changed(0);
		
		tabs.page_changed.connect(bar_option_changed);
		d.progress_notification.connect(deviceProgress);
	}
	
	public void updateChildren() {
		summary.refreshLists();
		music_list.doUpdate(music_list.getView(), music_list.medias, true, false);
		
		if(d.supports_podcasts())
			podcast_list.doUpdate(podcast_list.getView(), podcast_list.medias, true, false);
		if(d.supports_audiobooks())
			stdout.printf("will update audiobook list in future\n");
	}
	
	public void set_is_current_view(bool val) {
		music_list.set_is_current_view(val);
		
		if(d.supports_podcasts())
			podcast_list.set_is_current_view(val);
		// add audiobook too
		
		if(val) {
			// loop through and turn on/off views
			for(int i = 0; i < get_children().length(); ++i) {
				if(get_children().nth_data(i) is ViewWrapper) {
					ViewWrapper vw = (ViewWrapper)get_children().nth_data(i);
					
					vw.set_is_current_view(vw.visible);
					if(vw.visible) {
						vw.doUpdate(vw.getView(), vw.medias, true, false);
						vw.set_statusbar_text();
					}
					
					// no millers in device view's for now. it looks weird.
					/*if(lw.initializationFinished && (lw.viewSelector.selected == 2)) {
						stdout.printf("doing miller update from device view\n");
						lw.miller.populateColumns("device", vw.medias);
					}
					lw.updateMillerColumns();*/
				}
				else {
					//lw.updateMillerColumns();
				}
			}
		}
	}
	
	void bar_option_changed(int option) {
		lw.updateMillerColumns();
		set_is_current_view(true);
	}
	
	public int currentViewIndex() {
		return tabs.page;
	}
	
	public void showImportDialog() {
		// ask the user if they want to import medias from device that they don't have in their library (if any)
		if(!lm.doing_file_operations() && lm.settings.getMusicFolder() != "") {
			var externals = new LinkedList<int>();
			foreach(var i in d.get_medias()) {
				if(lm.media_from_id(i).isTemporary)
					externals.add(i);
			}
			
			if(externals.size > 0) {
				TransferFromDeviceDialog tfdd = new TransferFromDeviceDialog(lw, d, externals);
				tfdd.show();
			}
		}
	}
	
	public void syncClicked() {
		summary.syncClicked();
	}
	
	void import_requested(LinkedList<int> to_import) {
		d.transfer_to_library(to_import);
	}
	
	void deviceProgress(string? message, double progress) {
		lw.progressNotification(message, progress);
	}
}
