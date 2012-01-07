using Gst;
using Gee;

public class BeatBox.GStreamerTagger : GLib.Object {
	//LinkedList<Media> new_medias;
	private Gst.Discoverer disc;
	DiscovererInfo info;
	
	dynamic Element import_playbin;
	dynamic Element import_audiosink;
	dynamic Element import_videosink;
	Gst.Bus import_bus;
	
	dynamic Element artwork_playbin;
	dynamic Element artwork_audiosink;
	dynamic Element artwork_videosink;
	Gst.Bus artwork_bus;
	bool fetching_album_art;
	
	public GStreamerTagger() {
		disc = new Discoverer((ClockTime)(10*Gst.SECOND));
		
		import_playbin = ElementFactory.make("playbin2", null);
		import_audiosink = ElementFactory.make("fakesink", null);
		import_videosink = ElementFactory.make("fakesink", null);
		import_playbin.set("audio-sink", import_audiosink); 
		import_playbin.set("video-sink", import_videosink);
		import_bus = import_playbin.get_bus();
		
		artwork_playbin = ElementFactory.make("playbin2", null);
		artwork_audiosink = ElementFactory.make("fakesink", null);
		artwork_videosink = ElementFactory.make("fakesink", null);
		artwork_playbin.set("audio-sink", artwork_audiosink); 
		artwork_playbin.set("video-sink", artwork_videosink);
		artwork_bus = artwork_playbin.get_bus();
	}
	
	public Media? playbin_import_media(string path) {
		stdout.printf("set state to ready\n");
		import_playbin.set_state(State.READY);
		stdout.printf("set uri\n");
		import_playbin.uri = "file://" + path;
		stdout.printf("set state to paused\n");
		import_playbin.set_state(State.PAUSED);
		
		Media s = new Media(path);
		
		bool done = false;
		bool error_only = true;
		while(!done) {
			stdout.printf("start\n");
			Gst.Message m = import_bus.pop_filtered(Gst.MessageType.ERROR | Gst.MessageType.TAG | Gst.MessageType.ASYNC_DONE);
			stdout.printf("got message\n");
			
			if(m != null) {
				switch (m.type) {
				case Gst.MessageType.ERROR:
					done = true;
					
					break;
				case Gst.MessageType.ASYNC_DONE:
					done = true;
					
					break;
				case Gst.MessageType.TAG:
					error_only = false;
					Gst.TagList tag_list;
					stdout.printf("parsing tags\n");
					m.parse_tag (out tag_list);
					stdout.printf("parsed tags\n");
					if(tag_list != null) {
						string title, artist, composer, album_artist, album, grouping, genre, comment, lyrics;
						uint track, track_count, album_number, album_count, bitrate, rating;
						double bpm;
						uint64 duration;
						GLib.Date? date = new GLib.Date();
						
						// get title, artist, album artist, album, genre, comment, lyrics strings
						if(tag_list.get_string(TAG_TITLE, out title))
							s.title = title;
						if(tag_list.get_string(TAG_ARTIST, out artist))
							s.artist = artist;
						if(tag_list.get_string(TAG_COMPOSER, out composer))
							s.composer = composer;
						stdout.printf("in tags\n");
						if(tag_list.get_string(TAG_ALBUM_ARTIST, out album_artist))
							s.album_artist = album_artist;
						else
							s.album_artist = s.artist;
						stdout.printf("in tags\n");
						if(tag_list.get_string(TAG_ALBUM, out album))
							s.album = album;
						if(tag_list.get_string(TAG_GROUPING, out grouping))
							s.grouping = grouping;
						if(tag_list.get_string(TAG_GENRE, out genre))
							s.genre = genre;
						if(tag_list.get_string(TAG_COMMENT, out comment))
							s.comment = comment;
						if(tag_list.get_string(TAG_LYRICS, out lyrics))
							s.lyrics = lyrics;
						stdout.printf("in tags\n");
						// get the year
						if(tag_list.get_date(TAG_DATE, out date)) {
							if(date != null)
								s.year = (int)date.get_year();
						}
						// get track/album number/count, bitrating, rating, bpm
						if(tag_list.get_uint(TAG_TRACK_NUMBER, out track))
							s.track = (int)track;
						if(tag_list.get_uint(TAG_TRACK_COUNT, out track_count))
							s.track_count = track_count;
							stdout.printf("in tags\n");
						if(tag_list.get_uint(TAG_ALBUM_VOLUME_NUMBER, out album_number))
							s.album_number = album_number;
						if(tag_list.get_uint(TAG_ALBUM_VOLUME_COUNT, out album_count))
							s.album_count = album_count;
						stdout.printf("in tags\n");
						if(tag_list.get_uint(TAG_BITRATE, out bitrate))
							s.bitrate = (int)(bitrate/1000);
						if(tag_list.get_uint(TAG_USER_RATING, out rating))
							s.rating = (int)((rating > 0 && rating <= 5) ? rating : 0);
						if(tag_list.get_double(TAG_BEATS_PER_MINUTE, out bpm))
							s.bpm = (int)bpm;
						//if(info.get_audio_streams().length() > 0)
						//	s.samplerate = info.get_audio_streams().nth_data(0).get_sample_rate();
						
						// get length
						if(tag_list.get_uint64(TAG_DURATION, out duration))
							s.length = (uint)duration/10000000;
						stdout.printf("in tags\n");
						// see if it has an image data
						Gst.Buffer buf;
						if(tag_list.get_buffer(TAG_IMAGE, out buf))
							s.has_embedded = true;
						stdout.printf("in tags\n");
						s.date_added = (int)time_t();
						stdout.printf("in tags\n");
						if(s.artist == "" && s.album_artist != null)
							s.artist = s.album_artist;
						else if(s.album_artist == "" && s.artist != null)
							s.album_artist = s.artist;
					}
					break;
				default:
					break;
				}
			}
			else {
				//done = true;
			}
			
			stdout.printf("in loop\n");
		}
		
		// check if we should use taglib, the backup
		if(error_only) {
			stdout.printf("error only setting state to null\n");
			import_playbin.set_state(State.NULL);
			stdout.printf("state set to null\n");
			s = taglib_import_media(path);
		}
		
		import_playbin.set_state(State.NULL);
		stdout.printf("returned\n");
		return s;
	}
	
	public Media? taglib_import_media(string file_path) {
		Media s = new Media(file_path);
		TagLib.File tag_file;
		
		tag_file = new TagLib.File(file_path);
		
		if(tag_file != null && tag_file.tag != null && tag_file.audioproperties != null) {
			try {
				s.title = tag_file.tag.title;
				s.artist = tag_file.tag.artist;
				s.album = tag_file.tag.album;
				s.genre = tag_file.tag.genre;
				s.comment = tag_file.tag.comment;
				s.year = (int)tag_file.tag.year;
				s.track = (int)tag_file.tag.track;
				s.bitrate = tag_file.audioproperties.bitrate;
				s.length = tag_file.audioproperties.length;
				s.samplerate = tag_file.audioproperties.samplerate;
				s.date_added = (int)time_t();
				
				// get the size and convert to MB
				//s.file_size = (int)(GLib.File.new_for_path(file_path).query_info("*", FileQueryInfoFlags.NONE).get_size()/1000000);
				
			}
			finally {
				if(s.title == null || s.title == "") {
					string[] paths = file_path.split("/", 0);
					s.title = paths[paths.length - 1];
				}
				if(s.artist == null || s.artist == "") s.artist = "Unknown Artist";
				
				s.album_artist = s.artist;
				s.album_number = 1;
			}
		}
		else {
			return null;
		}
		
		return s;
	}
	
	public Media? discoverer_import_media(GLib.File file) {
		if(Gst.uri_is_valid (file.get_uri())) {
			try {
				info = disc.discover_uri(file.get_uri());
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
		
		Media s = new Media(file.get_path());
		stdout.printf("importing %s\n", file.get_path());
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
				s.length = (uint)info.get_duration()/1000000;
				
				// see if it has an image data
				//Gst.Buffer buf;
				//if(info.get_tags().get_buffer(TAG_IMAGE, out buf))
				//	s.has_embedded = true;
				
				s.date_added = (int)time_t();
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
		/*if(fetching_album_art) {
			stdout.printf("user is trying to get album art twice at once\n");
			return null;
		}
		fetching_album_art = true;
		Gdk.Pixbuf? rv = null;
		artwork_playbin.set_state(State.READY);
		artwork_playbin.uri = "file://" + s.file;
		artwork_playbin.set_state(State.PAUSED);
		
		bool done = false;
		bool error_only = true;
		while(!done) {
			 Gst.Message m = artwork_bus.pop_filtered(Gst.MessageType.ERROR | Gst.MessageType.TAG | Gst.MessageType.ASYNC_DONE);
			
			if(m != null) {
				switch (m.type) {
				case Gst.MessageType.ERROR:
					done = true;
					
					break;
				case Gst.MessageType.ASYNC_DONE:
					done = true;
					
					break;
				case Gst.MessageType.TAG:
					error_only = false;
					Gst.TagList tag_list;
					m.parse_tag (out tag_list);
					
					if(tag_list != null) {
						Gst.Buffer buf = null;
						int i;
						
						// choose the best image based on image type
						for(i = 0; ; ++i) {
							Gst.Buffer buffer;
							Gst.Value? value = null;
							string media_type;
							Gst.Structure caps_struct;
							int imgtype;
							
							value = tag_list.get_value_index(TAG_IMAGE, i);
							if(value == null)
								break;
							
							buffer = value.get_buffer();
							if (buffer == null) {
								//stdout.printf("apparently couldn't get image buffer\n");
								continue;
							}
							
							caps_struct = buffer.caps.get_structure(0);
							media_type = caps_struct.get_name();
							if (media_type == "text/uri-list") {
								//stdout.printf("ignoring text/uri-list image tag\n");
								continue;
							}
							
							caps_struct.get_enum ("image-type", typeof(Gst.TagImageType), out imgtype);
							if (imgtype == Gst.TagImageType.UNDEFINED) {
								if (buf == null) {
									//stdout.debug ("got undefined image type\n");
									buf = buffer;
								}
							} else if (imgtype == Gst.TagImageType.FRONT_COVER) {
								//stdout.debug ("got front cover image\n");
								buf = buffer;
							}
						}
						
						if(buf == null) {
							//stdout.debug("could not find emedded art for %s\n", s.file);
							fetching_album_art = false;
							artwork_playbin.set_state(State.NULL);
							return null;
						}
						
						// now that we have the buffer we want, load it into the pixbuf
						Gdk.PixbufLoader loader = new Gdk.PixbufLoader();
						try {
							if (!loader.write(buf.data)) {
								//stdout.debug("pixbuf loader doesn't like the data");
								fetching_album_art = false;
								artwork_playbin.set_state(State.NULL);
								return null;
							}
						}
						catch(Error err) {
							fetching_album_art = false;
							artwork_playbin.set_state(State.NULL);
							loader.close();
							return null;
						}
						loader.close();
						rv = loader.get_pixbuf();
						
						fetching_album_art = false;
						artwork_playbin.set_state(State.NULL);
						stdout.printf("got album artwork for %s by %s\n", s.title, s.album);
						return rv;
					}
					break;
				default:
					break;
				}
			}
			else {
				stdout.printf("message is null\n");
				done = true;
			}
		}
		
		artwork_playbin.set_state(State.NULL);
		fetching_album_art = false;
		return rv;*/
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
