using Gtk;

public class BeatBox.PresetList : TreeView {
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
		this.set_headers_visible(false);
		
		TreeViewColumn col = new TreeViewColumn();
		col.title = "object";
		col.visible = false;
		this.insert_column(col, 0);
		
		var cell = new CellRendererText();
		cell.ellipsize = Pango.EllipsizeMode.END;
		this.insert_column_with_attributes(-1, "label", cell, "text", 1, null);
		
		this.get_selection().changed.connect(listSelectionChange);
		
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
		TreeModel mo;
		TreeIter it;
		get_selection().get_selected(out mo, out it);
		
		get_selection().select_path( new TreePath.from_string("0") );
		store.remove(it);
	}
	
	public virtual void listSelectionChange() {
		if(get_selection().count_selected_rows() != 1)
			return;
		
		TreeModel mo;
		TreeIter it;
		get_selection().get_selected(out mo, out it);
		
		GLib.Object o;
		mo.get(it, 0, out o);
		
		preset_selected((EqualizerPreset)o);
		scroll_to_cell(mo.get_path(it), null, false, 0.0f, 0.0f);
	}
	
	public void selectPreset(EqualizerPreset? p) {
		get_selection().unselect_all();
		
		if(p == null) {
			get_selection().select_path( new TreePath.from_string("0") );
			return;
		}
		
		TreeIter iter;
		for(int i = 0; store.get_iter_from_string(out iter, i.to_string()); ++i) {
			GLib.Object o;
			store.get(iter, 0, out o);
			
			if(((EqualizerPreset)o).name == p.name) {
				get_selection().select_iter(iter);
				scroll_to_cell(new TreePath.from_string(i.to_string()), null, false, 0.0f, 0.0f);
				stdout.printf("tada\n");
				return;
			}
		}
		
		get_selection().select_path( new TreePath.from_string("0"));
	}
	
	public EqualizerPreset getSelectedPreset() {
		TreeModel mo;
		TreeIter it;
		get_selection().get_selected(out mo, out it);
		
		GLib.Object o;
		mo.get(it, 0, out o);
		
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
