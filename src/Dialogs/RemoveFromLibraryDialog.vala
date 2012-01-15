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

	public signal void remove_media (bool trash_files);

	private LibraryWindow lw;

	private Button remove_button;
	private Button trash_button;
	private Button cancel_button;

	public RemoveFromLibraryDialog (LibraryWindow lw, LinkedList<Media> to_remove,
									 ViewWrapper.Hint media_type)
	{
		this.lw = lw;

		set_title("");
		window_position = WindowPosition.CENTER;
		type_hint = Gdk.WindowTypeHint.DIALOG;
		set_modal(true);
		set_transient_for(lw);
		destroy_with_parent = true;
		resizable = false;
		deletable = false;
		set_size_request (200, -1);

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

		string title_text = "";

		if (multiple_media) {
			media_text.append_unichar('s'); // Plural form
			title_text = "Remove %d %s from BeatBox?".printf(to_remove.size, media_text.str);
		}
		else {
  			Media m = to_remove.get(0);
			title_text = "Remove \"%s\" From BeatBox?".printf(m.title.replace("&", "&amp;"));
		}

		const string TITLE_MARKUP_START = "<span weight=\"bold\" size=\"larger\">";
		const string TITLE_MARKUP_END = "</span>";

		Label title = new Label (TITLE_MARKUP_START + title_text + TITLE_MARKUP_END);
		title.use_markup = true;
		title.halign = Gtk.Align.START;
		title.set_line_wrap(true);

		string info_text = "\nThis will remove the %s from your library and from any device that automatically syncs with BeatBox.\n\nWould you also like to move the file%s to the trash?".printf(media_text.str.down(), (multiple_media)? "s" : "");

		var info = new Label (info_text);
		info.halign = Gtk.Align.START;

		var warning_icon = new Image.from_stock(Gtk.Stock.DIALOG_WARNING, Gtk.IconSize.DIALOG);

		trash_button = new Button.with_label ("Move to Trash");
		remove_button = new Button.with_label ("Remove from BeatBox");
		cancel_button = new Button.with_label ("Cancel");

		/* set up controls layout */
		var content = new Box (Orientation.VERTICAL, 10);
		var padding = new Box (Orientation.HORIZONTAL, 20);

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

