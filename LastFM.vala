/** Queries last.fm for information and similar tracks. yay. third try.
 * @author Scott Ringwelski
*/
using Xml;

public class LastFM.Core : Object {
	BeatBox.LibraryManager _lm;
	static const string api = "a40ea1720028bd40c66b17d7146b3f3b";
	static const string secret = "92ba5023f6868e680a3352c71e21243d";
	public string token;
	public string session_key;
	
	Gee.ArrayList<BeatBox.Song> similar;
	BeatBox.Song similarToAdd;
	
	public Core(BeatBox.LibraryManager lm) {
		_lm = lm;
	}
	
	/** vala sucks here **/
	public static string fix_for_url(string fix) {
		var fix1 = fix.replace(" ", "%20");
		var fix2 = fix1.replace("!", "%21");
		var fix3 = fix2.replace("\"","%22");
		var fix4 = fix3.replace("#", "%23");
		var fix5 = fix4.replace("$", "%24");
		var fix6 = fix5.replace("&", "%26");
		var fix7 = fix6.replace("'", "%27");
		var fix8 = fix7.replace("(", "%28");
		var fix9 = fix8.replace(")", "%29");
		var fix0 = fix9.replace("*", "%2A");
		return fix0;
	}
	
	public string generate_md5(string text) {
		return GLib.Checksum.compute_for_string(ChecksumType.MD5, text, text.length);
	}
	
	public string generate_signature(string token, string method) {
		return generate_md5("api_key" + api + "method" + method + "token" + token + secret);
	}
	
	public string? getToken() {
		var url = "http://ws.audioscrobbler.com/2.0/?method=auth.gettoken&api_key=" + api;
		
		Xml.Doc* doc = Parser.parse_file (url);
		if(doc == null) return null;
		
		Xml.Node* root = doc->get_root_element();
		if(root == null) return null;
		
		for (Xml.Node* iter = root->children; iter != null; iter = iter->next) {
            if(iter->name == "token") {
				return iter->get_content();
			}
		}
		
		return null;
	}
	
	public string? getSessionKey(string token) {
		var url = "http://ws.audioscrobbler.com/2.0/?method=auth.getSession&api_key=" + api + "&api_sig=" + generate_signature(token, "auth.getSession") + "&token=" + token;
		
		Xml.Doc* doc = Parser.parse_file (url);
		if(doc == null) return null;
		
		Xml.Node* root = doc->get_root_element();
		if(root == null) return null;
		
		for (Xml.Node* iter = root->children; iter != null; iter = iter->next) {
            if(iter->name == "session") {
				for(Xml.Node* n = iter->children; n != null; n = n->next) {
					if(n->name == "key")
						return n->get_content();
				}
			}
		}
		
		return null;
	}
	
	/** Gets similar songs
	 * @param artist The artist of song to get similar to
	 * @param title The title of song to get similar to
	 * @return The songs that are similar
	 */
	public Gee.ArrayList<BeatBox.Song> getSimilarTracks(string title, string artist) {
		var artist_fixed = fix_for_url(artist);
		var title_fixed = fix_for_url(title);
		var url = "http://ws.audioscrobbler.com/2.0/?method=track.getsimilar&artist=" + artist_fixed + "&track=" + title_fixed + "&api_key=" + api;
		Xml.Doc* doc = Parser.parse_file (url);
		
		if(doc == null)
			stdout.printf("Could not load similar artist information for %s by %s", title, artist);
		else if(doc->get_root_element() == null)
			stdout.printf("Oddly, similar artist information was invalid");
		else {
			//stdout.printf("Getting similar tracks with %s... \n", url);
			similar = new Gee.ArrayList<BeatBox.Song>();
			similarToAdd = null;
			parse_similar_nodes(doc->get_root_element(), "");
			
			return similar;
		}
		
		return new Gee.ArrayList<BeatBox.Song>();
	}
	
	public void parse_similar_nodes(Xml.Node* node, string parent) {
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			
            if (iter->type != ElementType.ELEMENT_NODE) {
                continue;
            }

            string node_name = iter->name;
            string node_content = iter->get_content ();
            
            if(parent == "similartrackstrack") {
				if(node_name == "name") {
					if(similarToAdd != null) {
						similar.add(similarToAdd);
					}
					
					similarToAdd = new BeatBox.Song("");
					similarToAdd.title = node_content;
				}
			}
			else if(parent == "similartrackstrackartist") {
				if(node_name == "name") {
					similarToAdd.artist = node_content;
				}
			}
			
			parse_similar_nodes(iter, parent+node_name);
		}
		
	}
	
}
