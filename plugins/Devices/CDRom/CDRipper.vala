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

public class Noise.CDRipper : GLib.Object {
    public dynamic Gst.Pipeline pipeline;
    public dynamic Gst.Element src;
    public dynamic Gst.Element queue;
    public dynamic Gst.Element filter;
    public dynamic Gst.Element sink;

    Noise.Medium current_media; // media currently being processed/ripped
    private string _device;
    public int track_count;
    public int track_index;
    private Gst.Format _format;

    public signal void media_ripped (Noise.Medium s, bool success);
    public signal void progress_notification (double progress);
    public signal void error (string err, Gst.Message message);

    public CDRipper (Mount mount, int count) {
        _device = mount.get_volume ().get_identifier (GLib.VolumeIdentifier.UNIX_DEVICE);
        track_count = count;
    }

    public bool initialize () {
        pipeline = new Gst.Pipeline ("pipeline");
        Gst.Element src = null;
        try {
            src = Gst.Element.make_from_uri (Gst.URIType.SRC, "cdda://", null);
        } catch (Error e) {
            warning (e.message);
        }
        src.set_property ("device", _device);
        queue = Gst.ElementFactory.make ("queue", "queue");
        filter = Gst.ElementFactory.make ("lamemp3enc", "lamemp3enc");
        sink = Gst.ElementFactory.make ("filesink", "filesink");

        if (src == null || queue == null || filter == null || sink == null) {
            critical ("Could not create GST Elements for ripping.\n");
            return false;
        }

        if (src.get_class ().find_property ("paranoia-mode") != null) {
            src.set_property ("paranoia-mode", 0xff);
        }

        // trick cdparanoiasrc into resetting the device speed in case we've
        // previously set it to 1 for playback
        if (src.get_class ().find_property ("read-speed") != null) {
            src.set_property ("read-speed", 0xffff);
        }

        queue.set ("max-size-time", 120 * Gst.SECOND);

        _format = Gst.Format.get_by_nick ("track");

        ((Gst.Bin)pipeline).add_many (src, queue, filter, sink);
        if(!src.link_many (queue, filter, sink)) {
            critical ("CD Ripper link_many failed\n");
            return false;
        }

        pipeline.bus.add_watch (GLib.Priority.DEFAULT, bus_callback);

        Timeout.add (500, do_position_update);

        return true;
    }

    public bool do_position_update () {
        double track_position = ((double) get_position ()) / ((double) get_duration ());
        double track_number = ((double) track_index) / ((double) track_count);
        progress_notification (track_position * track_number);

        if (get_duration () <= 0)
            return false;
        else
            return true;
    }

    public int64 get_position () {
        int64 rv = (int64)0;
        Gst.Format f = Gst.Format.TIME;

        src.query_position (f, out rv);

        return rv;
    }

    public int64 get_duration () {
        int64 rv = (int64)0;
        Gst.Format f = Gst.Format.TIME;

        src.query_duration (f, out rv);

        return rv;
    }

    private bool bus_callback (Gst.Bus bus, Gst.Message message) {
        switch (message.type) {
            /*case Gst.MessageType.STATE_CHANGED:
                Gst.State oldstate;
                Gst.State newstate;
                Gst.State pending;
                message.parse_state_changed (out oldstate, out newstate,
                                             out pending);
                if (oldstate == Gst.State.READY && newstate == Gst.State.PAUSED && pending == Gst.State.PLAYING) {
                    var mimetype = "FIX THIS";// probeMimeType ();

                    if (mimetype != null && mimetype != "") {
                        critical ("Detected mimetype of %s\n", mimetype);
                    }
                    else {
                        critical ("Could not detect mimetype\n");
                    }
                }

                break;*/
            case Gst.MessageType.ERROR:
                error ("error", message);
                break;
            case Gst.MessageType.ELEMENT:
                critical ("missing element\n");
                error ("missing element", message);

                break;
            case Gst.MessageType.EOS:
                pipeline.set_state (Gst.State.NULL);
                current_media.uri = File.new_for_path (sink.location).get_uri ();
                media_ripped (current_media, true);

                break;
            default:
                break;
        }

        return true;
    }

    public void rip_media (uint track, Noise.Medium s) {
        var f = FileUtils.get_new_destination (s);

        sink.set_state (Gst.State.NULL);
        sink.set ("location", f.get_path ());
        src.set ("track", track);
        if (current_media != null)
            current_media.unique_status_image = new ThemedIcon ("process-completed-symbolic");
        track_index++;
        current_media = s;
        current_media.unique_status_image = new ThemedIcon ("view-refresh-symbolic");

        pipeline.set_state (Gst.State.PLAYING);
    }
}
