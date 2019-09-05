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
 * Authored by: Victor Eduardo <victoreduardm@gmail.com>
 *              Scott Ringwelski <sgringwe@mtu.edu>
 */

namespace Music.Compare {

    public inline int titles (Media a, Media b) {
        return String.compare (a.get_display_title (), b.get_display_title ());
    }

    public inline int genres (Media a, Media b) {
        int order = String.compare (a.get_display_genre (), b.get_display_genre ());
        if (order == 0)
            order = album_artists (a, b);
        return order;
    }

    public inline int artists (Media a, Media b) {
        int order = String.compare (a.get_display_artist (), b.get_display_artist ());
        // secondarily compare by year
        if (order == 0)
            order = standard_unsigned (a.year, b.year);
        if (order == 0)
            order = albums (a, b);
        return order;
    }

    public inline int album_artists (Media a, Media b) {
        int order = String.compare (a.get_display_album_artist (true), b.get_display_album_artist (true));
        if (order == 0)
            order = albums (a, b);
        return order;
    }

    public inline int albums (Media a, Media b) {
        int order = String.compare (a.get_display_album (), b.get_display_album ());
        if (order == 0)
            order = standard_unsigned (a.album_number, b.album_number);
        if (order == 0)
            order = track_numbers (a, b);
        return order;
    }

    public inline int track_numbers (Media a, Media b) {
        return standard_unsigned (a.track, b.track);
    }

    public inline int standard (int a, int b) {
        return (int) (a > b) - (int) (a < b);
    }

    public inline int standard_unsigned (uint a, uint b) {
        return (int) (a > b) - (int) (a < b);
    }

    public inline int standard_64 (int64 a, int64 b) {
        return (int) (a > b) - (int) (a < b);
    }
}
