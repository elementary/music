// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012-2015 Noise Developers (https://launchpad.net/noise)
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
        DATE_RELEASED,
        GENRE,
        GROUPING,
        LAST_PLAYED,
        LENGTH,
        PLAYCOUNT,
        RATING,
        SKIPCOUNT,
        TITLE,
        YEAR
    }
    
    public int rowid { get; set; default = 0; }
    public FieldType field { get; set; default = FieldType.ALBUM; }
    public ComparatorType comparator { get; set; default = ComparatorType.IS; }
    public string value { get; set; default = ""; } //internally this often holds numbers, but that's ok.
    
    public SmartQuery () {
        
    }
    
    public SmartQuery.with_info (FieldType field, ComparatorType comparator, string value) {
        this.field = field;
        this.comparator = comparator;
        this.value = value;
    }

}
