// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
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
 * Authored by: Victor Eduardo <victoreduardm@gmail.com>
 */

namespace Noise.TimeUtils {
    public const uint64 NANO_INV = 1000000000;
    public const uint64 MILI_INV = 1000;
    private const uint64 SEC_INV = 1;

    /**
     * Returns a formatted date and time string.
     */
    public inline string pretty_timestamp_from_time (Time dt) {
        /// Format of date strings. See reference documentation of g_date_time_format()
        /// for more details.
        return dt.format (_("%m/%e/%Y %l:%M %p"));
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

    public inline uint nanoseconds_to_seconds (uint64 nanoseconds) {
        return (uint) (nanoseconds * SEC_INV / NANO_INV);
    }

    public inline uint64 seconds_to_nanoseconds (uint64 seconds) {
        return (uint64) (seconds * NANO_INV / SEC_INV);
    }
}
