// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012-2013 Noise Developers (http://launchpad.net/noise)
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
 *              Corentin Noël <tintou@mailoo.org>
 */

public class Noise.SmartPlaylist : Playlist {

    public static const string QUERY_SEPARATOR = "<query_sep>";
    public static const string VALUE_SEPARATOR = "<val_sep>";

    public enum ConditionalType {
        ALL = true,
        ANY = false
    }

    public ConditionalType conditional { get; set; default = ConditionalType.ALL; }
    public Gee.ArrayList<SmartQuery> _queries;
    public int query_count { get; set; default = 0; }
    
    public bool limit { get; set; default = false; }
    public int limit_amount { get; set; default = 50; }
    
    private Gee.Collection<Media> medias_library;
    
    public SmartPlaylist(Gee.Collection<Media> library) {
        _queries = new Gee.ArrayList<SmartQuery>();
        medias = new Gee.LinkedList<Media> ();
        medias_library = library;
        icon = Icons.SMART_PLAYLIST.gicon;
    }

    public void clearQueries() {
        query_count = 0;
        _queries.clear();
        updated ();
    }

    public Gee.ArrayList<SmartQuery> queries() {
        return _queries;
    }

    public void add_query(SmartQuery s) {
        query_count++;
        _queries.add(s);
        analyse_list_async.begin (medias_library);
        updated ();
    }

    public void add_queries(Gee.Collection<SmartQuery> queries) {
        query_count = query_count + queries.size;
        _queries.add_all (queries);
        analyse_list_async.begin (medias_library);
        updated ();
    }

    public void update_medias (Gee.Collection<Media> medias) {
        var added_medias = new Gee.LinkedList<Media> ();
        
        foreach (var media in medias) {
            if (media != null && medias_library.contains (media)) {
                added_medias.add (media);
            }
            if ((limit && limit_amount > medias.size) || !limit) {
                analyse_list_async.begin (added_medias);
            }
        }
    }

    public override void add_media (Media m) {
        var added_media = new Gee.LinkedList<Media> ();
        
        if (m != null && !medias_library.contains (m)) {
            medias_library.add (m);
            added_media.add (m);
        }
        if ((limit && limit_amount > medias.size) || !limit) {
            analyse_list_async.begin (added_media);
        }
    }

    public override void add_medias (Gee.Collection<Media> to_add) {
        var added_media = new Gee.LinkedList<Media> ();
        
        foreach (var m in to_add) {
            if (m != null && !medias_library.contains (m)) {
                medias_library.add (m);
                added_media.add (m);
            }
        }
        if ((limit && limit_amount > medias.size) || !limit) {
            analyse_list_async.begin (added_media);
        }
    }

    public override void remove_media (Media to_remove) {
        if (to_remove != null && medias.contains (to_remove)) {
            var removed_media = new Gee.LinkedList<Media> ();
            removed_media.add (to_remove);
            medias.remove (to_remove);
            media_removed (removed_media);
        }
        if (medias_library.contains (to_remove))
            medias_library.remove (to_remove);
    }

    public override void remove_medias (Gee.Collection<Media> to_remove) {
        var removed_media = new Gee.LinkedList<Media> ();
        foreach (var m in to_remove) {
            if (m != null && medias.contains (m)) {
                removed_media.add (m);
                medias.remove (m);
            }
            if (medias_library.contains (m))
                medias_library.remove (m);
        }
        media_removed (removed_media);
    }

    /** temp_playlist should be in format of #,#,#,#,#, **/
    public void queries_from_string(string q) {
        string[] queries_in_string = q.split(QUERY_SEPARATOR, 0);
        
        int index;
        
        var queries = new Gee.LinkedList<SmartQuery> ();
        for(index = 0; index < queries_in_string.length - 1; index++) {
            string[] pieces_of_query = queries_in_string[index].split(VALUE_SEPARATOR, 3);
            pieces_of_query.resize (3);
            
            SmartQuery sq = new SmartQuery();
            sq.field = (SmartQuery.FieldType)int.parse(pieces_of_query[0]);
            sq.comparator = (SmartQuery.ComparatorType)int.parse(pieces_of_query[1]);
            sq.value = pieces_of_query[2];
            
            queries.add (sq);
        }
        add_queries (queries);
    }

    public string queries_to_string() {
        string rv = "";
        
        foreach(SmartQuery q in queries()) {
            rv += ((int)q.field).to_string() + VALUE_SEPARATOR + ((int)q.comparator).to_string() + VALUE_SEPARATOR + q.value + QUERY_SEPARATOR;
        }
        
        return rv;
    }

    /*public Gee.Collection<Media> analyze_ids (LibraryManager lm, Gee.Collection<int> ids) {
        var to_analyze = new Gee.LinkedList<Media> ();
        foreach (var id in ids) {
            var m = lm.media_from_id (id);
            if (m != null)
                to_analyze.add (m);
        }
        return analyze (lm, to_analyze);
    }*/

    public void reanalyze () {

        analyse_list_async.begin (medias_library);
    }

    async void analyse_list_async (Gee.Collection<Media> given_library) {
        var added = new Gee.LinkedList<Media> ();
        var removed = new Gee.LinkedList<Media> ();
        
        lock (medias_library) {
            Threads.add (() => {
                foreach (var m in given_library) {
                    if (m == null)
                        continue;

                    int match_count = 0; //if OR must be greater than 0. if AND must = queries.size.

                    foreach (var q in _queries) {
                        if (media_matches_query (q, m))
                            match_count++;
                    }
                    
                    if(((conditional == ConditionalType.ALL && match_count == _queries.size) || 
                        (conditional == ConditionalType.ANY && match_count >= 1)) && !m.isTemporary) {
                        if (!medias.contains (m)) {
                            added.add (m);
                            medias.add (m);
                        }
                    } else if (medias.contains (m)) {
                        // a media which was part of the previous set no longer matches
                        // the query, and it must be removed
                        medias.remove (m);
                        removed.add (m);
                    }

                    if (limit && limit_amount <= medias.size)
                        break;
                }

                Idle.add( () => {
                    // Emit signal to let views know about the change
                    media_added (added);
                    media_removed (removed);
                    return false;
                });
            });
        }

        yield;
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

    public override void clear() {
        medias.clear ();
        medias_library.clear ();
        cleared ();
    }
}
