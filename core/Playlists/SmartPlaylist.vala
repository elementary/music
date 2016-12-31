// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012-2017 elementary LLC. (https://elementary.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
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

public class Noise.SmartPlaylist : Playlist {
    public enum ConditionalType {
        ALL = true,
        ANY = false
    }

    public virtual ConditionalType conditional { get; set; default = ConditionalType.ALL; }
    public Gee.TreeSet<SmartQuery> queries;
    public int query_count { get; set; default = 0; }

    public virtual bool limit { get; set; default = false; }
    public virtual uint limit_amount { get; set; default = 50; }

    protected Noise.Library library;

    /*
     * A SmartPlaylist should be linked to only one library.
     */
    public SmartPlaylist (Noise.Library library) {
        this.library = library;
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

    construct {
        medias = new Gee.ArrayQueue<Media> ();
        icon = new ThemedIcon ("playlist-automatic");
        queries = new Gee.TreeSet<SmartQuery>();
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
                    return q.value.get_string ().down () == s.album.down();
                else if(q.comparator == SmartQuery.ComparatorType.CONTAINS)
                    return (q.value.get_string ().down() in s.album.down());
                else if(q.comparator == SmartQuery.ComparatorType.NOT_CONTAINS)
                    return !(q.value.get_string ().down() in s.album.down());
                break;
            case Noise.SmartQuery.FieldType.ARTIST:
                if(q.comparator == SmartQuery.ComparatorType.IS)
                    return q.value.get_string ().down() == s.artist.down();
                else if(q.comparator == SmartQuery.ComparatorType.CONTAINS)
                    return (q.value.get_string ().down() in s.artist.down());
                else if(q.comparator == SmartQuery.ComparatorType.NOT_CONTAINS)
                    return !(q.value.get_string ().down() in s.artist.down());
                break;
            case Noise.SmartQuery.FieldType.COMPOSER:
                if(q.comparator == SmartQuery.ComparatorType.IS)
                    return q.value.get_string ().down() == s.composer.down();
                else if(q.comparator == SmartQuery.ComparatorType.CONTAINS)
                    return (q.value.get_string ().down() in s.composer.down());
                else if(q.comparator == SmartQuery.ComparatorType.NOT_CONTAINS)
                    return !(q.value.get_string ().down() in s.composer.down());
                break;
            case Noise.SmartQuery.FieldType.COMMENT:
                if(q.comparator == SmartQuery.ComparatorType.IS)
                    return q.value.get_string ().down() == s.comment.down();
                else if(q.comparator == SmartQuery.ComparatorType.CONTAINS)
                    return (q.value.get_string ().down() in s.comment.down());
                else if(q.comparator == SmartQuery.ComparatorType.NOT_CONTAINS)
                    return !(q.value.get_string ().down() in s.comment.down());
                break;
            case Noise.SmartQuery.FieldType.GENRE:
                if(q.comparator == SmartQuery.ComparatorType.IS)
                    return q.value.get_string ().down() == s.genre.down();
                else if(q.comparator == SmartQuery.ComparatorType.CONTAINS)
                    return (q.value.get_string ().down() in s.genre.down());
                else if(q.comparator == SmartQuery.ComparatorType.NOT_CONTAINS)
                    return !(q.value.get_string ().down() in s.genre.down());
                break;
            case Noise.SmartQuery.FieldType.GROUPING:
                if(q.comparator == SmartQuery.ComparatorType.IS)
                    return q.value.get_string ().down() == s.grouping.down();
                else if(q.comparator == SmartQuery.ComparatorType.CONTAINS)
                    return (q.value.get_string ().down() in s.grouping.down());
                else if(q.comparator == SmartQuery.ComparatorType.NOT_CONTAINS)
                    return !(q.value.get_string ().down() in s.grouping.down());
                break;
            case Noise.SmartQuery.FieldType.TITLE:
                if(q.comparator == SmartQuery.ComparatorType.IS)
                    return q.value.get_string ().down() == s.title.down();
                else if(q.comparator == SmartQuery.ComparatorType.CONTAINS)
                    return (q.value.get_string ().down() in s.title.down());
                else if(q.comparator == SmartQuery.ComparatorType.NOT_CONTAINS)
                    return !(q.value.get_string ().down() in s.title.down());
                break;
            case Noise.SmartQuery.FieldType.BITRATE:
                if(q.comparator == SmartQuery.ComparatorType.IS_EXACTLY)
                    return q.value.get_int () == s.bitrate;
                else if(q.comparator == SmartQuery.ComparatorType.IS_AT_MOST)
                    return (s.bitrate <= q.value.get_int ());
                else if(q.comparator == SmartQuery.ComparatorType.IS_AT_LEAST)
                    return (s.bitrate >= q.value.get_int ());
                break;
            case Noise.SmartQuery.FieldType.PLAYCOUNT:
                if(q.comparator == SmartQuery.ComparatorType.IS_EXACTLY)
                    return q.value.get_int () == s.play_count;
                else if(q.comparator == SmartQuery.ComparatorType.IS_AT_MOST)
                    return (s.play_count <= q.value.get_int ());
                else if(q.comparator == SmartQuery.ComparatorType.IS_AT_LEAST)
                    return (s.play_count >= q.value.get_int ());
                break;
            case Noise.SmartQuery.FieldType.SKIPCOUNT:
                if(q.comparator == SmartQuery.ComparatorType.IS_EXACTLY)
                    return q.value.get_int () == s.skip_count;
                else if(q.comparator == SmartQuery.ComparatorType.IS_AT_MOST)
                    return (s.skip_count <= q.value.get_int ());
                else if(q.comparator == SmartQuery.ComparatorType.IS_AT_LEAST)
                    return (s.skip_count >= q.value.get_int ());
                break;
            case Noise.SmartQuery.FieldType.YEAR:
                if(q.comparator == SmartQuery.ComparatorType.IS_EXACTLY)
                    return q.value.get_int () == s.year;
                else if(q.comparator == SmartQuery.ComparatorType.IS_AT_MOST)
                    return (s.year <= q.value.get_int ());
                else if(q.comparator == SmartQuery.ComparatorType.IS_AT_LEAST)
                    return (s.year >= q.value.get_int ());
                break;
            case Noise.SmartQuery.FieldType.LENGTH:
                if(q.comparator == SmartQuery.ComparatorType.IS_EXACTLY)
                    return q.value.get_int () == s.length;
                else if(q.comparator == SmartQuery.ComparatorType.IS_AT_MOST)
                    return (s.length <= q.value.get_int ());
                else if(q.comparator == SmartQuery.ComparatorType.IS_AT_LEAST)
                    return (s.length >= q.value.get_int ());
                break;
            case Noise.SmartQuery.FieldType.RATING:
                if(q.comparator == SmartQuery.ComparatorType.IS_EXACTLY)
                    return q.value.get_int () == s.rating;
                else if(q.comparator == SmartQuery.ComparatorType.IS_AT_MOST)
                    return (s.rating <= q.value.get_int ());
                else if(q.comparator == SmartQuery.ComparatorType.IS_AT_LEAST)
                    return (s.rating >= q.value.get_int ());
                break;
            case Noise.SmartQuery.FieldType.DATE_ADDED:
                var now = new DateTime.now_local ();
                var played = new DateTime.from_unix_local (s.date_added);
                played = played.add_days (q.value.get_int ());
            
                if (q.comparator == SmartQuery.ComparatorType.IS_EXACTLY) {
                    return (now.get_day_of_year () == played.get_day_of_year () && now.get_year () == played.get_year ());
                } else if (q.comparator == SmartQuery.ComparatorType.IS_WITHIN) {
                    return played.compare (now) > 0;
                } else if (q.comparator == SmartQuery.ComparatorType.IS_BEFORE) {
                    return now.compare (played) > 0;
                }
                break;
            case Noise.SmartQuery.FieldType.LAST_PLAYED:
                if(s.last_played == 0)
                    return false;

                var now = new DateTime.now_local();
                var played = new DateTime.from_unix_local (s.last_played);
                played = played.add_days (q.value.get_int ());

                if (q.comparator == SmartQuery.ComparatorType.IS_EXACTLY) {
                    return (now.get_day_of_year () == played.get_day_of_year () && now.get_year () == played.get_year ());
                } else if (q.comparator == SmartQuery.ComparatorType.IS_WITHIN) {
                    return played.compare (now) > 0;
                } else if (q.comparator == SmartQuery.ComparatorType.IS_BEFORE) {
                    return now.compare (played) > 0;
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
