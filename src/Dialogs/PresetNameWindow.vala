/*-
 * Copyright (c) 2011       Scott Ringwelski <sgringwe@mtu.edu>
 *
 * Originaly Written by Scott Ringwelski for BeatBox Music Player
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

/* Merely a place holder for multiple pieces of information regarding
 * the current song playing. Mostly here because of dependence. */

using Gtk;

public class BeatBox.PresetNameWindow : Window {
	public EqualizerPreset _original;
	
	VBox content;
	HBox padding;
	
	public Entry _name;
	public Button _save;
	
	public signal void preset_saved(EqualizerPreset p);

	public PresetNameWindow(LibraryWindow lw, EqualizerPreset original) {
		title = "";
		
		this.window_position = WindowPosition.CENTER;
		this.type_hint = Gdk.WindowTypeHint.DIALOG;
		this.set_modal(true);
		this.set_transient_for(lw);
		this.destroy_with_parent = true;
		resizable = false;
		set_size_request(190, -1);		

		_original = original;
		
		content = new VBox(false, 10);
		padding = new HBox(false, 10);

		/* start out by creating all category labels */
		Label nameLabel = new Label("Name of Preset");
		_name = new Entry();
		_save = new Button.with_label("Done");
		
		/* set up controls */
		nameLabel.xalign = 0.0f;
		nameLabel.set_markup("<b>Name of Preset</b>");
		
		_name.text = original.name;
		
		/* add controls to form */
		HButtonBox bottomButtons = new HButtonBox();
		bottomButtons.set_layout(ButtonBoxStyle.END);
		bottomButtons.pack_end(_save, false, false, 0);
		
		content.pack_start(wrap_alignment(nameLabel, 10, 0, 0, 0), false, true, 0);
		content.pack_start(wrap_alignment(_name, 0, 10, 0, 10), false, true, 0);
		content.pack_start(bottomButtons, false, false, 10);
		
		padding.pack_start(content, true, true, 10);
		
		add(padding);
		
		show_all();
		
		_save.clicked.connect(saveClicked);
		_name.activate.connect(nameActivate);
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
	
	public virtual void saveClicked() {
		_original.name = _name.text;
		preset_saved(_original);
		
		this.destroy();
	}
	
	public virtual void nameActivate() {
		saveClicked();
	}
}
