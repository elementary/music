/*-
 * Copyright (c) 2013 Corentin Noël <tintou@mailoo.org>
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

public interface Noise.LibraryManagerInterface : Object {
    public signal void file_operations_started ();
    public signal void file_operations_done ();
    public signal void progress_cancel_clicked ();

    public signal void music_counted (int count);
    public signal void music_added (Gee.Collection<string> not_imported);
    public signal void music_imported (Gee.Collection<Media> new_media, Gee.Collection<string> not_imported);
    public signal void music_rescanned (Gee.Collection<Media> new_media, Gee.Collection<string> not_imported);

    public signal void media_added (Gee.Collection<int> ids);
    public signal void media_updated (Gee.Collection<int> ids);
    public signal void media_removed (Gee.Collection<int> ids);
    
    public signal void playlist_added (StaticPlaylist playlist);
    public signal void playlist_name_updated (StaticPlaylist playlist);
    public signal void playlist_removed (StaticPlaylist playlist);
    
    public signal void smartplaylist_added (SmartPlaylist smartplaylist);
    public signal void smartplaylist_name_updated (SmartPlaylist smartplaylist);
    public signal void smartplaylist_removed (SmartPlaylist smartplaylist);
    
    public abstract void initialize_library ();
    public abstract void add_files_to_library (Gee.Collection<string> files);
}
