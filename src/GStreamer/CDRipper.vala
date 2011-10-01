using Gst;

public class BeatBox.CDRipper : GLib.Object {
	public dynamic Gst.Pipeline pipeline;
	public dynamic Gst.Element src;
	public dynamic Gst.Element queue;
	public dynamic Gst.Element filter;
	public dynamic Gst.Element sink;
	
	Song current_song; // song currently being processed/ripped
	private string _device;
	public int track_count;
	private Format _format;
	private bool _isRipping;
	
	public signal void song_ripped(Song s);
	public signal void progress_notification(double progress);
	public signal void error(string err, Message message);
	
	public CDRipper(string device, int count) {
		_device = device;
		track_count = count;
	}
	
	public bool initialize() {
		pipeline = new Gst.Pipeline("pipeline");
		src = ElementFactory.make("cdparanoiasrc", "mycdparanoia");
		queue = ElementFactory.make("queue", "queue");
		filter = ElementFactory.make("lame", "encoder");
		sink = ElementFactory.make("filesink", "filesink");
		
		if(src == null || queue == null || filter == null || sink == null) {
			stdout.printf("Could not create GST Elements for ripping.\n");
			return false;
		}
		
		queue.set("max-size-time", 120 * Gst.SECOND);
		
		_format = Gst.format_get_by_nick("track");
		
		((Gst.Bin)pipeline).add_many(src, queue, filter, sink);
		if(!src.link_many(queue, filter, sink)) {
			return false;
			stdout.printf("CD Ripper link_many failed\n");
		}
		
		pipeline.bus.add_watch(busCallback);
		
		Timeout.add(500, doPositionUpdate);
		
		return true;
	}
	
	public bool doPositionUpdate() {
		progress_notification((double)getPosition()/getDuration());
		
		if(getDuration() <= 0)
			return false;
		else
			return true;
	}
	
	public int64 getPosition() {
		int64 rv = (int64)0;
		Format f = Format.TIME;
		
		src.query_position(ref f, out rv);
		
		return rv;
	}
	
	public int64 getDuration() {
		int64 rv = (int64)0;
		Format f = Format.TIME;
		
		src.query_duration(ref f, out rv);
		
		return rv;
	}
	
	private bool busCallback(Gst.Bus bus, Gst.Message message) {
		switch (message.type) {
			/*case Gst.MessageType.STATE_CHANGED:
				Gst.State oldstate;
				Gst.State newstate;
				Gst.State pending;
				message.parse_state_changed (out oldstate, out newstate,
											 out pending);
				if(oldstate == Gst.State.READY && newstate == Gst.State.PAUSED && pending == Gst.State.PLAYING) {
					var mimetype = "FIX THIS";// probeMimeType();
					
					if(mimetype != null && mimetype != "") {
						stdout.printf("Detected mimetype of %s\n", mimetype);
					}
					else {
						stdout.printf("Could not detect mimetype\n");
					}
				}
				
				break;*/
			case Gst.MessageType.ERROR:
				GLib.Error err;
				string debug;
				message.parse_error (out err, out debug);
				stdout.printf ("Error: %s!:%s\n", err.message, debug);
				break;
			case Gst.MessageType.ELEMENT:
				stdout.printf("missing element\n");
				error("missing element", message);
				
				break;
			case Gst.MessageType.EOS:
				pipeline.set_state(Gst.State.NULL);
				song_ripped(current_song);
				
				break;
			default:
				break;
		}
 
        return true;
    }
    
    public void ripSong(uint track, string path, Song s) {
		sink.set_state(Gst.State.NULL);
		stdout.printf("1\n");
		sink.set("location", path);
		stdout.printf("2\n");
		src.set("track", track);
		current_song = s;
		stdout.printf("3\n");
		/*Iterator<Gst.Element> tagger = ((Gst.Bin)converter).iterate_all_by_interface(typeof(TagSetter));
		tagger.foreach( (el) => {
			
			((Gst.TagSetter)el).add_tags(Gst.TagMergeMode.REPLACE_ALL,
										Gst.TAG_ENCODER, "BeatBox");
			
		});*/
		
		stdout.printf("4\n");
		pipeline.set_state(Gst.State.PLAYING);
	}
}
