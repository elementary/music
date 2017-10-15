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
 * Authored by: Corentin Noël <corentin@elementary.io>
 */

namespace Noise.SettingsWindow {
    /**
     * A section in the preferences dialog. Each section has a page in the window's
     * notebook containing @container. SubSections can be added to the page through
     * the add_subsection() method.
     *
     * When the preferences' window save button is clicked, save_changes() is called for
     * every section.
     */
    public class NoteBook_Page : Gtk.Grid {
        public new string name { get; private set; }

        private const int INDENTATION_MARGIN = 12;

        public NoteBook_Page (string name) {
            this.name = name;

            margin = 12;
            margin_top = 0;
            hexpand = true;
            column_spacing = 12;
            row_spacing = 6;
        }

        /**
         * Appends a subsection. Its main purpose is to allow easier addition of
         * subsections to a normal Section. This makes it easy to maintain a
         * consistent look through all the different preferences sections
         * (even those added by plugins, etc.)
         */
        
        public void add_section (Gtk.Label name, ref int row) {
            name.set_text (name.get_text ());
            name.get_style_context ().add_class ("h4");
            name.halign = Gtk.Align.START;
            attach (name, 0, row, 1, 1);
            row ++;
        }
        
        public void add_option (Gtk.Widget label, Gtk.Widget switcher, ref int row) {
            label.halign = Gtk.Align.END;
            label.hexpand = true;
            label.margin_start = INDENTATION_MARGIN;

            switcher.hexpand = true;
            
            if (switcher is Gtk.Switch || switcher is Gtk.CheckButton
                || switcher is Gtk.Entry) { /* then we don't want it to be expanded */
                switcher.halign = Gtk.Align.START;
            }
            
            attach (label, 0, row, 1, 1);
            attach (switcher, 1, row, 3, 1);
            row ++;
        }
        
        public void add_full_option (Gtk.Widget big_widget, ref int row) {
            big_widget.hexpand = true;
            big_widget.margin_start = INDENTATION_MARGIN;
            
            attach (big_widget, 0, row, 4, 1);
            row ++;
        }
    }
}
