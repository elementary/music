/** Queries last.fm for information and similar tracks. yay. third try.
 * @author Scott Ringwelski
*/
using Xml;
using Rest;

public class LastFM.Core : Object {
	BeatBox.LibraryManager lm;
	Rest.Proxy proxy;
	
	/** NOTICE: These API keys and secrets are unique to BeatBox and Beatbox
	 * only. To get your own, FREE key go to http://www.last.fm/api/account */
	public static const string api = "a40ea1720028bd40c66b17d7146b3f3b";
	public static const string secret = "92ba5023f6868e680a3352c71e21243d";
	
	public string token;
	public string session_key;
	
	public Core(BeatBox.LibraryManager lmm) {
		lm = lmm;
		token = lm.settings.getLastFMToken();
		session_key = lm.settings.getLastFMSessionKey();
		
		proxy = new Rest.Proxy("POST http://ws.audioscrobbler.com/2.0/", false);
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
	
	public string generate_getsession_signature(string token) {
		return generate_md5("api_key" + api + "methodauth.getSessiontoken" + token + secret);
	}
	
	public string generate_tracklove_signature(string artist, string track) {
		return generate_md5("api_key" + api + "artist" + artist + "methodtrack.lovesk" + session_key + "track" + track + secret);
	}
	
	public string? getToken() {
		var url = "http://ws.audioscrobbler.com/2.0/?method=auth.gettoken&api_key=" + api;
		
		Xml.Doc* doc = Parser.parse_file (url);
		if(doc == null) return null;
		
		Xml.Node* root = doc->get_root_element();
		if(root == null) return null;
		
		for (Xml.Node* iter = root->children; iter != null; iter = iter->next) {
            if(iter->name == "token") {
				string token = iter->get_content();
				lm.settings.setLastFMToken(token);
				return token;
			}
		}
		
		return null;
	}
	
	public string? getSessionKey(string token) {
		var sig = generate_getsession_signature(token);
		var url = "http://ws.audioscrobbler.com/2.0/?method=auth.getSession&api_key=" + api + "&api_sig=" + sig + "&token=" + token;
		
		stdout.printf("url: %s\n", url);
		
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
		Rest.ProxyCall call = proxy.new_call();
		
		call.add_params("method", "track.love",
						"api_key", api,
						"api_sig", generate_tracklove_signature(artist, title),
						"artist", artist,
						"sk", session_key,
						"track", title);
		
		try { 
			call.run_async(on_call_finish, this); 
		}
		catch (GLib.Error err) { 
			stdout.printf("Could not love track: %s\n", err.message);
		}
		
		/*var uri = "POST http://ws.audioscrobbler.com/2.0/?method=track.love&api_key=" + api + "&api_sig=" + generate_tracklove_signature(artist, title) + "&artist=" + fix_for_url(artist) + "&sk=" + session_key + "&track=" + fix_for_url(title);
		
		stdout.printf("sending %s\n", uri);
		
		Soup.SessionAsync session = new Soup.SessionAsync();
		Soup.Message message = new Soup.Message ("POST", uri);
		
		/* send the HTTP request */
		//session.send_message(message);
		
		//stdout.printf(message.response_body.data);
		
		return false;
	}
	
	private void on_call_finish(Rest.ProxyCall call) {
		stdout.printf("Call finished\n");
	}
	
	public bool banTrack(string title, string artist) {
		/*var uri = "http://ws.audioscrobbler.com/2.0/?method=track.ban&api_key=" + api + "&api_sig=" + generate_signature(token, "track.ban") + "&sk=" + lm.settings.getLastFMSessionKey() + "&track=" + fix_for_url(title) + "&artist=" + fix_for_url(artist);
		
		Soup.SessionAsync session = new Soup.SessionAsync();
		Soup.Message message = new Soup.Message ("POST", uri);
		
		/* send the HTTP request */
		//session.send_message(message);
		
		return false;
	}
}
