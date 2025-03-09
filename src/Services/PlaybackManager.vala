/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2021-2022 elementary, Inc. (https://elementary.io)
 */

public class Music.PlaybackManager : Object {
    public signal bool ask_has_previous ();
    public signal bool ask_has_next (bool repeat_all);
    public signal void invalids_found (int count);

    public AudioObject? current_audio { get; set; default = null; }
    public ListStore queue_liststore { get; private set; }
    public bool has_items { get; private set; }
    public uint n_items {
        get {
            return queue_liststore != null ? queue_liststore.get_n_items () : 0;
        }
    }
    public int64 playback_position { get; private set; }

    private static GLib.Once<PlaybackManager> instance;
    public static unowned PlaybackManager get_default () {
        return instance.once (() => { return new PlaybackManager (); });
    }

    private dynamic Gst.Element playbin;
    private uint progress_timer = 0;
    private Settings settings;

    private enum Direction {
        NONE,
        NEXT,
        PREVIOUS
    }

    private bool next_by_eos = false;

    private Direction direction = Direction.NONE;

    private PlaybackManager () {}

    construct {
        queue_liststore = new ListStore (typeof (AudioObject));

        playbin = Gst.ElementFactory.make ("playbin", "playbin");

        var bus = playbin.get_bus ();
        bus.add_watch (0, bus_callback);
        bus.enable_sync_message_emission ();

        queue_liststore.items_changed.connect (() => {
            var shuffle_action_action = (SimpleAction) GLib.Application.get_default ().lookup_action (Application.ACTION_SHUFFLE);
            has_items = queue_liststore.get_n_items () > 0;
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

    // Files[] must not contain any null entries
    public void queue_files (File[] files) {
        int invalids = 0;
        foreach (unowned var file in files) {
            if (file.query_exists () && "audio" in ContentType.guess (file.get_uri (), null, null)) {
                var audio_object = new AudioObject.from_file (file);
                queue_liststore.append (audio_object);
            } else {
                invalids++;
                continue;
            }
        }

        if (invalids > 0) {
            invalids_found (invalids);
        }

        if (current_audio == null) {
            var audio_object = (AudioObject) queue_liststore.get_object (0);
            if (audio_object != null) {
                current_audio = audio_object;
            }
        } else {
            // Don't notify on app startup or if the app is focused
            var application = (Gtk.Application) GLib.Application.get_default ();
            var added_tracks = files.length - invalids;
            if (
                !application.get_active_window ().is_active &&
                added_tracks > 0
            ) {
                var notification = new Notification (
                    ngettext (
                        "%d track was added to the queue",
                        "%d tracks were added to the queue",
                        added_tracks
                    ).printf (added_tracks)
                );
                notification.set_icon (new ThemedIcon ("playlist-queue"));

                application.send_notification ("queue-files", notification);
            }
        }
    }

    private bool bus_callback (Gst.Bus bus, Gst.Message message) {
        switch (message.type) {
            case Gst.MessageType.EOS:
                next (true);
                break;
            case Gst.MessageType.ERROR:
                switch (direction) {
                    case Direction.NEXT:
                        next (next_by_eos);
                        break;
                    case Direction.PREVIOUS:
                        previous ();
                        break;
                    default:
                        break;
                }
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

    public void next (bool eos = false) {
        direction = Direction.NEXT;
        next_by_eos = eos;
        uint position;
        bool from_queue = queue_liststore.find (current_audio, out position);

        if (from_queue && position != queue_liststore.get_n_items () - 1) {
            current_audio = (AudioObject) queue_liststore.get_item (position + 1);
            return;
        }

        if (next_by_eos) {
            switch (settings.get_string ("repeat-mode")) {
                case "disabled":
                    break;

                case "all":
                    if (!from_queue) {
                        ask_has_next (true);
                        return;
                    } else {
                        current_audio = (AudioObject) queue_liststore.get_item (0);
                        if (position == 0) {
                            seek_to_progress (0);
                        }
                        return;
                    }

                case "one":
                    seek_to_progress (0);
                    return;
            }
        }

        ask_has_next (false);
    }

    public void previous () {
        direction = Direction.PREVIOUS;
        uint position = -1;

        if (queue_liststore.find (current_audio, out position)) {
            if (position == 0) {
                uint n_items = queue_liststore.get_n_items ();
                if (n_items == 1) {
                    seek_to_progress (0);
                } else {
                    current_audio = (AudioObject) queue_liststore.get_item (n_items - 1);
                }

                return;
            }

            current_audio = (AudioObject) queue_liststore.get_item (position - 1);
            return;
        }

        ask_has_previous ();
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

    public int find_title (string term) {
        return 0;
        //  var search_object = new AudioObject ("") {
        //      title = term
        //  };

        //  int found_at = -1;
        //  uint position;
        //  if (queue_liststore.find_with_equal_func (
        //      search_object,
        //      (a, b) => {
        //          var term_a = ((AudioObject)a).title.down ();
        //          var term_b = ((AudioObject)b).title.down ();
        //          return term_a.contains (term_b);
        //      },
        //      out position
        //  )) {
        //      found_at = (int)position;
        //  }

        //  return found_at;
    }

    private void update_next_previous_sensitivity () {
        var next_sensitive = false;
        var previous_sensitive = false;

        next_sensitive = previous_sensitive = current_audio != null;

        var default_application = GLib.Application.get_default ();

        var next_action = (SimpleAction) default_application.lookup_action (Application.ACTION_NEXT);
        next_action.set_enabled (next_sensitive);

        var previous_action = (SimpleAction) default_application.lookup_action (Application.ACTION_PREVIOUS);
        previous_action.set_enabled (previous_sensitive);

    }

    public static Gst.Sample? get_cover_sample (Gst.TagList tag_list) {
        Gst.Sample cover_sample = null;
        Gst.Sample sample;
        for (int i = 0; tag_list.get_sample_index (Gst.Tags.IMAGE, i, out sample); i++) {
            var caps = sample.get_caps ();
            unowned Gst.Structure caps_struct = caps.get_structure (0);
            int image_type = Gst.Tag.ImageType.UNDEFINED;
            caps_struct.get_enum ("image-type", typeof (Gst.Tag.ImageType), out image_type);
            if (image_type == Gst.Tag.ImageType.UNDEFINED && cover_sample == null) {
                cover_sample = sample;
            } else if (image_type == Gst.Tag.ImageType.FRONT_COVER) {
                return sample;
            }
        }

        return cover_sample;
    }
}
