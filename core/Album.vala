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
 * Authored by: Victor Eduardo <victoreduardm@gmail.com>
 */

/**
 * An object representing an album.
 *
 * Currently only used by the album grid view to keep an internal cache.
 *
 * TODO (a lot of work for 1.0 ++)
 * - Replace album-related Media fields with an album object.
 * - Allow organizing media by disc number. Creating a Disc object would probably
 *   be overkill, considering our basic needs.
 * - Modify code accordingly
 * - Save albums to database
 * - Keep albums organized by library manager
 */
public class Noise.Album : Object {

    public string name { get; set; default = ""; }
    public string artist { get; set; default = ""; }

    // Number of discs contained by this album
    public uint n_discs { get; set; default = 1; }

    //public uint rating { get; set; default = 0; }
    //public Date release_date { get; set; }
    
    // store release year, date is overkill and not stored in most tags.
    public uint year { get; set; default = 0; }

    private Gee.HashSet<Media> media = new Gee.HashSet<Media> ();

    ~Album () {
        media.clear ();
    }

    /**
     * Convenience constructor.
     *
     * This is a temporary workaround used by the Grid View and will be
     * deprecated after the TODO list is completed.
     */
    public Album.from_media (Media m) {
        name = m.album;
        artist = m.album_artist;
        year = m.year;

        if (String.is_empty (artist, true))
            artist = m.artist;
    }

    public uint n_media {
        get { return media.size; }
    }

    public bool is_empty {
        get { return n_media < 1; }
    }

    public string to_string () {
        var builder = new StringBuilder ();
        builder.append (name);
        builder.append (artist);
        return builder.str;
    }

    public inline string get_display_name () {
        return Media.get_simple_display_text (name);
    }

    public inline string get_display_artist () {
        return Media.get_simple_display_text (artist);
    }

    public bool contains (Media m) {
        return media.contains (m);
    }

    public bool is_compatible (Media m) {
        if (m.get_album_hashkey () == get_hashkey ())
            return true;
        else
            return false;
    }

    public void remove_media (Media m) {
        m.album_info = null;
        media.remove (m);
    }

    public void add_media (Media m) {
        media.add (m);
        m.album_info = this;
    }

    public string get_hashkey () {
        return "%s|%s".printf (name, artist);
    }

    /**
     * Returns the media contained by the disc specified
     */
    public Gee.Collection<Media> get_media (uint n_disc = 1)
        requires (n_disc > 0)
        requires (n_disc <= n_discs)
    {
        return media.read_only_view;
    }

#if 0
    /**
     * Planed for the future (Wrappers for CoverartCache).
     */

    public Gdk.Pixbuf? get_thumbnail () { }

    public Gdk.Pixbuf? get_full_sized_image () { }

    public File? get_image_file () { }
#endif
}
