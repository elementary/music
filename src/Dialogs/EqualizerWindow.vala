/*-
 * Copyright (c) 2011-2012	   Scott Ringwelski <sgringwe@mtu.edu>
 *
 * Originally Written by Scott Ringwelski and Victor Eduardo for
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

public class Noise.EqualizerWindow : Gtk.Window {

	LibraryManager lm;
	LibraryWindow lw;

	private Switch eq_switch;
	private PresetList preset_combo;
	private Entry new_preset_entry;
	private Toolbar bottom_toolbar;
	private ToolItem side_list;
	private ToolItem new_preset_field;
	private Button close_button;

	private bool apply_changes;
	private bool initialized;
	private bool adding_preset;

	private const int ANIMATION_TIMEOUT = 20;

	private List<VScale> scale_list;
	private List<Label> label_list;

	private bool in_transition;
	private Gee.ArrayList<int> target_levels;

	private string new_preset_name;

	public EqualizerWindow (LibraryManager lm, LibraryWindow lw) {

		this.lm = lm;
		this.lw = lw;

		scale_list = new List<VScale>();
		label_list = new List<Label>();
		target_levels = new Gee.ArrayList<int>();

		adding_preset = false;
		initialized = false;
		apply_changes = false;

		build_ui();
		load_presets();

		initialized = true;

		if (Settings.Equalizer.instance.auto_switch_preset) {
			preset_combo.selectAutomaticPreset();
		} else {
			var preset = Settings.Equalizer.instance.selected_preset;
			if (preset != null)
				preset_combo.selectPreset(preset);
		}

		on_eq_switch_toggled ();
		apply_changes = true;
	}

	void build_ui () {
		set_title(_("Equalizer"));

		window_position = WindowPosition.CENTER;
		type_hint = Gdk.WindowTypeHint.DIALOG;
		set_transient_for(lw);
		set_size_request(440, 224);
		resizable = false;
		set_deletable(false);

		set_icon(render_icon(Gtk.Stock.PREFERENCES, IconSize.DIALOG, null));

		var outer_box = new HBox(false, 10);
		var inner_box = new VBox(false, 0);
		var scales = new HBox(false, 0);

		bottom_toolbar = new Toolbar();
		eq_switch = new Switch();
		preset_combo = new PresetList();

		eq_switch.set_active(Settings.Equalizer.instance.equalizer_enabled);

		string[] decibels = {"60", "170", "310", "600", "1k", "3k", "6k", "12k", "14k", "16k"};
		//string[] decibels = {"32", "64", "125", "250", "500", "1k", "2k", "4k", "8k", "16k"};

		for (int index = 0; index < 10; ++index) {
			VBox holder = new VBox(false, 0);
			VScale v = new VScale.with_range(-80, 80, 1);
			v.add_mark(0, PositionType.LEFT, null);
			v.draw_value = false;
			v.inverted = true;

			var label = new Label(decibels[index]);

			holder.pack_start(v, true, true, 0);
			holder.pack_end(UI.wrap_alignment (label, 4, 0, 0, 0), false, false, 0);

			scales.pack_start(holder, true, true, 6);
			scale_list.append(v);
			label_list.append(label);

			v.value_changed.connect( () => {
				if(apply_changes && initialized && !preset_combo.automatic_chosen) {
					App.player.player.setEqualizerGain(scale_list.index(v), (int)scale_list.nth_data(scale_list.index(v)).get_value());

					if(!in_transition) {
						if (!preset_combo.getSelectedPreset().is_default)
							preset_combo.getSelectedPreset().setGain(scale_list.index(v), (int)scale_list.nth_data(scale_list.index(v)).get_value());
						else
							on_default_preset_modified();
					}
				}
			});

		}

		preset_combo.set_size_request(165, -1);

		var eq_switch_item = new ToolItem();
		eq_switch_item.add(eq_switch);

		side_list = new ToolItem();
		side_list.add(preset_combo);

		new_preset_entry = new Entry();

		var entry_icon = Icons.render_icon ("dialog-apply", IconSize.MENU);
		new_preset_entry.set_icon_from_pixbuf(Gtk.EntryIconPosition.SECONDARY, entry_icon);
		new_preset_entry.set_icon_tooltip_text(Gtk.EntryIconPosition.SECONDARY, _("Save preset"));

		new_preset_field = new ToolItem();
		new_preset_field.add(new_preset_entry);

		var space_item = new ToolItem();
		space_item.set_expand(true);

		close_button = new Button.from_stock (Gtk.Stock.CLOSE);
		var close_button_item = new ToolItem();
		close_button.set_size_request(120, -1);
		close_button_item.set_expand(false);
		close_button_item.add(close_button);

		// Set spacing stuff
		eq_switch.valign = preset_combo.valign = close_button.valign = new_preset_entry.valign = Gtk.Align.CENTER;

		// Sync size between entry and combobox
		preset_combo.size_allocate.connect ( (alloc) => {
			new_preset_entry.set_size_request (alloc.width, alloc.height);
		});

		bottom_toolbar.insert(eq_switch_item, 0);
		bottom_toolbar.insert(side_list, 1);
		bottom_toolbar.insert(space_item, 2);
		bottom_toolbar.insert(close_button_item, 3);

		// Set the egtk bottom toolbar style.
		bottom_toolbar.get_style_context().add_class("bottom-toolbar");

		inner_box.pack_end(UI.wrap_alignment (bottom_toolbar, 0, 0, 0, 0), false, false, 0);
		inner_box.pack_start(UI.wrap_alignment (scales, 0, 12, 0, 12), true, true, 10);

		outer_box.pack_start(inner_box);
		add(outer_box);

		eq_switch.notify["active"].connect(on_eq_switch_toggled);
		preset_combo.automatic_preset_chosen.connect(on_automatic_chosen);
		preset_combo.delete_preset_chosen.connect(remove_preset_clicked);
		preset_combo.preset_selected.connect (preset_selected);
		new_preset_entry.activate.connect (add_new_preset);
		new_preset_entry.icon_press.connect (new_preset_entry_icon_pressed);
		new_preset_entry.focus_out_event.connect (on_entry_focus_out);

		close_button.clicked.connect ( () => destroy () );
		destroy.connect(on_quit);

		show_all();
	}

	bool on_entry_focus_out () {
		if (!in_destruction ())
			new_preset_entry.grab_focus();
		return false;
	}

	void set_sliders_sensitivity (bool sensitivity) {
		foreach (var scale in scale_list) {
			label_list.nth_data(scale_list.index(scale)).sensitive = sensitivity;
			scale.sensitive = sensitivity;
		}
	}

	void on_eq_switch_toggled () {
		in_transition = false;

		bool eq_active = eq_switch.get_active();
		preset_combo.sensitive = eq_active;
		set_sliders_sensitivity (eq_active);
		Settings.Equalizer.instance.equalizer_enabled = eq_active;

		if (eq_active) {
			if(!preset_combo.automatic_chosen) {
				EqualizerPreset? selected_preset = preset_combo.getSelectedPreset();

				if (selected_preset != null) {
					for(int i = 0; i < 10; ++i)
						App.player.player.setEqualizerGain(i, selected_preset.getGain(i));
				}
			}
			else {
				preset_combo.selectAutomaticPreset();
			}
		}
		else {
			for (int i = 0; i < 10; ++i)
				App.player.player.setEqualizerGain(i, 0);
		}
	}

	void load_presets () {
		foreach (var preset in Equalizer.get_default_presets ()) {
			preset.is_default = true;
			preset_combo.addPreset(preset);
		}

		foreach (var preset in Settings.Equalizer.instance.getPresets ()) {
			preset_combo.addPreset(preset);
		}
	}

	void save_presets () {
		string[] val = new string[0];

		foreach (var preset in preset_combo.getPresets ()) {
			if (preset.is_default)
			    continue;
			val += preset.to_string ();
		}

		Settings.Equalizer.instance.custom_presets = val;
	}

	void preset_selected (EqualizerPreset p) {

		if (!initialized)
			return;

		set_sliders_sensitivity (true);
		target_levels.clear();

		foreach (int i in p.gains) {
			target_levels.add(i);
		}

		if (in_destruction () || (initialized && !apply_changes) || adding_preset) {
			set_target_levels ();
		}
		else if (!in_transition) {
			in_transition = true;
			Timeout.add(ANIMATION_TIMEOUT, transition_scales);
		}
	}

	void set_target_levels () {
		in_transition = false;

		for (int index = 0; index < 10; ++index)
			scale_list.nth_data(index).set_value(target_levels.get(index));
	}

	bool transition_scales () {
		if (!in_transition)
			return false;

		bool is_finished = true;

		for (int index = 0; index < 10; ++index) {
			double currLvl = scale_list.nth_data(index).get_value();
			double targetLvl = target_levels.get(index);
			double difference = targetLvl - currLvl;

			if (in_destruction () || Math.fabs(difference) <= 1) {
				scale_list.nth_data(index).set_value(targetLvl);
				// if switching from the automatic mode, apply the changes correctly
				if (!preset_combo.automatic_chosen && targetLvl == 0)
					App.player.player.setEqualizerGain (index, 0);
			}
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

	void on_automatic_chosen () {
		Settings.Equalizer.instance.auto_switch_preset = preset_combo.automatic_chosen;

		target_levels.clear();

		for (int i = 0; i < 10; ++i)
			target_levels.add(0);

		set_sliders_sensitivity (false);

		if (apply_changes) {
			in_transition = true;
			Timeout.add (ANIMATION_TIMEOUT, transition_scales);
			save_presets ();
			App.player.change_gains_thread ();
		}
		else {
			set_target_levels ();
		}
	}

	void on_default_preset_modified () {

		if(adding_preset || in_destruction ())
			return;

		adding_preset = true;

		close_button.sensitive = !adding_preset;

		bottom_toolbar.remove(side_list);
		bottom_toolbar.insert(new_preset_field, 1);

		new_preset_name = create_new_preset_name(true);

		new_preset_entry.set_text(new_preset_name);
		eq_switch.sensitive = false;
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

		if(verify_preset_name(new_name))
			new_preset_name = new_name;

		int i = 0;
		int[] gains = new int[10];

		foreach(VScale scale in scale_list) {
			gains[i] = (int)scale_list.nth_data(scale_list.index(scale)).get_value();
			i++;
		}

		var new_preset = new EqualizerPreset.with_gains(new_preset_name, gains);
		preset_combo.addPreset(new_preset);

		bottom_toolbar.remove(new_preset_field);
		bottom_toolbar.insert(side_list, 1);
		bottom_toolbar.show_all();
		eq_switch.sensitive = true;
		adding_preset = false;
		close_button.sensitive = !adding_preset;
	}

	string create_new_preset_name (bool from_current) {

		int i = 0;
		bool is_valid = false;

		string current_preset_name = (from_current)? preset_combo.getSelectedPreset().name : "";
		string preset_name = "...";

		do
		{
			debug ("preset name %s is invalid. Looping", preset_name);
			// We have to be explicit in order to make this translatable
			if (from_current) {
				if (i < 1)
					preset_name = _("%s (Custom)").printf (current_preset_name);
				else
					preset_name = _("%s (Custom %i)").printf (current_preset_name, i);
			}
			else {
				if (i < 1)
					preset_name = _("Custom Preset");
				else
					preset_name = _("Custom Preset %i").printf (i);
			}

			i++;
			is_valid = verify_preset_name(preset_name);

		} while (!is_valid);

		return preset_name;
	}

	public bool verify_preset_name (string preset_name) {
		if (preset_name == null)
			return false;

		if (String.is_white_space (preset_name))
			return false;

		foreach (var preset in preset_combo.getPresets ()) {
			if (preset_name == preset.name)
				return false;
		}

		return true;
	}


	void remove_preset_clicked () {
		preset_combo.removeCurrentPreset();
	}

	void on_quit () {
		if (in_transition)
			set_target_levels ();
		else if (adding_preset)
			add_new_preset ();

		save_presets ();
		Settings.Equalizer.instance.selected_preset = (preset_combo.getSelectedPreset() != null)? preset_combo.getSelectedPreset().name : "";
		Settings.Equalizer.instance.auto_switch_preset = preset_combo.automatic_chosen;
	}
}

