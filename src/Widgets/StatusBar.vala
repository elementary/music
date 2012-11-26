// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012 Noise Developers (http://launchpad.net/noise)
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
 */

namespace Noise.Widgets {

    public class StatusBar : Granite.Widgets.StatusBar {
        public Gtk.Widget playlist_item { get; private set; default = new AddPlaylistChooser (); }
        public Gtk.Widget shuffle_item { get; private set; default = new ShuffleChooser (); }
        public Gtk.Widget repeat_item { get; private set; default = new RepeatChooser (); }
        public Gtk.Widget equalizer_item { get; private set; default = new EqualizerChooser (); }
        public Gtk.Widget info_panel_item { get; private set; default = new InfoPanelChooser (); }

        public StatusBar (LibraryWindow lw) {
            insert_widget (playlist_item, true);
            insert_widget (shuffle_item, true);
            insert_widget (repeat_item, true);
            insert_widget (equalizer_item);
            insert_widget (info_panel_item);
        }

        public void set_info (string message) {
            set_text (message);
        }

        public void update_sensitivities () {
            var lm = App.library_manager;
            playlist_item.set_sensitive (lm.main_directory_set && lm.have_media);
            info_panel_item.set_sensitive (App.main_window.info_panel.can_show_up);
        }
    }


    private class RepeatChooser : SimpleOptionChooser {

        public RepeatChooser () {
            var repeat_on_image = Icons.REPEAT_ON.render_image (Gtk.IconSize.MENU);
            var repeat_one_image = Icons.REPEAT_ONE.render_image (Gtk.IconSize.MENU);
            var repeat_off_image = Icons.REPEAT_OFF.render_image (Gtk.IconSize.MENU);

            // MUST follow the exact same order of Noise.Player.Repeat
            appendItem (_("Off"), repeat_off_image, _("Enable Repeat"));
            appendItem (_("Song"), repeat_one_image, _("Repeat Song"));
            appendItem (_("Album"), repeat_on_image, _("Repeat Album"));
            appendItem (_("Artist"), repeat_on_image, _("Repeat Artist"));
            appendItem (_("All"), repeat_on_image, _("Repeat All"));

            update_option ();

            option_changed.connect (on_option_changed);
            App.player.notify["repeat"].connect (update_option);
        }

        private void update_option () {
            setOption ((int)App.player.repeat);
        }

        private void on_option_changed () {
            int val = current_option;

            if ((int)App.player.repeat == val)
                return;

            App.player.repeat = (Player.Repeat)val;
        }
    }


    private class ShuffleChooser : SimpleOptionChooser {

        public ShuffleChooser () {
            var shuffle_on_image   = Icons.SHUFFLE_ON.render_image (Gtk.IconSize.MENU);
            var shuffle_off_image  = Icons.SHUFFLE_OFF.render_image (Gtk.IconSize.MENU);

            appendItem (_("Off"), shuffle_off_image, _("Enable Shuffle"));
            appendItem (_("All"), shuffle_on_image, _("Disable Shuffle"));

            update_mode ();

            option_changed.connect (on_option_changed);
            App.player.notify["shuffle"].connect (update_mode);
        }

        private void update_mode () {
            setOption ((int)App.player.shuffle);
        }

        private void on_option_changed () {
            int val = current_option;

            if ((int)App.player.shuffle == val)
                return;

            App.player.setShuffleMode ((Player.Shuffle)val, true);
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

            add (Icons.LIST_ADD_SYMBOLIC.render_image (Gtk.IconSize.MENU));

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


    private class EqualizerChooser : SimpleOptionChooser {

        private Gtk.Window? equalizer_window = null;

        public EqualizerChooser () {
            var eq_show_image = Icons.EQ_SYMBOLIC.render_image (Gtk.IconSize.MENU);
            var eq_hide_image = Icons.EQ_SYMBOLIC.render_image (Gtk.IconSize.MENU);

            appendItem (_("Hide"), eq_show_image, _("Show Equalizer"));
            appendItem (_("Show"), eq_hide_image, _("Hide Equalizer"));

            setOption (0);

            option_changed.connect (eq_option_chooser_clicked);
        }

        private void eq_option_chooser_clicked () {
            int val = current_option;

            if (equalizer_window == null && val == 1) {
                equalizer_window = new EqualizerWindow (App.library_manager, App.main_window);
                equalizer_window.show_all ();
                equalizer_window.destroy.connect ( () => {
                    // revert the option to "Hide equalizer" after the window is destroyed
                    setOption (0);
                });
            }
            else if (val == 0 && equalizer_window != null) {
                equalizer_window.destroy ();
                equalizer_window = null;
            }
        }
    }


    private class InfoPanelChooser : SimpleOptionChooser {

        public InfoPanelChooser () {
            var info_panel_show = Icons.PANE_SHOW_SYMBOLIC.render_image (Gtk.IconSize.MENU);
            var info_panel_hide = Icons.PANE_HIDE_SYMBOLIC.render_image (Gtk.IconSize.MENU);

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
                saved_state.more_visible = visible;
        }
    }

}
