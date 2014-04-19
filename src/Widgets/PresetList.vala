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

public class Noise.PresetList : Gtk.ComboBox {

	public signal void preset_selected(EqualizerPreset p);
	public signal void automatic_preset_chosen();
	public signal void delete_preset_chosen();

	public bool automatic_chosen {
		get {
			return automatic_selected;
		}
	}

	public EqualizerPreset last_selected_preset;

	private int ncustompresets {get; set;}

	private bool modifying_list;
	private bool automatic_selected;

	private Gtk.ListStore store;

	private const string SEPARATOR_NAME = "<separator_item_unique_name>";

    // We cannot make these constants due to issues with N_()
	private static string AUTOMATIC_MODE = _("Automatic");
	private static string DELETE_PRESET = _("Delete Current");

	public PresetList() {
		ncustompresets = 0;
		modifying_list = false;
		automatic_selected = false;

		store = new Gtk.ListStore(2, typeof(GLib.Object), typeof(string));

		buildUI();

		clearList();
		addAutomaticMode();
	}

	public void buildUI() {
		this.set_model(store);

		this.set_id_column(1);
		this.set_row_separator_func( (model, iter) => {
			string content = "";
			model.get(iter, 1, out content);

			return content == SEPARATOR_NAME;
		});

		var cell = new Gtk.CellRendererText();
		cell.ellipsize = Pango.EllipsizeMode.END;
		this.pack_start(cell, true);
		this.add_attribute(cell, "text", 1);

		this.changed.connect(listSelectionChange);

		this.show_all();
	}

	private void clearList() {
		store.clear();
	}

	public void addAutomaticMode() {
		Gtk.TreeIter iter;

		store.append(out iter);
		store.set(iter, 0, null, 1, AUTOMATIC_MODE);

		addSeparator ();
	}

	public void addSeparator () {
		Gtk.TreeIter iter;
		store.append(out iter);
		store.set(iter, 0, null, 1, SEPARATOR_NAME);
	}

	public void addPreset(EqualizerPreset ep) {
		modifying_list = true;

		if(!ep.is_default) {
			/* If the number of custom presets is zero, add a separator */
			if (ncustompresets < 1)
				addSeparator();

   			ncustompresets++;
		}

		Gtk.TreeIter iter;
		store.append(out iter);
		store.set(iter, 0, ep, 1, ep.name);

		modifying_list = false;
		automatic_selected = false;

		set_active_iter(iter);
	}

	public void removeCurrentPreset() {
		modifying_list = true;

		Gtk.TreeIter iter;
		for(int i = 0; store.get_iter_from_string(out iter, i.to_string()); ++i) {
			GLib.Object o;
			store.get(iter, 0, out o);

			if(o != null && o is EqualizerPreset && ((EqualizerPreset)o) == last_selected_preset) {
				if (!((EqualizerPreset)o).is_default) {
					ncustompresets--;
					store.remove(iter);
					break;
				}
			}
		}

		/* If there are no custom presets, remove the separator */
		if (ncustompresets < 1)
			remove_separator_item (-1);

		modifying_list = false;

		selectAutomaticPreset();
	}

	public virtual void listSelectionChange() {
		if (modifying_list)
			return;

		Gtk.TreeIter it;
		get_active_iter (out it);

		GLib.Object o;
		store.get (it, 0, out o);

		if (o != null && o is EqualizerPreset) {
			set_title ((o as EqualizerPreset).name);
			last_selected_preset = o as EqualizerPreset;

			if (!(o as EqualizerPreset).is_default)
				add_delete_preset_option();
			else
				remove_delete_option();

			automatic_selected = false;
			preset_selected(o as EqualizerPreset);
			return;
		}

		string option;
		store.get (it, 1, out option);

		if (option == AUTOMATIC_MODE) {
			automatic_selected = true;
			remove_delete_option();
			automatic_preset_chosen();
		} else if (option == DELETE_PRESET) {
			delete_preset_chosen ();
		}
	}

	public void selectAutomaticPreset() {
		automatic_selected = true;
		automatic_preset_chosen ();
		set_active(0);
	}

	public void selectPreset(string? preset_name) {

		if (!(preset_name == null || preset_name.length < 1)) {
			Gtk.TreeIter iter;
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
		Gtk.TreeIter it;
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

		Gtk.TreeIter iter;
		for(int i = 0; store.get_iter_from_string(out iter, i.to_string()); ++i) {
			GLib.Object o;
			store.get(iter, 0, out o);

			if(o != null && o is EqualizerPreset)
				rv.add(o as EqualizerPreset);
		}

		return rv;
	}

	private void remove_delete_option () {
		Gtk.TreeIter iter;
		for(int i = 0; store.get_iter_from_string(out iter, i.to_string()); ++i) {
			string text;
			store.get(iter, 1, out text);

			if(text != null && text == DELETE_PRESET) {
				store.remove(iter);
				// Also remove the separator ...
				remove_separator_item(1);
			}
		}
	}

	private void remove_separator_item (int index) {
		int count = 0, nitems = store.iter_n_children(null);
		Gtk.TreeIter iter;

		for(int i = nitems - 1; store.get_iter_from_string(out iter, i.to_string()); --i) {
			count++;
			string text;
			store.get(iter, 1, out text);

			if((nitems - index == count || index == -1) && text != null && text == SEPARATOR_NAME) {
				store.remove(iter);
				break;
			}
		}
	}

	private void add_delete_preset_option () {
		bool already_added = false;
		Gtk.TreeIter last_iter, new_iter;

		for(int i = 0; store.get_iter_from_string(out last_iter, i.to_string()); ++i) {
			string text;
			store.get(last_iter, 1, out text);

			if(text != null && text == SEPARATOR_NAME) {
				new_iter = last_iter;

				if (store.iter_next(ref new_iter)) {
					store.get(new_iter, 1, out text);
					already_added = (text == DELETE_PRESET);				
				}
			
				break;
			}
		}

		if (already_added)
			return;

		// Add option
		store.insert_after(out new_iter, last_iter);
		store.set(new_iter, 0, null, 1, DELETE_PRESET);

		last_iter = new_iter;

		// Add separator
		store.insert_after(out new_iter, last_iter);
		store.set(new_iter, 0, null, 1, SEPARATOR_NAME);
	}
}

