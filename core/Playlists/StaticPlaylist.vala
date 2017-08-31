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

public class Noise.StaticPlaylist : Playlist {
    public bool read_only { get; set; default=false;}
    public bool show_badge { get; set; default=false;}
    public bool allow_duplicate { get; set; default=false;}

    public StaticPlaylist () {

    }

    public StaticPlaylist.with_info (int rowid, string name) {
        this.rowid = rowid;
        this.name = name;
    }

    construct {
        medias = new Gee.ArrayList<Media>();
        icon = new ThemedIcon ("playlist");
    }

    public override void add_media (Media m) {
        var added_media = new Gee.LinkedList<Media> ();
        if (allow_duplicate || medias.contains (m) == false) {
            medias.add (m);
            added_media.add (m);
            media_added (added_media);
        }

        updated ();
    }

    public override void add_medias (Gee.Collection<Media> to_add) {
        var added_media = new Gee.LinkedList<Media> ();
        foreach (Media m in to_add) {
            if (allow_duplicate || medias.contains (m) == false) {
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
