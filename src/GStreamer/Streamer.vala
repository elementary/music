using Gst;

public class BeatBox.Streamer : GLib.Object {
	LibraryManager lm;
	LibraryWindow lw;
	BeatBox.Pipeline pipe;
	
	InstallGstreamerPluginsDialog dialog;
	
	 /** signals **/
	public signal void end_of_stream();
	public signal void current_position_update(int64 position);
	public signal void song_not_found();
	
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
		pipe.playbin.uri = uri.replace("#", "%23");
		/*
		if(pipe.video.element != null) {
			var xoverlay = pipe.video.element as XOverlay;
			xoverlay.set_xwindow_id (Gdk.x11_drawable_get_xid (lw.videoArea.window));
		}*/
		
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
	
	public void setVolume(double val) {
		pipe.playbin.volume = val;
	}
	
	public double getVolume() {
		return pipe.playbin.volume;
	}
	
	/* Extra stuff */
	public void enableEqualizer() {
		pipe.enableEqualizer();
	}
	
	public void disableEqualizer() {
		pipe.disableEqualizer();
	}
	
	public void setEqualizerGain(int index, int val) {
		pipe.eq.setGain(index, val);
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
		case Gst.MessageType.ELEMENT:
			if(message.get_structure() != null && is_missing_plugin_message(message) && (dialog == null || !dialog.visible)) {
				dialog = new InstallGstreamerPluginsDialog(lm, lw, message);
			}
			break;
		default:
			break;
		}
 
		return true;
	}
}
