// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012-2015 Noise Developers (https://launchpad.net/noise)
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
 *              Scott Ringwelski <sgringwe@mtu.edu>
 */

/**
 * A place to store icon information and pixbufs.
 */
public class Noise.Icons {
    public const int DEFAULT_ALBUM_ART_SIZE = 138;

    public static Icon DEFAULT_ALBUM_ART { get; private set; default = new Icon ("albumart"); }
    public static Icon DEFAULT_ALBUM_ART_2 { get; private set; default = new Icon ("albumart_2"); }
    // FIXME: have a real icon for audiobooks
    public static Icon STARRED { get; private set; default = new Icon ("starred"); }
    public static Icon NOT_STARRED { get; private set; default = new Icon ("non-starred"); }
    public static Icon STARRED_SYMBOLIC { get; private set; default = new Icon ("starred-symbolic"); }
    public static Icon NOT_STARRED_SYMBOLIC { get; private set; default = new Icon ("non-starred-symbolic"); }

    /**
     * This is needed until vala really supports initialization of static members.
     * See https://bugzilla.gnome.org/show_bug.cgi?id=543189
     */
    public static void init () {
        new Icons (); // dummy instantiation to init static members
    }

    public static Gdk.Pixbuf? render_icon (string icon_name, Gtk.IconSize size, Gtk.StyleContext? context = null) {
        return new Icon (icon_name).render (size, context);
    }

    public static Gtk.Image? render_image (string icon_name, Gtk.IconSize size) {
        return new Icon (icon_name).render_image (size);
    }
}
