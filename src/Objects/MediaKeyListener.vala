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
	
	public int last_pause_time;
	
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
            try {
				media_object.GrabMediaPlayerKeys("beatbox", (uint32)0);
			}
			catch(IOError err) {
				stdout.printf("Could not grab media player keys: %s\n", err.message);
			}
        }
	}
	
	public void releaseMediaKeys() {
		try {
			media_object.ReleaseMediaPlayerKeys("beatbox");
		}
		catch(IOError err) {
			stdout.printf("Could not release media player keys: %s\n", err.message);
		}
	}
	
	public void showNotification(int i) {
		if(lm.song_from_id(i) == null)
			return;
		
		if(!lw.has_toplevel_focus) {
			try {
				lw.notification.set_timeout(1);
				lw.notification.update(lm.song_from_id(i).title, lm.song_from_id(i).artist + "\n" + lm.song_from_id(i).album, "");
				
				Gdk.Pixbuf notify_pix;
				if(File.new_for_path(lm.song_from_id(i).getAlbumArtPath()).query_exists())
					notify_pix = new Gdk.Pixbuf.from_file(lm.song_from_id(i).getAlbumArtPath());
				else
					notify_pix = lw.render_icon("beatbox", Gtk.IconSize.DIALOG, null);
				
				if(notify_pix != null)
					lw.notification.set_image_from_pixbuf(notify_pix);
				else {
					/* create blank pixbuf so we don't show old album art */
					/*Gdk.Pixbuf blank = new Gdk.Pixbuf(Gdk.Colorspace.RGB, true, 8, 2, 2);
					blank.fill((uint) 0xffffff00);
					notification.set_image_from_pixbuf(blank);*/
				}
				
				lw.notification.show();
				lw.notification.set_timeout(5000);
			}
			catch(GLib.Error err) {
				stderr.printf("Could not show notification: %s\n", err.message);
			}
		}
	}
	
	private void mediaKeyPressed(dynamic Object bus, string application, string key) {
		if(application != "beatbox")
			return;
		
		if(key == "Previous") {
			lw.previousClicked();
			
			if(lm.song_info.song != null)
				showNotification(lm.song_info.song.rowid);
		}
		else if(key == "Play") {
			lw.playClicked();
			
			var elapsed = (int)time_t() - last_pause_time;
			
			if(lm.song_info.song != null && lm.playing && (elapsed > 60))
				showNotification(lm.song_info.song.rowid);
			else if(!lm.playing)
				last_pause_time = (int)time_t();
		}
		else if(key == "Next") {
			lw.nextClicked();
			
			if(lm.song_info.song != null)
				showNotification(lm.song_info.song.rowid);
		}
		else {
			stdout.printf("Unused key pressed: %s\n", key);
		}
	}
}
