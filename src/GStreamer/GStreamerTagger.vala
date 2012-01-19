using Gst;
using Gee;

public class BeatBox.GStreamerTagger : GLib.Object {
	LibraryManager lm;
	static int DISCOVER_SET_SIZE = 50;
	Gst.Discoverer d;
	Gst.Discoverer art_d;
	HashMap<string, int> uri_to_id;
	LinkedList<string> path_queue;
	
	public signal void media_imported(Media m);
	public signal void import_error(string file);
	public signal void queue_finished();
	
	bool cancelled;
	
	public GStreamerTagger(LibraryManager lm) {
		this.lm = lm;
		d = new Discoverer((ClockTime)(10*Gst.SECOND));
		d.discovered.connect(import_media);
		d.finished.connect(finished);
		
		art_d = new Discoverer((ClockTime)(10*Gst.SECOND));
		art_d.discovered.connect(import_art);
		art_d.finished.connect(art_finished);
		
		uri_to_id = new HashMap<string, int>();
		path_queue = new LinkedList<string>();
	}
	
	void finished() {
		if(!cancelled && path_queue.size > 0) {
			d = new Discoverer((ClockTime)(10*Gst.SECOND));
			d.discovered.connect(import_media);
			d.finished.connect(finished);
			
			d.start();
			for(int i = 0; i < DISCOVER_SET_SIZE && i < path_queue.size; ++i) {
				d.discover_uri_async("file://" + path_queue.get(i));
			}
		}
		else {
			stdout.printf("queue finished\n");
			queue_finished();
		}
	}
	
	void art_finished() {
		stdout.printf("art finished %d %s\n", path_queue.size, cancelled? "true":"False");
		if(!cancelled && path_queue.size > 0) {
			art_d = new Discoverer((ClockTime)(10*Gst.SECOND));
			art_d.discovered.connect(import_art);
			art_d.finished.connect(art_finished);
			
			art_d.start();
			for(int i = 0; i < DISCOVER_SET_SIZE && i < path_queue.size; ++i) {
				art_d.discover_uri_async(path_queue.get(i));
			}
		}
		else {
			stdout.printf("art queue finished\n");
		}
	}
	
	public void cancel_operations() {
		//d.stop();
		//queue_finished();
		cancelled = true;
	}
	
	public void discoverer_import_medias(LinkedList<string> files) {
		int size = 0;
		cancelled = false;
		path_queue.clear();
		
		foreach(string s in files) {
			path_queue.add(s);
			
			d.start();
			if(size < DISCOVER_SET_SIZE) {
				++size;
				d.discover_uri_async("file://" + s);
			}
		}
	}
	
	public void fetch_art(LinkedList<int> files) {
		return;
		
		
		int size = 0;
		//cancelled = false;
		stdout.printf("gstreamer tagger fetching art for %d\n", files.size);
		
		uri_to_id.clear();
		foreach(int i in files) {
			string uri = lm.media_from_id(i).uri;
			path_queue.add(uri);
			uri_to_id.set(uri, i);
			
			art_d.start();
			if(size < DISCOVER_SET_SIZE) {
				++size;
				art_d.discover_uri_async(uri);
			}
		}
	}
	
	/*public bool discoverer_get_art(Media s) {
		return d.discover_uri_async("file://" + s.file);
	}*/
	
	void import_media(DiscovererInfo info, Error err) {
		path_queue.remove(info.get_uri().replace("file://",""));
		
		if(info != null && info.get_tags() != null) {
			Media s = new Media(info.get_uri());
			
			try {
				string title = "";
				string artist, composer, album_artist, album, grouping, genre, comment, lyrics;
				uint track, track_count, album_number, album_count, bitrate, rating;
				double bpm;
				uint64 duration;
				GLib.Date? date = GLib.Date();
				
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
				//if(info.get_tags().get_uint64(TAG_DURATION, out duration)) {
				//	s.length = (uint)(duration/10000000);
				//}
				//else {
					s.length = get_length(s.uri);
				//}
				
				// see if it has an image data
				//Gst.Buffer buf;
				//if(info.get_tags().get_buffer(TAG_IMAGE, out buf))
				//	s.has_embedded = true;
				
				s.date_added = (int)time_t();
				
				// get the size and convert to MB
				s.file_size = (int)(File.new_for_uri(info.get_uri()).query_info("*", FileQueryInfoFlags.NONE).get_size()/1000000);
				
			}
			finally {
				if(s.title == null || s.title == "") {
					string[] paths = info.get_uri().split("/", 0);
					s.title = paths[paths.length - 1];
				}
				if(s.artist == null || s.artist == "") s.artist = "Unknown Artist";
			}
			
			media_imported(s);
		}
		else {
			Media s = taglib_import_media(info.get_uri());
			
			if(s == null)
				import_error(info.get_uri().replace("file://", ""));
			else
				media_imported(s);
		}
	}
	
	public uint get_length(string uri) {
		uint rv = 0;
		TagLib.File tag_file;
		
		try {
			tag_file = new TagLib.File(uri.replace("file://",""));
		}
		catch {}
		
		if(tag_file != null && tag_file.audioproperties != null) {
			try {
				rv = tag_file.audioproperties.length;
			}
			catch {}
		}
		
		return rv;
	}
	
	public Media? taglib_import_media(string uri) {
		Media s = new Media(uri);
		TagLib.File tag_file;
		
		tag_file = new TagLib.File(uri.replace("file://",""));
		
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
					string[] paths = uri.split("/", 0);
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
	
	void import_art(DiscovererInfo info) {
		return;
		
		path_queue.remove(info.get_uri());
		stdout.printf("discovered %s\n", info.get_uri());
		if(info != null && info.get_tags() != null) {
			try {
				Gst.Buffer buf = null;
				Gdk.Pixbuf? rv = null;
				int i;
				
				// choose the best image based on image type
				for(i = 0; ; ++i) {
					Gst.Buffer buffer;
					Gst.Value? value = null;
					string media_type;
					Gst.Structure caps_struct;
					int imgtype;
					
					value = info.get_tags().get_value_index(TAG_IMAGE, i);
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
				
				stdout.printf("done with for loop\n");
				if(buf == null) {
					//stdout.debug("could not find emedded art for %s\n", s.file);
					return;
				}
				
				// now that we have the buffer we want, load it into the pixbuf
				Gdk.PixbufLoader loader = new Gdk.PixbufLoader();
				stdout.printf("created loader\n");
				try {
					if (!loader.write(buf.data)) {
						//stdout.debug("pixbuf loader doesn't like the data");
						stdout.printf("loader failed\n");
						loader.close();
						return;
					}
				}
				catch(Error err) {
					loader.close();
					return;
				}
				stdout.printf("loaded\n");
				
				try {
					loader.close();
				}
				catch(Error err) {}
				
				rv = loader.get_pixbuf();
				int id = uri_to_id.get(info.get_uri());
				lm.set_album_art(id, rv);
			}
			catch(Error err) {
				stdout.printf("Failed to import album art from %s\n", info.get_uri());
			}
		}
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
	
	public bool save_embeddeart_d(Gdk.Pixbuf pix) {
		
		return false;
	}
}
