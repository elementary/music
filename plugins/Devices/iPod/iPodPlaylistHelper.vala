/*-
 * Copyright (c) 2012 Noise Developers
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

public class Noise.Plugins.iPodPlaylistHelper {
    public static GPod.Playlist get_gpod_playlist_from_playlist (Noise.Playlist pl, Gee.HashMap<unowned GPod.Track, Noise.Media> library, GPod.iTunesDB db) {
        var rv = new GPod.Playlist (pl.name, false);
        rv.itdb = db;
        int32 index = 0;
        foreach (var m in pl.medias) {
            foreach (var entry in library.entries) {
                if (entry.value == m) {
                    rv.add_track (entry.key, index);
                    index++;
                    break;
                }
            }
        }

        return rv;
    }

    public static Gee.Collection<unowned GPod.Track> get_gpod_tracks_from_medias (Gee.Collection<Media> medias, Gee.HashMap<unowned GPod.Track, Noise.Media> library) {
        var list = new Gee.LinkedList <unowned GPod.Track> ();
        foreach (var m in medias) {
            foreach (var entry in library.entries) {
                if (entry.value == m) {
                    list.add (entry.key);
                    break;
                }
            }
        }

        return list;
    }

    public static Noise.Playlist? get_playlist_from_gpod_playlist (GPod.Playlist pl, Gee.HashMap<unowned GPod.Track, Noise.Media> library) {
        if (pl.is_spl) {
            
        } else if (pl.is_podcasts () == false && pl.is_audiobooks () == false && pl.is_mpl() == false) {
            var playlist = new StaticPlaylist.with_info (0, pl.name);
            foreach (var track in pl.members) {
                playlist.add_media (library.get (track));
            }

            return playlist;
        }

        return null;
    }

    public static GPod.Playlist get_gpod_playlist_from_smart_playlist (Noise.SmartPlaylist pl) {
        var rv = new GPod.Playlist (pl.name, false);
        set_properties_from_smart_playlist (rv, pl);
        return rv;
    }

    // TODO: FIXME from sort_column to sort_column_id
    /*private static GPod.PlaylistSortOrder get_gpod_sortorder_from_tvs (Noise.TreeViewSetup tvs) {
        if (tvs.sort_column == "#")
            return GPod.PlaylistSortOrder.MANUAL;
        else if (tvs.sort_column == "Track" || tvs.sort_column == "Episode")
            return GPod.PlaylistSortOrder.TRACK_NR;
        else if (tvs.sort_column == "Title" || tvs.sort_column == "Name")
            return GPod.PlaylistSortOrder.TITLE;
        else if (tvs.sort_column == "Length")
            return GPod.PlaylistSortOrder.TIME;
        else if (tvs.sort_column == "Artist")
            return GPod.PlaylistSortOrder.ARTIST;
        else if (tvs.sort_column == "Album")
            return GPod.PlaylistSortOrder.ALBUM;
        else if (tvs.sort_column == "Genre")
            return GPod.PlaylistSortOrder.GENRE;
        else if (tvs.sort_column == "Bitrate")
            return GPod.PlaylistSortOrder.BITRATE;
        else if (tvs.sort_column == "Year")
            return GPod.PlaylistSortOrder.YEAR;
        else if (tvs.sort_column == "Date")
            return GPod.PlaylistSortOrder.RELEASE_DATE;
        else if (tvs.sort_column == "Date Added")
            return GPod.PlaylistSortOrder.TIME_ADDED;
        else if (tvs.sort_column == "Plays")
            return GPod.PlaylistSortOrder.PLAYCOUNT;
        else if (tvs.sort_column == "Last Played")
            return GPod.PlaylistSortOrder.TIME_PLAYED;
        else if (tvs.sort_column == "BPM")
            return GPod.PlaylistSortOrder.BPM;
        else if (tvs.sort_column == "Rating")
            return GPod.PlaylistSortOrder.RATING;
        else if (tvs.sort_column == "Comments")
            return GPod.PlaylistSortOrder.DESCRIPTION;
        else
            return GPod.PlaylistSortOrder.MANUAL;
    }*/

    public static void set_rule_from_smart_query (GPod.SPLRule rule, Noise.SmartQuery q) {
        message("adding rule\n");
        if (q.field == SmartQuery.FieldType.ALBUM) { // strings
            rule.field = GPod.SPLField.ALBUM;
            rule.@string = q.value;
        } else if (q.field == SmartQuery.FieldType.ARTIST) {
            rule.field = GPod.SPLField.ARTIST;
            rule.@string = q.value;
        } else if (q.field == SmartQuery.FieldType.COMPOSER) {
            rule.field = GPod.SPLField.COMPOSER;
            rule.@string = q.value;
        } else if (q.field == SmartQuery.FieldType.COMMENT) {
            rule.field = GPod.SPLField.COMMENT;
            rule.@string = q.value;
        } else if (q.field == SmartQuery.FieldType.GENRE) {
            rule.field = GPod.SPLField.GENRE;
            rule.@string = q.value;
        } else if (q.field == SmartQuery.FieldType.GROUPING) {
            rule.field = GPod.SPLField.GROUPING;
            rule.@string = q.value;
        } else if (q.field == SmartQuery.FieldType.TITLE) {
            rule.field = GPod.SPLField.SONG_NAME;
            rule.@string = q.value;
        } else if (q.field == SmartQuery.FieldType.BITRATE) { // ints
            rule.field = GPod.SPLField.BITRATE;
            rule.fromvalue = uint64.parse (q.value);
            rule.tovalue = uint64.parse (q.value);
        } else if (q.field == SmartQuery.FieldType.PLAYCOUNT) {
            rule.field = GPod.SPLField.PLAYCOUNT;
            rule.fromvalue = uint64.parse (q.value);
            rule.tovalue = uint64.parse (q.value);
        } else if (q.field == SmartQuery.FieldType.SKIPCOUNT) {
            rule.field = GPod.SPLField.SKIPCOUNT;
            rule.fromvalue = uint64.parse (q.value);
            rule.tovalue = uint64.parse (q.value);
        } else if (q.field == SmartQuery.FieldType.YEAR) {
            rule.field = GPod.SPLField.YEAR;
            rule.fromvalue = uint64.parse (q.value);
            rule.tovalue = uint64.parse (q.value);
        } else if (q.field == SmartQuery.FieldType.LENGTH) {
            rule.field = GPod.SPLField.TIME;
            rule.fromvalue = uint64.parse (q.value) * 1000;
            rule.tovalue = uint64.parse (q.value) * 1000;
        } else if (q.field == SmartQuery.FieldType.RATING) {
            rule.field = GPod.SPLField.RATING;
            rule.fromvalue = uint64.parse (q.value) * 20;
            rule.tovalue = uint64.parse (q.value) * 20;
        } else if (q.field == SmartQuery.FieldType.DATE_ADDED) {
            rule.field = GPod.SPLField.DATE_ADDED;
            rule.fromvalue = uint64.parse (q.value) * 1000;
            rule.tovalue = uint64.parse (q.value) * 1000;
        } else if (q.field == SmartQuery.FieldType.LAST_PLAYED) {
            rule.field = GPod.SPLField.LAST_PLAYED;
            rule.fromvalue = uint64.parse (q.value) * 20;
            rule.tovalue = uint64.parse (q.value) * 20;
        } else if (q.field == SmartQuery.FieldType.DATE_RELEASED) {
            // no equivalant
        }
/*
        else if (q.field == SmartQuery.FieldType.MEDIA_TYPE) {
            rule.field = GPod.SPLField.VIDEO_KIND;
            if (q.value == "0") {
                rule.fromvalue = (uint64)GPod.MediaType.AUDIO;
                rule.tovalue = (uint64)GPod.MediaType.AUDIO;
            } else if (q.value == "1") {
                rule.fromvalue = (uint64)GPod.MediaType.PODCAST;
                rule.tovalue = (uint64)GPod.MediaType.PODCAST;
            } else if (q.value == "2") {
                rule.fromvalue = (uint64)GPod.MediaType.AUDIOBOOK;
                rule.tovalue = (uint64)GPod.MediaType.AUDIOBOOK;
            }
        }
*/
        rule.tounits = 1;

        // set action type
        if (q.comparator == SmartQuery.ComparatorType.IS) {
            rule.action = GPod.SPLAction.IS_STRING;
        } else if (q.comparator == SmartQuery.ComparatorType.IS_NOT) {
            rule.action = GPod.SPLAction.IS_NOT_INT;
        } else if (q.comparator == SmartQuery.ComparatorType.CONTAINS) {
            rule.action = GPod.SPLAction.CONTAINS;
        } else if (q.comparator == SmartQuery.ComparatorType.NOT_CONTAINS) {
            rule.action = GPod.SPLAction.DOES_NOT_CONTAIN;
        } else if (q.comparator == SmartQuery.ComparatorType.IS_EXACTLY) {
            rule.action = GPod.SPLAction.IS_INT;
        } else if (q.comparator == SmartQuery.ComparatorType.IS_AT_MOST) {
            rule.action = GPod.SPLAction.IS_NOT_GREATER_THAN;
        } else if (q.comparator == SmartQuery.ComparatorType.IS_AT_LEAST) {
            rule.action = GPod.SPLAction.IS_NOT_LESS_THAN;
        } else if (q.comparator == SmartQuery.ComparatorType.IS_WITHIN) {
            rule.action = GPod.SPLAction.IS_GREATER_THAN;
        } else if (q.comparator == SmartQuery.ComparatorType.IS_BEFORE) {
            rule.action = GPod.SPLAction.IS_LESS_THAN;
        }
    }

    public static void set_properties_from_smart_playlist (GPod.Playlist rv, Noise.SmartPlaylist sp) {
        message ("playlist is %s\n", sp.name);
        foreach (var sq in sp.get_queries ()) {
            rv.splr_add_new(-1);
            unowned GPod.SPLRule? rule = rv.splrules.rules.nth_data(rv.splrules.rules.length() - 1);
            message ("adding rule\n");
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
                rule.fromvalue = uint64.parse (value);
                rule.tovalue = uint64.parse (value);
                rule.tounits = 1;
                rule.fromunits = 1;
                break;
            case SmartQuery.FieldType.PLAYCOUNT:
                rule.field = GPod.SPLField.PLAYCOUNT;
                rule.fromvalue = uint64.parse (value);
                rule.tovalue = uint64.parse (value);
                rule.tounits = 1;
                rule.fromunits = 1;
                break;
            case SmartQuery.FieldType.SKIPCOUNT:
                rule.field = GPod.SPLField.SKIPCOUNT;
                rule.fromvalue = uint64.parse (value);
                rule.tovalue = uint64.parse (value);
                rule.tounits = 1;
                break;
            case SmartQuery.FieldType.YEAR:
                rule.field = GPod.SPLField.YEAR;
                rule.fromvalue = uint64.parse (value);
                rule.tovalue = uint64.parse (value);
                rule.tounits = 1;
                rule.fromunits = 1;
                break;
            case SmartQuery.FieldType.LENGTH:
                rule.field = GPod.SPLField.TIME;
                rule.fromvalue = uint64.parse (value) * 1000;
                rule.tovalue = uint64.parse (value) * 1000;
                rule.tounits = 1;
                rule.fromunits = 1;
                break;
            case SmartQuery.FieldType.RATING:
                message("rating rule is %s\n", value);
                rule.field = GPod.SPLField.RATING;
                rule.fromvalue = uint64.parse (value) * 20;
                rule.tovalue = uint64.parse (value) * 20;
                rule.tounits = 1;//20;
                rule.fromunits = 1;//20;
                break;
            case SmartQuery.FieldType.DATE_ADDED:
                rule.field = GPod.SPLField.DATE_ADDED;
                rule.fromvalue = uint64.parse (value) * 60 * 60 * 24;
                rule.tovalue = uint64.parse (value) * 60 * 60 * 24;
                rule.tounits = 1;//60 * 60 * 24;
                rule.fromunits = 1;//60 * 60 * 24;
                break;
            case SmartQuery.FieldType.LAST_PLAYED:
                rule.field = GPod.SPLField.LAST_PLAYED;
                rule.fromvalue = uint64.parse (value) * 60 * 60 * 24;
                rule.tovalue = uint64.parse (value) * 60 * 60 * 24;
                rule.tounits = 1;//60 * 60 * 24;
                rule.fromunits = 1;//60 * 60 * 24;
                break;
            case SmartQuery.FieldType.DATE_RELEASED:
                // no equivelant
                break;
/*
            case SmartQuery.FieldType.MEDIA_TYPE:
                rule.field = GPod.SPLField.VIDEO_KIND;
                if (value == "0") {
                    message ("must be song\n");
                    rule.fromvalue = 0x00000001;
                    rule.tovalue = 0x00000001;;
                } else if (value == "1") {
                    rule.fromvalue = 0x00000006;
                    rule.tovalue = 0x00000006;
                    message ("must be podcast\n");
                } else if (value == "2") {
                    rule.fromvalue = 0x00000008;
                    rule.tovalue = 0x00000008;
                }
                break;
*/            
            }

            // set action type
            if (comparator == SmartQuery.ComparatorType.IS) {
/*
                if (field == SmartQuery.FieldType.MEDIA_TYPE)
                    rule.action = GPod.SPLAction.BINARY_AND;
                else
                    rule.action = GPod.SPLAction.IS_STRING;
*/
                rule.action = GPod.SPLAction.IS_STRING;

            } else if (comparator == SmartQuery.ComparatorType.IS_NOT) {
/*
                if (field == SmartQuery.FieldType.MEDIA_TYPE)
                    rule.action = GPod.SPLAction.NOT_BINARY_AND;
                else
                    rule.action = GPod.SPLAction.IS_NOT_INT;
*/
                rule.action = GPod.SPLAction.IS_NOT_INT;
            } else if (comparator == SmartQuery.ComparatorType.CONTAINS) {
                rule.action = GPod.SPLAction.CONTAINS;
                message ("hi at contains\n");
            } else if (comparator == SmartQuery.ComparatorType.NOT_CONTAINS) {
                rule.action = GPod.SPLAction.DOES_NOT_CONTAIN;
            } else if (comparator == SmartQuery.ComparatorType.IS_EXACTLY) {
                rule.action = GPod.SPLAction.IS_INT;
            } else if (comparator == SmartQuery.ComparatorType.IS_AT_MOST) {
                rule.action = GPod.SPLAction.IS_LESS_THAN;
                rule.fromvalue += 1;
                rule.tovalue += 1;
            } else if (comparator == SmartQuery.ComparatorType.IS_AT_LEAST) {
                rule.action = GPod.SPLAction.IS_GREATER_THAN;
                rule.fromvalue -= 1;
                rule.tovalue -= 1;
            } else if (comparator == SmartQuery.ComparatorType.IS_WITHIN) {
                rule.action = GPod.SPLAction.IS_GREATER_THAN;
            } else if (comparator == SmartQuery.ComparatorType.IS_BEFORE) {
                rule.action = GPod.SPLAction.IS_LESS_THAN;
            }
            
            message ("in smartplaylist  has rule and string %s\n", rule.@string);
        }

        message ("check %d rules\n", (int)rv.splrules.rules.length ());
        rv.splpref.checkrules = (uint8)rv.splrules.rules.length ();
        rv.splpref.checklimits = (uint8)0;
        rv.splrules.match_operator = (sp.conditional == SmartPlaylist.ConditionalType.ANY) ? GPod.SPLMatch.OR : GPod.SPLMatch.AND;
        rv.splpref.liveupdate = 1;
        rv.is_spl = true;
    }
}
