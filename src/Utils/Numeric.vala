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


namespace BeatBox.Numeric {

    // If there's something similar already in glibc, please let me know!

    /**
     * Approximates a double to the best uint.
     * Sometimes compilers do this wrong by truncating numbers rather than rounding them.
     */
    public uint uint_from_double (double number) {
        // Check limits
        if (number > (double)uint.MAX)
            return uint.MAX;
        else if (number < (double)uint.MIN)
            return uint.MIN; // obviously '0'

        uint rv = (uint)number;

		// fix approximation
		if ((double)rv < number) {
			// check if the number is lower than what we expected
			if (number - (double)rv >= 0.5) {
				// the approximation was wrong. Increase to the next integer
				rv ++;
			}
		}
		else {
			// check if the number is higher than what we expected
			if (number - (double)rv < -0.5) {
				// the approximation was wrong. Decrease to the previous integer
				rv --;
			}
		}

        return rv;
    }

    /**
     * Approximates a float to the best int.
     * Sometimes compilers do this wrong by truncating numbers rather than rounding them.
     */
    public int int_from_float (float number) {
        // Check limits
        if (number > (float)int.MAX)
            return int.MAX;
        else if (number < (float)int.MIN)
            return int.MIN;

        int rv = (int)number;

		// fix approximation
		if ((float)rv < number) {
			// check if the number is lower than what we expected
			if (number - (float)rv >= 0.5f) {
				// the approximation was wrong. Increase to the next integer
				rv ++;
			}
		}
		else {
			// check if the number is higher than what we expected
			if (number - (float)rv < -0.5f) {
				// the approximation was wrong. Decrease to the previous integer
				rv --;
			}
		}

        return rv;
    }
}

