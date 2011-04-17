/** Queries last.fm for information and similar tracks. yay. third try.
 * @author Scott Ringwelski
*/
using Xml;
using Soup;

public class LastFM.Core : Object {
	BeatBox.LibraryManager lm;
	
	/** NOTICE: These API keys and secrets are unique to BeatBox and Beatbox
	 * only. To get your own, FREE key go to http://www.last.fm/api/account */
	public static const string api = "a40ea1720028bd40c66b17d7146b3f3b";
	public static const string secret = "92ba5023f6868e680a3352c71e21243d";
	
	public string token;
	public string session_key;
	
	public signal void logged_in();
	
	public Core(BeatBox.LibraryManager lmm) {
		lm = lmm;
		session_key = lm.settings.getLastFMSessionKey();
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
	
	public string generate_trackban_signature(string artist, string track) {
		return generate_md5("api_key" + api + "artist" + artist + "methodtrack.bansk" + session_key + "track" + track + secret);
	}
	
	public string generate_trackscrobble_signature(string artist, string track, int timestamp) {
		return generate_md5("api_key" + api + "artist" + artist + "methodtrack.scrobblesk" + session_key + "timestamp" + timestamp.to_string() + "track" + track + secret);
	}
	
	public string generate_trackupdatenowplaying_signature(string artist, string track) {
		return generate_md5("api_key" + api + "artist" + artist + "methodtrack.updateNowPlayingsk" + session_key + "track" + track + secret);
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
		if(session_key == null || session_key == "") {
			stdout.printf("User tried to ban a track, but is not logged into Last FM\n");
			return false;
		}
		
		var uri = "http://ws.audioscrobbler.com/2.0/?api_key=" + api + "&api_sig=" + generate_tracklove_signature(artist, title) + "&artist=" + fix_for_url(artist) + "&method=track.love&sk=" + session_key + "&track=" + fix_for_url(title);
		
		Soup.SessionSync session = new Soup.SessionSync();
		Soup.Message message = new Soup.Message ("POST", uri);
		
		var headers = new Soup.MessageHeaders(MessageHeadersType.REQUEST);
		headers.append("api_key", api);
		headers.append("api_sig", generate_tracklove_signature(artist, title));
		headers.append("artist", artist);
		headers.append("method", "track.love");
		headers.append("sk", session_key);
		headers.append("track", title);
		
		message.request_headers = headers;
		
		/* send the HTTP request */
		session.send_message(message);
		
		if(message.response_body.length == 0)
			return false;
		
		return true;
	}
	
	public bool banTrack(string title, string artist) {
		if(session_key == null || session_key == "") {
			stdout.printf("User tried to ban a track, but is not logged into Last FM\n");
			return false;
		}
		
		var uri = "http://ws.audioscrobbler.com/2.0/?api_key=" + api + "&api_sig=" + generate_trackban_signature(artist, title) + "&artist=" + fix_for_url(artist) + "&method=track.ban&sk=" + session_key + "&track=" + fix_for_url(title);
		
		Soup.SessionSync session = new Soup.SessionSync();
		Soup.Message message = new Soup.Message ("POST", uri);
		
		var headers = new Soup.MessageHeaders(MessageHeadersType.REQUEST);
		headers.append("api_key", api);
		headers.append("api_sig", generate_trackban_signature(artist, title));
		headers.append("artist", artist);
		headers.append("method", "track.ban");
		headers.append("sk", session_key);
		headers.append("track", title);
		
		message.request_headers = headers;
		
		/* send the HTTP request */
		session.send_message(message);
		
		if(message.response_body.length == 0)
			return false;
		
		return true;
	}
	
	public bool scrobbleTrack(string title, string artist) {
		if(session_key == null || session_key == "")
			return false;
		
		var timestamp = (int)time_t();
		var uri = "http://ws.audioscrobbler.com/2.0/?api_key=" + api + "&api_sig=" + generate_trackscrobble_signature(artist, title, timestamp) + "&artist=" + fix_for_url(artist) + "&method=track.scrobble&sk=" + session_key + "&timestamp=" + timestamp.to_string() + "&track=" + fix_for_url(title);
		
		Soup.SessionSync session = new Soup.SessionSync();
		Soup.Message message = new Soup.Message ("POST", uri);
		
		var headers = new Soup.MessageHeaders(MessageHeadersType.REQUEST);
		headers.append("api_key", api);
		headers.append("api_sig", generate_trackscrobble_signature(artist, title, timestamp));
		headers.append("artist", artist);
		headers.append("method", "track.scrobble");
		headers.append("sk", session_key);
		headers.append("timestamp", timestamp.to_string());
		headers.append("track", title);
		
		message.request_headers = headers;
		
		/* send the HTTP request */
		session.send_message(message);
		
		if(message.response_body.length == 0)
			return false;
		
		return true;
	}
	
	public bool updateNowPlaying(string title, string artist) {
		if(session_key == null || session_key == "")
			return false;
		
		var uri = "http://ws.audioscrobbler.com/2.0/?api_key=" + api + "&api_sig=" + generate_trackupdatenowplaying_signature(artist, title) + "&artist=" + fix_for_url(artist) + "&method=track.updateNowPlaying&sk=" + session_key + "&track=" + fix_for_url(title);
		
		Soup.SessionSync session = new Soup.SessionSync();
		Soup.Message message = new Soup.Message ("POST", uri);
		
		var headers = new Soup.MessageHeaders(MessageHeadersType.REQUEST);
		headers.append("api_key", api);
		headers.append("api_sig", generate_trackupdatenowplaying_signature(artist, title));
		headers.append("artist", artist);
		headers.append("method", "track.updateNowPlaying");
		headers.append("sk", session_key);
		headers.append("track", title);
		
		message.request_headers = headers;
		
		/* send the HTTP request */
		session.send_message(message);
		
		if(message.response_body.length == 0)
			return false;
		
		return true;
	}
}
