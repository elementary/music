/*-
 * Copyright (c) 2011-2012	Scott Ringwelski <sgringwe@mtu.edu>
 * Copyright (c) 2014 Noise Developers (http://launchpad.net/noise)
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

public class Noise.EqualizerPopover : Gtk.Popover {
	private Gtk.Switch eq_switch;
	private Gtk.Entry new_preset_entry;
	private Gtk.Grid side_list;
	private Gtk.Grid scale_container;
	private PresetList preset_combo;
	private Gee.List<Gtk.Scale> scales;
	private Gee.List<int> target_levels;
	private Settings.Equalizer equalizer_settings;
	private string new_preset_name;
	private bool apply_changes = false;
	private bool initialized = false;
	private bool adding_preset = false;
	private bool in_transition = false;
	private bool closing = false;

	private const int ANIMATION_TIMEOUT = 20;

	private const string[] DECIBELS = {
		"60", "170", "310", "600", "1k", "3k", "6k", "12k", "14k", "16k"
	};

	public EqualizerPopover () {
		scales = new Gee.ArrayList<Gtk.Scale> ();
		target_levels = new Gee.ArrayList<int> ();

		equalizer_settings = Settings.Equalizer.get_default ();

		build_ui ();
		load_presets ();

		initialized = true;

		if (equalizer_settings.auto_switch_preset) {
			preset_combo.selectAutomaticPreset ();
		} else {
			var preset = equalizer_settings.selected_preset;
			if (preset != null)
				preset_combo.selectPreset (preset);
		}

		on_eq_switch_toggled ();
		apply_changes = true;
	}

	public override void closed () {
		closing = true;

		if (in_transition)
			set_target_levels ();
		else if (adding_preset)
			add_new_preset ();

		save_presets ();

		var selected_preset = preset_combo.getSelectedPreset ();
		equalizer_settings.selected_preset = selected_preset != null ? selected_preset.name : "";
		equalizer_settings.auto_switch_preset = preset_combo.automatic_chosen;

		closing = false;
	}

	public bool verify_preset_name (string preset_name) {
		if (preset_name == null || String.is_white_space (preset_name))
			return false;

		foreach (var preset in preset_combo.getPresets ()) {
			if (preset_name == preset.name)
				return false;
		}

		return true;
	}

	private void build_ui () {
		set_size_request (-1, 240);

		scale_container = new Gtk.Grid ();
		scale_container.column_spacing = 12;
		scale_container.margin = 18;
		scale_container.margin_bottom = 0;

		foreach (string decibel in DECIBELS) {
			var scale = new Gtk.Scale.with_range (Gtk.Orientation.VERTICAL, -80, 80, 1);
			scale.add_mark (0, Gtk.PositionType.LEFT, null);
			scale.draw_value = false;
			scale.inverted = true;

			var tag = new Gtk.Label (decibel);

			scale.halign = tag.halign = Gtk.Align.CENTER;
			scale.expand = true;
			tag.hexpand = true;

			var holder = new Gtk.Grid ();
			holder.orientation = Gtk.Orientation.VERTICAL;
			holder.expand = true;
			holder.row_spacing = 4;
			holder.add (scale);
			holder.add (tag);

			scale_container.add (holder);
			scales.add (scale);

			scale.value_changed.connect (() => {
				if (initialized && apply_changes && !preset_combo.automatic_chosen) {
					int index = scales.index_of (scale);
					int val = (int) scale.get_value ();
					apply_equalizer_gain (index, val);

					if (!in_transition) {
						var selected_preset = preset_combo.getSelectedPreset ();

						if (selected_preset.is_default)
							on_default_preset_modified ();
						else
							selected_preset.setGain (index, val);
					}
				}
			});
		}

		eq_switch = new Gtk.Switch ();
		eq_switch.set_active (equalizer_settings.equalizer_enabled);

		preset_combo = new PresetList ();
		preset_combo.set_size_request (165, -1);

		side_list = new Gtk.Grid ();
		side_list.add (preset_combo);

		new_preset_entry = new Gtk.Entry ();
		new_preset_entry.secondary_icon_name = "document-save-symbolic";
		new_preset_entry.secondary_icon_tooltip_text = _("Save preset");

		eq_switch.valign = preset_combo.valign = new_preset_entry.valign = Gtk.Align.CENTER;

		// Sync size between entry and combobox
		preset_combo.size_allocate.connect ((alloc) => {
			new_preset_entry.set_size_request (alloc.width, alloc.height);
			new_preset_entry.queue_resize ();
		});

		var bottom_controls = new Gtk.Grid ();
		bottom_controls.margin = 12;
		bottom_controls.margin_top = 0;
		bottom_controls.add (eq_switch);
		bottom_controls.add (side_list);

		var layout = new Gtk.Grid ();
		layout.orientation = Gtk.Orientation.VERTICAL;
		layout.row_spacing = 12;

		layout.add (scale_container);
		layout.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
		layout.add (bottom_controls);
		layout.show_all ();

		add (layout);

		eq_switch.notify["active"].connect (on_eq_switch_toggled);
		preset_combo.automatic_preset_chosen.connect (on_automatic_chosen);
		preset_combo.delete_preset_chosen.connect (remove_preset_clicked);
		preset_combo.preset_selected.connect (preset_selected);
		new_preset_entry.activate.connect (add_new_preset);
		new_preset_entry.icon_press.connect (new_preset_entry_icon_pressed);
		new_preset_entry.focus_out_event.connect (on_entry_focus_out);
	}

	private void apply_equalizer_gain (int index, int val) {
		App.player.player.set_equalizer_gain (index, val);
	}

	private void apply_automatic_gains () {
		App.player.change_gains_thread ();
	}

	private bool on_entry_focus_out () {
		if (!closing)
			new_preset_entry.grab_focus ();

		return false;
	}

	private void set_sliders_sensitivity (bool sensitivity) {
		scale_container.sensitive = sensitivity;
	}

	private void on_eq_switch_toggled () {
		in_transition = false;

		bool eq_active = eq_switch.active;
		preset_combo.sensitive = eq_active;
		set_sliders_sensitivity (eq_active);
		equalizer_settings.equalizer_enabled = eq_active;

		if (eq_active) {
			if (preset_combo.automatic_chosen) {
				preset_combo.selectAutomaticPreset ();
			} else {
				var selected_preset = preset_combo.getSelectedPreset ();

				if (selected_preset != null) {
					for (int i = 0; i < scales.size; ++i)
						apply_equalizer_gain (i, selected_preset.getGain (i));
				}
			}
		} else {
			for (int i = 0; i < scales.size; ++i)
				apply_equalizer_gain (i, 0);
		}
	}

	private void load_presets () {
		foreach (var preset in Equalizer.get_default_presets ()) {
			preset.is_default = true;
			preset_combo.addPreset (preset);
		}

		foreach (var preset in equalizer_settings.getPresets ())
			preset_combo.addPreset (preset);
	}

	private void save_presets () {
		var val = new string[0];

		foreach (var preset in preset_combo.getPresets ()) {
			if (!preset.is_default)
				val += preset.to_string ();
		}

		equalizer_settings.custom_presets = val;
	}

	private void preset_selected (EqualizerPreset p) {
		if (!initialized)
			return;

		set_sliders_sensitivity (true);
		target_levels.clear ();

		foreach (int i in p.gains)
			target_levels.add (i);

		if (closing || (initialized && !apply_changes) || adding_preset) {
			set_target_levels ();
		} else if (!in_transition) {
			in_transition = true;
			Timeout.add (ANIMATION_TIMEOUT, transition_scales);
		}
	}

	private void set_target_levels () {
		in_transition = false;

		for (int index = 0; index < scales.size; ++index) {
			var scale = scales.get (index);
			scale.set_value (target_levels.get (index));
		}
	}

	private bool transition_scales () {
		if (!in_transition)
			return false;

		bool is_finished = true;

		for (int index = 0; index < scales.size; ++index) {
			var scale = scales.get (index);
			double current_level = scale.get_value ();
			double target_level = target_levels.get (index);
			double difference = target_level - current_level;

			if (closing || Math.fabs (difference) <= 1) {
				scale.set_value (target_level);

				// if switching from the automatic mode, apply the changes correctly
				if (!preset_combo.automatic_chosen && target_level == 0)
					apply_equalizer_gain (index, 0);
			} else {
				scale.set_value (scale.get_value () + (difference / 8.0));
				is_finished = false;
			}
		}

		if (is_finished) {
			in_transition = false;

			// all done. stop
			return false;
		}

		// keep going
		return true;
	}

	private void on_automatic_chosen () {
		equalizer_settings.auto_switch_preset = preset_combo.automatic_chosen;

		target_levels.clear ();

		for (int i = 0; i < scales.size; ++i)
			target_levels.add (0);

		set_sliders_sensitivity (false);

		if (apply_changes) {
			in_transition = true;
			Timeout.add (ANIMATION_TIMEOUT, transition_scales);
			save_presets ();
			apply_automatic_gains ();
		} else {
			set_target_levels ();
		}
	}

	private void on_default_preset_modified () {
		if (adding_preset || closing)
			return;

		adding_preset = true;

		side_list.remove (preset_combo);
		side_list.add (new_preset_entry);
		side_list.show_all ();

		new_preset_name = create_new_preset_name (true);

		new_preset_entry.set_text (new_preset_name);
		eq_switch.sensitive = false;
		new_preset_entry.grab_focus ();
	}

	private void new_preset_entry_icon_pressed (Gtk.EntryIconPosition pos, Gdk.Event event) {
		if (pos != Gtk.EntryIconPosition.SECONDARY && !adding_preset)
			return;

		add_new_preset ();
	}

	private void add_new_preset () {
		if (!adding_preset)
			return;

		var new_name = new_preset_entry.get_text ();

		if (verify_preset_name (new_name))
			new_preset_name = new_name;

		int[] gains = new int[scales.size];

		for (int i = 0; i < scales.size; i++)
			gains[i] = (int) scales.get (i).get_value ();

		var new_preset = new EqualizerPreset.with_gains (new_preset_name, gains);
		preset_combo.addPreset (new_preset);

		side_list.add (preset_combo);
		side_list.set_focus_child (preset_combo);
		side_list.remove (new_preset_entry);
		side_list.show_all ();

		eq_switch.sensitive = true;
		adding_preset = false;
	}

	private string create_new_preset_name (bool from_current) {
		string current_preset_name = from_current ? preset_combo.getSelectedPreset ().name : "";
		string preset_name = "";

		bool is_valid = false;
		int i = 0;

		do {
			debug ("preset name %s is invalid. Looping", preset_name);

			// We have to be explicit in order to make this translatable
			if (from_current) {
				if (i < 1)
					preset_name = _("%s (Custom)").printf (current_preset_name);
				else
					preset_name = _("%s (Custom %i)").printf (current_preset_name, i);
			} else {
				if (i < 1)
					preset_name = _("Custom Preset");
				else
					preset_name = _("Custom Preset %i").printf (i);
			}

			i++;
			is_valid = verify_preset_name (preset_name);
		} while (!is_valid);

		return preset_name;
	}

	private void remove_preset_clicked () {
		preset_combo.removeCurrentPreset ();
	}
}