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

namespace BeatBox.Search {

    /**
     * Description:
     * Receives a string and returns a valid search string.
     * This method can be used as a parser as well [TODO].
     */
    public inline string get_valid_search_string (string s) {
        return s.strip ().down ();
    }


    /**
     * Search functions
     */

    public inline void search_in_media_list (Gee.Collection<BeatBox.Media> to_search,
                                       out Gee.LinkedList<BeatBox.Media> results,
                                       string search = "", // Search string
                                       string album_artist = "",
                                       string album = "",
                                       string genre = "",
                                       int year = -1, // All years
                                       int rating = -1 // All ratings
                                       )
    {
        results = new Gee.LinkedList<BeatBox.Media>();

        string l_search = search.down();
        
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

    public inline void search_in_media_ids (BeatBox.LibraryManager lm,
                                       Gee.Collection<int> to_search_ids,
                                       out Gee.LinkedList<int> results_ids,
                                       string search = "", // Search string
                                       string album_artist = "",
                                       string album = "",
                                       string genre = "",
                                       int year = -1, // All years
                                       int rating = -1 // All ratings
                                       )
    {
        results_ids = new Gee.LinkedList<int>();

        var library_manager = lm;
        if (library_manager == null) {
            critical ("Utils :: search_in_media_ids: Cannot search because LibraryManager is NULL");
            return;
        }

        string l_search = search.down();

        debug ("Searching '%s' in media ids", l_search);
        
        bool valid_media = false;
        foreach(int id in to_search_ids) {
            var media = library_manager.media_from_id (id);
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
                                     results_ids.add (media.rowid);
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

   public inline void fast_album_search_in_media_list (Gee.Collection<BeatBox.Media> to_search,
                                                  out Gee.LinkedList<BeatBox.Media> results,
                                                  string search = "", // Search string
                                                  string album_artist = "",
                                                  string album = ""
                                                  )
    {
        results = new Gee.LinkedList<BeatBox.Media>();

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


    public inline void full_search_in_media_list (Gee.Collection<BeatBox.Media> to_search,
                            out Gee.LinkedList<BeatBox.Media> ? results,
                            out Gee.LinkedList<BeatBox.Media> ? album_results,
                            out Gee.LinkedList<BeatBox.Media> ? genre_results,
                            out Gee.LinkedList<BeatBox.Media> ? year_results,
                            out Gee.LinkedList<BeatBox.Media> ? rating_results,
                            ViewWrapper.Hint hint,
                            string search = "", // Search string
                            string album_artist = "",
                            string album = "",
                            string genre = "",
                            int year = -1, // All years
                            int rating = -1 // All ratings
                            )
    {
        results = new Gee.LinkedList<BeatBox.Media>();
        album_results = new Gee.LinkedList<BeatBox.Media>();
        genre_results = new Gee.LinkedList<BeatBox.Media>();
        year_results = new Gee.LinkedList<BeatBox.Media>();
        rating_results = new Gee.LinkedList<BeatBox.Media>();

        string l_search = search.down();
        int mediatype = 0;

        bool include_temps = hint == BeatBox.ViewWrapper.Hint.CDROM ||
                             hint == BeatBox.ViewWrapper.Hint.DEVICE_AUDIO || 
                             hint == BeatBox.ViewWrapper.Hint.DEVICE_PODCAST ||
                             hint == BeatBox.ViewWrapper.Hint.DEVICE_AUDIOBOOK ||
                             hint == BeatBox.ViewWrapper.Hint.QUEUE ||
                             hint == BeatBox.ViewWrapper.Hint.HISTORY ||
                             hint == BeatBox.ViewWrapper.Hint.ALBUM_LIST;

        // FIXME: Use constants for media type and not simply numbers. This has the
        // potential of breaking the search at some point if someone to changes
        // the values of each media type.

        if(hint == BeatBox.ViewWrapper.Hint.PODCAST || hint == BeatBox.ViewWrapper.Hint.DEVICE_PODCAST) {
            mediatype = 1;
        }
        else if(hint == BeatBox.ViewWrapper.Hint.AUDIOBOOK || hint == BeatBox.ViewWrapper.Hint.DEVICE_AUDIOBOOK) {
            mediatype = 2;
        }
        else if(hint == BeatBox.ViewWrapper.Hint.STATION) {
            mediatype = 3;
        }
        else if(hint == BeatBox.ViewWrapper.Hint.QUEUE || hint == BeatBox.ViewWrapper.Hint.HISTORY ||
                 hint == BeatBox.ViewWrapper.Hint.PLAYLIST || hint == BeatBox.ViewWrapper.Hint.SMART_PLAYLIST ||
                 hint == BeatBox.ViewWrapper.Hint.ALBUM_LIST)
        {
            mediatype = -1; // some lists should be able to have ALL media types
        }
        
        foreach (var m in to_search) {
            bool valid_song =   m != null &&
                              ( m.mediatype == mediatype || mediatype == -1 ) &&
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

