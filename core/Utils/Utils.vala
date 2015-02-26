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

namespace Noise.Utils {

    /**
     * Checks whether //cancellable// is canceled.
     *
     * @param cancellable The GLib.Cancellable object to query.
     * @return whether the cancellable is canceled; or //false// in case //cancellable// was null.
     */
    public inline bool is_cancelled (Cancellable? cancellable) {
        return (cancellable != null) ? cancellable.is_cancelled () : false;
    }

    /**
     * Checks whether the set of flags specified by //to_check// are set in //flags//.
     *
     * @param flags Set of flags to check.
     * @param to_check Set of flags to look for in //flags//.
     * @return Whether all the flags in //to_check// were set in //flags//.
     */
    public inline bool flags_set (int flags, int to_check) {
        return (flags & to_check) == to_check;
    }

    /**
     * Returns the name of the current desktop shell.
     *
     * Encoding is the same of unix filenames.
     *
     * @return name of the desktop shell, or null if it's not found.
     */
    public string? get_desktop_shell () {
        return Environment.get_variable ("XDG_CURRENT_DESKTOP");
    }
}
