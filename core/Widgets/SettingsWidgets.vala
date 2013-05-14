// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
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
 * Authored by: Corentin Noël <tintou@mailoo.org>
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

        private static const int IDENTATION_MARGIN = 12;

        public NoteBook_Page (string name) {
            this.name = name;

            margin = 12;
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
            name.use_markup = true;
            name.set_markup ("<b>%s</b>".printf (name.get_text ()));
            name.halign = Gtk.Align.START;
            attach (name, 0, row, 1, 1);
            row ++;
        }
        
        public void add_option (Gtk.Widget label, Gtk.Widget switcher, ref int row) {
            label.set_hexpand (true);
            label.set_halign (Gtk.Align.END);
            label.set_margin_left (20);
            switcher.set_halign (Gtk.Align.FILL);
            switcher.set_hexpand (true);
            
            if (switcher is Gtk.Switch || switcher is Gtk.CheckButton
                || switcher is Gtk.Entry) { /* then we don't want it to be expanded */
                switcher.halign = Gtk.Align.START;
            }
            
            attach (label, 0, row, 1, 1);
            attach (switcher, 1, row, 3, 1);
            row ++;
        }
        
        public void add_full_option (Gtk.Widget big_widget, ref int row) {
            big_widget.set_halign (Gtk.Align.FILL);
            big_widget.set_hexpand (true);
            big_widget.set_margin_left (20);
            big_widget.set_margin_right (20);
            
            attach (big_widget, 0, row, 4, 1);
            row ++;
        }
    }
}
