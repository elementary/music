using Gtk;

public class BeatBox.DeviceSummaryWidget : ScrolledWindow {
	LibraryManager lm;
	LibraryWindow lw;
	Device dev;
	
	Entry deviceName;
	RadioButton syncAllMusic;
	RadioButton filterSyncedMusic;
	Button openSyncFilter;
	Button sync;
	
	public DeviceSummaryWidget(LibraryManager lm, LibraryWindow lw, Device d) {
		this.lm = lm;
		this.lw = lw;
		this.dev = d;
		
		buildUI();
	}
	
	public void buildUI() {
		deviceName = new Entry();
		syncAllMusic = new RadioButton.with_label(null, "Sync all Music");
		filterSyncedMusic = new RadioButton.with_label(null, "Filter Synced Music");
		openSyncFilter = new Button.with_label("Open Sync Filter");
		sync = new Button.with_label("Sync Music");
		
		Label deviceNameLabel = new Label("Device Name:");
		Label syncOptionsLabel = new Label("Sync Options:");
		
		var content = new VBox(false, 10);
		
		var deviceNameBox = new HBox(true, 6);
		deviceNameBox.pack_start(deviceNameLabel, false, true, 0);
		deviceNameBox.pack_start(deviceName, false, true, 0);
		
		var syncOptionsBox = new VBox(false, 0);
		syncOptionsBox.pack_start(syncAllMusic, false, false, 0);
		syncOptionsBox.pack_start(filterSyncedMusic, false, false, 0);
		filterSyncedMusic.join_group(syncAllMusic);
		
		var syncHBox = new HBox(true, 6);
		syncHBox.pack_start(syncOptionsLabel, false, true, 0);
		syncHBox.pack_start(syncOptionsBox, false, true, 0);
		
		var syncButtons = new HBox(false, 6);
		var leftFillerLabel = new Label("");
		var syncButtonsComplete = new HBox(true, 6);
		syncButtons.pack_start(openSyncFilter, false, true, 0);
		syncButtons.pack_start(sync, false, true, 0);
		
		syncButtonsComplete.pack_start(leftFillerLabel, false, true, 0);
		syncButtonsComplete.pack_start(syncButtons, false, true, 0);
		
		content.pack_start(deviceNameBox, false, true, 0);
		content.pack_start(syncHBox, false, true, 0);
		content.pack_start(syncButtonsComplete, false, true, 0);
		
		add_with_viewport(wrap_alignment(content, 15, 10, 10, 10));
		
		deviceNameLabel.xalign = 1.0f;
		deviceName.halign = Align.START;
		
		syncOptionsLabel.yalign = 0.0f;
		syncOptionsLabel.xalign = 1.0f;
		syncOptionsBox.halign = Align.START;
		
		syncButtons.halign = Align.START;
		
		set_policy(PolicyType.AUTOMATIC, PolicyType.NEVER);
		
		
		show_all();
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
}
