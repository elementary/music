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

public class Noise.Widgets.AlbumImage : Gtk.Grid {
    private const string STYLESHEET = """
        .album {
            background-image: -gtk-icontheme("audio-x-generic-symbolic");
            background-size: 50%;
            background-repeat: no-repeat;
            background-position: center center;
            color: #abacae;
        }
    """;

    public Gtk.Image image;

    construct {
        var style_context = get_style_context ();
        style_context.add_class (Granite.STYLE_CLASS_CARD);
        style_context.add_class ("album");

        image = new Gtk.Image ();
        image.height_request = 64;
        image.width_request = 64;

        halign = Gtk.Align.CENTER;
        valign = Gtk.Align.CENTER;
        margin = 12;
        add (image);

        var provider = new Gtk.CssProvider ();
        try {
            provider.load_from_buffer (STYLESHEET.data);
            style_context.add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (GLib.Error e) {
            critical (e.message);
        }
    }

    public override Gtk.SizeRequestMode get_request_mode () {
        return Gtk.SizeRequestMode.HEIGHT_FOR_WIDTH;
    }

    public override void get_preferred_height_for_width (int width, out int minimum_height, out int natural_height) {
        minimum_height = natural_height = width;
        image.pixel_size = width;
    }
}
