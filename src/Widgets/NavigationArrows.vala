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

public class Granite.Widgets.NavigationArrows : Gtk.Box {
    private const string PREVIOUS_ICON = "go-previous";
    private const string NEXT_ICON = "go-next";
    private const string PREVIOUS_ICON_SYMBOLIC = "go-previous";
    private const string NEXT_ICON_SYMBOLIC = "go-next";

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


    public NavigationArrows (bool symbolic = true) {
        orientation = Gtk.Orientation.HORIZONTAL;
        homogeneous = true;
        spacing = 0;

        can_focus = false;

        previous_button = new Gtk.Button ();
        var previous_icon_name = symbolic ? PREVIOUS_ICON_SYMBOLIC : PREVIOUS_ICON;
        var previous_image = new Gtk.Image.from_icon_name (previous_icon_name, Gtk.IconSize.MENU);
        previous_button.set_image (previous_image);

        previous_button.clicked.connect ( () => {
            previous_clicked ();
        });

        next_button = new Gtk.Button ();
        var next_icon_name = symbolic ? NEXT_ICON_SYMBOLIC : NEXT_ICON;
        var next_image = new Gtk.Image.from_icon_name (next_icon_name, Gtk.IconSize.MENU);
        next_button.set_image (next_image);

        next_button.clicked.connect ( () => {
            next_clicked ();
        });

        add (previous_button);
        add (next_button);

        var style = get_style_context ();
        style.add_class (Gtk.STYLE_CLASS_LINKED);
        style.add_class ("raised"); // Needed for toolbars

        show_all ();
    }
}