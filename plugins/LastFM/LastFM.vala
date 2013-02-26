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

        private Noise.PreferencesWindow? preferences_window;
        private LastFM.Core core;
        private int prefs_page_index = -1;
        private bool added_view = false;
        private bool desactivation = false;
        private LastFM.PreferencesSection prefs_section;

        public void activate () {
            Value value = Value(typeof(GLib.Object));
            get_property("object", ref value);
            plugins = (Noise.Plugins.Interface)value.get_object();

            message ("Activating Last.fm plugin");

            plugins.register_function(Interface.Hook.WINDOW, () => {
                
                // Add Similar playlist.
                core = new LastFM.Core ();

                App.main_window.source_list_added.connect (source_list_added);
                libraries_manager.local_library.add_playlist (core.get_similar_playlist ());
                similar_media_widget = new Noise.SimilarMediasWidget (core);
                added_view = true;
            });

            plugins.register_function_arg(Interface.Hook.SETTINGS_WINDOW, (window) => {
                preferences_window = window as Noise.PreferencesWindow;
                prefs_section = new LastFM.PreferencesSection (core);
                App.main_window.add_preference_page (prefs_section.page);
            });
        }
        
        private void source_list_added (GLib.Object o, int view_number) {
            if (o == core.get_similar_playlist ()) {
                ((Noise.ReadOnlyPlaylistViewWrapper)App.main_window.view_container.get_view(view_number)).set_no_media_alert_message (_("No similar songs found"), _("There are no songs similar to the current song in your library. Make sure all song info is correct and you are connected to the Internet. Some songs may not have matches.") , Gtk.MessageType.INFO);
            }
        }

        public void deactivate () {
            desactivation = true;
            if (added_view) {
                added_view = false;
                
                libraries_manager.local_library.remove_playlist (core.get_similar_playlist ().rowid);
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
