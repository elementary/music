// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012 Noise Developers (http://launchpad.net/noise)
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
 */


[ModuleInit]
public void peas_register_types (TypeModule module) {
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type (typeof (Peas.Activatable), typeof (Noise.Plugins.MPRISPlugin));
}

public class Noise.Plugins.MPRISPlugin : Peas.ExtensionBase, Peas.Activatable {
    public GLib.Object object { owned get; construct; }

    private Interface plugins;
    private Noise.MPRIS mpris;

    public void activate () {
        message ("Activating MPRIS plugin");

        var value = Value (typeof (Object));
        get_property ("object", ref value);
        plugins = (Noise.Plugins.Interface)value.get_object();

        mpris = new Noise.MPRIS ();
        mpris.initialize ();
    }

    public void deactivate () {
        // nothing to do
    }

    public void update_state () {
        // nothing to do
    }
}

