// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012-2018 elementary LLC. (https://elementary.io)
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
 * The Music authors hereby grant permission for non-GPL compatible
 * GStreamer plugins to be used and distributed together with GStreamer
 * and Music. This permission is above and beyond the permissions granted
 * by the GPL license by which Music is covered. If you modify this code
 * you may extend this exception to your version of the code, but you are not
 * obligated to do so. If you do not wish to do so, delete this exception
 * statement from your version.
 *
 * Authored by: Corentin Noël <corentin@elementary.io>
 */

public interface Music.Playback : GLib.Object {

    public abstract Gee.Collection<string> get_supported_uri ();

    /*
     * Signals
     */

    public signal void end_of_stream ();
    public signal void current_position_update (int64 position);
    public signal void error_occured ();

    /*
     * Basic playback functions
     */

    public abstract void play ();
    public abstract void pause ();
    public abstract void set_state (Gst.State s);
    public abstract void set_media (Media media);
    public abstract void set_position (int64 pos);
    public abstract int64 get_position ();
    public abstract int64 get_duration ();
    public abstract void set_volume (double val);
    public abstract double get_volume ();

    /*
     * Extra stuff
     */

    public abstract bool update_position ();
    public abstract void enable_equalizer ();
    public abstract void disable_equalizer ();
    public abstract void set_equalizer_gain (int index, int val);

}
