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

public class BeatBox.PresetList : ComboBox {
	LibraryManager lm;
	LibraryWindow lw;
	ListStore store;

	public int preset_list_size {
		get {
			return ndefaultpresets + ncustompresets;
		}
	}

	public bool automatic_chosen {
		get {
			return automatic_selected;
		}
	}

	public bool default_presets_changed;
	
	public EqualizerPreset last_selected_preset;

	public signal void preset_selected(EqualizerPreset p);
	public signal void automatic_preset_chosen();
	public signal void add_preset_chosen();
	public signal void delete_preset_chosen();

	private int ndefaultpresets;
	private int ncustompresets;

	private bool modifying_list;
	private bool automatic_selected;
	
	private const string SEPARATOR_NAME = "<separator_item_unique_name>";

	private const string ADD_NEW_PRESET = "Add New";
	private const string AUTOMATIC_MODE = "Automatic";
	private const string DELETE_PRESET = "Delete Current";

	public PresetList(LibraryManager lm, LibraryWindow lw) {
		this.lm = lm;
		this.lw = lw;

		ndefaultpresets = 0;
		ncustompresets = 0;
		modifying_list = false;
		automatic_selected = false;
		
		buildUI();
	}
	
	public void buildUI() {
		store = new ListStore(2, typeof(GLib.Object), typeof(string));
		this.set_model(store);
		
		this.set_id_column(1);
		this.set_row_separator_func( (model, iter) => {
			string content = "";
			model.get(iter, 1, out content);
			
			return content == SEPARATOR_NAME;
		});
		
		var cell = new CellRendererText();
		cell.ellipsize = Pango.EllipsizeMode.END;
		this.pack_start(cell, true);
		this.add_attribute(cell, "text", 1);
		
		this.changed.connect(listSelectionChange);
		
		this.show_all();
	}
	
	public void clearList() {
		store.clear();
	}
	
	public void addTopOptions() {
		TreeIter iter;

		store.append(out iter);
		store.set(iter, 0, null, 1, AUTOMATIC_MODE);
		
		addSeparator ();
		
		if(ndefaultpresets < 1) {
			store.append(out iter);
			store.set(iter, 0, null, 1, ADD_NEW_PRESET);
		}

		if(this.preset_list_size > 0) {
			store.append(out iter);
			store.set(iter, 0, null, 1, DELETE_PRESET);
			addSeparator ();
		}
	}
	
	public void addSeparator () {
		TreeIter iter;
		store.append(out iter);
		store.set(iter, 0, null, 1, SEPARATOR_NAME);
	}
	
	public void addPreset(EqualizerPreset ep) {
		modifying_list = true;

		if(ep.is_default) {
			ndefaultpresets++;
			default_presets_changed = true;
		} else {
			ncustompresets++;
		}

		if(this.preset_list_size < 2) {
			clearList();
			addTopOptions();
		}

		if (!ep.is_default && ncustompresets < 2 && ndefaultpresets > 0)
			addSeparator ();

		TreeIter iter;
		store.append(out iter);
		store.set(iter, 0, ep, 1, ep.name);

		modifying_list = false;
		automatic_selected = false;
		
		set_active_iter(iter);
	}
	
	public void removeCurrentPreset() {
		modifying_list = true;

		if (automatic_selected || last_selected_preset == null || this.preset_list_size < 1) {
			modifying_list = false;
			selectAutomaticPreset ();
			return;
		}

		TreeIter iter;
		for(int i = 0; store.get_iter_from_string(out iter, i.to_string()); ++i) {
			GLib.Object o;
			store.get(iter, 0, out o);
			
			if(o != null && o is EqualizerPreset && ((EqualizerPreset)o) == last_selected_preset) {
				if (((EqualizerPreset)o).is_default) {
					ndefaultpresets--;
					default_presets_changed = true;
				} else {
					ncustompresets--;
				}
				
				store.remove(iter);
				break;
			}
		}


		if(this.preset_list_size < 1) {
			clearList();
			addTopOptions();
		}

		// If either the list of default or custom presets is empty ...

		if (last_selected_preset.is_default && ndefaultpresets < 1 && ncustompresets > 0) {
			var presets = getPresets ();

			// Update the top options to include 'Add New'
			clearList ();
			addTopOptions ();
			
			foreach (EqualizerPreset p in presets) {
				store.append (out iter);
				store.set (iter, 0, p, 1, p.name);
			}
		}
		else if (!last_selected_preset.is_default && ncustompresets < 1 && ndefaultpresets > 0) {
			remove_preset_separator ();
		}

		modifying_list = false;
		
		selectAutomaticPreset ();
	}

	private void remove_preset_separator () {
		TreeIter iter;		
		for(int i = store.iter_n_children(null) - 1; store.get_iter_from_string(out iter, i.to_string()); --i) {
			string text;
			store.get(iter, 1, out text);

			if(text != null && text == SEPARATOR_NAME) {
				store.remove(iter);
				break;
			}
		}
			
	}
	
	public virtual void listSelectionChange() {
		if (modifying_list)
			return;

		TreeIter it;
		get_active_iter (out it);
		
		GLib.Object o;
		store.get (it, 0, out o);

		if (o != null && o is EqualizerPreset) {
			set_title ((o as EqualizerPreset).name);
			last_selected_preset = o as EqualizerPreset;
			automatic_selected = false;
			preset_selected(o as EqualizerPreset);
			return;
		}

		string option;
		store.get (it, 1, out option);

		if (option != null)
			switch (option)
			{
				case AUTOMATIC_MODE:
					automatic_selected = true;
					automatic_preset_chosen();
					break;
				case ADD_NEW_PRESET:
					add_preset_chosen();
					break;
				case DELETE_PRESET:
					delete_preset_chosen ();
					break;
			}
	}
	
	public void selectAutomaticPreset() {
		automatic_selected = true;
		automatic_preset_chosen ();
		set_active(0);
	}
	
	public void selectPreset(string? preset_name) {

		if (!(preset_name == null || preset_name.length < 1)) {
			TreeIter iter;
			for(int i = 0; store.get_iter_from_string(out iter, i.to_string()); ++i) {
				GLib.Object o;
				store.get(iter, 0, out o);

				if(o != null && o is EqualizerPreset && (o as EqualizerPreset).name == preset_name) {
					set_active_iter(iter);
					automatic_selected = false;
					preset_selected(o as EqualizerPreset);
					return;
				}
			}
		}
		
		selectAutomaticPreset ();
	}
	
	public EqualizerPreset? getSelectedPreset() {
		TreeIter it;
		get_active_iter(out it);
		
		GLib.Object o;
		store.get(it, 0, out o);

		if(o != null && o is EqualizerPreset)
			return o as EqualizerPreset;
		else
			return null;
	}
	
	public Gee.Collection<EqualizerPreset> getPresets() {
		
		var rv = new Gee.LinkedList<EqualizerPreset>();
		
		TreeIter iter;
		for(int i = 0; store.get_iter_from_string(out iter, i.to_string()); ++i) {
			GLib.Object o;
			store.get(iter, 0, out o);
			
			if(o != null && o is EqualizerPreset)
				rv.add(o as EqualizerPreset);
		}
		
		return rv;
	}
}

