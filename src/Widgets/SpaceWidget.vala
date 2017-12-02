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
 */

public class SpaceWidget : Gtk.Grid {
    public signal void sync_clicked();

    private Gtk.Button sync_button;
    public Granite.Widgets.StorageBar storagebar;

    public SpaceWidget (uint64 size) {
        get_style_context ().add_class (Gtk.STYLE_CLASS_INLINE_TOOLBAR);

        storagebar = new Granite.Widgets.StorageBar (size);

        sync_button = new Gtk.Button.with_label (_("Sync"));
        sync_button.valign = Gtk.Align.CENTER;
        sync_button.width_request = 80;

        sync_button.clicked.connect ( ()=> {
            sync_clicked();
        });

        var grid = new Gtk.Grid ();
        grid.column_spacing = 6;
        grid.margin = 12;
        grid.add (storagebar);
        grid.add (sync_button);

        add (grid);
    }

    public void set_sync_button_sensitive (bool val) {
        sync_button.sensitive = val;
    }
}
