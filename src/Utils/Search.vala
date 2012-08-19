// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*
 * Copyright (c) 2012 Noise Developers
 *
 * This library is free software; you can redistribute it and/or
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

namespace Noise.Search {

    /**
     * Description:
     * Receives a string and returns a valid search string.
     * This method can be used as a parser as well [TODO].
     */
    public inline string get_valid_search_string (string s) {
        return canonicalize_for_search (s);
    }


    // Taken from gnome-contacts' contacts-utils.vala
    private unichar strip_char (unichar ch) {
        switch (ch.type ()) {
            case UnicodeType.CONTROL:
            case UnicodeType.FORMAT:
            case UnicodeType.UNASSIGNED:
            case UnicodeType.NON_SPACING_MARK:
            case UnicodeType.COMBINING_MARK:
            //case UnicodeType.SPACING_MARK:
            case UnicodeType.ENCLOSING_MARK:
            case UnicodeType.LINE_SEPARATOR:
            case UnicodeType.SPACE_SEPARATOR:
            case UnicodeType.PARAGRAPH_SEPARATOR:
            case UnicodeType.OPEN_PUNCTUATION:
            case UnicodeType.OTHER_PUNCTUATION:
                /* Ignore those */
                return 0;
            default:
                return ch.tolower ();
        }
    }

    // Taken from gnome-contacts' contacts-utils.vala
    private string canonicalize_for_search (string str) {
        unowned string s;
        var buf = new unichar[unichar.MAX_DECOMPOSITION_LENGTH];
        var res = new StringBuilder ();

        for (s = str; s[0] != 0; s = s.next_char ()) {
            var c = strip_char (s.get_char ());

            if (c != 0) {
                var size = c.fully_decompose (false, buf);

                if (size > 0)
                    res.append_unichar (buf[0]);
            }
        }

        return res.str;
    }


    /**
     * Parses a rating from stars. e.g. "***" => 3
     * Returns -1 if @rating_string doesn't represent a valid rating
     */
    private int get_rating_from_string (string rating_string) {
        int i;
        unichar c;

        for (i = 0; rating_string.get_next_char (ref i, out c);) {
            if (c != '*')
                return -1;
        }

        return i;
    }


    /**
     * Non-strict search
     */
    public void smart_search (Gee.Collection<Media> to_search,
                              out Gee.LinkedList<Media> results,
                              string search_str) {
        results = new Gee.LinkedList<Media> ();
        string search = "";
        int parsed_rating = get_rating_from_string (search_str.strip ());

        if (parsed_rating >= 0) {
            parsed_rating = parsed_rating.clamp (0, 5);

            foreach (var m in to_search) {
                if (m.rating == parsed_rating)
                    results.add (m);
            }

            return;
        }

        // If we failed at parsing a rating above, use normal search

        search = get_valid_search_string (search_str);

        foreach (var m in to_search) {
            if (search == m.year.to_string ()) {
                results.add (m);
            } else if (search in get_valid_search_string (m.title)) {
                results.add (m);
            } else if (search in get_valid_search_string (m.album)) {
                results.add (m);
            } else if (search in get_valid_search_string (m.artist)) {
                results.add (m);
            } else if (search in get_valid_search_string (m.album_artist)) {
                results.add (m);
            } else if (search in get_valid_search_string (m.genre)) {
                results.add (m);
            } else if (search in get_valid_search_string (m.composer)) {
                results.add (m);
            } else if (search in get_valid_search_string (m.grouping)) {
                results.add (m);
            } else if (search in get_valid_search_string (m.comment)) {
                results.add (m);
            } else if (search in get_valid_search_string (m.lyrics)) {
                results.add (m);
            }
        }
    }

    /**
     * Search functions
     */

    public inline void search_in_media_list (Gee.Collection<Media> to_search,
                                       out Gee.LinkedList<Media> results,
                                       string search = "", // Search string
                                       string album_artist = "",
                                       string album = "",
                                       string genre = "",
                                       int year = -1, // All years
                                       int rating = -1 // All ratings
                                       )
    {
        results = new Gee.LinkedList<Media> ();

        var l_search = search.down ();

        bool valid_media = false;
        foreach(var media in to_search) {
            valid_media =   media != null &&
                          ( l_search == "" ||
                            l_search in media.title.down() ||
                            l_search in media.album_artist.down() ||
                            l_search in media.artist.down() ||
                            l_search in media.album.down() ||
                            l_search in media.genre.down() ||
                            l_search == media.year.to_string()); // We want full match here

            if (valid_media)
            {
                if (rating == -1 || media.rating == rating)
                {
                    if (year == -1 || media.year == year)
                    {
                        if (genre == "" || media.genre == genre)
                        {
                            if (album_artist == "" || media.album_artist == album_artist)
                            {
                                if (album == "" || media.album == album)
                                {
                                     results.add (media);
                                }
                            }
                        }
                    }
                }
            }
        }
    }


   /**
    * These are optimized for certain kinds of searches
    */

   public inline void fast_album_search_in_media_list (Gee.Collection<Media> to_search,
                                                  out Gee.LinkedList<Media> results,
                                                  string search = "", // Search string
                                                  string album_artist = "",
                                                  string album = ""
                                                  )
    {
        results = new Gee.LinkedList<Media>();

        string l_search = search.down();
        
        bool valid_media = false;
        foreach(var media in to_search) {
            valid_media = media != null &&
                          ( l_search == "" ||
                            l_search in media.title.down() ||
                            l_search in media.album_artist.down() ||
                            l_search in media.artist.down() ||
                            l_search in media.album.down() ||
                            l_search in media.genre.down() ||
                            l_search == media.year.to_string()); // We want full match here

            if (valid_media)
            {
                if (album_artist == "" || media.album_artist == album_artist)
                {
                    if (album == "" || media.album == album)
                    {
                         results.add (media);
                    }
                }
            }
        }
    }


    public inline void full_search_in_media_list (Gee.Collection<Media> to_search,
                            out Gee.LinkedList<Media> ? results,
                            out Gee.LinkedList<Media> ? album_results,
                            out Gee.LinkedList<Media> ? genre_results,
                            out Gee.LinkedList<Media> ? year_results,
                            out Gee.LinkedList<Media> ? rating_results,
                            ViewWrapper.Hint hint,
                            string search = "", // Search string
                            string album_artist = "",
                            string album = "",
                            string genre = "",
                            int year = -1, // All years
                            int rating = -1 // All ratings
                            )
    {
        results = new Gee.LinkedList<Media>();
        album_results = new Gee.LinkedList<Media>();
        genre_results = new Gee.LinkedList<Media>();
        year_results = new Gee.LinkedList<Media>();
        rating_results = new Gee.LinkedList<Media>();

        string l_search = search.down();
        var mediatype = MediaType.SONG;

        bool include_temps = hint == Noise.ViewWrapper.Hint.CDROM ||
                             hint == Noise.ViewWrapper.Hint.DEVICE_AUDIO || 
                             hint == Noise.ViewWrapper.Hint.DEVICE_PODCAST ||
                             hint == Noise.ViewWrapper.Hint.DEVICE_AUDIOBOOK ||
                             hint == Noise.ViewWrapper.Hint.QUEUE ||
                             hint == Noise.ViewWrapper.Hint.HISTORY ||
                             hint == Noise.ViewWrapper.Hint.ALBUM_LIST;

        // FIXME: Use constants for media type and not simply numbers. This has the
        // potential of breaking the search at some point if someone to changes
        // the values of each media type.

        if(hint == Noise.ViewWrapper.Hint.PODCAST || hint == Noise.ViewWrapper.Hint.DEVICE_PODCAST) {
            mediatype = MediaType.PODCAST;
        }
        else if(hint == Noise.ViewWrapper.Hint.AUDIOBOOK || hint == Noise.ViewWrapper.Hint.DEVICE_AUDIOBOOK) {
            mediatype = MediaType.AUDIOBOOK;
        }
        else if(hint == Noise.ViewWrapper.Hint.STATION) {
            mediatype = MediaType.STATION;
        }
        else if(hint == Noise.ViewWrapper.Hint.QUEUE || hint == Noise.ViewWrapper.Hint.HISTORY ||
                 hint == Noise.ViewWrapper.Hint.PLAYLIST || hint == Noise.ViewWrapper.Hint.SMART_PLAYLIST ||
                 hint == Noise.ViewWrapper.Hint.ALBUM_LIST)
        {
            mediatype = MediaType.UNSPECIFIED; // some lists should be able to have ALL media types
        }
        
        foreach (var m in to_search) {
            bool valid_song =   m != null &&
                              ( m.mediatype == mediatype || mediatype == MediaType.UNSPECIFIED ) &&
                              ( !m.isTemporary || include_temps ) &&
                              ( l_search in m.title.down() ||
                                l_search in m.album_artist.down() ||
                                l_search in m.artist.down() ||
                                l_search in m.album.down() ||
                                l_search in m.genre.down() ||
                                l_search == m.year.to_string()); // We want full match here

            if (valid_song)
            {
                if (rating == -1 || (int)m.rating == rating)
                {
                    if (year == -1 || (int)m.year == year)
                    {
                        if (album_artist == "" || m.album_artist == album_artist)
                        {
                            if (genre == "" || m.genre == genre)
                            {
                                if (album == "" || m.album == album)
                                {
                                    results.add (m);
                                }

                                genre_results.add (m);
                            }
                    
                            album_results.add (m);
                        }

                        year_results.add (m);
                    }

                    rating_results.add (m);
                }
            }
        }
    }

}

