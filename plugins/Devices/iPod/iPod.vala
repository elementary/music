/*
 * Copyright (c) 2010 Abderrahim Kitouni
 * Copyright (c) 2011 Steve Frécinaux
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Library General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor Boston, MA 02110-1301,  USA
 */

namespace Noise.Plugins {
    public class iPodPlugin : Peas.ExtensionBase, Peas.Activatable {

        Interface plugins;
        public GLib.Object object { owned get; construct; }
        iPodDeviceManager ipod_manager;

        public void activate () {
            message ("Activating iPod Device plugin");

            Value value = Value (typeof (GLib.Object));
            get_property ("object", ref value);
            plugins = (Noise.Plugins.Interface) value.get_object ();
            plugins.register_function(Interface.Hook.WINDOW, () => {
                ipod_manager = new iPodDeviceManager ();
            });
        }

        public void deactivate () {
            if (ipod_manager != null)
                ipod_manager.remove_all ();
        }

        public void update_state () {
            
        }
    }
}

[ModuleInit]
public void peas_register_types (GLib.TypeModule module) {
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type (typeof (Peas.Activatable),
                                     typeof (Noise.Plugins.iPodPlugin));
}