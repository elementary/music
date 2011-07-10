using Gst;

public class BeatBox.Pipeline : GLib.Object {
	public Gst.Pipeline pipe;
	public Equalizer eq;
	public CDDA cdda;
	public ReplayGain gapless;
	public Video video;
	public Ripper ripper;
	
	public dynamic Gst.Bus bus;
	//Pad teepad;
	Pad pad;
	
	dynamic Element audiosink;
	dynamic Element audiosinkqueue;
	dynamic Element eq_audioconvert;
	dynamic Element eq_audioconvert2; 
	 
	public dynamic Gst.Element playbin;
	dynamic Gst.Element audiotee;
	dynamic Gst.Element audiobin;
	dynamic Gst.Element preamp;
	//dynamic Gst.Element volume;
	dynamic Gst.Element rgvolume;
	
	public Pipeline() {
		gapless = new ReplayGain();
		ripper = new Ripper();
		
		pipe = new Gst.Pipeline("pipeline");
		playbin = ElementFactory.make("playbin2", "playbin");
		
		audiosink = ElementFactory.make("autoaudiosink", "audiosink");
		//audiosink.set("profile", 1); // says we handle music and movies
		
		audiobin = new Gst.Bin("audiobin"); // this holds the real primary sink
		
		audiotee = ElementFactory.make("tee", "audiotee");
		audiosinkqueue = ElementFactory.make("queue", "audiosinkqueue");
		
		eq = new Equalizer();
		if(eq.element != null) {
			eq_audioconvert = ElementFactory.make("audioconvert", "audioconvert");
			eq_audioconvert2 = ElementFactory.make("audioconvert", "audioconvert2");
			preamp = ElementFactory.make("volume", "preamp");
			
			((Gst.Bin)audiobin).add_many(eq.element, eq_audioconvert, eq_audioconvert2, preamp);
		}
		
		((Gst.Bin)audiobin).add_many(audiotee, audiosinkqueue, audiosink);
		
		audiobin.add_pad(new GhostPad("sink", audiotee.get_pad("sink")));
		
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
		
		// now add CDDA and Video
		cdda = new CDDA();
		video = new Video();
		if(video.element != null) {
			audiosinkqueue.link_many(video.element);
			//((Gst.Bin)audiobin).add_many(video.element);
			playbin.set("video-sink", video.element);
		}
		
		//bus.add_watch(busCallback);
		/*play.about_to_finish.connect(aboutToFinish);
		play.audio_tags_changed.connect(audioTagsChanged);
		play.text_tags_changed.connect(textTagsChanged);
		play.video_tags_changed.connect(videoTagsChanged);*/
	}
	
	private void videoTagsChanged(Gst.Element sender, int stream_number) {
		
	}

	private void audioTagsChanged(Gst.Element sender, int stream_number) {
		
	}

	private void textTagsChanged(Gst.Element sender, int stream_number) {
		
	}
}
