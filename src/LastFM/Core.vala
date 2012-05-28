/*-
 * Copyright (c) 2011-2012       Scott Ringwelski <sgringwe@mtu.edu>
 *
 * Originally Written by Scott Ringwelski for BeatBox Music Player
 * BeatBox Music Player: http://www.launchpad.net/beat-box
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

/* Merely a place holder for multiple pieces of information regarding
 * the current media playing. Mostly here because of dependence. */

using Xml;
using Soup;
using Gee;

public class LastFM.Core : Object {
	BeatBox.LibraryManager lm;
	
	/** NOTICE: These API keys and secrets are unique to BeatBox and Beatbox
	 * only. To get your own, FREE key go to http://www.last.fm/api/account */
	
	public static const string api = "a40ea1720028bd40c66b17d7146b3f3b";
	public static const string secret = "92ba5023f6868e680a3352c71e21243d";

	public string token;
	public string session_key;
	
	public signal void logged_in();
	public signal void similar_retrieved(LinkedList<int> similarIDs, LinkedList<BeatBox.Media> similarDont);
	
	LastFM.SimilarMedias similarMedias;
	
	Mutex _artists_lock;
	Mutex _albums_lock;
	Mutex _tracks_lock;
	HashMap<string, LastFM.ArtistInfo> _artists;//key:artist
	HashMap<string, LastFM.AlbumInfo> _albums;//key:artist<sep>album
	HashMap<string, LastFM.TrackInfo> _tracks;//key:artist<sep>album<sep>track
	
	public Core(BeatBox.LibraryManager lmm) {
		lm = lmm;
		var lastfm_settings = new LastFM.Settings ();
		session_key = lastfm_settings.session_key;
		
		similarMedias = new LastFM.SimilarMedias(lm);
		
		_artists = new HashMap<string, LastFM.ArtistInfo>();
		_albums = new HashMap<string, LastFM.AlbumInfo>();
		_tracks = new HashMap<string, LastFM.TrackInfo>();
		
		_artists_lock.lock();
		foreach(LastFM.ArtistInfo a in lm.dbm.load_artists()) {
			_artists.set(a.name, a);
		}
		_artists_lock.unlock();
		
		_albums_lock.lock();
		foreach(LastFM.AlbumInfo a in lm.dbm.load_albums()) {
			_albums.set(a.name + " by " + a.artist, a);
		}
		_albums_lock.unlock();
		
		_tracks_lock.lock();
		foreach(LastFM.TrackInfo t in lm.dbm.load_tracks()) {
			_tracks.set(t.name + " by " + t.artist, t);
		}
		_tracks_lock.unlock();
		
		similarMedias.similar_retrieved.connect(similar_retrieved_signal);
	}
	
	/************* Last FM Artist Stuff ************/
	public GLib.List<LastFM.ArtistInfo> artists() {
		var rv = new GLib.List<LastFM.ArtistInfo>();
		foreach(var artist in _artists.values)
			rv.append(artist);
		
		return rv;
	}
	
	public void save_artist(LastFM.ArtistInfo artist) {
		_artists_lock.lock();
		_artists.set(artist.name.down(), artist);
		_artists_lock.unlock();
	}
	
	public bool artist_info_exists(string artist_key) {
		return _artists.get(artist_key.down()) != null;
	}
	
	public LastFM.ArtistInfo? get_artist(string artist_key) {
		LastFM.ArtistInfo? rv = null;
		
		_artists_lock.lock();
		if(artist_info_exists(artist_key.down()))	
			rv = _artists.get(artist_key.down());
		_artists_lock.unlock();
			
		return rv;
	}
	
	/************** LastFM Album stuff **************/
	public GLib.List<LastFM.AlbumInfo> albums() {
		var rv = new GLib.List<LastFM.AlbumInfo>();
		foreach(var album in _albums.values)
			rv.append(album);
		
		return rv;
	}
	
	public void save_album(LastFM.AlbumInfo album) {
		_albums_lock.lock();
		_albums.set(album.name.down() + " by " + album.artist.down(), album);
		_albums_lock.unlock();
	}
	
	public bool album_info_exists(string album_key) {
		return _albums.get(album_key) != null;
	}
	
	public LastFM.AlbumInfo? get_album(string album_key) {
		LastFM.AlbumInfo? rv = null;
		
		_albums_lock.lock();
		if(album_info_exists(album_key.down()))	
			rv = _albums.get(album_key.down());
		_albums_lock.unlock();
			
		return rv;
	}
	
	/************** Last FM Track Stuff ***************/
	public GLib.List<LastFM.TrackInfo> tracks() {
		var rv = new GLib.List<LastFM.TrackInfo>();
		foreach(var track in _tracks.values)
			rv.append(track);
		
		return rv;
	}
	
	public void save_track(LastFM.TrackInfo track) {
		_tracks_lock.lock();
		if (track != null && track.name != null && track.artist != null)
		_tracks.set(track.name.down() + " by " + track.artist.down(), track);
		_tracks_lock.unlock();
	}
	
	public bool track_info_exists(string track_key) {
		return _tracks.get(track_key.down()) != null;
	}
	
	public LastFM.TrackInfo? get_track(string track_key) {
		LastFM.TrackInfo? rv = null;
		
		_tracks_lock.lock();
		if(track_info_exists(track_key.down()))
			rv = _tracks.get(track_key.down());
		_tracks_lock.unlock();
			
		return rv;
	}
	
	/** Last.FM Api functions **/
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
			stdout.printf ("User tried to ban a track, but is not logged into Last FM\n");
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
			stdout.printf ("User tried to ban a track, but is not logged into Last FM\n");
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
	
	/** Fetches the current track's info from last.fm
	 */
	public void fetchCurrentTrackInfo() {
		try {
			new Thread<void*>.try (null, track_thread_function);
		} catch(GLib.Error err) {
			stdout.printf ("ERROR: Could not create last fm thread: %s \n", err.message);
		}
	}
	
	void* track_thread_function () {
		LastFM.TrackInfo track = new LastFM.TrackInfo.basic();

		string album_artist_s = lm.media_info.media.album_artist;
		string track_s = lm.media_info.media.title;

		/* first fetch track info since that is most likely to change */
		if(!track_info_exists(track_s + " by " + album_artist_s)) {
			track = new LastFM.TrackInfo.with_info(album_artist_s, track_s);

			if(track != null)
				save_track(track);

			if(track_s == lm.media_info.media.title && album_artist_s == lm.media_info.media.album_artist) {
				lm.media_info.track = track;
			}
		}

		return null;
	}
	
	public void fetchCurrentAlbumInfo() {
		try {
			new Thread<void*>.try (null, album_thread_function);
		} catch(GLib.Error err) {
			stdout.printf ("ERROR: Could not create last fm thread: %s \n", err.message);
		}
	}
	
	void* album_thread_function () {
		LastFM.AlbumInfo album = new LastFM.AlbumInfo.basic();
		
		string album_artist_s = lm.media_info.media.album_artist;
		string artist_s = lm.media_info.media.artist;
		string album_s = lm.media_info.media.album;

		/* fetch album info now. only save if still on current media */
		if(!album_info_exists(album_s + " by " + album_artist_s) || lm.get_cover_album_art(lm.media_info.media.rowid) == null) {
			// This does the fetching to internet. may take a few seconds
			album = new LastFM.AlbumInfo.with_info(album_artist_s, album_s);

			if(album != null) {
				save_album(album);
			}

			/* If on same song, update lm.media_info.album */
			if(lm.media_active && album != null && album_s == lm.media_info.media.album && artist_s == lm.media_info.media.artist) {
				lm.media_info.album = album;
			}
			
			/* If we found an album art, and we don't have one yet, save it to file **/
			if(album.url_image.url != null && lm.get_cover_album_art_from_key(album_artist_s, album_s) == null) {
				stdout.printf("Saving album locally\n");
				lm.save_album_locally(lm.media_info.media.rowid, album.url_image.url);
			}
		}
		else {
			stdout.printf("Not fetching album info or art\n");
		}

		return null;
	}
	
	/** Fetches artist info for currently playing song's artist
	 */
	public void fetchCurrentArtistInfo() {
		try {
			new Thread<void*>.try (null, artist_thread_function);
		} catch(GLib.Error err) {
			stdout.printf ("ERROR: Could not create last fm thread: %s \n", err.message);
		}
	}
	
	void* artist_thread_function () {
		LastFM.ArtistInfo artist = new LastFM.ArtistInfo.basic();

		string album_artist_s = lm.media_info.media.album_artist;

		/* fetch artist info now. save only if still on current media */
		if(!artist_info_exists(album_artist_s)) {
			// This does the fetching to internet. may take a few seconds
			artist = new LastFM.ArtistInfo.with_artist(album_artist_s);

			if(artist != null)
				save_artist(artist);

			// If still playing the same song, update lm.media_info.artist
			if(lm.media_active && artist != null && album_artist_s == lm.media_info.media.album_artist) {
				lm.media_info.artist = artist;
			}
		}

		return null;
	}
	
	/** Update's the user's currently playing track on last.fm
	 * 
	 */
	public void postNowPlaying() {
		try {
			new Thread<void*>.try (null, update_nowplaying_thread_function);
		} catch(GLib.Error err) {
			stdout.printf ("ERROR: Could not create last fm thread: %s \n", err.message);
		}
	}
	
	void* update_nowplaying_thread_function() {
		if(session_key == null || session_key == "") {
			stdout.printf ("Last.FM user not logged in\n");
			return null;
		}
		if(!lm.media_active)
			return null;
		
		var artist = lm.media_info.media.artist;
		var title = lm.media_info.media.title;
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
			return null;

		return null;
	}
	
	/**
	 * Scrobbles the currently playing track to last.fm
	 */
	public void postScrobbleTrack() {
		try {
			new Thread<void*>.try (null, scrobble_thread_function);
		} catch(GLib.Error err) {
			stdout.printf ("ERROR: Could not create last fm thread: %s \n", err.message);
		}
	}
	
	void* scrobble_thread_function () {
		if(session_key == null || session_key == "") {
			stdout.printf ("Last.FM user not logged in");
			return null;
		}
		if(!lm.media_active)
			return null;
		
		var timestamp = (int)time_t();
		var artist = lm.media_info.media.artist;
		var title = lm.media_info.media.title;
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
			return null;
		
		return null;
	}
	
	public void fetchCurrentSimilarSongs() {
		similarMedias.queryForSimilar(lm.media_info.media);
	}
	
	void similar_retrieved_signal(LinkedList<int> similarIDs, LinkedList<BeatBox.Media> similarDont) {
		similar_retrieved(similarIDs, similarDont);
	}
}
