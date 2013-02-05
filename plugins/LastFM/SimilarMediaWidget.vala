/*-
 * Copyright (c) 2012 Corentin Noël <tintou@mailoo.org>
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

public class Noise.SimilarMediasWidget : Gtk.Grid {

    private Noise.LibraryManager lm;
    private Noise.LibraryWindow lw;

    public LastFM.Core lfm;
    
    private Gtk.ScrolledWindow scroll;
    
    private LoveBanButtons love_ban_buttons;
    private Noise.MediaInfo media_info;
    
    private SimilarMediasView ssv;
    
    bool similars_fetched;
    
    public SimilarMediasWidget (Noise.LibraryManager lm, LastFM.Core core) {
        this.lm = lm;
        this.lw = lm.lw;
        ssv = new SimilarMediasView(lm, lm.lw);
        lfm = core;
        
        similars_fetched = false;
        
        // Last.fm
        lfm.logged_in.connect (logged_in_to_lastfm);
        lfm.similar_retrieved.connect (similar_retrieved);
        lw.update_media_info.connect ((m) => {
            lfm.fetchCurrentSimilarSongs();
            lfm.fetch_album_info (m);
        });
        
        love_ban_buttons = new LoveBanButtons ();
        // put treeview inside scrolled window
        scroll = new Gtk.ScrolledWindow (null, null);
        scroll.set_policy (Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
        scroll.add (ssv);
        scroll.set_hexpand (true);
        scroll.set_vexpand (true);
        
        media_info = new MediaInfo();
        media_info.track = new TrackInfo();
        media_info.artist = new ArtistInfo();
        media_info.album = new AlbumInfo();

        this.attach (love_ban_buttons, 0, 0, 1, 1);
        this.attach (scroll, 0, 1, 1, 1);
        
        lw.info_panel.add_view (this);
        show_all ();
        
        lw.info_panel.to_update.connect (update_visibilities);

        love_ban_buttons.changed.connect (love_ban_buttons_changed);
    }
    
    private void update_visibilities() {
        var lastfm_settings = new LastFM.Settings ();
        var lastfm_elements_visible = lastfm_settings.session_key != ""; // XXX also check for conectivity state!

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
    
    private void logged_in_to_lastfm() {
        update_visibilities();
    }
    
    private void love_ban_buttons_changed () {
        if (App.player.media_info == null || App.player.media_info.media == null)
            return;

        var title = App.player.media_info.media.title;
        var artist = App.player.media_info.media.artist;

        if (love_ban_buttons.mode == LoveBanButtons.Mode.LOVE)
            lfm.loveTrack (title, artist);
        else if (love_ban_buttons.mode == LoveBanButtons.Mode.BAN)
            lfm.banTrack (title, artist);
//        else
//            lfm.removeLoveBan (title, artist); // XXX TODO need to implement this method 
    }

/* TODO: update love_ban_button's mode according to the state of the current song. Remember
        to disconnect the love_ban_buttons_changed() handler or we'll be sending that information
        over again.
    public virtual void media_played(Media m) {
        
    }
*/
}
