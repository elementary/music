using Gee;

public class BeatBox.PodcastManager : GLib.Object {
	LibraryManager lm;
	LibraryWindow lw;
	
	public PodcastManager(LibraryManager lm, LibraryWindow lw) {
		this.lm = lm;
		this.lw = lw;
	}
	
	public void find_new_podcasts() {
		HashSet<string> rss_urls = new HashSet<string>();
		HashSet<string> mp3_urls = new HashSet<string>();
		
		foreach(int i in lm.podcast_ids()) {
			var pod = lm.song_from_id(i);
			
			rss_urls.add(pod.podcast_rss);
			mp3_urls.add(pod.podcast_url);
		}
		
		LinkedList<int> new_podcasts = new LinkedList<int>();
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
			
			// get root node rss properties
			/*for (Xml.Attr* prop = node->properties; prop != null; prop = prop->next) {
				string attr_name = prop->name;

				// Notice the ->children which points to a Node*
				// (Attr doesn't feature content)
				string attr_content = prop->children->content;
				print_indent (attr_name, attr_content, '|');
			}*/
			
			findNewItems(node, mp3_urls, ref new_podcasts);
		}
		
		// make sure s.mediatype = 1
		lm.add_songs(new_podcasts, true);
		
		Idle.add( () => {
			// somehow send signal that they were added. also try doing progressNotifications to refresh the list on the fly
			
			return false;
		})
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
        
        // make sure we got an 'ok' response
		for (Xml.Attr* prop = root->properties; prop != null && prop->name != "status" ; prop = prop->next) {
			if(prop->children->content != "ok")
				return null;
		}
		
		// we actually want one level down from root. top level is <response status="ok" ... >
		return root->children;
	}
	
	public void parse_new_rss(string rss) {
		stdout.printf("podcast_rss: %s\n", rss);
			
		// create an HTTP session to twitter
		var session = new Soup.SessionSync();
		var message = new Soup.Message ("GET", rss);
		
		// send the HTTP request
		session.send_message(message);
		
		Xml.Node* node = getRootNode(message);
		if(node == null)
			return null;
		
		// get root node rss properties
		string category, artist, 
		for (Xml.Attr* prop = node->properties; prop != null; prop = prop->next) {
			string attr_name = prop->name;
			string attr_content = prop->children->content;
			
			// maybe use this if it is useful later.
		}
		
		findNewItems(node, mp3_urls, ref new_podcasts);
	}
	
	// parses a xml root node for new podcasts
	public void findNewItems(Xml.Node* node, HashSet<string> existing, ref LinkedList<int> found, int max_items) {
		string pod_title, category, summary, image_url, 
		int id = int.parse(node->properties->children->content);
		if(id <= 0)
			return null;
		
		// go down to channel level
		node = node->children;
		
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			if (iter->type != ElementType.ELEMENT_NODE) {
				continue;
			}
			
			string name = iter->name;
			string content = iter->get_content();
			
			if(name == "title" || name == "itunes:author")
				pod_title = content;
			else if(name == "category")
				category = content;
			else if(name == "image") {
				rv.type = content;
				for (Xml.Node* image_iter = iter->children; image_iter != null; image_iter = image_iter->next) {
					if(image_iter->name == "url")
						image_url = image_iter->get_content();
					else if(image_iter->name == "width")
						image_width = image_iter->get_content();
					else if(image_iter->name == "height")
						image_height = image_iter->get_content();
				}
			}
			else if(name == "itunes:summary") {
				summary = iter->get_content();
			}
			else if(name == "item") {
				for (Xml.Node* item_iter = iter->children; item_iter != null; item_iter = item_iter->next) {
					string p_path = "";
					
					Song new_p = new Song(p_path);
					if(item_iter->name == "title")
						new_p.title = item_iter->get_content();
					else if(item_iter->name == "enclosure") {
						for (Xml.Attr* prop = item_iter->properties; prop != null; prop = prop->next) {
							string attr_name = prop->name;
							string attr_content = prop->children->content;
							
							if(attr_name == "url") {
								new_p.podcast_url = attr_content;
							}
							else if(attr_name == "length") {
								new_p.length = 
							}
						}
					}
					else if(item_iter->name == "pubDate") {
						GLib.Time tm = GLib.Time ();
						tm.strptime (item_iter->get_content(),
									"%a, %d %b %Y %H:%M:%S %Z");
						//s.podcast_date = tm.get_
					}
				}
			}
			
		}
	}
}
