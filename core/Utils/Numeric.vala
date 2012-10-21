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

namespace Noise.Numeric {

    /**
     * Inverted values of prefix multipliers.
     */
    public const uint64 NANO_INV = 1000000000;
    public const uint64 MILI_INV = 1000;

    /**
     * Convert from nanoseconds (10E-9) to miliseconds (10E-3);
     *
     * This is used extensively because {@link Noise.Media} stores
     * miliseconds, while GStreamer uses nanoseconds.
     */
    public inline uint nanoseconds_to_miliseconds (uint64 nanoseconds) {
        return (uint) (nanoseconds_to_seconds (nanoseconds) * MILI_INV);
    }

    public inline uint nanoseconds_to_seconds (uint64 nanoseconds) {
        return (uint) (nanoseconds / NANO_INV);
    }

    public inline int compare (int64 a, int64 b) {
        int64 diff = a - b;
        return (int) diff.clamp (int.MIN, int.MAX);
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

