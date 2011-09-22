using Gtk;

public class BeatBox.PresetList : ComboBox {
	LibraryManager lm;
	LibraryWindow lw;
	ListStore store;
	
	public signal void preset_selected(EqualizerPreset p);
	
	public PresetList(LibraryManager lm, LibraryWindow lw) {
		this.lm = lm;
		this.lw = lw;
		
		buildUI();
	}
	
	public void buildUI() {
		store = new ListStore(2, typeof(GLib.Object), typeof(string));
		this.set_model(store);
		
		this.set_id_column(1);
		
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
	
	public void addPreset(EqualizerPreset ep) {
		TreeIter iter;
		
		store.append(out iter);
		store.set(iter, 0, ep, 1, ep.name);
	}
	
	public void removeSelected() {
		// TODO: Fixme
	}
	
	public virtual void listSelectionChange() {
		TreeIter it;
		get_active_iter(out it);
		
		GLib.Object o;
		store.get(it, 0, out o);
		
		set_title(((EqualizerPreset)o).name);
		preset_selected((EqualizerPreset)o);
	}
	
	public void selectPreset(EqualizerPreset? p) {
		if(p == null) {
			set_active(0);
		}
		
		TreeIter iter;
		for(int i = 0; store.get_iter_from_string(out iter, i.to_string()); ++i) {
			GLib.Object o;
			store.get(iter, 0, out o);
			
			if(((EqualizerPreset)o).name == p.name) {
				set_active_iter(iter);
				
				stdout.printf("tada\n");
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
			
			rv.add((EqualizerPreset)o);
		}
		
		return rv;
	}
}
