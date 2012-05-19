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

    public QueueViewWrapper (LibraryWindow lw) {
        base (lw, Hint.QUEUE);

        var tvs = lw.lm.queue_setup;

        // Add list view and column browser
        list_view = new ListView (this, tvs);

        // Alert box
        embedded_alert = new Granite.Widgets.EmbeddedAlert ();            

        set_default_alert ();

        // Refresh view layout
        pack_views ();

        connect_data_signals ();
    }

    private void connect_data_signals () {
         // Listen for queues and unqueues
         lm.queue_changed.connect (on_queue_changed);
         
         // Listen for media order
         (list_view as ListView).reordered.connect (on_list_reordered);
         
         // TODO: listen for media updates?
    }

    bool modifying_queue = false;

    private void on_list_reordered () {
        // Update LM queue to use the new order
        modifying_queue = true;
        lm.queue_media (list_view.get_media ());
        modifying_queue = false;
    }

    private void on_queue_changed () {
        if (modifying_queue)
            return;
        set_media (lm.queue ());
    }

    private inline void set_default_alert () {
        if (!has_embedded_alert)
            return;

        embedded_alert.set_alert (_("No songs in Queue"), _("To add songs to the queue, use the <b>secondary click</b> on an item and choose <b>Queue</b>. When a song finishes, the queued songs will be played first before the next song in the currently playing list."), null, true, Gtk.MessageType.INFO);
    }
}

