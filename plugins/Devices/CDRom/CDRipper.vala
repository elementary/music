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

public class Noise.CDRipper : GLib.Object {
    public dynamic Gst.Pipeline pipeline;
    public dynamic Gst.Element src;
    public dynamic Gst.Element queue;
    public dynamic Gst.Element filter;
    public dynamic Gst.Element sink;
    
    Noise.Media current_media; // media currently being processed/ripped
    private string _device;
    public int track_count;
    public int track_index;
    private Gst.Format _format;
    
    public signal void media_ripped (Noise.Media s, bool success);
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
        filter = Gst.ElementFactory.make ("lame", "encoder");
        sink = Gst.ElementFactory.make ("filesink", "filesink");
        
        if (src == null || queue == null || filter == null || sink == null) {
            critical ("Could not create GST Elements for ripping.\n");
            return false;
        }
        
        if (src.get_class ().find_property ("paranoia-mode") != null)
            src.set_property ("paranoia-mode", 0xff);

        /* trick cdparanoiasrc into resetting the device speed in case we've
         * previously set it to 1 for playback
         */
        
        if (src.get_class ().find_property ("read-speed") != null)
            src.set_property ("read-speed", 0xffff);
        
        queue.set ("max-size-time", 120 * Gst.SECOND);
        
        _format = Gst.Format.get_by_nick ("track");
        
        ((Gst.Bin)pipeline).add_many (src, queue, filter, sink);
        if(!src.link_many (queue, filter, sink)) {
            critical ("CD Ripper link_many failed\n");
            return false;
        }
        
        pipeline.bus.add_watch (GLib.Priority.DEFAULT, busCallback);
        
        Timeout.add (500, doPositionUpdate);
        
        return true;
    }
    
    public bool doPositionUpdate () {
        double track_position = ((double) getPosition ()) / ((double) getDuration ());
        double track_number = ((double) track_index) / ((double) track_count);
        progress_notification (track_position * track_number);
        
        if (getDuration () <= 0)
            return false;
        else
            return true;
    }
    
    public int64 getPosition () {
        int64 rv = (int64)0;
        Gst.Format f = Gst.Format.TIME;
        
        src.query_position (f, out rv);
        
        return rv;
    }
    
    public int64 getDuration () {
        int64 rv = (int64)0;
        Gst.Format f = Gst.Format.TIME;
        
        src.query_duration (f, out rv);
        
        return rv;
    }
    
    private bool busCallback (Gst.Bus bus, Gst.Message message) {
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
    
    public void ripMedia (uint track, Noise.Media s) {
        var f = FileUtils.get_new_destination (s);
        
        sink.set_state (Gst.State.NULL);
        sink.set ("location", f.get_path ());
        src.set ("track", track);
        if (current_media != null)
            current_media.unique_status_image = Icons.PROCESS_COMPLETED.render (Gtk.IconSize.MENU);
        track_index++;
        current_media = s;
        current_media.unique_status_image = Icons.REFRESH_SYMBOLIC.render (Gtk.IconSize.MENU);
        
        
        /*Iterator<Gst.Element> tagger = ((Gst.Bin)converter).iterate_all_by_interface (typeof (TagSetter));
        tagger.foreach ( (el) => {
            
            ((Gst.TagSetter)el).add_tags (Gst.TagMergeMode.REPLACE_ALL,
                                        Gst.TAG_ENCODER, "Noise");
            
        });*/
        
        pipeline.set_state (Gst.State.PLAYING);
    }
}
