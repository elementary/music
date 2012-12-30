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

public class Noise.Pipeline : GLib.Object {
	public Gst.Pipeline pipe;
	public Equalizer eq;
	public ReplayGain gapless;
	
	public dynamic Gst.Bus bus;
	//Pad teepad;
	public Gst.Pad pad;
	
	public dynamic Gst.Element audiosink;
	public dynamic Gst.Element audiosinkqueue;
	public dynamic Gst.Element eq_audioconvert;
	public dynamic Gst.Element eq_audioconvert2; 
	 
	public dynamic Gst.Element playbin;
	public dynamic Gst.Element audiotee;
	public dynamic Gst.Element audiobin;
	public dynamic Gst.Element preamp;
	//dynamic Gst.Element volume;
	//dynamic Gst.Element rgvolume;
	
	public Pipeline() {
		gapless = new ReplayGain();
		
		pipe = new Gst.Pipeline("pipeline");
		playbin = Gst.ElementFactory.make("playbin2", "play");
		
		audiosink = Gst.ElementFactory.make("autoaudiosink", "audio-sink");
		//audiosink.set("profile", 1); // says we handle music and movies
		
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
		
		audiobin.add_pad(new Gst.GhostPad("sink", audiotee.get_pad("sink")));
		
		if (eq.element != null)
			audiosinkqueue.link_many(eq_audioconvert, preamp, eq.element, eq_audioconvert2, audiosink);
		else
			audiosinkqueue.link_many(audiosink); // link the queue with the real audio sink
		
		playbin.set("audio-sink", audiobin); 
		bus = playbin.get_bus();
		
		// Link the first tee pad to the primary audio sink queue
		Gst.Pad sinkpad = audiosinkqueue.get_pad("sink");
		pad = audiotee.get_request_pad("src%d");
		audiotee.set("alloc-pad", pad);
		pad.link(sinkpad);
		
		//bus.add_watch(busCallback);
		/*play.audio_tags_changed.connect(audioTagsChanged);
		play.text_tags_changed.connect(textTagsChanged);*/
	}

/*
	private void audioTagsChanged(Gst.Element sender, int stream_number) {
		
	}

	/*private void textTagsChanged(Gst.Element sender, int stream_number) {
		
	}
*/
	
	public void enableEqualizer() {
		if (eq.element != null) {
			audiosinkqueue.unlink_many(audiosink); // link the queue with the real audio sink
			audiosinkqueue.link_many(eq_audioconvert, preamp, eq.element, eq_audioconvert2, audiosink);
		}
	}
	
	public void disableEqualizer() {
		if (eq.element != null) {
			audiosinkqueue.unlink_many(eq_audioconvert, preamp, eq.element, eq_audioconvert2, audiosink);
			audiosinkqueue.link_many(audiosink); // link the queue with the real audio sink
		}
	}
}
