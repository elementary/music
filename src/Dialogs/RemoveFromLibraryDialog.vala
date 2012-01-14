/*-
 * Copyright (c) 2011       Scott Ringwelski <sgringwe@mtu.edu>
 *
 * Originally Written by Victor Eduardo for BeatBox Music Player
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

public class BeatBox.RemoveFromLibraryDialog : Window {

	private LibraryWindow lw;

	public signal void remove_media (bool trash_files);

	private Box content;
	private Box padding;
	private Button remove_button;
	private Button trash_button;
	private Button cancel_button;

	public RemoveFromLibraryDialog (LibraryWindow lw, LinkedList<Media> to_remove, ViewWrapper.Hint media_type) {
		this.lw = lw;
		this.set_title("");
		this.window_position = WindowPosition.CENTER;
		this.type_hint = Gdk.WindowTypeHint.DIALOG;
		this.set_modal(true);
		this.set_transient_for(lw);
		this.destroy_with_parent = true;
		this.resizable = false;
		this.deletable = false;

		set_size_request (200, -1);

		content = new Box (Orientation.VERTICAL, 10);
		padding = new Box (Orientation.HORIZONTAL, 20);

		string media_str = "";
		switch (media_type) {
			case ViewWrapper.Hint.MUSIC:
				media_str = "Song";
				break;
			case ViewWrapper.Hint.PODCAST:
				media_str = "Podcast";
				break;
			case ViewWrapper.Hint.AUDIOBOOK:
				media_str = "Audiobook";
				break;
			case ViewWrapper.Hint.STATION:
				media_str = "Station";
				break;
		}

		bool multiple_media = to_remove.size > 1;

		string title_text = "";

		if (multiple_media) {
			title_text = "Remove %d %ss from BeatBox?".printf(to_remove.size, media_str);
		}
		else {
  			Media m = to_remove.get(0);
			title_text = "Remove \"%s\" From BeatBox?".printf(m.title);
		}

		Label title = new Label ("<span weight=\"bold\" size=\"larger\">" + title_text + "</span>");
		title.use_markup = true;
		title.halign = Gtk.Align.START;
		title.set_line_wrap(true);

		string info_text = "\nThis will remove the %s%s from your library and from any device that automatically syncs with BeatBox.".printf(media_str.down(), (multiple_media)? "s" : ""/*, (multiple_media)? "s" : ""*/);

		Label info = new Label (info_text);
		info.set_line_wrap(true);
		info.halign = Gtk.Align.START;

		trash_button = new Button.with_label ("Move to Trash");
		remove_button = new Button.with_label ("Remove from BeatBox");
		cancel_button = new Button.with_label ("Cancel");

        var warning_icon = new Image.from_stock(Gtk.Stock.DIALOG_WARNING, Gtk.IconSize.DIALOG);

		/* set up controls layout */
		var content_area = new Box (Orientation.HORIZONTAL, 0);
		var info_wrapper = new Box (Orientation.VERTICAL, 0);
        var icon_wrapper = new Box (Orientation.VERTICAL, 0);

        icon_wrapper.pack_start (warning_icon, false, false, 0);
        icon_wrapper.pack_end (new Box (Orientation.VERTICAL, 0), true, true, 0);

		info_wrapper.pack_start (title, false, true, 0);
		info_wrapper.pack_start (info, false, true, 0);

		content_area.pack_start (icon_wrapper, false, false, 0);
		content_area.pack_start (info_wrapper, true, true, 0);

		var bottom_buttons = new ButtonBox (Orientation.HORIZONTAL);

		bottom_buttons.set_layout (ButtonBoxStyle.END);
		bottom_buttons.pack_start (trash_button, false, false, 0);
		bottom_buttons.pack_start (cancel_button, false, false, 0);
		bottom_buttons.pack_end (remove_button, false, false, 0);
		bottom_buttons.set_spacing (10);

		content.pack_start (content_area, true, true, 10);
		content.pack_start (bottom_buttons, false, true, 10);

		padding.pack_start (content, true, true, 12);

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
		cancel_button.grab_focus ();
	}
}

