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

public interface Noise.Playback : GLib.Object {

    public abstract Gee.Collection<string> get_supported_uri ();

    /* 
     * Signals
     */

    public signal void end_of_stream ();
    public signal void current_position_update (int64 position);
    public signal void media_not_found ();
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
