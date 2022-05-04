/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2021-2022 elementary, Inc. (https://elementary.io)
 */

public class Music.PlaybackManager : Object {
    public AudioObject? current_audio { get; set; default = null; }
    public ListStore queue_liststore { get; private set; }
    public int64 playback_position { get; private set; }

    private static PlaybackManager? _instance;
    public static PlaybackManager get_default () {
        if (_instance == null) {
            _instance = new PlaybackManager ();
        }

        return _instance;
    }

    private dynamic Gst.Element playbin;
    private uint progress_timer = 0;
    private Settings settings;

    private PlaybackManager () {}

    construct {
        queue_liststore = new ListStore (typeof (AudioObject));

        playbin = Gst.ElementFactory.make ("playbin", "playbin");

        var bus = playbin.get_bus ();
        bus.add_watch (0, bus_callback);
        bus.enable_sync_message_emission ();

        queue_liststore.items_changed.connect (() => {
            var shuffle_action_action = (SimpleAction) GLib.Application.get_default ().lookup_action (Application.ACTION_SHUFFLE);
            shuffle_action_action.set_enabled (queue_liststore.get_n_items () > 1);

            update_next_previous_sensitivity ();
        });

        notify["current-audio"].connect (() => {
            playbin.set_state (Gst.State.NULL);
            if (current_audio != null) {
                playbin.uri = current_audio.uri;
                playbin.set_state (Gst.State.PLAYING);
            } else {
                playbin.uri = "";
                playback_position = 0;

                if (progress_timer != 0) {
                    Source.remove (progress_timer);
                    progress_timer = 0;
                }
            }

            update_next_previous_sensitivity ();

            var play_pause_action = (SimpleAction) GLib.Application.get_default ().lookup_action (Application.ACTION_PLAY_PAUSE);
            play_pause_action.set_enabled (current_audio != null);
        });

        settings = new Settings ("io.elementary.music");
    }

    public void seek_to_progress (double percent) {
        playbin.seek_simple (Gst.Format.TIME, Gst.SeekFlags.FLUSH, (int64)(percent * current_audio.duration));
    }

    public void queue_files (File[] files) {
        foreach (unowned var file in files) {
            if (file.query_exists ()) {
                var audio_object = new AudioObject (file.get_uri ());
                queue_liststore.append (audio_object);
            }
        }

        if (current_audio == null) {
            var audio_object = (AudioObject) queue_liststore.get_object (0);
            if (audio_object != null) {
                current_audio = audio_object;
            }
        } else {
            // Don't notify on app startup or if the app is focused
            var application = GLib.Application.get_default ();
            if (!((Gtk.Application) application).get_active_window ().has_focus) {
                var notification = new Notification (
                    ngettext (
                        "%d track was added to the queue",
                        "%d tracks were added to the queue",
                        files.length
                    ).printf (files.length)
                );
                notification.set_icon (new ThemedIcon ("playlist-queue"));

                application.send_notification ("queue-files", notification);
            }
        }
    }

    private bool bus_callback (Gst.Bus bus, Gst.Message message) {
        switch (message.type) {
            case Gst.MessageType.EOS:
                next ();
                break;
            case Gst.MessageType.STATE_CHANGED:
                if (progress_timer != 0) {
                    Source.remove (progress_timer);
                    progress_timer = 0;
                }

                var play_pause_action = (SimpleAction) GLib.Application.get_default ().lookup_action (Application.ACTION_PLAY_PAUSE);

                Gst.State old_state, new_state, pending_state;
                message.parse_state_changed (out old_state, out new_state, out pending_state);
                if (new_state == Gst.State.PLAYING) {
                    play_pause_action.set_state (true);

                    progress_timer = GLib.Timeout.add (250, () => {
                        int64 position = 0;
                        playbin.query_position (Gst.Format.TIME, out position);
                        playback_position = position.clamp (0, current_audio.duration);

                        return Source.CONTINUE;
                    });
                } else {
                    play_pause_action.set_state (false);
                }
                break;
            default:
                break;
        }

        return true;
    }

    public void play_pause () {
        var play_pause_action = (SimpleAction) GLib.Application.get_default ().lookup_action (Application.ACTION_PLAY_PAUSE);
        if (play_pause_action.get_state ().get_boolean ()) {
            playbin.set_state (Gst.State.PAUSED);
        } else {
            playbin.set_state (Gst.State.PLAYING);
        }
    }

    public void next () {
        uint position = -1;
        queue_liststore.find (current_audio, out position);

        if (position != -1) {
            switch (settings.get_string ("repeat-mode")) {
                case "disabled":
                    if (position == queue_liststore.get_n_items () - 1) {
                        current_audio = null;
                        return;
                    }

                    current_audio = (AudioObject) queue_liststore.get_item (position + 1);

                    break;

                case "all":
                    if (position == queue_liststore.get_n_items () - 1) {
                        current_audio = (AudioObject) queue_liststore.get_item (0);
                    } else {
                        current_audio = (AudioObject) queue_liststore.get_item (position + 1);
                    }

                    break;
            }
        }
    }

    public void previous () {
        uint position = -1;
        queue_liststore.find (current_audio, out position);

        if (position != -1 && position != 0) {
            current_audio = (AudioObject) queue_liststore.get_item (position - 1);
        }
    }

    public void shuffle () {
        var temp_list = new ListStore (typeof (AudioObject));
        temp_list.append (current_audio);

        uint position = -1;
        queue_liststore.find (current_audio, out position);
        queue_liststore.remove (position);

        while (queue_liststore.get_n_items () > 0) {
            var random_position = Random.int_range (0, (int32) queue_liststore.get_n_items ());

            temp_list.append (queue_liststore.get_item (random_position));
            queue_liststore.remove (random_position);
        }

        for (int i = 0; i < temp_list.get_n_items (); i++) {
            queue_liststore.append (temp_list.get_item (i));
        }
    }

    private void update_next_previous_sensitivity () {
        var next_sensitive = false;
        var previous_sensitive = false;

        if (current_audio != null) {
            uint position = -1;
            queue_liststore.find (current_audio, out position);

            if (position != -1) {
                if (position != queue_liststore.get_n_items () - 1) {
                    next_sensitive = true;
                }

                if (position != 0) {
                    previous_sensitive = true;
                }
            }
        }

        var default_application = GLib.Application.get_default ();

        var next_action = (SimpleAction) default_application.lookup_action (Application.ACTION_NEXT);
        next_action.set_enabled (next_sensitive);

        var previous_action = (SimpleAction) default_application.lookup_action (Application.ACTION_PREVIOUS);
        previous_action.set_enabled (previous_sensitive);

    }
}
