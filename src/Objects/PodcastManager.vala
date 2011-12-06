using Gee;

public class BeatBox.PodcastManager : GLib.Object {
	LibraryManager lm;
	LibraryWindow lw;
	bool fetching;
	
	public PodcastManager(LibraryManager lm, LibraryWindow lw) {
		this.lm = lm;
		this.lw = lw;
		fetching = false;
	}
	
	
	
	public void find_new_podcasts() {
		if(fetching) {
			stdout.printf("Not going to find new podcasts, already fetching\n");
			return;
		}
		
		try {
			Thread.create<void*>(find_new_podcasts_thread, false);
		}
		catch(GLib.ThreadError err) {
			stdout.printf("ERROR: Could not create thread to fetch new podcasts: %s \n", err.message);
		}
	}
		
	public void* find_new_podcasts_thread () {
		HashSet<string> rss_urls = new HashSet<string>();
		HashSet<string> mp3_urls = new HashSet<string>();
		
		foreach(int i in lm.podcast_ids()) {
			var pod = lm.song_from_id(i);
			
			rss_urls.add(pod.podcast_rss);
			mp3_urls.add(pod.podcast_url);
		}
		
		LinkedList<Song> new_podcasts = new LinkedList<Song>();
		foreach(string rss in rss_urls) {
			stdout.printf("podcast_rss: %s\n", rss);
			
			// create an HTTP session to twitter
			var session = new Soup.SessionSync();
			var message = new Soup.Message ("GET", rss);
			
			// send the HTTP request
			session.send_message(message);
			
			Xml.Node* node = getRootNode(message);
			if(node == null)
				return null;
			
			findNewItems(rss, node, mp3_urls, ref new_podcasts, 10);
		}
		
		// make sure s.mediatype = 1
		lm.add_songs(new_podcasts, true);
		
		Idle.add( () => {
			
			
			return false;
		});
		
		return null;
	}
	
	public bool parse_new_rss(string rss) {
		stdout.printf("podcast_rss: %s\n", rss);
			
		// create an HTTP session to twitter
		var session = new Soup.SessionSync();
		var message = new Soup.Message ("GET", rss);
		
		// send the HTTP request
		session.send_message(message);
		
		Xml.Node* node = getRootNode(message);
		stdout.printf("got root node\n");
		if(node == null)
			return false;
			
		HashSet<string> mp3_urls = new HashSet<string>();
		LinkedList<Song> new_podcasts = new LinkedList<Song>();
		foreach(int i in lm.podcast_ids()) {
			var pod = lm.song_from_id(i);
			
			mp3_urls.add(pod.podcast_url);
		}
		
		findNewItems(rss, node, mp3_urls, ref new_podcasts, 10);
		
		lm.add_songs(new_podcasts, true);
		
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
	public void findNewItems(string rss, Xml.Node* node, HashSet<string> existing, ref LinkedList<Song> found, int max_items) {
		string pod_title = ""; string category = ""; string summary = ""; string image_url = "";
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
					new_p.mediatype = 1;
					new_p.podcast_rss = rss;
					new_p.genre = category;
					new_p.artist = pod_title;
					new_p.album_artist = pod_title;
					//new_p.album = ??
					if(new_p.comment == "")			new_p.comment = summary;
					if(new_p.podcast_date == 0)		new_p.podcast_date = (int)time_t();
					
					found.add(new_p);
					++visited_items;
					
					if(visited_items >= max_items - 1)
						return;
				}
				else {
					++visited_items;
					
					if(visited_items >= max_items - 1)
						return;
				}
			}
		}
	}
}
