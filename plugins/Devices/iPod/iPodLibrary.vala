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
 * Authored by: Corentin Noël <tintou@mailoo.org>
 */


public class Noise.Plugins.iPodLibrary : Noise.Library {
    private unowned GPod.iTunesDB db;
    
    public iPodLibrary (GPod.iTunesDB db) {
        this.db = db;
    }
    
    public override void initialize_library () {
    
    }
    public override void add_files_to_library (Gee.Collection<string> files) {
    
    }
    
    public override Gee.Collection<Media> get_medias () {
        return new Gee.LinkedList<Media> ();
    }
    public override Gee.Collection<StaticPlaylist> get_playlists () {
        return new Gee.LinkedList<StaticPlaylist> ();
    }
    public override Gee.Collection<SmartPlaylist> get_smart_playlists () {
        return new Gee.LinkedList<SmartPlaylist> ();
    }
    
    public override void add_media (Media s) {
    
    }
    public override void add_medias (Gee.Collection<Media> new_media) {
    
    }
    public override Media? media_from_id (int id) {
        return null;
    }
    public override Gee.Collection<Media> medias_from_ids (Gee.Collection<int> ids) {
        return new Gee.LinkedList<Media> ();
    }
    public override Media? find_media (Media to_find) {
        return null;
    }
    public override Media? media_from_file (File file) {
        return null;
    }
    public override Media? media_from_uri (string uri) {
        return null;
    }
    public override void update_media (Media s, bool updateMeta, bool record_time) {
    
    }
    public override void update_medias (Gee.Collection<Media> updates, bool updateMeta, bool record_time) {
    
    }
    public override void remove_media (Media s, bool trash) {
    
    }
    public override void remove_medias (Gee.Collection<Media> toRemove, bool trash) {
    
    }
    
    public override void add_smart_playlist (SmartPlaylist p) {
    
    }
    public override void remove_smart_playlist (int id) {
    
    }
    public override SmartPlaylist? smart_playlist_from_id (int id) {
        return null;
    }
    public override SmartPlaylist? smart_playlist_from_name (string name) {
        return null;
    }
    
    public override void add_playlist (StaticPlaylist p) {
    
    }
    public override void remove_playlist (int id) {
    
    }
    public override StaticPlaylist? playlist_from_id (int id) {
        return null;
    }
    public override StaticPlaylist? playlist_from_name (string name) {
        return null;
    }
    
    public override bool start_file_operations (string? message) {
        return true;
    }
    public override bool doing_file_operations () {
        return true;
    }
    public override void finish_file_operations () {
    
    }
    public override void cancel_operations () {
    
    }
}
