/*-
 * Copyright (c) 2012-2019 elementary, Inc. (https://elementary.io)
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
 * The Music authors hereby grant permission for non-GPL compatible
 * GStreamer plugins to be used and distributed together with GStreamer
 * and Music. This permission is above and beyond the permissions granted
 * by the GPL license by which Music is covered. If you modify this code
 * you may extend this exception to your version of the code, but you are not
 * obligated to do so. If you do not wish to do so, delete this exception
 * statement from your version.
 *
 * Authored by: Zeeshan Ali (Khattak) <zeeshanak@gnome.org> (from Rygel)
 *              Lucas Baudin <xapantu@gmail.com> (from Pantheon Files)
 *              Corentin Noël <corentin@elementary.io>
 */

public class Music.Plugins.Interface : Object {
    public Manager manager { get; construct; }

    public enum Hook {
        CONTEXT,
        SIDEBAR,
        TOOLBAR,
        SOURCE_VIEW,
        SETTINGS_WINDOW,
        WINDOW
    }

    public delegate void HookFunction ();
    public delegate void HookFunctionArg (Object object);

    public Gtk.Notebook context {internal set; get; }
    public Gtk.Notebook sidebar {internal set; get; }
    public Gtk.Application noise_app {internal set; get; }
    public Gtk.Toolbar toolbar {internal set; get; }
    public Gtk.Window window {private set; get; }
    public string set_name {internal set; get; }

    private string? argument {internal set; get; }

    private unowned List<Gtk.TextView> all_source_view { private set; get; }

    public Interface (Manager manager) {
        Object (manager: manager);
    }

    construct {
        all_source_view = new List<Gtk.TextView>();

        manager.hook_new_window.connect ((m) => {
            window = m;
        });

        manager.hook_source_view.connect ((m) => {
            all_source_view.append (m);
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
