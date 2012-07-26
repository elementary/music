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
	
	public void set_rule_properties(GPod.SPLRule rule) {
		message("adding rule\n");
		if(field == FieldType.ALBUM) { // strings
			rule.field = GPod.SPLField.ALBUM;
			rule.@string = value;
		}
		else if(field == FieldType.ARTIST) {
			rule.field = GPod.SPLField.ARTIST;
			rule.@string = value;
		}
		else if(field == FieldType.COMPOSER) {
			rule.field = GPod.SPLField.COMPOSER;
			rule.@string = value;
		}
		else if(field == FieldType.COMMENT) {
			rule.field = GPod.SPLField.COMMENT;
			rule.@string = value;
		}
		else if(field == FieldType.GENRE) {
			rule.field = GPod.SPLField.GENRE;
			rule.@string = value;
		}
		else if(field == FieldType.GROUPING) {
			rule.field = GPod.SPLField.GROUPING;
			rule.@string = value;
		}
		else if(field == FieldType.TITLE) {
			rule.field = GPod.SPLField.SONG_NAME;
			rule.@string = value;
		}
		else if(field == FieldType.BITRATE) { // ints
			rule.field = GPod.SPLField.BITRATE;
			rule.fromvalue = uint64.parse(value);
			rule.tovalue = uint64.parse(value);
		}
		else if(field == FieldType.PLAYCOUNT) {
			rule.field = GPod.SPLField.PLAYCOUNT;
			rule.fromvalue = uint64.parse(value);
			rule.tovalue = uint64.parse(value);
		}
		else if(field == FieldType.SKIPCOUNT) {
			rule.field = GPod.SPLField.SKIPCOUNT;
			rule.fromvalue = uint64.parse(value);
			rule.tovalue = uint64.parse(value);
		}
		else if(field == FieldType.YEAR) {
			rule.field = GPod.SPLField.YEAR;
			rule.fromvalue = uint64.parse(value);
			rule.tovalue = uint64.parse(value);
		}
		else if(field == FieldType.LENGTH) {
			rule.field = GPod.SPLField.TIME;
			rule.fromvalue = uint64.parse(value) * 1000;
			rule.tovalue = uint64.parse(value) * 1000;
		}
		else if(field == FieldType.RATING) {
			rule.field = GPod.SPLField.RATING;
			rule.fromvalue = uint64.parse(value) * 20;
			rule.tovalue = uint64.parse(value) * 20;
		}
		else if(field == FieldType.DATE_ADDED) {
			rule.field = GPod.SPLField.DATE_ADDED;
			rule.fromvalue = uint64.parse(value) * 1000;
			rule.tovalue = uint64.parse(value) * 1000;
		}
		else if(field == FieldType.LAST_PLAYED) {
			rule.field = GPod.SPLField.LAST_PLAYED;
			rule.fromvalue = uint64.parse(value) * 20;
			rule.tovalue = uint64.parse(value) * 20;
		}
		else if(field == FieldType.DATE_RELEASED) {
			// no equivalant
		}
		else if(field == FieldType.MEDIA_TYPE) {
			rule.field = GPod.SPLField.VIDEO_KIND;
			if(value == "0") {
				rule.fromvalue = (uint64)GPod.MediaType.AUDIO;
				rule.tovalue = (uint64)GPod.MediaType.AUDIO;
			}
			else if(value == "1") {
				rule.fromvalue = (uint64)GPod.MediaType.PODCAST;
				rule.tovalue = (uint64)GPod.MediaType.PODCAST;
			}
			else if(value == "2") {
				rule.fromvalue = (uint64)GPod.MediaType.AUDIOBOOK;
				rule.tovalue = (uint64)GPod.MediaType.AUDIOBOOK;
			}
		}
		
		rule.tounits = 1;
		
		// set action type
		if(comparator == ComparatorType.IS) {
			rule.action = GPod.SPLAction.IS_STRING;
		}
		else if(comparator == ComparatorType.IS_NOT) {
			rule.action = GPod.SPLAction.IS_NOT_INT;
		}
		else if(comparator == ComparatorType.CONTAINS) {
			rule.action = GPod.SPLAction.CONTAINS;
		}
		else if(comparator == ComparatorType.NOT_CONTAINS) {
			rule.action = GPod.SPLAction.DOES_NOT_CONTAIN;
		}
		else if(comparator == ComparatorType.IS_EXACTLY) {
			rule.action = GPod.SPLAction.IS_INT;
		}
		else if(comparator == ComparatorType.IS_AT_MOST) {
			rule.action = GPod.SPLAction.IS_NOT_GREATER_THAN;
		}
		else if(comparator == ComparatorType.IS_AT_LEAST) {
			rule.action = GPod.SPLAction.IS_NOT_LESS_THAN;
		}
		else if(comparator == ComparatorType.IS_WITHIN) {
			rule.action = GPod.SPLAction.IS_GREATER_THAN;
		}
		else if(comparator == ComparatorType.IS_BEFORE) {
			rule.action = GPod.SPLAction.IS_LESS_THAN;
		}
	}
}
