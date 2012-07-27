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

namespace Noise.TimeUtils {

    /**
     * Receives the number of seconds and returns a string with format:
     * "%i days, %i hours and %i minutes", "%i seconds", "%i minutes and %i seconds",
     * or similar.
     */
    public inline string time_string_from_seconds (uint seconds) {
        const uint SECONDS_PER_MINUTE = 60;

        if (seconds < SECONDS_PER_MINUTE)
            return ngettext ("%d second", "%d seconds", seconds).printf (seconds);

        uint SECONDS_PER_HOUR = 60 * SECONDS_PER_MINUTE;
        uint SECONDS_PER_DAY = 24 * SECONDS_PER_HOUR;

        string days_string = "", hours_string = "", minutes_string = "", seconds_string = "";
        uint days = 0, hours = 0, minutes = 0;

        // If less than one hour, show minutes + seconds
        if (seconds < SECONDS_PER_HOUR) {
            minutes = Numeric.lowest_uint_from_double (seconds / SECONDS_PER_MINUTE);
            minutes_string = ngettext ("%u minute", "%u minutes", minutes).printf (minutes);
            seconds -= minutes * SECONDS_PER_MINUTE;
            seconds_string = ngettext ("%u second", "%u seconds", seconds).printf (seconds);
            return _("%s and %s").printf (minutes_string, seconds_string);
        }

        // calculate days
        days = Numeric.lowest_uint_from_double (seconds / SECONDS_PER_DAY);
        seconds -= days * SECONDS_PER_DAY;

        // calculate remaining hours
        hours = Numeric.lowest_uint_from_double (seconds / SECONDS_PER_HOUR);
        seconds -= hours * SECONDS_PER_HOUR;

        // calculate remaining minutes. Now the best (and not the lowest)
        // approximation is desired
        minutes = Numeric.uint_from_double (seconds / SECONDS_PER_MINUTE);

        if (days > 0)
            days_string = ngettext ("%u day", "%u days", days).printf (days);

        if (hours > 0)
            hours_string = ngettext ("%u hour", "%u hours", hours).printf (hours);

        if (minutes > 0)
            minutes_string = ngettext ("%u minute", "%u minutes", minutes).printf (minutes);

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
                // In theory, this will never be reached,
                // since we handle this case above.
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
        return "%u:%02u".printf (minutes, seconds);
    }

    /**
     * Returns a formatted date and time string.
     * TODO: Use locale settings to decide format
     */
    public inline string pretty_timestamp_from_time (Time dt) {
        return dt.format ("%m/%e/%Y %l:%M %p");
    }

    public inline string pretty_timestamp_from_uint (uint time) {
        var dt = Time.local (time);
        return pretty_timestamp_from_time (dt);
    }

}

