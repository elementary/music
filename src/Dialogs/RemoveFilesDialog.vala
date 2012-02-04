/*-
 * Copyright (c) 2011-2012       Scott Ringwelski <sgringwe@mtu.edu>
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
using Gee;

public class BeatBox.RemoveFilesDialog : Window {
	LibraryWindow lw;
	
	private VBox content;
	private HBox padding;
	
	private Button remove_button;
	private Button trash_button;
	private Button cancel_button;
	
	public signal void remove_media(bool response);
	
	public RemoveFilesDialog (LibraryWindow lw, LinkedList<Media> to_remove, ViewWrapper.Hint media_type) {
		this.lw = lw;
		
		this.set_title("BeatBox");
		
		// set the size based on saved gconf settings
		//this.window_position = WindowPosition.CENTER;
		this.type_hint = Gdk.WindowTypeHint.DIALOG;
		this.set_modal(true);
		this.set_transient_for(lw);
		this.destroy_with_parent = true;
		resizable = false;
		
		content = new VBox(false, 10);
		padding = new HBox(false, 20);
		
		// initialize controls
		Image warning = new Image.from_stock(Gtk.Stock.DIALOG_WARNING, Gtk.IconSize.DIALOG);
		Label title = new Label("");
		Label info = new Label("");
		trash_button = new Button.with_label ("Move to Trash");
		remove_button = new Button.with_label ("Remove from BeatBox");
		cancel_button = new Button.with_label ("Cancel");
		
		bool multiple_media = to_remove.size > 1;
		var media_text = new StringBuilder();
		switch (media_type) {
			case ViewWrapper.Hint.MUSIC:
				media_text.append("Song");
				break;
			case ViewWrapper.Hint.PODCAST:
				media_text.append("Podcast");
				break;
			case ViewWrapper.Hint.AUDIOBOOK:
				media_text.append("Audiobook");
				break;
			case ViewWrapper.Hint.STATION:
				media_text.append("Station");
				break;
		}
		
		// set title text
		title.xalign = 0.0f;
		string title_text = "";
		if (multiple_media) {
			media_text.append_unichar('s'); // Plural form
			title_text = "Remove %d %s from BeatBox?".printf(to_remove.size, media_text.str);
		}
		else {
  			Media m = to_remove.get(0);
  			
  			if(m.mediatype != 3)
				title_text = "Remove \"%s\" From BeatBox?".printf(m.title.replace("&", "&amp;"));
			else
				title_text = "Remove \"%s\" From BeatBox?".printf(m.album_artist.replace("&", "&amp;"));
		}
		title.set_markup("<span weight=\"bold\" size=\"larger\">" + title_text + "</span>");
		
		// set info text
		info.xalign = 0.0f;
		info.set_line_wrap(true);
		string info_text = "This will remove the %s from your library and from any device that automatically syncs with BeatBox.".printf(media_text.str.down());
		info.set_markup(info_text);
		
		// decide if we need the trash button
		bool need_trash = false;
		foreach(var m in to_remove) {
			if(m.uri.has_prefix("file:/")) {
				need_trash = true;
			}
		}
		
		/* set up controls layout */
		HBox information = new HBox(false, 0);
		VBox information_text = new VBox(false, 0);
		information.pack_start(warning, false, false, 10);
		information_text.pack_start(title, false, true, 10);
		information_text.pack_start(info, false, true, 0);
		information.pack_start(information_text, true, true, 10);
		
		HButtonBox bottomButtons = new HButtonBox();
		bottomButtons.set_layout(ButtonBoxStyle.END);
		if(need_trash)	bottomButtons.pack_end(trash_button, false, false, 0);
		bottomButtons.pack_end(cancel_button, false, false, 0);
		bottomButtons.pack_end(remove_button, false, false, 0);
		bottomButtons.set_spacing(10);
		
		content.pack_start(information, false, true, 0);
		content.pack_start(bottomButtons, false, true, 10);
		
		padding.pack_start(content, true, true, 10);
		
		trash_button.clicked.connect ( () => {
			remove_media (true);
			destroy ();
		});

		remove_button.clicked.connect ( () => {
			remove_media (false);
			destroy ();
		});

		cancel_button.clicked.connect ( () => {
			destroy ();
		});
		
		add(padding);
		show_all();
	}
}
