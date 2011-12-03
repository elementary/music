using Gtk;

public class BeatBox.DeviceSummaryWidget : ScrolledWindow {
	LibraryManager lm;
	LibraryWindow lw;
	Device dev;
	
	Granite.Widgets.HintedEntry deviceName;
	RadioButton syncAllMusic;
	RadioButton filterSyncedMusic;
	
	ListStore playlists;
	ComboBox playlistCombo;
	
	public DeviceSummaryWidget(LibraryManager lm, LibraryWindow lw, Device d) {
		this.lm = lm;
		this.lw = lw;
		this.dev = d;
		
		buildUI();
	}
	
	public void buildUI() {
		deviceName = new Granite.Widgets.HintedEntry("Device Name");
		syncAllMusic = new RadioButton.with_label(null, "Sync all Music");
		filterSyncedMusic = new RadioButton.with_label(null, "Filter music from playlist: ");
		var capacityInfo = new Label(dev.get_fancy_capacity());
		var deviceDescription = new Label(dev.get_fancy_description());
		
		Label deviceNameLabel = new Label("Device Name:");
		Label capacityLabel = new Label("Capacity:");
		Label syncOptionsLabel = new Label("Sync Options:");
		Label deviceDescriptionLabel = new Label("Model:");
		
		var content = new VBox(false, 10);
		
		playlists = new ListStore(2, typeof(GLib.Object), typeof(string));
		playlistCombo = new ComboBox();
		playlistCombo.set_model(playlists);
		
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
		
		playlistCombo.popup.connect(refreshPlaylistList);
		//playlistCombo.changed.connect(playlistSelectionChanged);
		
		var playlistOption = new HBox(false, 0);
		playlistOption.pack_start(filterSyncedMusic, false, false, 0);
		playlistOption.pack_start(wrap_alignment(playlistCombo, 0, 0, 0, 6), false, false, 0);
		
		var deviceNameBox = new HBox(true, 6);
		deviceNameBox.pack_start(deviceNameLabel, false, true, 0);
		deviceNameBox.pack_start(deviceName, false, true, 0);
		
		var syncOptionsBox = new VBox(false, 0);
		syncOptionsBox.pack_start(syncAllMusic, false, false, 0);
		syncOptionsBox.pack_start(playlistOption, false, false, 0);
		filterSyncedMusic.join_group(syncAllMusic);
		
		var syncHBox = new HBox(true, 6);
		syncHBox.pack_start(syncOptionsLabel, false, true, 0);
		syncHBox.pack_start(syncOptionsBox, false, true, 0);
		
		/* show capacity */
		var capcityHBox = new HBox(true, 6);
		capcityHBox.pack_start(capacityLabel, false, true, 0);
		capcityHBox.pack_start(capacityInfo, false, true, 0);
		
		/* show some general info */
		var descHBox = new HBox(true, 6);
		descHBox.pack_start(deviceDescriptionLabel, false, true, 0);
		descHBox.pack_start(deviceDescription, false, true, 0);
		
		content.pack_start(deviceNameBox, false, true, 0);
		content.pack_start(descHBox, false, true, 0);
		content.pack_start(capcityHBox, false, true, 0);
		content.pack_start(syncHBox, false, true, 0);
		//content.pack_start(new Label(dev.get_path()), false, false, 0);
		
		add_with_viewport(wrap_alignment(content, 15, 10, 10, 10));
		
		deviceNameLabel.xalign = 1.0f;
		deviceName.halign = Align.START;
		if(dev.getDisplayName() != "")
			deviceName.set_text(dev.getDisplayName());
		
		syncOptionsLabel.yalign = 0.0f;
		syncOptionsLabel.xalign = 1.0f;
		syncOptionsBox.halign = Align.START;
		
		capacityLabel.xalign = 1.0f;
		capacityInfo.halign = Align.START;
		
		deviceDescriptionLabel.xalign = 1.0f;
		deviceDescription.halign = Align.START;
		
		set_policy(PolicyType.AUTOMATIC, PolicyType.NEVER);
		
		refreshPlaylistList();
		
		deviceName.changed.connect(deviceNameChanged);
		
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
	
	void deviceNameChanged() {
		dev.setDisplayName(deviceName.get_text());
	}
	
	public bool allSongsSelected() {
		return syncAllMusic.active;
	}
	
	public GLib.Object selected_playlist() {
		TreeIter it;
		playlistCombo.get_active_iter(out it);
		
		GLib.Object o;
		playlists.get(it, 0, out o);
		
		return o;
	}
	
	public void refreshPlaylistList() {
		playlists.clear();
		
		foreach(var p in lm.smart_playlists()) {
			TreeIter iter;
			playlists.append(out iter);
			playlists.set(iter, 0, p, 1, p.name);
		}
		foreach(var p in lm.playlists()) {
			TreeIter iter;
			playlists.append(out iter);
			playlists.set(iter, 0, p, 1, p.name);
		}
	}
}
