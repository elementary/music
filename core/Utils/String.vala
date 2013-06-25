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

namespace Noise.String {

    public inline bool is_empty (string? text, bool check_white_space) {
        if (text != null)
            return check_white_space ? is_white_space (text) : text == "";
        return true;
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
    public inline string canonicalize_for_search (string str) {
        var buf = new unichar[unichar.MAX_DECOMPOSITION_LENGTH];
        var res = new StringBuilder ();

        unichar c;

        for (int i = 0; str.get_next_char (ref i, out c);) {
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

    /**
     * Capitalizes the initial letters of a UTF-8 string (Title Case).
     *
     * The implementation is guaranteed to be efficient.
     *
     * For example:
     * "This is an input string" => "This Is An Input String"
     * "example string/text"     => "Example String/Text" 
     */
    public inline string to_title_case (string text) {
        bool capitalize_next = true;

        var result = new StringBuilder ();
        unichar c;

        for (int i = 0; text.get_next_char (ref i, out c);) {
            if (capitalize_next) {
                result.append_unichar (c.totitle ());
                capitalize_next = false;
            } else {
                result.append_unichar (c.tolower ());

                // Capitalize letters following a space or control character.
                capitalize_next = c.isspace () || c.iscntrl ();
            }
        }

        return result.str;
    }

    /**
     * Converts a string encoded in the native operating system encoding to UTF-8.
     *
     * @param string_locale String in locale encoding.
     * @return String encoded in UTF-8, or //null// if the string could not be converted.
     */
    public string? locale_to_utf8 (string string_locale) {
        Error error;
        size_t bytes_read, bytes_written;
        string? string_utf8 = string_locale.locale_to_utf8 (string_locale.length,
                                                            out bytes_read,
                                                            out bytes_written,
                                                            out error);
        if (error != null)
            string_utf8 = null;

        return string_utf8;
    }
    
    /**
     * Base method used for searches. It does a previous parsing on the search string.
     *
     * If the output value of parsed_rating is greater than 0, then the view should
     * only display the media with that rating in the search results, and ignore
     * the value of parsed_search_string.
     *
     * @param search Non-parsed version of the search string.
     * @param parsed_rating location where the parsed rating it stored, or -1 if the
     * string didn't represent a valid rating.
     * @param parsed_search_string location where the canonicalized version of the
     * search string is stored. Should be passed to the methods in Noise.Search.
     */
    public static void base_search_method (string search, out int parsed_rating,
                                           out string parsed_search_string)
    {
        parsed_rating = Search.get_rating_from_string (search.strip ());

        if (parsed_rating > 0)
            parsed_rating = parsed_rating.clamp (1, 5);

        parsed_search_string = Search.get_valid_search_string (search);
    }
}
