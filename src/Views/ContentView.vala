// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012-2017 elementary LLC. (https://elementary.io)
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
 * Authored by: Scott Ringwelski <sgringwe@mtu.edu>
 *              Victor Eduardo <victoreduardm@gmail.com>
 */

public interface Noise.ContentView : Gtk.Widget {
    public const string FULL_STATUSBAR_FORMAT = NC_("Format used on statusbar: $description, $total_duration, $total_file_size", "%s, %s, %s");

    /**
     * Used for device syncing.
     */
    public signal void import_requested (Gee.Collection<Medium> to_import);

    public abstract ViewWrapper.Hint get_hint ();

    /**
     * For some views, get_media() and get_visible_media() return the same contents, since
     * the view doesn't have any kind of built-in filters. For other views, they don't return
     * the same since the view has some kind of internal browsing mechanism (e.g. Miller Columns).
     */
    public abstract Gee.Collection<Medium> get_media ();
    public abstract Gee.Collection<Medium> get_visible_media ();

    /**
     * Requests the view to apply a filter to only show the media matching the
     * search string.
     *
     * @param search Search string; pass null to use the previous search string.
     */
    public abstract void refilter ();

    public abstract void set_media (Gee.Collection<Medium> new_media);
    public abstract void add_media (Gee.Collection<Medium> to_add);
    public abstract void remove_media (Gee.Collection<Medium> to_remove);
    public abstract void update_media (Gee.Collection<Medium> to_update);
}
