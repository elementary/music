// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012-2017 elementary LLC. (https://elementary.io)
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
 * The Noise authors hereby grant permission for non-GPL compatible
 * GStreamer plugins to be used and distributed together with GStreamer
 * and Noise. This permission is above and beyond the permissions granted
 * by the GPL license by which Noise is covered. If you modify this code
 * you may extend this exception to your version of the code, but you are not
 * obligated to do so. If you do not wish to do so, delete this exception
 * statement from your version.
 */

public class Noise.Plugins.iPodMediaHelper {
    public static Medium medium_from_track (string uri, GPod.Track track) {
        Medium rv = null;
        if (uri.has_suffix ("/")) {
            rv = new Medium (uri.slice (0, uri.char_count ()-1) + GPod.iTunesDB.filename_ipod2fs (track.ipod_path));
        }

        if (rv == null)
            rv = new Medium (uri + GPod.iTunesDB.filename_ipod2fs (track.ipod_path));

        rv.isTemporary = true;
        rv.title = track.title;
        rv.artist = track.artist;
        rv.album_artist = track.albumartist;
        rv.album = track.album;
        rv.genre = track.genre;
        rv.comment = track.comment;
        rv.composer = track.composer;
        rv.grouping = track.grouping;
        rv.album_number = track.cd_nr;
        rv.album_count = track.cds;
        rv.track = track.track_nr;
        rv.track_count = track.tracks;
        rv.bitrate = track.bitrate;
        rv.year = track.year;
        rv.date_added = (int)track.time_added;
        rv.last_modified = (int)track.time_modified;
        rv.last_played = (int)track.time_played;
        rv.rating = track.rating * 20;
        rv.play_count = track.playcount;
        rv.bpm = track.BPM;
        rv.skip_count = track.skipcount;
        rv.length = (uint)track.tracklen;
        rv.file_size = track.size;
        rv.resume_pos = (int)track.bookmark_time;

        if(rv.artist == "" && rv.album_artist != "")
            rv.artist = rv.album_artist;
        else if(rv.album_artist == "" && rv.artist != "")
            rv.album_artist = rv.artist;

        return rv;
    }

    public static void update_track (ref unowned GPod.Track t, Medium m) {
        if(t == null)
            return;

        t.title = m.get_display_title ();
        t.artist = m.artist;
        t.albumartist = m.album_artist;
        t.album = m.album;
        t.genre = m.genre;
        t.comment = m.comment;
        t.composer = m.composer;
        t.grouping = m.grouping;
        t.cd_nr = (int)m.album_number;
        t.cds = (int)m.album_count;
        t.track_nr = (int)m.track;
        t.tracks = (int)m.track_count;
        t.bitrate = (int)m.bitrate;
        t.year = (int)m.year;
        t.time_modified = (time_t)m.last_modified;
        t.time_played = (time_t)m.last_played;
        t.rating = m.rating * 20;
        t.playcount = m.play_count;
        t.recent_playcount = m.play_count;
        t.BPM = (uint16)m.bpm;
        t.skipcount = m.skip_count;
        t.tracklen = (int)m.length;
        t.size = (uint) m.file_size;
        t.mediatype = GPod.MediaType.AUDIO;
        t.lyrics_flag = 1;
        t.description = m.lyrics;
        t.mark_unplayed = (m.play_count == 0) ? 1 : 0;
        t.bookmark_time = m.resume_pos;

        if (t.artist == "" && (t.albumartist != "" || t.albumartist != null))
            t.artist = t.albumartist;
        else if (t.albumartist == "" && (t.artist != "" || t.artist != null))
            t.albumartist = t.artist;
    }

    /**
     * caller *must* set ipod_path
     */
    public static GPod.Track track_from_medium (Medium m) {
        GPod.Track t = new GPod.Track();
        unowned GPod.Track tu = t;
        update_track (ref tu, m);
        return t;
    }

}
