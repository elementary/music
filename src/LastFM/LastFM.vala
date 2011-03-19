/** Queries last.fm for information and similar tracks. yay. third try.
 * @author Scott Ringwelski
*/
using Xml;

public class LastFM.Core : Object {
	BeatBox.LibraryManager lm;
	
	/** NOTICE: These API keys and secrets are unique to BeatBox and Beatbox
	 * only. To get your own, FREE key go to http://www.last.fm/api/account */
	public static const string api = "a40ea1720028bd40c66b17d7146b3f3b";
	public static const string secret = "92ba5023f6868e680a3352c71e21243d";
	
	public string token;
	public string session_key;
	
	public Core(BeatBox.LibraryManager lmm) {
		lm = lmm;
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
	
	public bool loveTrack(string title, string artist) {
		
		return false;
	}
	
	public bool banTrack(string title, string artist) {
		
		return false;
	}
}
