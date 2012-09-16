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

using Gtk;
using Peas;
using PeasGtk;

namespace Noise.Plugins {
    
    public class LastFMPlugin : Peas.ExtensionBase, Peas.Activatable {
        public GLib.Object object { owned get; construct; }

        private Interface plugins;
        private Noise.SimilarMediasWidget similar_media_widget;
        private Gtk.TreeIter similar_iter;

        private Noise.LibraryManager lm;
        private Noise.PreferencesWindow? preferences_window;
        private LastFM.Core core;
        private int prefs_page_index = -1;
        private bool added_view = false;

        public void activate () {
            Value value = Value(typeof(GLib.Object));
            get_property("object", ref value);
            plugins = (Noise.Plugins.Interface)value.get_object();

            message ("Activating Last.fm plugin");

            plugins.register_function(Interface.Hook.WINDOW, () => {
                lm = ((Noise.App)plugins.noise_app).library_manager;
                
                // Add Similar playlist.
                core = new LastFM.Core (lm);
                var similar_view = new Noise.SimilarViewWrapper (lm.lw, core);
                similar_media_widget = new Noise.SimilarMediasWidget (lm, core);

                lm.lw.add_view (_("Similar"), similar_view, out similar_iter);
                added_view = true;
            });

            plugins.register_function_arg(Interface.Hook.SETTINGS_WINDOW, (window) => {
                preferences_window = window as Noise.PreferencesWindow;
                var prefs_section = new LastFM.PreferencesSection (core);
                prefs_page_index = preferences_window.add_section (prefs_section);
            });
        }

        public void deactivate () {
            if (added_view) {
                added_view = false;
                lm.lw.sideTree.removeItem (similar_iter);
                lm.lw.sideTree.resetView ();
                similar_media_widget.destroy ();
            }

            if (prefs_page_index >= 0) {
                preferences_window.remove_section (prefs_page_index);
                prefs_page_index = -1;
            }
        }

        public void update_state () {
            // do nothing
        }
    }
}

[ModuleInit]
public void peas_register_types (GLib.TypeModule module) {
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type (typeof (Peas.Activatable),
                                     typeof (Noise.Plugins.LastFMPlugin));
}
