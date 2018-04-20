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
 * The Noise authors hereby grant permission for non-GPL compatible
 * GStreamer plugins to be used and distributed together with GStreamer
 * and Noise. This permission is above and beyond the permissions granted
 * by the GPL license by which Noise is covered. If you modify this code
 * you may extend this exception to your version of the code, but you are not
 * obligated to do so. If you do not wish to do so, delete this exception
 * statement from your version.
 *
 * Authored by: Corentin Noël <corentin@elementary.io>,
 *              Scott Ringwelski <sgringwe@mtu.edu>
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

        Noise.App.player.changing_player.connect ((m) => {
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
