// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
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

namespace Noise.Numeric {

    /**
     * Inverted values of prefix multipliers.
     */
    public const uint64 NANO_INV = 1000000000;
    public const uint64 MILI_INV = 1000;

    public inline int compare (int64 a, int64 b) {
        int64 diff = a - b;
        return (int) diff.clamp (int.MIN, int.MAX);
    }

    /**
     * A method for extracting integers from strings.
     *
     * The method does its best to extract a number from a string by cleaning up
     * non-numeric characters before parsing the string with uint64.parse(). The
     * purpose of this method is to provide a safe way of extracting numbers
     * from strings without making everything crash when passing a weird localized
     * string that would normally lead uint64.parse, int64.parse or int.parse
     * to a segmentation fault. This happens due to encoding incompatibilities:
     * Remember that the standard C library doesn't know how to deal with variable-
     * length UTF-8 characters!
     *
     * If no number is found in the string, zero is returned.
     *
     * Examples:
     * "a23oe ew2" => 232
     " "32 text"   => 32
     * "ins1 32"   => 132
     * "a word"    => 0
     *
     * @param str string known to contain a valid integer
     * @return Result of parsing the string.
     */
    public inline uint64 uint_from_string (string str) {
        // Used to prevent overflow
        const ushort MAX_DIGITS = 18;
        ushort ndigits = 0;

        var result = new StringBuilder ();
        unichar c;

        for (int i = 0; str.get_next_char (ref i, out c) && ndigits < MAX_DIGITS;) {
            if (c.isdigit ()) {
                result.append_unichar (c);
                ndigits++;
            }
        }

        return ndigits == 0 ? 0 : uint64.parse (result.str);
    }

    /**
     * Returns the lowest uint given a double.
     * For instance:
     * INPUT => OUTPUT
     *  7.02 => 7
     *  7.51 => 7
     *  7.99 => 7
     */
    [Deprecated (replacement = "GLib.Math.trunc")]
    public inline uint lowest_uint_from_double (double number)
        requires (number >= 0)
    {
        return (uint) Math.trunc (number);
    }

    /**
     * Returns the lowest int given a float.
     * For instance:
     * INPUT => OUTPUT
     *  7.02 => 7
     *  7.51 => 7
     *  7.99 => 7
     */
    [Deprecated (replacement = "GLib.Math.truncf")]
    public inline int lowest_int_from_float (float number) {
        return (int) Math.truncf (number);
    }

    /**
     * Approximates a double to the best uint.
     */
    [Deprecated (replacement = "GLib.Math.round")]
    public inline uint uint_from_double (double number)
        requires (number >= 0)
    {
        return (uint) Math.round (number);
    }

    /**
     * Approximates a float to the best integer.
     */
    [Deprecated (replacement = "GLib.Math.roundf")]
    public inline int int_from_float (float number) {
        return (int) Math.roundf (number);
    }
}

