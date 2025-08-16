/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2021-2022 elementary, Inc. (https://elementary.io)
 */

public class Music.PlaybackManager : Object {
    public AudioObject? current_audio { get; set; default = null; }
    public ListStore queue_liststore { get; private set; }
    public bool has_items { get; private set; }
    public uint n_items {
        get {
            return queue_liststore != null ? queue_liststore.get_n_items () : 0;
        }
    }
    public int64 playback_position { get; private set; }
    public signal void invalids_found (int count);

    private static GLib.Once<PlaybackManager> instance;
    public static unowned PlaybackManager get_default () {
        return instance.once (() => { return new PlaybackManager (); });
    }

    private dynamic Gst.Element playbin;
    private Gst.PbUtils.Discoverer discoverer;
    private uint progress_timer = 0;
    private Settings settings;

    private enum Direction {
        NONE,
        NEXT,
        PREVIOUS
    }

    private bool next_by_eos = false;

    private Direction direction = Direction.NONE;

    private SimpleAction next_action;
    private SimpleAction play_pause_action;
    private SimpleAction previous_action;
    private SimpleAction shuffle_action;

    private PlaybackManager () {}

    construct {
        settings = new Settings ("io.elementary.music");
        queue_liststore = new ListStore (typeof (AudioObject));

        playbin = Gst.ElementFactory.make ("playbin", "playbin");

        var bus = playbin.get_bus ();
        bus.add_watch (0, bus_callback);
        bus.enable_sync_message_emission ();

        try {
            discoverer = new Gst.PbUtils.Discoverer ((Gst.ClockTime) (5 * Gst.SECOND));
            discoverer.discovered.connect (update_metadata);
            discoverer.finished.connect (discoverer.stop);
        } catch (Error e) {
            critical ("Unable to start Gstreamer Discoverer: %s", e.message);
        }

        queue_liststore.items_changed.connect (on_items_changed);

        notify["current-audio"].connect (on_audio_changed);

        settings = new Settings ("io.elementary.music");

        var clear_action = new SimpleAction (Application.ACTION_CLEAR_QUEUE, null);
        clear_action.activate.connect (clear_queue);

        next_action = new SimpleAction (Application.ACTION_NEXT, null);
        next_action.activate.connect (() => next ());

        play_pause_action = new SimpleAction.stateful (Application.ACTION_PLAY_PAUSE, null, new Variant.boolean (false));
        play_pause_action.change_state.connect (play_pause);

        previous_action = new SimpleAction (Application.ACTION_PREVIOUS, null);
        previous_action.activate.connect (previous);

        shuffle_action = new SimpleAction (Application.ACTION_SHUFFLE, null);
        shuffle_action.activate.connect (shuffle);

        next_action.set_enabled (false);
        play_pause_action.set_enabled (false);
        previous_action.set_enabled (false);
        shuffle_action.set_enabled (false);

        unowned var app = GLib.Application.get_default ();
        app.add_action (clear_action);
        app.add_action (next_action);
        app.add_action (play_pause_action);
        app.add_action (previous_action);
        app.add_action (shuffle_action);

        bind_property ("has-items", clear_action, "enabled", SYNC_CREATE);
    }

    public void seek_to_progress (double percent) {
        playbin.seek_simple (Gst.Format.TIME, Gst.SeekFlags.FLUSH, (int64)(percent * current_audio.duration));
    }

    // Files[] must not contain any null entries
    public void queue_files (File[] files) {
        discoverer.start ();
        int invalids = 0;
        foreach (unowned var file in files) {
            if (file.query_exists () && "audio" in ContentType.guess (file.get_uri (), null, null)) {
                var audio_object = new AudioObject (file.get_uri ());

                string? basename = file.get_basename ();

                if (basename != null) {
                    audio_object.title = basename;
                } else {
                    audio_object.title = audio_object.uri;
                }

                discoverer.discover_uri_async (audio_object.uri);

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

    private void clear_queue () {
        playbin.set_state (Gst.State.NULL);
        current_audio = null;
        queue_liststore.remove_all ();
    }

    public void remove (AudioObject song) {
        if (song == current_audio) {
            playbin.set_state (Gst.State.NULL);
            current_audio = null;
        }

        uint position;
        queue_liststore.find (song, out position);
        queue_liststore.remove (position);
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
            return ((AudioObject) a).uri == ((AudioObject) b).uri;
        };

        var temp_audio_object = new AudioObject (uri);

        uint position = -1;
        queue_liststore.find_with_equal_func (temp_audio_object, equal_func, out position);

        if (position != -1) {
            var audio_object = (AudioObject) queue_liststore.get_item (position);
            audio_object.duration = (int64) info.get_duration ();

            unowned Gst.TagList? tag_list = info.get_tags ();

            string _album;
            tag_list.get_string (Gst.Tags.ALBUM, out _album);
            if (_album != null) {
                audio_object.album = _album;
            }

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

            string art_hash = uri;
            if (_artist != null && _album != null) {
                art_hash = "%s:%s".printf (_artist, _album);
            }

            var art_file = File.new_for_path (Path.build_path (
                Path.DIR_SEPARATOR_S,
                get_art_cache_dir (),
                Checksum.compute_for_string (SHA256, art_hash)
            ));

            if (art_file.query_exists ()) {
                audio_object.art_url = art_file.get_uri ();
                audio_object.texture = Gdk.Texture.from_file (art_file);
            } else {
                var sample = get_cover_sample (tag_list);
                if (sample != null) {
                    var buffer = sample.get_buffer ();

                    if (buffer != null) {
                        var texture = Gdk.Texture.for_pixbuf (get_pixbuf_from_buffer (buffer));
                        audio_object.texture = texture;

                        save_art_file.begin (texture, art_file, (obj, res) => {
                            try {
                                audio_object.art_url = save_art_file.end (res);
                            } catch (Error e) {
                                critical (e.message);
                            }
                        });
                    }
                }
            }
        } else {
            critical ("Couldn't find '%s' in queue", uri);
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

    private void play_pause (SimpleAction action, Variant? value) {
        action.set_state (value);

        if (value.get_boolean ()) {
            playbin.set_state (Gst.State.PLAYING);
        } else {
            playbin.set_state (Gst.State.PAUSED);
        }
    }

    private void next (bool eos = false) {
        direction = Direction.NEXT;
        next_by_eos = eos;
        uint position = -1;
        queue_liststore.find (current_audio, out position);

        if (position != -1) {
            if (!next_by_eos) {
                if (position == queue_liststore.get_n_items () - 1) {
                    current_audio = (AudioObject) queue_liststore.get_item (0);
                    if (position == 0) {
                        seek_to_progress (0);
                    }
                } else {
                    current_audio = (AudioObject) queue_liststore.get_item (position + 1);
                }

                return;
            }
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
                        if (position == 0) {
                            seek_to_progress (0);
                        }
                    } else {
                        current_audio = (AudioObject) queue_liststore.get_item (position + 1);
                    }

                    break;

                case "one":
                    seek_to_progress (0);
                    break;
            }
        }
    }

    private void previous () {
        direction = Direction.PREVIOUS;
        uint position = -1;
        queue_liststore.find (current_audio, out position);

        if (position != -1 && position != 0) {
            current_audio = (AudioObject) queue_liststore.get_item (position - 1);
        }

        if (position == 0) {
            uint n_items = queue_liststore.get_n_items ();
            if (n_items == 1) {
                seek_to_progress (0);
            } else {
                current_audio = (AudioObject) queue_liststore.get_item (n_items - 1);
            }
        }
    }

    private void shuffle () {
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

        next_sensitive = previous_sensitive = current_audio != null;

        next_action.set_enabled (next_sensitive);
        previous_action.set_enabled (previous_sensitive);
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

    private async string save_art_file (Gdk.Texture texture, File file) throws Error requires (texture != null) {
        DirUtils.create_with_parents (get_art_cache_dir (), 0755);

        var ostream = yield file.create_async (NONE);
        yield ostream.write_bytes_async (texture.save_to_png_bytes ());

        return file.get_uri ();
    }

    private string get_art_cache_dir () {
        return Path.build_path (
            Path.DIR_SEPARATOR_S,
            Environment.get_user_cache_dir (),
            GLib.Application.get_default ().application_id,
            "art"
        );
    }

    private void on_items_changed () {
        has_items = queue_liststore.get_n_items () > 0;
        shuffle_action.set_enabled (queue_liststore.get_n_items () > 1);
        update_next_previous_sensitivity ();
        save_queue ();
    }

    private void on_audio_changed () {
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

        play_pause_action.set_enabled (current_audio != null);

        var uri_last_played = current_audio != null ? current_audio.uri : "";
        settings.set_string ("uri-last-played", uri_last_played);
    }

    private void save_queue () {
        string[] list_uri = new string[queue_liststore.n_items];

        for (var i = 0; i < queue_liststore.n_items; i++) {
            var item = (Music.AudioObject)queue_liststore.get_item (i);
            list_uri[i] = item.uri;
        }

        settings.set_strv ("previous-queue", list_uri);
    }

    public void restore_queue () {
        // Restoring the queue overwrites the last played. So we need to retrieve it before taking care of the queue
        var uri_last_played = settings.get_string ("uri-last-played");
        var file_last_played = File.new_for_uri (uri_last_played);

        var last_session_uri = settings.get_strv ("previous-queue");
        var last_session_files = new File[last_session_uri.length];

        for (var i = 0; i < last_session_uri.length; i++) {
            var uri = last_session_uri[i];
            var file = File.new_for_uri (uri);
            last_session_files[i] = file;
        }

        var files_to_play = Application.loop_through_files (last_session_files);
        queue_files (files_to_play);

        if (uri_last_played != "" && file_last_played.query_exists ()) {
            var audio_object = new AudioObject (uri_last_played);
            uint position = -1;
            if (!queue_liststore.find_with_equal_func (
                audio_object,
                (EqualFunc<AudioObject>) AudioObject.equal_func,
                out position
            )) {
                return;
            }

            current_audio = (AudioObject) queue_liststore.get_item (position);
        }
    }
}
