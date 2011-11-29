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
	
	ListStore playlists;
	ComboBox playlistCombo;
	
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
		
		
		playlists = new ListStore(2, typeof(GLib.Object), typeof(string));
		playlistCombo = new ComboBox();
		playlistCombo.set_model(playlists);
		
		playlistCombo.set_size_request(-1, 800);
		
		playlistCombo.set_id_column(1);
		playlistCombo.set_row_separator_func( (model, iter) => {
			string sep = "";
			model.get(iter, 1, out sep);
			
			return sep == "<separator_item_unique_name>";
		});
		
		var cell = new CellRendererText();
		cell.ellipsize = Pango.EllipsizeMode.END;
		playlistCombo.pack_start(cell, true);
		playlistCombo.add_attribute(cell, "text", 1);
		
		playlistCombo.popup.connect(playlistListShown);
		//playlistCombo.changed.connect(playlistSelectionChanged);
		
		var deviceNameBox = new HBox(true, 6);
		deviceNameBox.pack_start(deviceNameLabel, false, true, 0);
		deviceNameBox.pack_start(deviceName, false, true, 0);
		
		var syncOptionsBox = new VBox(false, 0);
		syncOptionsBox.pack_start(syncAllMusic, false, false, 0);
		syncOptionsBox.pack_start(playlistCombo, false, false, 0);
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
		content.pack_start(new Label(dev.get_path()), false, false, 0);
		
		add_with_viewport(wrap_alignment(content, 15, 10, 10, 10));
		
		deviceNameLabel.xalign = 1.0f;
		deviceName.halign = Align.START;
		
		syncOptionsLabel.yalign = 0.0f;
		syncOptionsLabel.xalign = 1.0f;
		syncOptionsBox.halign = Align.START;
		
		syncButtons.halign = Align.START;
		
		set_policy(PolicyType.AUTOMATIC, PolicyType.NEVER);
		
		playlistListShown();
		
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
	
	public Playlist selected_playlist() {
		TreeIter it;
		playlistCombo.get_active_iter(out it);
		
		GLib.Object o;
		playlists.get(it, 0, out o);
		
		return (Playlist)o;
	}
	
	void playlistListShown() {
		playlists.clear();
		
		foreach(var p in lm.playlists()) {
			TreeIter iter;
			playlists.append(out iter);
			playlists.set(iter, 0, p, 1, p.name);
		}
	}
}
