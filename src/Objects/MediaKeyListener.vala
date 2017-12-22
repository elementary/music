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
 * Authored by: Scott Ringwelski <sgringwe@mtu.edu>
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
            if (_instance == null) {
                _instance = new MediaKeyListener ();
            }

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
        
        if (media_object != null) {
            media_object.MediaPlayerKeyPressed.connect(mediaKeyPressed);
            try {
                media_object.GrabMediaPlayerKeys (((Noise.App) GLib.Application.get_default ()).exec_name, (uint32)0);
            } catch (IOError err) {
                warning ("Could not grab media player keys: %s", err.message);
            }
        }
    }
    
    public void releaseMediaKeys() {
        try {
            media_object.ReleaseMediaPlayerKeys (((Noise.App) GLib.Application.get_default ()).exec_name);
        } catch (IOError err) {
            warning ("Could not release media player keys: %s", err.message);
        }
    }
    
    private void mediaKeyPressed (dynamic Object bus, string application, string key) {
        if (application != ((Noise.App) GLib.Application.get_default ()).exec_name) {
            return;
        }

        switch (key) {
            case "Previous":
                App.main_window.play_previous_media ();
                break;
            case "Play":
                App.main_window.play_media ();
                break;
            case "Next":
                App.main_window.play_next_media ();
                break;
            default:
                message ("Unused key pressed: %s", key);
                break
        }
    }
}

