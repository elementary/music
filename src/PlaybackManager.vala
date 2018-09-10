// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012-2018 elementary LLC. (https://elementary.io)
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
* Finds the appropriate {@link Noise.Playback} to play a media
*/
public class Noise.PlaybackManager : Object {
    // TODO: Have a correct implementation based on playlists.
    //        Show the next 2 medias in the queue when shuffle mode is enabled and create a playlist to remember shuffled songs
    //        Get the current filter (search, playlist) to be able to store and set it back when restart.

    public signal void changing_player ();
    public signal void media_played (Media played_media);
    public signal void playback_stopped (int64 was_playing);
    public signal void playback_started ();
    public signal void playback_paused ();
    public signal void player_changed ();
    public signal void queue_cleared ();

    private Gee.TreeSet<unowned Noise.Playback> playbacks = new Gee.TreeSet<unowned Noise.Playback> ();

    // id, media of current media.
    private Gee.HashMap<int, Media> _current = new Gee.HashMap<int, Media>();

    //list of id's yet to be played while on shuffle
    private Gee.HashMap<int, Media> _current_shuffled = new Gee.HashMap<int, Media>();

    public StaticPlaylist queue_playlist;
    public HistoryPlaylist history_playlist;

    // TODO: REWRITE IT USING THE LIBRARY
    private Library library { get { return libraries_manager.local_library; } }

    private int _current_index;
    public int current_index {
        get {
            if (_current_shuffled.size == 0) {
                return _current_index;
            } else {
                return _current_shuffled_index;
            }
        }
        set {
            debug ("Current index: %d", value);
            if (_current_shuffled.size == 0) {
                _current_index = value;
            } else {
                _current_shuffled_index = value;
            }
        }
    }

    private int _current_shuffled_index;

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

    private bool _playing_queued_song;

    public Noise.Streamer file_player;
    public Noise.Playback player;
    public Noise.Media current_media { private set; get; }

    construct {
        history_playlist = new HistoryPlaylist ();
        queue_playlist = new StaticPlaylist ();
        queue_playlist.name = C_("Name of the playlist", "Queue");
        queue_playlist.read_only = true;
        queue_playlist.allow_duplicate = true;
        queue_playlist.show_badge = true;
        queue_playlist.icon = new ThemedIcon ("playlist-queue");

        file_player = new Streamer ();
        playbacks.add (file_player);
        player = file_player;
    }

    public void add_playback (Noise.Playback playback) {
        playbacks.add (playback);
    }

    public void queue_media (Gee.Collection<Media> to_queue) {
        if (to_queue.size < 1) {
            return;
        }

        foreach (var q in to_queue) {
            debug ("QUEUED: %s", q.title);
        }

        queue_playlist.add_medias (to_queue);
    }

    public void unqueue_media (Gee.Collection<Media> to_unqueue) {
        queue_playlist.remove_medias (to_unqueue);
    }

    private Media poll_queue () {
        var m = queue_playlist.medias.get (0);
        queue_playlist.medias.remove_at (0);
        var unqueued = new Gee.LinkedList<Media> ();
        unqueued.add (m);
        queue_playlist.media_removed (unqueued);
        return m;
    }

    public void clear_queue () {
        _current.clear();
        current_index = 0;

        reshuffle ();
    }

    public Media media_from_current_index (int index_in_current) {
        if (Settings.Main.get_default ().shuffle_mode == Noise.Settings.Shuffle.OFF) {
            return _current.get (index_in_current);
        } else {
            return _current_shuffled.get (index_in_current);
        }
    }

    public Gee.Collection<Media> get_current_media_list () {
        if (Settings.Main.get_default ().shuffle_mode == Noise.Settings.Shuffle.OFF) {
            return _current_shuffled.values;
        } else {
            return _current.values;
        }
    }

    private void add_to_current (Media m) {
        _current.set (_current.size, m);
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
    private void reshuffle () {
        debug ("Reshuffling");
        _current_shuffled.clear ();
        _current_shuffled_index = 0;

        var main_settings = Settings.Main.get_default ();
        if (main_settings.shuffle_mode == Noise.Settings.Shuffle.OFF) {
            if (current_media != null) {
                //make sure we continue playing where we left off
                for (int i = 0; i < _current.size; ++i) {
                    if (_current.get (i) == current_media) {
                        _current_index = i;
                        return;
                    }
                }
            } else {
                _current_index = 0;
            }
        } else if (main_settings.shuffle_mode == Noise.Settings.Shuffle.ALL) {
            //create temp list of all of current's media
            var temp = new Gee.LinkedList<Media> ();
            foreach (var m in _current.values) {
                temp.add (m);
            }
            
            //loop through all current media id's and pick a random one remaining
            //and set that int i as one of those this is confusing just a sort
            //_current_shuffled.set(0, current_media.rowid);
            for (int i = 1; i < _current.size; i++) {
                int n_media = temp.size;
                if (n_media == 0) {
                    break;
                }

                int random = n_media <= 1 ? 0 : Random.int_range (0, n_media - 1);

                if (current_media != null && temp.get (random) == current_media) {
                    _current_shuffled.set (0, current_media);
                    i--;
                } else {
                    _current_shuffled.set (i, temp.get (random));
                }
                temp.remove (temp.get (random));
            }
        }
    }
    
    public Media? get_next (bool play) {
        Media? rv = null;
        
        var main_settings = Settings.Main.get_default ();
        // next check if user has queued media
        if (queue_playlist.medias.size > 0) {
            rv = poll_queue ();
            _playing_queued_song = true;
        } else if (main_settings.shuffle_mode != Noise.Settings.Shuffle.OFF) {
            if (_current_shuffled.is_empty ) {
                foreach (Media s in library.get_medias ())
                    add_to_current (s);    //first initialize the current selection the reshuffle it
                reshuffle ();
            }
            _playing_queued_song = false;
            
            if (current_media == null) {
                _current_shuffled_index = 0;
                rv = _current_shuffled.get (0);
            } else if (main_settings.repeat_mode == Noise.Settings.Repeat.MEDIA) {
                rv = _current_shuffled.get (_current_shuffled_index);
            } else if (_current_shuffled_index == (_current_shuffled.size - 1)) {// consider repeat options
                if (main_settings.repeat_mode == Noise.Settings.Repeat.ALL) {
                    _current_shuffled_index = 0;
                } else {
                    /* reset to no media playing */
                    current_media = null;
                    _current_shuffled.clear ();
                    _current.clear ();
                    _current_shuffled_index = 0;
                    _current_index = 0;
                    
                    if (play) {
                        stop_playback ();
                    }
                    
                    return null;
                }

                rv = _current_shuffled.get (0);
            } else if (_current_shuffled_index >= 0 && _current_shuffled_index < (_current_shuffled.size - 1)) {
                // make sure we are repeating what we need to be
                var next_current = _current_shuffled.get (_current_shuffled_index + 1);
                var now_current = _current_shuffled.get (_current_shuffled_index);
                
                if (main_settings.repeat_mode == Noise.Settings.Repeat.ARTIST && next_current.artist != now_current.artist) {
                    while (_current_shuffled.get (_current_shuffled_index - 1).artist == current_media.artist) {
                        _current_shuffled_index --;
                    }
                } else if (main_settings.repeat_mode == Noise.Settings.Repeat.ALBUM && next_current.album != now_current.album) {
                    while (_current_shuffled.get(_current_shuffled_index - 1).album == current_media.album) {
                        _current_shuffled_index--;
                    }
                } else {
                    _current_shuffled_index++;
                }
                
                rv = _current_shuffled.get (_current_shuffled_index);
            } else {
                _current_shuffled_index = 0;
                set_shuffle_mode (Noise.Settings.Shuffle.ALL);
                rv = _current_shuffled.get (0);
            }
        } else {
            _playing_queued_song = false;
            
            if (current_media == null) {
                _current_index = 0;
                rv = _current.get (0);
            } else if (main_settings.repeat_mode == Noise.Settings.Repeat.MEDIA) {
                rv = _current.get (_current_index);
            } else if (_current_index == (_current.size - 1)) {// consider repeat options
                if (main_settings.repeat_mode == Noise.Settings.Repeat.ALL) {
                    _current_index = 0;
                } else {
                    if (play) {
                        stop_playback ();
                    }
                    return null;
                }
                
                rv = _current.get (0);
            } else if (_current_index >= 0 && _current_index < (_current.size - 1)){
                // make sure we are repeating what we need to be
                var next_current = _current.get (_current_index + 1);
                var now_current = _current.get (_current_index);
                
                if (main_settings.repeat_mode == Noise.Settings.Repeat.ARTIST && next_current.artist != now_current.artist) {
                    while (_current.get(_current_index - 1).artist == current_media.artist) {
                        _current_index--;
                    }
                } else if (main_settings.repeat_mode == Noise.Settings.Repeat.ALBUM && next_current.album != now_current.album) {
                    while (_current.get (_current_index - 1).album == current_media.album) {
                        _current_index--;
                    }
                } else {
                    _current_index++;
                }
                
                rv = _current.get (_current_index);
            } else {
                foreach (Media s in library.get_medias ()) {
                    add_to_current(s);
                }
                
                _current_index = 0;
                rv = _current.get (0);
            }
        }
        
        if (play) {
            play_media (rv);
        }
        
        return rv;
    }
    
    // TODO: remove code redundancy
    public Media? get_previous (bool play) {
        Media? rv = null;
        
        var main_settings = Settings.Main.get_default ();
        if(main_settings.shuffle_mode != Noise.Settings.Shuffle.OFF) {
            if (_current_shuffled.is_empty) {
                foreach (Media s in library.get_medias ())
                    add_to_current (s);    //first initialize the current selection the reshuffle it
                reshuffle ();
            }

            _playing_queued_song = false;
            
            if(current_media == null) {
                _current_shuffled_index = _current_shuffled.size - 1;
                rv = _current_shuffled.get (_current_shuffled_index);
            } else if(main_settings.repeat_mode == Noise.Settings.Repeat.MEDIA) {
                rv = _current_shuffled.get(_current_shuffled_index);
            } else if(_current_shuffled_index == 0) {// consider repeat options
                if(main_settings.repeat_mode == Noise.Settings.Repeat.ALL)
                    _current_shuffled_index = _current_shuffled.size - 1;
                else {
                    stop_playback ();
                    return null;
                }
                
                rv = _current_shuffled.get(_current_shuffled_index);
            } else if(_current_shuffled_index > 0 && _current_shuffled_index < _current_shuffled.size){
                // make sure we are repeating what we need to be
                if(main_settings.repeat_mode == Noise.Settings.Repeat.ARTIST && _current_shuffled.get(_current_shuffled_index - 1).artist != _current_shuffled.get(_current_shuffled_index).artist) {
                    while(_current_shuffled.get(_current_shuffled_index + 1).artist == current_media.artist)
                        ++_current_shuffled_index;
                } else if(main_settings.repeat_mode == Noise.Settings.Repeat.ALBUM && _current_shuffled.get(_current_shuffled_index - 1).album != _current_shuffled.get(_current_shuffled_index).album) {
                    while(_current_shuffled.get(_current_shuffled_index + 1).album == current_media.album)
                        ++_current_shuffled_index;
                } else
                    --_current_shuffled_index;
                
                rv = _current_shuffled.get(_current_shuffled_index);
            } else {
                _current_shuffled_index = _current_shuffled.size - 1;
                rv = _current_shuffled.get(_current_shuffled_index);
            }
        } else {
            _playing_queued_song = false;
            
            if(current_media == null) {
                _current_index = _current.size - 1;
                rv = _current.get(_current_index);
            } else if(main_settings.repeat_mode == Noise.Settings.Repeat.MEDIA) {
                rv = _current.get(_current_index);
            } else if(_current_index == (0)) {// consider repeat options
                if(main_settings.repeat_mode == Noise.Settings.Repeat.ALL)
                    _current_index = _current.size - 1;
                else {
                    stop_playback ();
                    return null;
                }
                
                rv = _current.get (_current_index);
            } else if (_current_index > 0 && _current_index < _current.size) {
                // make sure we are repeating what we need to be
                if (main_settings.repeat_mode == Noise.Settings.Repeat.ARTIST && _current.get (_current_index - 1).artist != _current.get (_current_index).artist) {
                    while (_current.get (_current_index + 1).artist == current_media.artist)
                        _current_index++;
                } else if (main_settings.repeat_mode == Noise.Settings.Repeat.ALBUM && _current.get(_current_index - 1).album != _current.get (_current_index).album) {
                    while (_current.get (_current_index + 1).album == current_media.album)
                        _current_index++;
                } else {
                    _current_index--;
                }

                rv = _current.get (_current_index);
            } else {
                foreach (Media s in library.get_medias ()) {
                    add_to_current (s);
                }
                _current_index = _current.size - 1;
                rv = _current.get (_current_index);
            }
        }
        
        if (play) {
            play_media (rv);
        }
        
        return rv;
    }

    public void play_media (Media m) {
        int64 old_id = -1;

        // save previous media's id
        if (current_media != null)
            old_id = current_media.rowid;
        // set the current media
        current_media = m;

        // To avoid infinite loop, if we come across a song we already know does not exist
        // stop playback
        if (m.location_unknown) {
            if (File.new_for_uri (m.uri).query_exists ()) { // we did not know location, but it has re-appearred
                m.location_unknown = false;
                m.unique_status_image = null;
                //App.main_window.media_found(m.rowid);
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
            //App.main_window.media_not_found(id);
            get_next (true);
            return;
        } else {
            if (m.location_unknown && m.unique_status_image != null) {
                m.unique_status_image = null;
                m.location_unknown = false;
            }
        }

        change_gains_thread ();

        player.set_media (m); // actually play the media

        //pause if paused
        if (!playing) {
            player.pause ();
        }

        //update settings
        if (m.rowid >= 0 && !Settings.Main.get_default ().privacy_mode_enabled ()) {
            App.saved_state.set_int64 ("last-media-playing", m.rowid);
        }

        if (m != null) {
            media_played (m);
        }

        /* if same media 1 second later... */
        Timeout.add (1000, () => {
            if (m != null && current_media == m) {
                history_playlist.add_media (m);
                // potentially fix media length
                uint player_duration_s = (uint)(player.get_duration () / TimeUtils.NANO_INV);
                if (player_duration_s > 1) {
                    int delta_s = (int)player_duration_s - (int)(m.length / TimeUtils.MILI_INV);
                    if (Math.fabs ((double)delta_s) > 3) {
                        m.length = (uint)(player_duration_s * TimeUtils.MILI_INV);
                        library.update_media (m, false, false);
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
                if (p != null && current_media != null) {
                    var preset_name = p.name.down ();
                    var media_genre = current_media.genre.down ();

                    bool match_genre = (preset_name in media_genre) || (media_genre in preset_name);

                    if ((automatic_enabled && match_genre) ||
                        (!automatic_enabled && p.name == selected_preset)) {
                        for (int i = 0; i < 10; i++) {
                            player.set_equalizer_gain (i, p.get_gain (i));
                        }

                        return;
                    }
                }
            }

            foreach (var p in Equalizer.get_default_presets ()) {
                if (p != null && current_media != null) {
                    var preset_name = p.name.down ();
                    var media_genre = current_media.genre.down ();

                    bool match_genre = (preset_name in media_genre) || (media_genre in preset_name);

                    if ((automatic_enabled && match_genre) ||
                        (!automatic_enabled && p.name == selected_preset)) {
                        for (int i = 0; i < 10; i++) {
                            player.set_equalizer_gain (i, p.get_gain (i));
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
        if (current_media != null) {
            was_playing = current_media.rowid;
        }

        if (!Settings.Main.get_default ().privacy_mode_enabled ()) {
            App.saved_state.set_int64 ("last-media-playing", 0);
        }
        current_media = null;

        playback_stopped (was_playing);
    }

    public void start_playback () {
        player.play ();
        playing = true;
        ((SimpleAction) App.main_window.actions.lookup_action (LibraryWindow.ACTION_PLAY)).set_state (true);
        playback_started ();
    }

    public void pause_playback () {
        player.pause ();
        playing = false;
        ((SimpleAction) App.main_window.actions.lookup_action (LibraryWindow.ACTION_PLAY)).set_state (false);
        playback_paused ();
    }
}
