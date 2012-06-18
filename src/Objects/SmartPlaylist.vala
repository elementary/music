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

using Gee;


public class BeatBox.SmartPlaylist : Object {
    
    public enum ConditionalType {
        ANY = true,
        ALL = false
    }

    public signal void changed (Gee.Collection<Media> media);

    public int rowid { get; set; default = 0; }
    public TreeViewSetup tvs;
    public string name { get; set; default = ""; }
    public ConditionalType conditional { get; set; default = ConditionalType.ALL; }
    public Gee.ArrayList<SmartQuery> _queries;
    public int query_count { get; set; default = 0; }
    
    public bool limit { get; set; default = false; }
    public int limit_amount { get; set; default = 50; }
    
    public bool is_up_to_date { get; set; default = false; }
    LinkedList<Media> media;
    
    public SmartPlaylist() {
        tvs = new TreeViewSetup (MusicListView.MusicColumn.ARTIST, Gtk.SortType.ASCENDING, ViewWrapper.Hint.SMART_PLAYLIST);
        _queries = new Gee.ArrayList<SmartQuery>();
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
            string[] pieces_of_query = queries_in_string[index].split("<value_separator>", 0);
            pieces_of_query.resize (3);
            
            SmartQuery sq = new SmartQuery();
            sq.field = (SmartQuery.FieldType)int.parse(pieces_of_query[0]);
            sq.comparator = get_comparator_from_string(pieces_of_query[1]);
            sq.value = pieces_of_query[2];
            
            addQuery(sq);
        }
    }
    
    public string queries_to_string() {
        string rv = "";
        
        foreach(SmartQuery q in queries()) {
            rv += q.field.to_string() + "<value_separator>" + get_comparator_name(q.comparator) + "<value_separator>" + q.value + "<query_seperator>";
        }
        
        return rv;
    }

    public Gee.LinkedList<Media> analyze_ids (LibraryManager lm, Gee.Collection<int> ids) {
        var to_analyze = new Gee.LinkedList<Media> ();
        foreach (var id in ids) {
            var m = lm.media_from_id (id);
            if (m != null)
                to_analyze.add (m);
        }
        return analyze (lm, to_analyze);
    }

    public Gee.LinkedList<Media> analyze (LibraryManager lm, Collection<Media> to_test) {
        //if(is_up_to_date) {
        //    return media;
        //}
        
        var rv = new LinkedList<Media>();
        foreach (var m in to_test) {
            if (m == null)
                continue;

            int match_count = 0; //if OR must be greater than 0. if AND must = queries.size.
            
            foreach(SmartQuery q in _queries) {
                if(media_matches_query(q, m))
                    match_count++;
            }
            
            if(((conditional == ConditionalType.ALL && match_count == _queries.size) || (conditional == ConditionalType.ANY && match_count >= 1)) && !m.isTemporary)
                rv.add (m);
                
            if(_limit && _limit_amount <= rv.size)
                return rv;
        }
        
        is_up_to_date = true;
        media = rv;
        
        // Emit signal to let views know about the change
        changed (media);
        
        return rv;
    }
    
    public bool media_matches_query(SmartQuery q, Media s) {
        switch (q.field) {
            case BeatBox.SmartQuery.FieldType.ALBUM :
                if(q.comparator == SmartQuery.ComparatorType.IS)
                    return q.value.down() == s.album.down();
                else if(q.comparator == SmartQuery.ComparatorType.CONTAINS)
                    return (q.value.down() in s.album.down());
                else if(q.comparator == SmartQuery.ComparatorType.NOT_CONTAINS)
                    return !(q.value.down() in s.album.down());
                break;
            case BeatBox.SmartQuery.FieldType.ARTIST:
                if(q.comparator == SmartQuery.ComparatorType.IS)
                    return q.value.down() == s.artist.down();
                else if(q.comparator == SmartQuery.ComparatorType.CONTAINS)
                    return (q.value.down() in s.artist.down());
                else if(q.comparator == SmartQuery.ComparatorType.NOT_CONTAINS)
                    return !(q.value.down() in s.artist.down());
                break;
            case BeatBox.SmartQuery.FieldType.COMPOSER:
                if(q.comparator == SmartQuery.ComparatorType.IS)
                    return q.value.down() == s.composer.down();
                else if(q.comparator == SmartQuery.ComparatorType.CONTAINS)
                    return (q.value.down() in s.composer.down());
                else if(q.comparator == SmartQuery.ComparatorType.NOT_CONTAINS)
                    return !(q.value.down() in s.composer.down());
                break;
            case BeatBox.SmartQuery.FieldType.COMMENT:
                if(q.comparator == SmartQuery.ComparatorType.IS)
                    return q.value.down() == s.comment.down();
                else if(q.comparator == SmartQuery.ComparatorType.CONTAINS)
                    return (q.value.down() in s.comment.down());
                else if(q.comparator == SmartQuery.ComparatorType.NOT_CONTAINS)
                    return !(q.value.down() in s.comment.down());
                break;
            case BeatBox.SmartQuery.FieldType.GENRE:
                if(q.comparator == SmartQuery.ComparatorType.IS)
                    return q.value.down() == s.genre.down();
                else if(q.comparator == SmartQuery.ComparatorType.CONTAINS)
                    return (q.value.down() in s.genre.down());
                else if(q.comparator == SmartQuery.ComparatorType.NOT_CONTAINS)
                    return !(q.value.down() in s.genre.down());
                break;
            case BeatBox.SmartQuery.FieldType.GROUPING:
                if(q.comparator == SmartQuery.ComparatorType.IS)
                    return q.value.down() == s.grouping.down();
                else if(q.comparator == SmartQuery.ComparatorType.CONTAINS)
                    return (q.value.down() in s.grouping.down());
                else if(q.comparator == SmartQuery.ComparatorType.NOT_CONTAINS)
                    return !(q.value.down() in s.grouping.down());
                break;
            case BeatBox.SmartQuery.FieldType.TITLE:
                if(q.comparator == SmartQuery.ComparatorType.IS)
                    return q.value.down() == s.title.down();
                else if(q.comparator == SmartQuery.ComparatorType.CONTAINS)
                    return (q.value.down() in s.title.down());
                else if(q.comparator == SmartQuery.ComparatorType.NOT_CONTAINS)
                    return !(q.value.down() in s.title.down());
                break;
            case BeatBox.SmartQuery.FieldType.BITRATE:
                if(q.comparator == SmartQuery.ComparatorType.IS_EXACTLY)
                    return int.parse(q.value) == s.bitrate;
                else if(q.comparator == SmartQuery.ComparatorType.IS_AT_MOST)
                    return (s.bitrate <= int.parse(q.value));
                else if(q.comparator == SmartQuery.ComparatorType.IS_AT_LEAST)
                    return (s.bitrate >= int.parse(q.value));
                break;
            case BeatBox.SmartQuery.FieldType.PLAYCOUNT:
                if(q.comparator == SmartQuery.ComparatorType.IS_EXACTLY)
                    return int.parse(q.value) == s.play_count;
                else if(q.comparator == SmartQuery.ComparatorType.IS_AT_MOST)
                    return (s.play_count <= int.parse(q.value));
                else if(q.comparator == SmartQuery.ComparatorType.IS_AT_LEAST)
                    return (s.play_count >= int.parse(q.value));
                break;
            case BeatBox.SmartQuery.FieldType.SKIPCOUNT:
                if(q.comparator == SmartQuery.ComparatorType.IS_EXACTLY)
                    return int.parse(q.value) == s.skip_count;
                else if(q.comparator == SmartQuery.ComparatorType.IS_AT_MOST)
                    return (s.skip_count <= int.parse(q.value));
                else if(q.comparator == SmartQuery.ComparatorType.IS_AT_LEAST)
                    return (s.skip_count >= int.parse(q.value));
                break;
            case BeatBox.SmartQuery.FieldType.YEAR:
                if(q.comparator == SmartQuery.ComparatorType.IS_EXACTLY)
                    return int.parse(q.value) == s.year;
                else if(q.comparator == SmartQuery.ComparatorType.IS_AT_MOST)
                    return (s.year <= int.parse(q.value));
                else if(q.comparator == SmartQuery.ComparatorType.IS_AT_LEAST)
                    return (s.year >= int.parse(q.value));
                break;
            case BeatBox.SmartQuery.FieldType.LENGTH:
                if(q.comparator == SmartQuery.ComparatorType.IS_EXACTLY)
                    return int.parse(q.value) == s.length;
                else if(q.comparator == SmartQuery.ComparatorType.IS_AT_MOST)
                    return (s.length <= int.parse(q.value));
                else if(q.comparator == SmartQuery.ComparatorType.IS_AT_LEAST)
                    return (s.length >= int.parse(q.value));
                break;
            case BeatBox.SmartQuery.FieldType.RATING:
                if(q.comparator == SmartQuery.ComparatorType.IS_EXACTLY)
                    return int.parse(q.value) == s.rating;
                else if(q.comparator == SmartQuery.ComparatorType.IS_AT_MOST)
                    return (s.rating <= int.parse(q.value));
                else if(q.comparator == SmartQuery.ComparatorType.IS_AT_LEAST)
                    return (s.rating >= int.parse(q.value));
                break;
            case BeatBox.SmartQuery.FieldType.DATE_ADDED:
                var now = new DateTime.now_local();
                var played = new DateTime.from_unix_local(s.date_added);
                played = played.add_days(int.parse(q.value));
            
                if(q.comparator == SmartQuery.ComparatorType.IS_EXACTLY)
                    return (now.get_day_of_year() == played.get_day_of_year() && now.get_year() == played.get_year());
                else if(q.comparator == SmartQuery.ComparatorType.IS_WITHIN) {
                    return played.compare(now) > 0;
                }
                else if(q.comparator == SmartQuery.ComparatorType.IS_BEFORE) {
                    return now.compare(played) > 0;
                }
                break;
            case BeatBox.SmartQuery.FieldType.DATE_RELEASED:
                var now = new DateTime.now_local();
                var released = new DateTime.from_unix_local(s.podcast_date);
                released = released.add_days(int.parse(q.value));
            
                if(q.comparator == SmartQuery.ComparatorType.IS_EXACTLY)
                    return (now.get_day_of_year() == released.get_day_of_year() && now.get_year() == released.get_year());
                else if(q.comparator == SmartQuery.ComparatorType.IS_WITHIN) {
                    return released.compare(now) > 0;
                }
                else if(q.comparator == SmartQuery.ComparatorType.IS_BEFORE) {
                    return now.compare(released) > 0;
                }
                break;
            case BeatBox.SmartQuery.FieldType.LAST_PLAYED:
                if(s.last_played == 0)
                    return false;
            
                var now = new DateTime.now_local();
                var played = new DateTime.from_unix_local(s.last_played);
                played = played.add_days(int.parse(q.value));
            
                if(q.comparator == SmartQuery.ComparatorType.IS_EXACTLY)
                    return (now.get_day_of_year() == played.get_day_of_year() && now.get_year() == played.get_year());
                else if(q.comparator == SmartQuery.ComparatorType.IS_WITHIN) {
                    return played.compare(now) > 0;
                }
                else if(q.comparator == SmartQuery.ComparatorType.IS_BEFORE) {
                    return now.compare(played) > 0;
                }
                break;
            case BeatBox.SmartQuery.FieldType.MEDIA_TYPE:
                if(q.comparator == SmartQuery.ComparatorType.IS)
                    return s.mediatype == int.parse(q.value);
                else if(q.comparator == SmartQuery.ComparatorType.IS_NOT)
                    return s.mediatype != int.parse(q.value);
                
                break;
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
            //if(sq.field == "Media Type")
                //continue;
            
            rv.splr_add_new(-1);
            
            unowned GPod.SPLRule? rule = rv.splrules.rules.nth_data(rv.splrules.rules.length() - 1);
            
            stdout.printf("adding rule\n");
            var field = sq.field;
            var value = sq.value;
            var comparator = sq.comparator;
            switch (field) {
            case SmartQuery.FieldType.ALBUM:
                rule.field = GPod.SPLField.ALBUM;
                rule.@string = value;
                break;
            case SmartQuery.FieldType.ARTIST:
                rule.field = GPod.SPLField.ARTIST;
                rule.@string = value;
                break;
            case SmartQuery.FieldType.COMPOSER:
                rule.field = GPod.SPLField.COMPOSER;
                rule.@string = value;
                break;
            case SmartQuery.FieldType.COMMENT:
                rule.field = GPod.SPLField.COMMENT;
                rule.@string = value;
                break;
            case SmartQuery.FieldType.GENRE:
                rule.field = GPod.SPLField.GENRE;
                rule.@string = value;
                break;
            case SmartQuery.FieldType.GROUPING:
                rule.field = GPod.SPLField.GROUPING;
                rule.@string = value;
                break;
            case SmartQuery.FieldType.TITLE:
                rule.field = GPod.SPLField.SONG_NAME;
                rule.@string = value;
                break;
            case SmartQuery.FieldType.BITRATE:
                rule.field = GPod.SPLField.BITRATE;
                rule.fromvalue = uint64.parse(value);
                rule.tovalue = uint64.parse(value);
                rule.tounits = 1;
                rule.fromunits = 1;
                break;
            case SmartQuery.FieldType.PLAYCOUNT:
                rule.field = GPod.SPLField.PLAYCOUNT;
                rule.fromvalue = uint64.parse(value);
                rule.tovalue = uint64.parse(value);
                rule.tounits = 1;
                rule.fromunits = 1;
                break;
            case SmartQuery.FieldType.SKIPCOUNT:
                rule.field = GPod.SPLField.SKIPCOUNT;
                rule.fromvalue = uint64.parse(value);
                rule.tovalue = uint64.parse(value);
                rule.tounits = 1;
                break;
            case SmartQuery.FieldType.YEAR:
                rule.field = GPod.SPLField.YEAR;
                rule.fromvalue = uint64.parse(value);
                rule.tovalue = uint64.parse(value);
                rule.tounits = 1;
                rule.fromunits = 1;
                break;
            case SmartQuery.FieldType.LENGTH:
                rule.field = GPod.SPLField.TIME;
                rule.fromvalue = uint64.parse(value) * 1000;
                rule.tovalue = uint64.parse(value) * 1000;
                rule.tounits = 1;
                rule.fromunits = 1;
                break;
            case SmartQuery.FieldType.RATING:
                stdout.printf("rating rule is %s\n", value);
                rule.field = GPod.SPLField.RATING;
                rule.fromvalue = uint64.parse(value) * 20;
                rule.tovalue = uint64.parse(value) * 20;
                rule.tounits = 1;//20;
                rule.fromunits = 1;//20;
                break;
            case SmartQuery.FieldType.DATE_ADDED:
                rule.field = GPod.SPLField.DATE_ADDED;
                rule.fromvalue = uint64.parse(value) * 60 * 60 * 24;
                rule.tovalue = uint64.parse(value) * 60 * 60 * 24;
                rule.tounits = 1;//60 * 60 * 24;
                rule.fromunits = 1;//60 * 60 * 24;
                break;
            case SmartQuery.FieldType.LAST_PLAYED:
                rule.field = GPod.SPLField.LAST_PLAYED;
                rule.fromvalue = uint64.parse(value) * 60 * 60 * 24;
                rule.tovalue = uint64.parse(value) * 60 * 60 * 24;
                rule.tounits = 1;//60 * 60 * 24;
                rule.fromunits = 1;//60 * 60 * 24;
                break;
            case SmartQuery.FieldType.DATE_RELEASED:
                // no equivelant
                break;
            case SmartQuery.FieldType.MEDIA_TYPE:
                rule.field = GPod.SPLField.VIDEO_KIND;
                if(value == "0") {
                    stdout.printf("must be song\n");
                    rule.fromvalue = 0x00000001;
                    rule.tovalue = 0x00000001;;
                }
                else if(value == "1") {
                    rule.fromvalue = 0x00000006;
                    rule.tovalue = 0x00000006;
                    stdout.printf("must be podcast\n");
                }
                else if(value == "2") {
                    rule.fromvalue = 0x00000008;
                    rule.tovalue = 0x00000008;
                }
                break;
            }
            
            // set action type
            if(comparator == SmartQuery.ComparatorType.IS) {
                if(field == SmartQuery.FieldType.MEDIA_TYPE)
                    rule.action = GPod.SPLAction.BINARY_AND;
                else
                    rule.action = GPod.SPLAction.IS_STRING;
            }
            else if(comparator == SmartQuery.ComparatorType.IS_NOT) {
                if(field == SmartQuery.FieldType.MEDIA_TYPE)
                    rule.action = GPod.SPLAction.NOT_BINARY_AND;
                else
                    rule.action = GPod.SPLAction.IS_NOT_INT;
            }
            else if(comparator == SmartQuery.ComparatorType.CONTAINS) {
                rule.action = GPod.SPLAction.CONTAINS;
                stdout.printf("hi at contains\n");
            }
            else if(comparator == SmartQuery.ComparatorType.NOT_CONTAINS) {
                rule.action = GPod.SPLAction.DOES_NOT_CONTAIN;
            }
            else if(comparator == SmartQuery.ComparatorType.IS_EXACTLY) {
                rule.action = GPod.SPLAction.IS_INT;
            }
            else if(comparator == SmartQuery.ComparatorType.IS_AT_MOST) {
                rule.action = GPod.SPLAction.IS_LESS_THAN;
                rule.fromvalue += 1;
                rule.tovalue += 1;
            }
            else if(comparator == SmartQuery.ComparatorType.IS_AT_LEAST) {
                rule.action = GPod.SPLAction.IS_GREATER_THAN;
                rule.fromvalue -= 1;
                rule.tovalue -= 1;
            }
            else if(comparator == SmartQuery.ComparatorType.IS_WITHIN) {
                rule.action = GPod.SPLAction.IS_GREATER_THAN;
            }
            else if(comparator == SmartQuery.ComparatorType.IS_BEFORE) {
                rule.action = GPod.SPLAction.IS_LESS_THAN;
            }
            
            stdout.printf("in smartplaylist  has rule and string %s\n", rule.@string);
        }
        
        stdout.printf("check %d rules\n", (int)rv.splrules.rules.length());
        rv.splpref.checkrules = (uint8)rv.splrules.rules.length();
        rv.splpref.checklimits = (uint8)0;
        rv.splrules.match_operator = (conditional == ConditionalType.ANY) ? GPod.SPLMatch.OR : GPod.SPLMatch.AND;
        rv.splpref.liveupdate = 1;
        rv.is_spl = true;
    }
    
    public string get_comparator_name (SmartQuery.ComparatorType comparator) {
    
        switch (comparator) {
        case SmartQuery.ComparatorType.IS:
            return "is";
        case SmartQuery.ComparatorType.IS_NOT:
            return "isnot";
        case SmartQuery.ComparatorType.CONTAINS:
            return "contains";
        case SmartQuery.ComparatorType.NOT_CONTAINS:
            return "notcontains";
        case SmartQuery.ComparatorType.IS_EXACTLY:
            return "isexactly";
        case SmartQuery.ComparatorType.IS_AT_MOST:
            return "isatmost";
        case SmartQuery.ComparatorType.IS_AT_LEAST:
            return "isatleast";
        case SmartQuery.ComparatorType.IS_WITHIN:
            return "iswithin";
        case SmartQuery.ComparatorType.IS_BEFORE:
            return "isbefore";
        }
        return "is";
    }
    
    public SmartQuery.ComparatorType get_comparator_from_string (string comparator) {
    
        switch (comparator) {
        case "is":
            return SmartQuery.ComparatorType.IS;
        case "isnot":
            return SmartQuery.ComparatorType.IS_NOT;
        case "contains":
            return SmartQuery.ComparatorType.CONTAINS;
        case "notcontains":
            return SmartQuery.ComparatorType.NOT_CONTAINS;
        case "isexactly":
            return SmartQuery.ComparatorType.IS_EXACTLY;
        case "isatmost":
            return SmartQuery.ComparatorType.IS_AT_MOST;
        case "isatleast":
            return SmartQuery.ComparatorType.IS_AT_LEAST;
        case "iswithin":
            return SmartQuery.ComparatorType.IS_WITHIN;
        case "isbefore":
            return SmartQuery.ComparatorType.IS_BEFORE;
        }
        return SmartQuery.ComparatorType.IS;
    }
}
