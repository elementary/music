using Gtk;

public class BeatBox.EqualizerWindow : Window {
	LibraryManager lm;
	LibraryWindow lw;
	
	Switch equalizerOnOff;
	PresetList sideList;
	HScale volumeSlider;
	
	bool initialized;
	
	HBox scales;
	List<VScale> scaleList;
	bool autoSwitchChosen;
	
	private bool inTransition;
	private Gee.ArrayList<int> targetLevels;
	
	public EqualizerWindow(LibraryManager lm, LibraryWindow lw) {
		this.lm = lm;
		this.lw = lw;
		
		scaleList = new List<VScale>();
		initialized = false;
		targetLevels = new Gee.ArrayList<int>();
		autoSwitchChosen = false;
		
		buildUI();
		
		addPresets();
		
		sideList.selectPreset(lm.settings.getSelectedPreset());
		
		equalizerOnOff.set_active(!lm.settings.getEqualizerDisabled());
		equalizerOnOffToggled();
		
		volumeSlider.set_value(lm.player.getVolume());
		
		initialized = true;
	}
	
	public void buildUI() {
		set_title("Unequalizer");
		
		this.window_position = WindowPosition.CENTER;
		this.type_hint = Gdk.WindowTypeHint.DIALOG;
		//this.set_modal(true);
		this.set_transient_for(lw);
		
		// set the size
		set_size_request(-1, 350);
		resizable = true;
		
		Gdk.Geometry geo = Gdk.Geometry();
		geo.min_width = 400;
		geo.min_height = 350;
		set_geometry_hints(this, geo, Gdk.WindowHints.MIN_SIZE);
		
		// set icon
		set_icon( render_icon(Gtk.Stock.PREFERENCES, IconSize.DIALOG, null));
		
		HBox padding = new HBox(false, 10);
		VBox allItems = new VBox(false, 10);
		scales = new HBox(false, 0);
		
		HBox topItems = new HBox(false, 0);
		HBox bottomItems = new HBox(false, 0);
		HBox advanced = new HBox(false, 0);
		
		equalizerOnOff = new Switch();
		sideList = new PresetList(lm, lw);
		
		string[] decibals = {"32", "64", "125", "250", "500", "1k", "2k", "4k", "8k", "16k"};
		for(int index = 0; index < 10; ++index) {
			VBox holder = new VBox(false, 0);
			VScale v = new VScale.with_range(-80, 80, 1);
			v.draw_value = false;
			v.inverted = true;
			
			holder.pack_start(v, true, true, 0);
			holder.pack_end(wrap_alignment(new Label(decibals[index]), 4, 0, 0, 0), false, false, 0);
			
			scales.pack_start(holder, true, true, 6);
			scaleList.append(v);
			
			v.value_changed.connect( () => {
				lm.player.setEqualizerGain(scaleList.index(v), (int)scaleList.nth_data(scaleList.index(v)).get_value());
				
				if(!inTransition)
					sideList.getSelectedPreset().setGain(scaleList.index(v), (int)scaleList.nth_data(scaleList.index(v)).get_value());
			});
		}
		
		volumeSlider = new HScale.with_range(0.0, 1.0, 0.01);
		volumeSlider.draw_value = false;
		
		//category labels
		Label equalizerLabel = new Label("");
		Label volumeLabel = new Label("");
		
		equalizerLabel.xalign = 0.0f;
		volumeLabel.xalign = 0.0f;
		
		equalizerLabel.set_markup("<b>Equalizer</b>");
		volumeLabel.set_markup("<b>Volume</b>");
		
		sideList.set_size_request(150, -1);
		
		bottomItems.pack_start(wrap_alignment(equalizerOnOff, 0, 0, 0, 0), false, true, 0);
		bottomItems.pack_start(wrap_alignment(sideList, 0, 0, 0, 6), false, true, 0);
		
		/** Add save and cancel buttons **/
		HButtonBox bottomButtons = new HButtonBox();
		var doneButton = new Button.with_label("Close");
		bottomButtons.set_layout(ButtonBoxStyle.END);
		bottomButtons.pack_end(doneButton, false, false, 0);
		
		allItems.pack_start(wrap_alignment(equalizerLabel, 10, 0, 0, 0), false, true, 0);
		allItems.pack_start(wrap_alignment(scales, 0, 0, 0, 10), true, true, 0);
		allItems.pack_start(wrap_alignment(bottomItems, 0, 0, 0, 10), false, true, 0);
		allItems.pack_start(wrap_alignment(volumeLabel, 0, 0, 0, 0), false, true, 0);
		allItems.pack_start(wrap_alignment(volumeSlider, 0, 0, 0, 10), false, true, 0);
		allItems.pack_end(wrap_alignment(bottomButtons, 0, 10, 10, 0), false, true, 0);
		
		padding.pack_start(allItems, true, true, 10);
		add(padding);
		
		show_all();
		
		equalizerOnOff.notify["active"].connect(equalizerOnOffToggled);
		sideList.automatic_preset_chosen.connect(automaticPresetChosen);
		sideList.add_preset_chosen.connect(addPresetClicked);
		sideList.delete_preset_chosen.connect(removePresetClicked);
		sideList.preset_selected.connect(presetSelected);
		volumeSlider.value_changed.connect(volumeSliderChanged);
		doneButton.clicked.connect(onQuit);
		//this.destroy.connect(onQuit);
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
	
	public void equalizerOnOffToggled() {
		stdout.printf("eOnOff %s", equalizerOnOff.get_active() ? "true" : "false");
		sideList.set_sensitive(equalizerOnOff.get_active());
		
		foreach(var scale in scaleList)
			scale.set_sensitive(equalizerOnOff.get_active());
			
		if(equalizerOnOff.get_active()) {
			EqualizerPreset p = sideList.getSelectedPreset();
			
			for(int i = 0; i < 10; ++i)
				lm.player.setEqualizerGain(i, p.getGain(i));
		}
		else {
			for(int i = 0; i < 10; ++i) {
				lm.player.setEqualizerGain(i, 0);
			}
		}
	}
	
	public void addPresets() {
		var saved = lm.settings.getPresets();
		
		sideList.clearList();
		
		sideList.addTopOptions();
		if(saved.size == 0)
			addDefaultPresets();
		
		foreach(EqualizerPreset p in saved) {
			sideList.addPreset(p);
		}
	}
	
	public void addDefaultPresets() {
		sideList.addPreset( new EqualizerPreset.with_gains("Flat", {0, 0, 0, 0, 0, 0, 0, 0, 0, 0}) );
		sideList.addPreset( new EqualizerPreset.with_gains("Classical", {0, 0, 0, 0, 0, 0, -40, -40, -40, -50}) );
		sideList.addPreset( new EqualizerPreset.with_gains("Club", {0, 0, 20, 30, 30, 30, 20, 0, 0, 0}) );
		sideList.addPreset( new EqualizerPreset.with_gains("Dance", {50, 35, 10, 0, 0, -30, -40, -40, 0, 0}) );
		sideList.addPreset( new EqualizerPreset.with_gains("Full Bass", {70, 70, 70, 40, 20, -45, -50, -55, -55, -55}) );
		sideList.addPreset( new EqualizerPreset.with_gains("Full Treble", {-50, -50, -50, -25, 15, 55, 80, 80, 80, 85}) );
		sideList.addPreset( new EqualizerPreset.with_gains("Full Bass + Treble", {35, 30, 0, -40, -25, 10, 45, 55, 60, 60}) );
		sideList.addPreset( new EqualizerPreset.with_gains("Laptop/Headphones", {25, 50, 25, -20, 0, -30, -40, -40, 0, 0}) );
		sideList.addPreset( new EqualizerPreset.with_gains("Large Hall", {50, 50, 30, 30, 0, -25, -25, -25, 0, 0}) );
		sideList.addPreset( new EqualizerPreset.with_gains("Live", {-25, 0, 20, 25, 30, 30, 20, 15, 15, 10}) );
		sideList.addPreset( new EqualizerPreset.with_gains("Party", {35, 35, 0, 0, 0, 0, 0, 0, 35, 35}) );
		sideList.addPreset( new EqualizerPreset.with_gains("Pop", {-10, 25, 35, 40, 25, -5, -15, -15, -10, -10}) );
		sideList.addPreset( new EqualizerPreset.with_gains("Reggae", {0, 0, -5, -30, 0, -35, -35, 0, 0, 0}) );
		sideList.addPreset( new EqualizerPreset.with_gains("Rock", {40, 25, -30, -40, -20, 20, 45, 55, 55, 55}) );
		sideList.addPreset( new EqualizerPreset.with_gains("Soft", {25, 10, -5, -15, -5, 20, 45, 50, 55, 60}) );
		sideList.addPreset( new EqualizerPreset.with_gains("Ska", {-15, -25, -25, -5, 20, 30, 45, 50, 55, 50}) );
		sideList.addPreset( new EqualizerPreset.with_gains("Soft Rock", {20, 20, 10, -5, -25, -30, -20, -5, 15, 45}) );
		sideList.addPreset( new EqualizerPreset.with_gains("Techno", {40, 30, 0, -30, -25, 0, 40, 50, 50, 45}) );
		  
	}
	
	public void presetSelected(EqualizerPreset p) {
		autoSwitchChosen = false;
		
		targetLevels.clear();
		foreach(int i in p.gains)
			targetLevels.add(i);
		
		if(!initialized) {
			for(int index = 0; index < 10; ++index) {
				scaleList.nth_data(index).set_value(targetLevels.get(index));
			}
			
			return;
		}
		
		if(!inTransition) {
			inTransition = true;
			Timeout.add(20, transitionScales);
		}
	}
	
	public bool transitionScales() {
		bool isFinished = true;
		
		for(int index = 0; index < 10; ++index) {
			//scaleList.nth_data(index).set_value((double)p.getGain(index));
			double currLvl = scaleList.nth_data(index).get_value();
			double targetLvl = targetLevels.get(index);
			double difference = targetLvl - currLvl;
            
            if(Math.fabs(difference) <= 1)
                scaleList.nth_data(index).set_value(targetLvl);
            else {
                scaleList.nth_data(index).set_value(scaleList.nth_data(index).get_value() + (difference / 8.0));
                isFinished = false;
			}
		}
		
		if(isFinished) {
			inTransition = false;
			return false; // stop
		}
		
		return true; // keep going
	}
	
	public void automaticPresetChosen() {
		autoSwitchChosen = true;
	}
	
	public virtual void addPresetClicked() {
		PresetNameWindow pnw = new PresetNameWindow(lw, new EqualizerPreset.basic("Custom Preset"));
		pnw.preset_saved.connect(presetNameWindowSaved);
	}
	
	public virtual void presetNameWindowSaved(EqualizerPreset p) {
		sideList.addPreset(p);
	}
	
	public void removePresetClicked() {
		stdout.printf("removing selected..\n");
		sideList.removeCurrentPreset();
	}
	
	public void restorePresetsClicked() {
		sideList.clearList();
		addDefaultPresets();
	}
	
	public void volumeSliderChanged() {
		lm.player.setVolume(volumeSlider.get_value());
	}
	
	public void onQuit() {
		lm.settings.setEqualizerDisabled(!equalizerOnOff.get_active());
		lm.settings.setSelectedPreset(sideList.getSelectedPreset());
		lm.settings.setPresets(sideList.getPresets());
		lm.settings.setAutoSwitchPreset(autoSwitchChosen);
		lm.settings.setVolume(lm.player.getVolume());
		
		if(lm.settings.getEqualizerDisabled()) {
			lm.player.disableEqualizer();
		}
		else {
			lm.player.enableEqualizer();
		}
		
		if(lm.settings.getAutoSwitchPreset() && !lm.settings.getEqualizerDisabled()) {
			bool matched_genre = false;
			foreach(var p in lm.settings.getPresets()) {
				if(p.name.down() == lm.song_info.song.genre.down()) {
					
					matched_genre = true;
					
					for(int i = 0; i < 10; ++i)
						lm.player.setEqualizerGain(i, p.getGain(i));
					
					break;
				}
			}
			
			if(!matched_genre) {
				var p = lm.settings.getSelectedPreset();
				
				for(int i = 0; i < 10; ++i)
					lm.player.setEqualizerGain(i, p.getGain(i));
			}
		}
		
		this.destroy();
	}
}
