// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012 Noise Developers (http://launchpad.net/noise)
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
 *
 * The Noise authors hereby grant permission for non-GPL compatible
 * GStreamer plugins to be used and distributed together with GStreamer
 * and Noise. This permission is above and beyond the permissions granted
 * by the GPL license by which Noise is covered. If you modify this code
 * you may extend this exception to your version of the code, but you are not
 * obligated to do so. If you do not wish to do so, delete this exception
 * statement from your version.
 */

namespace Noise.Database {
    namespace Tables {
        public const string PLAYLISTS = """CREATE TABLE IF NOT EXISTS playlists (name TEXT, media TEXT,
            sort_column_id INT, sort_direction TEXT, columns TEXT, rowid INTEGER PRIMARY KEY AUTOINCREMENT)""";

        public const string SMART_PLAYLISTS = """CREATE TABLE IF NOT EXISTS smart_playlists (name TEXT,
            and_or INT, queries TEXT, limited INT, limit_amount INT, rowid INTEGER PRIMARY KEY AUTOINCREMENT)""";

        public const string COLUMNS = """CREATE TABLE IF NOT EXISTS columns (is_smart INT, name TEXT,
            sort_column_id INT, sort_direction TEXT, columns TEXT)""";

        public const string MEDIA = """CREATE TABLE IF NOT EXISTS media (uri TEXT, file_size INT,
            title TEXT, artist TEXT, composer TEXT, album_artist TEXT, album TEXT,
            grouping TEXT, genre TEXT,comment TEXT, lyrics TEXT, has_embedded INT,
            year INT, track INT, track_count INT, album_number INT,
            album_count INT, bitrate INT, length INT, samplerate INT, rating INT,
            playcount INT, skipcount INT, dateadded INT, lastplayed INT,
            lastmodified INT, rowid INTEGER PRIMARY KEY AUTOINCREMENT)""";

        public const string DEVICES = """CREATE TABLE IF NOT EXISTS devices (unique_id TEXT,
            sync_when_mounted INT, sync_music INT, sync_podcasts INT, sync_audiobooks INT,
            sync_all_music INT, sync_all_podcasts INT, sync_all_audiobooks INT, music_playlist STRING,
            podcast_playlist STRING, audiobook_playlist STRING, last_sync_time INT)""";
    }

    /*
     * NOTE:
     * Update those constants when you change the order of columns.
     */
    namespace Playlists {
        public static const string TABLE_NAME = "playlists";
        public static const string NAME = "+0";
        public static const string MEDIA = "+1";
        public static const string SORT_COLUMN_ID = "+2";
        public static const string SORT_DIRECTION = "+3";
        public static const string COLUMNS = "+4";
        public static const string ROWID = "+5";
    }

    namespace SmartPlaylists {
        public static const string TABLE_NAME = "smart_playlists";
        public static const string NAME = "+0";
        public static const string AND_OR = "+1";
        public static const string QUERIES = "+2";
        public static const string LIMITED = "+3";
        public static const string LIMIT_AMOUNT = "+4";
        public static const string ROWID = "+5";
    }

    namespace Media {
        public static const string TABLE_NAME = "media";
        public static const string URI = "+0";
        public static const string FILE_SIZE = "+1";
        public static const string TITLE = "+2";
        public static const string ARTIST = "+3";
        public static const string COMPOSER = "+4";
        public static const string ALBUM_ARTIST = "+5";
        public static const string ALBUM = "+6";
        public static const string GROUPING = "+7";
        public static const string GENRE = "+8";
        public static const string COMMENT = "+9";
        public static const string LYRICS = "+10";
        public static const string HAS_EMBEDDED = "+11";
        public static const string YEAR = "+12";
        public static const string TRACK = "+13";
        public static const string TRACK_COUNT = "+14";
        public static const string ALBUM_NUMBER = "+15";
        public static const string ALBUM_COUNT = "+16";
        public static const string BITRATE = "+17";
        public static const string LENGTH = "+18";
        public static const string SAMPLERATE = "+19";
        public static const string RATING = "+20";
        public static const string PLAYCOUNT = "+21";
        public static const string SKIPCOUNT = "+22";
        public static const string DATEADDED = "+23";
        public static const string LASTPLAYED = "+24";
        public static const string LASTMODIFIED = "+25";
        public static const string ROWID = "+26";
    }

    /*
     * Helper functions.
     */
    private static Value make_string_value (string str) {
        var val = Value (typeof(string));
        val.set_string (str);
        return val;
    }

    private static Value make_bool_value (bool bl) {
        var val = Value (typeof(bool));
        val.set_boolean (bl);
        return val;
    }

    private static Value make_uint_value (uint u) {
        var val = Value (typeof(uint));
        val.set_uint (u);
        return val;
    }

    private static Value make_int_value (int u) {
        var val = Value (typeof(int));
        val.set_int (u);
        return val;
    }

    private static Value make_int64_value (int64 u) {
        var val = Value (typeof(int64));
        val.set_int64 (u);
        return val;
    }

    private static Value make_uint64_value (uint64 u) {
        var val = Value (typeof(uint64));
        val.set_uint64 (u);
        return val;
    }

}
