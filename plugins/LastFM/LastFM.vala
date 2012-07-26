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

using GLib;
using Gtk;
using Peas;
using PeasGtk;

namespace Noise.Plugins {
    
    public class LastFMPlugin : Peas.ExtensionBase, Peas.Activatable {

        Interface plugins;
        public GLib.Object object { owned get; construct; }
        Noise.SimilarMediasWidget similar_media_widget;
        Gtk.TreeIter similar_iter;
        Noise.LibraryManager lm;
        LastFM.Core core;

        bool added { get; set; default=false; }
        static string ENABLE_SCROBBLING = _("Enable Scrobbling");
        static string LOGIN_UNSUCCESSFUL = _("Unsuccessful. Click to try again.");
        static string SCROBBLING_ENABLED = _("Scrobbling already Enabled");
        static string LOGIN_SUCCESSFUL = _("Success!");
        static string COMPLETE_LOGIN = _("Complete login");
        public Gtk.Button lastfmLogin_button;
        string lastfm_token { get; set; default=""; }
        Gtk.Grid container;
        int page_number { get; set; default=0; }
        Noise.PreferencesWindow preferences_window;

        public void activate () {
            added = false;
            Value value = Value(typeof(GLib.Object));
            get_property("object", ref value);
            plugins = (Noise.Plugins.Interface)value.get_object();
            
            plugins.register_function(Interface.Hook.WINDOW, () => {
                lm = ((Noise.App)plugins.noise_app).library_manager;
                Icons.init_lastfm ();
                
                // Add Similar playlist.
                core = new LastFM.Core (lm);
                var similar_view = new Noise.SimilarViewWrapper (lm.lw, core);
                similar_media_widget = new Noise.SimilarMediasWidget (lm, core);
                lm.lw.add_view (_("Similar"), similar_view, out similar_iter);
                added = true;
            });
            
            plugins.register_function_arg(Interface.Hook.SETTINGS_WINDOW, (window) => {
                preferences_window = (Noise.PreferencesWindow) window;
                container = new Gtk.Grid ();
                container.row_spacing = 6;
                container.column_spacing = 12;
                container.margin_left = 12;
                container.margin_right = 12;
                container.margin_top = 12;
                container.margin_bottom = 6;
                if(core.lastfm_settings.session_key == null || core.lastfm_settings.session_key == "")
                    lastfmLogin_button = new Button.with_label(ENABLE_SCROBBLING);
                else {
                    lastfmLogin_button = new Button.with_label(SCROBBLING_ENABLED);
                    lastfmLogin_button.set_tooltip_text(_("Click to redo the Last.fm Login Process"));
                }
                var label = new Gtk.Label (_("LastFM allow you to access to more informations about the music that are on your library"));
                label.set_line_wrap (true);
                container.attach (label, 0, 0, 1, 1);
                container.attach (lastfmLogin_button, 0, 1, 1, 1);
                container.show_all ();
                preferences_window.main_static_notebook.append_page (container, new Gtk.Label (_("Last.fm")));
                lastfmLogin_button.clicked.connect (lastfmLoginClick);
                page_number = preferences_window.main_static_notebook.page;
            });
        }

        public void deactivate () {
            if (added) {
                lm.lw.sideTree.removeItem(similar_iter);
                lm.lw.sideTree.resetView();
                similar_media_widget.destroy ();
            }
            if (page_number!=0) {
                container.destroy ();
                preferences_window.main_static_notebook.remove_page (page_number);
                page_number = 0;
            }
        }

        public void update_state () {
            
        }
        
        public void lastfmLoginClick() {
            warning ("clicked");
            if(lastfmLogin_button.get_label() == ENABLE_SCROBBLING || lastfmLogin_button.get_label() == LOGIN_UNSUCCESSFUL) {
                lastfm_token = core.getToken();
                if(lastfm_token == null) {
                    lastfmLogin_button.set_label(LOGIN_UNSUCCESSFUL);
                    warning ("Could not get a token. check internet connection\n");
                }
                else {
                    string auth_uri = "http://www.last.fm/api/auth/?api_key=" + LastFM.api + "&token=" + lastfm_token;
                    try {
                        GLib.AppInfo.launch_default_for_uri (auth_uri, null);
                    }
                    catch(GLib.Error err) {
                        warning ("Could not open Last FM website to authorize: %s\n", err.message);
                    }
                
                    //set button text. we are done this time around. next time we get session key
                    lastfmLogin_button.set_label(COMPLETE_LOGIN);
                }
            }
            else {
                if(lastfm_token == null) {
                    lastfmLogin_button.set_label(LOGIN_UNSUCCESSFUL);
                    message ("Invalid token. Cannot continue");
                }
                else {
                    var sk = core.getSessionKey(lastfm_token);
                    if(sk == null) {
                        lastfmLogin_button.set_label(LOGIN_UNSUCCESSFUL);
                        message ("Could not get Last.fm session key");
                    }
                    else {
                        core.logged_in();
                        message ("Successfully obtained a sessionkey");
                        debug (sk);
                        core.lastfm_settings.session_key = sk;
                        lastfmLogin_button.set_sensitive(false);
                        lastfmLogin_button.set_label(LOGIN_SUCCESSFUL);
                    }
                }
            }
        }
    }

}

[ModuleInit]
public void peas_register_types (GLib.TypeModule module) {
    var objmodule = module as Peas.ObjectModule;
    objmodule.register_extension_type (typeof (Peas.Activatable),
                                     typeof (Noise.Plugins.LastFMPlugin));
}
