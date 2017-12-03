// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012-2017 elementary LLC. (https://elementary.io)
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
 */

public class Noise.TopDisplay : Gtk.Stack {
    MusicListView list_view;

    Gtk.Grid empty_grid;

    // Time Grid
    Gtk.EventBox time_eventbox;
    Gtk.Grid time_grid;
    Gtk.Label track_label;
    Granite.SeekBar seek_bar;

    // Action Grid
    Gtk.Grid action_grid;
    Gtk.Label action_label;
    Gtk.ProgressBar progress_bar;
    Gtk.Button cancel_button;

    private uint change_timeout_id = 0;
    private uint progress_timeout_id = 0;

    public signal void scale_value_changed (Gtk.ScrollType scroll, double val);

    construct {
        /* GUI */
        transition_type = Gtk.StackTransitionType.CROSSFADE;

        seek_bar = new Granite.SeekBar (0.0);

        track_label = make_title_label ();

        time_grid = new Gtk.Grid ();
        time_grid.row_spacing = 6;
        time_grid.attach (track_label, 0, 0, 3, 1);
        time_grid.attach (seek_bar, 1, 1, 1, 1);
        time_eventbox = new Gtk.EventBox ();
        time_eventbox.add (time_grid);

        action_grid = new Gtk.Grid ();
        action_grid.column_spacing = 6;
        action_grid.row_spacing = 6;
        action_label = make_title_label ();
        progress_bar = new Gtk.ProgressBar ();
        progress_bar.fraction = 1;
        cancel_button = new Gtk.Button.from_icon_name ("process-stop-symbolic", Gtk.IconSize.MENU);
        cancel_button.halign = cancel_button.valign = Gtk.Align.CENTER;
        cancel_button.vexpand = true;
        cancel_button.tooltip_text = _("Cancel");
        action_grid.attach (action_label, 0, 0, 1, 1);
        action_grid.attach (progress_bar, 0, 1, 1, 1);
        action_grid.attach (cancel_button, 1, 0, 1, 2);

        time_eventbox.button_press_event.connect ((e) => {
            if (e.button == Gdk.BUTTON_SECONDARY) {
                var current = new Gee.TreeSet<Media> ();
                if (App.player.current_media != null) {
                    current.add (App.player.current_media);
                }
                list_view.popup_media_menu (current);
                return true;
            }

            return false;
        });

        empty_grid = new Gtk.Grid ();

        add_named (action_grid, "action");
        add_named (time_eventbox, "time");
        add_named (empty_grid, "empty");
        show_all ();
        set_visible_child (empty_grid);

        /* signals */

        cancel_button.clicked.connect (() => {
            NotificationManager.get_default ().progress_canceled ();
        });

        seek_bar.scale.change_value.connect (change_value);

        App.player.player.current_position_update.connect (player_position_update);

        App.player.changing_player.connect (() => {
            App.player.player.current_position_update.disconnect (player_position_update);
        });

        App.player.player_changed.connect (() => {
            App.player.player.current_position_update.connect (player_position_update);
        });

        var notification_manager = NotificationManager.get_default ();
        notification_manager.update_progress.connect ((message, progress) => {
            set_progress_value (progress);
            if (message != null)
                action_label.set_markup (message);
        });

        notification_manager.update_track.connect ((message) => {
            track_label.set_markup (message);
        });

        libraries_manager.local_library.media_updated.connect (media_updated);
    }

    private Gtk.Label make_title_label () {
        var label = new Gtk.Label ("");
        label.hexpand = true;
        label.justify = Gtk.Justification.CENTER;
        label.single_line_mode = false;
        label.ellipsize = Pango.EllipsizeMode.END;
        return label;
    }


    public override void get_preferred_width (out int minimum_width, out int natural_width) {
        base.get_preferred_width (out minimum_width, out natural_width);
        minimum_width = 200;
        if (natural_width < 600) {
            natural_width = 600;
        }
    }

    public void set_list_view (MusicListView list_view) {
        this.list_view = list_view;
    }

    // automatically shows/hides progress bar/seek_bar based on progress's value
    public void set_progress_value (double progress) {
        progress_bar.fraction = progress;
        update_view ();
    }

    public virtual bool change_value (Gtk.ScrollType scroll, double val) {
        App.player.player.current_position_update.disconnect(player_position_update);

        scale_value_changed(scroll, val);

        if (change_timeout_id > 0) {
            Source.remove (change_timeout_id);
        }

        change_timeout_id = Timeout.add (300, () => {
            if (!seek_bar.is_grabbing) {
                App.player.player.set_position((int64) TimeUtils.seconds_to_nanoseconds ((uint) (val * seek_bar.playback_duration)));
                App.player.player.current_position_update.connect(player_position_update);
            }

            change_timeout_id = 0;
            return false;
        });

        return false;
    }

    public virtual void player_position_update (int64 position) {
        if (App.player.current_media != null) {
            seek_bar.playback_progress = ((double) TimeUtils.nanoseconds_to_seconds (position)) / seek_bar.playback_duration;
        }
    }

    public void update_media () {
        update_current_media ();
        // If the media changes while an action is goind, show it for 5 seconds then come back to the action.
        if (progress_bar.fraction >= 0.0 && progress_bar.fraction < 1.0) {
            progress_timeout_id = Timeout.add (300, () => {
                update_view ();
                progress_timeout_id = 0;
                return false;
            });
        }
    }

    private void media_updated (Gee.Collection<int64?> ids) {
        if (App.player.current_media != null && ids.contains (App.player.current_media.rowid)) {
            update_current_media ();
        }
    }

    private void update_current_media () {
        var notification_manager = NotificationManager.get_default ();

        // Set the title
        var m = App.player.current_media;
        if (m != null) {
            notification_manager.update_track (m.get_title_markup ());
            seek_bar.playback_duration = ((double) m.length) / 1000.0;
            set_visible_child (time_eventbox);
        }
    }

    private void update_view () {
        if (progress_bar.fraction >= 0.0 && progress_bar.fraction < 1.0) {
            set_visible_child (action_grid);
        } else if (App.player.current_media != null) {
            set_visible_child (time_eventbox);
        } else {
            set_visible_child (empty_grid);
        }
    }
}
