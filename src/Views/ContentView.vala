/*
 * Copyright (c) 2012 Noise Developers
 *
 * This is a free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this program; see the file COPYING.  If not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Victor Eduardo <victoreduardm@gmail.com>
 */

public interface BeatBox.ContentView : Gtk.Container {
	public signal void import_requested (Gee.LinkedList<int> to_import);

	public abstract ViewWrapper.Hint get_hint ();

	/**
	 * Only useful for playlists. It lets the view associate a unique ID. Usually
	 * the same as the playlist's ID.
	 */
	public abstract int get_relative_id ();

	/**
	 * For some views, get_media() and get_visible_media() return the same contents, since
	 * the view doesn't have any kind of built-in filters. For other views, they don't return
	 * the same since the view has some kind of internal browsing mechanism (e.g. Miller Columns)
	 */
	public abstract Gee.Collection<Media> get_media ();
	public abstract Gee.Collection<Media> get_visible_media ();

	public abstract async void set_media    (Gee.Collection<Media> new_media);
	public abstract async void add_media    (Gee.Collection<Media> to_add);
	public abstract async void remove_media (Gee.Collection<Media> to_remove);
}

