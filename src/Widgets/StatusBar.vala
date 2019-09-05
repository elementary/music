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
 * The Music authors hereby grant permission for non-GPL compatible
 * GStreamer plugins to be used and distributed together with GStreamer
 * and Music. This permission is above and beyond the permissions granted
 * by the GPL license by which Music is covered. If you modify this code
 * you may extend this exception to your version of the code, but you are not
 * obligated to do so. If you do not wish to do so, delete this exception
 * statement from your version.
 */

public class Music.Widgets.StatusBar : Gtk.ActionBar {
    private Gtk.MenuButton playlist_menubutton;
    public bool playlist_menubutton_sensitive {
        set {
            playlist_menubutton.sensitive = value;
        }
    }

    construct {
        var add_pl_menuitem = new Gtk.MenuItem.with_label (_("Add Playlist"));
        var add_spl_menuitem = new Gtk.MenuItem.with_label (_("Add Smart Playlist"));

        var menu = new Gtk.Menu ();
        menu.append (add_pl_menuitem);
        menu.append (add_spl_menuitem);
        menu.show_all ();

        playlist_menubutton = new Gtk.MenuButton ();
        playlist_menubutton.direction = Gtk.ArrowType.UP;
        playlist_menubutton.popup = menu;
        playlist_menubutton.tooltip_text = _("Add Playlist");
        playlist_menubutton.add (new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.MENU));
        playlist_menubutton.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var eq_popover = new EqualizerPopover ();
        eq_popover.preset_changed.connect (update_tooltip);
        eq_popover.init ();

        var eq_menubutton = new Gtk.MenuButton ();
        eq_menubutton.popover = eq_popover;
        eq_menubutton.add (new Gtk.Image.from_icon_name ("media-eq-symbolic", Gtk.IconSize.MENU));
        eq_menubutton.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        pack_start (playlist_menubutton);
        pack_end (eq_menubutton);

        add_pl_menuitem.activate.connect (() => {
            App.main_window.create_new_playlist ();
        });

        add_spl_menuitem.activate.connect (() => {
            var smart_playlist_editor = new SmartPlaylistEditor (null, App.main_window.library_manager);
            smart_playlist_editor.show ();
        });
    }

    private void update_tooltip (string eq_preset_name) {
        /// Do not remove '%s'. It's a placeholder for selected equalizer preset name.
        tooltip_markup = _("Equalizer: %s").printf ("<b>" + Markup.escape_text (eq_preset_name) + "</b>");
    }
}
