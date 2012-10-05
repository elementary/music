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
     * Non-strict search.
     */
    public void smart_search (Gee.Collection<Media> to_search,
                              out Gee.LinkedList<Media> results,
                              string search_str,
                              Cancellable? cancellable = null)
    {
        results = new Gee.LinkedList<Media> ();
        int parsed_rating = get_rating_from_string (search_str.strip ());

        if (parsed_rating > 0) {
            parsed_rating = parsed_rating.clamp (0, 5);

            foreach (var m in to_search) {
                if (Utils.is_cancelled (cancellable))
                    break;

                if (m.rating == parsed_rating)
                    results.add (m);
            }

            return;
        }

        // If we failed at parsing a rating above, use normal search
        string search = get_valid_search_string (search_str, cancellable);

        if (String.is_white_space (search)) {
            foreach (var m in to_search) {
                if (Utils.is_cancelled (cancellable))
                    break;
                results.add (m);
            }
        } else {
            foreach (var m in to_search) {
                if (Utils.is_cancelled (cancellable))
                    break;

                if (match_string_to_media (m, search, cancellable))
                    results.add (m);
            }
        }
    }

    /**
     * Linear exact-string-matching search method.
     *
     * To mean "ALL", pass an empty string (i.e.: "") for string parameters; and
     * -1 for integer parameters.
     */
    public void search_in_media_list (Gee.Collection<Media> to_search,
                                       out Gee.LinkedList<Media> results,
                                       string album_artist = "",
                                       string album = "",
                                       string genre = "",
                                       int year = -1,
                                       int rating = -1,
                                       Cancellable? cancellable = null)
    {
        results = new Gee.LinkedList<Media> ();

        foreach (var media in to_search) {
            if (Utils.is_cancelled (cancellable))
                break;

            bool match = (rating == -1 || media.rating == rating)
                      && (year == -1 || media.year == year)
                      && (genre == "" || media.genre == genre)
                      && (album_artist == "" || media.album_artist == album_artist)
                      && (album == "" || media.album == album);

            if (match)
                results.add (media);
        }
    }

    private inline string get_valid_search_string (string s, Cancellable? cancellable = null) {
        return String.canonicalize_for_search (s, cancellable);
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
    private inline int get_rating_from_string (string rating_string)
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

    private inline bool match_string_to_media (Media m, string search,
                                               Cancellable? cancellable)
    {
        bool match = false;

        if (search == m.year.to_string ())
            match = true;
        else if (search in get_valid_search_string (m.title, cancellable))
            match = true;
        else if (search in get_valid_search_string (m.album, cancellable))
            match = true;
        else if (search in get_valid_search_string (m.artist, cancellable))
            match = true;
        else if (search in get_valid_search_string (m.album_artist, cancellable))
            match = true;
        else if (search in get_valid_search_string (m.genre, cancellable))
            match = true;
        else if (search in get_valid_search_string (m.composer, cancellable))
            match = true;
        else if (search in get_valid_search_string (m.grouping, cancellable))
            match = true;
        else if (search in get_valid_search_string (m.comment, cancellable))
            match = true;
        else if (search in get_valid_search_string (m.lyrics, cancellable))
            match = true;

        return match;
    }
}
