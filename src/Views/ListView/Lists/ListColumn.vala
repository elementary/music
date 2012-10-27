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

/**
 * Represents every possible column that can go in a media list.
 *
 * New column types must be appended at the end in order to ensure backwards
 * compatibility with older TreeViewSetup representations.
 *
 * TODO: Add columns:
 * + FILE LOCATION
 * + ALBUM ARTIST (It won't display Artist as fallback)
 * + COMPOSER
 * + GROUPING
 * + FILE SIZE
 */
public enum Noise.ListColumn {
    ICON,
    NUMBER,
    TRACK,
    TITLE,
    LENGTH,
    ARTIST,
    ALBUM,
    GENRE,
    YEAR,
    BITRATE,
    RATING,
    PLAY_COUNT,
    SKIP_COUNT,
    DATE_ADDED,
    LAST_PLAYED,
    BPM,
    N_COLUMNS;

    /**
     * Returns a string representation of the column.
     */
    public string to_string () {
        switch (this) {
            case ICON:
                return " ";

            case NUMBER:
                return C_("Column title (list view)", "#");

            case TRACK:
                return C_("Column title (list view)", "Track");

            case TITLE:
                return C_("Column title (list view)", "Title");

            case LENGTH:
                return C_("Column title (list view)", "Length");

            case ARTIST:
                return C_("Column title (list view)", "Artist");

            case ALBUM:
                return C_("Column title (list view)", "Album");

            case GENRE:
                return C_("Column title (list view)", "Genre");

            case YEAR:
                return C_("Column title (list view)", "Year");

            case BITRATE:
                return C_("Column title (list view)", "Bitrate");

            case RATING:
                return C_("Column title (list view)", "Rating");

            case PLAY_COUNT:
                return C_("Column title (list view)", "Plays");

            case SKIP_COUNT:
                return C_("Column title (list view)", "Skips");

            case DATE_ADDED:
                return C_("Column title (list view)", "Date Added");

            case LAST_PLAYED:
                return C_("Column title (list view)", "Last Played");

            case BPM:
                return C_("Column title (list view)", "BPM");

            default:
                assert_not_reached ();
        }
    }

    public Type get_data_type () {
        // Order is broken here to organize columns by common type. Types should
        // match the type of the media field, so that conversions are not needed
        // in the value function or cell-data functions.
        switch (this) {
            case ICON:
                return typeof (GLib.Icon);

            case TITLE:
            case ARTIST:
            case ALBUM:
            case GENRE:
                return typeof (string);

            case NUMBER:
            case TRACK:
            case LENGTH:
            case YEAR:
            case BITRATE:
            case RATING:
            case PLAY_COUNT:
            case SKIP_COUNT:
            case DATE_ADDED:
            case LAST_PLAYED:
            case BPM:
                return typeof (uint);

            default:
                assert_not_reached ();
        }
    }

    public static List<ListColumn> get_all () {
        var list = new List<ListColumn> ();
        for (int i = 0; i < N_COLUMNS; i++)
            list.append ((ListColumn) i);
        return list;
    }
}
