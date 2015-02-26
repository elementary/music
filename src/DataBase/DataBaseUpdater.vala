// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012 Noise Developers (http://launchpad.net/noise)
 *
 * This software is licensed under the GNU General Public License
 * (version 2 or later). See the COPYING file in this distribution.
 *
 * The Noise authors hereby grant permission for non-GPL compatible
 * GStreamer plugins to be used and distributed together with GStreamer
 * and Noise. This permission is above and beyond the permissions granted
 * by the GPL license by which Noise is covered. If you modify this code
 * you may extend this exception to your version of the code, but you are not
 * obligated to do so. If you do not wish to do so, delete this exception
 * statement from your version.
 *
 * Authored by: Scott Ringwelski <sgringwe@mtu.edu>,
 *              Victor Eduardo <victoreduardm@gmail.com>
 */

public class Noise.DataBaseUpdater : Object {

    private Gee.LinkedList<Object> to_remove;

    public DataBaseUpdater () {

        to_remove = new Gee.LinkedList<Object> ();

        // Save on a regular basis and before exit
        var app = (Noise.App) GLib.Application.get_default ();
        app.shutdown.connect_after (() => on_close_ui_save ());
        app.shutdown.connect_after (update_db_sync);
    }

    public async void removeItem (Object item) {
        if (!to_remove.contains (item))
            to_remove.offer (item);

        update_db_sync ();
    }

    private void update_db_sync () {
        var dbm = DataBaseManager.get_default ();
        for (Object? next = to_remove.poll (); next != null; next = to_remove.poll ()) {
            if (next is Gee.Collection) {
                dbm.remove_media (next as Gee.Collection<Media>);
            } else if (next is StaticPlaylist) {
                dbm.remove_playlist (next as StaticPlaylist);
                dbm.remove_columns_state (next as StaticPlaylist, null);
            } else if (next is SmartPlaylist) {
                dbm.remove_smart_playlist (next as SmartPlaylist);
                dbm.remove_columns_state (null, next as SmartPlaylist);
            } else
                assert_not_reached ();
        }
    }

    private bool on_close_ui_save () {
        var playlists_and_queue = new Gee.TreeSet<StaticPlaylist> ();
        playlists_and_queue.add_all (libraries_manager.local_library.get_playlists ());

        playlists_and_queue.add (((LocalLibrary)libraries_manager.local_library).p_music);

        debug ("-- Saving columns state preferences DB.");

        var dbm = DataBaseManager.get_default ();
        dbm.save_playlist (((LocalLibrary)libraries_manager.local_library).p_music);
        dbm.save_columns_state (playlists_and_queue, libraries_manager.local_library.get_smart_playlists ());

        debug ("-- Finished columns state preferences DB.");

        return true;
    }
    // If the name of the playlist changed, it provides the old name to remove it from database
    public void save_device (DevicePreferences device) {
        DataBaseManager.get_default ().save_device (device);
    }
    
    // If the name of the playlist changed, it provides the old name to remove it from database
    public void save_playlist (StaticPlaylist p, string? old_name = null) {
        DataBaseManager.get_default ().save_playlist (p, old_name);
    }
    
    // If the name of the playlist changed, it provides the old name to remove it from database
    public void save_smart_playlist (SmartPlaylist p, string? old_name = null) {
        DataBaseManager.get_default ().save_smart_playlist (p, old_name);
    }
}
