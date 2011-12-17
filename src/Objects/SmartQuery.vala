/*-
 * Copyright (c) 2011       Scott Ringwelski <sgringwe@mtu.edu>
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

public class BeatBox.SmartQuery : Object {
	// form a sql query as so:
	// WHERE `_field` _comparator _search
	private int _rowid;
	private string _field; 
	private string _comparator;
	private string _value; //internally this often holds numbers, but that's ok.
	
	public SmartQuery() {
		_field = "album";
		_comparator = "=";
		_value = "";
	}
	
	public SmartQuery.with_info(string field, string comparator, string value) {
		_field = field;
		_comparator = comparator;
		_value = value;
	}
	
	public int rowid {
		get { return _rowid; }
		set { _rowid = value; }
	}
	
	public string field {
		get { return _field; }
		set { _field = value; } // i should check this
	}
	
	public string comparator {
		get { return _comparator; }
		set { _comparator = value; } // i should check this
	}
	
	public string value {
		get { return _value; }
		set { _value = value; }
	}
	
	public void set_rule_properties(GPod.SPLRule rule) {
		stdout.printf("adding rule\n");
		if(field == "Album") { // strings
			rule.field = GPod.SPLField.ALBUM;
			rule.@string = value;
		}
		else if(field == "Artist") {
			rule.field = GPod.SPLField.ARTIST;
			rule.@string = value;
		}
		else if(field == "Composer") {
			rule.field = GPod.SPLField.COMPOSER;
			rule.@string = value;
		}
		else if(field == "Comment") {
			rule.field = GPod.SPLField.COMMENT;
			rule.@string = value;
		}
		else if(field == "Genre") {
			rule.field = GPod.SPLField.GENRE;
			rule.@string = value;
		}
		else if(field == "Grouping") {
			rule.field = GPod.SPLField.GROUPING;
			rule.@string = value;
		}
		else if(field == "Title") {
			rule.field = GPod.SPLField.SONG_NAME;
			rule.@string = value;
		}
		else if(field == "Bitrate") { // ints
			rule.field = GPod.SPLField.BITRATE;
			rule.fromvalue = uint64.parse(value);
			rule.tovalue = uint64.parse(value);
		}
		else if(field == "Playcount") {
			rule.field = GPod.SPLField.PLAYCOUNT;
			rule.fromvalue = uint64.parse(value);
			rule.tovalue = uint64.parse(value);
		}
		else if(field == "Skipcount") {
			rule.field = GPod.SPLField.SKIPCOUNT;
			rule.fromvalue = uint64.parse(value);
			rule.tovalue = uint64.parse(value);
		}
		else if(field == "Year") {
			rule.field = GPod.SPLField.YEAR;
			rule.fromvalue = uint64.parse(value);
			rule.tovalue = uint64.parse(value);
		}
		else if(field == "Length") {
			rule.field = GPod.SPLField.TIME;
			rule.fromvalue = uint64.parse(value) * 1000;
			rule.tovalue = uint64.parse(value) * 1000;
		}
		else if(field == "Rating") {
			rule.field = GPod.SPLField.RATING;
			rule.fromvalue = uint64.parse(value) * 20;
			rule.tovalue = uint64.parse(value) * 20;
		}
		else if(field == "Date Added") {
			rule.field = GPod.SPLField.DATE_ADDED;
			rule.fromvalue = uint64.parse(value) * 1000;
			rule.tovalue = uint64.parse(value) * 1000;
		}
		else if(field == "Last Played") {
			rule.field = GPod.SPLField.LAST_PLAYED;
			rule.fromvalue = uint64.parse(value) * 20;
			rule.tovalue = uint64.parse(value) * 20;
		}
		else if(field == "Date Released") {
			// no equivelant
		}
		else if(field == "Media Type") {
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
		if(comparator == "is") {
			rule.action = GPod.SPLAction.IS_STRING;
		}
		else if(comparator == "is not") {
			rule.action = GPod.SPLAction.IS_NOT_INT;
		}
		else if(comparator == "contains") {
			rule.action = GPod.SPLAction.CONTAINS;
		}
		else if(comparator == "does not contain") {
			rule.action = GPod.SPLAction.DOES_NOT_CONTAIN;
		}
		else if(comparator == "is exactly") {
			rule.action = GPod.SPLAction.IS_INT;
		}
		else if(comparator == "is at most") {
			rule.action = GPod.SPLAction.IS_NOT_GREATER_THAN;
		}
		else if(comparator == "is at least") {
			rule.action = GPod.SPLAction.IS_NOT_LESS_THAN;
		}
		else if(comparator == "is within") {
			rule.action = GPod.SPLAction.IS_GREATER_THAN;
		}
		else if(comparator == "is before") {
			rule.action = GPod.SPLAction.IS_LESS_THAN;
		}
	}
}
