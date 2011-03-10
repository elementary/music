/** Queries last.fm for information and similar tracks. yay. third try.
 * @author Scott Ringwelski
*/
using Xml;

public class LastFM.Core : Object {
	BeatBox.LibraryManager _lm;
	
	/** NOTICE: These API keys and secrets are unique to BeatBox and Beatbox
	 * only. To get your own, FREE key go to http://www.last.fm/api/account */
	public static const string api = "a40ea1720028bd40c66b17d7146b3f3b";
	public static const string secret = "92ba5023f6868e680a3352c71e21243d";
	
	public string token;
	public string session_key;
	
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
	
	public bool loveTrack(string title, string artist) {
		
		return false;
	}
	
	public bool banTrack(string title, string artist) {
		
		return false;
	}
	
	public void* lastfm_thread_function () {
		/*bool update_track = false, update_artist = false, update_album = false;
		LastFM.ArtistInfo artist = new LastFM.ArtistInfo.basic();
		LastFM.TrackInfo track = new LastFM.TrackInfo.basic();
		LastFM.AlbumInfo album = new LastFM.AlbumInfo.basic();
		
		if(lm.song_info.album.name != lm.song_info.song.album || lm.song_info.album.artist != lm.song_info.song.artist) {
			update_album = true;
			
			if(!lm.album_info_exists(lm.song_info.song.album + " by " + lm.song_info.song.artist)) {
				//stdout.printf("Downloading new Album Info from Last FM\n");
				album = new LastFM.AlbumInfo.with_info(lm.song_info.song.artist, lm.song_info.song.album);
				
				//try to save album image locally
				if(lm.get_album_location(lm.song_info.song.rowid) == null && album != null)
					lm.save_album_locally(lm.song_info.song.rowid, album.url_image.url);
				
				if(album != null)
					lm.save_album(album);
			}
			else {
				album = lm.get_album(lm.song_info.song.album + " by " + lm.song_info.song.artist);
				
				//if no local image saved, save it now
				if(lm.get_album_location(lm.song_info.song.rowid) == null && album != null)
					lm.save_album_locally(lm.song_info.song.rowid, album.url_image.url);
			}
		}
		if(lm.song_info.artist.name != lm.song_info.song.artist) {
			update_artist = true;
			
			if(!lm.artist_info_exists(lm.song_info.song.artist)) {
				//stdout.printf("Downloading new Artist Info from Last FM\n");
				artist = new LastFM.ArtistInfo.with_artist(lm.song_info.song.artist);
				
				//try to save artist art locally
				if(lm.get_album_location(lm.song_info.song.rowid) == null && artist != null)
					lm.save_artist_image_locally(lm.song_info.song.rowid, artist.url_image.url);
				
				if(artist != null)
					lm.save_artist(artist);
			}
			else {
				artist = lm.get_artist(lm.song_info.song.artist);
				
				//if no local image saved, save it now
				if(lm.get_artist_image_location(lm.song_info.song.rowid) == null)
					lm.save_artist_image_locally(lm.song_info.song.rowid, artist.url_image.url);
			}
		}
		if(lm.song_info.track.name != lm.song_info.song.title || lm.song_info.track.artist != lm.song_info.song.artist) {
			update_track = true;
			
			if(!lm.track_info_exists(lm.song_info.song.title + " by " + lm.song_info.song.artist)) {
				//stdout.printf("Downloading new Track Info from Last FM\n");
				track = new LastFM.TrackInfo.with_info(lm.song_info.song.artist, lm.song_info.song.title);
				
				if(track != null)
					lm.save_track(track);
			}
			else
				track = lm.get_track(lm.song_info.song.title + " by " + lm.song_info.song.artist);
		}
		
		//test if song info is still what we want or if user has moved on
		bool update_song_display = false;
		
		if(lm.song_info.album.name != album.name && update_album) {
			update_song_display = true;
			lm.song_info.album = album;
		}
		if(lm.song_info.artist.name != artist.name && update_artist) {
			update_song_display = true;
			lm.song_info.artist = artist;
		}
		if(lm.song_info.track.name != track.name && update_track) {
			update_song_display = true;
			lm.song_info.track = track;
		}
		
		if(update_song_display) {
			Idle.add(updateSongInfo);
			Idle.add(updateCurrentSong);
		}*/
		
		return null;
    }
}
