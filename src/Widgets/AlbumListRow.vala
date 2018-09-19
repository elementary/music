/*-
 * Copyright (c) 2018 elementary LLC. (https://elementary.io)
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
 */

public class Noise.AlbumListRow : Gtk.FlowBoxChild {
    public Media media { get; construct; }
    private Gtk.Revealer play_revealer;

    public AlbumListRow (Media media) {
        Object (media: media);
    }

    construct {
        var play_icon = new Gtk.Image.from_icon_name ("audio-volume-high-symbolic", Gtk.IconSize.MENU);

        play_revealer = new Gtk.Revealer ();
        play_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        play_revealer.add (play_icon);

        var title_label = new Gtk.Label (media.get_display_title ());
        title_label.hexpand = true;
        title_label.ellipsize = Pango.EllipsizeMode.END;
        title_label.xalign = 0;

        var time_label = new Gtk.Label (Granite.DateTime.seconds_to_time ((int)media.length / 1000));
        time_label.margin_end = 20;
        time_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        var grid = new Gtk.Grid ();
        grid.column_spacing = 6;
        grid.margin = 6;
        grid.add (play_revealer);
        grid.add (title_label);
        grid.add (time_label);

        margin_start = margin_end = 3;
        add (grid);

        update_play_icon ();

        App.player.playback_started.connect (()=> {
            update_play_icon ();
        });

        App.player.playback_paused.connect (()=> {
            update_play_icon ();
        });

        App.player.player_changed.connect (()=> {
            update_play_icon ();
        });
    }

    private void update_play_icon () {
        play_revealer.reveal_child = App.player.current_media == media && App.player.playing;
    }
}
