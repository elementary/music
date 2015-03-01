// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012 Noise Developers (http://launchpad.net/noise)
 *
 * This software is licensed under the GNU General Public License
 * (version 2 or later). See the COPYING file in this distribution.
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
 */
public enum Noise.ListColumn {
    ICON = 0,
    NUMBER,
    TRACK,
    TITLE,
    LENGTH,
    ARTIST,
    ALBUM,
    ALBUM_ARTIST,
    COMPOSER,
    GENRE,
    YEAR,
    GROUPING,
    BITRATE,
    RATING,
    PLAY_COUNT,
    SKIP_COUNT,
    DATE_ADDED,
    LAST_PLAYED,
    BPM,
    FILE_LOCATION,
    FILE_SIZE,
    N_COLUMNS;

    /**
     * Returns a string representation of the column.
     */
    public string to_string () {
        switch (this) {
            case ICON:
                return " ";

            case NUMBER:
                return C_("List column title", "#");

            case TRACK:
                return C_("List column title", "Track");

            case TITLE:
                return C_("List column title", "Title");

            case LENGTH:
                return C_("List column title", "Length");

            case ARTIST:
                return C_("List column title", "Artist");

            case ALBUM:
                return C_("List column title", "Album");

            case ALBUM_ARTIST:
                return C_("List column title", "Album Artist");

            case COMPOSER:
                return C_("List column title", "Composer");

            case GENRE:
                return C_("List column title", "Genre");

            case YEAR:
                return C_("List column title", "Year");

            case GROUPING:
                return C_("List column title", "Grouping");

            case BITRATE:
                return C_("List column title", "Bitrate");

            case RATING:
                return C_("List column title", "Rating");

            case PLAY_COUNT:
                return C_("List column title", "Plays");

            case SKIP_COUNT:
                return C_("List column title", "Skips");

            case DATE_ADDED:
                return C_("List column title", "Date Added");

            case LAST_PLAYED:
                return C_("List column title", "Last Played");

            case BPM:
                return C_("List column title (beats per minute)", "BPM");

            case FILE_LOCATION:
                return C_("List column title (file location)", "Location");

            case FILE_SIZE:
                return C_("List column title", "File Size");

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
            case ALBUM_ARTIST:
            case COMPOSER:
            case GENRE:
            case GROUPING:
            case FILE_LOCATION:
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

            case FILE_SIZE:
                return typeof (uint64);

            default:
                assert_not_reached ();
        }
    }

    /**
     * Returns the value of the data that should be displayed by the column in the view.
     *
     * media_row_index is only necessary for {@link ListColumn.NUMBER}.
     */
    public Value? get_value_for_media (Media m, int media_row_index = -1) {
        switch (this) {
            case ICON:
                GLib.Icon? icon;
                var currently_playing = App.player.current_media;

                if (m == currently_playing && currently_playing != null)
                    icon = Icons.NOW_PLAYING_SYMBOLIC.gicon;
                else
                    icon = m.unique_status_image;

                return icon;

            case NUMBER:
                assert (media_row_index >= 0);
                return (uint) media_row_index + 1;

            case TRACK:
                return m.track;

            case TITLE:
                return m.get_display_title ();

            case LENGTH:
                return m.length;

            case ARTIST:
                return m.get_display_artist ();

            case ALBUM:
                return m.get_display_album ();

            case ALBUM_ARTIST:
                return m.get_display_album_artist (false);

            case COMPOSER:
                return m.get_display_composer ();

            case GENRE:
                return m.get_display_genre ();

            case YEAR:
                return m.year;

            case GROUPING:
                return m.grouping;

            case BITRATE:
                return m.bitrate;

            case RATING:
                return m.rating;

            case PLAY_COUNT:
                return m.play_count;

            case SKIP_COUNT:
                return m.skip_count;

            case DATE_ADDED:
                return m.date_added;

            case LAST_PLAYED:
                return m.last_played;

            case BPM:
                return m.bpm;

            case FILE_LOCATION:
                return m.get_display_location ();

            case FILE_SIZE:
                return m.file_size;
        }

        assert_not_reached ();
    }

    public static Gee.Collection<ListColumn> get_all () {
        var list = new Gee.LinkedList<ListColumn> ();
        for (int i = 0; i < N_COLUMNS; i++)
            list.add ((ListColumn) i);
        return list;
    }
}
