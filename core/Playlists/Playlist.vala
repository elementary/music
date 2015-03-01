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
 
public abstract class Noise.Playlist : Object {
    public signal void request_play ();
    public virtual Gee.ArrayQueue<Media> medias { get; set; }

    public int rowid { get; set; }
    public GLib.Icon icon;
    private string _name;
    public string name {
        get {
            return _name;
        } 
        set {
            string old_name = _name;
            _name = value;
            updated (old_name);
        }
    }

    public signal void media_added (Gee.Collection<Media> media);
    public signal void media_removed (Gee.Collection<Media> media);
    public signal void updated (string? old_name = null);
    public signal void cleared ();

    public abstract void add_media (Media to_remove);
    public abstract void add_medias (Gee.Collection<Media> to_add);
    public abstract void remove_media (Media to_remove);
    public abstract void remove_medias (Gee.Collection<Media> to_remove);
    public abstract void clear ();

    public bool is_empty () {
        return (medias.size <= 0);
    }
}
