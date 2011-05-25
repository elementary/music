using Gst;
using Gee;

public class BeatBox.EqualizerPreset {
	string name;
	float freq;
	float width;
	float gain;
	
	public EqualizerPreset(string name, float freq, float width, float gain) {
		this.name = name;
		this.freq = freq;
		this.width = width;
		this.gain = gain;
	}
}

public class BeatBox.StreamPlayer : GLib.Object {
	MainLoop loop;
    dynamic Element play;
    dynamic Element equalizer;
    Gst.Bus bus;
    Song current;
    
	public ArrayList<BeatBox.EqualizerPreset> presetList;
    
    /** signals **/
    public signal void end_of_stream(Song s);
    public signal void current_position_update(int64 position);
    
    public StreamPlayer(string[] args) {
		Gst.init(ref args);
		play = ElementFactory.make ("playbin", "play");
		equalizer = ElementFactory.make("equalizer-10bands", "equalizer");
		equalizer.set("num-bands", 3, null);
		
		play.link(equalizer);
		
		bus = play.get_bus();
		bus.add_watch(bus_callback);
		
		presetList = new ArrayList<BeatBox.EqualizerPreset>();
		presetList.add(new BeatBox.EqualizerPreset("Rock", 120.0f, 40.0f, -3.0f));
		presetList.add(new BeatBox.EqualizerPreset("Flat", 500.0f, 20.0f, 12.0f));
		presetList.add(new BeatBox.EqualizerPreset("Pop", 1503.0f, 2.0f, 20.0f));
		
		loop = new MainLoop();
		var time = new TimeoutSource(500);

		time.set_callback(() => {
			int64 position = 0;
			Gst.Format fmt = Gst.Format.TIME;
			play.query_position(ref fmt, out position);
			current_position_update(position);
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
		if(s.file.length > 2) {// play a new file
			current = s;
			play.uri = "file://" + s.file;
			play.set_state(State.READY);
			play_stream();
		}
		
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
