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

    public enum ConditionalType {
        ALL = true,
        ANY = false
    }

    public ConditionalType conditional { get; set; default = ConditionalType.ALL; }
    public Gee.TreeSet<SmartQuery> queries;
    public int query_count { get; set; default = 0; }

    public bool limit { get; set; default = false; }
    public int limit_amount { get; set; default = 50; }

    private Noise.Library library;

    /*
     * A SmartPlaylist should be linked to only one library.
     */
    public SmartPlaylist (Noise.Library library) {
        this.library = library;
        queries = new Gee.TreeSet<SmartQuery>();
        medias = new Gee.ArrayQueue<Media> ();
        icon = Icons.SMART_PLAYLIST.gicon;
        library.media_added.connect ((medias) => {
            analyse_list (medias);
        });

        library.media_updated.connect ((medias) => {
            analyse_list (medias);
        });

        library.media_removed.connect ((medias) => {
            var removed = new Gee.LinkedList<Media> ();
            foreach (var m in medias) {
                if (this.medias.contains (m)) {
                    this.medias.remove (m);
                    removed.add (m);
                }
            }

            media_removed (removed);
        });
    }

    /*
     * Common Playlist Functions.
     */

    public override void add_media (Media m) {
        warning ("Trying to force the media addition to a smart playlist!");
    }

    public override void add_medias (Gee.Collection<Media> to_add) {
        warning ("Trying to force the media addition to a smart playlist!");
    }

    public override void remove_media (Media to_remove) {
        warning ("Trying to force the media removal from a smart playlist!");
    }

    public override void remove_medias (Gee.Collection<Media> to_remove) {
        warning ("Trying to force the media removal from a smart playlist!");
    }

    public virtual void analyse_all () {
        analyse_list (library.get_medias ());
    }

    /*
     * Special functions of a Smart Playlist.
     */

    public virtual void clear_queries () {
        query_count = 0;
        queries.clear ();
        updated ();
    }

    public virtual Gee.Collection<SmartQuery> get_queries () {
        return queries.read_only_view;
    }

    public virtual void add_query (SmartQuery s) {
        query_count++;
        queries.add (s);
        analyse_all ();
        updated ();
    }

    public virtual void add_queries (Gee.Collection<SmartQuery> queries) {
        query_count = query_count + queries.size;
        this.queries.add_all (queries);
        analyse_all ();
        updated ();
    }

    // FIXME: Clearing a Smart Playlist ???
    public override void clear() {
        medias.clear ();
        cleared ();
    }

    /*
     * Smart Playlist Helpers
     */

    public static bool media_matches_query (SmartQuery q, Media s) {
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

    private void analyse_list (Gee.Collection<Media> given_library) {
        new Thread<void*> (null, () => {
            var added = new Gee.TreeSet<Media> ();
            var removed = new Gee.TreeSet<Media> ();

            foreach (var m in given_library) {
                if (m == null)
                    continue;

                int match_count = 0; //if OR must be greater than 0. if AND must = queries.size.

                foreach (var q in queries) {
                    if (media_matches_query (q, m))
                        match_count++;
                }

                if(((conditional == ConditionalType.ALL && match_count == queries.size) || 
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

            return null;
        });
    }
}
