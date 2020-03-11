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
 * Authored by: Scott Ringwelski <sgringwe@mtu.edu>
 *              Victor Eduardo <victoreduardm@gmail.com>
 */

public class Music.CDDA : Object {
    private const string FILE_ATTRIBUTE_TITLE = "xattr::org.gnome.audio.title";
    private const string FILE_ATTRIBUTE_ARTIST = "xattr::org.gnome.audio.artist";
    private const string FILE_ATTRIBUTE_GENRE = "xattr::org.gnome.audio.genre";
    private const string FILE_ATTRIBUTE_DURATION = "xattr::org.gnome.audio.duration";

    public static Gee.LinkedList<Media> get_media_list (File device_file) {
        var rv = new Gee.LinkedList<Media> ();

        try {
            var query_attributes = new string[0];
            query_attributes += FILE_ATTRIBUTE_TITLE;
            query_attributes += FILE_ATTRIBUTE_ARTIST;
            query_attributes += FILE_ATTRIBUTE_GENRE;
            query_attributes += FILE_ATTRIBUTE_DURATION;
            query_attributes += FileAttribute.STANDARD_NAME;

            var device_info = device_file.query_info (
                string.joinv (",", query_attributes),
                FileQueryInfoFlags.NONE
            );

            if (device_info == null) {
                warning ("Could not query device attributes");
                return rv;
            }

            string? album_name = device_info.get_attribute_string (FILE_ATTRIBUTE_TITLE);
            string? album_artist = device_info.get_attribute_string (FILE_ATTRIBUTE_ARTIST);
            string? album_genre = device_info.get_attribute_string (FILE_ATTRIBUTE_GENRE);

            message ("CD ALBUM_NAME: %s", album_name);
            message ("CD ALBUM_ARTIST: %s", album_artist);
            message ("CD ALBUM_GENRE: %s", album_genre);

            bool valid_album_artist = Media.is_valid_string_field (album_artist);
            bool valid_album_name = Media.is_valid_string_field (album_name);
            bool valid_album_genre = Media.is_valid_string_field (album_genre);

            query_attributes += FILE_ATTRIBUTE_DURATION;
            var enumerator = device_file.enumerate_children (
                string.joinv (",", query_attributes),
                FileQueryInfoFlags.NONE
            );

            int index = 1;
            FileInfo track_info;

            for (track_info = enumerator.next_file (); track_info != null; track_info = enumerator.next_file ()) {
                // GStreamer's CDDA library handles tracks with URI format: cdda://$TRACK_NUMBER
                var s = new Media (enumerator.get_container ().get_uri () + track_info.get_name ());

                s.is_temporary = true;

                if (valid_album_artist) {
                    s.album_artist = album_artist;
                }

                if (valid_album_name) {
                    s.album = album_name;
                }

                if (valid_album_genre) {
                    s.genre = album_genre;
                }

                string? title = track_info.get_attribute_string (FILE_ATTRIBUTE_TITLE);
                string? artist = track_info.get_attribute_string (FILE_ATTRIBUTE_ARTIST);
                string? genre = track_info.get_attribute_string (FILE_ATTRIBUTE_GENRE);
                uint64 length = track_info.get_attribute_uint64 (FILE_ATTRIBUTE_DURATION); // seconds

                debug ("TRACK #%d\t:", index);
                debug ("  - TRACK_URI:      %s", s.uri);
                debug ("  - TRACK_TITLE:    %s", title);
                debug ("  - TRACK_ARTIST:   %s", artist);
                debug ("  - TRACK_GENRE:    %s", genre);
                debug ("  - TRACK_DURATION: %s secs\n", length.to_string ());

                s.track = index;
                s.length = (uint) (length * TimeUtils.MILI_INV); // no need to check, it's our best guess either way

                if (Media.is_valid_string_field (title))
                    s.title = title;

                if (Media.is_valid_string_field (artist))
                    s.artist = artist;

                if (Media.is_valid_string_field (genre))
                    s.genre = genre;

                // remove artist name from title
                //s.title = remove_artist_from_title (s.title, s.artist);

                // Capitalize nicely
                /*
                s.title = String.to_title_case (s.title);
                s.artist = String.to_title_case (s.artist);
                s.album_artist = String.to_title_case (s.album_artist);
                s.album = String.to_title_case (s.album);
                s.genre = String.to_title_case (s.genre);
                */

                rv.add (s);
                index++;
            }
        } catch (Error err) {
            warning ("Could not enumerate CD tracks or access album info: %s", err.message);
        }

        return rv;
    }

/*
    public static string remove_artist_from_title (string orig, string artist) {
        string new_title = orig;
        int needle_index = orig.down ().index_of (artist.down ());

        if (needle_index != -1) {


            new_title = orig.replace (artist, "");
            s = s.strip();

            if(s.get_char(0) == '-' || s.get_char(s.length - 1) == '-') {
                s = s.replace("-", "");
                s = s.strip();
            }
        }

        return new_title;
    }
*/
}
