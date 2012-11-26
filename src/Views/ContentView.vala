// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012 Noise Developers (http://launchpad.net/noise)
 *
 * This software is licensed under the GNU General Public License
 * (version 2 or later). See the COPYING file in this distribution.
 *
 * The Noise authors hereby grant permission for non-GPL compatible
 * GStreamer plugins to be used and distributed together with GStreamer
 * and Noise. This permission is above and beyond the permissions granted
 * by the GPL license by which Noise is covered. If you modify this code
 * you may extend this exception to your version of the code, but you are not
 * obligated to do so. If you do not wish to do so, delete this exception
 * statement from your version.
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

