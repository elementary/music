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
        public Gtk.Widget playlist_item { get; private set; default = new AddPlaylistChooser (); }
        public Gtk.Widget shuffle_item { get; private set; default = new ShuffleChooser (); }
        public Gtk.Widget repeat_item { get; private set; default = new RepeatChooser (); }
        public Gtk.Widget equalizer_item { get; private set; default = new EqualizerChooser (); }

        construct {
            pack_start (playlist_item);
            pack_start (shuffle_item);
            pack_start (repeat_item);

            pack_end (equalizer_item);
            pack_end (info_panel_item);
        }

        public void set_info (string message) {
            set_center_widget (null);
            set_center_widget (new Gtk.Label (message));
            show_all ();
        }

        public void update_sensitivities () {
            var local_library = (LocalLibrary) libraries_manager.local_library;
            playlist_item.set_sensitive (local_library.main_directory_set && local_library.get_medias ().size > 0);
        }
    }


    private class RepeatChooser : SimpleOptionChooser {
        construct {
            // MUST follow the exact same order of Noise.Player.Repeat
            append_item (_("Off"), "media-playlist-no-repeat-symbolic", _("Enable Repeat"), true);
            append_item (_("Song"), "media-playlist-repeat-one-symbolic", _("Repeat Song"), true);
            append_item (_("Album"), "media-playlist-repeat-symbolic", _("Repeat Album"));
            append_item (_("Artist"), "media-playlist-repeat-symbolic", _("Repeat Artist"));
            append_item (_("All"), "media-playlist-repeat-symbolic", _("Disable Repeat"), true);

            update_option ();

            option_changed.connect (on_option_changed);
            App.player.notify["repeat"].connect (update_option);
        }

        private void update_option () {
            set_option ((int)Settings.Main.get_default ().repeat_mode);
        }

        private void on_option_changed () {
            int val = current_option;

            if ((int)Settings.Main.get_default ().repeat_mode == val)
                return;

            App.player.set_repeat_mode ((Noise.Settings.Repeat)val);
        }
    }


    private class ShuffleChooser : SimpleOptionChooser {
        construct {
            append_item (_("Off"), "media-playlist-no-shuffle-symbolic", _("Enable Shuffle"), true);
            append_item (_("All"), "media-playlist-shuffle-symbolic", _("Disable Shuffle"), true);

            update_mode ();

            option_changed.connect (on_option_changed);
            App.player.notify["shuffle"].connect (update_mode);
        }

        private void update_mode () {
            set_option ((int)Settings.Main.get_default ().shuffle_mode);
        }

        private void on_option_changed () {
            int val = current_option;

            if ((int)Settings.Main.get_default ().shuffle_mode != val) {
                App.player.set_shuffle_mode ((Noise.Settings.Shuffle)val);
            }
        }
    }

    private class AddPlaylistChooser : Gtk.ToggleButton {
        private Gtk.Menu menu;

        construct {
            margin_right = 12;

            tooltip_text = _("Add Playlist");

            relief = Gtk.ReliefStyle.NONE;

            add (new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.MENU));

            var add_pl_menuitem = new Gtk.MenuItem.with_label (_("Add Playlist"));
            var add_spl_menuitem = new Gtk.MenuItem.with_label (_("Add Smart Playlist"));

            menu = new Gtk.Menu ();
            menu.append (add_pl_menuitem);
            menu.append (add_spl_menuitem);
            menu.show_all ();

            menu.attach_widget = this;

            add_pl_menuitem.activate.connect (() => {
                App.main_window.create_new_playlist ();
            });

            add_spl_menuitem.activate.connect (() => {
                App.main_window.show_smart_playlist_dialog ();
            });
        }

        public override void toggled () {
            if (menu.visible) {
                menu.popdown ();
            } else {
                menu.popup (null, null, null, Gdk.BUTTON_PRIMARY, Gtk.get_current_event_time ());
            }
        }
    }

    private class EqualizerChooser : Gtk.MenuButton {
        construct {
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

    private class InfoPanelChooser : SimpleOptionChooser {
        construct {
            var info_panel_show = new Gtk.Image.from_icon_name ("pane-show-symbolic", Gtk.IconSize.MENU);
            var info_panel_hide = new Gtk.Image.from_icon_name ("pane-hide-symbolic", Gtk.IconSize.MENU);

            append_item (_("Hide"), "pane-show-symbolic", _("Show Info Panel"), true);
            append_item (_("Show"), "pane-hide-symbolic", _("Hide Info Panel"), true);

            on_info_panel_visibility_change ();
            var info_panel = App.main_window.info_panel;
            info_panel.show.connect (on_info_panel_visibility_change);
            info_panel.hide.connect (on_info_panel_visibility_change);

            option_changed.connect (on_option_changed);
        }

        private void on_info_panel_visibility_change () {
            set_option (App.main_window.info_panel.visible ? 1 : 0);
        }

        private void on_option_changed (bool by_user) {
            int val = current_option;

            bool visible = val == 1;
            App.main_window.info_panel.visible = visible;

            // We write the new state to settings in this method as this is the only user-facing widget
            // for hiding and showing the context pane. Any other visibility change we do internally
            // or elsewhere should not be saved
            if (by_user) {
                Settings.SavedState.get_default ().more_visible = visible;
            }
        }
    }

}
