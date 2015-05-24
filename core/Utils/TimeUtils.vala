// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*
 * Copyright (c) 2012-2013 Noise Developers (http://launchpad.net/noise)
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
 *
 * The Noise authors hereby grant permission for non-GPL compatible
 * GStreamer plugins to be used and distributed together with GStreamer
 * and Noise. This permission is above and beyond the permissions granted
 * by the GPL license by which Noise is covered. If you modify this code
 * you may extend this exception to your version of the code, but you are not
 * obligated to do so. If you do not wish to do so, delete this exception
 * statement from your version.
 *
 * Authored by: Victor Eduardo <victoreduardm@gmail.com>
 */

namespace Noise.TimeUtils {
    public const uint64 NANO_INV = 1000000000;
    public const uint64 MILI_INV = 1000;

    public const uint SECONDS_PER_MINUTE = 60;
    public const uint SECONDS_PER_HOUR = 60 * SECONDS_PER_MINUTE;
    public const uint SECONDS_PER_DAY = 24 * SECONDS_PER_HOUR;

    /**
     * Receives the number of seconds and returns a string with format:
     * "%i days, %i hours and %i minutes", "%i seconds", "%i minutes and %i seconds",
     * or similar.
     */
    public inline string time_string_from_seconds (uint given_seconds) {
        uint days = given_seconds / 86400;
        uint hours = (given_seconds - days * 86400) / 3600;
        uint minutes = (given_seconds - days * 86400 - hours * 3600) / 60;
        uint seconds = given_seconds - days * 86400 - hours * 3600 - minutes * 60;

        if (given_seconds < SECONDS_PER_MINUTE)
            return ngettext ("%d second", "%d seconds", seconds).printf (seconds);

        string days_string = "", hours_string = "", minutes_string = "", seconds_string = "";

        // If less than one hour, show minutes + seconds
        if (given_seconds < SECONDS_PER_HOUR) {
            minutes_string = ngettext ("%u minute", "%u minutes", minutes).printf (minutes);

            if (seconds > 0) {
                seconds_string = ngettext ("%u second", "%u seconds", seconds).printf (seconds);
                /// Minutes and seconds
                return C_("minutes and seconds", "%s and %s").printf (minutes_string, seconds_string);
            }

            return minutes_string;
        }

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
                    /// days, hours and minutes
                    rv = C_("days, hours and minutes", "%s, %s and %s").printf (days_string, hours_string, minutes_string);
                else
                    /// days and hours
                    rv = C_("days and hours", "%s and %s").printf (days_string, hours_string);
            }
            else {
                if (minutes > 0)
                    /// days and minutes
                    rv = C_("days and minutes", "%s and %s").printf (days_string, minutes_string);
                else
                    rv = days_string;
            }
        }
        else {
            if (hours > 0) {
                if (minutes > 0)
                    /// hours and minutes
                    rv = C_("hours and minutes", "%s and %s").printf (hours_string, minutes_string);
                else
                    rv = hours_string;
            }
            else {
                // In theory, this will never be reached, since we handle it at the beginning.
                rv = minutes_string;
                warning ("Minutes string '%s'. Should not be reached", rv);
            }
        }

        return rv;
    }

    public inline string time_string_from_miliseconds (uint64 miliseconds) {
        return time_string_from_seconds ((uint)(miliseconds / MILI_INV));
    }

    public inline string time_string_from_nanoseconds (uint64 nanoseconds) {
        return time_string_from_seconds ((uint)(nanoseconds / NANO_INV));
    }

    /**
     * Receives the number of seconds and returns a string with format MM:SS
     */
    public inline string pretty_length (uint seconds) {
        if (seconds < SECONDS_PER_HOUR) {
            uint minutes = seconds / 60;
            seconds -= minutes * 60;
            return "%u:%02u".printf (minutes, seconds);
        }

        uint hours = seconds / 3600;
        seconds -= hours * 3600;
        uint minutes = seconds / 60;
        seconds -= minutes * 60;
        return "%u:%02u:%02u".printf (hours, minutes, seconds);
    }

    /**
     * Receives the number of miliseconds and returns a string with format MM:SS
     */
    public inline string pretty_length_from_ms (uint64 mseconds) {
        return pretty_length ((uint)(mseconds / MILI_INV));
    }

    /**
     * Receives the number of nanoseconds and returns a string with format MM:SS
     */
    public inline string pretty_length_from_ns (uint64 nseconds) {
        return pretty_length ((uint)(nseconds / NANO_INV));
    }

    /**
     * Returns a formatted date and time string.
     */
    public inline string pretty_timestamp_from_time (Time dt) {
        /// Format of date strings. See reference documentation of g_date_time_format()
        /// for more details.
        return dt.format (_("%m/%e/%Y %l:%M %p"));
    }

    public inline string pretty_timestamp_from_uint (uint time) {
        var dt = Time.local (time);
        return pretty_timestamp_from_time (dt);
    }

    /**
     * Convert from nanoseconds (10E-9) to miliseconds (10E-3);
     *
     * This is used extensively because {@link Noise.Media} stores
     * miliseconds, while GStreamer uses nanoseconds.
     *
     * The method does its best to avoid losing precision.
     */
    public inline uint nanoseconds_to_miliseconds (uint64 nanoseconds) {
        return (uint) (nanoseconds * MILI_INV / NANO_INV);
    }

    public inline uint64 miliseconds_to_nanoseconds (uint miliseconds) {
        return (uint64) miliseconds * NANO_INV / MILI_INV;
    }
}
