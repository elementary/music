// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012-2018 elementary LLC. (https://elementary.io)
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
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA.
 *
 * The Noise authors hereby grant permission for non-GPL compatible
 * GStreamer plugins to be used and distributed together with GStreamer
 * and Noise. This permission is above and beyond the permissions granted
 * by the GPL license by which Noise is covered. If you modify this code
 * you may extend this exception to your version of the code, but you are not
 * obligated to do so. If you do not wish to do so, delete this exception
 * statement from your version.
 *
 * Authored by: Zeeshan Ali (Khattak) <zeeshanak@gnome.org> (from Rygel)
 *              Lucas Baudin <xapantu@gmail.com> (from Pantheon Files)
 *              Corentin Noël <corentin@elementary.io>
 */

public class Noise.Plugins.Manager : Object {
    public signal void hook_main_menu (Gtk.Menu menu);
    public signal void hook_toolbar ();
    public signal void hook_set_arg (string set_name, string? set_arg);
    public signal void hook_notebook_bottom (Gtk.Notebook notebook);
    public signal void hook_source_view(Gtk.TextView view);
    public signal void hook_new_window(Gtk.Window window);
    public signal void hook_preferences_window(Gtk.Window window);
    public signal void hook_toolbar_context_menu(Gtk.Menu menu);

    Peas.Engine engine;
    Peas.ExtensionSet exts;

    public Gtk.Toolbar toolbar { set { plugin_iface.toolbar = value; } }
    public Gtk.Application noise_app { set { plugin_iface.noise_app = value;  }}
    public Noise.Plugins.Interface plugin_iface { private set; get; }

    private static Manager? plugin_manager = null;

    public static Manager get_default () {
        if (plugin_manager == null) {
            plugin_manager = new Manager ();
        }
        return plugin_manager;
    }

    private Manager () {

        plugin_iface = new Noise.Plugins.Interface (this);
        plugin_iface.set_name = "noise";

        /* Let's init the engine */
        engine = Peas.Engine.get_default ();
        engine.add_search_path (Build.PLUGIN_DIR, null);

        /* Do not load blacklisted plugins */
        var disabled_plugins = new Gee.LinkedList<string> ();
        foreach (var plugin in Settings.Main.get_default ().plugins_disabled) {
            disabled_plugins.add (plugin);
        }

        foreach (var plugin in engine.get_plugin_list ()) {
            if (!disabled_plugins.contains (plugin.get_module_name ())) {
                engine.try_load_plugin (plugin);
            }
        }

        /* Our extension set */
        Parameter param = Parameter();
        param.value = plugin_iface;
        param.name = "object";
        exts = new Peas.ExtensionSet (engine, typeof(Peas.Activatable), "object", plugin_iface, null);

        exts.extension_added.connect( (info, ext) => {
                ((Peas.Activatable)ext).activate();
        });
        exts.extension_removed.connect(on_extension_removed);

        exts.foreach (on_extension_added);
    }

    public Gtk.Widget get_view () {
        var view = new PeasGtk.PluginManager (engine);
        var bottom_box = view.get_children ().nth_data (1) as Gtk.Box;
        assert(bottom_box != null);
        bottom_box.get_children ().nth_data(0).no_show_all = true;
        bottom_box.get_children ().nth_data(0).visible = false;
        return view;
    }

    void on_extension_added(Peas.ExtensionSet set, Peas.PluginInfo info, Peas.Extension extension) {
        var core_list = engine.get_plugin_list ().copy ();
        for (int i = 0; i < core_list.length(); i++) {
            string module = core_list.nth_data (i).get_module_name ();
            if (module == info.get_module_name ()) {
                ((Peas.Activatable)extension).activate();
            } else if (module == plugin_iface.set_name) {
                debug ("Loaded %s", module);
                ((Peas.Activatable)extension).activate();
            } else {
                ((Peas.Activatable)extension).deactivate();
            }
        }
    }

    void on_extension_removed(Peas.PluginInfo info, Object extension) {
        ((Peas.Activatable)extension).deactivate();
    }

    public void hook_app(Gtk.Application app) {
        plugin_iface.noise_app = app;
    }

    public Gtk.Notebook context { set { plugin_iface.context = value; } }
    public signal void hook_notebook_context ();

    public Gtk.Notebook sidebar { set { plugin_iface.sidebar = value; } }
    public signal void hook_notebook_sidebar ();

    public signal void hook_addons_menu(Gtk.Menu menu);

    public void hook_example(string arg) {
    }
}
