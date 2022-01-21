/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2021 elementary, Inc. (https://elementary.io)
 */

public class Music.PlaybackManager : Object {
    public AudioObject? current_audio { get; private set; default = null; }
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
    private Gst.Bus bus;
    private Gst.PbUtils.Discoverer discoverer;
    private uint progress_timer = 0;

    private Settings settings;

    private PlaybackManager () {}

    construct {
        queue_liststore = new ListStore (typeof (AudioObject));

        playbin = Gst.ElementFactory.make ("playbin", "playbin");

        bus = playbin.get_bus ();
        bus.add_watch (0, bus_callback);
        bus.enable_sync_message_emission ();

        try {
            discoverer = new Gst.PbUtils.Discoverer ((Gst.ClockTime) (5 * Gst.SECOND));
            discoverer.discovered.connect (update_metadata);
            discoverer.finished.connect (discoverer.stop);
        } catch (Error e) {
            critical ("Unable to start Gstreamer Discoverer: %s", e.message);
        }

        queue_liststore.items_changed.connect (() => {
            update_next_previous_sensitivity ();
        });

        notify["current-audio"].connect (() => {
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
        discoverer.start ();
        foreach (unowned var file in files) {
            if (file.query_exists ()) {
                var audio_object = new AudioObject (file);
                audio_object.title = audio_object.file.get_path ();

                discoverer.discover_uri_async (audio_object.file.get_uri ());

                queue_liststore.append (audio_object);
            }
        }

        if (current_audio == null) {
            var audio_object = (AudioObject) queue_liststore.get_object (0);
            if (audio_object != null) {
                current_audio = audio_object;
                playbin.uri = audio_object.file.get_uri ();
                playbin.set_state (Gst.State.PLAYING);
            } else {
                reset_metadata ();
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

    private void update_metadata (Gst.PbUtils.DiscovererInfo info, Error? err) {
        string uri = info.get_uri ();
        switch (info.get_result ()) {
            case Gst.PbUtils.DiscovererResult.URI_INVALID:
                critical ("Couldn't read metadata for '%s': invalid URI.", uri);
                return;
            case Gst.PbUtils.DiscovererResult.ERROR:
                critical ("Couldn't read metadata for '%s': %s", uri, err.message);
                return;
            case Gst.PbUtils.DiscovererResult.TIMEOUT:
                critical ("Couldn't read metadata for '%s': Discovery timed out.", uri);
                return;
            case Gst.PbUtils.DiscovererResult.BUSY:
                critical ("Couldn't read metadata for '%s': Already discovering a file.", uri);
                return;
            case Gst.PbUtils.DiscovererResult.MISSING_PLUGINS:
                critical ("Couldn't read metadata for '%s': Missing plugins.", uri);
                return;
            default:
                break;
        }

        EqualFunc<string> equal_func = (a, b) => {
            return ((AudioObject) a).file.get_uri () == ((AudioObject) b).file.get_uri () ;
        };

        var temp_audio_object = new AudioObject (File.new_for_uri (uri));

        uint position = -1;
        queue_liststore.find_with_equal_func (temp_audio_object, equal_func, out position);

        if (position != -1) {
            var audio_object = (AudioObject) queue_liststore.get_item (position);
            audio_object.duration = (int64) info.get_duration ();

            unowned Gst.TagList? tag_list = info.get_tags ();

            string _title;
            tag_list.get_string (Gst.Tags.TITLE, out _title);
            if (_title != null) {
                audio_object.title = _title;
            }

            string _artist;
            tag_list.get_string (Gst.Tags.ARTIST, out _artist);
            if (_artist != null) {
                audio_object.artist = _artist;
            } else if (_title != null) { // Don't set artist for files without tags
                audio_object.artist = _("Unknown");
            }

            var sample = get_cover_sample (tag_list);
            if (sample != null) {
                var buffer = sample.get_buffer ();

                if (buffer != null) {
                    audio_object.texture = Gdk.Texture.for_pixbuf (get_pixbuf_from_buffer (buffer));
                }
            }
        } else {
            critical ("Couldn't find '%s' in queue", uri);
        }
    }

    private bool bus_callback (Gst.Bus bus, Gst.Message message) {
        switch (message.type) {
            case Gst.MessageType.EOS:
                next ();
                break;
            case Gst.MessageType.STATE_CHANGED:
                Gst.State old_state, new_state, pending_state;
                message.parse_state_changed (out old_state, out new_state, out pending_state);

                var play_pause_action = (SimpleAction) GLib.Application.get_default ().lookup_action (Application.ACTION_PLAY_PAUSE);
                if (new_state == Gst.State.PLAYING) {
                    play_pause_action.set_state (true);

                    if (current_audio.duration == 0) {
                        // It may take time to calculate the length, so we keep
                        // checking until we get something reasonable
                        GLib.Timeout.add (250, () => {
                            int64 duration = 0;
                            playbin.query_duration (Gst.Format.TIME, out duration);
                            current_audio.duration = duration;

                            if (current_audio.duration > 0) {
                                return Source.REMOVE;
                            }

                            return Source.CONTINUE;
                        });
                    }

                    progress_timer = GLib.Timeout.add (250, () => {
                        int64 position = 0;
                        playbin.query_position (Gst.Format.TIME, out position);
                        playback_position = position.clamp (0, current_audio.duration);

                        return Source.CONTINUE;
                    });
                } else {
                    play_pause_action.set_state (false);

                    if (progress_timer != 0) {
                        Source.remove (progress_timer);
                        progress_timer = 0;
                    }
                }
                break;
            default:
                break;
        }

        return true;
    }

    public void play_pause (bool playing) {
        if (playing) {
            playbin.set_state (Gst.State.PAUSED);
        } else {
            playbin.set_state (Gst.State.PLAYING);
        }
    }

    public void next () {
        playbin.set_state (Gst.State.NULL);

        uint position = -1;
        queue_liststore.find (current_audio, out position);

        if (position != -1) {
            playback_position = 0;

            switch (settings.get_string ("repeat-mode")) {
                case "disabled":
                    if (position == queue_liststore.get_n_items () - 1) {
                        reset_metadata ();
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

            playbin.uri = current_audio.file.get_uri ();
            playbin.set_state (Gst.State.PLAYING);
        }
    }

    public void previous () {
        playbin.set_state (Gst.State.NULL);

        uint position = -1;
        queue_liststore.find (current_audio, out position);

        if (position != -1 && position != 0) {
            playback_position = 0;

            current_audio = (AudioObject) queue_liststore.get_item (position - 1);
            playbin.uri = current_audio.file.get_uri ();
            playbin.set_state (Gst.State.PLAYING);
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

    private void reset_metadata () {
        current_audio = null;
        playbin.set_state (Gst.State.NULL);
        playbin.uri = "";
        playback_position = 0;
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
