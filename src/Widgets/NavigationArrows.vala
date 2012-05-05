//
//  Copyright (C) 2008 Christian Hergert <chris@dronelabs.com>
//  Copyright (C) 2011 Giulio Collura
//  Copyright (C) 2012 Mario Guerriero <mefrio.g@gmail.com>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

using Gtk;
using Gdk;

namespace Granite.Widgets {

    public class NavigationArrows : Gtk.Box {

        public signal void previous_clicked ();
        public signal void next_clicked ();

        // Style properties. Please note that style class names are for internal
        // use only. Theme developers should use GraniteWidgetsModeButton instead.
        internal static CssProvider style_provider;
        internal static StyleContext widget_style;
        private const int style_priority = Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION;
        
        private Gtk.Button previous_button;
        private Gtk.Button next_button;
        
        private const string STYLESHEET = """
            .GraniteModeButton .button {
                -GtkToolbar-button-relief: normal;
                border-radius: 0 0 0 0;
                border-style: solid;
                border-width: 1px 0 1px 1px;

                -unico-outer-stroke-width: 1px 0 1px 0;
                -unico-outer-stroke-radius: 0 0 0 0;
            }

            .GraniteModeButton .button:active,
            .GraniteModeButton .button:insensitive {
                -unico-outer-stroke-width: 1px 0 1px 0;
            }

            .GraniteModeButton .button:first-child {
                border-radius: 3px 0 0 3px;
                border-width: 1px 0 1px 1px;

                -unico-outer-stroke-width: 1px 0 1px 1px;
            }

            .GraniteModeButton .button:last-child {
                border-radius: 0 3px 3px 0;
                border-width: 1px;

                -unico-outer-stroke-width: 1px 1px 1px 0;
            }
        """;

        public NavigationArrows () {

            if (style_provider == null)
            {
                style_provider = new CssProvider ();
                try {
                    style_provider.load_from_data (STYLESHEET, -1);
                } catch (Error e) {
                    warning ("GraniteModeButton: %s. The widget will not look as intended", e.message);
                }
            }

            widget_style = get_style_context ();
            widget_style.add_class ("GraniteModeButton");

            homogeneous = true;
            spacing = 0;
            app_paintable = true;
    
            set_visual (get_screen ().get_rgba_visual ());

            can_focus = true;
            
            previous_button = new NavigationArrow ();
            var previous_image = new Image.from_icon_name ("go-previous-symbolic", IconSize.MENU);
            previous_button.set_image (previous_image);
            
            previous_button.clicked.connect (() => {
                previous_clicked ();
            });
            
            next_button = new NavigationArrow ();
            var next_image = new Image.from_icon_name ("go-next-symbolic", IconSize.MENU);
            next_button.set_image (next_image);
            
            next_button.clicked.connect (() => {
                next_clicked ();
            });
            
            add (previous_button);
            add (next_button);
            previous_button.show_all ();
            next_button.show_all ();

            previous_button.set_margin_left (4);
            previous_button.set_margin_top (4);
            previous_button.set_margin_bottom (4);
            
            next_button.set_margin_right (4);
            next_button.set_margin_top (4);
            next_button.set_margin_bottom (4);
        }

        public void set_item_visible (int index, bool val) {
            var item = get_children ().nth_data (index);
            if (item == null)
                return;

            item.set_no_show_all (!val);
            item.set_visible (val);
        }

    }

    private class NavigationArrow : Gtk.Button {
        public NavigationArrow () {
            can_focus = false;

            const int style_priority = Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION;

            get_style_context ().add_class ("raised");
            get_style_context ().add_provider (NavigationArrows.style_provider, style_priority);
        }
    }
}

