/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2012-2022 elementary, Inc. (https://elementary.io)
 */

[DBus (name = "org.mpris.MediaPlayer2")]
public class Music.MprisRoot : Object {
    public bool can_quit {
        get {
            return true;
        }
    }

    public bool can_raise {
        get {
            return true;
        }
    }

    public bool has_track_list {
        get {
            return false;
        }
    }

    public string desktop_entry {
        get {
            return "io.elementary.music";
        }
    }

    public string identity {
        get {
            return "io.elementary.music";
        }
    }

    public string[] supported_uri_schemes {
        owned get {
            return {"file"};
        }
    }

    public string[] supported_mime_types {
        owned get {
            return {"audio"};
        }
    }

    public void quit () throws GLib.Error {
        GLib.Application.get_default ().quit ();
    }

    public void raise () throws GLib.Error {
        GLib.Application.get_default ().activate ();
    }
}
