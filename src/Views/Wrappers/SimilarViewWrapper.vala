// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012 Noise Developers (http://launchpad.net/noise)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Scott Ringwelski <sgringwe@mtu.edu>
 *              Victor Eduardo <victoreduardm@gmail.com>
 */

public class BeatBox.SimilarViewWrapper : ViewWrapper {

    private const int REQUIRED_MEDIA = 10;

    private Media base_media;

    public SimilarViewWrapper (LibraryWindow lw) {
        base (lw, Hint.SIMILAR);

        var tvs = lw.lm.similar_setup;

        // Add list view
        list_view = new ListView (this, tvs);

        // Add alert
        embedded_alert = new Granite.Widgets.EmbeddedAlert();

        set_default_alert ();

		// Refresh view layout
		pack_views ();

        // Connect data signals
        lm.media_played.connect (on_media_played);
        lm.lfm.similar_retrieved.connect (similar_retrieved);
    }

    /**
     * Avoid fetching if the user is playing the queried results
     * '!is_current_wrapper' wouldn't work since at this point the user could be
     * clicking the NEXT and PREVIOUS buttons without having selected/played a song
     * in the result list. We want to keep searching for similar songs until that
     * happens.
     */
    private bool should_update_media () {
        return !(list_view as ListView).get_is_current_list ();
    }

    private void on_media_played (Media new_media) {
        if (!has_list_view)
            return;

        if (should_update_media ()) {
            base_media = new_media;

            if (base_media != null) {
                // Say we're fetching media
                embedded_alert.set_alert (_("Fetching similar songs"), _("Finding songs similar to %s by %s").printf ("<b>" + String.escape (base_media.title) + "</b>", "<b>" + String.escape (base_media.artist) + "</b>"), null, false, Gtk.MessageType.INFO);
            }
            else {
                // Base media is null, so show the proper warning. As this happens often, tell
                // the users more about this view instead of scaring them away
                set_default_alert ();
            }

            // Show the alert box
            set_active_view (ViewType.ALERT);
        }
    }

    private void similar_retrieved (Gee.Collection<int> similar_internal, Gee.Collection<Media> similar_external) {
        if (should_update_media ()) {
            set_media_from_ids (similar_internal);
        }
    }

    public void save_playlist () {
        if (base_media == null) {
            warning ("User tried to save similar playlist, but there is no base media\n");
            return;
        }

        var p = new Playlist();
        p.name = _("Similar to %s").printf (base_media.title);

        var to_add = new Gee.LinkedList<Media>();

        foreach (Media m in list_view.get_media ()) {
            to_add.add (m);
        }

        p.add_media (to_add);

        lm.add_playlist (p);
        lw.addSideListItem (p);
    }

    protected override bool check_have_media () {
        /* Check if the view is the current list and there's enough media */
        if (media_count >= REQUIRED_MEDIA || !has_embedded_alert) {
            select_proper_content_view ();
            return true;
        }

        /* At this point, there's no media (we couldn't find enough) and there's obviously
         * an embedded alert widget available. If not, set_active_view() will sort it out.
         */
        if (base_media != null) {
            /* say we could not find similar media */
            embedded_alert.set_alert (_("No similar songs found"), _("%s could not find songs similar to %s by %s in your music library. Make sure all song info is correct and you are connected to the Internet. Some songs may not have matches.").printf (String.escape (lw.app.get_name ()), "<b>" + String.escape (base_media.title) + "</b>", "<b>" + String.escape (base_media.artist) + "</b>"), null, true, Gtk.MessageType.INFO);
        }

        /* Show the alert box */
        set_active_view (ViewType.ALERT);

        return false;
    }

    private inline void set_default_alert () {
        if (!has_embedded_alert)
            return;

        embedded_alert.set_alert (_("Similar Song View"), _("In this view, %s will automatically find songs similar to the one you're playing. You can then start playing those songs, or save them as a playlist for later.").printf (String.escape (lw.app.get_name ())), null, true, Gtk.MessageType.INFO);

    }
}

