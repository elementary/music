/*
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

public class Noise.MediaMenu : Gtk.Menu {
    public bool can_scroll_to_current { get; construct; }
    public GenericList generic_list { get; construct; }

    public MediaMenu (GenericList generic_list, bool can_scroll_to_current) {
        Object (
            can_scroll_to_current: can_scroll_to_current,
            generic_list: generic_list
        );
    }

    construct {
        var scroll_to_current = new Gtk.MenuItem.with_label (_("Scroll to Current Song"));
        scroll_to_current.sensitive = false;

        if (can_scroll_to_current) {
            append (scroll_to_current);
            append (new Gtk.SeparatorMenuItem ());
        }

        scroll_to_current.activate.connect (() => {
            generic_list.scroll_to_current_media (true);
        });

        App.player.playback_stopped.connect (() => {
            scroll_to_current.sensitive = false;
        });

        App.player.playback_started.connect (() => {
            scroll_to_current.sensitive = true;
        });
    }
}
