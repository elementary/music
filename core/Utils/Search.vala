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
 *
 * Authored by: Victor Eduardo <victoreduardm@gmail.com>
 */

namespace Noise.Search {

    /**
     * Linear exact-string-matching search method.
     *
     * To mean "ALL", pass an empty string (i.e.: "") for string parameters; and
     * -1 for integer parameters.
     *
     * Please note that this method compares against the values returned by
     * Media.get_display_*(), and not the real fields. This means that a value
     * like 'Unknown' will have a matching media even if the actual field is empty.
     *
     *
     * Used by the column browser. Fields compared must match those *displayed* by the browser.
     *
     * /!\ Modify carefully.
     */
    public void search_in_media_list (Gee.Collection<Media> to_search,
                                      out Gee.Collection<Media> results,
                                      string album_artist = "",
                                      string album = "",
                                      string genre = "",
                                      string grouping = "",
                                      string composer = "",
                                      int year = -1,
                                      int rating = -1,
                                      Cancellable? cancellable = null)
    {
        results = new Gee.TreeSet<Media> ();

        foreach (var media in to_search) {
            if (Utils.is_cancelled (cancellable))
                break;

            if (match_fields_to_media (media, album_artist, album, genre, grouping, composer, year, rating))
                results.add (media);
        }
    }

    /**
     * Used by the column browser. Fields compared must match those *displayed* by the browser.
     *
     * /!\ Modify carefully.
     */
    public inline bool match_fields_to_media (Media media,
                                              string album_artist = "",
                                              string album = "",
                                              string genre = "",
                                              string grouping = "",
                                              string composer = "",
                                              int year = -1,
                                              int rating = -1)
    {
        return (rating == -1 || media.rating == rating)
            && (year == -1 || media.year == year)
            && (String.is_empty (genre, false) || media.get_display_genre () == genre)
            && (String.is_empty (album_artist, false) || media.get_display_album_artist () == album_artist)
            && (String.is_empty (album, false) || media.get_display_album () == album)
            && (String.is_empty (grouping, false) || media.grouping == grouping)
            && (String.is_empty (composer, false) || media.get_display_composer () == composer);
    }

    public inline string get_valid_search_string (string s) {
        return String.canonicalize_for_search (s);
    }

    /**
     * Parses a rating from stars. e.g. "***" => 3
     * Returns -1 if rating_string doesn't represent a valid rating.
     *
     * This method ''never'' returns zero. It simply doesn't make sense to
     * return a rating of zero for any given empty string.
     *
     * Samples of valid strings:
     *   "*"
     *   "****"
     * Samples of invalid strings:
     *   ""
     *   "  "
     *   "**a"
     */
    public inline int get_rating_from_string (string rating_string)
        ensures (result != 0 || result == -1)
    {
        int i;
        unichar c;

        for (i = 0; rating_string.get_next_char (ref i, out c);) {
            if (c != '*')
                return -1;
        }

        return i > 0 ? i : -1;
    }

    public inline bool match_string_to_media (Media m, string search) {
        return search == m.year.to_string ()
            || search in get_valid_search_string (m.get_display_title ())
            || search in get_valid_search_string (m.album)
            || search in get_valid_search_string (m.artist)
            || search in get_valid_search_string (m.album_artist)
            || search in get_valid_search_string (m.genre)
            || search in get_valid_search_string (m.composer)
            || search in get_valid_search_string (m.grouping)
            || search in get_valid_search_string (m.comment)
            || search in get_valid_search_string (m.lyrics);
    }
}
