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

/* Merely a place holder for multiple pieces of information regarding
 * the current media playing. Mostly here because of dependence. */

public class LastFM.SimilarMedias : Object {
    public const int MAX_FETCHED = 20;

    public signal void similar_retrieved (Gee.LinkedList<int64?> similarIDs, Gee.LinkedList<Noise.Media> similarDont);

    public Noise.StaticPlaylist similar_playlist;
    private GLib.Cancellable cancellable;

    public class SimilarMedias () {
        cancellable = new GLib.Cancellable ();
        similar_playlist = new Noise.StaticPlaylist ();
        similar_playlist.name = _("Similar");
        similar_playlist.read_only = true;
        similar_playlist.show_badge = true;
        similar_playlist.icon = new GLib.ThemedIcon ("playlist-similar");

        Noise.App.player.changing_player.connect ((m)=>{
            lock (similar_playlist) {
                similar_playlist.clear ();
            }
        });
    }

    public virtual void query_for_similar (Noise.Media s) {
        if (cancellable.is_cancelled () == false) {
            cancellable.cancel ();
        }

        similar_async.begin (s);
    }
    
    public async void similar_async (Noise.Media s) {
        debug ("In the similar thread");
        cancellable.reset ();
        var similar_medias = yield Core.get_default ().get_similar_tracks (s.title, s.artist, cancellable);
        if (cancellable.is_cancelled ())
            return;

        var similarIDs = new Gee.LinkedList<int64?> ();
        var similarDont = new Gee.LinkedList<Noise.Media> ();
        Noise.libraries_manager.local_library.media_from_name (similar_medias, similarIDs, similarDont);
        if (cancellable.is_cancelled ())
            return;

        similarIDs.offer_head (s.rowid);
        var found_medias = Noise.libraries_manager.local_library.medias_from_ids (similarIDs);
        found_medias.remove (s);
        similar_playlist.add_medias (found_medias);
        similar_retrieved (similarIDs, similarDont);
    }
    
}
