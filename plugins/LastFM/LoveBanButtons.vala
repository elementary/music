// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012 Noise Developers (http://launchpad.net/noise)
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
 * Authored by: Victor Eduardo <victoreduardm@gmail.com>
 */

/**
 * A widget that displays two buttons: love and ban. They are mutually exclusive.
 */
public class Noise.LoveBanButtons : Gtk.ButtonBox {
    private const int ITEM_WIDTH = 30;

    public enum Mode {
        LOVE,
        BAN,
        NONE
    }

    /**
     * The value of {@link Noise.LastFM.LoveBanButtons.mode} changed.
     */
    public signal void changed ();

    public Mode mode {
        get {
            if (love_button.active)
                return Mode.LOVE;
            if (ban_button.active)
                return Mode.BAN;
            return Mode.NONE;
        }
        set {
            if (value == Mode.NONE) {
                love_button.active = ban_button.active = false;
            } else {
                ban_button.active = value == Mode.BAN;
                love_button.active = !ban_button.active;
            }

            changed ();
        }
    }

    private Gtk.ToggleButton love_button;
    private Gtk.ToggleButton ban_button;

    public LoveBanButtons () {
        orientation = Gtk.Orientation.HORIZONTAL;
        halign = Gtk.Align.CENTER;
        hexpand = true;
        vexpand = false;
        spacing = 0;
        can_focus = false;

        get_style_context ().add_class (Gtk.STYLE_CLASS_LINKED);

        love_button = new Gtk.ToggleButton ();
        love_button.can_focus = false;
        love_button.hexpand = false;
        love_button.halign = Gtk.Align.END;
        love_button.set_image (Noise.Icons.LOVE.render_image (Gtk.IconSize.MENU));

        ban_button = new Gtk.ToggleButton ();
        ban_button.can_focus = false;
        ban_button.hexpand = false;
        ban_button.halign = Gtk.Align.START;
        ban_button.set_image (Noise.Icons.BAN.render_image (Gtk.IconSize.MENU));

        love_button.set_size_request (ITEM_WIDTH, -1);
        ban_button.set_size_request (ITEM_WIDTH, -1);

        pack_start (love_button, false, false, 0);
        pack_end (ban_button, false, false, 0);

        mode = Mode.NONE;

        love_button.clicked.connect_after (love_button_clicked);
        ban_button.clicked.connect_after (ban_button_clicked);
    }

    private void love_button_clicked () {
        if (love_button.active && ban_button.active)
            ban_button.active = false;
        changed ();
    }

    private void ban_button_clicked () {
        if (ban_button.active && love_button.active)
            love_button.active = false;
        changed ();
    }
}
