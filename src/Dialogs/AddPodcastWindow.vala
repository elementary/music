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

public class BeatBox.AddPodcastWindow : Window {
	public LibraryWindow lw;
	
	VBox content;
	HBox padding;
	
	Granite.Widgets.HintedEntry _source;
	Button _save;
	
	public signal void playlist_saved(Playlist p);
	
	public AddPodcastWindow(LibraryWindow lw) {
		this.lw = lw;
		
		title = "Add Podcast";
		
		set_default_size(400, -1);
		//resize(400, -1);
		
		this.window_position = WindowPosition.CENTER;
		this.type_hint = Gdk.WindowTypeHint.DIALOG;
		this.set_modal(true);
		this.set_transient_for(lw);
		this.destroy_with_parent = true;
		
		content = new VBox(false, 10);
		padding = new HBox(false, 10);
		
		/* start out by creating all category labels */
		Label sourceLabel = new Label("Podcast RSS Source");
		_source = new Granite.Widgets.HintedEntry("Podcast Source...");
		_save = new Button.with_label("Add");
		
		/* set up controls */
		sourceLabel.xalign = 0.0f;
		sourceLabel.set_markup("<b>Podcast RSS Source</b>");
		
		/* add controls to form */
		HButtonBox bottomButtons = new HButtonBox();
		bottomButtons.set_layout(ButtonBoxStyle.END);
		bottomButtons.pack_end(_save, false, false, 0);
		
		content.pack_start(wrap_alignment(sourceLabel, 10, 0, 0, 0), false, true, 0);
		content.pack_start(wrap_alignment(_source, 0, 10, 0, 0), false, true, 0);
		content.pack_start(bottomButtons, false, false, 10);
		
		padding.pack_start(content, true, true, 10);
		
		add(padding);
		
		show_all();
		
		//resize(400, -1);
		
		_save.clicked.connect(saveClicked);
		_source.activate.connect(sourceActivate);
		_source.changed.connect(sourceChanged);
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
	
	void saveClicked() {
		var success = lw.lm.pm.parse_new_rss(_source.get_text());
		
		if(success)
			this.destroy();
		else {
			lw.doAlert("No Podcasts Found", "The provided source is invalid. Make sure you are entering an RSS feed in XML format.");
		}
	}
	
	void sourceActivate() {
		saveClicked();
	}
	
	void sourceChanged() {
		// possibly do on-the-fly validation
	}
}
