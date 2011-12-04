using Gtk;

public class BeatBox.PresetList : ComboBox {
	LibraryManager lm;
	LibraryWindow lw;
	ListStore store;
	
	private int ndefaultpresets;
	private int ncustompresets;

	private bool default_presets_modified;
	
	private bool modifying_list;

	public int preset_list_size {
		get {
			return ndefaultpresets + ncustompresets;
		}
	}

	public bool default_presets_changed {
		get {
			return default_presets_modified;
		} set {
			default_presets_modified = value;
		}
	}
	
	public EqualizerPreset last_selected_preset;

	public signal void preset_selected(EqualizerPreset p);
	public signal void automatic_preset_chosen();
	public signal void add_preset_chosen();
	public signal void delete_preset_chosen();
	
	public PresetList(LibraryManager lm, LibraryWindow lw) {
		this.lm = lm;
		this.lw = lw;

		ndefaultpresets = 0;
		ncustompresets = 0;
		modifying_list = false;
		
		buildUI();
	}
	
	public void buildUI() {
		store = new ListStore(2, typeof(GLib.Object), typeof(string));
		this.set_model(store);
		
		this.set_size_request(-1, 800);
		
		this.set_id_column(1);
		this.set_row_separator_func( (model, iter) => {
			string content = "";
			model.get(iter, 1, out content);
			
			return content == "<separator_item_unique_name>";
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
		store.set(iter, 0, null, 1, "Automatic");
		
		store.append(out iter);
		store.set(iter, 0, null, 1, "<separator_item_unique_name>");

		if(ndefaultpresets < 1) {
			store.append(out iter);
			store.set(iter, 0, null, 1, "Add New...");
		}

		if(this.preset_list_size > 0) {
			store.append(out iter);
			store.set(iter, 0, null, 1, "Delete Current");
		}

		store.append(out iter);
		store.set(iter, 0, null, 1, "<separator_item_unique_name>");
	}
	
	public void addPreset(EqualizerPreset ep) {
		modifying_list = true;
		TreeIter iter;

		if(ep.is_default) {
			ndefaultpresets++;
			default_presets_modified = true;
		} else {
			ncustompresets++;
		}

		if((this.preset_list_size - 1) < 1) {
			clearList();
			addTopOptions();
		}

		store.append(out iter);
		store.set(iter, 0, ep, 1, ep.name);

		modifying_list = false;

		// TODO: Sort item

		set_active_iter(iter);
	}
	
	public void removeCurrentPreset() {
		modifying_list = true;
	
		if(last_selected_preset == null || this.preset_list_size < 1) {
			return;
		}
		
		TreeIter iter;
		for(int i = 0; store.get_iter_from_string(out iter, i.to_string()); ++i) {
			GLib.Object o;
			store.get(iter, 0, out o);
			
			if(o != null && o is EqualizerPreset && ((EqualizerPreset)o) == last_selected_preset) {
				if (((EqualizerPreset)o).is_default) {
					ndefaultpresets--;
					default_presets_modified = true;
				} else {
					ncustompresets--;
				}
				
				store.remove(iter);
			}
		}

		if(this.preset_list_size < 1) {
			clearList();
			addTopOptions();
		}
		
		modifying_list = false;
		set_active(0);
	}
	
	public virtual void listSelectionChange() {
		if(modifying_list)
			return;

		TreeIter it;
		get_active_iter(out it);
		
		GLib.Object o;
		store.get(it, 0, out o);

		if(o != null && o is EqualizerPreset) {
			set_title(((EqualizerPreset)o).name);
			last_selected_preset = (EqualizerPreset)o;
			preset_selected((EqualizerPreset)o);
		}
		else { // is Automatic, Add Preset or Delete Current
			if(get_active() == 0) {
				automatic_preset_chosen();
			}
			else if(get_active() == 2 && ndefaultpresets < 1) {
				add_preset_chosen();
			}
			else {
				delete_preset_chosen();
				selectPreset(last_selected_preset.name);
			}
		}
	}
	
	public void selectAutomaticPreset() {
		set_active(0);
	}
	
	public void selectPreset(string? preset_name) {
		if(preset_name == null || preset_name.length < 1) {
			set_active(0);
		}

		TreeIter iter;
		for(int i = 0; store.get_iter_from_string(out iter, i.to_string()); ++i) {
			GLib.Object o;
			store.get(iter, 0, out o);

			if(o != null && o is EqualizerPreset && ((EqualizerPreset)o).name == preset_name) {
				set_active_iter(iter);
				return;
			}
		}

		set_active(0);
	}
	
	public EqualizerPreset? getSelectedPreset() {
		TreeIter it;
		get_active_iter(out it);
		
		GLib.Object o;
		store.get(it, 0, out o);

		if(o != null && o is EqualizerPreset)
			return (EqualizerPreset)o;
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
				rv.add((EqualizerPreset)o);
		}
		
		return rv;
	}
}

