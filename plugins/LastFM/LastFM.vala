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

namespace Noise.Plugins {
    
    public class LastFMPlugin : Peas.ExtensionBase, Peas.Activatable {
        public GLib.Object object { owned get; construct; }

        private Interface plugins;
        private Noise.SimilarMediasWidget similar_media_widget;

        private Ag.Manager manager;
        private bool added_view = false;

        public void activate () {
            Value value = Value(typeof(GLib.Object));
            get_property("object", ref value);
            plugins = (Noise.Plugins.Interface)value.get_object();

            message ("Activating Last.fm plugin");
            plugins.register_function (Interface.Hook.WINDOW, load_plugin);
        }

        private void load_plugin () {
            manager = new Ag.Manager ();
            foreach (var uid in manager.list ()) {
                parse_account.begin (uid);
            }

            manager.account_created.connect ((uid) => {
                parse_account.begin (uid);
            });
            
        }

        private async void parse_account (uint uid) {
            if (LastFM.Core.get_default ().is_initialized)
                return;

            var account = manager.get_account (uid);
            if (account.get_provider_name () != "lastfm")
                return;

            var services = account.list_services_by_type ("scrobbling");
            if (services != null) {
                var ag_account_service = new Ag.AccountService (account, services.data);
                if (ag_account_service.get_enabled () == false) {
                    return;
                }

                var ag_auth_data = ag_account_service.get_auth_data ();
                var credentials_id = ag_auth_data.get_credentials_id ();
                try {
                    var identity = new Signon.Identity.from_db (credentials_id);
                    var session = identity.create_session (ag_auth_data.get_method ());
                    var login_parameters = ag_auth_data.get_login_parameters (null);
                    GLib.Variant session_data = yield session.process_async (login_parameters, ag_auth_data.get_mechanism (), null);
                    var token = session_data.lookup_value ("Secret", new VariantType ("s")).get_string ();
                    var client_id = login_parameters.lookup_value ("ClientId", new VariantType ("s")).get_string ();
                    var client_secret = login_parameters.lookup_value ("ClientSecret", new VariantType ("s")).get_string ();
                    var core = LastFM.Core.get_default ();
                    core.initialize (client_id, client_secret, token);
                    App.main_window.source_list_added.connect (source_list_added);
                    libraries_manager.local_library.add_playlist (core.get_similar_playlist ());
                    similar_media_widget = new Noise.SimilarMediasWidget (core);
                    added_view = true;
                } catch (Error e) {
                    critical (e.message);
                }
            }
        }

        private void source_list_added (GLib.Object o, int view_number) {
            if (o == LastFM.Core.get_default ().get_similar_playlist ()) {
                var view = (Noise.ReadOnlyPlaylistViewWrapper) App.main_window.view_container.get_view (view_number);
                view.set_no_media_alert_message (_("No similar songs found"), _("There are no songs similar to the current song in your library. Make sure all song info is correct and you are connected to the Internet. Some songs may not have matches.") , Gtk.MessageType.INFO);
            }
        }

        public void deactivate () {
            if (added_view) {
                added_view = false;
                libraries_manager.local_library.remove_playlist (LastFM.Core.get_default ().get_similar_playlist ().rowid);
                similar_media_widget.destroy ();
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
