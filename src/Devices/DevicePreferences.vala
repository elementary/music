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

public class Noise.DevicePreferences : GLib.Object {
	public string id { get; construct set; }
	
	public bool sync_when_mounted { get; set; }
	public int last_sync_time { get; set; }
	
	public bool sync_music { get; set; default=true; }
	public bool sync_podcasts { get; set; default=false; }
	public bool sync_audiobooks { get; set; default=false; }
	
	public bool sync_all_music { get; set; default=true;}
	public bool sync_all_podcasts { get; set; default=true; }
	public bool sync_all_audiobooks { get; set; default=true; }
	
	public string music_playlist { get; set; }
	public string podcast_playlist { get; set; } // must only contain podcasts. if not, will ignore others
	public string audiobook_playlist { get; set; } // must only contain audiobooks. if not, will ignore others
	
	public DevicePreferences(string id) {
		this.id = id;
	}
}
