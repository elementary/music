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
 * The Noise authors hereby grant permission for non-GPL compatible
 * GStreamer plugins to be used and distributed together with GStreamer
 * and Noise. This permission is above and beyond the permissions granted
 * by the GPL license by which Noise is covered. If you modify this code
 * you may extend this exception to your version of the code, but you are not
 * obligated to do so. If you do not wish to do so, delete this exception
 * statement from your version.
 *
 * Authored by: Scott Ringwelski <sgringwe@mtu.edu>
 *              Corentin Noël <corentin@elementary.io>
 */

public class Noise.SmartQuery : Object {
    public enum ComparatorType {
        IS,
        IS_NOT,
        CONTAINS,
        NOT_CONTAINS,
        IS_EXACTLY,
        IS_AT_MOST,
        IS_AT_LEAST,
        IS_WITHIN,
        IS_BEFORE
    }

    public enum FieldType {
        ALBUM,
        ARTIST,
        BITRATE,
        COMMENT,
        COMPOSER,
        DATE_ADDED,
        GENRE,
        GROUPING,
        LAST_PLAYED,
        LENGTH,
        PLAYCOUNT,
        RATING,
        SKIPCOUNT,
        TITLE,
        YEAR,
        URI
    }

    public int rowid { get; set; default = 0; }
    public FieldType field { get; set; default = FieldType.ALBUM; }
    public ComparatorType comparator { get; set; default = ComparatorType.IS; }
    public GLib.Value value { get; set; default = GLib.Value (typeof (int)); }

    public SmartQuery () {

    }

    public SmartQuery.with_info (FieldType field, ComparatorType comparator, GLib.Value value) {
        this.field = field;
        this.comparator = comparator;
        this.value = value;
    }

}
