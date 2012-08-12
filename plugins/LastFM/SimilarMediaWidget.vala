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
    
    private Gtk.Button love_button;
    private Gtk.Button ban_button;
    private Noise.MediaInfo media_info;
    
    private SimilarMediasView ssv;
    
    bool similars_fetched;
    bool scrobbled_track;
    
    public SimilarMediasWidget (Noise.LibraryManager lm, LastFM.Core core) {
        this.lm = lm;
        this.lw = lm.lw;
        ssv = new SimilarMediasView(lm, lm.lw);
        lfm = core;
        
        similars_fetched = false;
        scrobbled_track = false;
        
        // Last.fm
        lfm.logged_in.connect (logged_in_to_lastfm);
        lfm.similar_retrieved.connect (similar_retrieved);
        lw.media_half_played.connect (() => {
            scrobbled_track = true;
            lfm.postScrobbleTrack ();
        });
        lw.update_media_info.connect (() => {
            lfm.fetchCurrentSimilarSongs();
            lfm.fetchCurrentAlbumInfo();
            lfm.fetchCurrentArtistInfo();
            lfm.fetchCurrentTrackInfo();
            lfm.postNowPlaying();
        });
        
        love_button = new Gtk.Button ();
        love_button.set_image (Icons.LASTFM_LOVE.render_image (Gtk.IconSize.MENU));
        love_button.halign = Gtk.Align.CENTER;
        ban_button = new Gtk.Button ();
        ban_button.set_image (Icons.LASTFM_BAN.render_image (Gtk.IconSize.MENU));
        ban_button.halign = Gtk.Align.CENTER;
        
        var buttons = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
        buttons.pack_start (love_button, false, false, 0);
        buttons.pack_end (ban_button, false, false, 0);
        buttons.halign = Gtk.Align.CENTER;
        
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
        
        this.attach (buttons, 0, 0, 1, 1);
        this.attach (scroll, 0, 1, 1, 1);
        
        lw.info_panel.add_view (this);
        show_all ();
        
        lw.info_panel.to_update.connect (update_visibilities);
        love_button.clicked.connect (love_button_clicked);
        ban_button.clicked.connect (ban_button_clicked);
        lm.dbu.periodical_save.connect (do_periodical_save);
    }
    
    private void update_visibilities() {
        var lastfm_settings = new LastFM.Settings ();
        var lastfm_elements_visible = lastfm_settings.session_key != "";

        love_button.set_no_show_all (!lastfm_elements_visible);
        ban_button.set_no_show_all (!lastfm_elements_visible);

        love_button.set_visible (lastfm_elements_visible);
        ban_button.set_visible (lastfm_elements_visible);

        scroll.set_no_show_all (!similars_fetched);
        if (similars_fetched)
            scroll.show_all ();
        else
            scroll.hide ();
    }
    
    private void do_periodical_save () {
        /*lm.dbm.save_artists((Noise.ArtistInfo)lfm.artists());
        lm.dbm.save_albums(lfm.albums());
        lm.dbm.save_tracks(lfm.tracks());*/
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
    
    
    private void love_button_clicked() {
        if (App.player.media_info == null || App.player.media_info.media == null)
            return;

        lfm.loveTrack(App.player.media_info.media.title, App.player.media_info.media.artist);
    }

    private void ban_button_clicked() {
        if (App.player.media_info == null || App.player.media_info.media == null)
            return;

        lfm.banTrack(App.player.media_info.media.title, App.player.media_info.media.artist);
    }
    
    public virtual void media_played(Media m) {
        
    }

}
