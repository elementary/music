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
        public Gtk.Widget info_panel_item { get; private set; default = new InfoPanelChooser (); }

        public StatusBar (LibraryWindow lw) {
            pack_start (playlist_item);
            pack_start (shuffle_item);
            pack_start (repeat_item);
            pack_end (equalizer_item);
            pack_end (info_panel_item);
        }

        public void set_info (string message) {
            set_center_widget (null);
            set_center_widget (new Gtk.Label (message));
            this.show_all ();
        }

        public void update_sensitivities () {
            var local_library = (LocalLibrary) libraries_manager.local_library;
            playlist_item.set_sensitive (local_library.main_directory_set && local_library.get_medias ().size > 0);
            info_panel_item.set_sensitive (App.main_window.info_panel.can_show_up);
        }
    }


    private class RepeatChooser : SimpleOptionChooser {

        public RepeatChooser () {
            // MUST follow the exact same order of Noise.Player.Repeat
            appendItem (_("Off"), new Gtk.Image.from_icon_name ("media-playlist-no-repeat-symbolic", Gtk.IconSize.MENU), _("Enable Repeat"));
            appendItem (_("Song"), new Gtk.Image.from_icon_name ("media-playlist-repeat-one-symbolic", Gtk.IconSize.MENU), _("Repeat Song"));
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
            appendItem (_("Off"), new Gtk.Image.from_icon_name ("media-playlist-no-shuffle-symbolic", Gtk.IconSize.MENU), _("Enable Shuffle"));
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

#if HAVE_ADD_PLAYLIST_AS_BUTTON
    private class AddPlaylistChooser : Gtk.ToggleButton {
#else
    private class AddPlaylistChooser : Gtk.EventBox {
#endif

        private Gtk.Menu menu;

        public AddPlaylistChooser () {
            margin_right = 12;

            tooltip_text = _("Add Playlist");

#if HAVE_ADD_PLAYLIST_AS_BUTTON
            relief = Gtk.ReliefStyle.NONE;
#else
            visible_window = false;
            above_child = true;
#endif

            add (new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.MENU));

            var add_pl_menuitem = new Gtk.MenuItem.with_label (_("Add Playlist"));
            var add_spl_menuitem = new Gtk.MenuItem.with_label (_("Add Smart Playlist"));

            menu = new Gtk.Menu ();
            menu.append (add_pl_menuitem);
            menu.append (add_spl_menuitem);
            menu.show_all ();

            menu.attach_widget = this;

            add_pl_menuitem.activate.connect ( () => {
                App.main_window.create_new_playlist ();
            });

            add_spl_menuitem.activate.connect ( () => {
                App.main_window.show_smart_playlist_dialog ();
            });
        }

#if HAVE_ADD_PLAYLIST_AS_BUTTON
        public override void toggled () {
            if (menu.visible)
                menu.popdown ();
            else
                menu.popup (null, null, null, Gdk.BUTTON_PRIMARY, Gtk.get_current_event_time ());
        }
#else
        public override bool button_press_event (Gdk.EventButton event) {
            if (event.type == Gdk.EventType.BUTTON_PRESS) {
                menu.popup (null, null, null, Gdk.BUTTON_SECONDARY, event.time);
                return true;
            }

            return false;
        }
#endif
    }

    private class EqualizerChooser : Gtk.MenuButton {
        public EqualizerChooser () {
            var eq_popover = new EqualizerPopover ();
            eq_popover.preset_changed.connect (update_tooltip);
            eq_popover.init ();

            popover = eq_popover;
            add (new Gtk.Image.from_icon_name ("media-eq-symbolic", Gtk.IconSize.MENU));
        }

        private void update_tooltip (string eq_preset_name) {
            /// Do not remove '%s'. It's a placeholder for selected equalizer preset name.
            tooltip_markup = _("Equalizer: %s").printf ("<b>" + Markup.escape_text (eq_preset_name) + "</b>");
        }
    }

    private class InfoPanelChooser : SimpleOptionChooser {

        public InfoPanelChooser () {
            var info_panel_show = new Gtk.Image.from_icon_name ("pane-show-symbolic", Gtk.IconSize.MENU);
            var info_panel_hide = new Gtk.Image.from_icon_name ("pane-hide-symbolic", Gtk.IconSize.MENU);

            appendItem (_("Hide"), info_panel_show, _("Show Info Panel"));
            appendItem (_("Show"), info_panel_hide, _("Hide Info Panel"));

            on_info_panel_visibility_change ();
            var info_panel = App.main_window.info_panel;
            info_panel.show.connect (on_info_panel_visibility_change);
            info_panel.hide.connect (on_info_panel_visibility_change);

            option_changed.connect (on_option_changed);
        }

        private void on_info_panel_visibility_change () {
            setOption (App.main_window.info_panel.visible ? 1 : 0);
        }

        private void on_option_changed (bool by_user) {
            int val = current_option;

            bool visible = val == 1;
            App.main_window.info_panel.visible = visible;

            // We write the new state to settings in this method as this is the only user-facing widget
            // for hiding and showing the context pane. Any other visibility change we do internally
            // or elsewhere should not be saved
            if (by_user)
                Settings.SavedState.get_default ().more_visible = visible;
        }
    }

}
