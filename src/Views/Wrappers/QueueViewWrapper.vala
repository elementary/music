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
         lm.queue_cleared.connect (on_queue_cleared);
         lm.media_queued.connect (on_media_queued);
         lm.media_unqueued.connect (on_media_unqueued);

         // Listen for media order
         (list_view as ListView).reordered.connect (on_list_reordered);
         
         // Connect to lm.media_updated and lm.media_removed
         lm.media_removed.connect (on_library_media_removed);
    }

    bool modifying_list_order = false;

    private void on_list_reordered () {
        // Update LM queue to use the new order
        modifying_list_order = true;
        lm.clear_queue ();
        lm.queue_media (list_view.get_media ());
        modifying_list_order = false;
    }

    private void on_queue_cleared () {
        if (modifying_list_order)
            return;
        set_media (new Gee.LinkedList<Media> ());
    }

    private void on_media_queued (Gee.Collection<Media> queued) {
        if (modifying_list_order)
            return;
        add_media (queued);
    }

    private void on_media_unqueued (Gee.Collection<Media> unqueued) {
        if (modifying_list_order)
            return;
        remove_media (unqueued);
    }

    private void on_library_media_removed (Gee.Collection<int> ids) {
        remove_media (lm.media_from_ids (ids));
    }

    private inline void set_default_alert () {
        if (!has_embedded_alert)
            return;

        embedded_alert.set_alert (_("No songs in Queue"), _("To add songs to the queue, use the <b>secondary click</b> on an item and choose <b>Queue</b>. When a song finishes, the queued songs will be played first before the next song in the currently playing list."), null, true, Gtk.MessageType.INFO);
    }
}

