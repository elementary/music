using Xml;

public class LastFM.ArtistInfo : Object {
	static const string api = "a40ea1720028bd40c66b17d7146b3f3b";
	
	private string _name;
	private string _mbid; //music brainz id
	private string _url;// last fm url
	private int _streamable; // 1 = true
	
	private int _listeners;
	private int _playcount;
	
	private string _published;
	private string _summary;
	private string _content;
	
	private LastFM.Image _url_image;
	
	private Gee.ArrayList<LastFM.Tag> _tags;
	private Gee.ArrayList<LastFM.ArtistInfo> _similarArtists;
	
	// used by parser
	ArtistInfo similarToAdd;
	Tag tagToAdd;
	
	public ArtistInfo.basic() {
		_name = "Unkown Artist";
		_tags = new Gee.ArrayList<LastFM.Tag>();
		_similarArtists = new Gee.ArrayList<LastFM.ArtistInfo>();
		url_image = new LastFM.Image.basic();
	}
	
	public ArtistInfo.with_artist(string artist) {
		var artist_fixed = LastFM.Core.fix_for_url(artist);
		
		var url = "http://ws.audioscrobbler.com/2.0/?method=artist.getinfo&api_key=" + api + "&artist=" + artist_fixed;
		stdout.printf("Parsing artist info.\n");
		Xml.Doc* doc = Parser.parse_file (url);
		ArtistInfo.with_doc(doc);
	}
	
	public ArtistInfo.with_artist_and_url(string name, string url) {
		ArtistInfo.basic();
		_name = name;
		_url = url;
	}
	
	public ArtistInfo.with_doc(Xml.Doc* doc) {
		ArtistInfo.basic();
		similarToAdd = null;
		tagToAdd = null;
		
        if (doc == null) {
            stderr.printf ("Could not get artist info. \n");
            return;
        }

        // Get the root node. notice the dereferencing operator -> instead of .
        Xml.Node* root = doc->get_root_element ();
        if (root == null) {
            // Free the document manually before returning
            delete doc;
            stderr.printf ("The xml file is empty. \n");
            return;
        }
        
        // Let's parse those nodes
        parse_node (root, "");

        // Free the document
        delete doc;
	}
	
	/** recursively parses the nodes in a xml doc and also calls parse_properties
	 * @param node The node to parse
	 * @param parent the parent node
	 */
	private void parse_node (Xml.Node* node, string parent) {
        // Loop over the passed node's children
        for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
            // Spaces between tags are also nodes, discard them
            if (iter->type != ElementType.ELEMENT_NODE) {
                continue;
            }
			
            string node_name = iter->name;
            string node_content = iter->get_content ();
            
            if(parent == "artist") {
				if(node_name == "name")
					_name = node_content;
				else if(node_name == "mbid")
					_mbid = node_content;
				else if(node_name == "url")
					_url = node_content;
				else if(node_name == "streamable")
					_streamable = int.parse(node_content);
				else if(node_name == "image") {
					if(iter->get_prop("size") == "extralarge") {
						url_image = new LastFM.Image.with_url(node_content, true);
						url_image.set_size(200, 300);
					}
				}
			}
			else if(parent == "artiststats") {
				if(node_name == "playcount")
					_playcount = int.parse(node_content);
				else if(node_name == "listeners")
					_listeners = int.parse(node_content);
			}
			else if(parent == "artistsimilarartist") {
				if(node_name == "name") {
					if(similarToAdd != null)
						_similarArtists.add(similarToAdd);
					
					similarToAdd = new ArtistInfo();
					similarToAdd.name = node_content;
				}
				else if(node_name == "url")
					similarToAdd.url = node_content;
				else if(node_name == "image") {
					//TODO
				}
			}
			else if(parent == "artisttagstag") {
				if(node_name == "name") {
					if(tagToAdd != null)
						_tags.add(tagToAdd);
					
					tagToAdd = new LastFM.Tag();
					tagToAdd.tag = node_content;
				}
				else if(node_name == "url")
					tagToAdd.url = node_content;
			}
			else if(parent == "artistbio") {
				if(node_name == "published")
					_published = node_content;
				else if(node_name == "summary")
					_summary = node_content;
				else if(node_name == "content")
					_content = node_content;
			}
            
            // Now parse the node's properties (attributes) ...
            //parse_properties (iter);

            // Followed by its children nodes
            parse_node (iter, parent + node_name);
        }
    }
	
	public string name {
		get { return _name; }
		set { _name = value; }
	}
	
	public string mbid {
		get { return _mbid; }
		set { _mbid = value; }
	}
	
	public string url {
		get { return _url; }
		set { _url = value; }
	}
	
	public int streamable {
		get { return _streamable; }
		set { _streamable = value; }
	}
	
	public int listeners {
		get { return _listeners; }
		set { _listeners = value; }
	}
	
	public int playcount {
		get { return _playcount; }
		set { _playcount = value; }
	}
	
	public string published {
		get { return _published; }
		set { _published = value; }
	}
	
	public string summary {
		get { return _summary; }
		set { _summary = value; }
	}
	
	public string content {
		get { return _content; }
		set { _content = value; }
	}
	
	public LastFM.Image url_image {
		get { return _url_image; }
		set { _url_image = value; }
	}
	
	public void addSimilarArtist(LastFM.ArtistInfo artist) {
		_similarArtists.add(artist);
	}
	
	public Gee.ArrayList<LastFM.ArtistInfo> similarArtists() {
		return _similarArtists;
	}
	
	public void addTag(Tag t) {
		_tags.add(t);
	}
	
	public void addTagString(string t) {
		_tags.add(new LastFM.Tag.with_string(t));
	}
	
	public Gee.ArrayList<LastFM.Tag> tags() {
		return _tags;
	}
	
	public Gee.ArrayList<string> tagStrings() {
		var tags = new Gee.ArrayList<string>();
		
		foreach(LastFM.Tag t in _tags) {
			tags.add(t.tag);
		}
		
		return tags;
	}
	
}
