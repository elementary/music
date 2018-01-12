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
 * Authored by: Victor Eduardo <victoreduardm@gmail.com>
 */

public class Noise.MusicColumnBrowser : Noise.ColumnBrowser {
    private GLib.Settings saved_state_settings;

    public MusicColumnBrowser (ViewWrapper view_wrapper) {
        var columns = new BrowserColumn.Category [0];
        columns += BrowserColumn.Category.RATING;
        columns += BrowserColumn.Category.GROUPING;
        columns += BrowserColumn.Category.YEAR;
        columns += BrowserColumn.Category.GENRE;
        columns += BrowserColumn.Category.COMPOSER;
        columns += BrowserColumn.Category.ARTIST;
        columns += BrowserColumn.Category.ALBUM;

        base (view_wrapper, columns);

        saved_state_settings = new GLib.Settings ("io.elementary.music.saved-state");

        var visible_categories = new Gee.TreeSet<BrowserColumn.Category> ();

        foreach (var col_n in saved_state_settings.get_strv ("column-browser-visible-columns")) {
            visible_categories.add ((BrowserColumn.Category)int.parse (col_n));
        }

        visible_columns = visible_categories;
        position = (ColumnBrowser.Position) saved_state_settings.get_int ("column-browser-position");

        destroy.connect (save_current_state);
    }

    private void save_current_state () {
        var visible_categories = new string[0];

        foreach (var col_cat in visible_columns) {
           visible_categories += ((int)col_cat).to_string ();
        }

        saved_state_settings.set_strv ("column-browser-visible-columns", visible_categories);
        saved_state_settings.set_int ("column-browser-position", (int) position);
    }
}
