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
     * Receives the number of seconds and returns a string with format MM:SS
     */
    public inline string pretty_time_mins (uint seconds) {
        //make pretty current time
		uint minute = 0;

        // FIXME: not efficient with large numbers. Instead make a division
		while (seconds >= 60) {
			++ minute;
			seconds -= 60;
		}

        // Add '0' if seconds is between '0' and '9'
        return "%s:%s".printf (@"$minute", ((seconds < 10 ) ? @"0$seconds" : @"$seconds"));
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

