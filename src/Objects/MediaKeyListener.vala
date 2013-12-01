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

[DBus (name = "org.gnome.SettingsDaemon.MediaKeys")]
public interface GnomeMediaKeys : Object {
    public abstract void GrabMediaPlayerKeys (string application, uint32 time) throws IOError;
    public abstract void ReleaseMediaPlayerKeys (string application) throws IOError;
    public signal void MediaPlayerKeyPressed (string application, string key);
}

public class Noise.MediaKeyListener : Object {

    private static MediaKeyListener? _instance;
    public static MediaKeyListener instance {
        get {
            if (_instance == null)
                _instance = new MediaKeyListener ();
            return _instance;
        }
    }

    private GnomeMediaKeys? media_object;

    public void init () {
        assert (media_object == null);

        try {
            media_object = Bus.get_proxy_sync (BusType.SESSION, "org.gnome.SettingsDaemon", "/org/gnome/SettingsDaemon/MediaKeys");
        } catch (IOError e) {
            warning ("Mediakeys error: %s", e.message);
        }
        
        if(media_object != null) {
            media_object.MediaPlayerKeyPressed.connect(mediaKeyPressed);
            try {
                media_object.GrabMediaPlayerKeys (((Noise.App) GLib.Application.get_default ()).exec_name, (uint32)0);
            }
            catch(IOError err) {
                warning ("Could not grab media player keys: %s", err.message);
            }
        }
    }
    
    public void releaseMediaKeys() {
        try {
            media_object.ReleaseMediaPlayerKeys (((Noise.App) GLib.Application.get_default ()).exec_name);
        }
        catch(IOError err) {
            warning("Could not release media player keys: %s", err.message);
        }
    }
    
    private void mediaKeyPressed(dynamic Object bus, string application, string key) {
        if (application != ((Noise.App) GLib.Application.get_default ()).exec_name)
            return;

        if(key == "Previous") {
            App.main_window.play_previous_media ();
        }
        else if(key == "Play") {
            App.main_window.play_media ();
        }
        else if(key == "Next") {
            App.main_window.play_next_media ();
        }
        else if(key == "Pause") {
            // TODO
        }
        else {
            message ("Unused key pressed: %s", key);
        }
    }
}

