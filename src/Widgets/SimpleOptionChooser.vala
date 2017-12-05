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

public class Noise.SimpleOptionChooser : Gtk.EventBox {
    public Gee.LinkedList<Gtk.RadioMenuItem> items;
    public Gee.LinkedList<Gtk.Image> images;

    private int clicked_index;
    private int previous_index; // for left click
    private bool toggling;

    private Gtk.Menu? menu = null;

    public int current_option { get { return clicked_index; } }

    public signal void option_changed (bool by_user = false);

    public SimpleOptionChooser () {
        items = new Gee.LinkedList<Gtk.RadioMenuItem> ();
        images = new Gee.LinkedList<Gtk.Image> ();
        toggling = false;

        clicked_index = 0;
        previous_index = 0;
    }

    public void set_option (int index, bool notify = true) {
        if (index >= items.size) {
            return;
        }

        items.get (index).set_active (true);

        clicked_index = index;

        if (notify) {
            option_changed ();
        }

        if (get_child () != null) {
            remove (get_child ());
        }

        add (images.get (index));

        show_all ();
    }

    public int append_item (string text, string icon_name, string tooltip) {
        Gtk.RadioMenuItem item;

        if (items.size == 0) {
            item = new Gtk.RadioMenuItem.with_label (new SList<Gtk.RadioMenuItem>(), text);
        } else {
            item = new Gtk.RadioMenuItem.with_label_from_widget (items.get(0), text);
        }

        var image = new Gtk.Image.from_icon_name (icon_name, Gtk.IconSize.MENU);
        image.tooltip_text = tooltip;

        items.add (item);
        images.add (image);

        if (menu == null) {
            menu = new Gtk.Menu ();
        }
        menu.append (item);

        item.toggled.connect (() => {
            if (item.active) {
                set_option (items.index_of (item));
            }
        });

        item.show ();
        previous_index = items.size - 1; // my lazy way of making sure the bottom item is the default on/off on click

        return items.size - 1;
    }

    public override bool button_press_event (Gdk.EventButton event) {
        if (event.type == Gdk.EventType.BUTTON_PRESS) {
            if (event.button == 1) {
                // Silently set the options. We emit the option_changed signal below.
                if (clicked_index == 0) {
                    set_option (previous_index, false);
                } else {
                    previous_index = clicked_index;
                    set_option (0, false);
                }

                option_changed (true); // #true since the user made the change
            } else if (menu != null && items.size > 1) {
                menu.popup (null, null, null, 3, event.time);
            }
        }

        return false;
    }
}
