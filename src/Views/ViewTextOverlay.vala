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

/**
 * An overlay used to display messages in the same area of a normal view,
 * e.g. "No Albums Found" in the same area of the GridView.
 *
 * The base widget (view) can be added/removed using the normal add() and
 * remove() container methods.
 */
public class Noise.ViewTextOverlay : Gtk.Overlay {

    /**
     * Markup used by default. It forces a large text size.
     */
    private string MESSAGE_MARKUP = "<span size='x-large'>%s</span>";

    /**
     * The message to display.
     *
     * It can contain markup information, and therefore you must escape the real
     * text before assigning it to this property.
     *
     * @see Noise.String.escape
     */
    public string message {
        get { return message_label.get_label (); }
        set { message_label.set_label (MESSAGE_MARKUP.printf (value)); }
    }

    /**
     * Whether or not to show the message.
     *
     * The message is hidden by default.
     */
    public bool message_visible {
        get { return !message_label.no_show_all; }
        set {
            message_label.no_show_all = !value;
            message_label.visible = value;
        }
    }

    private Gtk.Label message_label;

    /**
     * Creates a new text overlay.
     */
    public ViewTextOverlay () {
        set_size_request (-1, 200);

        message_label = new Gtk.Label (null);
        message_label.expand = true;
        message_label.margin = 20;
        message_label.set_size_request (150, -1);
        message_label.halign = message_label.valign = Gtk.Align.CENTER;

        message_label.set_line_wrap (true);
        message_label.ellipsize = Pango.EllipsizeMode.END;
        message_label.use_markup = true;

        // Even though GtkLabels are no-window widgets, we can't forget that the overlay
        // will add its own background window to this label once we add it. Due to that
        // reason, we override its background color to force transparency.
        override_background_color (0, {0, 0, 0, 0});

        add_overlay (message_label);

        message_visible = false;
    }
}
