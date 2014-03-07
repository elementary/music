// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012-2013 Noise Developers (http://launchpad.net/noise)
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
 *
 * The Noise authors hereby grant permission for non-GPL compatible
 * GStreamer plugins to be used and distributed together with GStreamer
 * and Noise. This permission is above and beyond the permissions granted
 * by the GPL license by which Noise is covered. If you modify this code
 * you may extend this exception to your version of the code, but you are not
 * obligated to do so. If you do not wish to do so, delete this exception
 * statement from your version.
 *
 * Authored by: Scott Ringwelski <sgringwe@mtu.edu>
 *              Corentin Noël <tintou@mailoo.org>
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
	
	public unowned Playlist music_playlist { get; set; }
	public unowned Playlist podcast_playlist { get; set; } // must only contain podcasts. if not, will ignore others
	public unowned Playlist audiobook_playlist { get; set; } // must only contain audiobooks. if not, will ignore others
	
	public DevicePreferences (string id) {
		this.id = id;
	}
}