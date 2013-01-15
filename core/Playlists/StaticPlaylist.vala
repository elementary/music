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

public class Noise.StaticPlaylist : Playlist {
    public bool read_only { get; set; default=false;}
    public bool allow_duplicate { get; set; default=false;}

    public StaticPlaylist() {
        name = "";
        medias = new Gee.LinkedList<Media>();
    }

    public StaticPlaylist.with_info(int rowid, string name) {
        this.rowid = rowid;
        this.name = name;
        medias = new Gee.LinkedList<Media>();
    }

    public override void add_media (Media m) {
        var added_media = new Gee.LinkedList<Media> ();
        
        if (m != null && (allow_duplicate == true || !medias.contains (m))) {
            medias.add (m);
            added_media.add (m);
            media_added (added_media);
        }
        updated ();
    }

    public override void add_medias (Gee.Collection<Media> to_add) {
        var added_media = new Gee.LinkedList<Media> ();
        
        foreach (Media m in to_add) {
            if (m != null && (allow_duplicate == true || !medias.contains (m))) {
                medias.add (m);
                added_media.add (m);
            }
        }
        
        updated ();
        media_added (added_media);
    }

    public override void remove_media (Media to_remove) {
        if (to_remove != null && medias.contains (to_remove)) {
            var removed_media = new Gee.LinkedList<Media> ();
            removed_media.add (to_remove);
            medias.remove (to_remove);
            media_removed (removed_media);
        }
        updated ();
    }

    public override void remove_medias (Gee.Collection<Media> to_remove) {
        var removed_media = new Gee.LinkedList<Media> ();
        foreach (var m in to_remove) {
            if (m != null && medias.contains (m)) {
                removed_media.add (m);
                medias.remove (m);
            }
        }
        updated ();
        media_removed (removed_media);
    }

    public override void clear() {
        medias.clear ();
        cleared ();
        updated ();
    }
}
