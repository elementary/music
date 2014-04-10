// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012-2013 Noise Developers (http://launchpad.net/noise)
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
 *              Scott Ringwelski <sgringwe@mtu.edu>
 */

public class Noise.CompareFuncHolder {
    public unowned Gtk.TreeIterCompareFunc sort_func;

    public CompareFuncHolder (Gtk.TreeIterCompareFunc func) {
        sort_func = func;
    }
}

namespace Noise.Compare {
    
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
            order = Numeric.compare(a.year, b.year);
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
            order = Numeric.compare (a.album_number, b.album_number);
        if (order == 0)
            order = track_numbers (a, b);
        return order;
    }

    public inline int track_numbers (Media a, Media b) {
        return Numeric.compare (a.track, b.track);
    }


}
