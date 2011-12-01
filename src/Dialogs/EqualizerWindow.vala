/*-
 * Copyright (c) 2011	   Scott Ringwelski <sgringwe@mtu.edu>
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

public class BeatBox.EqualizerWindow : Gtk.Window {

	LibraryManager lm;
	LibraryWindow lw;
	
	Switch eq_switch;
	PresetList preset_combo;
	Entry new_preset_entry;
	Toolbar bottom_toolbar;
	ToolItem side_list;
	ToolItem new_preset_field;
	
	bool initialized;
	bool automatic_chosen;
	bool adding_preset;

	private string new_preset_name;

	List<VScale> scale_list;
	List<Label> label_list;
	
	bool in_transition;
	Gee.ArrayList<int> target_levels;
	
	public EqualizerWindow (LibraryManager lm, LibraryWindow lw) {
	
		this.lm = lm;
		this.lw = lw;
		
		scale_list = new List<VScale>();
		label_list = new List<Label>();
		adding_preset = false;
		initialized = false;
		target_levels = new Gee.ArrayList<int>();
		automatic_chosen = false;

		build_ui();

		load_presets();

		var preset = lm.settings.getSelectedPreset();

		if (preset != null)
			preset_combo.selectPreset(preset);

		eq_switch.set_active(lm.settings.getEqualizerEnabled());
		on_eq_switch_toggled();

		if (lm.settings.getAutoSwitchPreset()) {
			preset_combo.selectAutomaticPreset();
			on_automatic_chosen();
		}

		initialized = true;
	}
	
	void build_ui () {
	
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
		bottom_toolbar = new Toolbar();		
		
		eq_switch = new Switch();
		preset_combo = new PresetList(lm, lw);
		
		string[] decibels = {"32", "64", "125", "250", "500", "1k", "2k", "4k", "8k", "16k"};

		for (int index = 0; index < 10; ++index) {
			VBox holder = new VBox(false, 0);
			VScale v = new VScale.with_range(-80, 80, 2);
			v.add_mark(0, PositionType.LEFT, null);
			v.draw_value = false;
			v.inverted = true;

			var label = new Label(decibels[index]);
			
			holder.pack_start(v, true, true, 0);
			holder.pack_end(wrap_alignment(label, 4, 0, 0, 0), false, false, 0);
			
			scales.pack_start(holder, true, true, 6);
			scale_list.append(v);
			label_list.append(label);
			
			v.value_changed.connect( () => {
				if(initialized) {
					lm.player.setEqualizerGain(scale_list.index(v), (int)scale_list.nth_data(scale_list.index(v)).get_value());

					if(!in_transition) {
						if (preset_combo.getSelectedPreset().is_default == false)
							preset_combo.getSelectedPreset().setGain(scale_list.index(v), (int)scale_list.nth_data(scale_list.index(v)).get_value());
						else
							on_default_preset_modified();
					}
				}
			});

		}

		preset_combo.set_size_request(150, -1);

		var eq_switch_item = new ToolItem();
		eq_switch_item.add(eq_switch);

		side_list = new ToolItem();
		side_list.add(preset_combo);

		new_preset_entry = new Entry();
		new_preset_entry.set_size_request(150, -1);
		new_preset_entry.set_icon_from_stock(Gtk.EntryIconPosition.SECONDARY, Gtk.Stock.OK);
		new_preset_entry.set_icon_tooltip_text(Gtk.EntryIconPosition.SECONDARY, "Save this preset");

		new_preset_field = new ToolItem();
		new_preset_field.add(new_preset_entry);

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
		new_preset_entry.activate.connect (add_new_preset);
		new_preset_entry.icon_press.connect (new_preset_entry_icon_pressed);

		close_button.clicked.connect(on_close);
		destroy.connect(on_close);
		
		show_all();
	}
	
	static Gtk.Alignment wrap_alignment (Gtk.Widget widget, int top, int right, int bottom, int left) {
	
		var alignment = new Gtk.Alignment(0.0f, 0.0f, 1.0f, 1.0f);
		alignment.top_padding = top;
		alignment.right_padding = right;
		alignment.bottom_padding = bottom;
		alignment.left_padding = left;
		
		alignment.add(widget);
		return alignment;
	}
	
	void set_sliders_sensitivity (bool sensitivity) {
	
		foreach (var scale in scale_list) {
			label_list.nth_data(scale_list.index(scale)).sensitive = sensitivity;
			scale.sensitive = sensitivity;
		}	
	}
	
	void on_eq_switch_toggled () {

		bool eq_active = eq_switch.get_active();
		preset_combo.sensitive = eq_active;
		set_sliders_sensitivity(eq_active);

		if (eq_active) {
			if(!automatic_chosen) {
				EqualizerPreset? selected_preset = preset_combo.getSelectedPreset();

				if (selected_preset != null && preset_combo.preset_list_size > 0) {
					for(int i = 0; i < 10; ++i)
						lm.player.setEqualizerGain(i, selected_preset.getGain(i));
					return;
				}
			}
		
			set_sliders_sensitivity(false);
			preset_combo.selectAutomaticPreset();
			on_automatic_chosen();
		} else {
			for (int i = 0; i < 10; ++i)
				lm.player.setEqualizerGain(i, 0);
		}
	}
	
	void load_presets () {

		var custom_presets = lm.settings.getCustomPresets();
		var default_presets = lm.settings.getDefaultPresets();

		preset_combo.clearList();
		preset_combo.addTopOptions();

		foreach (EqualizerPreset preset in default_presets) {
			preset.is_default = true;
			preset_combo.addPreset(preset);
		}

		foreach (EqualizerPreset preset in custom_presets) {
			preset_combo.addPreset(preset);
		}
	}

	void presetSelected(EqualizerPreset p) {
		automatic_chosen = false;

		set_sliders_sensitivity (true);
		target_levels.clear();
		
		foreach (int i in p.gains) {
			target_levels.add(i);
		}
		
		if (!initialized) {
			for (int index = 0; index < 10; ++index) {
				scale_list.nth_data(index).set_value(target_levels.get(index));
			}
			return;
		}
		
		if (!in_transition) {
			in_transition = true;
			Timeout.add(20, transition_scales);
		}
	}
	
	bool transition_scales () {
	
		bool is_finished = true;
		
		for (int index = 0; index < 10; ++index) {
			double currLvl = scale_list.nth_data(index).get_value();
			double targetLvl = target_levels.get(index);
			double difference = targetLvl - currLvl;
			
			if (Math.fabs(difference) <= 1)
				scale_list.nth_data(index).set_value(targetLvl);
			else {
				scale_list.nth_data(index).set_value(scale_list.nth_data(index).get_value() + (difference / 8.0));
				is_finished = false;
			}
		}
		
		if (is_finished) {
			in_transition = false;
			return false; // stop
		}

		return true; // keep going
	}
	
	void on_automatic_chosen() {

		automatic_chosen = true;
		lm.settings.setAutoSwitchPreset(automatic_chosen);
		lm.change_gains_thread();
		set_sliders_sensitivity (false);
	}

	void on_default_preset_modified() {

		if(adding_preset)
			return;

		adding_preset = true;

		bool preset_already_exists = false;
		var current_presets = preset_combo.getPresets();

		bottom_toolbar.remove(side_list);
		bottom_toolbar.insert(new_preset_field, 1);

		string current_preset_name = preset_combo.getSelectedPreset().name;
		string new_preset_name = " ";
		int i = 1;

		do
		{
			new_preset_name = current_preset_name + " (Custom" + ((preset_already_exists)? " " + i.to_string() : "") + ")";

			preset_already_exists = false;

			foreach(EqualizerPreset preset in current_presets) {
				if(new_preset_name == preset.name) {
					preset_already_exists = true;
					break;
				}
			}

			i++;
		
		} while (preset_already_exists);

		new_preset_entry.set_text(new_preset_name);
		bottom_toolbar.show_all();
		new_preset_entry.grab_focus();
	}

	void new_preset_entry_icon_pressed (EntryIconPosition pos, Gdk.Event event) {
		if(pos != Gtk.EntryIconPosition.SECONDARY && !adding_preset)
			return;

		add_new_preset();
	}

	void add_new_preset() {
		if(!adding_preset)
			return;

		var new_name = new_preset_entry.get_text();

		if(new_name != null)
			new_preset_name = new_name;

		int i = 0;
		int[] gains = new int[10];

		foreach(VScale scale in scale_list) {
			gains[i] = (int)scale_list.nth_data(scale_list.index(scale)).get_value();
			i++;
		}

		var newPreset = new EqualizerPreset.with_gains(new_preset_name, gains);
		preset_combo.addPreset(newPreset);

		bottom_toolbar.remove(new_preset_field);
		bottom_toolbar.insert(side_list, 1);
		bottom_toolbar.show_all();
		
		adding_preset = false;
	}

	void addPresetClicked () {
		PresetNameWindow pnw = new PresetNameWindow(lw, new EqualizerPreset.basic("Custom Preset"));
		pnw.preset_saved.connect(presetNameWindowSaved);
	}
	
	void presetNameWindowSaved (EqualizerPreset p) {
		preset_combo.addPreset(p);
	}

	void removePresetClicked () {

		preset_combo.removeCurrentPreset();
	}

	void on_close () {
		if(!in_transition)
			close_equalizer();
		else
			Timeout.add(20, close_equalizer);
	}
	
	bool close_equalizer () {

		if(in_transition)
			return true;

		lm.settings.setEqualizerEnabled(eq_switch.get_active());
		
		if(preset_combo.getSelectedPreset() != null) {
			lm.settings.setSelectedPreset(preset_combo.getSelectedPreset());
		}

		var defaultPresets = new Gee.LinkedList<EqualizerPreset>();
		var customPresets = new Gee.LinkedList<EqualizerPreset>();

		foreach(EqualizerPreset preset in preset_combo.getPresets()) {
			if(preset.is_default == true)
				defaultPresets.add(preset);
			else
				customPresets.add(preset);
		}

		lm.settings.setPresets(defaultPresets, null);
		lm.settings.setPresets(customPresets, "custom-presets");

		lm.settings.setAutoSwitchPreset(automatic_chosen);

		destroy();
		
		return false;
	}
}
