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

    public HistoryViewWrapper (LibraryWindow lw) {
        base (lw, Hint.HISTORY);

        var tvs = lw.lm.history_setup;

        if (tvs != null) {
            // Add list view
            list_view = new ListView (this, tvs);

            // Alert box
            embedded_alert = new Granite.Widgets.EmbeddedAlert ();

            embedded_alert.set_alert (_("No songs in History"), _("After a part of a song has been played, it is added to the history list.\nYou can use this list to see all the songs you have played during the current session."), null, true, Gtk.MessageType.INFO);

    		// Refresh view layout
    		pack_views ();

            connect_data_signals ();
        }

    }

    private void connect_data_signals () {
         // Listen for queues and unqueues
         lm.history_changed.connect (on_history_changed);

         // Connect to lm.media_updated and lm.media_removed
         lm.media_updated.connect (on_library_media_updated);
         lm.media_removed.connect (on_library_media_removed);
    }

    private void on_history_changed () {
        set_media (lm.already_played ());
    }

    private void on_library_media_updated (Gee.Collection<int> ids) {
        update_media (lm.media_from_ids (ids));
    }

    private void on_library_media_removed (Gee.Collection<int> ids) {
        remove_media (lm.media_from_ids (ids));
    }
}

