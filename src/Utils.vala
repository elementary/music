/*
 * Copyright (c) 2012 Noise Developers
 *
 * This is a free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this program; see the file COPYING.  If not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Victor Eduardo <victoreduardm@gmail.com>
 */

namespace Utils {

    /**
     * Description:
     * Receives a string and returns a valid search string.
     * This method can be used as a parser.
     *
     * Examples:
     *
     * INPUT:           OUTPUT:
     * "     Foo Bar "  "Foo Bar"     --> Removes trailing spaces from beginning and end
     * "             "  ""            --> Converts white space into a void string
     * "Foo   Bar"      "Foo    Bar"  --> Doesn't change middle spaces.
     */
    private string get_valid_search_string (string s) {

        if (s.length < 1)
            return "";

        bool found_valid_char = false;
        int white_space = 0, first_char_position = 0;
        unichar c;

        // WHITESPACE CHECK
        for (int i = 0; s.get_next_char (ref i, out c);) {
            if (c.isspace()) {
                ++ white_space;
            }
            else {
                found_valid_char = true;
                first_char_position = i; // position of the first valid character
                break; // no need to keep looping
            }
        }

        if (white_space == s.length)
            return "";

        if (found_valid_char) {
            var rv = new StringBuilder();

            int last_char_position = 0;
            for (int i = first_char_position - 1; s.get_next_char (ref i, out c);) {
                if (!c.isspace()) {
                    last_char_position = i;
                }
            }

            // Remove trailing spaces. In fact we just don't copy chars outside the
            // [first_valid_char, last_valid_char] interval.
            for (int i = first_char_position - 1; s.get_next_char (ref i, out c) && i <= last_char_position;) {
                    rv.append_unichar (c);
            }

            return rv.str;
        }

        return "";
    }


    /**
     * Search function
     */
    public void search_in_media_list (Collection<BeatBox.Media> to_search,
                                       out LinkedList<BeatBox.Media> ? results,
                                       out LinkedList<BeatBox.Media> ? album_results,
                                       out LinkedList<BeatBox.Media> ? genre_results,
                                       out LinkedList<BeatBox.Media> ? year_results,
                                       out LinkedList<BeatBox.Media> ? rating_results,
                                       BeatBox.ViewWrapper.Hint hint,
                                       string search = "", // Search string
                                       string album_artist = "",
                                       string album = "",
                                       string genre = "",
                                       int year = -1, // All years
                                       int rating = -1 // All ratings
                                       )
    {
        bool include_results = (results != null);
        bool include_album_results = (album_results != null);
        bool include_genre_results = (genre_results != null);
        bool include_year_results = (year_results != null);
        bool include_rating_resulst = (rating_results != null);

        if (include_results)
            results = new LinkedList<BeatBox.Media>();

        if (include_album_results);
            album_results = new LinkedList<BeatBox.Media>();

        if (include_genre_results)
            genre_results = new LinkedList<BeatBox.Media>();

        if (include_year_results)
            year_results = new LinkedList<BeatBox.Media>();

        if (include_rating_results)
            rating_results = new LinkedList<BeatBox.Media>();

        string l_search = search.down();
        int mediatype = 0;

        bool include_temps = hint == ViewWrapper.Hint.CDROM ||
                             hint == ViewWrapper.Hint.DEVICE_AUDIO || 
                             hint == ViewWrapper.Hint.DEVICE_PODCAST ||
                             hint == ViewWrapper.Hint.DEVICE_AUDIOBOOK ||
                             hint == ViewWrapper.Hint.QUEUE ||
                             hint == ViewWrapper.Hint.HISTORY ||
                             hint == ViewWrapper.Hint.ALBUM_LIST;

        if(hint == ViewWrapper.Hint.PODCAST || hint == ViewWrapper.Hint.DEVICE_PODCAST) {
            mediatype = 1;
        }
        else if(hint == ViewWrapper.Hint.AUDIOBOOK || hint == ViewWrapper.Hint.DEVICE_AUDIOBOOK) {
            mediatype = 2;
        }
        else if(hint == ViewWrapper.Hint.STATION) {
            mediatype = 3;
        }
        else if(hint == ViewWrapper.Hint.QUEUE || hint == ViewWrapper.Hint.HISTORY ||
                 hint == ViewWrapper.Hint.PLAYLIST || hint == ViewWrapper.Hint.SMART_PLAYLIST ||
                 hint == ViewWrapper.Hint.ALBUM_LIST)
        {
            mediatype = -1; // some lists should be able to have ALL media types
        }
        
        foreach(var media in to_search) {
            bool valid_song =   media != null &&
                              ( media.mediatype == mediatype || mediatype == -1 ) &&
                              ( !media.isTemporary || include_temps ) &&
                              ( l_search in media.title.down() ||
                                l_search in media.album_artist.down() ||
                                l_search in media.artist.down() ||
                                l_search in media.album.down() ||
                                l_search in media.genre.down() ||
                                l_search == media.year.to_string()); // We want full match here

            if (valid_song)
            {
                if (rating == -1 || media.rating == rating)
                {
                    if (year == -1 || media.year == year)
                    {
                        if (album_artist == "" || media.album_artist == album_artist)
                        {
                            if (genre == "" || media.genre == genre)
                            {
                                if (album == "" || media.album == album)
                                {
                                    if (include_results)
                                        results.add (media);
                                }

                                if (include_genre_results)
                                    genre_results.add (media);
                            }
    
                            if (include_album_results)
                                album_results.add (media);
                        }
                        
                        if (include_year_results)
                            year_results.add (media);
                    }

                    if (include_rating_results)
                        rating_results.add (media);
                }
            }
        }
    }
}

