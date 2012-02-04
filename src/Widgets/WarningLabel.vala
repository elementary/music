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

public class BeatBox.WarningLabel : EventBox {

	private Label errorLabel;
	private Image warningIcon;

	public bool show_icon {
		get {
			return warningIcon.visible;
		}
		set {
			warningIcon.set_no_show_all (!value);
			warningIcon.set_visible (value);
		}
	}

	public WarningLabel() {
		errorLabel = new Label("");
		warningIcon = Icons.render_image (Gtk.Stock.DIALOG_WARNING, Gtk.IconSize.DIALOG);

		var content = new Box (Orientation.HORIZONTAL, 10);
		var content_wrapper = new Box (Orientation.HORIZONTAL, 0);
		var outer_box = new Box (Orientation.VERTICAL, 0);
		var top_padding = new Box (Orientation.VERTICAL, 0);
		var bottom_padding = new Box (Orientation.VERTICAL, 0);
		var left_padding = new Box (Orientation.HORIZONTAL, 0);
		var right_padding = new Box (Orientation.HORIZONTAL, 0);

		content.pack_start (wrap_alignment(warningIcon, 0, 10, 10, 10), false, false, 0);
		content.pack_start (errorLabel, false, true, 0);

		content_wrapper.pack_start (left_padding, true, true, 0);
		content_wrapper.pack_start (content, false, true, 0);
		content_wrapper.pack_start (right_padding, true, true, 0);

		outer_box.pack_start (top_padding, true, true, 0);
		outer_box.pack_start (content_wrapper, false, true, 10);
		outer_box.pack_start (bottom_padding, true, true, 0);

		add(outer_box);

		// Change background color.
		override_background_color (Gtk.StateFlags.NORMAL, LibraryWindow.base_color);

		errorLabel.xalign = 0.5f;
		errorLabel.set_justify(Justification.CENTER);
		errorLabel.ellipsize = Pango.EllipsizeMode.END;
	}

	static Gtk.Alignment wrap_alignment (Gtk.Widget widget, int top, int right, int bottom, int left) {

		var alignment = new Gtk.Alignment(0.0f, 0.0f, 1.0f, 1.0f);
		alignment.top_padding = top;
		alignment.right_padding = right;
		alignment.bottom_padding = bottom;
		alignment.left_padding = left;

		alignment.add(widget);
		return alignment;
	}

	public void setWarning(string warning, Gtk.Justification? jst) {
		if (jst == null)
			errorLabel.set_justify(Gtk.Justification.CENTER);
		else
			errorLabel.set_justify(jst);

		errorLabel.set_markup(warning);
	}
}
