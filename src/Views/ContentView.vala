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

using Gee;

public interface BeatBox.ContentView : Gtk.Container {

	public signal void import_requested(LinkedList<int> to_import);
	
//	public abstract void set_hint(ViewWrapper.Hint hint);
	public abstract ViewWrapper.Hint get_hint();
	public abstract void set_relative_id(int id);
	public abstract int get_relative_id();
	
	/* TODO */
	
	// set_media
	// remove_media
	// add_media
	
	/* -- end TODO -- */

	// @deprecated:
//	public abstract void set_show_next(Collection<int> medias);
//	public abstract void populate_view();
//	public abstract void append_medias(Collection<int> new_medias);
//	public abstract void remove_medias(Collection<int> to_remove);
//	public abstract void set_as_current_list(int media_id, bool is_initial = false);
//	public abstract void set_statusbar_info();

//	public abstract Collection<int> get_medias();
//	public abstract Collection<int> get_showing_medias();
	
//	public abstract void update_medias(Collection<int> medias); // request to update displayed information
}

