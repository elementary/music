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
 * Authored by: Scott Ringwelski <sgringwe@mtu.edu>,
 *              Victor Eduardo <victoreduardm@gmail.com>
 */

public class Noise.DataBaseUpdater : Object {
    private const uint PERIODIC_UI_SAVE_TIMEOUT_SEC = 120;

    public signal void periodical_save ();

    private LibraryManager lm;
    private DataBaseManager dbm;

    private Gee.LinkedList<Media> media_updates;
    private Gee.LinkedList<Object> to_remove;

    private bool in_update_thread = false;

    public DataBaseUpdater (LibraryManager lm, DataBaseManager databm) {
        this.lm = lm;
        dbm = databm;

        media_updates = new Gee.LinkedList<Media> ();
        to_remove = new Gee.LinkedList<Object> ();

        // Save on a regular basis and before exit
        Timeout.add_seconds (PERIODIC_UI_SAVE_TIMEOUT_SEC, periodic_ui_save);
        App.instance.shutdown.connect_after (() => periodic_ui_save ());
        App.instance.shutdown.connect_after (update_db_sync);
    }

    public async void removeItem (Object item) {
        lock (to_remove) {
            if (!to_remove.contains (item))
                to_remove.offer (item);
        }

        yield update_db_async ();
    }

    public async void update_media (Media s) {
        lock (media_updates) {
            if (!media_updates.contains (s))
                media_updates.offer (s);
        }

        yield update_db_async ();
    }

    private async void update_db_async () {
        // If many updates are being queued, we want to delay this as much as
        // possible in order to use the same thread. For data safety reasosn,
        // we also want the main loop to trigger the update instead of the same
        // thread which invoked the public method (remove_item, update_media, etc. )
        Idle.add (update_db_async.callback);
        yield;

        // If an update thread is already running, just return, as the update
        // will be handled there.
        if (in_update_thread)
            return;

        message ("-- Starting database update.");

        in_update_thread = true;

        Threads.add (() => {
            update_db_sync ();
            Idle.add (update_db_async.callback);
        });

        yield;

        in_update_thread = false;
        message ("-- Finished database update.");
    }

    private void update_db_sync () {
        while (true) {
            lock (media_updates) {
                if (media_updates.size > 0) {
                    dbm.update_media (media_updates);
                    media_updates.clear ();
                    break;
                }
            }

            lock (to_remove) {
                Object? next = to_remove.poll ();

                if (next != null) {
                    if (next is Gee.LinkedList)
                        dbm.remove_media ( next as Gee.LinkedList<string>);
                    else if (next is Playlist)
                        dbm.remove_playlist (next as Playlist);
                    else if (next is SmartPlaylist)
                        dbm.remove_smart_playlist (next as SmartPlaylist);
                } else {
                    break;
                }
            }
        }
    }

    private bool periodic_ui_save () {
        var playlists_and_queue = new Gee.LinkedList<Playlist> ();
        playlists_and_queue.add_all (lm.playlists ());

        Playlist p_queue = new Playlist ();
        p_queue.name = "autosaved_queue";
        p_queue.add_media (App.player.queue ());
        lm.lw.set_treeviewsetup_from_playlist (p_queue, lm.queue_setup);

        Playlist p_history = new Playlist ();
        p_history.name = "autosaved_history";
        lm.lw.set_treeviewsetup_from_playlist (p_history, lm.history_setup);

        Playlist p_similar = new Playlist ();
        p_similar.name = "autosaved_similar";
        lm.lw.set_treeviewsetup_from_playlist (p_similar, lm.similar_setup);

        Playlist p_music = new Playlist ();
        p_music.name = "autosaved_music";
        lm.lw.set_treeviewsetup_from_playlist (p_music, lm.music_setup);

        playlists_and_queue.add (p_queue);
        playlists_and_queue.add (p_history);
        playlists_and_queue.add (p_similar);
        playlists_and_queue.add (p_music);

        message ("-- Saving playlists and device preferences DB.");

        dbm.save_playlists (playlists_and_queue);
        dbm.save_smart_playlists (lm.smart_playlists ());
        dbm.save_devices (lm.device_manager.device_preferences ());

        message ("-- Finished saving playlists and device preferences DB.");

        Idle.add (() => {
            periodical_save ();
            return false;
        });

        return true;
    }
}
