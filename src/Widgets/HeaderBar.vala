// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012-2018 elementary LLC. (https://elementary.io)
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
 *
 * Authored by: Scott Ringwelski <sgringwe@mtu.edu>,
 *              Victor Eduardo <victoreduardm@gmail.com>
 */

public class Noise.HeaderBar : Gtk.HeaderBar {
    private PreferencesWindow? preferences = null;

    construct {
        var previous_button = new Gtk.Button.from_icon_name ("media-skip-backward-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
        previous_button.action_name = LibraryWindow.ACTION_PREFIX + LibraryWindow.ACTION_PLAY_PREVIOUS;
        previous_button.tooltip_text = _("Previous");

        var play_button = new Gtk.Button.from_icon_name ("media-playback-start-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
        play_button.action_name = LibraryWindow.ACTION_PREFIX + LibraryWindow.ACTION_PLAY;
        play_button.tooltip_text = _("Play");

        var next_button = new Gtk.Button.from_icon_name ("media-skip-forward-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
        next_button.action_name = LibraryWindow.ACTION_PREFIX + LibraryWindow.ACTION_PLAY_NEXT;
        next_button.tooltip_text = _("Next");

        var import_menuitem = new Gtk.MenuItem.with_label (_("Import to Library…"));
        import_menuitem.action_name = LibraryWindow.ACTION_PREFIX + LibraryWindow.ACTION_IMPORT;

        var preferences_menuitem = new Gtk.MenuItem.with_label (_("Preferences"));
        preferences_menuitem.activate.connect (open_preferences);

        var menu = new Gtk.Menu ();
        menu.append (import_menuitem);
        menu.append (new Gtk.SeparatorMenuItem ());
        menu.append (preferences_menuitem);
        menu.show_all ();

        var menu_button = new Gtk.MenuButton ();
        menu_button.image = new Gtk.Image.from_icon_name ("open-menu", Gtk.IconSize.LARGE_TOOLBAR);
        menu_button.popup = menu;
        menu_button.valign = Gtk.Align.CENTER;

        show_close_button = true;
        title = ((Noise.App) GLib.Application.get_default ()).program_name;
        pack_start (previous_button);
        pack_start (play_button);
        pack_start (next_button);
        pack_end (menu_button);

        App.main_window.actions.action_state_changed.connect ((name, new_state) => {
            if (name == LibraryWindow.ACTION_PLAY) {
                if (new_state.get_boolean () == false) {
                    play_button.image = new Gtk.Image.from_icon_name ("media-playback-start-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
                    play_button.tooltip_text = _("Play");
                } else {
                    play_button.image = new Gtk.Image.from_icon_name ("media-playback-pause-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
                    play_button.tooltip_text = _("Pause");
                }
            }
        });
    }

    private void open_preferences () {
        if (preferences == null) {
            preferences = new PreferencesWindow ();
        }

        preferences.show_all ();
        preferences.run ();
        preferences = null;
    }
}
