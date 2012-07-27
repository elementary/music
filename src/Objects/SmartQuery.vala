/*-
 * Copyright (c) 2011-2012       Scott Ringwelski <sgringwe@mtu.edu>
 *
 * Originally Written by Scott Ringwelski for BeatBox Music Player
 * BeatBox Music Player: http://www.launchpad.net/beat-box
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
 */

public class Noise.SmartQuery : Object {
	// form a sql query as so:
	// WHERE `_field` _comparator _search
	
	public enum ComparatorType {
		IS = 0,
		IS_NOT = 1,
		CONTAINS = 2,
		NOT_CONTAINS = 3,
		IS_EXACTLY = 4,
		IS_AT_MOST = 5,
		IS_AT_LEAST = 6,
		IS_WITHIN = 7,
		IS_BEFORE = 8
	}
	
	public enum FieldType {
		ALBUM = 0,
		ARTIST = 1,
		BITRATE = 2,
		COMMENT = 3,
		COMPOSER = 4,
		DATE_ADDED = 5,
		DATE_RELEASED = 6,
		GENRE = 7,
		GROUPING = 8,
		LAST_PLAYED = 9,
		LENGTH = 10,
		MEDIA_TYPE = 11,
		PLAYCOUNT = 12,
		RATING = 13,
		SKIPCOUNT = 14,
		TITLE = 15,
		YEAR = 16
	}
	
	public int rowid { get; set; default = 0; }
	public FieldType field { get; set; default = FieldType.ALBUM; }
	public ComparatorType comparator { get; set; default = ComparatorType.IS; }
	public string value { get; set; default = ""; } //internally this often holds numbers, but that's ok.
	
	public SmartQuery() {
	}
	
	public SmartQuery.with_info(FieldType field, ComparatorType comparator, string value) {
		this.field = field;
		this.comparator = comparator;
		this.value = value;
	}

}
