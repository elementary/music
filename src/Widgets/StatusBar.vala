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

namespace Noise.Widgets {

    public class StatusBar : Gtk.ActionBar {
        private Gtk.MenuButton playlist_menubutton;
        public Gtk.Widget shuffle_item { get; private set; default = new ShuffleChooser (); }
        public Gtk.Widget repeat_item { get; private set; default = new RepeatChooser (); }
        public Gtk.Widget equalizer_item { get; private set; default = new EqualizerChooser (); }

        public StatusBar () {
            var add_pl_menuitem = new Gtk.MenuItem.with_label (_("Add Playlist"));
            var add_spl_menuitem = new Gtk.MenuItem.with_label (_("Add Smart Playlist"));

            var menu = new Gtk.Menu ();
            menu.append (add_pl_menuitem);
            menu.append (add_spl_menuitem);
            menu.show_all ();

            playlist_menubutton = new Gtk.MenuButton ();
            playlist_menubutton.direction = Gtk.ArrowType.UP;
            playlist_menubutton.margin_right = 12;
            playlist_menubutton.popup = menu;
            playlist_menubutton.tooltip_text = _("Add Playlist");
            playlist_menubutton.add (new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.MENU));
            playlist_menubutton.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

            pack_start (playlist_menubutton);
            pack_start (shuffle_item);
            pack_start (repeat_item);
            pack_end (equalizer_item);

            add_pl_menuitem.activate.connect (() => {
                App.main_window.create_new_playlist ();
            });

            add_spl_menuitem.activate.connect (() => {
                App.main_window.show_smart_playlist_dialog ();
            });
        }

        public void update_sensitivities () {
            var local_library = (LocalLibrary) libraries_manager.local_library;
            playlist_menubutton.set_sensitive (local_library.main_directory_set && local_library.get_medias ().size > 0);
        }
    }


    private class RepeatChooser : SimpleOptionChooser {

        public RepeatChooser () {
            // MUST follow the exact same order of Noise.Player.Repeat
            appendItem (_("Off"), new Gtk.Image.from_icon_name ("media-playlist-no-repeat-symbolic", Gtk.IconSize.MENU), _("Enable Repeat"));
            appendItem (_("Song"), new Gtk.Image.from_icon_name ("media-playlist-repeat-song-symbolic", Gtk.IconSize.MENU), _("Repeat Song"));
            appendItem (_("Album"), new Gtk.Image.from_icon_name ("media-playlist-repeat-symbolic", Gtk.IconSize.MENU), _("Repeat Album"));
            appendItem (_("Artist"), new Gtk.Image.from_icon_name ("media-playlist-repeat-symbolic", Gtk.IconSize.MENU), _("Repeat Artist"));
            appendItem (_("All"), new Gtk.Image.from_icon_name ("media-playlist-repeat-symbolic", Gtk.IconSize.MENU), _("Disable Repeat"));

            update_option ();

            option_changed.connect (on_option_changed);
            App.player.notify["repeat"].connect (update_option);
        }

        private void update_option () {
            setOption ((int)Settings.Main.get_default ().repeat_mode);
        }

        private void on_option_changed () {
            int val = current_option;

            if ((int)Settings.Main.get_default ().repeat_mode == val)
                return;

            App.player.set_repeat_mode ((Noise.Settings.Repeat)val);
        }
    }


    private class ShuffleChooser : SimpleOptionChooser {

        public ShuffleChooser () {
            appendItem (_("Off"), new Gtk.Image.from_icon_name ("media-playlist-consecutive-symbolic", Gtk.IconSize.MENU), _("Enable Shuffle"));
            appendItem (_("All"), new Gtk.Image.from_icon_name ("media-playlist-shuffle-symbolic", Gtk.IconSize.MENU), _("Disable Shuffle"));

            update_mode ();

            option_changed.connect (on_option_changed);
            App.player.notify["shuffle"].connect (update_mode);
        }

        private void update_mode () {
            setOption ((int)Settings.Main.get_default ().shuffle_mode);
        }

        private void on_option_changed () {
            int val = current_option;

            if ((int)Settings.Main.get_default ().shuffle_mode == val)
                return;

            App.player.set_shuffle_mode ((Noise.Settings.Shuffle)val);
        }
    }

    private class EqualizerChooser : Gtk.MenuButton {
        public EqualizerChooser () {
            var eq_popover = new EqualizerPopover ();
            eq_popover.preset_changed.connect (update_tooltip);
            eq_popover.init ();

            popover = eq_popover;
            add (new Gtk.Image.from_icon_name ("media-eq-symbolic", Gtk.IconSize.MENU));
            get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        }

        private void update_tooltip (string eq_preset_name) {
            /// Do not remove '%s'. It's a placeholder for selected equalizer preset name.
            tooltip_markup = _("Equalizer: %s").printf ("<b>" + Markup.escape_text (eq_preset_name) + "</b>");
        }
    }
}
