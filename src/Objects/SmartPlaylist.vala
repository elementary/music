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


public class Noise.SmartPlaylist : Object {

    //public static const string QUERY_S_SEP = "<query_sep>";
    //public static const string VALUE_S_SEP = "<val_sep>";

    public enum ConditionalType {
        ANY = true,
        ALL = false
    }

    public signal void media_added (Gee.Collection<Media> added);

    public signal void media_removed (Gee.Collection<Media> removed);

    public int rowid { get; set; default = 0; }
    public TreeViewSetup tvs;
    public string name { get; set; default = ""; }
    public ConditionalType conditional { get; set; default = ConditionalType.ALL; }
    public Gee.ArrayList<SmartQuery> _queries;
    public int query_count { get; set; default = 0; }
    
    public bool limit { get; set; default = false; }
    public int limit_amount { get; set; default = 50; }
    
    private Gee.HashSet<Media> media = new Gee.HashSet<Media> ();
    
    public SmartPlaylist() {
        tvs = new TreeViewSetup (ListColumn.ARTIST, Gtk.SortType.ASCENDING, ViewWrapper.Hint.SMART_PLAYLIST);
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
        string[] queries_in_string = q.split("<query_sep>", 0);
        
        int index;
        for(index = 0; index < queries_in_string.length - 1; index++) {
            string[] pieces_of_query = queries_in_string[index].split("<val_sep>", 3);
            pieces_of_query.resize (3);
            
            SmartQuery sq = new SmartQuery();
            sq.field = (SmartQuery.FieldType)int.parse(pieces_of_query[0]);
            sq.comparator = (SmartQuery.ComparatorType)int.parse(pieces_of_query[1]);
            sq.value = pieces_of_query[2];
            
            addQuery(sq);
        }
    }
    
    public string queries_to_string() {
        string rv = "";
        
        foreach(SmartQuery q in queries()) {
            rv += ((int)q.field).to_string() + "<val_sep>" + ((int)q.comparator).to_string() + "<val_sep>" + q.value + "<query_sep>";
        }
        
        return rv;
    }

    public Gee.Collection<Media> analyze_ids (LibraryManager lm, Gee.Collection<int> ids) {
        var to_analyze = new Gee.LinkedList<Media> ();
        foreach (var id in ids) {
            var m = lm.media_from_id (id);
            if (m != null)
                to_analyze.add (m);
        }
        return analyze (lm, to_analyze);
    }

    public Gee.Collection<Media> analyze (LibraryManager lm, Collection<Media> to_test) {
        var added = new Gee.LinkedList<Media> ();
        var removed = new Gee.LinkedList<Media> ();

        foreach (var m in to_test) {
            if (m == null)
                continue;

            int match_count = 0; //if OR must be greater than 0. if AND must = queries.size.

            foreach (var q in _queries) {
                if (media_matches_query (q, m))
                    match_count++;
            }
            
            if(((conditional == ConditionalType.ALL && match_count == _queries.size) || (conditional == ConditionalType.ANY && match_count >= 1)) && !m.isTemporary) {
                if (!media.contains (m)) {
                    added.add (m);
                    media.add (m);
                }
            } else if (media.contains (m)) {
                // a media which was part of the previous set no longer matches
                // the query, and it must be removed
                media.remove (m);
                removed.add (m);
            }

            if (_limit && _limit_amount <= media.size)
                break;
        }

        // Emit signal to let views know about the change
        media_added (added);
        media_removed (removed);

        return media.read_only_view;
    }
    
    public bool media_matches_query(SmartQuery q, Media s) {
        switch (q.field) {
            case Noise.SmartQuery.FieldType.ALBUM :
                if(q.comparator == SmartQuery.ComparatorType.IS)
                    return q.value.down() == s.album.down();
                else if(q.comparator == SmartQuery.ComparatorType.CONTAINS)
                    return (q.value.down() in s.album.down());
                else if(q.comparator == SmartQuery.ComparatorType.NOT_CONTAINS)
                    return !(q.value.down() in s.album.down());
                break;
            case Noise.SmartQuery.FieldType.ARTIST:
                if(q.comparator == SmartQuery.ComparatorType.IS)
                    return q.value.down() == s.artist.down();
                else if(q.comparator == SmartQuery.ComparatorType.CONTAINS)
                    return (q.value.down() in s.artist.down());
                else if(q.comparator == SmartQuery.ComparatorType.NOT_CONTAINS)
                    return !(q.value.down() in s.artist.down());
                break;
            case Noise.SmartQuery.FieldType.COMPOSER:
                if(q.comparator == SmartQuery.ComparatorType.IS)
                    return q.value.down() == s.composer.down();
                else if(q.comparator == SmartQuery.ComparatorType.CONTAINS)
                    return (q.value.down() in s.composer.down());
                else if(q.comparator == SmartQuery.ComparatorType.NOT_CONTAINS)
                    return !(q.value.down() in s.composer.down());
                break;
            case Noise.SmartQuery.FieldType.COMMENT:
                if(q.comparator == SmartQuery.ComparatorType.IS)
                    return q.value.down() == s.comment.down();
                else if(q.comparator == SmartQuery.ComparatorType.CONTAINS)
                    return (q.value.down() in s.comment.down());
                else if(q.comparator == SmartQuery.ComparatorType.NOT_CONTAINS)
                    return !(q.value.down() in s.comment.down());
                break;
            case Noise.SmartQuery.FieldType.GENRE:
                if(q.comparator == SmartQuery.ComparatorType.IS)
                    return q.value.down() == s.genre.down();
                else if(q.comparator == SmartQuery.ComparatorType.CONTAINS)
                    return (q.value.down() in s.genre.down());
                else if(q.comparator == SmartQuery.ComparatorType.NOT_CONTAINS)
                    return !(q.value.down() in s.genre.down());
                break;
            case Noise.SmartQuery.FieldType.GROUPING:
                if(q.comparator == SmartQuery.ComparatorType.IS)
                    return q.value.down() == s.grouping.down();
                else if(q.comparator == SmartQuery.ComparatorType.CONTAINS)
                    return (q.value.down() in s.grouping.down());
                else if(q.comparator == SmartQuery.ComparatorType.NOT_CONTAINS)
                    return !(q.value.down() in s.grouping.down());
                break;
            case Noise.SmartQuery.FieldType.TITLE:
                if(q.comparator == SmartQuery.ComparatorType.IS)
                    return q.value.down() == s.title.down();
                else if(q.comparator == SmartQuery.ComparatorType.CONTAINS)
                    return (q.value.down() in s.title.down());
                else if(q.comparator == SmartQuery.ComparatorType.NOT_CONTAINS)
                    return !(q.value.down() in s.title.down());
                break;
            case Noise.SmartQuery.FieldType.BITRATE:
                if(q.comparator == SmartQuery.ComparatorType.IS_EXACTLY)
                    return int.parse(q.value) == s.bitrate;
                else if(q.comparator == SmartQuery.ComparatorType.IS_AT_MOST)
                    return (s.bitrate <= int.parse(q.value));
                else if(q.comparator == SmartQuery.ComparatorType.IS_AT_LEAST)
                    return (s.bitrate >= int.parse(q.value));
                break;
            case Noise.SmartQuery.FieldType.PLAYCOUNT:
                if(q.comparator == SmartQuery.ComparatorType.IS_EXACTLY)
                    return int.parse(q.value) == s.play_count;
                else if(q.comparator == SmartQuery.ComparatorType.IS_AT_MOST)
                    return (s.play_count <= int.parse(q.value));
                else if(q.comparator == SmartQuery.ComparatorType.IS_AT_LEAST)
                    return (s.play_count >= int.parse(q.value));
                break;
            case Noise.SmartQuery.FieldType.SKIPCOUNT:
                if(q.comparator == SmartQuery.ComparatorType.IS_EXACTLY)
                    return int.parse(q.value) == s.skip_count;
                else if(q.comparator == SmartQuery.ComparatorType.IS_AT_MOST)
                    return (s.skip_count <= int.parse(q.value));
                else if(q.comparator == SmartQuery.ComparatorType.IS_AT_LEAST)
                    return (s.skip_count >= int.parse(q.value));
                break;
            case Noise.SmartQuery.FieldType.YEAR:
                if(q.comparator == SmartQuery.ComparatorType.IS_EXACTLY)
                    return int.parse(q.value) == s.year;
                else if(q.comparator == SmartQuery.ComparatorType.IS_AT_MOST)
                    return (s.year <= int.parse(q.value));
                else if(q.comparator == SmartQuery.ComparatorType.IS_AT_LEAST)
                    return (s.year >= int.parse(q.value));
                break;
            case Noise.SmartQuery.FieldType.LENGTH:
                if(q.comparator == SmartQuery.ComparatorType.IS_EXACTLY)
                    return int.parse(q.value) == s.length;
                else if(q.comparator == SmartQuery.ComparatorType.IS_AT_MOST)
                    return (s.length <= int.parse(q.value));
                else if(q.comparator == SmartQuery.ComparatorType.IS_AT_LEAST)
                    return (s.length >= int.parse(q.value));
                break;
            case Noise.SmartQuery.FieldType.RATING:
                if(q.comparator == SmartQuery.ComparatorType.IS_EXACTLY)
                    return int.parse(q.value) == s.rating;
                else if(q.comparator == SmartQuery.ComparatorType.IS_AT_MOST)
                    return (s.rating <= int.parse(q.value));
                else if(q.comparator == SmartQuery.ComparatorType.IS_AT_LEAST)
                    return (s.rating >= int.parse(q.value));
                break;
            case Noise.SmartQuery.FieldType.DATE_ADDED:
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
            case Noise.SmartQuery.FieldType.DATE_RELEASED:
/*
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
*/
                break;
            case Noise.SmartQuery.FieldType.LAST_PLAYED:
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
        }
        
        return false;
    }
}
