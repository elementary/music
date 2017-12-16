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
 * Authored by: Corentin Noël <corentin@elementary.io>,
 *              Scott Ringwelski <sgringwe@mtu.edu>
 */

public class Noise.SimilarMediasView : Gtk.TreeView {
    private new Gtk.ListStore model;
    private Gee.LinkedList<Media> media;

    private Gee.LinkedList<string> urlsToOpen;//queue for opening urls

    public SimilarMediasView () {
        media = new Gee.LinkedList<Media> ();
        urlsToOpen = new Gee.LinkedList<string> ();

        /* id is always first and is stored as an int. Then the rest are (1)
         * strings (for simplicity), and include:
         * #, track, title, artist, album, genre, comment, year, rating, (9)
         * bitrate, play count, last played, date added, file name, (5)
         * bpm, length, file size, (3) */
        model = new Gtk.ListStore (2, typeof (Noise.Media), typeof (string));

        var col = new Gtk.TreeViewColumn ();
        col.title = _("media");
        col.visible = false;
        insert_column (col, 0);

        var text_renderer = new Gtk.CellRendererText ();
        text_renderer.ellipsize = Pango.EllipsizeMode.END;
        insert_column_with_attributes (-1, _("Similar Media"), text_renderer, "markup", 1, null);
        get_column (1).set_alignment ((float) 0.5);
        set_model (model);
        row_activated.connect (viewDoubleClick);
    }

    public void populateView (Gee.Collection<Media> nMedias) {
        media.clear ();
        model.clear ();
        int count = 0;
        foreach (Media s in nMedias) {
            media.add (s);

            Gtk.TreeIter iter;
            model.append (out iter);

            var title_fixed = Markup.escape_text (s.title);
            var artist_fixed = Markup.escape_text (s.artist);

            model.set (iter, 0, s, 1, "<b>%s</b>\n%s".printf (title_fixed, artist_fixed));
            ++count;

            if (count >= 16)
                return;
        }
    }

    public virtual void viewDoubleClick (Gtk.TreePath path, Gtk.TreeViewColumn column) {
        try {
            new Thread<void*>.try (null, take_action);
        } catch (GLib.Error err) {
            warning ("ERROR: Could not create thread to have fun: %s", err.message);
        }
    }

    public void* take_action () {
        Gtk.TreeIter iter;
        Gtk.TreeModel mo;
        Media s;

        get_selection ().get_selected (out mo, out iter);
        mo.get (iter, 0, out s);

        // fall back to just opening the last fm page
        if (s != null && s.comment != null && s.comment != "") {
            try {
                GLib.AppInfo.launch_default_for_uri (s.comment, null);
            } catch (Error err) {
                message ("Couldn't open the similar medium's last fm page: %s", err.message);
            }
        }

        return null;
    }
}
