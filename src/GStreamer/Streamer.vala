using Gst;

public class BeatBox.Streamer : GLib.Object {
	LibraryManager lm;
	LibraryWindow lw;
	BeatBox.Pipeline pipe;
	CDRipper ripper;
	
	 /** signals **/
    public signal void end_of_stream();
    public signal void current_position_update(int64 position);
	
	public Streamer(LibraryManager lm, LibraryWindow lw, string[] args) {
		Gst.init(ref args);
		
		this.lm = lm;
		this.lw = lw;
		
		pipe = new BeatBox.Pipeline();
		
		pipe.bus.add_watch(busCallback);
		
		Timeout.add(500, doPositionUpdate);
	}
	
	public void songRipped(Song s) {
		setURI("file://" + s.file);
	}
	
	public bool doPositionUpdate() {
		current_position_update(getPosition());
		Timeout.add(500, doPositionUpdate);
		
		return false;
	}
	
	/* Basic playback functions */
	public void play() {
		setState(State.PLAYING);
	}
	
	public void pause() {
		setState(State.PAUSED);
	}
	
	public void setState(State s) {
		pipe.playbin.set_state(s);
	}
	
	public void setURI(string uri) {
		setState(State.READY);
		pipe.playbin.uri = uri;
		
		if(pipe.video.element != null) {
			var xoverlay = pipe.video.element as XOverlay;
			xoverlay.set_xwindow_id (Gdk.x11_drawable_get_xid (lw.videoArea.window));
		}
		
		setState(State.PLAYING);
		
		play();
	}
	
	public void setPosition(int64 pos) {
		pipe.playbin.seek(1.0,
        Gst.Format.TIME, Gst.SeekFlags.FLUSH,
        Gst.SeekType.SET, pos,
        Gst.SeekType.NONE, getDuration());
	}
	
	public int64 getPosition() {
		int64 rv = (int64)0;
		Format f = Format.TIME;
		
		pipe.playbin.query_position(ref f, out rv);
		
		return rv;
	}
	
	public int64 getDuration() {
		int64 rv = (int64)0;
		Format f = Format.TIME;
		
		pipe.playbin.query_duration(ref f, out rv);
		
		return rv;
	}
	
	/* Extra stuff */
	public void setEqualizerGain(int index, int val) {
		pipe.eq.setGain(index, val);
	}
	
	public void ripCD(string device, int count) {
		ripper = new CDRipper(device, count);
		ripper.ripSong(1, "/home/scott/cdtest/track 1.mp3");
		
		ripper.song_ripped.connect(song_ripped);
	}
	
	public void song_ripped(Song s) {
		if(s.track < ripper.track_count)
			ripper.ripSong(s.track + 1, "/home/scott/cdtest/track " + (s.track + 1).to_string() + ".mp3");
	}
	
	
	/* Callbacks */
	private bool busCallback(Gst.Bus bus, Gst.Message message) {
		switch (message.type) {
        case Gst.MessageType.ERROR:
            GLib.Error err;
            string debug;
            message.parse_error (out err, out debug);
            stdout.printf ("Error: %s\n", err.message);
            break;
        case Gst.MessageType.EOS:
			end_of_stream();
            break;
        default:
            break;
        }
 
        return true;
    }
}
