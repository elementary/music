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

public class BeatBox.EqualizerPreset {
	public float freq;
	public float width;
	public float gain;
	
	public EqualizerPreset(float freq, float width, float gain) {
		this.freq = freq;
		this.width = width;
		this.gain = gain;
	}
}

public class BeatBox.StreamPlayer : GLib.Object {
	MainLoop loop;
    dynamic Bin bin;
    dynamic Element play;
    dynamic Element sink;
    dynamic Element equalizer;
    Gst.Bus bus;
    Song current;
    
	public ArrayList<BeatBox.EqualizerPreset> presetList;
    
    /** signals **/
    public signal void end_of_stream(Song s);
    public signal void current_position_update(int64 position);
    
    public StreamPlayer(string[] args) {
		Gst.init(ref args);
		bin = new Gst.Bin("bin");
		play = ElementFactory.make("playbin", "playbin");
		equalizer = ElementFactory.make("equalizer-nbands", "equalizer");
		sink = ElementFactory.make("autoaudiosink", "sink");
		
		equalizer.set("num-bands", 3, null);
		
		bus = play.get_bus();
		bus.add_watch(bus_callback);
		
		GhostPad gPad = new GhostPad("sink", equalizer.get_static_pad("sink"));
		bin.add_pad(gPad);
		
		presetList = new ArrayList<BeatBox.EqualizerPreset>();
		presetList.add(new BeatBox.EqualizerPreset(120.0f, 40.0f, -3.0f));
		presetList.add(new BeatBox.EqualizerPreset(500.0f, 20.0f, 12.0f));
		presetList.add(new BeatBox.EqualizerPreset(1503.0f, 2.0f, 15.0f));
		
		for (int index = 0; index < 3; index++) {
			Gst.Object band = ((Gst.ChildProxy)equalizer).get_child_by_index(index);
			band.set("freq", presetList.get(index).freq,
			"bandwidth", presetList.get(index).width,
			"gain", presetList.get(index).gain);
		}
		
		bin.add_many(sink, equalizer);
		equalizer.link(sink);
		
		// if i uncomment this, my code will not play any music
		play.set("audio-sink", bin); 
		
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
				var gains = new LinkedList<int>();
				gains.add(switcharoo ? -24 : 0);
				gains.add(switcharoo ? 0 : 12);
				gains.add(switcharoo ? -12 : 6);
				
				
				for (int i=0 ; i< gains.size ; ++i) {
					float gain = gains.get(i);
					if (gain < 0)
						gain *= 0.24f;
					else
						gain *= 0.12f;
					
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
