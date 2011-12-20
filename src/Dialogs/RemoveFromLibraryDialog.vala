/*-
 * Copyright (c) 2011       Scott Ringwelski <sgringwe@mtu.edu>
 *
 * Originally Written by Victor Eduardo for BeatBox Music Player
 * BeatBox Music Player: http://www.launchpad.net/beat-box
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
 */

using Gtk;

public class BeatBox.RemoveFromLibraryDialog : Window {

    private LibraryWindow lw;

    public signal void ok_button_pressed (bool delete_files);

    private VBox content;
    private HBox padding;
    private Button ok_button;
    private Button cancel_button;
    private CheckButton check_button;


    public RemoveFromLibraryDialog (LibraryWindow library_window, int number_of_songs) {

        this.lw = library_window;

        this.set_title("");
        this.window_position = WindowPosition.CENTER;
        this.type_hint = Gdk.WindowTypeHint.DIALOG;
        this.set_modal(true);
        this.set_transient_for(lw);
        this.destroy_with_parent = true;
        this.resizable = false;
        this.deletable = false;

        content = new VBox(false, 10);
        padding = new HBox(false, 20);

        Image question = new Image.from_stock(Gtk.Stock.DIALOG_WARNING, Gtk.IconSize.DIALOG);

        string question_text;

	if (number_of_songs > 1)
        	question_text = "Remove " + number_of_songs.to_string () + " Songs From Library?";
        else
        	question_text = "Remove Song From Library?";

        Label title = new Label (question_text);

        ok_button = new Button.with_label ("OK");
        cancel_button = new Button.with_label ("Cancel");

        string checkbox_text = "Move file" + ((number_of_songs > 1)? "s": "") + " to the trash";

        check_button = new CheckButton.with_label (checkbox_text);
        check_button.set_active (false);

        title.xalign = 0.0f;
        title.set_line_wrap(false);
        title.set_markup("<span weight=\"bold\" size=\"larger\">" + question_text + "</span>");

        /* set up controls layout */
        HBox information = new HBox (false, 0);
        VBox information_text = new VBox (false, 0);

        information.pack_start (question, false, false, 10);
        information_text.pack_start (title, false, true, 12);
        information_text.pack_start (check_button, false, true, 5);
        information.pack_start (information_text, true, true, 5);

        HButtonBox bottom_buttons = new HButtonBox ();

        bottom_buttons.set_layout (ButtonBoxStyle.END);
        bottom_buttons.pack_end (cancel_button, false, false, 0);
        bottom_buttons.pack_end (ok_button, false, false, 0);
        bottom_buttons.set_spacing (10);

        content.pack_start (information, false, true, 0);
        content.pack_start (bottom_buttons, false, true, 10);

        padding.pack_start (content, true, true, 10);

        ok_button.clicked.connect (ok_button_clicked);
        cancel_button.clicked.connect ( () => { destroy (); });

        add(padding);

	cancel_button.grab_focus ();

        show_all();
    }

    public static Gtk.Alignment wrap_alignment (Gtk.Widget widget, int top, int right, int bottom, int left) {
        var alignment = new Gtk.Alignment(0.0f, 0.0f, 1.0f, 1.0f);
        alignment.top_padding = top;
        alignment.right_padding = right;
        alignment.bottom_padding = bottom;
        alignment.left_padding = left;

        alignment.add (widget);
        
        return alignment;
    }

    void ok_button_clicked () {
        ok_button_pressed (check_button.get_active ());
        destroy ();
    }
}

