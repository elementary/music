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

namespace Noise.Database.Tables {

public const string PLAYLISTS = """
CREATE TABLE IF NOT EXISTS playlists (`name` TEXT, `media` TEXT,
'sort_column_id' INT, 'sort_direction' TEXT, 'columns' TEXT)
""";

public const string SMART_PLAYLISTS = """
CREATE TABLE IF NOT EXISTS smart_playlists (`name` TEXT, `and_or` INT, `queries` TEXT,
'limit' INT, 'limit_amount' INT, 'sort_column_id' INT,  'sort_direction' TEXT,
'columns' TEXT)
""";

public const string MEDIA = """
CREATE TABLE IF NOT EXISTS media (`uri` TEXT, 'file_size' INT, `title` TEXT,
`artist` TEXT, 'composer' TEXT, 'album_artist' TEXT, `album` TEXT,
'grouping' TEXT, `genre` TEXT,`comment` TEXT, 'lyrics' TEXT, 'has_embedded' INT,
`year` INT, `track` INT, 'track_count' INT, 'album_number' INT,
'album_count' INT, `bitrate` INT, `length` INT, `samplerate` INT, `rating` INT,
`playcount` INT, 'skipcount' INT, `dateadded` INT, `lastplayed` INT,
'lastmodified' INT, 'mediatype' INT, 'resume_pos' INT)
""";

public const string DEVICES = """
CREATE TABLE IF NOT EXISTS devices ('unique_id' TEXT, 'sync_when_mounted' INT,
'sync_music' INT, 'sync_podcasts' INT, 'sync_audiobooks' INT, 'sync_all_music' INT,
'sync_all_podcasts' INT, 'sync_all_audiobooks' INT, 'music_playlist' STRING,
'podcast_playlist' STRING, 'audiobook_playlist' STRING, 'last_sync_time' INT)
""";

public const string ARTISTS = """
CREATE TABLE IF NOT EXISTS artists ( 'name' TEXT, 'mbid' TEXT, 'listeners' INT,
'playcount' INT, 'published' TEXT, 'summary' TEXT, 'content' TEXT, 'image_uri' TEXT)
""";

public const string ALBUMS = """
CREATE TABLE IF NOT EXISTS albums ('name' TEXT, 'artist' TEXT, 'mbid' TEXT,
'release_date' TEXT, 'summary' TEXT, 'listeners' INT, 'playcount' INT, 'image_uri' TEXT)
""";

public const string TRACKS = """
CREATE TABLE IF NOT EXISTS tracks ('id' INT, 'name' TEXT, 'artist' TEXT,
'album' TEXT, 'duration' INT, 'listeners' INT, 'playcount' INT, 'summary' TEXT,
'content' TEXT)
""";

}
