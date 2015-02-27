//
//  Copyright (C) 2012 Mario Guerriero <mefrio.g@gmail.com>,
//                     Victor Eduardo <victoreduardm@gmail.com>
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

public class Noise.Widgets.NavigationArrows : Gtk.Box {
    public signal void previous_clicked ();
    public signal void next_clicked ();

    public bool can_go_back {
        get { return previous_button.sensitive; }
        set { previous_button.sensitive = value; }
    }

    public bool can_go_next {
        get { return next_button.sensitive; }
        set { next_button.sensitive = value; }
    }

    private Gtk.Button previous_button;
    private Gtk.Button next_button;

    public NavigationArrows () {
        
    }

    construct {
        orientation = Gtk.Orientation.HORIZONTAL;
        spacing = 0;
        homogeneous = true;
        can_focus = false;

        previous_button = new Gtk.Button.from_icon_name ("go-previous-symbolic", Gtk.IconSize.BUTTON);
        previous_button.clicked.connect (() => {
            previous_clicked ();
        });

        next_button = new Gtk.Button.from_icon_name ("go-next-symbolic", Gtk.IconSize.BUTTON);
        next_button.clicked.connect ( () => {
            next_clicked ();
        });

        add (previous_button);
        add (next_button);
        get_style_context ().add_class (Gtk.STYLE_CLASS_LINKED);

        show_all ();
    }
}
