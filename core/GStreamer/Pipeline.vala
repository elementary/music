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
 */

public class Noise.Pipeline : GLib.Object {
    public Gst.Pipeline pipe;
    public Equalizer eq;
    
    public dynamic Gst.Bus bus;
    public Gst.Pad pad;
    
    public dynamic Gst.Element audiosink;
    public dynamic Gst.Element audiosinkqueue;
    public dynamic Gst.Element eq_audioconvert;
    public dynamic Gst.Element eq_audioconvert2; 
     
    public dynamic Gst.Element playbin;
    public dynamic Gst.Element audiotee;
    public dynamic Gst.Element audiobin;
    public dynamic Gst.Element preamp;
    
    public Pipeline() {
        
        pipe = new Gst.Pipeline("pipeline");
        playbin = Gst.ElementFactory.make ("playbin", "play");
        
        audiosink = Gst.ElementFactory.make("autoaudiosink", "audio-sink");
        
        audiobin = new Gst.Bin("audiobin"); // this holds the real primary sink
        
        audiotee = Gst.ElementFactory.make("tee", null);
        audiosinkqueue = Gst.ElementFactory.make("queue", null);
        
        eq = new Equalizer();
        if(eq.element != null) {
            eq_audioconvert = Gst.ElementFactory.make("audioconvert", null);
            eq_audioconvert2 = Gst.ElementFactory.make("audioconvert", null);
            preamp = Gst.ElementFactory.make("volume", "preamp");
            
            ((Gst.Bin)audiobin).add_many(eq.element, eq_audioconvert, eq_audioconvert2, preamp);
        }
        
        ((Gst.Bin)audiobin).add_many(audiotee, audiosinkqueue, audiosink);
        
        audiobin.add_pad (new Gst.GhostPad ("sink", audiotee.get_static_pad ("sink")));
        
        if (eq.element != null)
            audiosinkqueue.link_many(eq_audioconvert, preamp, eq.element, eq_audioconvert2, audiosink);
        else
            audiosinkqueue.link_many(audiosink); // link the queue with the real audio sink
        
        playbin.set("audio-sink", audiobin); 
        bus = playbin.get_bus();
        
        // Link the first tee pad to the primary audio sink queue
        Gst.Pad sinkpad = audiosinkqueue.get_static_pad ("sink");
        pad = audiotee.get_request_pad ("src_%u");
        audiotee.set("alloc-pad", pad);
        pad.link(sinkpad);
    }

    public void enableEqualizer() {
        if (eq.element != null) {
            audiosinkqueue.unlink (audiosink); // link the queue with the real audio sink
            audiosinkqueue.link_many(eq_audioconvert, preamp, eq.element, eq_audioconvert2, audiosink);
        }
    }
    
    public void disableEqualizer() {
        if (eq.element != null) {
            audiosinkqueue.unlink (eq_audioconvert);
            audiosinkqueue.unlink (preamp);
            audiosinkqueue.unlink (eq.element);
            audiosinkqueue.unlink (eq_audioconvert2);
            audiosinkqueue.unlink (audiosink);
            audiosinkqueue.link_many(audiosink); // link the queue with the real audio sink
        }
    }
}
