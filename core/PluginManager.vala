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
 * Authored by: Zeeshan Ali (Khattak) <zeeshanak@gnome.org> (from Rygel)
 *              Lucas Baudin <xapantu@gmail.com> (from Pantheon Files)
 *              Corentin Noël <tintou@mailoo.org>
 */

public class Noise.Plugins.Interface : Object {
    Manager manager;

    public enum Hook {
        CONTEXT,
        SIDEBAR,
        MAIN_MENU,
        ADDONS_MENU,
        BOTTOMBAR,
        TOOLBAR,
        SOURCE_VIEW,
        SETTINGS_WINDOW,
        WINDOW
    }

    public delegate void HookFunction ();
    public delegate void HookFunctionArg (Object object);
    
    public Gtk.Notebook context {internal set; get; }
    public Gtk.Notebook sidebar {internal set; get; }
    public Gtk.Notebook bottombar {internal set; get; }
    public Gtk.Application noise_app {internal set; get; }
    public Gtk.Menu main_menu {private set; get; }
    public Gtk.Menu addons_menu {private set; get; }
    public Gtk.Toolbar toolbar {internal set; get; }
    public Gtk.Window window {private set; get; }
    public string set_name {internal set; get; }
    public string? argument {internal set; get; }

    public unowned List<Gtk.TextView> all_source_view { private set; get; }

    public Interface (Manager manager) {
        this.manager = manager;
        all_source_view = new List<Gtk.TextView>();

        manager.hook_main_menu.connect( (m) => {
            main_menu = m;
        });
        manager.hook_addons_menu.connect( (m) => {
            addons_menu = m;
        });
        manager.hook_new_window.connect( (m) => {
            window = m;
        });
        manager.hook_notebook_bottom.connect( (m) => {
            bottombar = m;
        });
        manager.hook_source_view.connect( (m) => {
            all_source_view.append(m);
        });
    }
    
    public void register_function_arg (Hook hook, HookFunctionArg hook_function) {
        switch (hook) {
        case Hook.SOURCE_VIEW:
            manager.hook_source_view.connect_after ((m) => {
                hook_function(m);
            });
            foreach (var source_view in all_source_view) {
                hook_function (source_view);
            }
            break;
        case Hook.SETTINGS_WINDOW:
            manager.hook_preferences_window.connect_after ( (d) => {
                hook_function (d);
            });
            break;
        }
    }
    
    public void register_function_signal (Hook hook, string signal_name, Object obj) {
        switch(hook) {
        case Hook.BOTTOMBAR:
            manager.hook_notebook_bottom.connect_after (() => {
                Signal.emit_by_name (obj, signal_name);
            });
            if(bottombar != null) {
                Signal.emit_by_name (obj, signal_name);
            }
            break;
        }
    }
    
    public void register_function (Hook hook, HookFunction hook_function) {
        switch(hook) {
        case Hook.CONTEXT:
            manager.hook_notebook_context.connect_after (() => {
                hook_function();
            });
            if (context != null) {
                hook_function ();
            }
            break;
        case Hook.SIDEBAR:
            manager.hook_notebook_sidebar.connect_after (() => {
                hook_function();
            });
            if (sidebar != null) {
                hook_function ();
            }
            break;
        case Hook.TOOLBAR:
            manager.hook_toolbar.connect_after (() => {
                hook_function();
            });
            if (toolbar != null) {
                hook_function ();
            }
            break;
        case Hook.BOTTOMBAR:
            manager.hook_notebook_bottom.connect_after (() => {
                hook_function();
            });
            if (bottombar != null) {
                hook_function ();
            }
            break;
        case Hook.MAIN_MENU:
            manager.hook_main_menu.connect_after (() => {
                hook_function();
            });
            if (main_menu != null) {
                hook_function ();
            }
            break;
        case Hook.ADDONS_MENU:
            manager.hook_addons_menu.connect_after (() => {
                hook_function();
            });
            if (addons_menu != null) {
                hook_function ();
            }
            break;
        case Hook.WINDOW:
            manager.hook_new_window.connect_after (() => {
                hook_function ();
            });
            if (window != null) {
                hook_function ();
            }
            break;
        }
    }
    
}


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
        if (plugin_manager == null)
            plugin_manager = new Manager ();
        return plugin_manager;
    }

    private Manager () {

        plugin_iface = new Noise.Plugins.Interface (this);
        plugin_iface.set_name = "noise";

        /* Let's init the engine */
        engine = Peas.Engine.get_default ();
        engine.enable_loader ("python");
        engine.enable_loader ("gjs");
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
            if (module == info.get_module_name ()) 
                ((Peas.Activatable)extension).activate();
            /* Enable plugin set */
            else if (module == plugin_iface.set_name) {
                debug ("Loaded %s", module);
                ((Peas.Activatable)extension).activate();
            }
            else
                ((Peas.Activatable)extension).deactivate();
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
