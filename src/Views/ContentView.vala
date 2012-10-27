/*
 * Copyright (c) 2012 Noise Developers
 *
 * This is a free software; you can redistribute it and/or
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
 * Authored by: Scott Ringwelski <sgringwe@mtu.edu>
 *              Victor Eduardo <victoreduardm@gmail.com>
 */

public interface Noise.ContentView : Gtk.Widget {
    public const string FULL_STATUSBAR_FORMAT = NC_("Format used on statusbar: $description, $total_duration, $total_file_size", "%s, %s, %s");

    /**
     * Used for device syncing.
     */
	public signal void import_requested (Gee.LinkedList<Media> to_import);

	public abstract ViewWrapper.Hint get_hint ();

	/**
	 * For some views, get_media() and get_visible_media() return the same contents, since
	 * the view doesn't have any kind of built-in filters. For other views, they don't return
	 * the same since the view has some kind of internal browsing mechanism (e.g. Miller Columns).
	 */
	public abstract Gee.Collection<Media> get_media ();
	public abstract Gee.Collection<Media> get_visible_media ();

    /**
     * Text that should be displayed in the statusbar for the view.
     */
    public abstract string get_statusbar_text ();

    /**
     * Requests the view to apply a filter to only show the media matching the
     * search string.
     *
     * @param search Search string; pass null to use the previous search string.
     */
    public abstract void refilter (string? search);

	public abstract void set_media (Gee.Collection<Media> new_media);
	public abstract void add_media (Gee.Collection<Media> to_add);
	public abstract void remove_media (Gee.Collection<Media> to_remove);
	public abstract void update_media (Gee.Collection<Media> to_update);

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

