// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012-2018 elementary LLC. (https://elementary.io)
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
 * Authored by: Nine Hall <nine.gentooman@gmail.com>
 */

class Noise.Infobar : Gtk.InfoBar {
    private Gtk.ProgressBar progress_bar;
    
    construct {
        var action_label = new TitleLabel ("");

        progress_bar = new Gtk.ProgressBar ();
        progress_bar.fraction = 1;

        var cancel_button = new Gtk.Button.from_icon_name ("process-stop-symbolic", Gtk.IconSize.MENU);
        cancel_button.halign = cancel_button.valign = Gtk.Align.CENTER;
        cancel_button.vexpand = true;
        cancel_button.tooltip_text = _("Cancel");
        cancel_button.clicked.connect (() => {
            NotificationManager.get_default ().progress_canceled ();
        });

        var layout = new Gtk.Grid ();
        layout.column_spacing = 6;
        layout.row_spacing = 6;
        layout.attach (action_label, 0, 0, 1, 1);
        layout.attach (progress_bar, 0, 1, 1, 1);
        layout.attach (cancel_button, 1, 0, 1, 2);

        var notification_manager = NotificationManager.get_default ();
        notification_manager.update_progress.connect ((message, progress) => {
            set_progress_value (progress);
            if (message != null)
                action_label.set_markup (message);
        });
    }

    private class TitleLabel : Gtk.Label {
        public TitleLabel (string label) {
            Object (label: label);
            hexpand = true;
            justify = Gtk.Justification.CENTER;
            ellipsize = Pango.EllipsizeMode.END;
        }
    }

    public void set_progress_value (double progress) {
        progress_bar.fraction = progress;
    }
}
