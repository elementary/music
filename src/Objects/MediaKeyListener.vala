/*-
 * Copyright (c) 2011       Scott Ringwelski <sgringwe@mtu.edu>
 *
 * Originaly Written by Scott Ringwelski for BeatBox Music Player
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

using GLib;

[DBus (name = "org.gnome.SettingsDaemon.MediaKeys")]
public interface GnomeMediaKeys : GLib.Object {
    public abstract void GrabMediaPlayerKeys (string application, uint32 time) throws GLib.IOError;
    public abstract void ReleaseMediaPlayerKeys (string application) throws GLib.IOError;
    public signal void MediaPlayerKeyPressed (string application, string key);
}

public class BeatBox.MediaKeyListener : GLib.Object {
	private LibraryManager lm;
	private LibraryWindow lw;
	private GnomeMediaKeys media_object;
	
	public MediaKeyListener(LibraryManager lmm, LibraryWindow lww) {
		lm = lmm;
		lw = lww;
		
        try {
            media_object = Bus.get_proxy_sync (BusType.SESSION, "org.gnome.SettingsDaemon", "/org/gnome/SettingsDaemon/MediaKeys");
        } catch (IOError e) {
            stderr.printf ("Mediakeys error: %s\n", e.message);
        }
		
        if(media_object != null) {
            media_object.MediaPlayerKeyPressed.connect(mediaKeyPressed);
            media_object.GrabMediaPlayerKeys("beatbox", (uint32)0);
        }
	}
	
	public void releaseMediaKeys() {
		media_object.ReleaseMediaPlayerKeys("beatbox");
	}
	
	private void mediaKeyPressed(dynamic Object bus, string application, string key) {
		if(application != "beatbox")
			return;
		
		if(key == "Previous") {
			lw.previousClicked();
		}
		else if(key == "Play") {
			lw.playClicked();
		}
		else if(key == "Next") {
			lw.nextClicked();
		}
		else {
			stdout.printf("Unused key pressed: %s\n", key);
		}
	}
}
