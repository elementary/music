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
