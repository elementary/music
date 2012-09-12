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
	
	public SmartQuery() {
	}
	
	public SmartQuery.with_info(FieldType field, ComparatorType comparator, string value) {
		this.field = field;
		this.comparator = comparator;
		this.value = value;
	}

}
