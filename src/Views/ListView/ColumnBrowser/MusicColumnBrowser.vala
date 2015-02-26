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
 * Authored by: Victor Eduardo <victoreduardm@gmail.com>
 */

public class Noise.MusicColumnBrowser : Noise.ColumnBrowser {

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

        // set visible columns ...
        restore_saved_state ();

        destroy.connect (save_current_state);
    }

    private void save_current_state () {
        var visible_categories = new string[0];

        foreach (var col_cat in visible_columns) {
           visible_categories += ((int)col_cat).to_string ();
        }

        var saved_state = Settings.SavedState.get_default ();
        saved_state.column_browser_visible_columns = visible_categories;
        saved_state.column_browser_position = (int) position;
    }

    private void restore_saved_state () {
        // Read visible columns from settings
        var visible_categories = new Gee.TreeSet<BrowserColumn.Category> ();

        var saved_state = Settings.SavedState.get_default ();
        foreach (var col_n in saved_state.column_browser_visible_columns) {
            visible_categories.add ((BrowserColumn.Category)int.parse (col_n));
        }

        visible_columns = visible_categories;
        position = (ColumnBrowser.Position) saved_state.column_browser_position;
    }
}
