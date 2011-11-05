using Gtk;

public class BeatBox.EqualizerWindow : Window {
	LibraryManager lm;
	LibraryWindow lw;
	
	Switch eq_switch;
	PresetList preset_combo;
	
	bool initialized;
	
	List<VScale> scaleList;
	List<Label> label_list;
	bool autoSwitchChosen;
	
	private bool in_transition;
	private Gee.ArrayList<int> targetLevels;
	
	public EqualizerWindow (LibraryManager lm, LibraryWindow lw) {
	
		this.lm = lm;
		this.lw = lw;
		
		scaleList = new List<VScale>();
		label_list = new List<Label>();
		initialized = false;
		targetLevels = new Gee.ArrayList<int>();
		autoSwitchChosen = false;
		
		build_ui();
		
		load_presets();
		
		var preset = lm.settings.getSelectedPreset();
		
		if (preset != null) {
			preset_combo.selectPreset(preset);
		}
		
		eq_switch.set_active(!lm.settings.getEqualizerDisabled());
		on_eq_switch_toggled();

		if (lm.settings.getAutoSwitchPreset()) {
			preset_combo.selectAutomaticPreset();
			on_automatic_chosen();
		}

		initialized = true;
	}
	
	public void build_ui () {
	
		set_title("Equalizer");
		
		window_position = WindowPosition.CENTER;
		type_hint = Gdk.WindowTypeHint.DIALOG;
		set_transient_for(lw);
		
		set_size_request(440, 224);
		resizable = false;

		set_icon(render_icon(Gtk.Stock.PREFERENCES, IconSize.DIALOG, null));
		
		var outer_box = new HBox(false, 10);
		var inner_box = new VBox(false, 0);
		var scales = new HBox(false, 0);
        var bottom_toolbar = new Toolbar();		
		
		eq_switch = new Switch();
		preset_combo = new PresetList(lm, lw);
		
		string[] decibals = {"32", "64", "125", "250", "500", "1k", "2k", "4k", "8k", "16k"};
		for (int index = 0; index < 10; ++index) {
			VBox holder = new VBox(false, 0);
			VScale v = new VScale.with_range(-80, 80, 2);
			v.add_mark(0, PositionType.LEFT, null);
			v.draw_value = false;
			v.inverted = true;
			
			var label = new Label(decibals[index]);
			
			holder.pack_start(v, true, true, 0);
			holder.pack_end(wrap_alignment(label, 4, 0, 0, 0), false, false, 0);
			
			scales.pack_start(holder, true, true, 6);
			scaleList.append(v);
			label_list.append(label);
			
			v.value_changed.connect( () => {
				lm.player.setEqualizerGain(scaleList.index(v), (int)scaleList.nth_data(scaleList.index(v)).get_value());
				
				if (!in_transition)
					preset_combo.getSelectedPreset().setGain(scaleList.index(v), (int)scaleList.nth_data(scaleList.index(v)).get_value());
			});
		}

		preset_combo.set_size_request(150, -1);

		var eq_switch_item = new ToolItem();
		eq_switch_item.add(eq_switch);

		var side_list = new ToolItem();
		side_list.add(preset_combo);

		var space_item = new ToolItem();
		space_item.set_expand(true);
		
		var close_button = new Button.with_label("Close");
		var close_button_item = new ToolItem();
        close_button_item.set_expand(true);
		close_button_item.add(close_button);

		bottom_toolbar.insert(eq_switch_item, 0);
		bottom_toolbar.insert(side_list, 1);
		bottom_toolbar.insert(space_item, 2);
		bottom_toolbar.insert(close_button_item, 3);

        // Set the egtk bottom toolbar style.
		bottom_toolbar.get_style_context().add_class("bottom-toolbar");

		inner_box.pack_end(wrap_alignment(bottom_toolbar, 0, 0, 0, 0), false, false, 0);	
		inner_box.pack_start(wrap_alignment(scales, 0, 12, 0, 12), true, true, 10);
		
		outer_box.pack_start(inner_box);
		add(outer_box);
		
		eq_switch.notify["active"].connect(on_eq_switch_toggled);
		preset_combo.automatic_preset_chosen.connect(on_automatic_chosen);
		preset_combo.add_preset_chosen.connect(addPresetClicked);
		preset_combo.delete_preset_chosen.connect(removePresetClicked);
		preset_combo.preset_selected.connect(presetSelected);
		close_button.clicked.connect(on_close);
		destroy.connect(on_close);
		
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
	
	void set_sliders_sensitivity (bool sensitivity) {
	
		foreach (var scale in scaleList) {
		    label_list.nth_data(scaleList.index(scale)).sensitive = sensitivity;
			scale.sensitive = sensitivity;
		}	
	}
	
	public void on_eq_switch_toggled () {
	    
		preset_combo.sensitive = eq_switch.get_active();
		
		if (eq_switch.get_active()) {
		    stdout.printf("Active\n");
			EqualizerPreset p = preset_combo.getSelectedPreset();
			
			if (p != null) {
				for(int i = 0; i < 10; ++i)
					lm.player.setEqualizerGain(i, p.getGain(i));
			}
		} else {
		    stdout.printf("Inactive\n");
			for(int i = 0; i < 10; ++i) {
				lm.player.setEqualizerGain(i, 0);
			}
		}
		
        if (autoSwitchChosen) {
            stdout.printf("Sliders going inactive\n");
	        set_sliders_sensitivity (false);
        } else {
            stdout.printf("Sliders going get_active()\n");
	        set_sliders_sensitivity (eq_switch.get_active());
        }
	}
	
	public void load_presets () {
	
		var saved = lm.settings.getPresets();
			
		preset_combo.clearList();
		preset_combo.addTopOptions();
		
		if (saved.size == 0) {
			load_default_presets();
		}
		
		foreach(EqualizerPreset p in saved) {
			preset_combo.addPreset(p);
		}
	}
	
	public void load_default_presets () {
	
		preset_combo.addPreset( new EqualizerPreset.with_gains("Flat", {0, 0, 0, 0, 0, 0, 0, 0, 0, 0}) );
		preset_combo.addPreset( new EqualizerPreset.with_gains("Classical", {0, 0, 0, 0, 0, 0, -40, -40, -40, -50}) );
		preset_combo.addPreset( new EqualizerPreset.with_gains("Club", {0, 0, 20, 30, 30, 30, 20, 0, 0, 0}) );
		preset_combo.addPreset( new EqualizerPreset.with_gains("Dance", {50, 35, 10, 0, 0, -30, -40, -40, 0, 0}) );
		preset_combo.addPreset( new EqualizerPreset.with_gains("Full Bass", {70, 70, 70, 40, 20, -45, -50, -55, -55, -55}) );
		preset_combo.addPreset( new EqualizerPreset.with_gains("Full Treble", {-50, -50, -50, -25, 15, 55, 80, 80, 80, 85}) );
		preset_combo.addPreset( new EqualizerPreset.with_gains("Full Bass + Treble", {35, 30, 0, -40, -25, 10, 45, 55, 60, 60}) );
		preset_combo.addPreset( new EqualizerPreset.with_gains("Laptop/Headphones", {25, 50, 25, -20, 0, -30, -40, -40, 0, 0}) );
		preset_combo.addPreset( new EqualizerPreset.with_gains("Large Hall", {50, 50, 30, 30, 0, -25, -25, -25, 0, 0}) );
		preset_combo.addPreset( new EqualizerPreset.with_gains("Live", {-25, 0, 20, 25, 30, 30, 20, 15, 15, 10}) );
		preset_combo.addPreset( new EqualizerPreset.with_gains("Party", {35, 35, 0, 0, 0, 0, 0, 0, 35, 35}) );
		preset_combo.addPreset( new EqualizerPreset.with_gains("Pop", {-10, 25, 35, 40, 25, -5, -15, -15, -10, -10}) );
		preset_combo.addPreset( new EqualizerPreset.with_gains("Reggae", {0, 0, -5, -30, 0, -35, -35, 0, 0, 0}) );
		preset_combo.addPreset( new EqualizerPreset.with_gains("Rock", {40, 25, -30, -40, -20, 20, 45, 55, 55, 55}) );
		preset_combo.addPreset( new EqualizerPreset.with_gains("Soft", {25, 10, -5, -15, -5, 20, 45, 50, 55, 60}) );
		preset_combo.addPreset( new EqualizerPreset.with_gains("Ska", {-15, -25, -25, -5, 20, 30, 45, 50, 55, 50}) );
		preset_combo.addPreset( new EqualizerPreset.with_gains("Soft Rock", {20, 20, 10, -5, -25, -30, -20, -5, 15, 45}) );
		preset_combo.addPreset( new EqualizerPreset.with_gains("Techno", {40, 30, 0, -30, -25, 0, 40, 50, 50, 45}) );
	}
	
	public void presetSelected(EqualizerPreset p) {
	
	    assert(p != null);
		
		autoSwitchChosen = false;
		set_sliders_sensitivity (true);
		targetLevels.clear();
		foreach (int i in p.gains) {
			targetLevels.add(i);
		}
		
		if (!initialized) {
			for (int index = 0; index < 10; ++index) {
				scaleList.nth_data(index).set_value(targetLevels.get(index));
			}
			return;
		}
		
		if(!in_transition) {
			in_transition = true;
			Timeout.add(20, transition_scales);
		}
	}
	
	public bool transition_scales () {
	
		bool is_finished = true;
		
		for (int index = 0; index < 10; ++index) {
			//scaleList.nth_data(index).set_value((double)p.getGain(index));
			double currLvl = scaleList.nth_data(index).get_value();
			double targetLvl = targetLevels.get(index);
			double difference = targetLvl - currLvl;
            
            if (Math.fabs(difference) <= 1)
                scaleList.nth_data(index).set_value(targetLvl);
            else {
                scaleList.nth_data(index).set_value(scaleList.nth_data(index).get_value() + (difference / 8.0));
                is_finished = false;
			}
		}
		
		if (is_finished) {
			in_transition = false;
			return false; // stop
		}
		
		return true; // keep going
	}
	
	public void on_automatic_chosen () {
	
	    stdout.printf("Automatic chosen\n");
		autoSwitchChosen = true;
		set_sliders_sensitivity (false);
	}
	
	public virtual void addPresetClicked () {
	
		PresetNameWindow pnw = new PresetNameWindow(lw, new EqualizerPreset.basic("Custom Preset"));
		pnw.preset_saved.connect(presetNameWindowSaved);
	}
	
	public virtual void presetNameWindowSaved(EqualizerPreset p) {
	
		preset_combo.addPreset(p);
	}
	
	public void removePresetClicked () {
	
		preset_combo.removeCurrentPreset();
	}
	
	public void restorePresetsClicked () {
	
		preset_combo.clearList();
		load_default_presets();
	}
	
	public void on_close () {
	
        stdout.printf("On_closing\n");
	
		lm.settings.setEqualizerDisabled(!eq_switch.get_active());
		
		if(preset_combo.getSelectedPreset() != null) {
			lm.settings.setSelectedPreset(preset_combo.getSelectedPreset());
		}
		
		lm.settings.setPresets(preset_combo.getPresets());
		lm.settings.setAutoSwitchPreset(autoSwitchChosen);
		
		if (lm.settings.getEqualizerDisabled()) {
			lm.player.disableEqualizer();
		} else {
			lm.player.enableEqualizer();
		}
		
		if (lm.settings.getAutoSwitchPreset() && !lm.settings.getEqualizerDisabled()) {
			bool matched_genre = false;
			foreach(var p in lm.settings.getPresets()) {
				if(p.name.down() == lm.song_info.song.genre.down()) {
					
					matched_genre = true;
					
					for(int i = 0; i < 10; ++i)
						lm.player.setEqualizerGain(i, p.getGain(i));
					
					break;
				}
			}
			
			if (!matched_genre) {
				var p = lm.settings.getSelectedPreset();
				
				for(int i = 0; i < 10; ++i)
					lm.player.setEqualizerGain(i, p.getGain(i));
			}
		}
		
		destroy();
	}
}
