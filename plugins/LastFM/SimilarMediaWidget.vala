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
 * Authored by: Corentin Noël <corentin@elementary.io>
 */

public class Noise.SimilarMediasWidget : Gtk.Grid {
    public LastFM.Core lfm;

    private Gtk.ScrolledWindow scroll;
    private LoveBanButtons love_ban_buttons;
    private SimilarMediasView ssv;
    bool similars_fetched;

    public SimilarMediasWidget (LastFM.Core core) {
        ssv = new SimilarMediasView();
        lfm = core;
        
        similars_fetched = false;
        
        // Last.fm
        lfm.similar_retrieved.connect (similar_retrieved);
        
        App.main_window.update_media_info.connect ((m) => {
            lfm.fetchCurrentSimilarSongs ();
        });
        App.player.changing_player.connect ((m) => {
            similars_fetched = false;
            update_visibilities ();
        });
        
        love_ban_buttons = new LoveBanButtons ();
        // put treeview inside scrolled window
        scroll = new Gtk.ScrolledWindow (null, null);
        scroll.set_policy (Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
        scroll.add (ssv);
        scroll.set_hexpand (true);
        scroll.set_vexpand (true);

        this.attach (love_ban_buttons, 0, 0, 1, 1);
        this.attach (scroll, 0, 1, 1, 1);
        
        App.main_window.info_panel.add_view (this);
        show_all ();
        update_visibilities ();
        
        App.main_window.info_panel.to_update.connect (update_visibilities);

        love_ban_buttons.changed.connect (love_ban_buttons_changed);
    }
    
    private void update_visibilities() {
        var lastfm_elements_visible = LastFM.Core.get_default ().is_initialized;

        love_ban_buttons.set_no_show_all (!lastfm_elements_visible);
        love_ban_buttons.set_visible (lastfm_elements_visible);

        scroll.set_no_show_all (!similars_fetched);
        if (similars_fetched)
            scroll.show_all ();
        else
            scroll.hide ();
    }
    
    private void similar_retrieved (Gee.LinkedList<int> similar_internal, Gee.LinkedList<Media> similar_external) {
        update_similar_list(similar_external);
    }

    public void update_similar_list (Gee.Collection<Media> media) {
        if (media.size > 8) {
            similars_fetched = true;
            ssv.populateView (media);
        }
        
        update_visibilities ();
    }

    private void love_ban_buttons_changed () {
        if (App.player.current_media == null)
            return;

        var title = App.player.current_media.title;
        var artist = App.player.current_media.artist;

        if (love_ban_buttons.mode == LoveBanButtons.Mode.LOVE)
            lfm.loveTrack (title, artist);
        else if (love_ban_buttons.mode == LoveBanButtons.Mode.BAN)
            lfm.banTrack (title, artist);
    }
}
