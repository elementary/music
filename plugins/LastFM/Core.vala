// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012-2018 elementary LLC. (https://elementary.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * The Music authors hereby grant permission for non-GPL compatible
 * GStreamer plugins to be used and distributed together with GStreamer
 * and Music. This permission is above and beyond the permissions granted
 * by the GPL license by which Music is covered. If you modify this code
 * you may extend this exception to your version of the code, but you are not
 * obligated to do so. If you do not wish to do so, delete this exception
 * statement from your version.
 *
 * Authored by: Corentin Noël <corentin@elementary.io>,
 *              Scott Ringwelski <sgringwe@mtu.edu>
 */

/* Merely a place holder for multiple pieces of information regarding
 * the current media playing. Mostly here because of dependence. */

public class LastFM.Core : Object {
    public signal void similar_retrieved (Gee.LinkedList<int> similarIDs, Gee.LinkedList<Music.Media> similarDont);
    public signal void loved (string title, string artist);
    public signal void baned (string title, string artist);

    public bool is_initialized = false;

    private const string API_URL = "http://ws.audioscrobbler.com/2.0/";
    private LastFM.SimilarMedias similarMedias;
    //TODO: make them private and have all transactions in the Core.
    public string api_key;
    public string api_secret;
    public string session_key;

    private static Core core = null;
    public static Core get_default () {
        if (core == null)
            core = new Core ();

        return core;
    }

    private GLib.Cancellable fetch_cancellable;

    private Core () {
        fetch_cancellable = new GLib.Cancellable ();
        similarMedias = new LastFM.SimilarMedias ();
        Music.App.main_window.update_media_info.connect ((media) => {postNowPlaying (media);});
        Music.App.main_window.media_half_played.connect ((media) => {postScrobbleTrack (media);});
        Music.libraries_manager.local_library.media_added.connect ((medias) => {fetch_albums_slowly.begin (medias);});
        similarMedias.similar_retrieved.connect (similar_retrieved_signal);
    }

    public void initialize (string api_key, string api_secret, string session_key) {
        this.api_key = api_key;
        this.api_secret = api_secret;
        this.session_key = session_key;
        is_initialized = true;
    }

    public Music.StaticPlaylist get_similar_playlist () {
        return similarMedias.similar_playlist;
    }

    public void loveTrack (string title, string artist) {
        if (Music.String.is_empty (title, true) | Music.String.is_empty (artist, true))
            return;

        var uri = new Soup.URI (API_URL);
        uri.set_query_from_fields ("method", "track.love",
                                   "api_key", api_key,
                                   "artist", artist,
                                   "track", title,
                                   "sk", session_key,
                                   "api_sig", generate_tracklove_signature (artist, title));

        var session = new Soup.Session ();
        Soup.Message message = new Soup.Message.from_uri ("POST", uri);

        /* send the HTTP request */
        session.send_message (message);

        if (message.status_code == Soup.Status.OK) {
            loved (title, artist);
        }
    }

    public void banTrack (string title, string artist) {
        if (Music.String.is_empty (title, true) | Music.String.is_empty (artist, true))
            return;

        var uri = new Soup.URI (API_URL);
        uri.set_query_from_fields ("method", "track.ban",
                                   "api_key", api_key,
                                   "artist", artist,
                                   "track", title,
                                   "sk", session_key,
                                   "api_sig", generate_trackban_signature (artist, title));

        var session = new Soup.Session ();
        Soup.Message message = new Soup.Message.from_uri ("POST", uri);

        /* send the HTTP request */
        session.send_message (message);

        if (message.status_code == Soup.Status.OK)
            baned (title, artist);
    }

    /** Fetches the current track's info from last.fm
     */

    public async void fetch_albums_slowly (Gee.Collection<Music.Media> new_medias) {
        var albums = new Gee.TreeSet<Music.Album> ();
        foreach (var media in new_medias) {
            if (!(media.album_info in albums)) {
                albums.add (media.album_info);
                get_album_infos.begin (media.album_info, fetch_cancellable);
            }
        }
    }

    /** Update's the user's currently playing track on last.fm
     *
     */
    public void postNowPlaying (Music.Media m) {
        debug ("Sound send as now_playing");
        var uri = new Soup.URI (API_URL);
        uri.set_query_from_fields ("method", "track.updateNowPlaying",
                                   "api_key", api_key,
                                   "artist", m.artist,
                                   "track", m.title,
                                   "sk", session_key,
                                   "api_sig", generate_trackupdatenowplaying_signature (m.artist, m.title));

        var session = new Soup.Session ();
        Soup.Message message = new Soup.Message.from_uri ("POST", uri);

        /* send the HTTP request */
        session.send_message (message);
    }

    /**
     * Scrobbles the currently playing track to last.fm
     */
    public void postScrobbleTrack (Music.Media m) {
        if (Music.App.player.current_media == null)
            return;

        debug ("Sound Scrobbled");
        var timestamp = (int)time_t ();
        var uri = new Soup.URI (API_URL);
        uri.set_query_from_fields ("method", "track.scrobble",
                                   "api_key", api_key,
                                   "artist", m.artist,
                                   "track", m.title,
                                   "timestamp", timestamp.to_string (),
                                   "sk", session_key,
                                   "api_sig", generate_trackscrobble_signature (m.artist, m.title, timestamp));

        var session = new Soup.Session ();
        Soup.Message message = new Soup.Message.from_uri ("POST", uri);

        /* send the HTTP request */
        session.send_message (message);
    }

    public void fetchCurrentSimilarSongs () {
        similarMedias.query_for_similar (Music.App.player.current_media);
    }

    private void similar_retrieved_signal (Gee.LinkedList<int> similarIDs, Gee.LinkedList<Music.Media> similarDont) {
        similar_retrieved (similarIDs, similarDont);
    }


    /** Gets similar medias
     * @param artist The artist of media to get similar to
     * @param title The title of media to get similar to
     * @return The media that are similar
     */
    public async Gee.TreeSet<Music.Media> get_similar_tracks (string title, string artist, GLib.Cancellable cancellable) {
        var returned_medias = new Gee.TreeSet<Music.Media> ();

        var uri = new Soup.URI (API_URL);
        uri.set_query_from_fields ("method", "track.getsimilar",
                                   "api_key", api_key,
                                   "artist", artist,
                                   "track", title,
                                   "format", "json");
        var session = new Soup.Session ();
        try {
            var uri_request = session.request_uri (uri);

            /* send the HTTP request */
            var stream = yield uri_request.send_async (cancellable);
            var parser = new Json.Parser ();
            parser.load_from_stream (stream);
            weak Json.Object parser_object = parser.get_root ().get_object ();
            if (parser_object == null || parser_object.has_member ("similartracks") == false)
                return returned_medias;

            weak Json.Object similartracks = parser_object.get_object_member ("similartracks");
            if (similartracks.has_member ("track") && similartracks.get_member ("track").get_node_type () == Json.NodeType.ARRAY) {
                List<unowned Json.Node> similar_tracks_values = similartracks.get_array_member ("track").get_elements ();
                foreach (unowned Json.Node element in similar_tracks_values) {
                    weak Json.Object track_object = element.get_object ();
                    var similar_to_add = new Music.Media ("");
                    returned_medias.add (similar_to_add);
                    similar_to_add.title = track_object.get_string_member ("name");
                    if (track_object.has_member ("url"))
                        similar_to_add.comment = track_object.get_string_member ("url");
                    if (track_object.has_member ("artist")) {
                        weak Json.Object artist_object = track_object.get_object_member ("artist");
                        if (artist_object.has_member ("name"))
                            similar_to_add.artist = artist_object.get_string_member ("name");
                    }
                }
            }
        } catch (Error e) {
            critical (e.message);
        }

        return returned_medias;
    }

    public async void get_album_infos (Music.Album album, Cancellable cancellable) {
        var uri = new Soup.URI (API_URL);
        uri.set_query_from_fields ("method", "album.getinfo",
                                   "api_key", api_key,
                                   "artist", album.artist,
                                   "album", album.name,
                                   "format", "json");
        var session = new Soup.Session ();
        try {
            var uri_request = session.request_uri (uri);

            /* send the HTTP request */
            var stream = yield uri_request.send_async (cancellable);
            var parser = new Json.Parser ();
            parser.load_from_stream (stream);
            weak Json.Object parser_object = parser.get_root ().get_object ();
            if (parser_object == null || parser_object.has_member ("album") == false)
                return;

            weak Json.Object album_object = parser_object.get_member ("album").get_object ();
            if (album_object.has_member ("image") && album_object.get_member ("image").get_node_type () == Json.NodeType.ARRAY) {
                List<unowned Json.Node> image_values = album_object.get_array_member ("image").get_elements ();
                string image_url = "";
                string image_size = "";
                foreach (unowned Json.Node element in image_values) {
                    weak Json.Object image_object = element.get_object ();
                    unowned string new_size = image_object.get_string_member ("size");
                    if (new_size == "mega" ||
                        (new_size == "extralarge" && image_size != "mega") ||
                        (new_size == "large" && image_size != "mega" && image_size != "extralarge")) {
                        image_url = image_object.get_string_member ("#text").dup ();
                        image_size = new_size.dup ();
                    }
                }

                if (image_url != "") {
                    debug ("Caching last.fm image from URL: %s", image_url);
                    album.save_cover_file (File.new_for_uri (image_url));
                }
            }

            if (album_object.has_member ("releasedate") && album.year == 0) {
                var releasedate = album_object.get_string_member ("releasedate");
                var date = Date ();
                date.set_parse (releasedate);
                if (date.valid ()) {
                    album.year = date.get_year ();
                }
            }
        } catch (Error e) {
            critical (e.message);
        }
    }

    /*
     * Signature generation helpers.
     */

    public string generate_md5 (string text) {
        return GLib.Checksum.compute_for_string (ChecksumType.MD5, text, text.length);
    }

    public string generate_getsession_signature (string token) {
        return generate_md5 ("api_key" + api_key + "methodauth.getSessiontoken" + token + api_secret);
    }

    public string generate_tracklove_signature (string artist, string track) {
        return generate_md5 ("api_key" + api_key + "artist" + artist + "methodtrack.lovesk" + session_key + "track" + track + api_secret);
    }

    public string generate_trackban_signature (string artist, string track) {
        return generate_md5 ("api_key" + api_key + "artist" + artist + "methodtrack.bansk" + session_key + "track" + track + api_secret);
    }

    public string generate_trackscrobble_signature (string artist, string track, int timestamp) {
        return generate_md5 ("api_key" + api_key + "artist" + artist + "methodtrack.scrobblesk" + session_key + "timestamp" + timestamp.to_string () + "track" + track + api_secret);
    }

    public string generate_trackscrobble_signature2 (string artist, string track, string album, int timestamp) {
        return generate_md5 ("album" + album + "api_key" + api_key + "artist" + artist + "methodtrack.scrobblesk" + session_key + "timestamp" + timestamp.to_string () + "track" + track + api_secret);
    }

    public string generate_trackupdatenowplaying_signature (string artist, string track) {
        return generate_md5 ("api_key" + api_key + "artist" + artist + "methodtrack.updateNowPlayingsk" + session_key + "track" + track + api_secret);
    }
}
