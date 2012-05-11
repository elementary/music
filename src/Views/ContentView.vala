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

public interface BeatBox.ContentView : Gtk.Container {
	public signal void import_requested (Gee.LinkedList<int> to_import);
	
	public abstract ViewWrapper.Hint get_hint ();
	public abstract int get_relative_id ();

	public abstract async void set_media    (Gee.Collection<Media> new_media);
	public abstract async void append_media (Gee.Collection<Media> to_add);
	public abstract async void remove_media (Gee.Collection<Media> to_remove);
}

