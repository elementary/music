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
		
		if(pipe.video.element != null) {
			var xoverlay = pipe.video.element as XOverlay;
			xoverlay.set_xwindow_id(Gdk.X11Window.get_xid(lw.videoArea.get_window ()));
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
		case MessageType.TAG:
            Gst.TagList tag_list;
            stdout.printf ("taglist found\n");
            message.parse_tag (out tag_list);
            if(tag_list != null) {
				if(tag_list.get_tag_size(TAG_TITLE) > 0) {
					string title = "";
					tag_list.get_string(TAG_TITLE, out title);
					
					if(lm.song_info.song.mediatype == 3 && title != "") { // is radio
						stdout.printf("title: %s\n", title);
						string[] pieces = title.split("-", 0);
						
						if(pieces.length >= 2) {
							lm.song_info.song.artist = (pieces[0] != null) ? pieces[0].chug().strip() : "Unknown Artist";
							lm.song_info.song.title = (pieces[1] != null) ? pieces[1].chug().strip() : title;
							lw.song_played(lm.song_info.song.rowid, lm.song_info.song.rowid); // pretend as if song changed
						}
						else {
							lm.song_info.song.artist = "Unknown Artist";
							lm.song_info.song.title = title;
							// if the title doesn't follow the general title - artist format, probably not a song change and instead an advert
							lw.updateInfoLabel();
						}
						
					}
				}
				
			}
            break;
		default:
			break;
		}
 
		return true;
	}
	
	private void foreach_tag (Gst.TagList list, string tag) {
		stdout.printf("%s\n", tag);
		switch (tag) {
        case "title":
            string tag_string;
            list.get_string (tag, out tag_string);
            stdout.printf ("tag: %s = %s\n", tag, tag_string);
            break;
        default:
            break;
        }
    }
}
