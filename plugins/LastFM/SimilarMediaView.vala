/*-
 * Copyright (c) 2011-2012       Scott Ringwelski <sgringwe@mtu.edu>
 *
 * Originally Written by Scott Ringwelski for BeatBox Music Player
 * BeatBox Music Player: http://www.launchpad.net/beat-box
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
 */

public class Noise.SimilarMediasView : Gtk.TreeView {
    private new Gtk.ListStore model;
    private Gee.LinkedList<Media> medias;

    private Gee.LinkedList<string> urlsToOpen;//queue for opening urls

    public SimilarMediasView () {
        medias = new Gee.LinkedList<Media> ();
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
        medias.clear ();
        model.clear ();
        int count = 0;
        foreach (Media s in nMedias) {
            medias.add (s);

            Gtk.TreeIter iter;
            model.append (out iter);

            var title_fixed = String.escape (s.title);
            var artist_fixed = String.escape (s.artist);

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
                message ("Couldn't open the similar media's last fm page: %s", err.message);
            }
        }

        return null;
    }
}
