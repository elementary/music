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
    public static const int MAX_FETCHED = 20;

    bool working;

    public Noise.StaticPlaylist similar_playlist;
    private Gee.LinkedList<Noise.Media> similar_medias;

    public signal void similar_retrieved (Gee.LinkedList<int> similarIDs, Gee.LinkedList<Noise.Media> similarDont);

    public class SimilarMedias () {
        working = false;
        similar_medias = new Gee.LinkedList<Noise.Media> ();
        similar_playlist = new Noise.StaticPlaylist ();
        similar_playlist.name = _("Similar");
        similar_playlist.read_only = true;
        similar_playlist.show_badge = true;
        try {
            similar_playlist.icon = GLib.Icon.new_for_string ("playlist-similar");
        } catch (GLib.Error e) {
            critical (e.message);
        }
        
        Noise.App.player.changing_player.connect ((m)=>{
            lock (similar_medias) {
                similar_medias.clear ();
            }
            lock (similar_playlist) {
                similar_playlist.clear ();
            }
        });
    }
    
    public virtual void queryForSimilar (Noise.Media s) {
        
        if (!working) {
            working = true;
            
            similar_async (s);
        }
    }
    
    public void similar_async (Noise.Media s) {
        debug ("In the similar thread");
        var similarIDs = new Gee.LinkedList<int> ();
        var similarDont = new Gee.LinkedList<Noise.Media> ();
        
        similar_medias.add_all (Core.get_default ().getSimilarTracks (s.title, s.artist));
        lock (similar_medias) {
            Noise.libraries_manager.local_library.media_from_name (similar_medias, similarIDs, similarDont);
        }
        similarIDs.offer_head (s.rowid);
        
        similar_playlist.add_medias (Noise.libraries_manager.local_library.medias_from_ids (similarIDs));
        similar_retrieved (similarIDs, similarDont);
        working = false;
    }
    
}
