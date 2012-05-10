// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012 Granite Developers (http://launchpad.net/noise)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Victor Eduardo <victoreduardm@gmail.com>
 */

/**
 * An alert compliant with elementary's HIG
 * TODO: add link http://elementaryos.org/...
 * FIXME: Make line wrapping work perfectly. Currently it allocates a huge size. Probably
 *         would have to be fixed inside WrapLabel
 */
public class Granite.Widgets.EmbeddedAlert : Gtk.EventBox {

    /**
     * Returns the Gtk.Action.name of the clicked button as received by set_alert()
     */
    public signal void action_button_clicked (string action_name);

    public enum Level {
        ERROR,
        WARNING,
        QUESTION,
        INFO
    }

    const string ERROR_ICON = "dialog-error";
    const string WARNING_ICON = "dialog-warning";
    const string QUESTION_ICON = "dialog-question";
    const string INFO_ICON = "dialog-information";

    const string PRIMARY_TEXT_MARKUP = "<span weight=\"bold\" size=\"larger\">%s</span>";

    private Gtk.Box hbox;

    protected Gtk.Label primary_text_label;
    protected Gtk.Label secondary_text_label;
    protected Gtk.Image image;
    protected Gtk.ButtonBox action_button_box;


    public EmbeddedAlert () {
        get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        get_style_context ().add_class (Granite.STYLE_CLASS_CONTENT_VIEW);

        action_button_box = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
        action_button_box.valign = Gtk.Align.START;

        primary_text_label = new Gtk.Label (null);
        primary_text_label.margin_bottom = 12;

        secondary_text_label = new Gtk.Label (null);
        secondary_text_label.margin_bottom = 24;

        // Make sure the text is selectable
        primary_text_label.selectable = secondary_text_label.selectable = true;
        primary_text_label.use_markup = secondary_text_label.use_markup = true;

        primary_text_label.wrap = secondary_text_label.wrap = true;
        primary_text_label.wrap_mode = secondary_text_label.wrap_mode = Pango.WrapMode.WORD_CHAR;

        primary_text_label.valign = secondary_text_label.valign = Gtk.Align.START;

        image = new Gtk.Image.from_icon_name ("", Gtk.IconSize.DIALOG);

        image.halign = Gtk.Align.END;
        image.valign = Gtk.Align.START;
        image.margin_right = 12;

        // Init stuff
        set_alert ("", "");

        var message_vbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        message_vbox.pack_start (primary_text_label, false, false, 0);
        message_vbox.pack_start (secondary_text_label, false, false, 0);
        message_vbox.pack_end (action_button_box, false, false, 0);

        var hbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        hbox.halign = hbox.valign = Gtk.Align.CENTER; // center-align the content
        hbox.margin_top = hbox.margin_bottom = 50;

        hbox.pack_start (image, false, false, 0);
        hbox.pack_end (message_vbox, true, true, 0);

        this.size_allocate.connect (on_size_allocate);

        add (hbox);
    }

    private void on_size_allocate (Gtk.Allocation alloc) {
        /* TEXT_WIDTH = (3/5)TOTAL_WIDTH
         * HR_MARGIN  = (1/5)TOTAL_WIDTH
         * TOTAL_WIDTH = TEXT_WIDTH + 2 * HR_MARGIN
         */
        hbox.margin_left = hbox.margin_right = alloc.width / 5;
    }

    public void set_alert (string primary_text, string secondary_text, Gtk.Action[] ? actions = null,
                            bool show_icon = true, Level alert_level = Level.WARNING)
    {
        // Reset size request
        set_size_request (1, 1);

        if (primary_text == null)
            primary_text = "";

        if (secondary_text == null)
            secondary_text = "";

        // We force the HIG here. Whenever show_icon is true, the title has to be left-aligned.
        if (show_icon) {
            primary_text_label.halign = secondary_text_label.halign = Gtk.Align.START;
            primary_text_label.justify = secondary_text_label.justify = Gtk.Justification.LEFT;

            // TODO: Unless the same icon system is added to granite, don't depend on it.
            switch (alert_level) {
                case Level.ERROR:
                    image.set_from_pixbuf (Icons.render_icon (ERROR_ICON, Gtk.IconSize.DIALOG));
                    break;
                case Level.WARNING:
                    image.set_from_pixbuf (Icons.render_icon (WARNING_ICON, Gtk.IconSize.DIALOG));
                    break;
                case Level.QUESTION:
                    image.set_from_pixbuf (Icons.render_icon (QUESTION_ICON, Gtk.IconSize.DIALOG));
                    break;
                default:
                    image.set_from_pixbuf (Icons.render_icon (INFO_ICON, Gtk.IconSize.DIALOG));
                    break;
             }
        }
        else {
            primary_text_label.halign = secondary_text_label.halign = Gtk.Align.CENTER;
            primary_text_label.justify = secondary_text_label.justify = Gtk.Justification.CENTER;
        }

        image.set_no_show_all (!show_icon);
        image.set_visible (show_icon);

        // clear button box
        foreach (var button in action_button_box.get_children ()) {
            action_button_box.remove (button);
        }

        // Add a button for each action
        if (actions != null && actions.length > 0) {
            for (int i = 0; i < actions.length; i++) {
                var action_item = actions[i];
                if (action_item != null) {
                    var action_button = Granite.Widgets.Utils.new_button_from_action (action_item);
                    if (action_button != null) {
                        // Pack into the button box
                        action_button_box.pack_start (action_button, false, false, 0);

                        action_button.button_release_event.connect ( () => {
                            action_button_clicked (action_item.name);
                            return false;
                        });
                    }
                }
            }

            if (show_icon) {
                action_button_box.set_layout (Gtk.ButtonBoxStyle.END);
                action_button_box.halign = Gtk.Align.END;
            }
            else {
                action_button_box.set_layout (Gtk.ButtonBoxStyle.CENTER);
                action_button_box.halign = Gtk.Align.CENTER;
            }

            action_button_box.set_no_show_all (false);
            action_button_box.show_all ();
        }
        else {
            action_button_box.set_no_show_all (true);
            action_button_box.hide ();
        }

        primary_text_label.set_markup (PRIMARY_TEXT_MARKUP.printf (Markup.escape_text (primary_text, -1)));
        secondary_text_label.set_markup (secondary_text);
    }
}

// TODO: Move to a separate file
namespace Granite.Widgets.Utils {

    public Gtk.Button? new_button_from_action (Gtk.Action action) {
        if (action == null)
            return new Gtk.Button ();

        bool has_label = action.label != null;
        bool has_stock = action.stock_id != null;
        bool has_gicon = action.gicon != null;
        bool has_tooltip = action.tooltip != null;

        Gtk.Button? action_button = null;

        // Prefer label over stock_id
        if (has_label)
            action_button = new Gtk.Button.with_label (action.label);
        else if (has_stock)
            action_button = new Gtk.Button.from_stock (action.stock_id);
        else
            action_button = new Gtk.Button ();

        // Prefer stock_id over gicon
        if (has_stock)
            action_button.set_image (new Gtk.Image.from_stock (action.stock_id, Gtk.IconSize.BUTTON));
        else if (has_gicon)
            action_button.set_image (new Gtk.Image.from_gicon (action.gicon, Gtk.IconSize.BUTTON));

        if (has_tooltip)
            action_button.set_tooltip_text (action.tooltip);

        return action_button;
    }
}

