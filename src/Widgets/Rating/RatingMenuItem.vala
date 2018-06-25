/*-
 * Copyright (c) 2012-2018 elementary LLC. (https://elementary.io)
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
 * Authored by: Lucas Baudin <xapantu@gmail.com>,
 *              Victor Eduardo <victoreduardm@gmail.com>
 */

public class Music.RatingMenuItem : Gtk.MenuItem {
    public RatingWidget rating { get; private set; }

    public int rating_value {
        get { return rating.rating; }
        set { rating.rating = value; }
    }

    public RatingMenuItem () {
        rating = new RatingWidget (false, Gtk.IconSize.MENU, false);
        add (rating);

        // Workaround. Move the offset one star to the left for menuitems.
        rating.rating_offset = - (double) rating.item_width - (double) rating.star_spacing;

        this.state_flags_changed.connect ( () => {
            // Suppress SELECTED and PRELIGHT states, since these are usually obtrusive
            var selected_flags = Gtk.StateFlags.SELECTED | Gtk.StateFlags.PRELIGHT;
            if ((get_state_flags () & selected_flags) != 0) {
                unset_state_flags (selected_flags);
            }
        });
    }

    public override bool motion_notify_event (Gdk.EventMotion ev) {
        rating.motion_notify_event (ev);
        rating.queue_draw ();
        return true;
    }

    public override bool button_press_event (Gdk.EventButton ev) {
        rating.button_press_event (ev);
        activate ();
        return true;
    }

    public override bool leave_notify_event (Gdk.EventCrossing ev) {
        rating.update_rating (rating_value);
        return true;
    }
}
