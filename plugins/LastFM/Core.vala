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

namespace LastFM {

    // NOTICE: These API keys and secrets are unique to Noise and Noise
    // only. To get your own, FREE key go to http://www.last.fm/api/account
    public const string API = "8659cfc191c2cde0b33bb4970fcbbd49";
    public const string SECRET = "f61323da870d6ed9322dc51c875357c6";

    public class Core : Object {
        Noise.LibraryManager lm;

        public Settings lastfm_settings { get; private set; }

        public signal void logged_in();
        public signal void similar_retrieved(LinkedList<int> similarIDs, LinkedList<Noise.Media> similarDont);

        public signal void loved (string title, string artist);
        public signal void baned (string title, string artist);

        LastFM.SimilarMedias similarMedias;

        HashMap<string, LastFM.ArtistInfo> _artists;//key:artist
        HashMap<string, LastFM.AlbumInfo> _albums;//key:artist<sep>album
        HashMap<string, LastFM.TrackInfo> _tracks;//key:artist<sep>album<sep>track

        public Core(Noise.LibraryManager lmm) {
            lm = lmm;

            lastfm_settings = new LastFM.Settings ();

            similarMedias = new LastFM.SimilarMedias(lm);

            _artists = new HashMap<string, LastFM.ArtistInfo>();
            _albums = new HashMap<string, LastFM.AlbumInfo>();
            _tracks = new HashMap<string, LastFM.TrackInfo>();

            lock(_artists) {
                foreach(Noise.ArtistInfo a in lm.dbm.load_artists()) {
                    _artists.set(a.name, (LastFM.ArtistInfo)a);
                }
            }

            lock(_albums) {
                foreach(Noise.AlbumInfo a in lm.dbm.load_albums()) {
                    _albums.set(a.name + " by " + a.artist, (LastFM.AlbumInfo)a);
                }
            }

            lock(_tracks) {
                foreach(Noise.TrackInfo t in lm.dbm.load_tracks()) {
                    _tracks.set(t.name + " by " + t.artist, (LastFM.TrackInfo)t);
                }
            }
            
            Noise.App.main_window.update_media_info.connect ((media) => {postNowPlaying (media);});
            Noise.App.main_window.media_half_played.connect ((media) => {postScrobbleTrack (media);});

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
            lock(_artists) {
                _artists.set(artist.name.down(), artist);
            }
        }

        public bool artist_info_exists(string artist_key) {
            return _artists.get(artist_key.down()) != null;
        }

        public LastFM.ArtistInfo? get_artist(string artist_key) {
            LastFM.ArtistInfo? rv = null;

            lock(_artists) {
                if(artist_info_exists(artist_key.down()))
                    rv = _artists.get(artist_key.down());
            }

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
            lock(_albums) {
                _albums.set(album.name.down() + " by " + album.artist.down(), album);
            }
        }

        public bool album_info_exists(string album_key) {
            return _albums.get(album_key) != null;
        }

        public LastFM.AlbumInfo? get_album(string album_key) {
            LastFM.AlbumInfo? rv = null;

            lock(_albums) {
                if(album_info_exists(album_key.down()))
                    rv = _albums.get(album_key.down());
            }

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
            lock(_tracks) {
                if (track != null && track.name != null && track.artist != null)
                _tracks.set(track.name.down() + " by " + track.artist.down(), track);
            }
        }

        public bool track_info_exists(string track_key) {
            return _tracks.get(track_key.down()) != null;
        }

        public LastFM.TrackInfo? get_track(string track_key) {
            LastFM.TrackInfo? rv = null;

            lock(_tracks) {
                if(track_info_exists(track_key.down()))
                    rv = _tracks.get(track_key.down());
            }

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

        public string generate_trackscrobble_signature(string artist, string track, int timestamp) {
            return generate_md5("api_key" + API + "artist" + artist + "methodtrack.scrobblesk" + lastfm_settings.session_key + "timestamp" + timestamp.to_string() + "track" + track + SECRET);
        }

        public string generate_trackupdatenowplaying_signature(string artist, string track) {
            return generate_md5("api_key" + API + "artist" + artist + "methodtrack.updateNowPlayingsk" + lastfm_settings.session_key + "track" + track + SECRET);
        }

        public string? getToken() {
            var url = "http://ws.audioscrobbler.com/2.0/?method=auth.gettoken&api_key=" + API;

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
            var url = "http://ws.audioscrobbler.com/2.0/?method=auth.getSession&api_key=" + API + "&api_sig=" + sig + "&token=" + token;

            message ("url: %s\n", url);

            Xml.Doc* doc = Parser.parse_file (url);
            if(doc == null) return null;

            Xml.Node* root = doc->get_root_element();
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
            love_thread (title, artist);
        }
        
        private async void love_thread (string title, string artist) {
            SourceFunc callback = love_thread.callback;

            Noise.Threads.add (() => {
                var uri = "http://ws.audioscrobbler.com/2.0/?api_key=" + API + "&api_sig=" + generate_tracklove_signature(artist, title) + "&artist=" + fix_for_url(artist) + "&method=track.love&sk=" + lastfm_settings.session_key + "&track=" + fix_for_url(title);

                Soup.SessionSync session = new Soup.SessionSync();
                Soup.Message message = new Soup.Message ("POST", uri);

                var headers = new Soup.MessageHeaders(MessageHeadersType.REQUEST);
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

                Idle.add ((owned) callback);
            });

            yield;
        }

        public void banTrack (string title, string artist) {
            if (Noise.String.is_empty (lastfm_settings.session_key, true)) {
                debug ("Last.FM user not logged in\n");
                return;
            }
            if (Noise.String.is_empty (title, true) | Noise.String.is_empty (artist, true))
                return;
            ban_thread (title, artist);
        }
        
        private async void ban_thread (string title, string artist) {
            SourceFunc callback = ban_thread.callback;

            Noise.Threads.add (() => {
                
                var uri = "http://ws.audioscrobbler.com/2.0/?api_key=" + API + "&api_sig=" + generate_trackban_signature(artist, title) + "&artist=" + fix_for_url(artist) + "&method=track.ban&sk=" + lastfm_settings.session_key + "&track=" + fix_for_url(title);

                Soup.SessionSync session = new Soup.SessionSync();
                Soup.Message message = new Soup.Message ("POST", uri);

                var headers = new Soup.MessageHeaders(MessageHeadersType.REQUEST);
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

                Idle.add ((owned) callback);
            });

            yield;
        }

        /** Fetches the current track's info from last.fm
         */

        Mutex fetch_info_guard;

        public void fetchCurrentTrackInfo () {
            if (Noise.App.player.media_info.media == null)
                return;
            track_thread (Noise.App.player.media_info.media);
        }

        private async void track_thread (Noise.Media m) {
            SourceFunc callback = track_thread.callback;

            Noise.Threads.add (() => {

                string album_artist_s = m.album_artist;
                string track_s = m.title;

                if (album_artist_s == "")
                    album_artist_s = m.artist;

                // first fetch track info since that is most likely to change
                if (!track_info_exists (track_s + " by " + album_artist_s)) {
                    var track = new LastFM.TrackInfo.with_info (album_artist_s, track_s);

                    if (track != null)
                        save_track (track);

                    // helps to avoid a race condition, since Noise.App.player.media_info.media is subject to change
                    // as the songs are skipped
                    fetch_info_guard.lock ();
                    if (Noise.App.player.media_info.media == m)
                        Noise.App.player.media_info.track = track;
                    fetch_info_guard.unlock ();
                }

                Idle.add ((owned) callback);
            });

            yield;
        }

        public void fetchCurrentAlbumInfo() {
            Noise.Threads.add (album_thread_function);
        }

        private void album_thread_function () {

            var current_media = Noise.App.player.media_info.media;
            if (current_media == null)
                return;

            string album_artist_s = current_media.album_artist;
            string album_s = current_media.album;

            if (album_artist_s == "")
                album_artist_s = current_media.artist;

            /* fetch album info now. only save if still on current media */
            if (!album_info_exists (album_s + " by " + album_artist_s)) {
                // This does the fetching to internet. may take a few seconds
                var album = new LastFM.AlbumInfo.with_info (album_artist_s, album_s);

                if (album == null)
                    return;

                save_album (album);

                /* If on same song, update Noise.App.player.media_info.album */
                fetch_info_guard.lock ();

                if (Noise.App.player.media_active && Noise.App.player.media_info.media == current_media) {
                    Noise.App.player.media_info.album = album;
                }

                fetch_info_guard.unlock ();

                /* If we found an album art, and we don't have one yet, save it to file **/
                var coverart_cache = Noise.CoverartCache.instance;

                if (coverart_cache.has_image (current_media))
                    return;

                if (album.image_uri != "") {
                    message ("Caching last.fm image from URL: %s", album.image_uri);

                    var image_file = File.new_for_uri (album.image_uri);
                    coverart_cache.cache_image_from_file_async.begin (current_media, image_file);
                }

            }
            else {
                message ("Not fetching album info or art");
            }
        }

        /** Fetches artist info for currently playing song's artist
         */
        public void fetchCurrentArtistInfo() {
            Noise.Threads.add (artist_thread_function);
        }

        private void artist_thread_function () {
            var current_media = Noise.App.player.media_info.media;
            if (current_media == null)
                return;

            string album_artist_s = current_media.album_artist;
            if (album_artist_s == "")
                album_artist_s = current_media.artist;


            /* fetch artist info now. save only if still on current media */

            if (!artist_info_exists (album_artist_s)) {
                // This does the fetching to internet. may take a few seconds
                var artist = new LastFM.ArtistInfo.with_artist (album_artist_s);

                if (artist != null)
                    save_artist (artist);

                // If still playing the same song, update Noise.App.player.media_info.artist
                fetch_info_guard.lock ();

                if (Noise.App.player.media_info.media == current_media) {
                    Noise.App.player.media_info.artist = (Noise.ArtistInfo)artist;
                }

                fetch_info_guard.unlock ();
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
            update_nowplaying_thread (m);
        }
        
        private async void update_nowplaying_thread (Noise.Media m) {
            SourceFunc callback = update_nowplaying_thread.callback;

            Noise.Threads.add (() => {
                debug ("Sound send as now_playing");

                var uri = "http://ws.audioscrobbler.com/2.0/?api_key=" + API + "&api_sig=" + generate_trackupdatenowplaying_signature(m.artist, m.title) + "&artist=" + fix_for_url(m.artist) + "&method=track.updateNowPlaying&sk=" + lastfm_settings.session_key + "&track=" + fix_for_url(m.title);

                Soup.SessionSync session = new Soup.SessionSync();
                Soup.Message message = new Soup.Message ("POST", uri);

                var headers = new Soup.MessageHeaders(MessageHeadersType.REQUEST);
                headers.append("api_key", API);
                headers.append("api_sig", generate_trackupdatenowplaying_signature(m.artist, m.title));
                headers.append("artist", m.artist);
                headers.append("method", "track.updateNowPlaying");
                headers.append("sk", lastfm_settings.session_key);
                headers.append("track", m.title);

                message.request_headers = headers;

                /* send the HTTP request */
                session.send_message(message);

                Idle.add ((owned) callback);
            });

            yield;
        }

        /**
         * Scrobbles the currently playing track to last.fm
         */
        public void postScrobbleTrack (Noise.Media m) {
            if (Noise.String.is_empty (lastfm_settings.session_key, true)) {
                debug ("Last.FM user not logged in\n");
                return;
            }
            if (!Noise.App.player.media_active)
                return;
            if (m == null)
                return;
            scrobble_thread (m);
        }
        
        private async void scrobble_thread (Noise.Media m) {
            SourceFunc callback = scrobble_thread.callback;

            Noise.Threads.add (() => {
                debug ("Sound Scrobbled");

                var timestamp = (int)time_t();
                var uri = "http://ws.audioscrobbler.com/2.0/?api_key=" + API + "&api_sig=" + generate_trackscrobble_signature(m.artist, m.title, timestamp) + "&artist=" + fix_for_url(m.artist) + "&method=track.scrobble&sk=" + lastfm_settings.session_key + "&timestamp=" + timestamp.to_string() + "&track=" + fix_for_url(m.title);

                Soup.SessionSync session = new Soup.SessionSync();
                Soup.Message message = new Soup.Message ("POST", uri);

                var headers = new Soup.MessageHeaders(MessageHeadersType.REQUEST);
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

                Idle.add ((owned) callback);
            });

            yield;
        }

        public void fetchCurrentSimilarSongs() {
            similarMedias.queryForSimilar(Noise.App.player.media_info.media);
        }

        void similar_retrieved_signal(LinkedList<int> similarIDs, LinkedList<Noise.Media> similarDont) {
            similar_retrieved(similarIDs, similarDont);
        }
    }
}
