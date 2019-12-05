// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012-2018 elementary LLC. (https://elementary.io)
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
 * The Music authors hereby grant permission for non-GPL compatible
 * GStreamer plugins to be used and distributed together with GStreamer
 * and Music. This permission is above and beyond the permissions granted
 * by the GPL license by which Music is covered. If you modify this code
 * you may extend this exception to your version of the code, but you are not
 * obligated to do so. If you do not wish to do so, delete this exception
 * statement from your version.
 *
 * Authored by: Corentin Noël <corentin@elementary.io>
 */

public abstract class Music.Library : GLib.Object {

    /*
     * Signals
     */

    public signal void file_operations_started ();
    public signal void file_operations_done ();

    public signal void media_added (Gee.Collection<Media> medias);
    public signal void media_updated (Gee.Collection<Media> medias);
    public signal void media_removed (Gee.Collection<Media> medias);
    public signal void media_imported (Gee.Collection<Media> medias); // Only sent at the end of import.
    public signal void search_finished ();

    public signal void playlist_added (StaticPlaylist playlist);
    public signal void playlist_name_updated (StaticPlaylist playlist);
    public signal void playlist_removed (StaticPlaylist playlist);

    public signal void smartplaylist_added (SmartPlaylist smartplaylist);
    public signal void smartplaylist_name_updated (SmartPlaylist smartplaylist);
    public signal void smartplaylist_removed (SmartPlaylist smartplaylist);

    public abstract void initialize_library ();
    public abstract void add_files_to_library (Gee.Collection<string> files);

    public abstract Gee.Collection<Media> get_medias ();
    public abstract Gee.Collection<StaticPlaylist> get_playlists ();
    public abstract Gee.Collection<SmartPlaylist> get_smart_playlists ();

    public abstract void search_medias (string search);
    public abstract Gee.Collection<Media> get_search_result ();

    public abstract void add_media (Media s);
    public abstract void add_medias (Gee.Collection<Media> new_media);
    public abstract Media? find_media (Media to_find);
    public abstract Media? media_from_file (File file);
    public abstract Media? media_from_uri (string uri);
    public abstract Media? media_from_id (int64 id);
    public abstract Gee.Collection<Media> medias_from_uris (Gee.Collection<string> uris);
    public abstract Gee.Collection<Media> medias_from_ids (Gee.Collection<int64?> ids);
    public abstract void update_media (Media s, bool update_meta, bool record_time);
    public abstract void update_medias (Gee.Collection<Media> updates, bool update_meta, bool record_time);
    public abstract void remove_media (Media s, bool trash);
    public abstract void remove_medias (Gee.Collection<Media> to_remove, bool trash);

    public abstract bool support_smart_playlists ();
    public abstract void add_smart_playlist (SmartPlaylist p);
    public abstract void remove_smart_playlist (int64 id);
    public abstract SmartPlaylist? smart_playlist_from_id (int64 id);
    public abstract SmartPlaylist? smart_playlist_from_name (string name);

    public abstract bool support_playlists ();
    public abstract void add_playlist (StaticPlaylist p);
    public abstract void remove_playlist (int64 id);
    public abstract StaticPlaylist? playlist_from_id (int64 id);
    public abstract StaticPlaylist? playlist_from_name (string name);

    public abstract bool start_file_operations (string? message);
    public abstract bool doing_file_operations ();
    public abstract void finish_file_operations ();

    public int playlist_count_without_read_only () {
        int i = 0;
        foreach (var p in get_playlists ()) {
            if (p.read_only == false)
                i++;
        }
        return i;
    }

    public void media_from_name (Gee.Collection<Media> tests, Gee.Collection<int64?> found, Gee.Collection<Media> not_found) {
        foreach (Media test in tests) {
            var media_found = find_media (test);
            if (media_found != null) {
                found.add (media_found.rowid);
            } else {
                not_found.add (test);
            }
        }
    }
}
