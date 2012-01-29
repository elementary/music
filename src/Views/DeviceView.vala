using Gtk;
using Gee;

public class BeatBox.DeviceView : VBox {
	LibraryManager lm;
	LibraryWindow lw;
	Device d;
	DeviceSummaryWidget summary;
	
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
		
		if(d.get_preferences().sync_when_mounted)
			syncClicked();
	}
	
	void buildUI() {
		summary = new DeviceSummaryWidget(lm, lw, d);
		pack_start(summary, true, true, 0);
		
		show_all();
		d.progress_notification.connect(deviceProgress);
	}
	
	
	public void set_is_current_view(bool val) {
		if(val)
			summary.refreshLists();
	}
	
	public void showImportDialog() {
		// ask the user if they want to import medias from device that they don't have in their library (if any)
		if(!lm.doing_file_operations() && lm.settings.getMusicFolder() != "") {
			var externals = new LinkedList<int>();
			foreach(var i in d.get_medias()) {
				if(lm.match_media_to_list(i, lm.media_ids()) == 0) {
					externals.add(i);
				}
			}
			
			if(externals.size > 0) {
				TransferFromDeviceDialog tfdd = new TransferFromDeviceDialog(lw, d, externals);
				tfdd.show();
			}
			else {
				lw.doAlert("No External Songs", "There were no songs found on this device that are not in your library.");
			}
		}
	}
	
	public void syncClicked() {
		summary.syncClicked();
	}
	
	void deviceProgress(string? message, double progress) {
		lw.progressNotification(message, progress);
	}
}
