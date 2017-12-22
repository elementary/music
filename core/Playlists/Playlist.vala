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

public abstract class Noise.Playlist : Object {
    public signal void request_play ();

    public virtual Gee.ArrayList<Medium> media { get; internal set; default = new Gee.ArrayList<Medium> (); }

    public int64 rowid { get; construct set; }
    public GLib.Icon icon;
    internal string _name = "";
    public virtual string name {
        get {
            return _name;
        }
        set {
            string old_name = _name;
            _name = value;
            updated (old_name);
        }
    }

    public signal void media_added (Gee.Collection<Medium> media);
    public signal void media_removed (Gee.Collection<Medium> media);
    public signal void updated (string? old_name = null);
    public signal void cleared ();

    public abstract void add_medium (Medium to_remove);
    public abstract void add_media (Gee.Collection<Medium> to_add);
    public abstract void remove_medium (Medium to_remove);
    public abstract void remove_media (Gee.Collection<Medium> to_remove);
    public abstract void clear ();

    public bool is_empty () {
        return media.size <= 0;
    }

    /**
    * Retrives a Medium at an index in this playlist
    */
    public new Medium get (int index) {
        return media[index];
    }

    public new void set (int index, Medium m) {
        media[index] = m;
    }

    public Gee.Iterator<Medium> iterator () {
        return media.iterator ();
    }
}
