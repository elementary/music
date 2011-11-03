using Gtk;

public class BeatBox.PresetList : ComboBox {
	LibraryManager lm;
	LibraryWindow lw;
	ListStore store;
	
	EqualizerPreset currentPreset;
	
	public signal void preset_selected(EqualizerPreset p);
	public signal void automatic_preset_chosen();
	public signal void add_preset_chosen();
	public signal void delete_preset_chosen();
	
	public PresetList(LibraryManager lm, LibraryWindow lw) {
		this.lm = lm;
		this.lw = lw;
		
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
		
		store.append(out iter);
		store.set(iter, 0, null, 1, "Add New...");
		store.append(out iter);
		store.set(iter, 0, null, 1, "Delete Current");
		
		store.append(out iter);
		store.set(iter, 0, null, 1, "<separator_item_unique_name>");
	}
	
	public void addPreset(EqualizerPreset ep) {
		TreeIter iter;
		
		store.append(out iter);
		store.set(iter, 0, ep, 1, ep.name);
		
		// TODO: Sort item
		
		set_active_iter(iter);
	}
	
	public void removeCurrentPreset() {
		if(currentPreset == null) {
			return;
		}
		
		TreeIter iter;
		for(int i = 0; store.get_iter_from_string(out iter, i.to_string()); ++i) {
			GLib.Object o;
			store.get(iter, 0, out o);
			
			if(o != null && o is EqualizerPreset && ((EqualizerPreset)o) == currentPreset) {
				store.remove(iter);
				
				return;
			}
		}
		
		set_active(0);
	}
	
	public virtual void listSelectionChange() {
		TreeIter it;
		get_active_iter(out it);
		
		GLib.Object o;
		store.get(it, 0, out o);
		
		if(o != null && o is EqualizerPreset) {
			set_title(((EqualizerPreset)o).name);
			currentPreset = (EqualizerPreset)o;
			preset_selected((EqualizerPreset)o);
		}
		else { // is Automatic, Add New, or Delete Current
			if(get_active() == 0) {
				automatic_preset_chosen();
			}
			else if(get_active() == 2) {
				add_preset_chosen();
			}
			else if(get_active() == 3) {
				delete_preset_chosen();
				selectPreset(currentPreset);
			}
			
		}
	}
	
	public void selectAutomaticPreset() {
		set_active(0);
	}
	
	public void selectPreset(EqualizerPreset? p) {
		if(p == null) {
			set_active(0);
		}
		
		TreeIter iter;
		for(int i = 0; store.get_iter_from_string(out iter, i.to_string()); ++i) {
			GLib.Object o;
			store.get(iter, 0, out o);
			
			if(o != null && o is EqualizerPreset && ((EqualizerPreset)o).name == p.name) {
				set_active_iter(iter);
				
				return;
			}
		}
		
		set_active(0);
	}
	
	public EqualizerPreset getSelectedPreset() {
		TreeIter it;
		get_active_iter(out it);
		
		GLib.Object o;
		store.get(it, 0, out o);
		
		return (EqualizerPreset)o;
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
