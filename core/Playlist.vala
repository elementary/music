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

public class Noise.Playlist : Object {
    public Gee.LinkedList<Media> media { public get; private set; }

    public int rowid { get; set; }
    public string name { get; set; }
    public bool read_only { get; set; default=false;}
    public bool allow_duplicate { get; set; default=false;}

    public signal void media_added (Gee.Collection<Media> media);
    public signal void media_removed (Gee.Collection<Media> media);
    public signal void cleared ();

    public Playlist() {
        name = "";
        media = new Gee.LinkedList<Media>();
    }

    public Playlist.with_info(int rowid, string name) {
        this ();
        this.rowid = rowid;
        this.name = name;
    }

    public void add_media (Gee.Collection<Media> to_add) {
        var added_media = new Gee.LinkedList<Media> ();
        
        foreach (var m in to_add) {
            if (m != null && (allow_duplicate == true || !media.contains (m))) {
                media.add (m);
                added_media.add (m);
            }
        }
        
        media_added (added_media);
    }

    public void remove_media (Media to_remove) {
        if (to_remove != null && media.contains (to_remove)) {
            var removed_media = new Gee.LinkedList<Media> ();
            removed_media.add (to_remove);
            media.remove (to_remove);
            media_removed (removed_media);
        }
    }

    public void remove_medias (Gee.Collection<Media> to_remove) {
        var removed_media = new Gee.LinkedList<Media> ();
        foreach (var m in to_remove) {
            if (m != null && media.contains (m)) {
                removed_media.add (m);
                media.remove (m);
            }
        }
        media_removed (removed_media);
    }

    public bool is_empty () {
        return (media.size <= 0);
    }

    public void clear() {
        media = new Gee.LinkedList<Media> ();
        cleared ();
    }

    public bool contains (Media m) {
        return media.contains (m);
    }

}
