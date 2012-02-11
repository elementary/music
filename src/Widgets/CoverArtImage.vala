/*-
 * Copyright (c) 2011-2012      Scott Ringwelski <sgringwe@mtu.edu>
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
using Gdk;

public class BeatBox.CoverArtImage : Gtk.EventBox {
	LibraryManager lm;
	LibraryWindow lw;

	public Gdk.Pixbuf defaultImage;
	Gdk.Pixbuf image;

	public CoverArtImage(LibraryManager lmm, LibraryWindow lww) {
		lm = lmm;
		lw = lww;

		drag_dest_set(this, DestDefaults.ALL, {}, Gdk.DragAction.MOVE);
		Gtk.drag_dest_add_uri_targets(this);

		draw.connect(draw_event);
	}

	public void set_from_pixbuf(Gdk.Pixbuf buf) {
		image = buf;
		queue_draw();
	}

	public virtual bool draw_event(Cairo.Context cairo) {
		Allocation al;
		get_allocation(out al);

		Gdk.cairo_set_source_pixbuf(cairo, image.scale_simple(al.width, al.width, Gdk.InterpType.BILINEAR), 0, 0);
		cairo.paint();

		return true;
	}
}

