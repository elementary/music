using Gee;

public class BeatBox.PodcastManager : GLib.Object {
	LibraryManager lm;
	LibraryWindow lw;
	bool fetching;
	bool user_cancelled;
	bool saving_locally;
	
	int index;
	int total;
	GLib.File new_dest;
	int64 online_size;
	string current_operation;
	
	Collection<int> save_locally_ids;
	
	public PodcastManager(LibraryManager lm, LibraryWindow lw) {
		this.lm = lm;
		this.lw = lw;
		fetching = saving_locally = false;
		user_cancelled = false;
		index = total = 0;
		
		lm.progress_cancel_clicked.connect( () => { 
			user_cancelled = true;
			current_operation = "<b>Cancelling</b> remaining downloads...";
		} );
	}
	
	public void find_new_podcasts() {
		if(fetching || lm.doing_file_operations()) {
			stdout.printf("Not going to find new podcasts, already fetching\n");
			return;
		}
		
		lm.start_file_operations("Fetching new Podcast Episodes");
		try {
			Thread.create<void*>(find_new_podcasts_thread, false);
		}
		catch(GLib.ThreadError err) {
			stdout.printf("ERROR: Could not create thread to fetch new podcasts: %s \n", err.message);
		}
		
		lm.have_fetched_new_podcasts = true;
	}
		
	public void* find_new_podcasts_thread () {
		HashSet<string> rss_urls = new HashSet<string>();
		HashSet<string> mp3_urls = new HashSet<string>();
		HashMap<string, string> rss_names = new HashMap<string, string>();
		
		foreach(int i in lm.podcast_ids()) {
			var pod = lm.song_from_id(i);
			
			rss_urls.add(pod.podcast_rss);
			mp3_urls.add(pod.podcast_url);
			rss_names.set(pod.podcast_rss, pod.artist);
		}
		
		index = 0;
		total = 10 * rss_urls.size;
		current_operation = "Looking for new episodes";
		fetching = true;
		user_cancelled = false;
		Timeout.add(500, doProgressNotificationWithTimeout);
		
		LinkedList<Song> new_podcasts = new LinkedList<Song>();
		var rss_index = 0;
		foreach(string rss in rss_urls) {
			if(user_cancelled)
				break;
			
			current_operation = "Searching for new <b>" + rss_names.get(rss).replace("&", "&amp;") + "</b> podcast episodes...";
			
			// create an HTTP session to twitter
			var session = new Soup.SessionSync();
			var message = new Soup.Message ("GET", rss);
			
			// send the HTTP request
			session.send_message(message);
			
			Xml.Node* node = getRootNode(message);
			if(node != null) {
				findNewItems(rss, node, mp3_urls, ref new_podcasts);
			}
			
			++rss_index;
			index = rss_index * 10;
		}
		
		index = total + 1;
		fetching = false;
		
		Idle.add( () => {
			lm.add_songs(new_podcasts, true);
			lw.updateSensitivities();
			lm.lw.updateInfoLabel();
			lm.finish_file_operations();
			
			if(lm.settings.getDownloadNewPodcasts()) {
				var new_podcast_ids = new LinkedList<int>();
				foreach(var s in new_podcasts)
					new_podcast_ids.add(s.rowid);
				
				save_episodes_locally(new_podcast_ids);
			}
			
			return false;
		});
		
		return null;
	}
	
	public bool is_valid_rss(string url) {
		// create an HTTP session to twitter
		var session = new Soup.SessionSync();
		var message = new Soup.Message ("GET", url);
		
		// send the HTTP request
		session.send_message(message);
		
		Xml.Node* node = getRootNode(message);
		stdout.printf("got root node\n");
		if(node == null)
			return false;
		
		return node->name == "rss";
	}
	
	public bool parse_new_rss(string rss) {
		if(!lm.start_file_operations("Fetching podcast from <b>" + rss + "</b>"))
			return false;
		
		fetching = true;
		index = 0;
		total = 10;
		current_operation = "Fetching podcast from <b>" + rss + "</b>";
		Timeout.add(500, doProgressNotificationWithTimeout);
		
		stdout.printf("podcast_rss: %s\n", rss);
		
		// create an HTTP session to twitter
		var session = new Soup.SessionSync();
		var message = new Soup.Message ("GET", rss);
		
		// send the HTTP request
		session.send_message(message);
		
		Xml.Node* node = getRootNode(message);
		stdout.printf("got root node\n");
		if(node == null) {
			fetching = false;
			return false;
		}
			
		HashSet<string> mp3_urls = new HashSet<string>();
		LinkedList<Song> new_podcasts = new LinkedList<Song>();
		foreach(int i in lm.podcast_ids()) {
			var pod = lm.song_from_id(i);
			
			mp3_urls.add(pod.podcast_url);
		}
		
		findNewItems(rss, node, mp3_urls, ref new_podcasts);
		
		index = 11;
		fetching = false;
		
		lm.add_songs(new_podcasts, true);
		lm.finish_file_operations();
		
		return new_podcasts.size > 0;
	}
	
	public Xml.Node* getRootNode(Soup.Message message) {
		Xml.Parser.init();
		Xml.Doc* doc = Xml.Parser.parse_memory((string)message.response_body.data, (int)message.response_body.length);
		if(doc == null)
			return null;
		//stdout.printf("%s\n", (string)message.response_body.data);
        Xml.Node* root = doc->get_root_element ();
        if (root == null) {
            delete doc;
            return null;
        }
		
		// we actually want one level down from root. top level is <response status="ok" ... >
		return root;
	}
	
	// parses a xml root node for new podcasts
	public void findNewItems(string rss, Xml.Node* node, HashSet<string> existing, ref LinkedList<Song> found) {
		string pod_title = ""; string pod_author = ""; string category = ""; string summary = ""; string image_url = "";
		int image_width, image_height;
		int visited_items = 0;
		
		node = node->children->next;
		
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			if (iter->type != Xml.ElementType.ELEMENT_NODE) {
				continue; // should this be break?
			}
			
			string name = iter->name;
			string content = iter->get_content();
			
			if(name == "title")
				pod_title = content.replace("\n","").replace("\t","").replace("\r","");
			else if(name == "author")
				pod_author = content.replace("\n","").replace("\t","").replace("\r","");
			else if(name == "category") {
				if(content != "")
					category = content.replace("\n","").replace("\t","").replace("\r","");
				
				for (Xml.Attr* prop = iter->properties; prop != null; prop = prop->next) {
					string attr_name = prop->name;
					string attr_content = prop->children->content;
					
					if(attr_name == "text" && attr_content != "") {
						category = attr_content;
					}
				}
			}
			else if(name == "image") {
				for (Xml.Node* image_iter = iter->children; image_iter != null; image_iter = image_iter->next) {
					if(image_iter->name == "url")
						image_url = image_iter->get_content();
					else if(image_iter->name == "width")
						image_width = int.parse(image_iter->get_content());
					else if(image_iter->name == "height")
						image_height = int.parse(image_iter->get_content());
				}
			}
			else if(name == "summary" || name == "description") {
				summary = iter->get_content().replace("\n","").replace("\t","").replace("\r","");
			}
			else if(name == "item") {
				Song new_p = new Song("");
			
				for (Xml.Node* item_iter = iter->children; item_iter != null; item_iter = item_iter->next) {
					//stdout.printf("name is %s\n", item_iter->name);
					if(item_iter->name == "title")
						new_p.title = item_iter->get_content();
					else if(name == "author") {
						pod_author = item_iter->get_content().replace("\n","").replace("\t","").replace("\r","");
						new_p.artist = pod_author;
						new_p.album_artist = pod_author;
					}
					else if(item_iter->name == "enclosure") {
						for (Xml.Attr* prop = item_iter->properties; prop != null; prop = prop->next) {
							string attr_name = prop->name;
							string attr_content = prop->children->content;
							
							if(attr_name == "url") {
								new_p.podcast_url = attr_content;
								new_p.file = attr_content;
							}
						}
					}
					else if(item_iter->name == "pubDate") {
						GLib.Time tm = GLib.Time ();
						tm.strptime (item_iter->get_content(),
									"%a, %d %b %Y %H:%M:%S %Z");
						new_p.podcast_date = int.parse(tm.format("%s"));
					}
					else if(item_iter->name == "duration") {
						string[] dur_pieces = item_iter->get_content().split(":", 0);
						
						int seconds = 0; int minutes = 0; int hours = 0;
						seconds = int.parse(dur_pieces[dur_pieces.length - 1]);
						if(dur_pieces.length > 1)
							minutes = int.parse(dur_pieces[dur_pieces.length - 2]);
						if(dur_pieces.length > 2)
							hours = int.parse(dur_pieces[dur_pieces.length - 3]);
							
						new_p.length = seconds + (minutes * 60) + (hours * 3600);
					}
					else if(item_iter->name == "subtitle" || item_iter->name == "description") {
						new_p.comment = item_iter->get_content().replace("\n","").replace("\t","").replace("\r","");
					}
				}
				
				if(new_p.podcast_url != null && !existing.contains(new_p.podcast_url) && new_p.podcast_url != "") {
					if(pod_author == null || pod_author == "")
						pod_author = pod_title;
					if(category == null || category == "")
						category = "Podcast";
					
					new_p.mediatype = 1;
					new_p.podcast_rss = rss;
					new_p.genre = category;
					new_p.artist = pod_author;
					new_p.album_artist = pod_author;
					new_p.album = pod_title;
					//new_p.album = ??
					if(new_p.comment == "")			new_p.comment = summary;
					if(new_p.podcast_date == 0)		new_p.podcast_date = (int)time_t();
					
					found.add(new_p);
				}
				
				++visited_items;
				++index;
				
				//if(visited_items >= max_items - 1)
				//	return;
			}
		}
	}
	
	public void save_episodes_locally(Collection<int> ids) {
		if(fetching) {
			stdout.printf("Not going to save episodes locally. Must wait to finish fetching.\n");
			return;
		}
		else if(lm.doing_file_operations()) {
			stdout.printf("Can't save episodes locally. Already doing file operations.\n");
			return;
		}
		else if(!File.new_for_path(lm.settings.getMusicFolder()).query_exists()) {
			lw.doAlert("Could not save locally", "The music folder could not be found. It may need to be mounted");
			return;
		}
		
		save_locally_ids = ids;
		
		try {
			Thread.create<void*>(save_episodes_locally_thread, false);
		}
		catch(GLib.ThreadError err) {
			stdout.printf("ERROR: Could not create thread to save episodes locally: %s \n", err.message);
		}
	}
	
	public void* save_episodes_locally_thread () {
		if(save_locally_ids == null || save_locally_ids.size == 0)
			return null;
		
		lm.start_file_operations(null);
		saving_locally = true;
		user_cancelled = false;
		index = 0;
		total = save_locally_ids.size;
		Timeout.add(500, doProgressNotificationWithTimeoutSaveLocally);
		
		foreach(var i in save_locally_ids) {
			if(user_cancelled)
				break;
			
			// first, transfer it to local thread
			// then, set i.file to the new location
			current_operation = "Downloading <b>" + lm.song_from_id(i).title + "</b> (" + (index + 1).to_string() + " of " + save_locally_ids.size.to_string() + ")";
			online_size = File.new_for_uri(lm.song_from_id(i).podcast_url).query_info("*", FileQueryInfoFlags.NONE).get_size();
			new_dest = lm.fo.get_new_destination(lm.song_from_id(i));
			lm.fo.update_file_hierarchy(lm.song_from_id(i), false, true);
			lm.song_from_id(i).file_size = (int)(new_dest.query_info("*", FileQueryInfoFlags.NONE).get_size() / 1000000);
			++index;
		}
		
		index = total + 1;
		
		Idle.add( () => {
			lm.lw.updateInfoLabel();
			//lm.lw.searchField.changed();
			lm.finish_file_operations();
			saving_locally = false;
			
			return false;
		});
		
		return null;
	}
	
	public bool doProgressNotificationWithTimeout() {
		if(fetching)
			lw.progressNotification(current_operation.replace("&", "&amp;"), (double)((double)index/(double)total));
		
		if(index < total && fetching) {
			return true;
		}
		
		return false;
	}
	
	public bool doProgressNotificationWithTimeoutSaveLocally() {
		int64 current_local_size = 0;
		if(new_dest.query_exists())
			current_local_size = new_dest.query_info("*", FileQueryInfoFlags.NONE).get_size();
		
		lw.progressNotification(current_operation.replace("&", "&amp;"), (double)(((double)index + (double)((double)current_local_size/(double)online_size))/((double)total)));
		
		if(index < total && lm.doing_file_operations()) {
			return true;
		}
		
		return false;
	}
}
