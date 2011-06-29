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

using Gst;
using Gee;

public class BeatBox.StreamPlayer : GLib.Object {
	MainLoop loop;
	dynamic Bin bin;
    dynamic Pipeline pipeline;
    dynamic Element play;
    dynamic Element sink;
    dynamic Element equalizer;
    Gst.Bus bus;
    Song current;
    
    /** signals **/
    public signal void end_of_stream(Song s);
    public signal void current_position_update(int64 position);
    
    public StreamPlayer(string[] args) {
		Gst.init(ref args);
		bin = new Gst.Bin("bin");
		pipeline = new Gst.Pipeline("pipeline");
		play = ElementFactory.make("playbin2", "playbin");
		equalizer = ElementFactory.make("equalizer-nbands", "equalizer");
		sink = ElementFactory.make("autoaudiosink", "sink");
		
		bin.add_many(pipeline, play, equalizer, sink);
		
		equalizer.set("num-bands", 10, null);
		
		bus = play.get_bus();
		bus.add_watch(bus_callback);
		
		GhostPad gPad = new GhostPad("sink", equalizer.get_static_pad("sink"));
		bin.add_pad(gPad);
		
		int[10] freqs = {60, 170, 310, 600, 1000, 3000, 6000, 12000, 14000, 16000};
		
		float last_freq = 0;
		for (int index = 0; index < 10; index++) {
			Gst.Object band = ((Gst.ChildProxy)equalizer).get_child_by_index(index);
			
			float freq = freqs[index];
			float bandwidth = freq - last_freq;
			last_freq = freq;
			
			band.set("freq", freq,
			"bandwidth", bandwidth,
			"gain", 0.0f);
		}
		
		equalizer.link_many(sink, play, pipeline);
		
		// if i uncomment this, my code will not play any music
		//play.set("audio-sink", bin); 
		
		loop = new MainLoop();
		var time = new TimeoutSource(500);
		int switchtime = 0;
		bool switcharoo = false;
		time.set_callback(() => {
			int64 position = 0;
			Gst.Format fmt = Gst.Format.TIME;
			play.query_position(ref fmt, out position);
			current_position_update(position);
			switchtime++;
			
			if(switchtime > 10) {
				stdout.printf("switching\n");
				
				for (int i=0 ; i< 10 ; ++i) {
					float gain = switcharoo ? -24 : 12;
					//if (gain < 0)
					//	gain *= 0.24f;
					//else
					//	gain *= 0.12f;
					
					Gst.Object band = ((Gst.ChildProxy)equalizer).get_child_by_index(i);
					band.set("gain", gain, null);
				}
				
				switcharoo = !switcharoo;
				switchtime = 0;
			}
			
			return true;
		});

		time.attach(loop.get_context());
	}
 
    private bool bus_callback (Gst.Bus bus, Gst.Message message) {
		switch (message.type) {
        case Gst.MessageType.ERROR:
            GLib.Error err;
            string debug;
            message.parse_error (out err, out debug);
            stdout.printf ("Error: %s\n", err.message);
            break;
        case Gst.MessageType.EOS:
			end_of_stream(current);
            break;
        default:
            break;
        }
 
        return true;
    }
	
    public void play_song (Song s) {
		if(s.isPreview) {
			play_uri(s.file);
			return;
		}
		
		if(s.file.length > 2) {// play a new file
			current = s;
			play.uri = "file://" + s.file;
			play.set_state(State.READY);
			play_stream();
		}
		
        play.set_state(State.PLAYING);
    }
    
    public void play_uri(string uri) {
		play.uri = uri;
		play.set_state(State.READY);
		play_stream();
		
		play.set_state(State.PLAYING);
	}
    
    public void play_stream() {
		play.set_state(State.PLAYING);
	}
    
    public void pause_stream() {
		play.set_state(State.PAUSED);
	}
	
	public void seek_position(int64 position) {
		if(play.current_state != State.PLAYING)
			play.seek_simple(Gst.Format.TIME, Gst.SeekFlags.FLUSH, position);
		else
			play.seek_simple(Gst.Format.TIME, Gst.SeekFlags.FLUSH, position);
	}
}
