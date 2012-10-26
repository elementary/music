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

public class Noise.HistoryViewWrapper : ViewWrapper {

    public HistoryViewWrapper (LibraryWindow lw) {
        base (lw, Hint.HISTORY);
        build_async.begin ();
    }

    private async void build_async () {
        var tvs = lw.library_manager.history_setup;

        list_view = new ListView (this, tvs);
        embedded_alert = new Granite.Widgets.EmbeddedAlert ();

        // Refresh view layout
        pack_views ();

        yield set_media_async (App.player.already_played ());
        connect_data_signals ();
    }

    protected override void set_no_media_alert () {
        embedded_alert.set_alert (_("No songs in History"), _("After a part of a song has been played, it is added to the history list.\nYou can use this list to see all the songs you have played during the current session."), null, true, Gtk.MessageType.INFO);

    }

    private void connect_data_signals () {
         App.player.history_changed.connect (on_history_changed);

         lm.media_updated.connect (on_library_media_updated);
         lm.media_removed.connect (on_library_media_removed);
    }

    private async void on_history_changed () {
        yield set_media_async (App.player.already_played ());
    }

    private async void on_library_media_updated (Gee.Collection<int> ids) {
        yield update_media_async (lm.media_from_ids (ids));
    }

    private async void on_library_media_removed (Gee.Collection<int> ids) {
        yield remove_media_async (lm.media_from_ids (ids));
    }
}

