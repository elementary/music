/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2021 elementary, Inc. (https://elementary.io)
 */

public class Music.SeekBar : Gtk.Grid {
    private bool scale_pressed = false;

    private int64 _playback_duration;
    public int64 playback_duration {
        get {
            return _playback_duration;
        }
        set {
            int64 duration = value;
            if (duration < 0) {
                duration = 0;
            }

            _playback_duration = duration;

            duration_label.label = "<span font-features='tnum'>%s</span>".printf (
                Granite.DateTime.seconds_to_time ((int) (duration / Gst.SECOND))
            );
        }
    }

    private int64 _playback_position;
    public int64 playback_position {
        get {
            return _playback_position;
        }
        set {
            int64 position = value;
            if (position < 0) {
                position = 0;
            }

            _playback_position = position;

            position_label.label = "<span font-features='tnum'>%s</span>".printf (
                Granite.DateTime.seconds_to_time ((int) (position / Gst.SECOND))
            );

            if (!scale_pressed) {
                scale.set_value ((double) 1 / playback_duration * position);
            }
        }
    }

    private Gtk.Label duration_label;
    private Gtk.Label position_label;
    private Gtk.Scale scale;

    construct {
        position_label = new Gtk.Label (null) {
            use_markup = true
        };
        duration_label = new Gtk.Label (null) {
            use_markup = true
        };

        scale = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0, 1, 0.1) {
            draw_value = false,
            hexpand = true
        };

        scale.button_press_event.connect (() => {
            scale_pressed = true;
            return Gdk.EVENT_PROPAGATE;
        });

        scale.button_release_event.connect (() => {
            PlaybackManager.get_default ().seek_to_progress (scale.get_value ());
            scale_pressed = false;
            return Gdk.EVENT_PROPAGATE;
        });

        column_spacing = 6;
        get_style_context ().add_class (Granite.STYLE_CLASS_SEEKBAR);
        add (position_label);
        add (scale);
        add (duration_label);
    }
}
