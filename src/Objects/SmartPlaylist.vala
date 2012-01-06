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

using Gee;

public class BeatBox.SmartPlaylist : Object {
	private int _rowid;
	public TreeViewSetup tvs;
	private string _name;
	private string _conditional; //any or all
	private Gee.ArrayList<SmartQuery> _queries;
	public int query_count;
	
	private bool _limit;
	private int _limit_amount;
	
	private bool _is_up_to_date;
	public bool viewWrapper_is_up_to_date;
	LinkedList<int> medias;
	
	public SmartPlaylist() {
		_name = "";
		tvs = new TreeViewSetup("#", Gtk.SortType.ASCENDING, ViewWrapper.Hint.SMART_PLAYLIST);
		_conditional = "all";
		query_count = 0;
		_queries = new Gee.ArrayList<SmartQuery>();
		_limit = false;
		_limit_amount = 50;
		viewWrapper_is_up_to_date = false;
		is_up_to_date = false;
	}
	
	public bool is_up_to_date {
		get { return _is_up_to_date; }
		set { 
			_is_up_to_date = value;
			
			if(!value)
				viewWrapper_is_up_to_date = value; 
		}
	}
	
	public int rowid {
		get { return _rowid; }
		set { _rowid = value; }
	}
	
	public string name {
		get { return _name; }
		set { _name = value; }
	}
	
	public string conditional {
		get { return _conditional; }
		set {
			if(value == "all" || value == "any")
				_conditional = value;
			else
				stderr.printf("Invalid conditional for smart playlist. Must be \"all\" or \"any\". Supplied: %s \n", value);
		}
	}
	
	public bool limit {
		get { return _limit; }
		set { _limit = value; }
	}
	
	public int limit_amount {
		get { return _limit_amount; }
		set { _limit_amount = value; }
	}
	
	public void clearQueries() {
		query_count = 0;
		_queries.clear();
	}
	
	public Gee.ArrayList<SmartQuery> queries() {
		return _queries;
	}
	
	public void addQuery(SmartQuery s) {
		query_count++;
		_queries.add(s);
	}
	
	/** temp_playlist should be in format of #,#,#,#,#, **/
	public void queries_from_string(string q) {
		string[] queries_in_string = q.split("<query_seperator>", 0);
		
		int index;
		for(index = 0; index < queries_in_string.length - 1; index++) {
			string[] pieces_of_query = queries_in_string[index].split("<value_seperator>", 0);
			
			SmartQuery sq = new SmartQuery();
			sq.field = pieces_of_query[0];
			sq.comparator = pieces_of_query[1];
			sq.value = pieces_of_query[2];
			
			addQuery(sq);
		}
	}
	
	public string queries_to_string() {
		string rv = "";
		
		foreach(SmartQuery q in queries()) {
			rv += q.field + "<value_seperator>" + q.comparator + "<value_seperator>" + q.value + "<query_seperator>";
		}
		
		return rv;
	}
	
	public LinkedList<int> analyze(LibraryManager lm) {
		//if(is_up_to_date) {
		//	return medias;
		//}
		
		LinkedList<int> rv = new LinkedList<int>();
		foreach(Media s in lm.media()) {
			int match_count = 0; //if OR must be greather than 0. if AND must = queries.size.
			
			foreach(SmartQuery q in _queries) {
				if(media_matches_query(q, s))
					match_count++;
			}
			
			if(((conditional == "all" && match_count == _queries.size) || (conditional == "any" && match_count >= 1)) && !s.isTemporary)
				rv.add(s.rowid);
				
			if(_limit && _limit_amount <= rv.size)
				return rv;
		}
		
		is_up_to_date = true;
		medias = rv;
		
		return rv;
	}
	
	public bool media_matches_query(SmartQuery q, Media s) {
		if(q.field == "Album") { //strings
			if(q.comparator == "is")
				return q.value.down() == s.album.down();
			else if(q.comparator == "contains")
				return (q.value.down() in s.album.down());
			else if(q.comparator == "does not contain")
				return !(q.value.down() in s.album.down());
		}
		else if(q.field == "Artist") {
			if(q.comparator == "is")
				return q.value.down() == s.artist.down();
			else if(q.comparator == "contains")
				return (q.value.down() in s.artist.down());
			else if(q.comparator == "does not contain")
				return !(q.value.down() in s.artist.down());
		}
		else if(q.field == "Composer") {
			if(q.comparator == "is")
				return q.value.down() == s.composer.down();
			else if(q.comparator == "contains")
				return (q.value.down() in s.composer.down());
			else if(q.comparator == "does not contain")
				return !(q.value.down() in s.composer.down());
		}
		else if(q.field == "Comment") {
			if(q.comparator == "is")
				return q.value.down() == s.comment.down();
			else if(q.comparator == "contains")
				return (q.value.down() in s.comment.down());
			else if(q.comparator == "does not contain")
				return !(q.value.down() in s.comment.down());
		}
		else if(q.field == "Genre") {
			if(q.comparator == "is")
				return q.value.down() == s.genre.down();
			else if(q.comparator == "contains")
				return (q.value.down() in s.genre.down());
			else if(q.comparator == "does not contain")
				return !(q.value.down() in s.genre.down());
		}
		else if(q.field == "Grouping") {
			if(q.comparator == "is")
				return q.value.down() == s.grouping.down();
			else if(q.comparator == "contains")
				return (q.value.down() in s.grouping.down());
			else if(q.comparator == "does not contain")
				return !(q.value.down() in s.grouping.down());
		}
		else if(q.field == "Title") {
			if(q.comparator == "is")
				return q.value.down() == s.title.down();
			else if(q.comparator == "contains")
				return (q.value.down() in s.title.down());
			else if(q.comparator == "does not contain")
				return !(q.value.down() in s.title.down());
		}
		else if(q.field == "Bitrate") {//numbers
			if(q.comparator == "is exactly")
				return int.parse(q.value) == s.bitrate;
			else if(q.comparator == "is at most")
				return (s.bitrate <= int.parse(q.value));
			else if(q.comparator == "is at least")
				return (s.bitrate >= int.parse(q.value));
		}
		else if(q.field == "Playcount") {
			if(q.comparator == "is exactly")
				return int.parse(q.value) == s.play_count;
			else if(q.comparator == "is at most")
				return (s.play_count <= int.parse(q.value));
			else if(q.comparator == "is at least")
				return (s.play_count >= int.parse(q.value));
		}
		else if(q.field == "Skipcount") {
			if(q.comparator == "is exactly")
				return int.parse(q.value) == s.skip_count;
			else if(q.comparator == "is at most")
				return (s.skip_count <= int.parse(q.value));
			else if(q.comparator == "is at least")
				return (s.skip_count >= int.parse(q.value));
		}
		else if(q.field == "Year") {
			if(q.comparator == "is exactly")
				return int.parse(q.value) == s.year;
			else if(q.comparator == "is at most")
				return (s.year <= int.parse(q.value));
			else if(q.comparator == "is at least")
				return (s.year >= int.parse(q.value));
		}
		else if(q.field == "Length") {
			if(q.comparator == "is exactly")
				return int.parse(q.value) == s.length;
			else if(q.comparator == "is at most")
				return (s.length <= int.parse(q.value));
			else if(q.comparator == "is at least")
				return (s.length >= int.parse(q.value));
		}
		else if(q.field == "Rating") {
			if(q.comparator == "is exactly")
				return int.parse(q.value) == s.rating;
			else if(q.comparator == "is at most")
				return (s.rating <= int.parse(q.value));
			else if(q.comparator == "is at least")
				return (s.rating >= int.parse(q.value));
		}
		else if(q.field == "Date Added") {//time
			var now = new DateTime.now_local();
			var played = new DateTime.from_unix_local(s.date_added);
			played = played.add_days(int.parse(q.value));
			
			if(q.comparator == "is exactly")
				return (now.get_day_of_year() == played.get_day_of_year() && now.get_year() == played.get_year());
			else if(q.comparator == "is within") {
				return played.compare(now) > 0;
			}
			else if(q.comparator == "is before") {
				return now.compare(played) > 0;
			}
		}
		else if(q.field == "Date Released") {//time
			var now = new DateTime.now_local();
			var released = new DateTime.from_unix_local(s.podcast_date);
			released = released.add_days(int.parse(q.value));
			
			if(q.comparator == "is exactly")
				return (now.get_day_of_year() == released.get_day_of_year() && now.get_year() == released.get_year());
			else if(q.comparator == "is within") {
				return released.compare(now) > 0;
			}
			else if(q.comparator == "is before") {
				return now.compare(released) > 0;
			}
		}
		else if(q.field == "Last Played") {
			if(s.last_played == 0)
				return false;
			
			var now = new DateTime.now_local();
			var played = new DateTime.from_unix_local(s.last_played);
			played = played.add_days(int.parse(q.value));
			
			if(q.comparator == "is exactly")
				return (now.get_day_of_year() == played.get_day_of_year() && now.get_year() == played.get_year());
			else if(q.comparator == "is within") {
				return played.compare(now) > 0;
			}
			else if(q.comparator == "is before") {
				return now.compare(played) > 0;
			}
		}
		else if(q.field == "Media Type") {
			if(q.comparator == "is")
				return s.mediatype == int.parse(q.value);
			else if(q.comparator == "is not")
				return s.mediatype != int.parse(q.value);
		}
		
		return false;
	}
	
	public GPod.Playlist get_gpod_playlist() {
		GPod.Playlist rv = new GPod.Playlist(name, false);
		
		return rv;
	}
	
	public void set_playlist_properties(GPod.Playlist rv) {
		stdout.printf("playlist is %s\n", name);
		
		foreach(var sq in _queries) {
			rv.splr_add_new(-1);
			
			unowned GPod.SPLRule? rule = rv.splrules.rules.nth_data(rv.splrules.rules.length() - 1);
			
			stdout.printf("adding rule\n");
			var field = sq.field;
			var value = sq.value;
			var comparator = sq.comparator;
			if(field == "Album") { // strings
				rule.field = GPod.SPLField.ALBUM;
				rule.@string = value;
			}
			else if(field == "Artist") {
				rule.field = GPod.SPLField.ARTIST;
				rule.@string = value;
				stdout.printf("hi at artist\n");
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
				rule.tounits = 1;
				rule.fromunits = 1;
			}
			else if(field == "Playcount") {
				rule.field = GPod.SPLField.PLAYCOUNT;
				rule.fromvalue = uint64.parse(value);
				rule.tovalue = uint64.parse(value);
				rule.tounits = 1;
				rule.fromunits = 1;
			}
			else if(field == "Skipcount") {
				rule.field = GPod.SPLField.SKIPCOUNT;
				rule.fromvalue = uint64.parse(value);
				rule.tovalue = uint64.parse(value);
				rule.tounits = 1;
			}
			else if(field == "Year") {
				rule.field = GPod.SPLField.YEAR;
				rule.fromvalue = uint64.parse(value);
				rule.tovalue = uint64.parse(value);
				rule.tounits = 1;
				rule.fromunits = 1;
			}
			else if(field == "Length") {
				rule.field = GPod.SPLField.TIME;
				rule.fromvalue = uint64.parse(value) * 1000;
				rule.tovalue = uint64.parse(value) * 1000;
				rule.tounits = 1;
				rule.fromunits = 1;
			}
			else if(field == "Rating") {
				rule.field = GPod.SPLField.RATING;
				rule.fromvalue = uint64.parse(value) * 20;
				rule.tovalue = uint64.parse(value) * 20;
				rule.tounits = 1;//20;
				rule.fromunits = 1;//20;
			}
			else if(field == "Date Added") {
				rule.field = GPod.SPLField.DATE_ADDED;
				rule.fromvalue = uint64.parse(value) * 60 * 60 * 24;
				rule.tovalue = uint64.parse(value) * 60 * 60 * 24;
				rule.tounits = 1;//60 * 60 * 24;
				rule.fromunits = 1;//60 * 60 * 24;
			}
			else if(field == "Last Played") {
				rule.field = GPod.SPLField.LAST_PLAYED;
				rule.fromvalue = uint64.parse(value) * 60 * 60 * 24;
				rule.tovalue = uint64.parse(value) * 60 * 60 * 24;
				rule.tounits = 1;//60 * 60 * 24;
				rule.fromunits = 1;//60 * 60 * 24;
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
			
			// set action type
			if(comparator == "is") {
				rule.action = GPod.SPLAction.IS_STRING;
			}
			else if(comparator == "is not") {
				rule.action = GPod.SPLAction.IS_NOT_INT;
			}
			else if(comparator == "contains") {
				rule.action = GPod.SPLAction.CONTAINS;
				stdout.printf("hi at contains\n");
			}
			else if(comparator == "does not contain") {
				rule.action = GPod.SPLAction.DOES_NOT_CONTAIN;
			}
			else if(comparator == "is exactly") {
				rule.action = GPod.SPLAction.IS_INT;
			}
			else if(comparator == "is at most") {
				rule.action = GPod.SPLAction.IS_LESS_THAN;
				rule.fromvalue += 1;
				rule.tovalue += 1;
			}
			else if(comparator == "is at least") {
				rule.action = GPod.SPLAction.IS_GREATER_THAN;
				rule.fromvalue -= 1;
				rule.tovalue -= 1;
			}
			else if(comparator == "is within") {
				rule.action = GPod.SPLAction.IS_GREATER_THAN;
			}
			else if(comparator == "is before") {
				rule.action = GPod.SPLAction.IS_LESS_THAN;
			}
			
			stdout.printf("in smartplaylist  has rule and string %s\n", rule.@string);
		}
		
		stdout.printf("check %d rules\n", (int)rv.splrules.rules.length());
		rv.splpref.checkrules = (uint8)rv.splrules.rules.length();
		rv.splpref.checklimits = (uint8)0;
		rv.splrules.match_operator = (conditional == "any") ? GPod.SPLMatch.OR : GPod.SPLMatch.AND;
		rv.splpref.liveupdate = 1;
		rv.is_spl = true;
	}
}
