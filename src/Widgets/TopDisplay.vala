/*-
 * Copyright (c) 2011-2012       Scott Ringwelski <sgringwe@mtu.edu>
 *
 * Originally Written by Scott Ringwelski for BeatBox Music Player
 * BeatBox Music Player: http://www.launchpad.net/beat-box
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

public class Noise.TopDisplay : Gtk.Stack {
    MusicListView list_view;

    Gtk.Grid empty_grid;

    // Time Grid
    Gtk.EventBox time_eventbox;
    Gtk.Grid time_grid;
    Gtk.Label track_label;
    Gtk.Label leftTime;
    Gtk.Label rightTime;
    Gtk.Scale scale;

    // Action Grid
    Gtk.Grid action_grid;
    Gtk.Label action_label;
    Gtk.ProgressBar progressbar;
    Gtk.Button cancelButton;

    private bool is_seeking = false;
    private uint change_timeout_id = 0;
    private uint progress_timeout_id = 0;

    public signal void scale_value_changed (Gtk.ScrollType scroll, double val);

    public TopDisplay () {
        this.get_style_context ().add_class ("seek-bar");
    }

    construct {
        /* GUI */
        transition_type = Gtk.StackTransitionType.CROSSFADE;

        time_grid = new Gtk.Grid ();
        time_grid.column_spacing = 6;
        track_label = new Gtk.Label ("");
        track_label.hexpand = true;
        track_label.justify = Gtk.Justification.CENTER;
        track_label.single_line_mode = false;
        track_label.ellipsize = Pango.EllipsizeMode.END;
        scale = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0, 1, 1000);
        scale.hexpand = true;
        scale.draw_value = false;
        scale.can_focus = false;
        scale.hexpand = true;
        leftTime = new Gtk.Label ("0:00");
        rightTime = new Gtk.Label ("0:00");
        time_grid.attach (track_label, 0, 0, 3, 1);
        time_grid.attach (leftTime, 0, 1, 1, 1);
        time_grid.attach (scale, 1, 1, 1, 1);
        time_grid.attach (rightTime, 2, 1, 1, 1);
        time_eventbox = new Gtk.EventBox ();
        time_eventbox.add (time_grid);

        action_grid = new Gtk.Grid ();
        action_grid.column_spacing = 6;
        action_grid.row_spacing = 6;
        action_label = new Gtk.Label ("");
        action_label.hexpand = true;
        action_label.justify = Gtk.Justification.CENTER;
        action_label.single_line_mode = false;
        action_label.ellipsize = Pango.EllipsizeMode.END;
        progressbar = new Gtk.ProgressBar ();
        progressbar.fraction = 1;
        cancelButton = new Gtk.Button.from_icon_name (Icons.PROCESS_STOP.name, Gtk.IconSize.MENU);
        cancelButton.halign = cancelButton.valign = Gtk.Align.CENTER;
        cancelButton.vexpand = true;
        cancelButton.tooltip_text = _(STRING_CANCEL);
        action_grid.attach (action_label, 0, 0, 1, 1);
        action_grid.attach (progressbar, 0, 1, 1, 1);
        action_grid.attach (cancelButton, 1, 0, 1, 2);

        time_eventbox.button_press_event.connect ((e) => {
            if (e.button == Gdk.BUTTON_SECONDARY) {
                var current = new Gee.TreeSet<Media> ();
                if (App.player.current_media != null)
                    current.add (App.player.current_media);
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

        cancelButton.clicked.connect (() => {
            NotificationManager.get_default ().progress_canceled ();
        });

        scale.button_press_event.connect (scale_button_press);
        scale.button_release_event.connect (scale_button_release);
        scale.value_changed.connect (value_changed);
        scale.change_value.connect (change_value);

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

    public override void get_preferred_width (out int minimum_width, out int natural_width) {
        base.get_preferred_width (out minimum_width, out natural_width);
        minimum_width = 200;
        if (natural_width < 600)
            natural_width = 600;
    }

    public void set_list_view (MusicListView list_view) {
        this.list_view = list_view;
    }

    // automatically shows/hides progress bar/scale based on progress's value
    public void set_progress_value (double progress) {
        progressbar.fraction = progress;
        update_view ();
    }

    public void set_max_time (double max) {
        scale.set_range (0, max);
    }

    public void set_current_time (double val) {
        scale.set_value (val);
    }

    public double get_scale_value () {
        return scale.get_value ();
    }

    public virtual bool scale_button_press (Gdk.EventButton event) {
        if (event.type != Gdk.EventType.BUTTON_PRESS) {
            return true;
        }

        App.player.player.current_position_update.disconnect (player_position_update);
        is_seeking = true;
        change_value (Gtk.ScrollType.NONE, get_current_time ());

        return false;
    }

    public virtual bool scale_button_release (Gdk.EventButton event) {
        is_seeking = false;
        change_value (Gtk.ScrollType.NONE, get_current_time ());
        return false;
    }

    public double get_current_time () {
        Gtk.Allocation extents;
        double point_x = 0;
        Gdk.ModifierType mask;
        unowned Gdk.Display display = Gdk.Display.get_default ();
        unowned Gdk.Window scale_window = scale.get_window ();
        unowned Gdk.DeviceManager device_manager = display.get_device_manager ();
        scale_window.get_device_position_double (device_manager.get_client_pointer (), out point_x, null, out mask);
        scale.get_allocation (out extents);
        point_x = point_x - extents.x;
        if (point_x < 0)
            point_x = 0;

        // get miliseconds of media
        // calculate percentage to go to based on location
        return (double)point_x / (double)extents.width * scale.get_adjustment().upper;
    }

    public virtual void value_changed () {
        if (!scale.visible)
            return;

        double val = scale.get_value ();
        if (val < 0.0)
            val = 0.0;

        //make pretty current time
        uint elapsed_secs = (uint)val;
        leftTime.set_text (TimeUtils.pretty_length_from_ms (elapsed_secs));

        uint media_duration_secs = (uint)App.player.current_media.length;

        //make pretty remaining time
        rightTime.set_text (TimeUtils.pretty_length_from_ms (media_duration_secs - elapsed_secs));
    }

    public virtual bool change_value (Gtk.ScrollType scroll, double val) {
        App.player.player.current_position_update.disconnect(player_position_update);
        scale.set_value(val);
        scale_value_changed(scroll, val);

        if (change_timeout_id > 0)
            Source.remove (change_timeout_id);

        change_timeout_id = Timeout.add (300, () => {
            if (!is_seeking) {
                App.player.player.set_position((int64) TimeUtils.miliseconds_to_nanoseconds ((uint) val));
                App.player.player.current_position_update.connect(player_position_update);
            }

            change_timeout_id = 0;
            return false;
        });

        return false;
    }

    public virtual void player_position_update (int64 position) {
        if (App.player.current_media != null) {
            scale.set_value ((double) TimeUtils.nanoseconds_to_miliseconds (position));
        }
    }

    public void set_media (Media current_media) {
        update_current_media ();
        // If the media changes while an action is goind, show it for 5 seconds then come back to the action.
        if (progressbar.fraction >= 0.0 && progressbar.fraction < 1.0) {
            progress_timeout_id = Timeout.add (300, () => {
                update_view ();
                progress_timeout_id = 0;
                return false;
            });
        }
    }

    private void media_updated (Gee.Collection<int> ids) {
        if (App.player.current_media != null && ids.contains (App.player.current_media.rowid)) {
            update_current_media ();
        }
    }

    private void update_current_media () {
        var notification_manager = NotificationManager.get_default ();
        if (App.player.current_media == null)
            return;

        // Set the title
        var m = App.player.current_media;
        if (m == null)
            return;

        notification_manager.update_track (m.get_title_markup ());
        set_max_time ((double) m.length);
        set_visible_child (time_eventbox);
    }

    private void update_view () {
        if (progressbar.fraction >= 0.0 && progressbar.fraction < 1.0) {
            set_visible_child (action_grid);
        } else if (App.player.current_media != null) {
            set_visible_child (time_eventbox);
        } else {
            set_visible_child (empty_grid);
        }
    }
}
