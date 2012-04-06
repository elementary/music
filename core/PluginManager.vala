/*
 * Copyright (C) 2011 Lucas Baudin <xapantu@gmail.com>
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org> (from Rygel)
 *
 * This file is part of Marlin.
 *
 * Marlin is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * Marlin is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 */


public class BeatBox.Plugins.Interface : Object {
    Manager manager;

    public Gtk.Window window {private set; get; }
    public Gtk.Dialog settings_dialog {private set; get; }

    public Interface (Manager manager) {
        this.manager = manager;
        manager.hook_new_window.connect ((w) => {
            window = w;
        });
        manager.hook_settings_dialog.connect ((w) => {
            settings_dialog = w;
        });
    }
    
    void on_send_hooks (Iface iface) {
        if (window != null) {
            iface.window = window;
            iface.window_created ();
        }
    }
    
    public void register_iface (Iface iface) {
        iface.send_hooks.connect (on_send_hooks);
        manager.hook_new_window.connect ( (w) => { iface.window = w; iface.window_created (); } );
    }
}

public class BeatBox.Plugins.Iface : Object {
    public Gtk.Window window { set; get; }
    public signal void window_created ();
    public signal void send_hooks ();
    public Iface() {
    }
}

public interface BeatBox.Plugins.Activatable : Object {
    public abstract Iface object { set; owned get; }
    public abstract void activate ();
    public abstract void deactivate ();
}

public class BeatBox.Plugins.Manager : Object
{
    public signal void hook_new_window (Gtk.Window window);
    public signal void hook_settings_dialog (Gtk.Dialog dialog);
    
    Peas.Engine engine;
    Peas.ExtensionSet exts;
    
    Peas.Engine engine_core;
    Peas.ExtensionSet exts_core;
	/*
    [CCode (cheader_filename = "libpeas/libpeas.h", cname = "peas_extension_set_foreach")]
    extern static void peas_extension_set_foreach (Peas.ExtensionSet extset, Peas.ExtensionSetForeachFunc option, void* data); */

    GLib.Settings settings;
    string settings_field;

    BeatBox.Plugins.Interface plugin_iface;

    public Manager(GLib.Settings s, string f, string d, string? e = null)
    {
        settings = s;
        settings_field = f;

        plugin_iface = new BeatBox.Plugins.Interface (this);

        /* Let's init the engine */
        engine = Peas.Engine.get_default ();
        engine.enable_loader ("python");
        engine.enable_loader ("gjs");
        engine.add_search_path (d, null);
//        engine.loaded_plugins = settings.get_strv(settings_field);

        /* Let's load the builtin ones */

        //settings.bind(settings_field, engine, "loaded-plugins", SettingsBindFlags.DEFAULT);

        /* Our extension set */
        exts = new Peas.ExtensionSet (engine, typeof(Activatable), null);

        exts.extension_added.connect(on_extension_added);
        exts.extension_removed.connect(on_extension_removed);
        exts.foreach(exts_foreach_function);
            
        var core_list = engine.get_plugin_list ().copy ();
        string[] core_plugins = new string[core_list.length()];

        for (int i = 0; i < core_list.length(); i++) {
            core_plugins[i] = core_list.nth_data (i).get_module_name ();
        }
        engine.loaded_plugins = core_plugins;

#if 0
        
        if (e != null) {
            /* The core now */
            engine_core = new Peas.Engine ();
            engine_core.enable_loader ("python");
            engine_core.enable_loader ("gjs");
            engine_core.add_search_path (GLib.Path.build_path ("/", d, e), null);

            var core_list = engine_core.get_plugin_list ().copy ();
            string[] core_plugins = new string[core_list.length()];

            for (int i = 0; i < core_list.length(); i++) {
                core_plugins[i] = core_list.nth_data (i).get_module_name ();
            }
            engine_core.loaded_plugins = core_plugins;

            /* Our extension set */
            exts_core = new Peas.ExtensionSet (engine_core, typeof(Peas.Activatable), "object", plugin_iface, null);

            peas_extension_set_foreach(exts_core, on_extension_added, null);
        }
#endif
    }

    public Gtk.Widget get_view () {
        var view = new PeasGtk.PluginManager (engine);
        var bottom_box = view.get_children ().nth_data (1) as Gtk.Box;
        assert(bottom_box != null);
        bottom_box.get_children ().nth_data(0).no_show_all = true;
        bottom_box.get_children ().nth_data(0).visible = false;
        return view;
    }

    void exts_foreach_function (Peas.ExtensionSet ext_set, Peas.PluginInfo info, Peas.Extension exten) {
        ((Activatable)exten).object = new Iface ();
        plugin_iface.register_iface (((Activatable)exten).object);
        ((Activatable)exten).activate();
    }

    void on_extension_added(Peas.PluginInfo info, Object extension) {
        ((Activatable)extension).object = new Iface ();
        plugin_iface.register_iface (((Activatable)extension).object);
        ((Activatable)extension).activate();
    }
    void on_extension_removed(Peas.PluginInfo info, Object extension) {
        ((Activatable)extension).deactivate();
    }
}


