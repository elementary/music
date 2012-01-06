using Gst;
using Gee;

public class BeatBox.GStreamerTagger : GLib.Object {
	//LinkedList<Media> new_medias;
	private Gst.Discoverer disc;
	DiscovererInfo info;
	
	/*dynamic Element playbin;
	dynamic Element audiosink;
	dynamic Element videosink;*/
	
	public GStreamerTagger() {
		disc = new Discoverer((ClockTime)(10*Gst.SECOND));
		/*playbin = ElementFactory.make("playbin2", "playbin");
		
		audiosink = ElementFactory.make("fakesink", "audiosink");
		videosink = ElementFactory.make("fakesink", "videosink");
		playbin.set("audio-sink", audiosink); 
		playbin.set("video-sink", videosink);
		var bus = playbin.get_bus();
		bus.add_watch(busCallback);*/
	}
	
	private bool busCallback(Gst.Bus bus, Gst.Message message) {
		switch (message.type) {
		case Gst.MessageType.ERROR:
			GLib.Error err;
			string debug;
			message.parse_error (out err, out debug);
			stdout.printf ("Error importing media: %s\n", err.message);
			
			break;
		/*case Gst.MessageType.ELEMENT:
			if(message.get_structure() != null && is_missing_plugin_message(message) && (dialog == null || !dialog.visible)) {
				dialog = new InstallGstreamerPluginsDialog(lm, lw, message);
			}
			break;*/
		case Gst.MessageType.TAG:
            Gst.TagList tag_list;
            stdout.printf("got tag_list\n");
            message.parse_tag (out tag_list);
            if(tag_list != null) {
				string title = "";
				string album = "";
				string artist = "";
				string album_artist = "";
				if(tag_list.get_tag_size(TAG_TITLE) > 0) {
					tag_list.get_string(TAG_TITLE, out title);
				}
				else if(tag_list.get_tag_size(TAG_ARTIST) > 0) {
					tag_list.get_string(TAG_ARTIST, out artist);
				}
				else if(tag_list.get_tag_size(TAG_ALBUM) > 0) {
					tag_list.get_string(TAG_ALBUM, out album);
				}
				else if(tag_list.get_tag_size(TAG_ALBUM_ARTIST) > 0) {
					tag_list.get_string(TAG_ALBUM_ARTIST, out album_artist);
				}
				
				stdout.printf("tags: %s, %s, %s, %s\n", title, album, artist, album_artist);
			}
            break;
		default:
			break;
		}
 
		return true;
	}
	
	private void foreach_tag (Gst.TagList list, string tag) {
		string tag_string;
		if(list.get_string (tag, out tag_string))
            stdout.printf ("tag: %s = %s\n", tag, tag_string);
    }
	
	public Media? import_media(GLib.File file) {
		//playbin.uri = file.get_uri();
		//playbin.set_state(State.PAUSED);
		
		
		Media s = new Media(file.get_path());
		stdout.printf("importing %s\n", file.get_path());
		
		if(Gst.uri_is_valid (file.get_uri())) {
			try {
				stdout.printf("getting info..\n");
				info = disc.discover_uri(file.get_uri());
				stdout.printf("info recieved\n");
				if(info == null)
					return null;
			}
			catch(GLib.Error err) {
				stdout.printf("Could not read media's metadata\n");
				return null;
			}
		}
		else {
			stdout.printf("Invalid URI used\n");
			return null;
		}
		
		if(info != null && info.get_tags() != null) {
			try {
				string title, artist, composer, album_artist, album, grouping, genre, comment, lyrics;
				uint track, track_count, album_number, album_count, bitrate, rating;
				double bpm;
				int64 duration;
				GLib.Date? date = new GLib.Date();
				
				// get title, artist, album artist, album, genre, comment, lyrics strings
				if(info.get_tags().get_string(TAG_TITLE, out title))
					s.title = title;
				if(info.get_tags().get_string(TAG_ARTIST, out artist))
					s.artist = artist;
				if(info.get_tags().get_string(TAG_COMPOSER, out composer))
					s.composer = composer;
				
				if(info.get_tags().get_string(TAG_ALBUM_ARTIST, out album_artist))
					s.album_artist = album_artist;
				else
					s.album_artist = s.artist;
				
				if(info.get_tags().get_string(TAG_ALBUM, out album))
					s.album = album;
				if(info.get_tags().get_string(TAG_GROUPING, out grouping))
					s.grouping = grouping;
				if(info.get_tags().get_string(TAG_GENRE, out genre))
					s.genre = genre;
				if(info.get_tags().get_string(TAG_COMMENT, out comment))
					s.comment = comment;
				if(info.get_tags().get_string(TAG_LYRICS, out lyrics))
					s.lyrics = lyrics;
				
				// get the year
				if(info.get_tags().get_date(TAG_DATE, out date)) {
					if(date != null)
						s.year = (int)date.get_year();
				}
				// get track/album number/count, bitrating, rating, bpm
				if(info.get_tags().get_uint(TAG_TRACK_NUMBER, out track))
					s.track = (int)track;
				if(info.get_tags().get_uint(TAG_TRACK_COUNT, out track_count))
					s.track_count = track_count;
					
				if(info.get_tags().get_uint(TAG_ALBUM_VOLUME_NUMBER, out album_number))
					s.album_number = album_number;
				if(info.get_tags().get_uint(TAG_ALBUM_VOLUME_COUNT, out album_count))
					s.album_count = album_count;
				
				if(info.get_tags().get_uint(TAG_BITRATE, out bitrate))
					s.bitrate = (int)(bitrate/1000);
				if(info.get_tags().get_uint(TAG_USER_RATING, out rating))
					s.rating = (int)((rating > 0 && rating <= 5) ? rating : 0);
				if(info.get_tags().get_double(TAG_BEATS_PER_MINUTE, out bpm))
					s.bpm = (int)bpm;
				if(info.get_audio_streams().length() > 0)
					s.samplerate = info.get_audio_streams().nth_data(0).get_sample_rate();
				
				// get length
				s.length = (uint)info.get_duration()/100000;
				
				// see if it has an image data
				Gst.Buffer buf;
				if(info.get_tags().get_buffer(TAG_IMAGE, out buf))
					s.has_embedded = true;
				
				s.date_added = (int)time_t();
				stdout.printf("g\n");
				// get the size and convert to MB
				s.file_size = (int)(file.query_info("*", FileQueryInfoFlags.NONE).get_size()/1000000);
				
			}
			finally {
				if(s.title == null || s.title == "") {
					string[] paths = file.get_path().split("/", 0);
					s.title = paths[paths.length - 1];
				}
				if(s.artist == null || s.artist == "") s.artist = "Unknown Artist";
			}
		}
		else {
			return null;
		}
		
		return s;
		//return null;
	}
	
	public Gdk.Pixbuf? get_embedded_art(Media s) {
		
		
		return null;
	}
	
	public bool save_media(Media s) {
		return false;
		
		/*Gst.Pipeline pipe = new Pipeline("pipe");
		Element src = Element.make_from_uri(URIType.SRC, "file://" + s.file, null);
		Element decoder = ElementFactory.make("decodebin", "decoder");
		
		GLib.Signal.connect(decoder, "new-decoded-pad", (GLib.Callback)newDecodedPad, this);
		
		if(!((Gst.Bin)pipe).add_many(src, decoder)) {
			stdout.printf("Could not add src and decoder to pipeline to save metadata\n");
			return false;
		}
		
		if(!src.link_many(decoder)) {
			stdout.printf("Could not link src to decoder to save metadata\n");
			return false;
		}
		
		
		Gst.Element queue = ElementFactory.make("queue", "queue");
		Gst.Element queue2 = ElementFactory.make("queue", "queue2");
		
		if(queue == null || queue2 == null) {
			stdout.printf("could not add create queues to save metadata\n");
			return false;
		}
		
		if(!((Gst.Bin)pipe).add_many(queue, queue2)) {
			stdout.printf("Could not add queue's to save metadata\n");
			return false;
		}
		
		queue.set("max-size-time", 120 * Gst.SECOND);
		
		
		
		
		
		
		
		
		//Element encoder = new_element_from_uri(URIType.SINK, "file://" + s.file, null);
		
		Gst.TagList tags;
		bool rv = true;
		//long day;
		
		tags = new TagList();
		tags.add(TagMergeMode.REPLACE,  TAG_TITLE, s.title,
										TAG_ARTIST, s.artist,
										TAG_COMPOSER, s.composer,
										TAG_ALBUM_ARTIST, s.album_artist,
										TAG_ALBUM, s.album,
										TAG_GROUPING, s.grouping,
										TAG_GENRE, s.genre,
										TAG_COMMENT, s.comment,
										TAG_LYRICS, s.lyrics,
										TAG_TRACK_NUMBER, s.track,
										TAG_TRACK_COUNT, s.track_count,
										TAG_ALBUM_VOLUME_NUMBER, s.album_number,
										TAG_ALBUM_VOLUME_COUNT, s.album_count,
										TAG_USER_RATING, s.rating);
		
		/* fetch date, set new year to s.year, set date */
		
		// now find a tag setter interface and use it
		/*Gst.Iterator iter;
		bool done;

		iter = ((Gst.Bin)pipeline).iterate_all_by_interface(typeof(Gst.TagSetter));
		done = false;
		while (!done) {
			  Gst.TagSetter tagger = null;

			  switch (iter.next(out tagger) {
			  case GST_ITERATOR_OK:
					tagger.merge_tags (tags, GST_TAG_MERGE_REPLACE_ALL);
					break;
			  case GST_ITERATOR_RESYNC:
					iter.resync();
					break;
			  case GST_ITERATOR_ERROR:
					stdout.printf("Could not update metadata on media\n");
					rv = false;
					done = true;
					break;
			  case GST_ITERATOR_DONE:
					done = true;
					break;
			  }
		}
		
		return rv;	*/
	}
	
	public bool save_embedded_art(Gdk.Pixbuf pix) {
		
		return false;
	}
}
