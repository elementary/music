/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2021 elementary, Inc. (https://elementary.io)
 */

public class Music.SeekBar : Gtk.Box {
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

            if (!scale_pressed) {
                position_label.label = "<span font-features='tnum'>%s</span>".printf (
                    Granite.DateTime.seconds_to_time ((int) (position / Gst.SECOND))
                );

                if (position != 0) {
                    scale.set_value ((double) 1 / playback_duration * position);
                } else {
                    scale.set_value (0);
                }

            }
        }
    }

    private Gtk.Label duration_label;
    private Gtk.Label position_label;
    private Gtk.Scale scale;

    construct {
        position_label = new Gtk.Label ("--:--") {
            use_markup = true
        };
        duration_label = new Gtk.Label ("--:--") {
            use_markup = true
        };

        var scale_event_controller = new Gtk.GestureClick ();

        scale = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0, 1, 0.1) {
            draw_value = false,
            hexpand = true
        };
        scale.add_controller (scale_event_controller);
        scale.add_css_class (Granite.STYLE_CLASS_ACCENT);

        spacing = 6;
        add_css_class (Granite.STYLE_CLASS_SEEKBAR);
        append (position_label);
        append (scale);
        append (duration_label);

        scale_event_controller.pressed.connect (() => {
            scale.value_changed.connect (scale_value_changed);

            scale_pressed = true;
        });

        scale_event_controller.stopped.connect (() => {
            scale.value_changed.disconnect (scale_value_changed);
            PlaybackManager.get_default ().seek_to_progress (scale.get_value ());
            scale_pressed = false;
        });
    }

    private void scale_value_changed () {
        position_label.label = "<span font-features='tnum'>%s</span>".printf (
            Granite.DateTime.seconds_to_time ((int) (scale.get_value () * (playback_duration / Gst.SECOND)))
        );
    }
}
