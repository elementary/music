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

public interface BeatBox.Device : GLib.Object {
	public signal void initialized(Device d);
	public signal void device_unmounted();
	public signal void progress_notification(string? message, double progress);
	public signal void sync_finished(bool success);
	
	/*public Device(Mount m) {
		this.mount = m;
		
		/*int audio = 0;
		int other = 0;
		FileOperator.guess_content_type(mount.get_default_location(), ref audio, ref other);
		
		audioPercentage = (double)(audio/(other + audio));*
		stdout.printf("created mount at %s and is type %s\n", get_path(), getContentType());
		
		if(getContentType() == "ipod-new" || getContentType() == "ipod-old") {
			var db = GPod.iTunesDB.parse(get_path());
			
			for(int i = 0; i < db.tracks.length(); ++i) {
				stdout.printf("%s %s %s\n", db.tracks.nth_data(i).title, db.tracks.nth_data(i).artist, db.tracks.nth_data(i).album);
			}
		}
	}*/
	
	public abstract DevicePreferences get_preferences();
	public abstract bool start_initialization();
	public abstract void finish_initialization();
	public abstract string getContentType();
	public abstract string getDisplayName();
	public abstract void setDisplayName(string name);
	public abstract string get_fancy_description();
	public abstract void set_mount(Mount mount);
	public abstract Mount get_mount();
	public abstract string get_path();
	public abstract void set_icon(GLib.Icon icon);
	public abstract GLib.Icon get_icon();
	public abstract uint64 get_capacity();
	public abstract string get_fancy_capacity();
	public abstract uint64 get_used_space();
	public abstract uint64 get_free_space();
	public abstract void unmount();
	public abstract void eject();
	public abstract void get_device_type();
	public abstract bool supports_podcasts();
	public abstract bool supports_audiobooks();
	public abstract Collection<int> get_medias();
	public abstract Collection<int> get_songs();
	public abstract Collection<int> get_podcasts();
	public abstract Collection<int> get_audiobooks();
	public abstract Collection<int> get_playlists();
	public abstract Collection<int> get_smart_playlists();
	public abstract bool sync_medias(LinkedList<int> list);
	public abstract bool is_syncing();
	public abstract void cancel_sync();
	public abstract bool will_fit(LinkedList<int> list);
	public abstract bool is_transferring();
	public abstract void cancel_transfer();
	public abstract bool transfer_to_library(LinkedList<int> list);
	
	public string get_unique_identifier() {
		string rv = "";

		var m = get_mount ();

		if (m != null) {
			var root = m.get_root ();
			if (root != null) {
				var root_uri = root.get_uri ();
				if (root_uri != null)
					rv += root_uri;
			}

			var uuid = m.get_uuid();
			if (uuid != null && uuid != "") {
				message ("uuid: %s\n", uuid);
				rv += ("/" + uuid);
			}
		}
		
		return rv;
	}
}

