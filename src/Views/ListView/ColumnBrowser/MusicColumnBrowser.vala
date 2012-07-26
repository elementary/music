/*-
 * Copyright (c) 2011-2012 Noise Developers
 *
 * BeatBox Music Player: http://www.launchpad.net/beat-box
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
 * Authored by: Scott Ringwelski <sgringwe@mtu.edu>
 *              Victor Eduardo <victoreduardm@gmail.com>
 */

public class Noise.MusicColumnBrowser : Noise.ColumnBrowser {

    public MusicColumnBrowser (ViewWrapper view_wrapper) {
        var columns = new BrowserColumn.Category [0];
        columns += BrowserColumn.Category.RATING;
        columns += BrowserColumn.Category.YEAR;
        columns += BrowserColumn.Category.GENRE;
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

        lw.savedstate_settings.column_browser_visible_columns = visible_categories;
   	    lw.savedstate_settings.column_browser_position = (int)position;
    }

    private void restore_saved_state () {
		// Read visible columns from settings
        var visible_categories = new List<BrowserColumn.Category> ();

		foreach (var col_n in lw.savedstate_settings.column_browser_visible_columns) {
			visible_categories.append ((BrowserColumn.Category)int.parse (col_n));
		}

        visible_columns = visible_categories;
		position = (Noise.BrowserPosition)lw.savedstate_settings.column_browser_position;
	}
}