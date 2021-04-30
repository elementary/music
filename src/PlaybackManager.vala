/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2021 elementary, Inc. (https://elementary.io)
 */

public class Music.PlaybackManager : Object {
    private static PlaybackManager? _instance;
    public static PlaybackManager get_default () {
        if (_instance == null) {
            _instance = new PlaybackManager ();
        }

        return _instance;
    }

    private dynamic Gst.Element playbin;

    private PlaybackManager () {}

    construct {
        playbin = Gst.ElementFactory.make ("playbin", "playbin");

        GLib.Application.get_default ().action_state_changed.connect ((name, new_state) => {
            if (name == Application.ACTION_PLAY_PAUSE) {
                if (new_state.get_boolean () == false) {
                    playbin.set_state (Gst.State.PAUSED);
                } else {
                    playbin.set_state (Gst.State.PLAYING);
                }
            }
        });
    }

    public void queue_files (File[] files) {
        playbin.uri = files[0].get_uri ();

        var play_pause_action = GLib.Application.get_default ().lookup_action (Application.ACTION_PLAY_PAUSE);

        var return = playbin.set_state (Gst.State.PLAYING);
        if (return == Gst.StateChangeReturn.FAILURE) {
            critical ("Unable to play %s", files[0].get_path ());
            ((SimpleAction) play_pause_action).set_state (false);
        } else {
            ((SimpleAction) play_pause_action).set_state (true);
        }
    }
}
