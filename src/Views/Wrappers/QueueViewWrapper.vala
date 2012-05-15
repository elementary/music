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
 * Authored by: Victor Eduardo <victoreduardm@gmail.com>
 */

using Gtk;
using Gee;

/**
 * Used for play queue
 */

public class BeatBox.QueueViewWrapper : ViewWrapper {

    public QueueViewWrapper (LibraryWindow lw, TreeViewSetup tvs) {
        base (lw, tvs, -1);

        if (tvs != null) {
            // Add list view and column browser
            list_view = new ListView (this, tvs);

            // Alert box
            embedded_alert = new Granite.Widgets.EmbeddedAlert ();            

    		// Refresh view layout
    		pack_views ();

            connect_data_signals ();
        }

    }

    private void connect_data_signals () {
         // Listen for queues and unqueues
         lm.media_queued.connect (on_media_queued);
         lm.media_unqueued.connect (on_media_unqueued);
         
         // TODO: listen for media updates?
    }

    private void on_media_queued (Gee.Collection<Media> queued) {
        add_media (queued);
    }

    private void on_media_unqueued (Gee.Collection<Media> unqueued) {
        remove_media (unqueued);
    }

    protected override bool check_have_media () {
        debug ("check_have_media");

        bool have_media = media_count > 0;

        if (have_media) {
            select_proper_content_view ();
            return true;
        }

        // show alert if there's no media
        if (has_embedded_alert) {
            embedded_alert.set_alert (_("No songs in Queue"), _("To add songs to the queue, use the <b>secondary click</b> on an item and choose <b>Queue</b>. When a song finishes, the queued songs will be played first before the next song in the currently playing list."), null, true, Granite.AlertLevel.INFO);

            // Switch to alert box
            set_active_view (ViewType.ALERT);
        }

        return false;
    }

}
