/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2021 elementary, Inc. (https://elementary.io)
 */

public class Music.PlaybackManager : Object {
    public Gdk.Pixbuf pixbuf { get; private set; }
    public string artist { get; private set; }
    public string title { get; private set; }
    public int64 playback_duration { get; private set; }
    public int64 playback_position { get; private set; }

    private static PlaybackManager? _instance;
    public static PlaybackManager get_default () {
        if (_instance == null) {
            _instance = new PlaybackManager ();
        }

        return _instance;
    }

    private uint progress_timer = 0;
    private dynamic Gst.Element playbin;
    private Gst.Bus bus;

    private PlaybackManager () {}

    construct {
        playbin = Gst.ElementFactory.make ("playbin", "playbin");

        bus = playbin.get_bus ();
        bus.add_watch (0, bus_callback);
        bus.enable_sync_message_emission ();

        GLib.Application.get_default ().action_state_changed.connect ((name, new_state) => {
            if (name == Application.ACTION_PLAY_PAUSE) {
                if (new_state.get_boolean () == false) {
                    playbin.set_state (Gst.State.PAUSED);
                    if (progress_timer != 0) {
                        Source.remove (progress_timer);
                        progress_timer = 0;
                    }
                } else {
                    playbin.set_state (Gst.State.PLAYING);

                    // It may take time to calculate the length, so we keep
                    // checking until we get something reasonable
                    GLib.Timeout.add (250, () => {
                        int64 duration = 0;
                        playbin.query_duration (Gst.Format.TIME, out duration);
                        playback_duration = duration;

                        if (duration > 0) {
                            return false;
                        }

                        return true;
                    });

                    progress_timer = GLib.Timeout.add (250, () => {
                        int64 position = 0;
                        playbin.query_position (Gst.Format.TIME, out position);
                        playback_position = position;

                        return true;
                    });
                }
            }
        });
    }

    public void seek_to_progress (double percent) {
        playbin.seek_simple (Gst.Format.TIME, Gst.SeekFlags.FLUSH, (int64)(percent * playback_duration));
    }

    public void queue_files (File[] files) {
        playbin.uri = files[0].get_uri ();
        ((SimpleAction) GLib.Application.get_default ().lookup_action (Application.ACTION_PLAY_PAUSE)).set_state (true);
    }

    private bool bus_callback (Gst.Bus bus, Gst.Message message) {
        switch (message.type) {
            case Gst.MessageType.TAG: 
                Gst.TagList tag_list;
                message.parse_tag (out tag_list);

                string _artist;
                tag_list.get_string (Gst.Tags.ARTIST, out _artist);
                artist = _artist;

                string _title;
                tag_list.get_string (Gst.Tags.TITLE, out _title);
                title = _title;

                var sample = get_cover_sample (tag_list);
                if (sample != null) {
                    var buffer = sample.get_buffer ();

                    if (buffer != null) {
                        pixbuf = get_pixbuf_from_buffer (buffer);
                    }
                }

                break;
            default:
                break;
            }

        return true;
    }

    private Gst.Sample? get_cover_sample (Gst.TagList tag_list) {
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

    private Gdk.Pixbuf? get_pixbuf_from_buffer (Gst.Buffer buffer) {
        Gst.MapInfo map_info;

        if (!buffer.map (out map_info, Gst.MapFlags.READ)) {
            warning ("Could not map memory buffer");
            return null;
        }

        Gdk.Pixbuf pix = null;

        try {
            var loader = new Gdk.PixbufLoader ();

            if (loader.write (map_info.data) && loader.close ()) {
                pix = loader.get_pixbuf ();
            }
        } catch (Error err) {
            warning ("Error processing image data: %s", err.message);
        }

        buffer.unmap (map_info);

        return pix;
    }
}
