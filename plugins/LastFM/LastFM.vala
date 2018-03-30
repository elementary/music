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
 */

namespace LastFM {

    public class Plugin : Peas.ExtensionBase, Peas.Activatable {
        public GLib.Object object { owned get; construct; }

        private Noise.Plugins.Interface plugins;

        private Ag.Manager manager;
        private bool added_view = false;

        public void activate () {
            Value value = Value(typeof(GLib.Object));
            get_property("object", ref value);
            plugins = (Noise.Plugins.Interface)value.get_object();

            message ("Activating Last.fm plugin");
            plugins.register_function (Noise.Plugins.Interface.Hook.WINDOW, load_plugin);
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
                    var similar_media_view = new SimilarMediaView (core.get_similar_playlist (), new Noise.TreeViewSetup (true));
                    Noise.App.main_window.view_manager.add (similar_media_view);
                    added_view = true;
                } catch (Error e) {
                    critical (e.message);
                }
            }
        }

        public void deactivate () {
            if (added_view) {
                added_view = false;
                Noise.libraries_manager.local_library.remove_playlist (LastFM.Core.get_default ().get_similar_playlist ().rowid);
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
                                     typeof (LastFM.Plugin));
}
