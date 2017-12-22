// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012-2017 elementary LLC. (https://elementary.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * The Noise authors hereby grant permission for non-GPL compatible
 * GStreamer plugins to be used and distributed together with GStreamer
 * and Noise. This permission is above and beyond the permissions granted
 * by the GPL license by which Noise is covered. If you modify this code
 * you may extend this exception to your version of the code, but you are not
 * obligated to do so. If you do not wish to do so, delete this exception
 * statement from your version.
 *
 * Authored by: Scott Ringwelski <sgringwe@mtu.edu>
 *              Corentin Noël <corentin@elementary.io>
 */

/**
* Manages song playback, queue, repeating and shuffling
*
* Finds the appropriate {@link Noise.Playback} to play a medium.
*/
public class Noise.PlaybackManager : Object, Noise.Player {
    public signal void queue_cleared ();
    public signal void media_queued (Gee.Collection<Medium> queued);

    public signal void medium_played (Medium played_medium);
    public signal void playback_stopped (int64 was_playing);
    public signal void playback_started ();
    public signal void playback_paused ();
    public signal void changing_player ();
    public signal void player_changed ();

    private Gee.TreeSet<unowned Noise.Playback> playbacks = new Gee.TreeSet<unowned Noise.Playback> ();

    // We keep the ordered_queue to be able to restore it when shuffling is turned off
    private StaticPlaylist ordered_queue;

    /**
    * Either contains the ordered or the shuffled queue
    *
    * When giving it a value, be sure it is ordered.
    */
    public StaticPlaylist queue_playlist {
        get {
            return _queue_playlist;
        }
        set {
            ordered_queue = value;
            reshuffle ();
        }
    }
    private StaticPlaylist _queue_playlist = new StaticPlaylist ();

    public bool is_shuffled {
        get {
            return Settings.Main.get_default ().shuffle_mode == Noise.Settings.Shuffle.ALL;
        }
        set {
            Settings.Main.get_default ().shuffle_mode = value
                ? Noise.Settings.Shuffle.ALL
                : Noise.Settings.Shuffle.OFF;
        }
    }

    public HistoryPlaylist history_playlist;

    // TODO: REWRITE IT USING THE LIBRARY
    public Library library { get { return libraries_manager.local_library; } }

    int _ci;
    public int current_index { get {
        return _ci;
        } set { debug ("Current index: %d", value); _ci = value; } }

    public bool playing { get; private set; default = false; }
    private double saved_volume = 1;
    public double volume {
        get {
            return player.get_volume ();
        }
        set {
            saved_volume = value;
            player.set_volume (value);
        }
    }

    public Streamer file_player;
    public Playback player;
    public Medium current_medium { private set; get; }

    construct {
        history_playlist = new HistoryPlaylist ();
        ordered_queue = new StaticPlaylist ();

        queue_playlist.name = C_("Name of the playlist", "Queue");
        queue_playlist.read_only = true;
        queue_playlist.allow_duplicate = true;
        queue_playlist.show_badge = true;
        queue_playlist.icon = new ThemedIcon ("playlist-queue");

        file_player = new Streamer ();
        playbacks.add (file_player);
        player = file_player;
    }

    public void add_playback (Playback playback) {
        playbacks.add (playback);
    }

    public void queue_medium (Medium to_queue) {
        queue_media (new Gee.ArrayList<Medium>.wrap ({ to_queue }));
    }

    public void queue_media (Gee.Collection<Medium> to_queue) {
        if (to_queue.size < 1) {
            return;
        }

        foreach (var q in to_queue) {
            debug ("QUEUED: %s", q.title);
        }

        ordered_queue.add_media (to_queue);
        reshuffle ();

        foreach (var q in queue_playlist.media) {
            debug ("NEUE QUEUE: %s", q.title);
        }
        media_queued (to_queue);
    }

    public void queue_media_by_id (Gee.Collection<int> ids) {
        queue_media (library.media_from_ids (ids));
    }

    public void unqueue_medium (Medium to_unqueue) {
        unqueue_media (new Gee.ArrayList<Medium>.wrap ({ to_unqueue }));
    }

    public void unqueue_media (Gee.Collection<Medium> to_unqueue) {
        ordered_queue.remove_media (to_unqueue);
        reshuffle ();
        queue_playlist.media_removed (to_unqueue);
    }

    public void unqueue_media_by_id (Gee.Collection<int> ids) {
        unqueue_media (library.media_from_ids (ids));
    }

    public void clear_queue () {
        queue_cleared ();
        queue_playlist.clear ();
        ordered_queue.clear ();
        current_index = 0;

        reshuffle ();
    }

    public Medium medium_from_current_index (int index_in_current) {
        return queue_playlist[index_in_current];
    }

    public Gee.Collection<Medium> get_current_medium_list () {
        return queue_playlist.media;
    }

    public void set_repeat_mode (Noise.Settings.Repeat mode) {
        var main_settings = Settings.Main.get_default ();
        if (main_settings.repeat_mode != mode) {
            main_settings.repeat_mode = mode;
        }
    }

    public void set_shuffle_mode (Noise.Settings.Shuffle mode) {
        var main_settings = Settings.Main.get_default ();
        if (main_settings.shuffle_mode != mode) {
            main_settings.shuffle_mode = mode;
            reshuffle ();
        }
    }

    /**
    * Regenerate the shuffled queue if needed
    */
    public void reshuffle () {
        debug ("Reshuffling");
        queue_playlist.clear ();
        if (is_shuffled) {
            debug ("Shuffled");
            queue_playlist.media.add_all (ordered_queue.media);

            //create temp list of all of current's media
            var temp = new Gee.ArrayList<Medium> ();
            temp.add_all (ordered_queue.media);

            //loop through all current media id's and pick a random one remaining
            //and set that int i as one of those this is confusing just a sort
            for (int i = 1; i < ordered_queue.media.size; i++) {
                int n_media = temp.size;
                if (n_media == 0) {
                    break;
                }

                int random = n_media <= 1 ? 0 : Random.int_range (0, n_media - 1);

                if (current_medium != null && temp[random] == current_medium) {
                    queue_playlist[0] = current_medium;
                    i--;
                } else {
                    queue_playlist[i] = temp[random];
                }
                temp.remove(temp[random]);
            }

            queue_playlist.media_added (queue_playlist.media);
        } else {
            debug ("Not shuffled");
            if (current_medium != null) {
                //make sure we continue playing where we left off
                current_index = ordered_queue.media.index_of (current_medium);
            } else {
                current_index = 0;
            }

            queue_playlist.add_media (ordered_queue.media);
        }
    }

    /**
    * Gets the medium of the queue at a certain position, relatively to the current one.
    *
    * For instance, calling this method with position = -1 will return the medium just before the current one.
    */
    public Medium? get_medium_at (int position, out int medium_index) {
        int index = current_index + position;
        medium_index = fix_index (index);
        Medium? res = queue_playlist.media.size > index > 0 ? queue_playlist[index] : null;

        var main_settings = Settings.Main.get_default ();
        switch (main_settings.repeat_mode) {
            case Noise.Settings.Repeat.MEDIUM:
                return current_medium;
            case Noise.Settings.Repeat.ALL:

                // go back to the beggining, or to the end if needed
                return res == null ? queue_playlist[fix_index (index)] : res;
            case Noise.Settings.Repeat.OFF:

                if (res == null) { // end of the queue
                    current_medium = null;
                    ordered_queue.clear ();
                    queue_playlist.clear ();
                }

                return res;
            case Noise.Settings.Repeat.ALBUM:

                // explore the queue, starting at the current song, and going back to the beggining when the end is reached
                for (int i = current_index + 1; i != current_index; i += position) {
                    i = fix_index (i);

                    if (queue_playlist[i].album == current_medium.album) {
                        return queue_playlist[i];
                    }
                }
                break;
            case Noise.Settings.Repeat.ARTIST:

                // same logic as above
                for (int i = current_index + 1; i != current_index; i += position) {
                    i = fix_index (i);

                    if (queue_playlist[i].artist == current_medium.artist) {
                        return queue_playlist[i];
                    }
                }
                break;
        }

        return res;
    }

    /**
    * Make sure index of medium is never out of the queue.
    */
    public int fix_index (int index) {
        return (queue_playlist.media.size + index) % queue_playlist.media.size;
    }

    public Medium? get_next (bool play) {
        int index;
        var next = get_medium_at (1, out index);
        if (play) {
            if (next == null) {
                stop_playback ();
            } else {
                current_index = index;
                play_medium (next);
            }
        }

        return next;
    }

    public Medium? get_previous (bool play) {
        int index;
        var prev = get_medium_at (-1, out index);
        if (play) {
            if (prev == null) {
                stop_playback ();
            } else {
                current_index = index;
                play_medium (prev);
            }
        }

        return prev;
    }


    public void play_medium (Medium m) {
        // set the current medium
        current_medium = m;

        // To avoid infinite loop, if we come across a song we already know does not exist
        // stop playback
        if (m.location_unknown) {
            if (File.new_for_uri (m.uri).query_exists ()) { // we did not know location, but it has re-appearred
                m.location_unknown = false;
                m.unique_status_image = null;
                // App.main_window.medium_found(m.rowid);
            } else { // to avoid infinite loop with repeat on, don't try to play next again
                stop_playback ();
                return;
            }
        }

        var found = false;
        lock (playbacks) {
            foreach (var playback in playbacks) {
                foreach (var supported_uri in playback.get_supported_uri ()) {
                    if (m.uri.has_prefix (supported_uri)) {
                        saved_volume = player.get_volume ();
                        changing_player ();
                        player.set_state (Gst.State.NULL);
                        found = true;
                        player = playback;
                        volume = saved_volume;
                        player_changed ();
                        break;
                    }
                }
                if (found == true) {
                    break;
                }
            }
        }
        if (!found) {
            m.unique_status_image = new ThemedIcon ("process-error-symbolic");
            get_next (true);
            return;
        }

        // check that the file exists
        if (!m.file.query_exists ()) {
            m.unique_status_image = new ThemedIcon ("process-error-symbolic");
            m.location_unknown = true;
            //App.main_window.medium_not_found(id);
            get_next (true);
            return;
        } else {
            if (m.location_unknown && m.unique_status_image != null) {
                m.unique_status_image = null;
                m.location_unknown = false;
            }
        }

        change_gains_thread ();

        player.set_medium (m); // actually play the medium

        // pause if paused
        if (!playing) {
            player.pause ();
        }

        //update settings
        if (m.rowid >= 0 && !Settings.Main.get_default ().privacy_mode_enabled ()) {
            Settings.Main.get_default ().last_medium_playing = m.rowid;
        }

        if (m != null) {
            medium_played (m);
        }

        /* if same medium 1 second later... */
        Timeout.add (1000, () => {
            if (m != null && current_medium == m) {
                history_playlist.add_medium (m);
                // potentially fix medium length
                uint player_duration_s = (uint)(player.get_duration() / TimeUtils.NANO_INV);
                if (player_duration_s > 1) {
                    int delta_s = (int)player_duration_s - (int)(m.length / TimeUtils.MILI_INV);
                    if (Math.fabs ((double)delta_s) > 3) {
                        m.length = (uint)(player_duration_s * TimeUtils.MILI_INV);
                        library.update_medium (m, false, false);
                    }
                }
            }

            return false;
        });
    }

    public void change_gains_thread () {
        var equalizer_settings = Settings.Equalizer.get_default ();
        if (equalizer_settings.equalizer_enabled) {
            bool automatic_enabled = equalizer_settings.auto_switch_preset;
            string selected_preset = equalizer_settings.selected_preset;

            foreach (var p in equalizer_settings.get_presets ()) {
                if (p != null && current_medium != null)  {
                    var preset_name = p.name.down ();
                    var medium_genre = current_medium.genre.down();

                    bool match_genre = (preset_name in medium_genre) || (medium_genre in preset_name);

                    if ((automatic_enabled && match_genre) ||
                        (!automatic_enabled && p.name == selected_preset)) {
                        for (int i = 0; i < 10; i++) {
                            player.set_equalizer_gain(i, p.get_gain (i));
                        }

                        return;
                    }
                }
            }

            foreach (var p in Equalizer.get_default_presets ()) {
                if (p != null && current_medium != null)  {
                    var preset_name = p.name.down ();
                    var medium_genre = current_medium.genre.down();

                    bool match_genre = (preset_name in medium_genre) || (medium_genre in preset_name);

                    if ((automatic_enabled && match_genre) ||
                        (!automatic_enabled && p.name == selected_preset)) {
                        for (int i = 0; i < 10; i++) {
                            player.set_equalizer_gain (i, p.get_gain(i));
                        }

                        return;
                    }
                }
            }
        }

        for (int i = 0; i < 10; ++i) {
            player.set_equalizer_gain (i, 0);
        }
    }

    public void stop_playback () {
        player.pause ();
        playing = false;

        int64 was_playing = 0;
        if (current_medium != null) {
            was_playing = current_medium.rowid;
        }

        if (!Settings.Main.get_default ().privacy_mode_enabled ()) {
            Settings.Main.get_default ().last_medium_playing = 0;
        }
        current_medium = null;

        playback_stopped (was_playing);
    }

    public void start_playback () {
        player.play ();
        playing = true;

        playback_started ();
    }

    public void pause_playback () {
        player.pause ();
        playing = false;

        playback_paused ();
    }
}
