/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2021 elementary, Inc. (https://elementary.io)
 */

public class Music.PlaybackManager : Object {
    public ListStore queue_liststore { get; private set; }
    public int64 playback_duration { get; private set; default = 0; }
    public int64 playback_position { get; private set; }
    public string artist { get; private set; }
    public string title { get; private set; }

    private static PlaybackManager? _instance;
    public static PlaybackManager get_default () {
        if (_instance == null) {
            _instance = new PlaybackManager ();
        }

        return _instance;
    }

    private dynamic Gst.Element playbin;
    private Gst.Bus bus;
    private uint progress_timer = 0;

    private PlaybackManager () {}

    construct {
        playbin = Gst.ElementFactory.make ("playbin", "playbin");

        bus = playbin.get_bus ();
        bus.add_watch (0, bus_callback);
        bus.enable_sync_message_emission ();

        queue_liststore = new ListStore (typeof (Music.AudioObject));

        GLib.Application.get_default ().action_state_changed.connect ((name, new_state) => {
            if (name == Application.ACTION_PLAY_PAUSE) {
                if (new_state.get_boolean () == false) {
                    playbin.set_state (Gst.State.PAUSED);
                    if (progress_timer != 0) {
                        Source.remove (progress_timer);
                        progress_timer = 0;
                    }
                } else {
                    if (playback_duration == 0) {
                        // It may take time to calculate the length, so we keep
                        // checking until we get something reasonable
                        GLib.Timeout.add (250, () => {
                            int64 duration = 0;
                            playbin.query_duration (Gst.Format.TIME, out duration);
                            playback_duration = duration;

                            if (playback_duration > 0) {
                                return false;
                            }

                            return true;
                        });
                    }

                    progress_timer = GLib.Timeout.add (250, () => {
                        int64 position = 0;
                        playbin.query_position (Gst.Format.TIME, out position);
                        playback_position = position.clamp (0, playback_duration);

                        return true;
                    });

                    playbin.set_state (Gst.State.PLAYING);
                }
            }
        });
    }

    public void seek_to_progress (double percent) {
        playbin.seek_simple (Gst.Format.TIME, Gst.SeekFlags.FLUSH, (int64)(percent * playback_duration));
    }

    public void queue_files (File[] files) {
        if (files[0].query_exists ()) {
            playbin.uri = files[0].get_uri ();

            var audio_object = new AudioObject ("", files[0].get_path (), 0);

            queue_liststore.append (audio_object);

            title = files[0].get_path ();
            ((SimpleAction) GLib.Application.get_default ().lookup_action (Application.ACTION_PLAY_PAUSE)).set_enabled (true);
            ((SimpleAction) GLib.Application.get_default ().lookup_action (Application.ACTION_PLAY_PAUSE)).set_state (true);
        } else {
            playbin.uri = "";
            title = _("Music");
            artist = _("Not playing");
            ((SimpleAction) GLib.Application.get_default ().lookup_action (Application.ACTION_PLAY_PAUSE)).set_enabled (false);
        }
    }

    private bool bus_callback (Gst.Bus bus, Gst.Message message) {
        switch (message.type) {
            case Gst.MessageType.EOS:
                ((SimpleAction) GLib.Application.get_default ().lookup_action (Application.ACTION_PLAY_PAUSE)).set_state (false);
                break;
            case Gst.MessageType.TAG:
                Gst.TagList tag_list;
                message.parse_tag (out tag_list);

                string _title;
                tag_list.get_string (Gst.Tags.TITLE, out _title);
                if (_title != null) {
                    title = _title;
                }

                string _artist;
                tag_list.get_string (Gst.Tags.ARTIST, out _artist);
                if (_artist != null) {
                    artist = _artist;
                } else if (_title != null) { // Don't set artist for files without tags
                    artist = _("Unknown");
                }

                break;
            default:
                break;
        }

        return true;
    }
}
