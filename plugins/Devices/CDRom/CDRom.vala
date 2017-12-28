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

namespace Noise.Plugins {
    public class CDRomPlugin : Peas.ExtensionBase, Peas.Activatable {

        Interface plugins;
        public GLib.Object object { owned get; construct; }
        CDRomDeviceManager cdrom_manager;

        public void activate () {
            message ("Activating CD-Rom Device plugin");

            Value value = Value(typeof(GLib.Object));
            get_property("object", ref value);
            plugins = (Noise.Plugins.Interface)value.get_object();
            plugins.register_function(Interface.Hook.WINDOW, () => {
                cdrom_manager = new CDRomDeviceManager ();
            });
        }

        public void deactivate () {
            if (cdrom_manager != null)
                cdrom_manager.remove_all ();
        }

        public void update_state () {

        }
    }

    /*public class CDRomConfig : Peas.ExtensionBase, PeasGtk.Configurable {
        public Gtk.Widget create_configure_widget () {
            string text = "This is a configuration dialog for the ValaHello plugin.";
            return new Gtk.Label (text);
        }
    }*/
}

[ModuleInit]
public void peas_register_types (GLib.TypeModule module) {
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type (typeof (Peas.Activatable),
                                     typeof (Noise.Plugins.CDRomPlugin));
    /*objmodule.register_extension_type (typeof (PeasGtk.Configurable),
                                     typeof (Noise.Plugins.CDRomConfig));*/
}
