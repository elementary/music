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

namespace Noise.String {

    public inline bool is_empty (string? text, bool check_white_space) {
        return text == null || check_white_space ? is_white_space (text) : text == "";
    }

    /**
     * Compares two strings encoded in UTF-8. Used extensively in the views for sorting.
     *
     * It takes into account the current locale's sorting rules and is faster
     * than normal string comparison.
     *
     * /!\ DON'T USE THIS METHOD WITH STRINGS NOT ENCODED IN UTF-8.
     *
     * @param a first string.
     * @param b second string.
     * @return 0 if a == b, a positive number if a > b, or a negative number if a < b.
     */
    public inline int compare (string? a, string? b) {
        // g_strcmp0 is known to handle NULL strings gracefully
        return strcmp (a != null ? a.collate_key () : (string) null,
                       b != null ? b.collate_key () : (string) null);
    }

    /**
     * Escapes the text for use with Markup.
     *
     * @return escaped text
     */
    public inline string escape (string text) {
        return Markup.escape_text (text, -1);
    }

    /**
     * Checks whether a string contains only whitespace.
     *
     * @return //true// if text consists enterely of white space.
     */
    public inline bool is_white_space (string text) {
        return text.strip ().length == 0;
    }

    /**
     * Removes irrelevant and meaningless characters from a string. Useful for search operations.
     * (Taken from gnome-contacts' contacts-utils.vala)
     */
    public inline string canonicalize_for_search (string str, Cancellable? cancellable = null) {
        var buf = new unichar[unichar.MAX_DECOMPOSITION_LENGTH];
        var res = new StringBuilder ();

        unichar c;

        for (int i = 0; str.get_next_char (ref i, out c);) {
            if (Utils.is_cancelled (cancellable))
                break;

            var sc = strip_char (c);

            if (sc != 0) {
                var size = sc.fully_decompose (false, buf);

                if (size > 0)
                    res.append_unichar (buf[0]);
            }
        }

        return res.str;
    }

    private inline unichar strip_char (unichar ch) {
        switch (ch.type ()) {
            case UnicodeType.CONTROL:
            case UnicodeType.FORMAT:
            case UnicodeType.UNASSIGNED:
            case UnicodeType.NON_SPACING_MARK:
            case UnicodeType.COMBINING_MARK:
            case UnicodeType.ENCLOSING_MARK:
            case UnicodeType.LINE_SEPARATOR:
            case UnicodeType.SPACE_SEPARATOR:
            case UnicodeType.PARAGRAPH_SEPARATOR:
            case UnicodeType.DASH_PUNCTUATION:
            case UnicodeType.OPEN_PUNCTUATION:
            case UnicodeType.OTHER_PUNCTUATION:
                return 0; // Ignore those
            default:
                return ch.tolower ();
        }
    }
}
