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
     * "%i days, %i hours and %i minutes", "%i seconds", "%i minutes and %i seconds",
     * or similar.
     */
    public inline string time_string_from_seconds (uint seconds) {
        const double SECONDS_PER_MINUTE = 60;
        const double SECONDS_PER_HOUR   = 3600;  // 60 X SECONDS_PER_MINUTE
        const double SECONDS_PER_DAY    = 86400; // 24 x SECONDS_PER_HOUR

        if (seconds < SECONDS_PER_MINUTE) {
            if (seconds < 1)
                return "";

            if (seconds < 2)
                return _("1 second");

            return _("%u seconds").printf (seconds);
        }

        double secs = (double)seconds; // XXX: this cast is dangerous
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

        if (days > 0) {
            if (days == 1)
                days_string = _("1 day");
            else
                days_string = _("%i days").printf ((int)days);
        }

        if (hours > 0) {
            if (hours == 1)
                hours_string = _("1 hour");
            else
                hours_string = _("%i hours").printf ((int)hours);
        }

        if (minutes > 0) {
            if (minutes == 1)
                minutes_string = _("1 minute");
            else
                minutes_string = _("%i minutes").printf ((int)minutes);
        }

#if 0
                // if less than one hour, show minutes + seconds
                int mins = Numeric.lowest_uint_from_double (secs / SECONDS_PER_MINUTE);
                // There is obviously more than one minute. Otherwise we would have returned
                // waay earlier
                minutes_string = _("").printf ()
                secs -= mins * SECONDS_PER_MINUTE;
                return _("%s and %s").printf (minutes_string, seconds_string);
#endif

        string rv = "";

        if (days > 0) {
            if (hours > 0) {
                if (minutes > 0)
                    rv = _("%s, %s and %s").printf (days_string, hours_string, minutes_string);
                else
                    rv = _("%s and %s").printf (days_string, hours_string);
            }
            else {
                if (minutes > 0)
                    rv = _("%s and %s").printf (days_string, minutes_string);
                else
                    rv = days_string;
            }
        }
        else {
            if (hours > 0) {
                if (minutes > 0)
                    rv = _("%s and %s").printf (hours_string, minutes_string);
                else
                    rv = hours_string;
            }
            else {
                rv = minutes_string;
            }
        }

        return rv;
    }

    /**
     * Receives the number of seconds and returns a string with format MM:SS
     */
    public inline string pretty_time_mins (uint seconds) {
        uint minutes = Numeric.lowest_uint_from_double ((double)seconds / 60);
        seconds -= minutes * 60;

        // Add '0' if seconds are between '0' and '9'
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

