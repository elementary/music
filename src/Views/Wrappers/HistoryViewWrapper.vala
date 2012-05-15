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

public class BeatBox.HistoryViewWrapper : ViewWrapper {

    public HistoryViewWrapper (LibraryWindow lw, TreeViewSetup tvs) {
        base (lw, tvs, -1);

        if (tvs != null) {
            // Add list view and column browser
            list_view = new ListView (this, tvs, false);

            // Alert box
            embedded_alert = new Granite.Widgets.EmbeddedAlert ();            

    		// Refresh view layout
    		pack_views ();

            connect_data_signals ();
        }

    }

    private void connect_data_signals () {
         // Listen for queues and unqueues
         lm.history_changed.connect (on_history_changed);
         
         // FIXME: connect to lm.media_updated ?
    }

    private void on_history_changed () {
        set_media (lm.already_played ());
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
            embedded_alert.set_alert (_("No songs in History"), _("After a part of a song has been played, it is added to the history list.\nYou can use this list to see all the songs you have played during the current session."), null, true, Granite.AlertLevel.INFO);

            // Switch to alert box
            set_active_view (ViewType.ALERT);
        }

        return false;
    }

}
