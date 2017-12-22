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

public class Noise.Plugins.CDPlayer : Noise.Playback, GLib.Object {
    InstallGstreamerPluginsDialog dialog;

    private string device;

    public Noise.Pipeline pipe;
    public dynamic unowned Gst.Element playbin2;
    public bool first_start = true;
    private double volume = 1;

    public CDPlayer (Mount mount) {
        device = mount.get_volume ().get_identifier (GLib.VolumeIdentifier.UNIX_DEVICE);
        initialize ();
    }

    public bool initialize () {
        pipe = new Noise.Pipeline ();
        // XXX: The playbin2 is a workaround until the bug https://bugzilla.gnome.org/show_bug.cgi?id=690907 get fixed
        playbin2 = pipe.playbin;
        playbin2.source_setup.connect (pipe_source_setup);
        pipe.playbin.set ("uri", "cdda://1");

        pipe.bus.add_signal_watch ();
        pipe.bus.add_watch (GLib.Priority.DEFAULT, bus_callback);

        Timeout.add (200, update_position);
        return true;
    }

    public void pipe_source_setup (Gst.Element playbin, Gst.Element source) {
        source.set ("device", device);

        if (source.get_class ().find_property ("paranoia-mode") != null)
            source.set ("paranoia-mode", 0);

        if (source.get_class ().find_property ("read-speed") != null)
            source.set ("read-speed", 2);
    }

    public Gee.Collection<string> get_supported_uri () {
        var uris = new Gee.LinkedList<string> ();
        uris.add ("cdda://");
        return uris;
    }

    public bool update_position () {
        if (first_start || (App.player.current_medium != null && get_position() >= (int64)(App.player.current_medium.resume_pos - 1) * 1000000000)) {
            first_start = false;
            current_position_update (get_position());
        } else if (App.player.current_medium != null) {
            pipe.playbin.seek_simple(Gst.Format.TIME, Gst.SeekFlags.FLUSH, (int64)App.player.current_medium.resume_pos * 1000000000);
        }

        return true;
    }

    /* Basic playback functions */
    public void play () {
        set_state (Gst.State.PLAYING);
    }

    public void pause () {
        set_state (Gst.State.PAUSED);
    }

    public void set_state (Gst.State s) {
        pipe.playbin.set_state (s);
    }

    public void set_medium (Medium medium) {
        set_state (Gst.State.READY);
        debug ("set track number to %u\n", medium.track);
        pipe.playbin.set ("uri", "cdda://%u".printf(medium.track));

        set_state (Gst.State.PLAYING);

        debug ("setURI seeking to %d\n", App.player.current_medium.resume_pos);
        pipe.playbin.seek_simple (Gst.Format.TIME, Gst.SeekFlags.FLUSH, (int64)App.player.current_medium.resume_pos * 1000000000);

        play ();
    }

    public void set_position (int64 pos) {
        pipe.playbin.seek (1.0,
        Gst.Format.TIME, Gst.SeekFlags.FLUSH,
        Gst.SeekType.SET, pos,
        Gst.SeekType.NONE, get_duration ());
    }

    public int64 get_position () {
        int64 rv = (int64)0;
        Gst.Format f = Gst.Format.TIME;

        pipe.playbin.query_position (f, out rv);

        return rv;
    }

    public int64 get_duration () {
        int64 rv = (int64)0;
        Gst.Format f = Gst.Format.TIME;

        pipe.playbin.query_duration (f, out rv);

        return rv;
    }

    public void set_volume (double val) {
        pipe.playbin.set ("volume", val);
        volume = val;
    }

    public double get_volume () {
        /*var val = GLib.Value (typeof(double));
        pipe.playbin.get ("volume", ref val);
        return (double)val;*/
        return volume;
    }

    /* Extra stuff */
    public void enable_equalizer () {
        pipe.enableEqualizer ();
    }

    public void disable_equalizer() {
        pipe.disableEqualizer ();
    }

    public void set_equalizer_gain (int index, int val) {
        pipe.eq.setGain (index, val);
    }

    /* Callbacks */
    private bool bus_callback (Gst.Bus bus, Gst.Message message) {
        switch (message.type) {
        case Gst.MessageType.ERROR:
            GLib.Error err;
            string debug;
            message.parse_error (out err, out debug);
            warning ("Error: %s\n", err.message);
            error_occured();
            break;
        case Gst.MessageType.ELEMENT:
            if (message.get_structure () != null && Gst.PbUtils.is_missing_plugin_message (message) && (dialog == null || !dialog.visible)) {
                dialog = new InstallGstreamerPluginsDialog (message);
            }
            break;
        case Gst.MessageType.EOS:
            end_of_stream ();
            break;
        case Gst.MessageType.STATE_CHANGED:
            Gst.State oldstate;
            Gst.State newstate;
            Gst.State pending;
            message.parse_state_changed (out oldstate, out newstate,
                                         out pending);

            if(newstate != Gst.State.PLAYING)
                break;

            break;
        case Gst.MessageType.TAG:
            Gst.TagList tag_list;

            message.parse_tag (out tag_list);
            if (tag_list != null) {
                if (tag_list.get_tag_size (Gst.Tags.TITLE) > 0) {
                    string title = "";
                    tag_list.get_string (Gst.Tags.TITLE, out title);
                    NotificationManager.get_default ().update_track (App.player.current_medium.album_artist + "\n" + title);
                }
            }
            break;
        default:
            break;
        }

        return true;
    }
}
