// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*
 * Copyright (c) 2012 Noise Developers
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this program; see the file COPYING.  If not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Victor Eduardo <victoreduardm@gmail.com>
 */

namespace BeatBox.TimeUtils {

    /**
     * Receives the number of seconds and returns a string with format:
     * "DD days, HH hours and MM minutes".
     */
    public inline string time_string_from_seconds (uint seconds) {
        double secs = (double)seconds;

        const double SECONDS_PER_DAY    = 86400; // 24 x SECONDS_PER_HOUR
        const double SECONDS_PER_HOUR   = 3600;  // 60 X SECONDS_PER_MINUTE
        const double SECONDS_PER_MINUTE = 60;

        uint days = 0, hours = 0, minutes = 0;

        // calculate days
        days = Numeric.lowest_uint_from_double (secs / SECONDS_PER_DAY);
        secs -= days * SECONDS_PER_DAY;

        // calculate remaining hours
        hours = Numeric.lowest_uint_from_double (secs / SECONDS_PER_HOUR);
        secs -= hours * SECONDS_PER_HOUR;

        // calculate remaining minutes. Now the best (and not the lowest)
        // approximation is desired
        minutes = Numeric.uint_from_double (secs / SECONDS_PER_MINUTE);

        string days_string = "", hours_string = "", minutes_string = "";

        var rv = new StringBuilder ();

        if (days > 0) {
            if (days == 1)
                days_string = _("1 day");
            else
                days_string = _("%i days").printf ((int)days);
        }

        rv.append (days_string);

        if (hours > 0) {
            // add separator
            if (days_string != "")
                rv.append (", ");

            if (hours == 1)
                hours_string = _("1 hour");
            else
                hours_string = _("%i hours").printf ((int)hours);
        }

        rv.append (hours_string);

        if (minutes > 0) {
            // add separator
            if (hours_string != "" || days_string != "")
                rv.append (" and ");

            if (minutes == 1)
                minutes_string = _("1 minute");
            else
                minutes_string = _("%i minutes").printf ((int)minutes);
        }

        rv.append (minutes_string);

        return String.remove_trailing_white_space (rv.str);
    }

    /**
     * Receives the number of seconds and returns a string with format MM:SS
     */
    public inline string pretty_time_mins (uint seconds) {
        uint minutes = Numeric.lowest_uint_from_double ((double)seconds / 60);
        seconds -= minutes * 60;

        // Add '0' if seconds is between '0' and '9'
        return "%s:%s".printf (@"$minutes", ((seconds < 10 ) ? @"0$seconds" : @"$seconds"));
    }

    /**
     * Returns a formatted date and time string.
     * TODO: Use locale settings to decide format
     */
    public string pretty_timestamp_from_time (Time dt) {
        return dt.format ("%m/%e/%Y %l:%M %p");
    }

    public string pretty_timestamp_from_uint (uint time) {
        var dt = Time.local (time);
        return pretty_timestamp_from_time (dt);
    }

}

