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

namespace LastFM {

    // NOTICE: These API keys and secrets are unique to Noise and Noise
    // only. To get your own, FREE key go to http://www.last.fm/api/account
    public const string API = "8659cfc191c2cde0b33bb4970fcbbd49";
    public const string SECRET = "f61323da870d6ed9322dc51c875357c6";
}

public class LastFM.Core : Object {

    public Settings lastfm_settings { get; private set; }

    public signal void logged_in ();
    public signal void similar_retrieved (Gee.LinkedList<int> similarIDs, Gee.LinkedList<Noise.Media> similarDont);

    public signal void loved (string title, string artist);
    public signal void baned (string title, string artist);

    LastFM.SimilarMedias similarMedias;

    public Core() {

        lastfm_settings = new LastFM.Settings ();

        similarMedias = new LastFM.SimilarMedias();
        
        Noise.App.main_window.update_media_info.connect ((media) => {postNowPlaying (media);});
        Noise.App.main_window.media_half_played.connect ((media) => {postScrobbleTrack (media);});
        Noise.libraries_manager.local_library.media_imported.connect ((medias) => {fetch_albums_slowly.begin (medias);});

        similarMedias.similar_retrieved.connect(similar_retrieved_signal);
    }
    
    public Noise.StaticPlaylist get_similar_playlist () {
        return similarMedias.similar_playlist;
    }

    public string generate_md5(string text) {
        return GLib.Checksum.compute_for_string(ChecksumType.MD5, text, text.length);
    }

    public string generate_getsession_signature(string token) {
        return generate_md5("api_key" + API + "methodauth.getSessiontoken" + token + SECRET);
    }

    public string generate_tracklove_signature(string artist, string track) {
        return generate_md5("api_key" + API + "artist" + artist + "methodtrack.lovesk" + lastfm_settings.session_key + "track" + track + SECRET);
    }

    public string generate_trackban_signature(string artist, string track) {
        return generate_md5("api_key" + API + "artist" + artist + "methodtrack.bansk" + lastfm_settings.session_key + "track" + track + SECRET);
    }

    public string generate_trackscrobble_signature (string artist, string track, int timestamp) {
        return generate_md5 ("api_key" + API + "artist" + artist + "methodtrack.scrobblesk" + lastfm_settings.session_key + "timestamp" + timestamp.to_string() + "track" + track + SECRET);
    }

    public string generate_trackscrobble_signature2 (string artist, string track, string album, int timestamp) {
        return generate_md5 ("album" + album + "api_key" + API + "artist" + artist + "methodtrack.scrobblesk" + lastfm_settings.session_key + "timestamp" + timestamp.to_string() + "track" + track + SECRET);
    }

    public string generate_trackupdatenowplaying_signature (string artist, string track) {
        return generate_md5 ("api_key" + API + "artist" + artist + "methodtrack.updateNowPlayingsk" + lastfm_settings.session_key + "track" + track + SECRET);
    }

    public string? getToken () {
        var url = "http://ws.audioscrobbler.com/2.0/?method=auth.gettoken&api_key=" + API;

        Xml.Doc* doc = Xml.Parser.parse_file (url);
        if (doc == null) return null;

        Xml.Node* root = doc->get_root_element ();
        if (root == null) return null;

        for (Xml.Node* iter = root->children; iter != null; iter = iter->next) {
            if (iter->name == "token") {
                return iter->get_content ();
            }
        }
        return null;
    }

    public string? getSessionKey (string token) {
        var sig = generate_getsession_signature (token);
        var url = "http://ws.audioscrobbler.com/2.0/?method=auth.getSession&api_key=" + API + "&api_sig=" + sig + "&token=" + token;

        message ("url: %s\n", url);

        Xml.Doc* doc = Xml.Parser.parse_file (url);
        if(doc == null) return null;

        Xml.Node* root = doc->get_root_element ();
        if(root == null) return null;

        for (Xml.Node* iter = root->children; iter != null; iter = iter->next) {
            if(iter->name == "session") {
                for(Xml.Node* n = iter->children; n != null; n = n->next) {
                    if(n->name == "key") {
                        return n->get_content();
                        }
                }
            }
        }
        return null;
    }

    public void loveTrack (string title, string artist) {
        if (Noise.String.is_empty (lastfm_settings.session_key, true)) {
            debug ("Last.FM user not logged in\n");
            return;
        }
        if (Noise.String.is_empty (title, true) | Noise.String.is_empty (artist, true))
            return;
        love_async.begin (title, artist);
    }
    
    private async void love_async (string title, string artist) {
        var uri = "http://ws.audioscrobbler.com/2.0/?api_key=" + API + "&api_sig=" + generate_tracklove_signature(artist, title) + "&artist=" + GLib.Uri.escape_string (artist) + "&method=track.love&sk=" + lastfm_settings.session_key + "&track=" + GLib.Uri.escape_string (title);

        var session = new Soup.Session ();
        Soup.Message message = new Soup.Message ("POST", uri);

        var headers = new Soup.MessageHeaders (Soup.MessageHeadersType.REQUEST);
        headers.append("api_key", API);
        headers.append("api_sig", generate_tracklove_signature(artist, title));
        headers.append("artist", artist);
        headers.append("method", "track.love");
        headers.append("sk", lastfm_settings.session_key);
        headers.append("track", title);

        message.request_headers = headers;

        /* send the HTTP request */
        session.send_message(message);

        if(message.response_body.length != 0)
            loved (title, artist);
    }

    public void banTrack (string title, string artist) {
        if (Noise.String.is_empty (lastfm_settings.session_key, true)) {
            debug ("Last.FM user not logged in\n");
            return;
        }
        if (Noise.String.is_empty (title, true) | Noise.String.is_empty (artist, true))
            return;
        ban_async.begin (title, artist);
    }
    
    private async void ban_async (string title, string artist) {
        var uri = "http://ws.audioscrobbler.com/2.0/?api_key=" + API + "&api_sig=" + generate_trackban_signature(artist, title) + "&artist=" + GLib.Uri.escape_string (artist) + "&method=track.ban&sk=" + lastfm_settings.session_key + "&track=" + GLib.Uri.escape_string (title);

        var session = new Soup.Session ();
        Soup.Message message = new Soup.Message ("POST", uri);

        var headers = new Soup.MessageHeaders (Soup.MessageHeadersType.REQUEST);
        headers.append("api_key", API);
        headers.append("api_sig", generate_trackban_signature(artist, title));
        headers.append("artist", artist);
        headers.append("method", "track.ban");
        headers.append("sk", lastfm_settings.session_key);
        headers.append("track", title);

        message.request_headers = headers;

        /* send the HTTP request */
        session.send_message(message);

        if(message.response_body.length != 0)
            baned (title, artist);
    }

    /** Fetches the current track's info from last.fm
     */

    public async void fetch_albums_slowly (Gee.Collection<Noise.Media> new_medias) {
        var albums = new Gee.ArrayList<string> ();
        var album_artist = new Gee.ArrayList<string> ();
        foreach (var media in new_medias) {
            string album_artist_s = media.album_artist;
            string album_s = media.album;

            if (album_artist_s == "")
                album_artist_s = media.artist;
            
            if (!albums.contains (album_s) || !album_artist.contains (album_artist_s)) {
                if (!albums.contains (album_s))
                    albums.add (album_s);
                if (!album_artist.contains (album_artist_s))
                    album_artist.add (album_artist_s);
                fetch_album_info_async.begin (media);
            }
        }
    }

    public void fetch_album_info (Noise.Media media) {
        fetch_album_info_async.begin (media);
    }

    private async void fetch_album_info_async (Noise.Media media) {
        // This does the fetching to internet. may take a few seconds
        var album = new LastFM.AlbumInfo (media);

        /* If we found an album art, and we don't have one yet, save it to file **/
        var coverart_cache = Noise.CoverartCache.instance;
        if (coverart_cache.has_image (media))
            return;

        if (album.image_uri != "") {
            debug ("Caching last.fm image from URL: %s", album.image_uri);

            var image_file = File.new_for_uri (album.image_uri);
            coverart_cache.cache_image_from_file_async.begin (media, image_file);
        }
    }

    /** Update's the user's currently playing track on last.fm
     *
     */
    public void postNowPlaying (Noise.Media m) {
        if(Noise.String.is_empty (lastfm_settings.session_key, true)) {
            debug ("Last.FM user not logged in\n");
            return;
        }
        if (m == null)
            return;
        update_nowplaying_async (m);
    }
    
    private void update_nowplaying_async (Noise.Media m) {
        debug ("Sound send as now_playing");

        var uri = "http://ws.audioscrobbler.com/2.0/?api_key=" + API + "&api_sig=" + generate_trackupdatenowplaying_signature(m.artist, m.title) + "&artist=" + GLib.Uri.escape_string (m.artist) + "&method=track.updateNowPlaying&sk=" + lastfm_settings.session_key + "&track=" + GLib.Uri.escape_string (m.title);

        var session = new Soup.Session ();
        Soup.Message message = new Soup.Message ("POST", uri);

        var headers = new Soup.MessageHeaders (Soup.MessageHeadersType.REQUEST);
        headers.append("api_key", API);
        headers.append("api_sig", generate_trackupdatenowplaying_signature(m.artist, m.title));
        headers.append("artist", m.artist);
        headers.append("method", "track.updateNowPlaying");
        headers.append("sk", lastfm_settings.session_key);
        headers.append("track", m.title);

        message.request_headers = headers;

        /* send the HTTP request */
        session.send_message(message);
    }

    /**
     * Scrobbles the currently playing track to last.fm
     */
    public void postScrobbleTrack (Noise.Media m) {
        if (Noise.String.is_empty (lastfm_settings.session_key, true)) {
            debug ("Last.FM user not logged in\n");
            return;
        }
        if (Noise.App.player.current_media == null)
            return;
        if (m == null)
            return;
        scrobble_async.begin (m);
    }
    
    private async void scrobble_async (Noise.Media m) {
        debug ("Sound Scrobbled");

        var timestamp = (int)time_t();
        var uri = "http://ws.audioscrobbler.com/2.0/?api_key=" + API + "&artist=" + GLib.Uri.escape_string (m.artist) + "&method=track.scrobble&sk=" + lastfm_settings.session_key + "&timestamp=" + timestamp.to_string() + "&track=" + GLib.Uri.escape_string (m.title);
        if (m.album != null && m.album != "")
            uri = uri + "&album=" + GLib.Uri.escape_string (m.album) + "&api_sig=" + generate_trackscrobble_signature2(m.artist, m.title, m.album, timestamp);
        else
            uri = uri + "&api_sig=" + generate_trackscrobble_signature(m.artist, m.title, timestamp);
        warning (uri);

        var session = new Soup.Session ();
        Soup.Message message = new Soup.Message ("POST", uri);

        var headers = new Soup.MessageHeaders (Soup.MessageHeadersType.REQUEST);
        headers.append("api_key", API);
        headers.append("api_sig", generate_trackscrobble_signature(m.artist, m.title, timestamp));
        headers.append("artist", m.artist);
        headers.append("method", "track.scrobble");
        headers.append("sk", lastfm_settings.session_key);
        headers.append("timestamp", timestamp.to_string());
        headers.append("track", m.title);

        message.request_headers = headers;

        /* send the HTTP request */
        session.send_message(message);
    }

    public void fetchCurrentSimilarSongs () {
        similarMedias.queryForSimilar (Noise.App.player.current_media);
    }

    void similar_retrieved_signal (Gee.LinkedList<int> similarIDs, Gee.LinkedList<Noise.Media> similarDont) {
        similar_retrieved (similarIDs, similarDont);
    }
}
