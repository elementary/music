// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012-2017 elementary LLC. (https://elementary.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * The Noise authors hereby grant permission for non-GPL compatible
 * GStreamer plugins to be used and distributed together with GStreamer
 * and Noise. This permission is above and beyond the permissions granted
 * by the GPL license by which Noise is covered. If you modify this code
 * you may extend this exception to your version of the code, but you are not
 * obligated to do so. If you do not wish to do so, delete this exception
 * statement from your version.
 *
 * Authored by: Corentin Noël <corentin@elementary.io>
 */

public interface Noise.NetworkDevice : GLib.Object {
	public signal void initialized();
	public signal void device_unmounted();
	public signal void progress_notification(string? message, double progress);
	public signal void sync_finished(bool success);

	public abstract bool start_initialization();
	public abstract void finish_initialization();
	public abstract string getContentType();
	public abstract string getDisplayName();
	public abstract void setDisplayName(string name);
	public abstract string get_fancy_description();
	public abstract string get_path();
	public abstract void set_icon(Gdk.Pixbuf icon);
	public abstract Gdk.Pixbuf get_icon();
	public abstract void unmount();
	public abstract void get_device_type();
	public abstract bool supports_podcasts();
	public abstract bool supports_audiobooks();
	public abstract Gee.Collection<Medium> get_medias();
	public abstract Gee.Collection<Medium> get_songs();
	public abstract Gee.Collection<Medium> get_podcasts();
	public abstract Gee.Collection<Medium> get_audiobooks();
	public abstract Gee.Collection<Playlist> get_playlists();
	public abstract Gee.Collection<SmartPlaylist> get_smart_playlists();
}
